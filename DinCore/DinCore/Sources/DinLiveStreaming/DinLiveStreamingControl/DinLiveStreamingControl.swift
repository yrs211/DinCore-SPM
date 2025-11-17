//
//  DinLiveStreamingControl.swift
//  DinCore
//
//  Created by Jin on 2021/6/9.
//

import UIKit
import DinSupport
import RxSwift
import RxRelay

public class DinLiveStreamingControl: NSObject {

//    var commObjects: [String: DinCameraKcpObject] = [:]

//    var cmdComm: DinCameraKcpObject?
//    var getPicComm: DinCameraKcpObject?
//    var hdComm: DinCameraKcpObject?
//    var stdComm: DinCameraKcpObject?
//    var audioComm: DinCameraKcpObject?
//    var talkComm: DinCameraKcpObject?

    /// 用于cmd的kcp通道保活
//    var cmdKcpTimer: DinGCDTimer?

    /// 用于在群组里面对ipc的通讯
    private(set) var communicateControl: DinChannelUDPControl?
    /// 用于在群组里面对群的通讯
    private(set) var group: DinUDPGroupControl?
    /// 摄像头实例
    private(set) var device: DinLiveStreaming

    var deviceProvider: String { type(of: device).provider }

    let operationManager: DinKcpChannelOperationManager

    let acceptDataQueue = DispatchQueue(label: DinQueueName.deviceAcceptData)

    /// Control info sync queue
    /// 在多线程读写的情况下，自研IPC的Info属性会有数据竞争的问题
    var unsafeInfo: [String: Any] = [:]
    var info: [String: Any]? {
        var tempInfo: [String: Any]? = [:]
        DinUser.homeDeviceInfoQueue.sync { [weak self] in
            if let self = self {
                tempInfo = self.unsafeInfo
            }
        }
        return tempInfo
    }

    var homeID: String

    // 属于代理的Kcp
    var proxyKcpManager: DinChannelKcpObjectManager?
    // 属于Lan的Kcp
    var lanKcpManager: DinChannelKcpObjectManager?
    // 属于P2P的Kcp
    var p2pKcpManager: DinChannelKcpObjectManager?

    var getRecordListMessageID = ""
    var getRecordListMessageIDV2 = ""
    var deleteRecordFileMessageID = ""
    var upgradeFirmwareMessageID = ""

    var decryQueue: DispatchQueue?

//    var isTalking = false
//    var isPreparingTalk = false
//
//    var isPreparingKcp = false
//
//    var isPreparingPic = false

    private let disposeBag = DisposeBag()

    // MARK: - 配件（主动操作/第三方操作）数据通知
    var deviceCallback: Observable<[String : Any]> {
        return deviceOperationResult.asObservable()
    }
    private let deviceOperationResult = PublishRelay<[String: Any]>()
    /// 设备（主动操作/第三方操作）数据通知
    /// - Parameter result: 结果
    func accept(deviceOperationResult result: [String: Any]) {
        // 音视频数据接收会再不同线程提交数据，框架设计只有一个提交数据通道，所以只能同步提交动作了
        acceptDataQueue.async { [weak self] in
            self?.deviceOperationResult.accept(result)
        }
    }

    // MARK: - 配件在线状态通知
    var deviceStatusCallback: Observable<Bool> {
        return deviceOnlineState.asObservable()
    }
    private let deviceOnlineState = PublishRelay<Bool>()
    /// 设备在线状态通知
    /// - Parameter online: 状态
    func accept(deviceOnlineState online: Bool) {
        deviceOnlineState.accept(online)
    }

