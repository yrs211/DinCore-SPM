//
//
//  DinStorageBatteryControl.swift
//  DinCore
//
//  Created by monsoir on 11/29/22.
//

import Foundation
import RxSwift
import RxRelay
import DinSupport
import Moya

class DinStorageBatteryControl: NSObject {

    private(set) var communicateControl: DinStorageBatteryUDPControl?

    private var group: DinUDPGroupControl?

    private(set) var model: DinStorageBattery

    private let homeID: String

    var provider: String { "" }

    ///解析器
    var parser: DinStorageBatteryPayloadParser { fatalError("Implement in subclass") }

    private var onGoingMSCTCommands: Set<MSCTCommandMessageID> = []
    private var onGoingHTTPCommands: Set<DinStorageBatteryHTTPCommand> = []

    private var onGoingMSCTCommandUserInfo: [MSCTCommandMessageID: MSCTCommandUserInfo] = [:]
    private var onGoingMSCTCommandsMap: [MSCTCommandMessageID: MSCTCommand] = [:]

    lazy var unsafeInfo: [String: Any] = newInfo
    var info: [String: Any]? {
        var tempInfo: [String: Any]? = [:]
        DinUser.homeDeviceInfoQueue.sync { [weak self] in
            if let self = self {
                tempInfo = self.unsafeInfo
            }
        }
        return tempInfo
    }