    deinit {
        self.stopTalk()
//        self.stopLiveClock()
        // reset
        self.cleanCameraCommunicator()
        self.cleanGroupCommunicator()
        // 把kcp都关了先
        cleanAllKcpManagers()

        NotificationCenter.default.removeObserver(self)
    }
    /// Camera的操作类
    /// - Parameters:
    ///   - camera: Camera对象
    ///   - homeID: 家庭ID
    public init(withCommunicationDevice liveStreamingDevice: DinLiveStreaming, belongsToHome homeID: String) {
        self.device = liveStreamingDevice
        self.homeID = homeID
        self.operationManager = DinKcpChannelOperationManager()

        decryQueue = DispatchQueue(label: "com.dinsafer.core.ing.decrypt.\(liveStreamingDevice.id)")

        super.init()
//        // 系统的UDP代理模式通道收到的kcp包
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(receivedServerData(_:)),
//                                               name: .dinProxyDeliverKcpDataReceived,
//                                               object: nil)
        self.operationManager.delegate = self
        updateInfoDict(complete: nil)

        genKcpManagers()

        // 监听lanIp变化
        DinCore.eventBus.camera.cameraLanIPReceivedObservable.subscribe(onNext: { [weak self] cameraID in
            if cameraID == self?.device.id {
                self?.communicateControl?.refreshLanPipe(
                    ipAdress: self?.device.lanAddress ?? "",
                    port: self?.device.lanPort ?? 0
                )
            }
        }).disposed(by: disposeBag)

        // 如果总代理Delivery改变了，同时ipc不是离线状态，这里强制重连
        DinCore.eventBus.basic.proxyDeliverChangedObservable.subscribe(onNext: { [weak self] _ in
            self?.acceptDataQueue.async { [weak self] in
                guard let self = self else { return }
                if self.device.networkState != .offline {
                    self.connectToCamera(discardCache: true)
                }
            }
        }).disposed(by: disposeBag)

        // 摄像头的离线通知
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(receiveNetworkState(_:)),
                                               name: .dinDeviceNetworkState, object: nil)
    }

    private func genKcpManagers() {
        self.proxyKcpManager = DinChannelKcpObjectManager(withDeliverType: .proxy, fileSaveID: device.id) { [weak self] in
            self?.sendCMD(["cmd": "keepalive"], manager: self?.proxyKcpManager)
        }
        self.lanKcpManager = DinChannelKcpObjectManager(withDeliverType: .lan, fileSaveID: device.id) { [weak self] in
            self?.sendCMD(["cmd": "keepalive"], manager: self?.lanKcpManager)
        }
        self.p2pKcpManager = DinChannelKcpObjectManager(withDeliverType: .p2p, fileSaveID: device.id) { [weak self] in
            self?.sendCMD(["cmd": "keepalive"], manager: self?.p2pKcpManager)
        }
        self.proxyKcpManager?.delegate = self
        self.lanKcpManager?.delegate = self
        self.p2pKcpManager?.delegate = self
    }

    private func cleanAllKcpManagers() {
        proxyKcpManager?.reset()
        lanKcpManager?.reset()
        p2pKcpManager?.reset()
    }

    func getAvailableManagerByPriority() -> DinChannelKcpObjectManager? {
        guard let commControl = communicateControl else {
            return nil
        }
        var manager: DinChannelKcpObjectManager?
        let type = commControl.availableDeliverByPriority()
        switch type {
        case .lan:
            manager = lanKcpManager
        case .p2p:
            manager = p2pKcpManager
        default:
            manager = proxyKcpManager
        }
        return manager
    }

    /// 更新与Camera通讯的ID
    /// - Parameters:
    ///   - commID: 与Camera通讯的ID
    ///   - commSecret: 与Camera通讯的Secret
    ///   - complete: 是否更新成功 （包括id的更新和通讯器的重建）
    public func updateCameraCommunicator(withID commID: String, commSecret: String, complete: ((Bool)->())?) {
        guard commID.count > 0 else {
            complete?(false)
            return
        }
        let user = DinGroupCommunicator(withUniqueID: commID, groupID: device.groupID, commSecret: commSecret)

        // 如果有通讯EndID就不用请求服务器了
        if device.uniqueID.count > 0 {
            if genCameraCommunicator(user: user) {
                complete?(true)
            } else {
                complete?(false)
            }
        } else {
            let request = DinLiveStreamingRequest.getDevicesEndid(
                homeID: homeID,
                deviceIDs: [device.id],
                providers: [deviceProvider]
            )
            DinHttpProvider.request(request) { [weak self] result in
                if let camerasArr = result?["list"] as? [[String: Any]], camerasArr.count > 0 {
                    if self?.device.id == camerasArr.first?["pid"] as? String,
                       let camEndID = camerasArr.first?["end_id"] as? String,
                       camEndID.count > 0 {
                        self?.device.uniqueID = camEndID
                        if self?.genCameraCommunicator(user: user) ?? false {
                            complete?(true)
                        } else {
                            complete?(false)
                        }
                        return
                    }
                }
                complete?(false)
            } fail: {_ in
                complete?(false)
            }
        }
    }
    private func genCameraCommunicator(user: DinGroupCommunicator) -> Bool {
        guard let deliver = DinCore.proxyDeliver, device.uniqueID.count > 0 else {
            return false
        }
        communicateControl = DinChannelUDPControl(with: deliver,
                                                       communicationDevice: device,
                                                       communicationIdentity: user,
                                                       dataEncryptor: DinChannelEncryptor(withSecret: user.commSecret))
        return true
    }
    private func cleanCameraCommunicator() {
        self.communicateControl?.disconnect()
        self.communicateControl = nil
    }

    /// 通过自身的endID，建立和IPC群组的通讯器
    /// - Parameters:
    ///   - commID: 自身通讯endID
    ///   - commSecret: 自身通讯的Secret
    ///   - groupSecret: 所在群组通讯的Secret
    /// - Returns: 是否成功
    public func updateGroupCommunicator(withID commID: String, commSecret: String, groupSecret: String) -> Bool {
        guard commID.count > 0 else {
            return false
        }
        let communicationGroup = DinCommunicationGroup(withGroupID: device.groupID, groupSecret: groupSecret)
        let user = DinGroupCommunicator(withUniqueID: commID, groupID: device.groupID, commSecret: commSecret)
        group = DinUDPGroupControl(withCommunicationGroup: communicationGroup, groupUser: user)
        group?.delegate = self
        // 这里不要先连接了，等到目标的连接器(communicateControl: DinStorageBatteryUDPControl?)能新建成功再连接
//        group?.connect(complete: nil)
        return true
    }
    private func cleanGroupCommunicator() {
        self.group?.disconnect()
        self.group = nil
    }

//    // 系统的UDP代理模式通道收到的MSCT包
//    @objc private func receivedServerData(_ notif: Notification) {
//        guard let data = notif.userInfo?[DinSupportNotificationKey.dinKCPDataKey] as? Data else {
//            return
//        }
//        // 检查是否是属于本设备的消息
//        let convString = notif.userInfo?[DinSupportNotificationKey.dinKCPIDKey] as? String ?? ""
//        guard let commObject = commObjects[convString] else {
//            return
//        }
//        // 处理消息
//        commObject.kcpObject.inputData(data)
//    }

    // 收到摄像头的网络状态变化
    @objc private func receiveNetworkState(_ notif: Notification) {
        guard let device = notif.userInfo?[DinSupportNotificationKey.dinUDPCommunicationDeviceKey] as? DinLiveStreaming,
              device == self.device else {
            return
        }
        guard let networkState = notif.userInfo?[DinSupportNotificationKey.dinUDPCommunicationDeviceStateKey] as? DinDeviceControlNetworkState else {
            return
        }
        if networkState == .offline {
            connectComplete(networkState: .offline)
        } else if networkState == .online {
            connectComplete(networkState: .online)
        }
    }

    private func logoutControl() {
        // 获取camera的通讯id后，尝试新建通讯器
        let request = DinLiveStreamingRequest.logoutDevices(
            homeID: DinCore.user?.curHome?.id ?? "",
            deviceIDs: [device.id],
            providers: [deviceProvider]
        )
        DinHttpProvider.request(request, success: nil, fail: nil)
//        DinHttpProvider.request(request) { [weak self] result in
//        } fail: { error in
//            //
//        }
    }

    ///
    /// 如果检测不到通讯器，尝试请求服务器，获取通讯id来建立通讯器
    /// - Parameter complete: 用户调用连接ipc接口时的回调
    /// - Returns: 是否存在
    private func checkCommunicateControl() -> Bool {
        // ipc的沟通还是需要ipc的endid, 如果没有communicateControl，还是需要返回false
        if communicateControl == nil {
            // 如果有群组的通讯器，就不用重新登录e2e获取属于自己的end（注意这个不是ipc的endID)
            if group == nil {
                // 获取camera的通讯id后，尝试新建通讯器
                let request = DinLiveStreamingRequest.loginDevices(
                    homeID: DinCore.user?.curHome?.id ?? "",
                    deviceIDs: [device.id],
                    providers: [deviceProvider]
                )
                DinHttpProvider.request(request) { [weak self] result in
                    if let infoArr = result?["ipcs"] as? [[String: Any]] {
                        for info in infoArr {
                            if let pid = info["pid"] as? String,
                               // 这个endid是iOS的endid
                               let endid = info["end_id"] as? String,
                               // 组内通信秘钥
                               let commSecret = info["chat_secret"] as? String,
                               // 对组通讯秘钥
                               let groupSecret = info["end_secret"] as? String {
                                if pid == self?.device.id {
                                    // 先更新群组通讯器
                                    if self?.updateGroupCommunicator(withID: endid, commSecret: commSecret, groupSecret: groupSecret) ?? false {
                                        // 再更新IPC的通讯器
                                        self?.updateCameraCommunicator(withID: self?.group?.communicationIdentity.uniqueID ?? "",
                                                                       commSecret: commSecret) { [weak self] success in
                                            if success {
                                                // 先连接群组的通讯器，有结果再对目标做心跳
                                                self?.group?.connect(complete: { [weak self] _ in
                                                    self?.connectToCamera(ignoreConnectingState: true)
                                                })
                                            } else {
                                                self?.connectComplete(networkState: .offline)
                                            }
                                        }
                                    }
                                    return
                                }
                            }
                        }
                    }
                    self?.connectComplete(networkState: .offline)
                } fail: { [weak self] _ in
                    self?.connectComplete(networkState: .offline)
                }
            } else {
                // 仅仅更新IPC的通讯对象，群组对象不用动
                self.updateCameraCommunicator(withID: group?.communicationIdentity.uniqueID ?? "",
                                              commSecret: group?.communicationIdentity.communicateKey ?? "") { [weak self] success in
                    if success {
                        // 先连接群组的通讯器，有结果再对目标做心跳
                        self?.group?.connect(complete: { [weak self] _ in
                            self?.connectToCamera(ignoreConnectingState: true)
                        })
                    } else {
                        self?.connectComplete(networkState: .offline)
                    }
                }
            }
            return false
        }
        return true
    }

    /// 连接摄像头
    /// - Parameters:
    ///   - ignoreConnectingState: 忽略登录中的状态，继续请求
    ///   - ignoreOnlineState: 忽略在线的状态，继续请求
    ///   - discardCache: 重置摄像头的通讯相关信息，来重新连接
    func connectToCamera(ignoreConnectingState: Bool = false, ignoreOnlineState: Bool = false, discardCache: Bool = false) {
        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            if !ignoreOnlineState && !discardCache {
                // 如果在线的话，就直接返回在线
                guard self.device.networkState != .online else {
                    self.connectComplete(networkState: .online)
                    return
                }
            }
            if !ignoreConnectingState && !discardCache {
                // 如果在连接中，忽略
                guard self.device.networkState != .connecting else {
                    self.connectComplete(networkState: .connecting)
                    return
                }
            }

            // 连接中
            self.updateCameraNetworkStateIfChanged(.connecting, result: nil)
            if discardCache {
                // 如果是不管缓存，直接把通讯器置空，重新请求
                self.cleanCameraCommunicator()
                self.cleanGroupCommunicator()
                // 把kcp都关了先，再新建
                self.cleanAllKcpManagers()
                self.genKcpManagers()
                // 把camera的endid置空
                self.device.uniqueID = ""
            }
            // 检查是否有通讯类，如果没有请求
            guard self.checkCommunicateControl() else {
                return
            }
            // 首先需要connect msct
            self.communicateControl?.connect { [weak self] success in
                guard let self = self else {
                    return
                }
                if success {
                    self.connectComplete(networkState: .online)
                } else {
                    self.connectComplete(networkState: .offline)
                }
            }
        }
    }
    private func connectComplete(networkState: DinLiveStreaming.NetworkState) {
        updateCameraNetworkStateIfChanged(networkState) { [weak self] changed in
            guard let self = self else { return }
            if changed {
                if networkState == .offline {
                    // 如果离线了，所有kcp重置
                    self.cleanAllKcpManagers()
                } else if networkState == .online {
                    // 重新连接p2p
                    // 如果只有p2p连上了，代理和局域网都连不上，这个时候，也是收到在线的状态回调
                    // 所以这里如果又重新调用重连p2p就会马上把p2p设置成没有连接，导致重复回到这里，并且是已离线的，实际是断开了p2p在重新连接中
                    // 所以现在改成，如果p2p连上了，就补充连了，否则会出现自己断自己后路的尴尬
                    self.communicateControl?.refreshP2pPipeIfNeeded()
                }
                self.accept(deviceOnlineState: networkState == .online)
            }
            self.accept(deviceOperationResult: ["cmd": "connect", "status": 1, "connect_status": self.device.networkState.rawValue])
        }
    }

    func estab(withKcpSessionID sessionID: UInt16,
               channelID: UInt16,
               complete: ((Bool) -> Void)?) {
        // 需要唤醒ipc
//        self.group?.wake(withTargetID: self.communicateControl?.communicationDevice.uniqueID ?? "") { _ in
            // 成功之后需要建立kcp通道
        self.group?.establishKcpCommunication(withKcpSessionID: sessionID, channelID: channelID, kcpTowardsID: device.uniqueID, success: { _ in
                complete?(true)
            }, fail: { _ in
                complete?(false)
            }, timeout: { _ in
                complete?(false)
            })
//        } fail: { _ in
//            complete?(false)
//        } timeout: { _ in
//            complete?(false)
//        }
    }
    

    public func disconnect() {
//        group?.resignKcpCommunication(withKcpSessionID: kcpSessionID, success: nil, fail: nil, timeout: nil)
//        for commObject in commObjects.values {
//            commObject.kcpObject.stopReceiving()
//        }
//        commObjects.removeAll()
        cleanAllKcpManagers()
        logoutControl()
        updateCameraNetworkStateIfChanged(.offline, result: nil)
        accept(deviceOnlineState: false)
        self.cleanCameraCommunicator()
        self.cleanGroupCommunicator()
    }

    /// 更新当前状态
    /// - Parameter state: 摄像头状态
    /// - Returns: 是否和原状态相同
    private func updateCameraNetworkStateIfChanged(_ state: DinLiveStreaming.NetworkState, result: ((Bool)->())?) {
        if device.networkState != state {
            // 状态有变化，先修改Info，再提交数据
            updateNetworkState(state, usingSync: false) { [weak self] in
                guard let self = self else { return }
                self.accept(deviceOperationResult: ["cmd": "connect_status_changed", "connect_status": self.device.networkState.rawValue])
                result?(true)
            }
        } else {
            // 状态没有变化，直接返回判断
            result?(false)
        }
    }
}