    /// 这里注意下，最好使用 static let，不然可能会出现「内存重用」的情况，虽然概率极小
    /// 即其他地方的 DispatchSpecificKey 被释放，新建的 DispatchSpecificKey 实例可能会分配在它的同一内存位置的
    /// https://tom.lokhorst.eu/2018/02/leaky-abstractions-in-swift-with-dispatchqueue
    /// Keys are only compared as pointers and are never dereferenced.
    /// https://developer.apple.com/documentation/dispatch/1452967-dispatch_queue_set_specific
    private static let acceptDataQueueToken = DispatchSpecificKey<Void>()
    private let acceptDataQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "com.dinsafer.dincore.queue.storage-battery.dataAccepct")
        queue.setSpecific(key: acceptDataQueueToken, value: ())
        return queue
    }()
    private var onAcceptDataQueue: Bool {
        DispatchQueue.getSpecific(key: Self.acceptDataQueueToken) != nil
    }

    // MARK: - 配件（主动操作/第三方操作）数据通知
    var deviceCallback: Observable<[String : Any]> {
        return deviceOperationResult.asObservable()
    }
    private let deviceOperationResult = PublishRelay<[String: Any]>()
    /// 设备（主动操作/第三方操作）数据通知
    /// - Parameter result: 结果
    func accept(deviceOperationResult result: [String: Any]) {
        if onAcceptDataQueue {
            deviceOperationResult.accept(result)
        } else {
            acceptDataQueue.async { [weak self] in
                self?.deviceOperationResult.accept(result)
            }
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

    private let disposeBag = DisposeBag()

    init(model: DinStorageBattery, homeID: String) {
        self.model = model
        self.homeID = homeID
       
        super.init()

        DinCore.eventBus.storageBattery.lanIPReceivedObservable.subscribe(onNext: { [weak self] cameraID in
            guard let self = self else { return }

            if cameraID == self.model.id {
                self.communicateControl?.refreshLanPipe(
                    ipAdress: self.model.lanAddress,
                    port: self.model.lanPort
                )
            }
        }).disposed(by: disposeBag)

        DinCore.eventBus.basic.proxyDeliverChangedObservable.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.acceptDataQueue.async { [weak self] in
                guard let self = self else { return }
                if self.model.networkState != .offline {
                    self.connect(discardCache: true)
                }
            }
        }).disposed(by: disposeBag)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveNetworkState(_:)),
            name: .dinDeviceNetworkState, object: nil
        )

        updateInfoDict(complete: nil)
    }

    @objc
    private func receiveNetworkState(_ notif: Notification) {
        guard let device = notif.userInfo?[DinSupportNotificationKey.dinUDPCommunicationDeviceKey] as? DinStorageBattery,
              device == self.model else {
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

    public func updateCommunicator(withID commID: String, commSecret: String, complete: ((Bool)->())?) {
        guard commID.count > 0 else {
            complete?(false)
            return
        }
        let user = DinGroupCommunicator(withUniqueID: commID, groupID: model.groupID, commSecret: commSecret)

        // 如果有通讯EndID就不用请求服务器了
        if model.uniqueID.count > 0 {
            if genCommunicator(user: user) {
                complete?(true)
            } else {
                complete?(false)
            }
        } else {
            typealias Condition = DinStorageBatteryRequest.SearchDeviceParameters.Condition
            let parameters = DinStorageBatteryRequest.SearchDeviceParameters(homeID: homeID,
                                                                             conditions: [Condition(deviceID: model.deviceID,
                                                                                                    model: provider)])
            let request = DinStorageBatteryRequest.getDevicesEndid(parameters)
            DinHttpProvider.request(request) { [weak self] result in
                if let camerasArr = result?["bmts"] as? [[String: Any]], camerasArr.count > 0 {
                    if self?.model.id == camerasArr.first?["id"] as? String,
                       let camEndID = camerasArr.first?["end_id"] as? String,
                       camEndID.count > 0 {
                        self?.model.uniqueID = camEndID
                        if self?.genCommunicator(user: user) ?? false {
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

    private func genCommunicator(user: DinGroupCommunicator) -> Bool {
        guard let deliver = DinCore.proxyDeliver, model.uniqueID.count > 0 else { return false }
        let control = DinStorageBatteryUDPControl(
            with: deliver,
            communicationDevice: model,
            communicationIdentity: user,
            dataEncryptor: DinChannelEncryptor(withSecret: user.commSecret)
        )
        control.delegate = self
        communicateControl = control
        return true
    }

    private func cleanCommunicator() {
        self.cancelOnGoingMSCTCommands()
        self.communicateControl?.disconnect()
        self.communicateControl?.delegate = nil
        self.communicateControl = nil
    }
    
    private func cancelOnGoingMSCTCommands() {
        onGoingMSCTCommands.forEach { messageID in
            if let command = onGoingMSCTCommandsMap[messageID] as? DinStorageBatteryMSCTCommand {
                let failureResult = Result<Data, Error>.failure(DinStorageBatteryUDPControl.TimeoutFailure())
                processCommandResult(command: command, messageID: messageID, result: failureResult)
            }
        }
    }

    public func updateGroupCommunicator(withID commID: String, commSecret: String, groupSecret: String) -> Bool {
        guard commID.count > 0 else {
            return false
        }
        let communicationGroup = DinCommunicationGroup(withGroupID: model.groupID, groupSecret: groupSecret)
        let user = DinGroupCommunicator(withUniqueID: commID, groupID: model.groupID, commSecret: commSecret)
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

    private func logoutControl() {
        // 获取BMT的通讯id后，尝试新建通讯器
        let paramters = DinStorageBatteryRequest.LogoutDevicesParameters(
            homeID: homeID,
            devices: [.init(id: model.id, model: model.model)],
            models: [DinStorageBattery.provider]
        )
        let request = DinStorageBatteryRequest.logoutDevices(paramters)

        DinHttpProvider.request(request, success: nil, fail: nil)
//        DinHttpProvider.request(request) { [weak self] result in
//        } fail: { error in
//            //
//        }

    }


    private func checkCommunicateControl() -> Bool {
        // ipc的沟通还是需要ipc的endid, 如果没有communicateControl，还是需要返回false
        if communicateControl == nil {
            // 如果有群组的通讯器，就不用重新登录e2e获取属于自己的end（注意这个不是ipc的endID)
            if group == nil {
                // 获取BMT的通讯id后，尝试新建通讯器
                let paramters = DinStorageBatteryRequest.LoginDevicesParameters(
                    homeID: homeID,
                    devices: [.init(id: model.id, model: model.model)],
                    models: [DinStorageBattery.provider]
                )
                let request = DinStorageBatteryRequest.loginDevices(paramters)
                DinHttpProvider.request(request) { [weak self] result in
                    if let infoArr = result?["e2es"] as? [[String: Any]] {
                        for info in infoArr {
                            if let pid = info["id"] as? String,
                               // 这个endid是iOS的endid
                               let endid = info["end_id"] as? String,
                               // 组内通信秘钥
                               let commSecret = info["chat_secret"] as? String,
                               // 对组通讯秘钥
                               let groupSecret = info["end_secret"] as? String {
                                if pid == self?.model.id {
                                    // 先更新群组通讯器
                                    if self?.updateGroupCommunicator(withID: endid, commSecret: commSecret, groupSecret: groupSecret) ?? false {
                                        // 再更新IPC的通讯器
                                        self?.updateCommunicator(withID: self?.group?.communicationIdentity.uniqueID ?? "",
                                                                 commSecret: commSecret) { [weak self] success in
                                            if success {
                                                self?.group?.connect(complete: { [weak self] _ in
                                                    self?.connect(ignoreConnectingState: true)
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
                self.updateCommunicator(
                    withID: group?.communicationIdentity.uniqueID ?? "",
                    commSecret: group?.communicationIdentity.communicateKey ?? ""
                ) { [weak self] success in
                    if success {
                        self?.connect(ignoreConnectingState: true)
                    } else {
                        self?.connectComplete(networkState: .offline)
                    }
                }
            }
            return false
        }
        return true
    }

    func connect(ignoreConnectingState: Bool = false, ignoreOnlineState: Bool = false, discardCache: Bool = false) {
        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            if !ignoreOnlineState && !discardCache {
                // 如果在线的话，就直接返回在线
                guard self.model.networkState != .online else {
                    self.connectComplete(networkState: .online)
                    return
                }
            }
            if !ignoreConnectingState && !discardCache {
                // 如果在连接中，忽略
                guard self.model.networkState != .connecting else {
                    self.connectComplete(networkState: .connecting)
                    return
                }
            }

            // 连接中
            self.updateNetworkStateIfChanged(.connecting, result: nil)
            if discardCache {
                // 如果是不管缓存，直接把通讯器置空，重新请求
                self.cleanCommunicator()
                self.cleanGroupCommunicator()
                // 把kcp都关了先，再新建
//                self.cleanAllKcpManagers()
//                self.genKcpManagers()
                // 把camera的endid置空
                self.model.uniqueID = ""
            }
            // 检查是否有通讯类，如果没有请求
            guard self.checkCommunicateControl() else { return }
            // 首先需要connect msct
            self.communicateControl?.connect { [weak self] success in
                guard let self = self else { return }
                if success {
                    self.connectComplete(networkState: .online)
                } else {
                    self.connectComplete(networkState: .offline)
                }
            }
        }
    }

    private func connectComplete(networkState: DinStorageBattery.NetworkState) {
        updateNetworkStateIfChanged(networkState) { [weak self] changed in
            guard let self = self else { return }
            if changed {
                if networkState == .offline {
                    // 如果离线了，所有kcp重置
    //                self.cleanAllKcpManagers()
                } else if networkState == .online {
                    // 重新连接p2p
                    // 如果只有p2p连上了，代理和局域网都连不上，这个时候，也是收到在线的状态回调
                    // 所以这里如果又重新调用重连p2p就会马上把p2p设置成没有连接，导致重复回到这里，并且是已离线的，实际是断开了p2p在重新连接中
                    // 所以现在改成，如果p2p连上了，就补充连了，否则会出现自己断自己后路的尴尬
                    self.communicateControl?.refreshP2pPipeIfNeeded()
                }
                // 如果状态改变了，回调
                self.accept(deviceOnlineState: networkState == .online)
            }
            self.accept(deviceOperationResult: ["cmd": "connect", "status": 1, "connect_status": self.model.networkState.rawValue])
        }
    }

    public func disconnect() {
        logoutControl()
        updateNetworkStateIfChanged(.offline, result: nil)
        accept(deviceOnlineState: false)
        self.cleanCommunicator()
        self.cleanGroupCommunicator()
    }

    private func updateNetworkStateIfChanged(_ state: DinStorageBattery.NetworkState, result: ((Bool)->())?) {
        DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            if model.networkState != state {
                // 状态有变化，先修改Info，再提交数据
                let previousState = model.networkState
                self.updateNetworkState(state, usingSync: true, complete: nil)
                self.accept(deviceOperationResult: ["cmd": "connect_status_changed",
                                                    "connect_status": self.model.networkState.rawValue,
                                                    "previous_status": previousState.rawValue])
                DispatchQueue.global().async {
                    result?(true)
                }
            } else {
                DispatchQueue.global().async {
                    // 状态没有变化，直接返回判断
                    result?(false)
                }
            }
        }
    }

    func rename(_ actionDict: [String: Any]) {
        let command: DinStorageBatteryHTTPCommand = .rename

        guard let name = actionDict["name"] as? String else {
            accept(deviceOperationResult: HTTPCommandBadRequestFailure(command: command).result)
            return
        }

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let params = DinStorageBatteryRequest.RenameParameters(homeID: self.homeID,
                                                                   deviceID: self.model.deviceID,
                                                                   model: self.provider,
                                                                   name: name)
            let request = DinStorageBatteryRequest.rename(params)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }
                    // 改名成功不会有result的
                    self.rename(name, command: command, complete: nil)
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }

    func rename(_ name: String, command: DinStorageBatteryHTTPCommand, complete: (()->())?) {
        updateName(name, usingSync: false) { [weak self] in
            guard let self = self else { return }
            self.acceptDataQueue.async { [weak self] in
                guard let self = self else { return }
                self.onGoingHTTPCommands.remove(command)
                self.deviceOperationResult.accept(
                    HTTPCommandSuccessfulResponse(
                        command: command,
                        payload: [:]
                    ).result
                )
                complete?()
            }
        }
    }

    func getInverterInputInfo() {
        execute(msctCommand: .getInverterInputInfo)
    }

    func getInverterOutputInfo() {
        execute(msctCommand: .getInverterOutputInfo)
    }

    final
    func resetInverter() {
        execute(msctCommand: .resetInverter)
    }

    final
    func getInverterInfo(at indexOrNil: Int?) {
        let command: DinStorageBatteryMSCTCommand = .getInverterInfoByIndex

        guard let index = indexOrNil, 0...2 ~= index  else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }

        execute(msctCommand: command, data: Data([UInt8(bitPattern: Int8(index))]))
    }

    final
    func getBatteryAccessoryState(at indexOrNil: Int?) {
        let command: DinStorageBatteryMSCTCommand = .getBatteryAccessoryStateByIndex

        guard let index = indexOrNil else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }

        execute(msctCommand: command, data: Data([UInt8(index)]))
    }

    func getBatteryAllInfo() {
        execute(msctCommand: .batchGetBatteryInfo)
    }

    func batchTurnOffBattery() {
        execute(msctCommand: .batchTurnOffBattery, data: Data([0xff]))
    }

    func getBatteryInfo(at indexOrNil: Int?) {
        let command: DinStorageBatteryMSCTCommand = .getBatteryInfoByIndex

        guard let index = indexOrNil else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }

        let data = Data([UInt8(bitPattern: Int8(index))])
        execute(msctCommand: command, data: data)
    }

    func getGlobalLoadState() {
        execute(msctCommand: .getGlobalLoadState)
    }

    func getGlobalExceptions() {
        execute(msctCommand: .getGlobalExceptions)
    }
    
    func getGlobalDisplayExceptions() {
        execute(msctCommand: .getGlobalDisplayExceptions)
    }

    func getMCUInfo() {
        execute(msctCommand: .getMCUInfo)
    }

    func getCaninetState(at indexOrNil: Int?) {
        let command: DinStorageBatteryMSCTCommand = .getCabinetStateByIndex

        guard let index = indexOrNil else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }

        execute(msctCommand: command, data: Data([index.uint8]))
    }

    func getMPPTState() {
        let command: DinStorageBatteryMSCTCommand = .getMPPTState
        execute(msctCommand: command)
    }

    func getEVState() {
        execute(msctCommand: .getEVState)
    }

    func getCabinetInfo() {
        execute(msctCommand: .getCabinetInfo)
    }

    func getEmergencyChargeSettings() {
        execute(msctCommand: .getEmergencyChargingSettings)
    }

    func setEmergencyCharging(isOn: Bool?, startTime: UInt32?, endTime: UInt32?) {
        let command: DinStorageBatteryMSCTCommand = .setEmergencyCharging

        guard let isOn = isOn, let startTime = startTime, let endTime = endTime else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }

        var data = Data([isOn ? 0x01 : 0x00])
        data.append(startTime.littleEndianData)
        data.append(endTime.littleEndianData)
        execute(msctCommand: command, data: data)
    }
    
    func getGridChargeMargin() {
        execute(msctCommand: .getGridChargeMargin)
    }

    func setChargeStrategy(
        strategyType: Int?,
        smartReserve: Int?,
        goodPricePercentage: Int?,
        emergencyReserve: Int?,
        acceptablePricePercentage: Int?
    ) {
        let command: DinStorageBatteryMSCTCommand = .setChargingStrategies

        guard
            let strategtyType = strategyType, let strategy = DinStorageBatteryCharingStrategy(rawValue: strategtyType),
            let smartReserve = smartReserve,
            let goodPricePercentage = goodPricePercentage,
            let emergencyReserve = emergencyReserve,
            let acceptablePricePercentage = acceptablePricePercentage
        else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }

        var goodPricePercentage16 = UInt16(goodPricePercentage >= 0 ? goodPricePercentage : 1111)
        let goodData = Data(bytes: &goodPricePercentage16, count: MemoryLayout.size(ofValue: goodPricePercentage16))
        var acceptablePricePercentage16 = UInt16(acceptablePricePercentage >= 0 ? acceptablePricePercentage : 1111)
        let acceptableData = Data(bytes: &acceptablePricePercentage16, count: MemoryLayout.size(ofValue: acceptablePricePercentage16))

        var data = Data()
        data.append(strategy.byte)
        data.append(smartReserve.uint8)
        data.append(emergencyReserve.uint8)
        data.append((goodPricePercentage == -1 || goodPricePercentage > 1000) ? 0x00 : 0x01)
        data.append(contentsOf: goodData)         // 大于1000，为任何价格都可以充电，对应界面ignore
        data.append((acceptablePricePercentage == -1 || acceptablePricePercentage > 1000) ? 0x00 : 0x01)
        data.append(contentsOf: acceptableData)   // 大于1000，为任何价格都可以充电，对应界面ignore
        execute(msctCommand: command, data: data)
    }

    func getChargingStrategies() {
        execute(msctCommand: .getChargingStrategies)
    }

    func setVirtualPowerPlant(userID: String?, isOn: Bool?) {
        let command: DinStorageBatteryMSCTCommand = .setVirtualPowerPlant
        guard
            let isOn = isOn,
            let userID = userID
        else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }
        var data = Data([isOn ? 0x01 : 0x00])
        
        let parameterStrings = [userID]

        // 循环遍历数组，检查长度后再添加到数据中
        for string in parameterStrings {
            guard !string.isEmpty, let stringData = string.data(using: .utf8) else {
                accept(error: MSCTCommandBadRequestFailure(command: command))
                return
            }

            let stringDataLength = stringData.count
            guard stringDataLength >= 0 && stringDataLength <= Int(UInt8.max) else {
                // 字符串超过长度失败
                accept(error: MSCTCommandBadRequestFailure(command: command))
                return
            }

            // 将字符串长度和字符串数据添加到 data 中
            data.append(UInt8(truncatingIfNeeded: stringDataLength))
            data.append(stringData)
        }
        
        execute(msctCommand: command, data: data)
    }

    func getVirtualPowerPlant() {
        execute(msctCommand: .getVirtualPowerPlant)
    }
    
    func setSellingProtection(isOn: Bool?, threshold: Int?) {
        let command = DinStorageBatteryMSCTCommand.setSellingProtection
        guard let isOn, let threshold else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }
        var data = Data([isOn.byte])
        data.append(threshold.littleEndianData)
        execute(msctCommand: .setSellingProtection, data: data)
    }
    
    func getSellingProtection() {
        execute(msctCommand: .getSellingProtection)
    }

    func getSignals() {
        execute(msctCommand: .getSignals)
    }

    func resetDevice() {
        execute(msctCommand: .reset)
    }

    func rebootDevice() {
        execute(msctCommand: .reboot)
    }

    func getAdvanceInfo() {
        execute(msctCommand: .getAdvanceInfo)
    }

    func setGlobalLoaderOpen(_ open: Bool?) {
        let command: DinStorageBatteryMSCTCommand = .setGlobalLoaderOpen
        guard let open = open else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }
        let data = Data([open ? 0x00 : 0x01])
        execute(msctCommand: command, data: data)
    }

    func getMode() {
        execute(msctCommand: .getMode)
    }
    
    func getModeV2() {
        execute(msctCommand: .getModeV2)
    }

    func getChipsStatus() {
        execute(msctCommand: .getChipsStatus)
    }

    func getChipsUpdateProgress() {
        execute(msctCommand: .getChipsUpdateProgress)
    }

    func updateChips() {
        execute(msctCommand: .updateChips)
    }

    func getCurrentReserveMode() {
        execute(msctCommand: .getCurrentReserveMode)
    }

    func getPriceTrackReserveMode() {
        execute(msctCommand: .getPriceTrackReserveMode)
    }

    func getScheduleReserveMode() {
        execute(msctCommand: .getScheduleReserveMode)
    }
    
    func getCustomScheduleMode() {
        execute(msctCommand: .getCustomScheduleMode)
    }

    func setReserveMode(_ mode: Int?, smart: Int?, emergency: Int?, weekdays: [Int]?, weekends: [Int]?, sync: Bool?, type: Int?) {
        let command: DinStorageBatteryMSCTCommand = .setReserveMode

        guard
            let mode = mode,
            let reserveMode = DinStorageBatteryReserveMode(rawValue: mode),
            let smart = smart,
            let emergency = emergency,
            let sync = sync,
            let type = type
        else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }

        var data = Data()
        data.append(reserveMode.byte)
        data.append((mode == 2 || mode == 3) && (weekdays == nil) && (weekends == nil) ? 0x01 : 0x00)
        data.append(smart.uint8)
        data.append(emergency.uint8)
        if let weekdays = weekdays {
            weekdays.forEach { data.append($0.uint8) }
        } else {
            for _ in 0..<24 {
                data.append(0x00)
            }
        }
        if let weekends = weekends {
            weekends.forEach { data.append($0.uint8) }
        } else {
            for _ in 0..<24 {
                data.append(0x00)
            }
        }
        data.append(sync ? 0x01 : 0x00)
        data.append(type.uint8)
        
        execute(msctCommand: command, data: data)
    }
    
    func getCustomScheduleModeAI() {
        execute(msctCommand: .getCustomScheduleModeAI)
    }
    
    func setReserveModeAi(smart: Int?, emergency: Int?, chargeDischargeData: [Int]?, type: Int?) {
        let command: DinStorageBatteryMSCTCommand = .setReserveModeAI

        guard
            let smart = smart,
            let emergency = emergency,
            let chargeDischargeData = chargeDischargeData,
            let type = type
        else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }

        var data = Data()
        data.append(smart.uint8)
        data.append(emergency.uint8)
        data.append(type.uint8)
        data.append(chargeDischargeData.count.uint8)
        chargeDischargeData.forEach { data.append($0.uint8) }
        
        execute(msctCommand: command, data: data)
    }

    func getCurrentEVChargingMode() {
        execute(msctCommand: .getCurrentEVChargingMode)
    }

    func getEVChargingModeSchedule() {
        execute(msctCommand: .getEVChargingModeSchedule)
    }

    func setEVChargingMode(_ mode: Int?, weekdays: [Int]?, weekends: [Int]?, sync: Bool?) {
        let command: DinStorageBatteryMSCTCommand = .setEVChargingMode

        guard
            let mode = mode,
            let evChargingMode = DinStorageBatteryEVChargingMode(rawValue: mode),
            weekdays == nil || (weekdays?.count ?? 0 == 24),
            weekends == nil || (weekends?.count ?? 0 == 24),
            let sync = sync
        else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }

        var data = Data()
        data.append(evChargingMode.byte)
        data.append((evChargingMode == .scheduled) && (weekdays == nil) && (weekends == nil) ? 0x01 : 0x00)
        if let weekdays = weekdays, weekdays.count >= 24 {
            data.append(parser.combineBitsIntoUInt8(Array(weekdays[0...7])) ?? 0x00)
            data.append(parser.combineBitsIntoUInt8(Array(weekdays[8...15])) ?? 0x00)
            data.append(parser.combineBitsIntoUInt8(Array(weekdays[16...23])) ?? 0x00)
        } else {
            for _ in 0..<3 {
                data.append(0x00)
            }
        }
        if let weekends = weekends, weekends.count >= 24 {
            data.append(parser.combineBitsIntoUInt8(Array(weekends[0...7])) ?? 0x00)
            data.append(parser.combineBitsIntoUInt8(Array(weekends[8...15])) ?? 0x00)
            data.append(parser.combineBitsIntoUInt8(Array(weekends[16...23])) ?? 0x00)
        } else {
            for _ in 0..<3 {
                data.append(0x00)
            }
        }
        data.append(sync ? 0x01 : 0x00)
        execute(msctCommand: command, data: data)
    }
    
    func setEVChargingModeInstant(_ mode: Int?, fixed: Int?) {
        let command: DinStorageBatteryMSCTCommand = .setEVChargingModeInstant

        guard
            let mode = mode,
            let evChargingMode = DinStorageBatteryEVChargingMode(rawValue: mode),
            let fixed = fixed
        else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }

        var data = Data()
        data.append(evChargingMode.byte)
        
        var ignoreFixed = fixed < 0
        
        data.append(ignoreFixed ? 0x01 : 0x00)
        
        var fixed16 = UInt16(ignoreFixed ? 0 : fixed)
        let fixedData = Data(bytes: &fixed16, count: MemoryLayout.size(ofValue: fixed16))
        
        data.append(fixedData)
        
        execute(msctCommand: command, data: data)
    }

    func setEvchargingModeInstantcharge(_ open: Bool?) {
        let command: DinStorageBatteryMSCTCommand = .setEvchargingModeInstantcharge
        guard let open = open else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }
        let data = Data([open ? 0x01 : 0x00])
        execute(msctCommand: command, data: data)
    }

    func getCurrentEVAdvancestatus() {
        execute(msctCommand: .getCurrentEVAdvanceStatus)
    }

    func getEVChargingInfo() {
        execute(msctCommand: .getEVChargingInfo)
    }
    
    func getSmartEvStatus() {
        execute(msctCommand: .getSmartEvStatus)
    }
    
    func setSmartEvStatus(toggleStatus: Int?, requestRestart: Bool?) {
        
        let command: DinStorageBatteryMSCTCommand = .setSmartEvStatus
        guard
            let toggleStatus = toggleStatus,
            let smartEVToggleStatus = DinStorageBatterySmartEVToggleStatus(rawValue: toggleStatus),
            let requestRestart = requestRestart
        else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }
        var data = Data()
        data.append(smartEVToggleStatus.byte)
        data.append(requestRestart ? 0x01 : 0x00)
        execute(msctCommand: command, data: data)
    }

    func setRegion(isPriceTrackingSupported: Bool?, countryCode: String?, countryName: String?, cityName: String?, timezone: String?, deliveryArea: String?) {
        let command: DinStorageBatteryMSCTCommand = .setRegion

        guard let isPriceTrackingSupported = isPriceTrackingSupported,
              let countryCode = countryCode,
              let countryName = countryName,
              let cityName = cityName,
              let timezone = timezone,
              let deliveryArea = deliveryArea
        else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }

        var data = Data([isPriceTrackingSupported ? 0x01 : 0x00])
        let parameterStrings = [countryCode, countryName, cityName, timezone, deliveryArea]

        // 循环遍历数组，检查长度后再添加到数据中
        for string in parameterStrings {
            if string.isEmpty { // cityName, deliveryArea可能为空字符串
                data.append(UInt8(truncatingIfNeeded: 0))
            } else {
                guard let stringData = string.data(using: .utf8) else {
                    accept(error: MSCTCommandBadRequestFailure(command: command))
                    return
                }

                let stringDataLength = stringData.count
                guard stringDataLength >= 0 && stringDataLength <= Int(UInt8.max) else {
                    // 字符串超过长度失败
                    accept(error: MSCTCommandBadRequestFailure(command: command))
                    return
                }

                // 将字符串长度和字符串数据添加到 data 中
                data.append(UInt8(truncatingIfNeeded: stringDataLength))
                data.append(stringData)
            }
        }
        execute(msctCommand: command, data: data, compensationUserInfo: SetRegionUserInfo.init(countryCode: countryCode, deliveryArea: deliveryArea))
    }

    func setExceptionIgnore(_ exception: Int?) {
        let command: DinStorageBatteryMSCTCommand = .setExceptionIgnore
        guard let exception = exception else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }
        var data = Data()
        data.append(exception.uint8)
        execute(msctCommand: command, data: data)
    }

    func getGlobalCurrentFlowInfo(_ dataMode: UInt8?) {
        var data = Data()
        data.append(dataMode ?? 0x00)
        execute(msctCommand: .getGlobalCurrentFlowInfo, data: data)
    }
    
    func getGridConnectionConfig() {
        execute(msctCommand: .getGridConnectionConfig)
    }
    
    func updateGridConnectionConfig(
        powerPercent: Float?,
        appFastPowerDown: Bool?,
        quMode: Bool?,
        cosMode: Bool?,
        antiislandingMode: Bool?,
        highlowMode: Bool?,
        activeSoftStartRate: Float?,
        overfrequencyLoadShedding: Float?,
        overfrequencyLoadSheddingSlope: Float?,
        underfrequencyLoadShedding: Float?,
        underfrequencyLoadSheddingSlope: Float?,
        powerFactor: Float?,
        reconnectTime: Float?,
        gridOvervoltage1: Float?,
        gridOvervoltage1ProtectTime: Float?,
        gridOvervoltage2: Float?,
        gridOvervoltage2ProtectTime: Float?,
        gridUndervoltage1: Float?,
        gridUndervoltage1ProtectTime: Float?,
        gridUndervoltage2: Float?,
        gridUndervoltage2ProtectTime: Float?,
        gridOverfrequency1: Float?,
        gridOverfrequencyProtectTime: Int?,
        gridOverfrequency2: Float?,
        gridUnderfrequency1: Float?,
        gridUnderfrequencyProtectTime: Int?,
        gridUnderfrequency2: Float?,
        reconnectSlope: Float?,
        rebootGridOvervoltage: Float?,
        rebootGridUndervoltage: Float?,
        rebootGridOverfrequency: Float?,
        rebootGridUnderfrequency: Float?
    ) {
        let command: DinStorageBatteryMSCTCommand = .updateGridConnectionConfig
        guard
            let powerPercent = powerPercent,
            let appFastPowerDown = appFastPowerDown,
            let quMode = quMode,
            let cosMode = cosMode,
            let antiislandingMode = antiislandingMode,
            let highlowMode = highlowMode,
            let activeSoftStartRate = activeSoftStartRate,
            let overfrequencyLoadShedding = overfrequencyLoadShedding,
            let overfrequencyLoadSheddingSlope = overfrequencyLoadSheddingSlope,
            let underfrequencyLoadShedding = underfrequencyLoadShedding,
            let underfrequencyLoadSheddingSlope = underfrequencyLoadSheddingSlope,
            let powerFactor = powerFactor,
            let reconnectTime = reconnectTime,
            
            let gridOvervoltage1 = gridOvervoltage1,
            let gridOvervoltage1ProtectTime = gridOvervoltage1ProtectTime,
            let gridOvervoltage2 = gridOvervoltage2,
            let gridOvervoltage2ProtectTime = gridOvervoltage2ProtectTime,
            let gridUndervoltage1 = gridUndervoltage1,
            let gridUndervoltage1ProtectTime = gridUndervoltage1ProtectTime,
            let gridUndervoltage2 = gridUndervoltage2,
            let gridUndervoltage2ProtectTime = gridUndervoltage2ProtectTime,
            
            let gridOverfrequency1 = gridOverfrequency1,
            let gridOverfrequencyProtectTime = gridOverfrequencyProtectTime,
            let gridOverfrequency2 = gridOverfrequency2,
            let gridUnderfrequency1 = gridUnderfrequency1,
            let gridUnderfrequencyProtectTime = gridUnderfrequencyProtectTime,
            let gridUnderfrequency2 = gridUnderfrequency2,
            
            let reconnectSlope = reconnectSlope,
            
            let rebootGridOvervoltage = rebootGridOvervoltage,
            let rebootGridUndervoltage = rebootGridUndervoltage,
            let rebootGridOverfrequency = rebootGridOverfrequency,
            let rebootGridUnderfrequency = rebootGridUnderfrequency
        else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }
        
        var data = Data()
        
        // 市电一级过压保护时间
        let gridOvervoltage1ProtectTimeData = parser.floatToInt16(gridOvervoltage1ProtectTime, decimalPlaces: 1).littleEndianData
        data.append(gridOvervoltage1ProtectTimeData)
        // 市电二级过压保护时间
        let gridOvervoltage2ProtectTimeData = parser.floatToInt16(gridOvervoltage2ProtectTime, decimalPlaces: 1).littleEndianData
        data.append(gridOvervoltage2ProtectTimeData)
        // 市电一级欠压保护时间
        let gridUndervoltage1ProtectTimeData = parser.floatToInt16(gridUndervoltage1ProtectTime, decimalPlaces: 1).littleEndianData
        data.append(gridUndervoltage1ProtectTimeData)
        // 市电二级欠压保护时间
        let gridUndervoltage2ProtectTimeData = parser.floatToInt16(gridUndervoltage2ProtectTime, decimalPlaces: 1).littleEndianData
        data.append(gridUndervoltage2ProtectTimeData)
        
        // 有功软启速率
        let activeSoftStartRateData = parser.floatToInt16(activeSoftStartRate, decimalPlaces: 2).littleEndianData
        data.append(activeSoftStartRateData)
        // app快速下电
        let appFastPowerDownData = Int16(appFastPowerDown ? 1 : 0).littleEndianData
        data.append(appFastPowerDownData)
        // 过频降载
        let overfrequencyLoadSheddingData = parser.floatToInt16(overfrequencyLoadShedding, decimalPlaces: 2).littleEndianData
        data.append(overfrequencyLoadSheddingData)
        // 过频降载斜率
        let overfrequencyLoadSheddingSlopeData = parser.floatToInt16(overfrequencyLoadSheddingSlope, decimalPlaces: 2).littleEndianData
        data.append(overfrequencyLoadSheddingSlopeData)
        // 欠频加载
        let underfrequencyLoadSheddingData = UInt16(parser.floatToInt16(underfrequencyLoadShedding, decimalPlaces: 2)).littleEndianData
        data.append(underfrequencyLoadSheddingData)
        // QU模式
        let quModeData = Int16(quMode ? 1 : 0).littleEndianData
        data.append(quModeData)
        // cos φ(P)模式
        let cosModeData = Int16(cosMode ? 1 : 0).littleEndianData
        data.append(cosModeData)
        // 防孤岛开关
        let antiislandingModeData = Int16(antiislandingMode ? 1 : 0).littleEndianData
        data.append(antiislandingModeData)
        // 高低穿使能开关
        let highlowModeData = Int16(highlowMode ? 1 : 0).littleEndianData
        data.append(highlowModeData)
        // 功率因数
        let powerFactorData = Int16(parser.floatToInt16(powerFactor, decimalPlaces: 2)).littleEndianData
        data.append(powerFactorData)
        // 开机故障重连时间设置
        let reconnectTimeData = Int16(parser.floatToInt16(reconnectTime, decimalPlaces: 1)).littleEndianData
        data.append(reconnectTimeData)
        // 开机故障重连斜率
        let reconnectSlopeData = parser.floatToInt16(reconnectSlope, decimalPlaces: 2).littleEndianData
        data.append(reconnectSlopeData)
        
        // 电网电压一级过压
        let gridOvervoltage1Data = parser.floatToInt16(gridOvervoltage1, decimalPlaces: 1).littleEndianData
        data.append(gridOvervoltage1Data)
        // 电网电压二级过压
        let gridOvervoltage2Data = parser.floatToInt16(gridOvervoltage2, decimalPlaces: 1).littleEndianData
        data.append(gridOvervoltage2Data)
        // 电网电压一级欠压
        let gridUndervoltage1Data = parser.floatToInt16(gridUndervoltage1, decimalPlaces: 1).littleEndianData
        data.append(gridUndervoltage1Data)
        // 电网电压二级欠压
        let gridUndervoltage2Data = parser.floatToInt16(gridUndervoltage2, decimalPlaces: 1).littleEndianData
        data.append(gridUndervoltage2Data)
        // 电网频率1级过频
        let gridOverfrequency1Data = parser.floatToInt16(gridOverfrequency1, decimalPlaces: 2).littleEndianData
        data.append(gridOverfrequency1Data)
        // 电网频率2级过频
        let gridOverfrequency2Data = parser.floatToInt16(gridOverfrequency2, decimalPlaces: 2).littleEndianData
        data.append(gridOverfrequency2Data)
        // 电网频率1级欠频
        let gridUnderfrequency1Data = parser.floatToInt16(gridUnderfrequency1, decimalPlaces: 2).littleEndianData
        data.append(gridUnderfrequency1Data)
        // 电网频率2级欠频
        let gridUnderfrequency2Data = parser.floatToInt16(gridUnderfrequency2, decimalPlaces: 2).littleEndianData
        data.append(gridUnderfrequency2Data)
        
        // 功率设置
        let powerPercentData = parser.floatToInt16(powerPercent, decimalPlaces: 2).littleEndianData
        data.append(powerPercentData)
        // 过频保护时间
        let gridOverfrequencyProtectTimeData = Int16(gridOverfrequencyProtectTime).littleEndianData
        data.append(gridOverfrequencyProtectTimeData)
        // 欠频保护时间
        let gridUnderfrequencyProtectTimeData = Int16(gridUnderfrequencyProtectTime).littleEndianData
        data.append(gridUnderfrequencyProtectTimeData)
        // 欠频加载斜率
        let underfrequencyLoadSheddingSlopeData = parser.floatToInt16(underfrequencyLoadSheddingSlope, decimalPlaces: 3).littleEndianData
        data.append(underfrequencyLoadSheddingSlopeData)
        // 开机与故障重连的欠频
        let rebootGridOvervoltageData = parser.floatToInt16(rebootGridOvervoltage, decimalPlaces: 2).littleEndianData
        data.append(rebootGridOvervoltageData)
        // 开机与故障重连的过频
        let rebootGridUndervoltageData = parser.floatToInt16(rebootGridUndervoltage, decimalPlaces: 2).littleEndianData
        data.append(rebootGridUndervoltageData)
        // 开机与故障重连的欠压
        let rebootGridOverfrequencyData = parser.floatToInt16(rebootGridOverfrequency, decimalPlaces: 1).littleEndianData
        data.append(rebootGridOverfrequencyData)
        // 开机与故障重连的过压
        let rebootGridUnderfrequencyData = parser.floatToInt16(rebootGridUnderfrequency, decimalPlaces: 2).littleEndianData
        data.append(rebootGridUnderfrequencyData)
        