extension DinLiveStreamingControl: DinUDPGroupControlDelegate {
    // ipc群组通知
    func control(_ control: DinUDPGroupControl, receivedGroupNotifyInfo info: [String : Any]) {
        // 在自研IPC1.0.0以前的版本，出现了一个比较严重的问题，IPC的唯一id会出现重复，为了修复这个问题，服务器、客户端和自研IPC统一改成 "原ID_XXXX"。
        // 所以0.9.15版本强制升级1.0.0版本的时候会出现，客户端持有 "原ID" 的自研IPC对象请求并且监控IPC的升级，但是当IPC升级完成后，会变成 "原ID_XXXX" 来连接服务器。
        // 这时候客户端就不能和升级好的IPC通讯了（ID和EndID都变了），所以在收到 "member-online" 的指令后，通过新版"原ID_XXXX" 里面截取出来的 "原ID" 对比，改变当前对象下面的ID，重新连接就可以重新通讯了。
        // 在改变替换原对象之后（DinLiveStreamingControl里面的private(set) var device: DinLiveStreaming），会推送这个消息上去，上层收到推送会调用对应的清除缓存重新连接的，所以这里只需要更改对应的device对象即可
        if info["cmd"] as? String == "member-online",
            let memberID = (info["members"] as? [[String: Any]])?.first?["member"] as? String,
            !memberID.isEmpty {
#if ENABLE_LOG
            if #available(iOS 14.0, *) {
                DinCoreLogger.msctNotification.debug("DinLiveStreamingControl receivedGroupNotifyInfo => \(info)")
            }
#endif
            // "member-online"的群主消息
            var shortID = ""
            // 看看id是不是新id（自研IPC1.0.0版本之后的ID），同时当前ID是1.0.0之前的短的ID（原ID）
            if memberID.contains("_"),
                !(communicateControl?.communicationDevice.deviceID.contains("_") ?? false) {
                // 获取新版"原ID_XXXX" 里面截取出来的 "原ID" 作对比
                shortID = memberID.components(separatedBy: "_").first ?? ""
                if shortID == communicateControl?.communicationDevice.deviceID {
                    // 成功的话替换原对象，等待重新连接
                    let newDevice = DinCamera()
                    newDevice.id = memberID
                    newDevice.name = device.name
                    newDevice.groupID = device.groupID
                    device = newDevice
                }
            }

        }
        // 推送出去
        DinCore.cameraDelegate?.dinCoreCameraDidReceiveGroupNotification(info)
    }
}

//extension DinLiveStreamingControl {
//    private func createKcpComm(withType type: DinKcpType) -> DinCameraKcpObject? {
//        let commObj = DinCameraKcpObject(withKcpType: type) { [weak self] outpuData in
//            self?.communicateControl?.sendKcpData(outpuData)
//            return 0
//        }
//        commObj?.kcpObject.delegate = self
//        return commObj
//    }
//
//    func createHDVideoKcp() {
//        guard hdComm == nil else {
//            return
//        }
//        // 高清视频流
//        hdComm = createKcpComm(withType: .hd)
//        if let kcpComm = hdComm {
//            commObjects[kcpComm.convString] = kcpComm
//        }
//    }
//
//    func createSTDVideoKcp() {
//        guard stdComm == nil else {
//            return
//        }
//        // 标清视频流
//        stdComm = createKcpComm(withType: .std)
//        if let kcpComm = stdComm {
//            commObjects[kcpComm.convString] = kcpComm
//        }
//    }
//
//    func createAudioKcp() {
//        guard audioComm == nil else {
//            return
//        }
//        // 收听音频流
//        audioComm = createKcpComm(withType: .audio)
//        if let kcpComm = audioComm {
//            commObjects[kcpComm.convString] = kcpComm
//        }
//    }
//
//    func createTalkKcp() {
//        guard talkComm == nil else {
//            return
//        }
//        // 讲话音频流
//        talkComm = createKcpComm(withType: .talk)
//        if let kcpComm = talkComm {
//            commObjects[kcpComm.convString] = kcpComm
//        }
//    }
//
//    func createCMDKcp() {
//        guard cmdComm == nil else {
//            return
//        }
//        // 指令
//        cmdComm = createKcpComm(withType: .jsonCmd)
//        if let kcpComm = cmdComm {
//            commObjects[kcpComm.convString] = kcpComm
//        }
//    }
//    func stopLiveClock() {
//        cmdKcpTimer = nil
//    }
//
//    func createGetPicKcp() {
//        guard getPicComm == nil else {
//            return
//        }
//        // 指令
//        getPicComm = createKcpComm(withType: .getPic)
//        if let kcpComm = getPicComm {
//            commObjects[kcpComm.convString] = kcpComm
//        }
//    }
//}