//        print("数据如下：")
//        print(NSData(data: data))
        
        execute(msctCommand: command, data: data)
    }
    
    func resumeGridConnectionConfig() {
        execute(msctCommand: .resumeGridConnectionConfig)
    }
    
    func getFirmwares(_ type: Int?) {
        let command: DinStorageBatteryMSCTCommand = .getFirmwares
        
        guard let type = type,
              let firmwareType = DinFirmwareType(rawValue: type)
        else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }

        var data = Data()
        data.append(firmwareType.byte)

        execute(msctCommand: command, data: data)
    }
    
    func setFuseSpecs(powerCap: Int?, spec: String?) {
        let command: DinStorageBatteryMSCTCommand = .setFuseSpecs

        guard let powerCap = powerCap, let spec = spec else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }
        guard (0...Int(UInt16.max)).contains(powerCap) else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }
        guard let specData = spec.data(using: .utf8), !specData.isEmpty, specData.count <= Int(UInt8.max) else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }
        
        var data = Data()
        
        data.append(UInt8(truncatingIfNeeded: specData.count))
        data.append(specData)
        data.append(UInt16(powerCap).littleEndianData)
        
        execute(msctCommand: command, data: data)
    }
    
    func getFuseSpecs() {
        execute(msctCommand: .getFuseSpecs)
    }
    
    func getThirdPartyPVInfo() {
        execute(msctCommand: .getThirdPartyPVInfo)
    }
    
    func setThirdPartyPVOn(isOn: Bool?) {
        let command: DinStorageBatteryMSCTCommand = .setThirdPartyPVOn

        guard let isOn = isOn else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }

        var data = Data([isOn ? 0x01 : 0x00])
        execute(msctCommand: command, data: data)
    }
    
    func getRegulateFrequencyState() {
        let command: DinStorageBatteryMSCTCommand = .getRegulateFrequencyState
        execute(msctCommand: command)
    }
    
    func getPVDist() {
        let command: DinStorageBatteryMSCTCommand = .getPVDist
        execute(msctCommand: command)
    }
    
    func setPVDist(ai: Int?, scheduled: Int?) {
        let command: DinStorageBatteryMSCTCommand = .setPVDist
        
        guard let ai = ai, let scheduled = scheduled else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }
        
        var data = Data()
        data.append(ai.uint8)
        data.append(scheduled.uint8)
        execute(msctCommand: command, data: data)
    }
    
    func getAllSupportFeatures() {
        let command: DinStorageBatteryMSCTCommand = .getAllSupportFeatures
        execute(msctCommand: command)
    }

    // Peak Shaving
    
    func togglPeakShaving(isOn:Bool? ) {
        let command: DinStorageBatteryMSCTCommand = .togglPeakShaving
        guard let isOn = isOn else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }
        let data = isOn.toUInt8Data()
        execute(msctCommand: command, data: data)
    }
    
    func setPeakShavingPoints(point1:Int? ,point2:Int?) {
        let command: DinStorageBatteryMSCTCommand = .setPeakShavingPoints
        guard let point1 = point1,let point2 = point2 else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }
        
        var data = Data()
        data.append(point1.uint8)
        data.append(point2.uint8)
        execute(msctCommand: command, data: data)
    }
    
    func setPeakShavingRedundancy(redundancy:Int?) {
        let command: DinStorageBatteryMSCTCommand = .setPeakShavingRedundancy
        guard let redundancy = redundancy else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }
        var data = Data()
        data.append(UInt32(redundancy).littleEndianData)
        execute(msctCommand: command, data: data)
    }
    
    func getPeakShavingSchedule(){
        execute(msctCommand: .getPeakShavingSchedule)
    }
    
    func addPeakShavingSchedule(schedules:[[String: Any]]?) {
        let command: DinStorageBatteryMSCTCommand = .addPeakShavingSchedule
        guard let schedules = schedules else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }
        
        var data = Data()
        data.append(UInt8(schedules.count * 26).littleEndianData)
        
        for item in schedules {
            let allDay = (item["allDay"] as? Bool) ?? false
            let start = Int32(item["start"] as? Int32 ?? 0)
            let end = Int32(item["end"] as? Int32 ?? 0)
            let weekdays = (item["weekdays"] as? [Bool]) ?? Array(repeating: false, count: 7)
            let limit = Int32(item["limit"] as? Int32 ?? 0)
            let createdAt = Int64(item["createdAt"] as? Int64 ?? 0)
            let scheduleId = Int32(item["scheduleId"] as? Int32 ?? 0)
            
            data.append(allDay.toUInt8Data())
            data.append(start.littleEndianData)
            data.append(end.littleEndianData)
            data.append(weekdays.toWeekdayData())
            data.append(limit.littleEndianData)
            data.append(createdAt.littleEndianData)
            data.append(scheduleId.littleEndianData)
        }
        
        execute(msctCommand: command, data: data)
    }
    
    func delPeakShavingSchedule(scheduleId:Int?) {
        let command: DinStorageBatteryMSCTCommand = .delPeakShavingSchedule
        guard let scheduleId = scheduleId else {
            accept(error: MSCTCommandBadRequestFailure(command: command))
            return
        }
        var data = Data()
        data.append(Int32(scheduleId).littleEndianData)
        execute(msctCommand: command, data: data)
    }
    
    func getPeakShavingConfig() {
        execute(msctCommand: .getPeakShavingConfig)
    }
    
    func execute(
        msctCommand command: DinStorageBatteryMSCTCommand,
        data: Data? = nil,
        compensationUserInfo: MSCTCommandUserInfo? = nil
    ) {
        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }
            guard let control = self.communicateControl else {
                accept(error: MSCTConnectionUnavailableFailure(command: command))
                return
            }

            let msgID = String.UUID()
            self.onGoingMSCTCommands.insert(msgID)
            self.onGoingMSCTCommandsMap[msgID] = command
            if let value = compensationUserInfo { self.onGoingMSCTCommandUserInfo[msgID] = value }
            control.execute(command: command, messageID: msgID, parameters: data)
        }
    }

    func accept(error: CommandExecutionFailure) {
        if onAcceptDataQueue {
            deviceOperationResult.accept(error.result)
        } else {
            acceptDataQueue.async { [weak self] in
                self?.deviceOperationResult.accept(error.result)
            }
        }
    }

    func getRegionList() {
        let command: DinStorageBatteryHTTPCommand = .getRegionList

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }
            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let request = DinStorageBatteryRequest.getRegionList
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }
                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }
                        self.onGoingHTTPCommands.remove(command)

                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: result ?? [:]
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }
                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }
                        self.onGoingHTTPCommands.remove(command)

                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }

    func updateRegion(countryCode: String, countryName: String, cityName: String, timezone: String) {
        let command: DinStorageBatteryHTTPCommand = .updateRegion

        guard !countryCode.isEmpty, !countryName.isEmpty, !cityName.isEmpty, !timezone.isEmpty else {
            accept(deviceOperationResult: HTTPCommandBadRequestFailure(command: command).result)
            return
        }

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryRequest.UpdateRegionParameters(
                homeID: self.homeID,
                deviceID: self.model.deviceID,
                countryCode: countryCode,
                model: self.model.model,
                region: "\(cityName),\(countryName)",
                timezone: timezone
            )
            let request = DinStorageBatteryRequest.updateRegion(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: result ?? [:]
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }
    
    func applyRegionUpdated(countryCode: String, deliveryArea: String, complete: @escaping () -> Void) {
        let info = ["country_code": countryCode, "delivery_area": deliveryArea]
        self.handleRegionUpdate(info) {
            complete()
        }
    }

    func getRegion() {
        let command: DinStorageBatteryHTTPCommand = .getRegion

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryRequest.GetRegionParameters(
                homeID: self.homeID,
                deviceID: self.model.deviceID,
                model: self.model.model
            )
            let request = DinStorageBatteryRequest.getRegion(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: result ?? [:]
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }

    func bindInverter(inverterID: String, mcuID: String) {
        let command: DinStorageBatteryHTTPCommand = .bindInverter

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)
            let parameters = DinStorageBatteryRequest.BindInverterParameters(
                bmtId: self.model.deviceID,
                homeID: self.homeID,
                inverterID: inverterID,
                mcuID: mcuID,
                model: self.model.model
            )
            let request = DinStorageBatteryRequest.bindInverter(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: result ?? [:]
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }
    
    func getElecPriceInfo(offset: Int) {
        let command: DinStorageBatteryHTTPCommand = .getElecPriceInfo

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryRequest.GetElecPriceInfoParameters(
                homeID: self.homeID,
                deviceID: self.model.deviceID,
                model: self.model.model,
                offset: offset
            )

            let request = DinStorageBatteryRequest.getElecPriceInfo(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        var payload = result ?? [:]

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: payload
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }

    func getFusePowerCaps() {
        let command: DinStorageBatteryHTTPCommand = .getFusePowerCaps

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryRequest.GetFusePowerCapsParameters(
                json: [:]
            )

            let request = DinStorageBatteryRequest.getFusePowerCaps(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        var payload = result ?? [:]

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: payload
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }

    func getDualPowerOpen() {
        let command: DinStorageBatteryHTTPCommand = .getDualPowerOpen

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryRequest.GetDualPowerOpenParameters(
                homeID: self.homeID,
                deviceID: self.model.deviceID
            )

            let request = DinStorageBatteryRequest.getDualPowerOpen(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        let payload = result ?? [:]

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: payload
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }
    
    func getFeature() {
        let command: DinStorageBatteryHTTPCommand = .getFeature

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryRequest.GetFeatureParameters(
                homeID: self.homeID,
                deviceID: self.model.id,
                model: self.model.model
            )
            let request = DinStorageBatteryRequest.getFeature(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: result ?? [:]
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }
    
    func getBmtLocation() {
        let command: DinStorageBatteryHTTPCommand = .getBmtLocation

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryRequest.GetBmtLocationParameter(
                homeID: self.homeID,
                deviceID: self.model.id,
                model: self.model.model
            )
            let request = DinStorageBatteryRequest.getBmtLocation(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: result ?? [:]
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }

    func getSoundSettings() {
            execute(msctCommand: .getSoundSettings)
        }
        
        func getBrightnessSettings() {
            execute(msctCommand: .getBrightnessSettings)
        }
        
        func setBrightnessSettings(brightness: Int?) {
            let command: DinStorageBatteryMSCTCommand = .setBrightnessSettings
            
            guard let brightness = brightness else {
                accept(error: MSCTCommandBadRequestFailure(command: command))
                return
            }

            let data = withUnsafeBytes(of: Int16(brightness).littleEndian) { Data($0) }
            execute(msctCommand: command, data: data)
        }
        
        func setSoundSettings(systemTones: Bool?,reminderAlerts:Bool?) {
            let command: DinStorageBatteryMSCTCommand = .setSoundSettings
            
            guard let systemTones = systemTones , let reminderAlerts = reminderAlerts  else {
                accept(error: MSCTCommandBadRequestFailure(command: command))
                return
            }
            
            func boolsToData(_ bools: Bool...) -> Data {
               let bytes = bools.map { $0 ? UInt8(1) : UInt8(0) }
               return Data(bytes)
           }
            
            let data = boolsToData(systemTones, reminderAlerts)
            execute(msctCommand: command, data: data)
        }

}

// MARK: - GetStorageBatteryStats Function
extension DinStorageBatteryControl {
    func getStatsLoadusage(interval: String, offset: Int) {
        let command: DinStorageBatteryHTTPCommand = .getStatsLoadusage

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryStatsRequest.GetStatsParameters(
                homeID: self.homeID,
                deviceID: self.model.deviceID,
                model: self.model.model,
                interval: interval,
                offset: offset
            )

            let request = DinStorageBatteryStatsRequest.getStatsLoadusage(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        var payload = result ?? [:]
                        payload["interval_type"] = interval

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: payload
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }
    
    func getStatsLoadusageV2(interval: String, offset: Int) {
        let command: DinStorageBatteryHTTPCommand = .getStatsLoadusageV2

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryStatsRequest.GetStatsParameters(
                homeID: self.homeID,
                deviceID: self.model.deviceID,
                model: self.model.model,
                interval: interval,
                offset: offset
            )

            let request = DinStorageBatteryStatsRequest.getStatsLoadusageV2(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        var payload = result ?? [:]
                        payload["interval_type"] = interval

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: payload
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }

    func getStatsBattery(interval: String, offset: Int) {
        let command: DinStorageBatteryHTTPCommand = .getStatsBattery

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryStatsRequest.GetStatsParameters(
                homeID: self.homeID,
                deviceID: self.model.deviceID,
                model: self.model.model,
                interval: interval,
                offset: offset
            )

            let request = DinStorageBatteryStatsRequest.getStatsBattery(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        var payload = result ?? [:]
                        payload["interval_type"] = interval

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: payload
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }
    
    func getStatsBatteryV2(interval: String, offset: Int) {
        let command: DinStorageBatteryHTTPCommand = .getStatsBatteryV2

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryStatsRequest.GetStatsParameters(
                homeID: self.homeID,
                deviceID: self.model.deviceID,
                model: self.model.model,
                interval: interval,
                offset: offset
            )

            let request = DinStorageBatteryStatsRequest.getStatsBatteryV2(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        var payload = result ?? [:]
                        payload["interval_type"] = interval

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: payload
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }

    func getStatsBatteryPowerlevel(interval: String, offset: Int) {
        let command: DinStorageBatteryHTTPCommand = .getStatsBatteryPowerlevel

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryStatsRequest.GetStatsParameters(
                homeID: self.homeID,
                deviceID: self.model.deviceID,
                model: self.model.model,
                interval: interval,
                offset: offset
            )

            let request = DinStorageBatteryStatsRequest.getStatsBatteryPowerlevel(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        var payload = result ?? [:]
                        payload["interval_type"] = interval

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: payload
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }

    func getStatsGrid(interval: String, offset: Int, get_real: Bool, query_interval: Int) {
        let command: DinStorageBatteryHTTPCommand = .getStatsGrid

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryStatsRequest.GetStatsGridParameters(
                homeID: self.homeID,
                deviceID: self.model.deviceID,
                model: self.model.model,
                interval: interval,
                offset: offset,
                get_real: get_real,
                query_interval: query_interval
            )

            let request = DinStorageBatteryStatsRequest.getStatsGrid(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        var payload = result ?? [:]
                        payload["interval_type"] = interval

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: payload
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }

    func getStatsMppt(interval: String, offset: Int) {
        let command: DinStorageBatteryHTTPCommand = .getStatsMppt

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryStatsRequest.GetStatsParameters(
                homeID: self.homeID,
                deviceID: self.model.deviceID,
                model: self.model.model,
                interval: interval,
                offset: offset
            )

            let request = DinStorageBatteryStatsRequest.getStatsMppt(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        var payload = result ?? [:]
                        payload["interval_type"] = interval

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: payload
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }
    
    func getStatsMpptV2(interval: String, offset: Int) {
        let command: DinStorageBatteryHTTPCommand = .getStatsMpptV2

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryStatsRequest.GetStatsParameters(
                homeID: self.homeID,
                deviceID: self.model.deviceID,
                model: self.model.model,
                interval: interval,
                offset: offset
            )

            let request = DinStorageBatteryStatsRequest.getStatsMpptV2(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        var payload = result ?? [:]
                        payload["interval_type"] = interval

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: payload
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }

    func getStatsRevenue(interval: String, offset: Int) {
        let command: DinStorageBatteryHTTPCommand = .getStatsRevenue

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryStatsRequest.GetStatsParameters(
                homeID: self.homeID,
                deviceID: self.model.deviceID,
                model: self.model.model,
                interval: interval,
                offset: offset
            )

            let request = DinStorageBatteryStatsRequest.getStatsRevenue(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        var payload = result ?? [:]
                        payload["interval_type"] = interval

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: payload
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }
    
    func getStatsRevenueV2(interval: String, offset: Int) {
        let command: DinStorageBatteryHTTPCommand = .getStatsRevenueV2

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryStatsRequest.GetStatsParameters(
                homeID: self.homeID,
                deviceID: self.model.deviceID,
                model: self.model.model,
                interval: interval,
                offset: offset
            )

            let request = DinStorageBatteryStatsRequest.getStatsRevenueV2(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        var payload = result ?? [:]
                        payload["interval_type"] = interval

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: payload
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }

    func getStatsEco(interval: String, offset: Int) {
        let command: DinStorageBatteryHTTPCommand = .getStatsEco

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryStatsRequest.GetStatsParameters(
                homeID: self.homeID,
                deviceID: self.model.deviceID,
                model: self.model.model,
                interval: interval,
                offset: offset
            )

            let request = DinStorageBatteryStatsRequest.getStatsEco(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        var payload = result ?? [:]
                        payload["interval_type"] = interval

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: payload
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }
    
    func getStatsEcoV2(interval: String, offset: Int) {
        let command: DinStorageBatteryHTTPCommand = .getStatsEcoV2

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryStatsRequest.GetStatsParameters(
                homeID: self.homeID,
                deviceID: self.model.deviceID,
                model: self.model.model,
                interval: interval,
                offset: offset
            )

            let request = DinStorageBatteryStatsRequest.getStatsEcoV2(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        var payload = result ?? [:]
                        payload["interval_type"] = interval

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: payload
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }
    
    func getChargingDischargingPlans(offset: Int) {
        let command: DinStorageBatteryHTTPCommand = .getChargingDischargingPlans

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryStatsRequest.GetChargingDischargingPlansParameters(
                homeID: self.homeID,
                deviceID: self.model.deviceID,
                model: self.model.model,
                offset: offset
            )

            let request = DinStorageBatteryStatsRequest.getChargingDischargingPlans(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        var payload = result ?? [:]

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: payload
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }
    
    func getChargingDischargingPlansV2() {
        let command: DinStorageBatteryHTTPCommand = .getChargingDischargingPlansV2

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryStatsRequest.GetChargingDischargingPlansParameters(
                homeID: self.homeID,
                deviceID: self.model.deviceID,
                model: self.model.model,
                offset: -1//
            )

            let request = DinStorageBatteryStatsRequest.getChargingDischargingPlansV2(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        var payload = result ?? [:]

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: payload
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }
    
    func getChargingDischargingPlansV2Minute() {
        let command: DinStorageBatteryHTTPCommand = .getChargingDischargingPlansV2Minute

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryStatsRequest.GetChargingDischargingPlansParameters(
                homeID: self.homeID,
                deviceID: self.model.deviceID,
                model: self.model.model,
                offset: -1//
            )

            let request = DinStorageBatteryStatsRequest.getChargingDischargingPlansV2Minute(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        var payload = result ?? [:]

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: payload
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }
    
    func getBSensorStatus() {
        let command: DinStorageBatteryHTTPCommand = .getBSensorStatus

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryStatsRequest.GetBSensorStatusParameters(
                homeID: self.homeID,
                deviceID: self.model.deviceID,
                model: self.model.model
            )

            let request = DinStorageBatteryStatsRequest.getBSensorStatus(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        let payload = result ?? [:]

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: payload
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }
    
    func getAIModeSettings() {
        let command: DinStorageBatteryHTTPCommand = .getAIModeSettings

        acceptDataQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.onGoingHTTPCommands.contains(command) else { return }
            self.onGoingHTTPCommands.insert(command)

            let parameters = DinStorageBatteryRequest.GetAIModeSettingsParameter(
                homeID: self.homeID,
                deviceID: self.model.deviceID,
                model: self.model.model
            )

            let request = DinStorageBatteryRequest.getAIModeSettings(parameters)
            DinHttpProvider.request(
                request,
                success: { [weak self] result in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        let payload = result ?? [:]

                        // ⚠️ 注意：
                        // 1. `complete` 回调的执行切换到了主线程
                        // 2. 如果需要等待缓存更新后再回调成功，需要切换回 `acceptDataQueue`
                        //    确保缓存更新和设备指令结果的提交在同一个队列中执行，
                        //    避免在不同线程中同时操作 `deviceOperationResult` 可能导致的线程安全问题
                        self.handleAIModeSettingsUpdate(payload, complete: {})
                        
                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandSuccessfulResponse(
                                command: command,
                                payload: payload
                            ).result
                        )
                    }
                },
                fail: { [weak self] error in
                    guard let self = self else { return }

                    self.acceptDataQueue.async { [weak self] in
                        guard let self = self else { return }

                        self.onGoingHTTPCommands.remove(command)
                        self.deviceOperationResult.accept(
                            HTTPCommandInternalFailure(
                                command: command,
                                error: error
                            ).result
                        )
                    }
                }
            )
        }
    }
    
    func getLocallySwitch() {
        let command = DinStorageBatteryHTTPCommand.getLocallySwitch
        let request = DinStorageBatteryRequest.getLocallySwitch(.init(
            homeID: homeID,
            deviceID: model.deviceID,
            model: model.model
        ))
        sendRequest(request, command: command)
    }
    
    func setLocallySwitch(isEnable: Bool) {
        let command = DinStorageBatteryHTTPCommand.setLocallySwitch
        let request = DinStorageBatteryRequest.setLocallySwitch(.init(
            homeID: homeID,
            deviceID: model.deviceID,
            model: model.model,
            enable: isEnable
        ))
        sendRequest(request, command: command)
    }
    
    func setBmtInitPeakShaving(isEnable: Bool) {
        let command = DinStorageBatteryHTTPCommand.setBmtInitPeakShaving
        let request = DinStorageBatteryRequest.setBmtInitPeakShaving(.init(
            id: model.deviceID,
            initPeakShaving: isEnable
        ))
        sendRequest(request, command: command)
    }
    
    /// 通用的网络请求方法，沿用之前的请求流程
    /// - Parameters:
    ///   - request: DinStorageBatteryRequest 类型的请求参数
    ///   - command: DinStorageBatteryHTTPCommand 类型的命令，用于缓存进行中的请求
    ///   - resultHandler: 请求成功后的返回数据预处理方法
    func sendRequest(_ request: DinStorageBatteryRequest, command: DinStorageBatteryHTTPCommand, resultHandler: (([String: Any]) -> Void)? = nil) {
        acceptDataQueue.async { [weak self] in
            guard let self else { return }
            guard !onGoingHTTPCommands.contains(command) else { return }
            onGoingHTTPCommands.insert(command)
            
            DinHttpProvider.request(request) { result in
                self.acceptDataQueue.async { [weak self] in
                    guard let self = self else { return }

                    let payload = result ?? [:]
                    resultHandler?(payload)
                    
                    self.onGoingHTTPCommands.remove(command)
                    self.deviceOperationResult.accept(
                        HTTPCommandSuccessfulResponse(
                            command: command,
                            payload: payload
                        ).result
                    )
                }
            } fail: { error in
                self.acceptDataQueue.async { [weak self] in
                    guard let self = self else { return }

                    self.onGoingHTTPCommands.remove(command)
                    self.deviceOperationResult.accept(
                        HTTPCommandInternalFailure(
                            command: command,
                            error: error
                        ).result
                    )
                }
            }

        }
    }
}

extension DinStorageBatteryControl: DinUDPGroupControlDelegate {
    func control(_ control: DinUDPGroupControl, receivedGroupNotifyInfo info: [String : Any]) {
        // 推送出去
        DinCore.storageBatteryDelegate?.dinCoreStorageBatteryDidReceiveGroupNotification(info)
    }
}


//MARK: - 回调UDPControl指令指令结果
extension DinStorageBatteryControl: DinStorageBatteryUDPControlDelegate {
    
    func dinStorageBatteryUDPControl(_ control: DinStorageBatteryUDPControl, didReceive command: DinStorageBatteryMSCTCommand, messageID: String, result: Result<Data, Error>) {
        guard control === communicateControl else { return }

        processCommandResult(command: command, messageID: messageID, result: result)
    }
    
    private func processCommandResult(command: DinStorageBatteryMSCTCommand, messageID: String, result: Result<Data, Error>) {
        switch command {
        case .connect, .disconnect: break
        default:
            acceptDataQueue.async { [weak self] in
                guard let self = self else { return }

                defer {
                    self.onGoingMSCTCommands.remove(messageID)
                    self.onGoingMSCTCommandUserInfo.removeValue(forKey: messageID)
                }

                var response: [String: Any] = [
                    "cmd": command.rawValue,
                    "owned": self.onGoingMSCTCommands.contains(messageID),
                ]

                switch result {
                case .failure(let error):
                    switch error {
                    case let value as DinStorageBatteryUDPControl.TimeoutFailure:
                        response["status"] = -2
                        response["errorMsg"] = value.reason
                    case let value as DinStorageBatteryUDPControl.ExecutionFailure:
                        response["status"] = -1
                        response["errorMsg"] = value.reason
                    default:
                        response["status"] = 0
                        response["errorMsg"] = self.unknownErrorReason
                    }
                case .success(let data):
                    do {
                        try self.parse(data,
                                       command: command,
                                       messageID: messageID,
                                       result: { result in
                            response["result"] = result
                            response["status"] = 1
                            self.accept(deviceOperationResult: response)
                        })
                        return
                    } catch {
                        response["status"] = 0
                        response["errorMsg"] = self.corruptedDataErrorReason
                    }
                }

                self.accept(deviceOperationResult: response)
            }
        }
    }

    private func parse(_ data: Data, command: DinStorageBatteryMSCTCommand, messageID: MSCTCommandMessageID, result: @escaping ([String: Any])->()) throws {
        switch command {

            // Inverter
        case .getInverterInputInfo: result(try parser.parse(getInverterInputInfoData: data))
        case .getInverterOutputInfo: result(try parser.parse(getInverterOutputInfoData: data))
        case .getInverterInfoByIndex:
            let returnDict = try parser.parse(getInverterInfoData: data)
            self.handleSingleVertStateUpdate(returnDict) { result(returnDict) }
        case .inverterExceptionsNotify:
            let returnDict = try parser.parse(inverterExceptionData: data)
            self.updateInverterAllExceptions(dict: returnDict, usingSync: false) {
                result(returnDict)
            }
        case .resetInverter: result(try parser.parse(resetInverter: data))
            // Battery
        case .getBatteryAccessoryStateByIndex: result(try parser.parse(getBatteryAccessoryStateData: data))
        case .getBatteryInfoByIndex: result(try parser.parse(getBatteryInfoByIndexData: data))
        case .batteryExceptionsNotify:
            let returnDict = try parser.parse(batteryExceptionsNotifyData: data)
            if let exceptions = returnDict["exceptions"] as? [Int] {
                self.updateBatteryExceptions(exceptions, usingSync: false) {
                    result(returnDict)
                }
            } else {
                result(returnDict)
            }
        case .batchGetBatteryInfo: result(try parser.parse(batchGetBatteryInfoData: data))
        case .batchTurnOffBattery: result([:])
        case .batteryAccessoryStateChangedNotify: result(try parser.parse(batteryAccessoryStateChangedNotifyData: data))
        case .batteryAccessoryStateChangedCustomNotify: result(try parser.parse(batteryAccessoryStateChangedCustomNotifyData: data))
        case .batteryIndexChangedNotify: result(try parser.parse(batteryIndexChangedNotifyData: data))
        case .batteryStatusInfoNotify: result(try parser.parse(batteryStatusInfoNotifyData: data))

            // EV
        case .getEVState: result(try parser.parse(getEVStateData: data))
        case .evExceptionsNotify:
            let returnDict = try parser.parse(evExceptionsNotifyData: data)
            if let exceptions = returnDict["exceptions"] as? [Int] {
                self.updateEVExceptions(exceptions, usingSync: false) {
                    result(returnDict)
                }
            } else {
                result(returnDict)
            }
            // MPPT
        case .getMPPTState: result(try parser.parse(getMPPTStateData: data))
        case .mpptExceptionsNotify:
            let returnDict = try parser.parse(mpptExceptionsNotifyData: data)
            if let exceptions = returnDict["exceptions"] as? [Int] {
                self.updateMPPTExceptions(exceptions, usingSync: false) {
                    result(returnDict)
                }
            } else {
                result(returnDict)
            }
            // MCU
        case .getMCUInfo: result(try parser.parse(getMCUInfoData: data))

            // Cabinet
        case .getCabinetInfo: result(try parser.parse(getCabinetInfoData: data))
        case .getCabinetStateByIndex: result(try parser.parse(getCabinetStateData: data))
        case .cabinetStateChangedNotify: result(try parser.parse(cabinetStateChangedNotifyData: data))
        case .cabinetIndexChangedNotify: result(try parser.parse(cabinetIndexChangedNotifyData: data))
        case .cabinetExceptionChangedNotify:
            let returnDict = try parser.parse(cabinetExceptionChangedNotifyData: data)
            if let exceptions = returnDict["exceptions"] as? [Int] {
                self.updateCabinetExceptions(exceptions, usingSync: false) {
                    result(returnDict)
                }
            } else {
                result(returnDict)
            }
            // Global
        case .getGlobalLoadState: result(try parser.parse(getGlobalLoadStateData: data))
        case .getGlobalExceptions:
            let returnDict = try parser.parse(getGlobalExceptionsData: data)
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.checkAllExceptions(UsingSync: returnDict)
                DispatchQueue.global().async {
                    result(returnDict)
                }
            }
        case .getGlobalDisplayExceptions: result(try parser.parse(getGlobalExceptionsData: data))
        case .systemExceptionsNotify:
            let returnDict = try parser.parse(systemExceptionsNotifyData: data)
            if let exceptions = returnDict["exceptions"] as? [Int] {
                self.updateSystemExceptions(exceptions, usingSync: false) {
                    result(returnDict)
                }
            } else {
                result(returnDict)
            }
        case .communicationExceptionsNotify:
            let returnDict = try parser.parse(communicationExceptionsNotifyData: data)
            if let exceptions = returnDict["exceptions"] as? [Int] {
                self.updateCommunicationExceptions(exceptions, usingSync: false) {
                    result(returnDict)
                }
            } else {
                result(returnDict)
            }
        case .getGlobalCurrentFlowInfo:
            let returnDict = try parser.parse(getGlobalCurrentFlowInfoData: data)
            self.handleThirdPartyPVOnUpdate(returnDict) {
                self.handleGridStatusUpdate(returnDict) {
                    result(returnDict)
                }
            }
            // Strategy
        case .getEmergencyChargingSettings: result(try parser.parse(getEmergencyChargeSettingsData: data))
        case .setEmergencyCharging: result([:])
        case .getGridChargeMargin: result(try parser.parse(getGridChargeMarginData: data))
        case .setChargingStrategies: result([:])
        case .getChargingStrategies: result(try parser.parse(getChargingStrategiesData: data))
        case .setVirtualPowerPlant: result([:])
        case .getVirtualPowerPlant: result(try parser.parse(getVirtualPowerPlantData: data))
        case .setSellingProtection: result([:])
        case .getSellingProtection: result(try parser.parse(getSellingProtectionData: data))
        case .getSignals: result(try parser.parse(getSignalsData: data))
        case .reset: result([:])
        case .reboot: result([:])
        case .getAdvanceInfo:
            let returnDict = try parser.parse(getAdvanceInfoData: data)
            self.handleIotVersionUpdate(returnDict) { result(returnDict) }
        case .setGlobalLoaderOpen: result([:])
        case .getMode: result(try parser.parse(getModeData: data))
        case .getModeV2: result(try parser.parse(getModeV2Data: data))

            // Connection
        case .connect, .disconnect, .connectStatusChangedNotify: result([:])

            // Charge, Discharge
        case .getChipsStatus:
            let returnDict = try parser.parse(getChipsStatus: data)
            self.handleChipStatusUpdate(returnDict) { result(returnDict) }
        case .getChipsUpdateProgress:
            let returnDict = try parser.parse(getChipsUpdateProgress: data)
            self.handleChipStatusUpdate(returnDict) { result(returnDict) }
        case .updateChips:
            let returnDict = try parser.parse(updateChips: data)
            self.handleChipStatusUpdate(returnDict) { result(returnDict) }
        case .getCurrentReserveMode: result(try parser.parse(reserveMode: data))
        case .getPriceTrackReserveMode: result(try parser.parse(priceTrackReserveMode: data))
        case .getScheduleReserveMode: result(try parser.parse(scheduleReserveMode: data))
        case .getCustomScheduleMode: result(try parser.parse(customScheduleMode: data))
        case .setReserveMode: result([:])
        case .getCustomScheduleModeAI: result(try parser.parse(customScheduleModeAI: data))
        case .setReserveModeAI: result([:])
        case .getCurrentEVChargingMode: result(try parser.parse(currentEVChargingMode: data))
        case .getEVChargingModeSchedule: result(try parser.parse(evChargingModeSchedule: data))
        case .setEVChargingMode: result([:])
        case .setEVChargingModeInstant: result([:])
        case .setEvchargingModeInstantcharge: result(try parser.parse(setEvchargingModeInstantcharge: data))
        case .getCurrentEVAdvanceStatus: result(try parser.parse(currentEVAdvanceStatus: data))
        case .evAdvanceStatusChangedNotify: result(try parser.parse(evAdvancestatuschanged: data))
        case .getEVChargingInfo: result(try parser.parse(evchargingInfo: data))
        case .getSmartEvStatus: result(try parser.parse(getSmartEvStatus: data))
        case .setSmartEvStatus: result([:])
        case .setRegion:
            if let value = onGoingMSCTCommandUserInfo[messageID] as? SetRegionUserInfo {
                let info = ["country_code": value.countryCode, "delivery_area": value.deliveryArea]
                self.handleRegionUpdate(info) {
                    result([:])
                }
            } else {
                result([:])
            }
        case .setExceptionIgnore: result([:])
        case .getGridConnectionConfig: result(try parser.parse(gridConnectionConfigData: data))
        case .updateGridConnectionConfig: result([:])
        case .resumeGridConnectionConfig: result([:])
        case .getFirmwares: result(try parser.parse(firmwaresData: data))
        case .setFuseSpecs: result([:])
        case .getFuseSpecs: result(try parser.parse(fuseSpecsData: data))
        case .getThirdPartyPVInfo: result(try parser.parse(getThirdPartyPVInfoData: data))
        case .setThirdPartyPVOn: result(try parser.parse(setThirdPartyPVOnData: data))
        case .getRegulateFrequencyState:
            let returnDict = try parser.parse(getRegulateFrequencyState: data)
            self.handleRegulateFrequencyStateUpdate(returnDict) { result(returnDict) }
        case .getPVDist: result(try parser.parse(pvDistData: data))
        case .setPVDist: result([:])
        case .getAllSupportFeatures:
            let returnDict = try parser.parse(AllSupportFeatures: data)
            self.handleAllSupportFeaturesUpdate(returnDict) { result(returnDict) }
        case .getBrightnessSettings: result(try parser.parse(getBrightnessSettingsData: data))
        case .setBrightnessSettings: result([:])
        case .getSoundSettings: result(try parser.parse(getSoundSettingsData: data))
        case .setSoundSettings: result([:])
        case .togglPeakShaving: result(try parser.parse(togglPeakShaving: data))
        case .setPeakShavingPoints:result([:])
        case .setPeakShavingRedundancy:result([:])
        case .getPeakShavingConfig: result(try parser.parse(getPeakShavingConfig: data))
        case .getPeakShavingSchedule:result(try parser.parse(getPeakShavingSchedule: data))
        case .addPeakShavingSchedule:result([:])
        case .delPeakShavingSchedule:result([:])
        }
    }
    
    private func handleSingleVertStateUpdate(_ returnDict: [String: Any], complete: @escaping () -> Void) {
        if let index = returnDict["index"] as? Int, let state = returnDict["state"] as? Int {
            self.updateVertState(state, at: index, usingSync: false) {
                complete()
            }
        } else {
            complete()
        }
    }
    
    private func handleChipStatusUpdate(_ returnDict: [String: Any], complete: @escaping () -> Void) {
        if let status = returnDict["status"] as? Int {
            self.updateChipsStatus(status, usingSync: false) {
                complete()
            }
        } else {
            complete()
        }
    }
    
    private func handleThirdPartyPVOnUpdate(_ returnDict: [String: Any], complete: @escaping () -> Void) {
        if let isOn = returnDict["thirdpartyPVOn"] as? Bool {
            self.updateThirdPartyPVOn(isOn, usingSync: false) {
                complete()
            }
        } else {
            complete()
        }
    }
    
    private func handleGridStatusUpdate(_ returnDict: [String: Any], complete: @escaping () -> Void) {
        if let gridValid = returnDict["gridValid"] as? Bool {
            let gridStatus: DinStorageBattery.GridStatus = gridValid ? .onGrid : .offGrid
            self.updateGridStatus(gridStatus, usingSync: false) {
                complete()
            }
        } else {
            complete()
        }
    }
    
    private func handleIotVersionUpdate(_ returnDic: [String: Any], complete: @escaping () -> Void) {
        if let iotVersion = returnDic["version"] as? String, let iotRealVersion = returnDic["realVersion"] as? String {
            self.updateIotVersion(iotVersion, iotRealVersion: iotRealVersion, usingSync: false) {
                complete()
            }
        } else {
            complete()
        }
    }
    
    private func handleRegionUpdate(_ returnDic: [String: Any], complete: @escaping () -> Void) {
        if let countryCode = returnDic["country_code"] as? String, let deliveryArea = returnDic["delivery_area"] as? String {
            self.updateCountryCode(countryCode, usingSync: false) {
                self.updateDeliveryArea(deliveryArea, usingSync: false) {
                    complete()
                }
            }
        } else {
            complete()
        }
    }
    
    private func handleRegulateFrequencyStateUpdate(_ returnDict: [String: Any], complete: @escaping () -> Void) {
        if let status = returnDict["state"] as? Int {
            self.updateRegulateFrequencyState(status, usingSync: false) {
                complete()
            }
        } else {
            complete()
        }
    }
    
    private func handleAIModeSettingsUpdate(_ returnDict: [String: Any], complete: @escaping () -> Void) {
        if let aiSmart = returnDict["smart_reserve"] as? Int, let aiEmergency = returnDict["emergency_reserve"] as? Int {
            self.updateAIModeSettings(aiSmart, aiEmergency, usingSync: false) {
                complete()
            }
        } else {
            complete()
        }
    }
    private func handleAllSupportFeaturesUpdate(_ returnDic: [String: Any], complete: @escaping () -> Void) {
        if let pvSupplyCustomizationSupported = returnDic["pvSupplyCustomizationSupported"] as? Bool,
           let peakShavingSupported = returnDic["peakShavingSupported"] as? Bool {
            self.updatePVSupplyCustomizationSupported(pvSupplyCustomizationSupported,peakShavingSupported,usingSync: false) {
                complete()
            }
        } else {
            complete()
        }
    }
    
    private func checkAllExceptions(UsingSync returnDict: [String: Any]) {
        if let ev = returnDict["vertBatteryExceptions"] as? [Int] {
            self.updateInverterBatteryExceptions(ev, usingSync: true, complete: nil)
        }
        if let ev = returnDict["vertExceptions"] as? [Int] {
            self.updateInverterExceptions(ev, usingSync: true, complete: nil)
        }
        if let ev = returnDict["vertGridExceptions"] as? [Int] {
            self.updateInverterGridExceptions(ev, usingSync: true, complete: nil)
        }
        if let ev = returnDict["vertSystemExceptions"] as? [Int] {
            self.updateInverterSystemExceptions(ev, usingSync: true, complete: nil)
        }
        if let ev = returnDict["vertmpptExceptions"] as? [Int] {
            self.updateInverterMPPTExceptions(ev, usingSync: true, complete: nil)
        }
        if let ev = returnDict["vertPresentExceptions"] as? [Int] {
            self.updateInverterPresentExceptions(ev, usingSync: true, complete: nil)
        }
        if let ev = returnDict["vertDCExceptions"] as? [Int] {
            self.updateInverterDCExceptions(ev, usingSync: true, complete: nil)
        }
        if let ev = returnDict["ev"] as? [Int] {
            self.updateEVExceptions(ev, usingSync: true, complete: nil)
        }
        if let mppt = returnDict["mppt"] as? [Int] {
            self.updateMPPTExceptions(mppt, usingSync: true, complete: nil)
        }
        if let cabinet = returnDict["cabinet"] as? [Int] {
            self.updateCabinetExceptions(cabinet, usingSync: true, complete: nil)
        }
        if let battery = returnDict["battery"] as? [Int] {
            self.updateBatteryExceptions(battery, usingSync: true, complete: nil)
        }
        if let system = returnDict["system"] as? [Int] {
            self.updateSystemExceptions(system, usingSync: true, complete: nil)
        }
        if let communication = returnDict["communication"] as? [Int] {
            self.updateCommunicationExceptions(communication, usingSync: true, complete: nil)
        }
    }
}

extension DinStorageBatteryControl {

    fileprivate typealias MSCTCommandMessageID = String

    fileprivate var newInfo: [String: Any] {
        [
            "name": "",
            "addtime": model.addtime,
            "networkState": -1, // offline: -1; connecting: 0; online: 1
        ]
    }

    fileprivate var unknownErrorReason: String { "unknown error" }
    fileprivate var corruptedDataErrorReason: String { "corrupted data" }
    fileprivate var indexKey: String { "index" }
    
    /// 用于更换设备缓存里的  country_code、delivery_area
    struct SetRegionUserInfo: MSCTCommandUserInfo {
        let countryCode: String
        let deliveryArea: String
    }
}

enum DinStorageBatteryCharingStrategy: Int {
    case priceInsensitive = 1
    case smartCharge
    case extremlySaving

    fileprivate var byte: UInt8 {
        switch self  {
        case .priceInsensitive: return 0x00
        case .smartCharge: return 0x01
        case .extremlySaving: return 0x02
        }
    }
}

enum DinStorageBatteryEVState: Int {
    case evClose = 1
    case evFree
    case evOutput
    case evInput

    fileprivate var byte: UInt8 {
        switch self  {
        case .evClose: return 0x00
        case .evFree: return 0x01
        case .evOutput: return 0x02
        case .evInput: return 0x03
        }
    }
}

enum DinStorageBatteryEVLightState: Int {
    case stop = 1
    case green
    case red
    fileprivate var byte: UInt8 {
        switch self  {
        case .stop: return 0x00
        case .green: return 0x01
        case .red: return 0x02
        }
    }
}

enum DinStorageBatteryInverterState: Int {
    case shutdown = 1
    case running
    case downToError
    fileprivate var byte: UInt8 {
        switch self  {
        case .shutdown: return 0x00
        case .running: return 0x01
        case .downToError: return 0x02
        }
    }
}

enum DinStorageBatteryInverterFanState: Int {
    case stop = 1
    case running
    fileprivate var byte: UInt8 {
        switch self  {
        case .stop: return 0x00
        case .running: return 0x01
        }
    }
}

enum DinStorageBatteryCabinetWaterState: Int {
    case valid = 1
    case exception
    fileprivate var byte: UInt8 {
        switch self  {
        case .valid: return 0x00
        case .exception: return 0x01
        }
    }
}

enum DinStorageBatterySOCState: Int {
    case full = 1
    case lowSOCAlert
    case lowSOCWarning
    case lowSOCProtect
    fileprivate var byte: UInt8 {
        switch self {
        case .full: return 0x00
        case .lowSOCAlert: return 0x01
        case .lowSOCWarning: return 0x02
        case .lowSOCProtect: return 0x03
        }
    }

}

enum DinStorageBatteryCabinetFanState: Int {
    case stopped = 1
    case running
    case exception
    fileprivate var byte: UInt8 {
        switch self  {
        case .stopped: return 0x00
        case .running: return 0x01
        case .exception: return 0x02
        }
    }
}

enum DinStorageBatteryReserveMode: Int {
    case priceTracking = 1
    case scheduled
    case aiAdapter
    fileprivate var byte: UInt8 {
        switch self {
        case .priceTracking: return 0x00
        case .scheduled: return 0x01
        case .aiAdapter: return 0x02
        }
    }
}

enum DinStorageBatterySmartEVToggleStatus: Int {
    case off = -1
    case ignore = 0
    case on = 1
    fileprivate var byte: UInt8 {
        return self.rawValue.uint8
    }
}

enum DinStorageBatteryEVChargingMode: Int {
    case lowerUtilityRate = 1           // 在接下来的12个小时内，找到电价最低的3个小时充电，每小时最多可充10kWh。
    case solarOnly                      // EV充电功率将被限制在太阳能发电功率以内。
    case scheduled                      // 在预设的时段内允许EV充电。
    case instantChargeFull              // 立即充电，充满为止
    case instantChargeFixed             // 每次固定充电
    fileprivate var byte: UInt8 {
        switch self {
        case .lowerUtilityRate: return 0x00
        case .solarOnly: return 0x01
        case .scheduled: return 0x02
        case .instantChargeFull: return 0x03
        case .instantChargeFixed: return 0x04
        }
    }
}

enum DinStorageBatteryEVDetailState: Int {
    case close = 1            // 关闭
    case free            // 空闲
    case charging              // 充电中
    case carUnvalid            // 车端挂起(车端主动停止充电)
    case unvalid            // 桩端挂起(桩端主动停止充电)
    case complete            // 充电结束（应用侧可以配合电量量消耗大于5Kwh，来认定是否充满）
    case error               // 充电桩故障且停止充电。
    fileprivate var byte: UInt8 {
        switch self {
        case .close: return 0x00
        case .free: return 0x01
        case .charging: return 0x02
        case .carUnvalid: return 0x03
        case .unvalid: return 0x04
        case .complete: return 0x05
        case .error: return 0x06
        }
    }
}

enum DinStorageBatteryEVAdvanceStatus: Int {
    case off = 1                // 空闲，没有插进车里
    case wait                   // 已经插在车里，由于条件未符合，导致还没开始充电
    case charging               // 充电中
    case error                  // 有异常发生
}

enum DinFirmwareType: Int {
    case Invertor = 0           // 逆变
    case EV                     // 车充
    case Battery                // 电池包（总包）
    case MPPT                   // 太阳能
    case Cabinet                // 机柜
    case MCU                    // MCU
    case SideCar                // SideCar
    case InverterSN             // 逆变序列号
    fileprivate var byte: UInt8 {
        switch self {
        case .Invertor: return 0x00
        case .EV: return 0x01
        case .Battery: return 0x02
        case .MPPT: return 0x03
        case .Cabinet: return 0x04
        case .MCU: return 0x05
        case .SideCar: return 0x06
        case .InverterSN: return 0x07
        }
    }
}

enum DinRegulateFrequencyState: Int {
    case idle = 0                // 没有调频
    case onHold            // 等待调频过程中
    case fcrN        // FCR-N 模式
    case fcrDUp        // FCR-DUp 模式
    case fcrDDown        // FCR-DDown
    case fcrDUpDown
}

enum DinStorageBatteryPVPreference: Int {
    case ignore = 0         // 无效值，IoT 不会返回该值
    case followEmaldoAI      // 跟随AI策略
    case load              // 负载优先
    case batteryCharge      // 充电优先

    fileprivate var byte: UInt8 {
        switch self  {
        case .ignore: return 0x00
        case .followEmaldoAI: return 0x01 
        case .load: return 0x02
        case .batteryCharge: return 0x03
        }
    }
}

extension Bool {
    var byte: UInt8 { self ? 0x01 : 0x00 }
}

