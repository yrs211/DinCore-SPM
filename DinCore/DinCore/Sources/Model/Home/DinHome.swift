//
//  DinHome.swift
//  DinCore
//
//  Created by Jin on 2021/4/23.
//

import UIKit
import HandyJSON
import RxSwift
import RxRelay
import DinSupport

public typealias DinHomeGetDevicesBlock = ([DinHomeDeviceProtocol]?) -> Void
public typealias DinHomeGetDevicesDiffBlock = ([DinHomeDeviceProtocol]?, [DinHomeDeviceProtocol]?) -> Void
public typealias DinHomeRemoveDeviceBlock = (Bool) -> Void

public enum DinGetDeviceString: String, CaseIterable {
    case doorWindowSensor = "doorWindowSensor"
    case smartPlugin = "smartPlugin"
    case smartButton = "smartButton"
    case siren = "siren"
    case remoteControl = "remoteControl"
    case relay = "relay"
    case securityAccessory = "securityAccessory"
    case keypad = "keypad"
    case signalRepeaterPlug = "signalRepeaterPlug"
    case smartPlugAndSignalRepeaterPlug = "smartPlugAndSignalRepeaterPlug"
}

/// 家庭
public class DinHome: DinModel {

    /// 家庭id
    open var id: String = "" {
        didSet {

        }
    }
    /// e2e通讯组id
    public var groupID: String = ""
    /// e2e通讯组通讯秘钥
    public var groupSecret: String = ""
    /// e2e通讯临时id
    public var commID: String = ""
    /// e2e通讯组员之间通讯秘钥
    public var commSecret: String = ""
    /// 家庭名
    public var name: String = ""
    /// 用户在当前家庭的权限
    public var level: Int = 10
    /// icon
    public var avatar: String = ""
    /// 操作token
    public var token: String = ""
    /// 家庭kcp是否链接中
    public var isConnected: Bool {
        (commControl?.networkState == .online) ?? false
    }
    /// 家庭里面的设备 [类别id: 设备]
    private var unsafeDevices: [String: [DinHomeDeviceProtocol]]? = [:]
    public var devices: [String: [DinHomeDeviceProtocol]]? {
        var tempDevices: [String: [DinHomeDeviceProtocol]]?
        DinUser.homeInfoQueue.sync { [weak self] in
            tempDevices = self?.unsafeDevices?.filter { !$0.value.isEmpty }
        }
        return tempDevices
    }
    /// 家庭的设备列表管理器
    private var unsafeDeviceManagers: [DinHomeDeviceManagerProtocol]? = []
    var deviceManagers: [DinHomeDeviceManagerProtocol]? {
        var tempDeviceManagers: [DinHomeDeviceManagerProtocol]?
        DinUser.homeInfoQueue.sync { [weak self] in
            tempDeviceManagers = self?.unsafeDeviceManagers
        }
        return tempDeviceManagers
    }
    /// 主机信息
    public var panelInfo: [String: Any]?
    /// 用户当前区域的国家区号，用来注册涂鸦账号的
    public var domain: String = ""
    /// 家庭成员
    private var unsafeMembers: [DinMember]? = []
    public var members: [DinMember]? {
        var tempMembers: [DinMember]?
        DinUser.homeInfoQueue.sync { [weak self] in
            tempMembers = self?.unsafeMembers
        }
        return tempMembers
    }
    
    public private(set) var isDeviceManagersInitialized = false

    public var commControl: DinUDPGroupControl?

    private var fetchDataRelays: [String: PublishRelay<Bool>] = [:]
    private var fetchDataDisposeBag: DisposeBag?

    private let fetchDeviceQueue = DispatchQueue(label: "com.heliopro.home.fetchdevices")

    public override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)
        mapper <<<
            self.id <-- "home_id"
        mapper <<<
            self.groupID <-- "group_id"
        mapper <<<
            self.name <-- ["home_name", "name"]
        mapper <<<
            self.panelInfo <-- "device"

        mapper >>> self.unsafeDevices
        mapper >>> self.unsafeDeviceManagers
        mapper >>> self.isDeviceManagersInitialized
        mapper >>> self.commControl
        mapper >>> self.fetchDataRelays
        mapper >>> self.fetchDataDisposeBag
    }

    func refreshData(by home: DinHome) {
        self.name = home.name
        self.level = home.level
        self.avatar = home.avatar
        self.token = home.token
        self.panelInfo = home.panelInfo
        self.domain = home.domain
    }

    /// 用于家庭的kcp 连接
    public func connect(complete: ((Bool) -> Void)?) {
        updateCommunicationInfo { [weak self] (success) in
            guard let self = self else {
                complete?(false)
                return
            }
            if success {
                let user = DinGroupCommunicator(withUniqueID: self.commID,
                                                groupID: self.groupID,
                                                commSecret: self.commSecret)
                guard let control = DinUDPGroupControl(withCommunicationGroup: DinCommunicationGroup(withGroupID: self.groupID, groupSecret: self.groupSecret), groupUser: user) else {
                    complete?(false)
                    return
                }
                self.commControl = control
                control.delegate = self
                self.commControl?.connect(complete: complete)
            } else {
                complete?(false)
            }
        }
    }
    private func updateCommunicationInfo(complete: ((Bool) -> Void)?) {
        DinCore.msctLogin(homeID: id) { [weak self] (result) in
            guard let resultDict = result else {
                complete?(false)
                return
            }
            guard let groupID = resultDict["group_id"] as? String, groupID.count > 0 else {
                complete?(false)
                return
            }
            // 服务器域名，用于多服务器节点时选择指定服务器节点
            guard let host = resultDict["host"] as? String, host.count > 0 else {
                complete?(false)
                return
            }
            // host 是domain+port
            let ipInfoArr = host.components(separatedBy: ":")
            guard ipInfoArr.count == 2, let domain = ipInfoArr.first, let port = UInt16(ipInfoArr.last ?? "0") else {
                complete?(false)
                return
            }
            // 查看有没有获取客户端公网地址的服务
            var getPublicIPHost = ""
            var getPublicIPPort: UInt16 = 0
            if let host = resultDict["util_host"] as? String, host.count > 0 {
                let utilHostInfoArr = host.components(separatedBy: ":")
                getPublicIPHost = utilHostInfoArr.first ?? ""
                getPublicIPPort = UInt16(utilHostInfoArr.last ?? "0") ?? 0
            }
            DinCore.updateUDPAddress(withDomain: domain,
                                     port: port,
                                     getPublicIPHost: getPublicIPHost,
                                     getPublicIPPort: getPublicIPPort)
            // 通讯端密钥，与服务器通讯时加密的密钥，不能公开
            self?.groupID = groupID
            guard let groupSecret = resultDict["end_secret"] as? String, groupSecret.count > 0 else {
                complete?(false)
                return
            }
            // 通讯端id，注意每次调用登录接口返回值都不一样
            self?.groupSecret = groupSecret
            guard let communicateID = resultDict["end_id"] as? String, communicateID.count > 0 else {
                complete?(false)
                return
            }
            // 和群组间成员通讯时的加密密钥，群组成员内共享，每次调用登录接口可能返回不一样的值
            self?.commID = communicateID
            guard let commSecret = resultDict["chat_secret"] as? String, commSecret.count > 0 else {
                complete?(false)
                return
            }
            self?.commSecret = commSecret
            complete?(true)
        } fail: { (_) in
            complete?(false)
        }
    }

    public func disconnect() {
        cache()
        commControl?.disconnect()
        commControl = nil
        DinCore.msctLogout(homeID: id, success: nil, fail: nil)
    }

    /// 添加管理器
    public func addDeviceManager(_ manager: DinHomeDeviceManagerProtocol) {
        // 去重， 用最新
        DinUser.homeInfoQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            if let managers = self.unsafeDeviceManagers {
                for i in 0 ..< managers.count {
                    let oldManager = self.unsafeDeviceManagers?[i]
                    if oldManager?.categoryID == manager.categoryID {
                        self.unsafeDeviceManagers?.remove(at: i)
                        break
                    }
                }
            } else {
                self.unsafeDeviceManagers = []
            }
            self.unsafeDeviceManagers?.append(manager)
        }
    }
    
    // 设备管理器的初始化已完成
    public func finalizeDeviceManagersInitialization() {
        isDeviceManagersInitialized = true
    }

    /// 初始化/刷新全部设备列表
    /// - Parameter onlyLoadCache: 只加载缓存，目前只用于界面预加载，不做数据同步
    public func fetchDevices(onlyLoadCache: Bool = false) {
            DinUser.homeInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.unsafeDevices?.removeAll()
                self.fetchDeviceQueue.async { [weak self] in
                    for deviceManager in self?.deviceManagers ?? [] {
                        let cacheDevices = deviceManager.getDevices(onlyLoadCache: onlyLoadCache, complete: { [weak self] (result, _) in
                            // 不仅仅加载缓存的话，要处理服务器返回的数据
                            if !onlyLoadCache {
                                self?.refreshDevices(result, deviceCategoryID: deviceManager.categoryID, complete: {})
                            }
                        })
                        if onlyLoadCache {
                            self?.refreshDevices(cacheDevices, deviceCategoryID: deviceManager.categoryID, complete: {})
                        }
                    }
            }
        }
    }

    /// 接收完所有消息再推送
    /// 如果 onlyLoadCache == true (只加载缓存), 则不会通过rx通知上层。
    /// 即 DinCore.eventBus.home.accept(devicesUpdated:) 不会被调用
    /// - Parameters:
    ///   - onlyLoadCache: 只加载缓存，目前只用于界面预加载，不做数据同步
    ///   - ignoredManagerIDs: 要忽略的管理器，因为它们有另外的加载流程
    ///   - complete: 完成回调
    public func fetchDevicesTilAllManagerReceive(onlyLoadCache: Bool = false, ignoredManagerIDs: [String] = [], complete: (()->())?) {
        fetchDeviceQueue.async { [weak self] in
            self?.fetchDataRelays.removeAll()
            // 根据Home的manager生成所有Relay来统一所有到达的消息
            for deviceManager in self?.deviceManagers ?? [] {
                if ignoredManagerIDs.contains(deviceManager.categoryID) {
                    continue
                }
                self?.fetchDataRelays[deviceManager.categoryID] = PublishRelay<Bool>()
            }
            // 注册所有的消息监听，统一到zip统筹管理
            if let relays = self?.fetchDataRelays.values, relays.count > 0 {
                let disposeBag = DisposeBag()
                self?.fetchDataDisposeBag = disposeBag
                Observable.zip(relays).subscribe(onNext: { [weak self] _ in
                    if !onlyLoadCache {
                        // 如果加载的是最新的数据，将设备刷新的消息推送到上层
                        for deviceManager in self?.deviceManagers ?? [] {
                            DinCore.homeDelegate?.dinCoreHomeDevicesDidUpdate(categoryID: deviceManager.categoryID,
                                                                              reason: .refreshed(devices: self?.devices?[deviceManager.categoryID] ?? []))
                        }
                    }
                    complete?()
                    // 取消订阅
                    self?.fetchDataDisposeBag = nil
                }).disposed(by: disposeBag)
            }
            // 加载数据
            for deviceManager in self?.deviceManagers ?? [] {
                if ignoredManagerIDs.contains(deviceManager.categoryID) {
                    continue
                }
                _ = deviceManager.getDevices(onlyLoadCache: onlyLoadCache, complete: { [weak self] (result, _) in
                    // 最后再根据onlyLoadCache判断是否提醒，暂时不提醒
                    self?.refreshDevices(result, deviceCategoryID: deviceManager.categoryID, notify: false, complete: {
                        self?.fetchDataRelays[deviceManager.categoryID]?.accept(true)
                    })
                })
            }
        }
    }
    private func refreshDevices(_ device: [DinHomeDeviceProtocol]?, addedDevices: [DinHomeDeviceProtocol]? = nil, deviceCategoryID: String, notify: Bool = true, complete: @escaping ()->()) {
        DinUser.homeInfoQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            if let newDevices = device, newDevices.count > 0 {
                self.unsafeDevices?[deviceCategoryID] = newDevices
            } else {
                self.unsafeDevices?.removeValue(forKey: deviceCategoryID)
            }
            // 用个子线程推送给上层，以防被卡住
            DispatchQueue.global().async { [weak self] in
                complete()
                if notify {
                    DinCore.homeDelegate?.dinCoreHomeDevicesDidUpdate(categoryID: deviceCategoryID,
                                                                      reason: .refreshed(devices: self?.devices?[deviceCategoryID] ?? []))
                    DinCore.homeDelegate?.dinCoreHomeDevicesDidUpdate(categoryID: deviceCategoryID,
                                                                      reason: .addDevices(devices: addedDevices ?? []))
                }
            }
        }
    }

    // 刷新某种类型的设备
    public func fetchSpecificDevices(categoryID: String, notify: Bool = true, complete: @escaping ()->() = {}) {
        for deviceManager in deviceManagers ?? [] where deviceManager.categoryID == categoryID {
            _ = deviceManager.getDevices(onlyLoadCache: false, complete: { [weak self] (result, addedDevices) in
                self?.refreshDevices(result, addedDevices: addedDevices, deviceCategoryID: deviceManager.categoryID, notify: notify, complete: complete)
            })
        }
    }

    /// 获取设备列表
    /// - Parameters:
    ///   - deviceString: 特指的设备种类字符
    ///   - info: 附带的信息，可以为任何值, DeviceManager自己适配
    ///   - complete: 完成回调
    public func getDevices(withDeviceString deviceString: DinGetDeviceString, andInfo info: Any?, complete: DinHomeGetDevicesBlock?) {
        for deviceManager in deviceManagers ?? [] {
            if deviceManager.getDevices(withDeviceString: deviceString, andInfo: info, complete: complete) {
                break
            }
        }
    }

    /// 添加特定设备
    /// - Parameter deviceInfo: 添加设备需要的特定信息
    ///   - complete: Bool: 是否成功， Any：附带的信息
    public func add(deviceInfo: Any, extraInfo: Any?, complete: ((Bool, [DinHomeDeviceProtocol]?) -> Void)?) {
        var managerHit = false
        defer {
            if !managerHit {
                complete?(false, nil)
            }
        }

        for deviceManager in deviceManagers ?? [] {
            if deviceManager.shouldAdd(deviceInfo: deviceInfo, extraInfo: extraInfo) {
                deviceManager.add(deviceInfo: deviceInfo, extraInfo: extraInfo) { [weak self] addSuccess, shouldNotifyGlobal, devicesOrNil, addedDevice in
                    guard let self = self else { return }
                    if shouldNotifyGlobal {
                        DinUser.homeInfoQueue.async(flags: .barrier) { [weak self] in
                            guard let self = self, let deviceAdded = addedDevice else { return }
                            self.unsafeDevices?[deviceManager.categoryID] = devicesOrNil
                            // 用个子线程推送给上层，以防被卡住
                            DispatchQueue.global().async {
                                DinCore.homeDelegate?.dinCoreHomeDevicesDidUpdate(categoryID: deviceManager.categoryID,
                                                                                  reason: .addDevices(devices: [deviceAdded]))
                            }
                        }
                    }
                    complete?(addSuccess, devicesOrNil)
                }
                managerHit = true
                break
            }
        }
    }

    /// 使用设备的类型ID快捷获取DinHomeDeviceProtocol数组
    /// - Parameter withCategoryID: DinHomeDeviceManagerProtocol里面的CategoryID, 由实现者自己定义
    /// - parameter includeDeleted: 有一部分是被标识为已删除的设备，需要过滤下
    public func getDevices(withCategoryID categoryID: String, includeDeleted: Bool = false) -> [DinHomeDeviceProtocol]? {
        var returnDevices: [DinHomeDeviceProtocol]?
        DinUser.homeInfoQueue.sync { [weak self] in
            let tempDevices = self?.unsafeDevices?.filter { !$0.value.isEmpty }
            returnDevices = tempDevices?[categoryID]
            returnDevices = returnDevices?.filter({ device in
                !(device.info["isDeleted"] as? Bool ?? false) || includeDeleted
            })
        }
        return returnDevices
    }

    /// 设备添加方法，用于将新设备添加到当前家庭以及对应的设备Manager中

    /// - Parameters:
    ///   - device: DinHomeDeviceManagerProtocol里面的CategoryID, 由实现者自己定义
    ///   - isAddedToManager: 此设备是否已经添加到对应的设备manager里
    ///   - notify: 是否通知更新到上层
    public func addDevice(_ device: DinHomeDeviceProtocol, isAddedToManager: Bool = false, withNotify notify: Bool = true, complete: (() -> Void)? = nil) {
        DinUser.homeInfoQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            for manager in self.unsafeDeviceManagers ?? [] {
                if manager.categoryID == device.manageTypeID {
                    if !isAddedToManager {
                        manager.addDevice(device, complete: {}, inSafeQueue: true)
                    }
                    // check if already added, yes? mark as replace for alert refresh, else alert added.
                    var isReplace: Bool = false
                    // 判断是否已在数组中，如果已在，则替换
                    if let targetDevices: [DinHomeDeviceProtocol] = self.unsafeDevices?[manager.categoryID] {
                        if !targetDevices.isEmpty {
                            for i in 0 ..< targetDevices.count {
                                let plug = targetDevices[i]
                                if plug.id == device.id {
                                    self.unsafeDevices?[manager.categoryID]?.remove(at: i)
                                    isReplace = true
                                    break
                                }
                            }
                        }
                    } else {
                        self.unsafeDevices?[manager.categoryID] = []
                    }
                    self.unsafeDevices?[manager.categoryID]?.append(device)
                    // 用个子线程推送给上层，以防被卡住
                    DispatchQueue.global().async {
                        if notify {
                            let reason: DevicesUpdateReason = isReplace ? .refreshed(devices: [device]) : .addDevices(devices: [device])
                            DinCore.homeDelegate?.dinCoreHomeDevicesDidUpdate(categoryID: manager.categoryID, reason: reason)
                        }
                        complete?()
                    }

                    break
                }
            }
        }
    }

    /// 删除缓存设备
    /// - Parameters:
    ///   - deviceID: 设备ID
    ///   - manageTypeID: 管理器ID
    ///   - success: 成功。如果没命中（本来就没有），也就是没有，当作删除成功，让上层返回首页
    ///   - fail: 失败
    public func removeDevice(_ deviceID: String, manageTypeID: String, success: (()->Void)?, fail: (()->Void)?) {
        var isHit = false
        for manager in deviceManagers ?? [] where manager.categoryID == manageTypeID {
            isHit = true
            manager.removeDevice(deviceID) { [weak self] (succeed) in
                DinUser.homeInfoQueue.async(flags: .barrier) { [weak self] in
                    guard let self = self else { return }
                    if succeed {
                        // 删除DinHome里持有的设备
                        if let removeIndex = self.unsafeDevices?[manager.categoryID]?.firstIndex(
                            where: { $0.id == deviceID || $0.info["cameraPID"] as? String == deviceID }
                        ) {
                            self.unsafeDevices?[manager.categoryID]?.remove(at: removeIndex)
                            if self.unsafeDevices?[manager.categoryID]?.count ?? 0 == 0 {
                                self.unsafeDevices?[manager.categoryID] = nil
                            }
                        }
                        // 用个子线程推送给上层，以防被卡住
                        DispatchQueue.global().async {
                            DinCore.homeDelegate?.dinCoreHomeDevicesDidUpdate(categoryID: manager.categoryID, reason: .removeDevices(deviceIds: [deviceID]))
                            success?()
                        }
                    } else {
                        // 用个子线程推送给上层，以防被卡住
                        DispatchQueue.global().async {
                            fail?()
                        }
                    }
                }
            }
            break
        }
        // 如果没命中，也就是没有，当作删除成功，让上层返回首页
        if !isHit {
            success?()
        }
    }

    /// 删除特定设备缓存
    /// - Parameter deviceInfo: 添加设备需要的特定信息
    ///   - complete: Bool: 是否成功， Any：附带的信息
    public func remove(deviceInfo: Any, extraInfo: Any?, complete: ((Bool, [DinHomeDeviceProtocol]?) -> Void)?) {
        var managerHit = false
        defer {
            if !managerHit {
                complete?(false, nil)
            }
        }

        for deviceManager in deviceManagers ?? [] {
            if deviceManager.supportRemove(deviceInfo: deviceInfo, extraInfo: extraInfo) {
                deviceManager.remove(deviceInfo: deviceInfo, extraInfo: extraInfo) { [weak self] removeSuccess, shouldNotifyGlobal, devicesOrNil, deviceRemoved in
                    guard let self = self else { return }
                    if shouldNotifyGlobal {
                        DinUser.homeInfoQueue.async(flags: .barrier) { [weak self] in
                            guard let self = self, let deviceRemoved = deviceRemoved else { return }
                            self.unsafeDevices?[deviceManager.categoryID] = devicesOrNil
                            // 用个子线程推送给上层，以防被卡住
                            DispatchQueue.global().async {
                                DinCore.homeDelegate?.dinCoreHomeDevicesDidUpdate(categoryID: deviceManager.categoryID,
                                                                                  reason: .removeDevices(deviceIds: [deviceRemoved]))
                            }
                        }
                    }
                    complete?(removeSuccess, devicesOrNil)
                }
                managerHit = true
                break
            }
        }
    }

    /// 将缓存的设备标记为已删除
    /// - Parameters:
    ///   - deviceID: 设备ID
    ///   - manageTypeID: 管理器ID
    ///   - success: 成功。如果没命中（本来就没有），也就是没有，当作标记成功，让上层返回首页
    ///   - fail: 失败
    public func setDeviceAsDeleted(_ deviceID: String, manageTypeID: String, success: (()->Void)?, fail: (()->Void)?) {
        var isHit = false
        for manager in deviceManagers ?? [] where manager.categoryID == manageTypeID {
            isHit = true
            manager.setDeviceAsDeleted(deviceID) { succeed, devicesOrNil, deletedDevice in
                DinUser.homeInfoQueue.async(flags: .barrier) { [weak self] in
                    guard let self = self else { return }
                    if succeed, let deletedDevice = deletedDevice {
                        self.unsafeDevices?[manager.categoryID] = devicesOrNil
                        // 用个子线程推送给上层，以防被卡住
                        DispatchQueue.global().async {
                            DinCore.homeDelegate?.dinCoreHomeDevicesDidUpdate(categoryID: manager.categoryID, reason: .refreshed(devices: [deletedDevice]))
                            success?()
                        }
                    } else {
                        // 用个子线程推送给上层，以防被卡住
                        DispatchQueue.global().async {
                            fail?()
                        }
                    }
                }
            }
            break
        }
        // 如果没命中，也就是没有，当作标记成功，让上层返回首页
        if !isHit {
            success?()
        }
    }

#if ENABLE_DINCORE_PANEL
    /// 查询是否有新主机绑定家庭
    public func checkPanelNewToHome() {
        guard let panelManager = deviceManagers?.first(where: { $0.categoryID == DinNovaPanel.panelCategoryID }) else {
            DinCore.homeDelegate?.dinCoreHomeDevicesDidUpdate(categoryID: DinNovaPanel.panelCategoryID, reason: .refreshed(devices: []))
            return
        }
        // 获取当前是否有主机，用与判断是否有新设备
        panelManager.getHardDiskCachedDevices { [weak self] resultDevices  in
            guard let self = self else { return }
            // 由于主机是没有getNew的接口的，所以直接判断，只要是从这里调用的，就是新添加了主机，只要缓存有主机，就是新的
            self.fetchSpecificDevices(categoryID: DinNovaPanel.panelCategoryID, notify: false, complete: { [weak self] in
                if let serverPanel = self?.getDevices(withCategoryID: DinNovaPanel.panelCategoryID)?.first {
                    var reason: DevicesUpdateReason?
                    if resultDevices?.first?.id == serverPanel.id {
                        reason = .refreshed(devices: [serverPanel])
                    } else {
                        reason = .addDevices(devices: [serverPanel])
                    }
                    if let realReason = reason {
                        DinCore.homeDelegate?.dinCoreHomeDevicesDidUpdate(categoryID: DinNovaPanel.panelCategoryID, reason: realReason)
                    }
                } else {
                    // 没有设备
                    DinCore.homeDelegate?.dinCoreHomeDevicesDidUpdate(categoryID: DinNovaPanel.panelCategoryID, reason: .refreshed(devices: []))
                }
            })
        }
    }
#endif

#if ENABLE_DINCORE_PANEL
    /// 绑定主机到家庭
    /// - 针对旧固件版本的主机，新固件版本的主机由它自己进行绑定
    /// - Parameters:
    ///   - deviceID: 即将绑定的主机 ID
    ///   - completion: 绑定完成回调
    public func bindPanelToHome(deviceID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let request = DinNovaPanelRequest.bindPanelToHome(
            homeID: id,
            panelID: deviceID
        )
        DinHttpProvider.request(request) { result in
            completion(.success(()))
        } fail: { error in
            completion(.failure(error))
        }
    }
#endif

    public func setMembers(_ members: [DinMember]?) {
        DinUser.homeInfoQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.unsafeMembers = members
        }
    }

    public func cache() {
        for manager in deviceManagers ?? [] {
            manager.save()
        }
    }
}

extension DinHome: DinUDPGroupControlDelegate {
    func control(_ control: DinUDPGroupControl, receivedGroupNotifyInfo info: [String : Any]) {

#if ENABLE_LOG
        if #available(iOS 14.0, *) {
            DinCoreLogger.msctNotification.debug("DinHome receivedGroupNotifyInfo => \(info)")
        }
#endif

        var managerHit = false
        defer {
            if !managerHit {
                // 检查一下是不是有用户权限变化，如果有，更新一下
                if info["cmd"] as? String == "AuthorityUpdated", let role = info["level"] as? Int {
                    // 这里是排除权限出现不是 10/20/30 的情况
                    switch role {
                    case 20:
                        level = 20
                    case 30:
                        level = 30
                    default:
                        level = 10
                    }
                }
                DinCore.homeDelegate?.dinCoreHomeDidReceiveNotification(info)
            }
        }

        for manager in deviceManagers ?? [] {
            if manager.shouldHandleNotification(info) {

                manager.handleGroupNotification(info) { [weak self, weak manager] (success, devicesOrNil, intent) in
                    guard let self = self, let manager = manager else { return }
                    if success {
                        DinUser.homeInfoQueue.async(flags: .barrier) { [weak self] in
                            guard let self = self else { return }
                            self.unsafeDevices?[manager.categoryID] = devicesOrNil
                            // notification intent
                            var reason: DevicesUpdateReason?
                            switch intent {
                            case .removeDevices(let deviceIDs):
                                reason = .removeDevices(deviceIds: deviceIDs)
                            case .addDevices(let devices):
                                reason = .addDevices(devices: devices)
                            case .renameDevice(let deviceID):
                                reason = .renameDevices(deviceId: deviceID)
                            case .refreshDevices(let devices):
                                reason = .refreshed(devices: devices)
                            case .regionUpdated(let deviceID):
                                reason = .regionUpdated(deviceId: deviceID)
                            case .ignore:
                                // 不需要处理
                                return
                            default:
                                break
                            }
                            // 用个子线程推送给上层，以防被卡住
                            DispatchQueue.global().async {
                                if let reason = reason {
                                    DinCore.homeDelegate?.dinCoreHomeDevicesDidUpdate(categoryID: manager.categoryID, reason: reason)
                                }
                                DinCore.homeDelegate?.dinCoreHomeDidReceiveNotification(info)
                            }
                        }
                    }
                }

                managerHit = true
                break
            }
        }
    }
}

//2.0新增的方法
//MARK: 更新家庭数据和设备
extension DinHome {
    /// 获取对应id的设备
    public func searchDeviceFromServer(withIDs deviceIDs: [String], info: Any? = nil, categoryID: String, notify: Bool = true, complete: ((Bool, [DinHomeDeviceProtocol]?) -> Void)?) {
        print("更新组件-——>7")
        for deviceManager in deviceManagers ?? [] {
            if deviceManager.categoryID == categoryID {
                deviceManager.searchDeviceFromServer(withIDs: deviceIDs, info: info) { [weak self] success, newDevices in
                    if success {
                        self?.replaceNew(devices: newDevices, deviceCategoryID: categoryID, complete: complete)
                    } else {
                        complete?(false, nil)
                    }
                }
            }
        }
    }
    private func replaceNew(devices: [DinHomeDeviceProtocol]?,
                            deviceCategoryID: String,
                            notify: Bool = true,
                            complete: ((Bool, [DinHomeDeviceProtocol]?) -> Void)?) {
        DinUser.homeInfoQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                complete?(false, nil)
                return
            }

            if let newDevices = devices, newDevices.count > 0 {
                var replaceDevices: [DinHomeDeviceProtocol] = []
                let oldDevices = self.unsafeDevices?[deviceCategoryID] ?? []
                // 替换已经存在的设备
                for oldDevice in oldDevices {
                    var exist = false
                    for newDevice in newDevices where oldDevice.id == newDevice.id {
                        replaceDevices.append(newDevice)
                        exist = true
                        break
                    }
                    if !exist {
                        replaceDevices.append(oldDevice)
                    }
                }
                // 把未存在的设备加进去
                for newDevice in newDevices {
                    var exist = false
                    for oldDevice in oldDevices where oldDevice.id == newDevice.id {
                        exist = true
                        break
                    }
                    if !exist {
                        replaceDevices.append(newDevice)
                    }
                }
                self.unsafeDevices?[deviceCategoryID] = replaceDevices
            }
            // 用个子线程推送给上层，以防被卡住
            DispatchQueue.global().async {
                if notify {
                    
                    print("更新组件-devices:\(devices)")
                  
                    DinCore.homeDelegate?.dinCoreHomeDevicesDidUpdate(categoryID: deviceCategoryID,
                                                                      reason: .refreshed(devices: devices ?? []))
                }
                complete?(true, devices)
            }
        }
    }
    
    public func acquireTemporaryDevices(withIDs deviceIDs: [String], info: Any? = nil, categoryID: String, complete: ((Bool, [DinHomeDeviceProtocol]?) -> Void)?) {
        for deviceManager in deviceManagers ?? [] {
            if deviceManager.categoryID == categoryID {
                deviceManager.acquireTemporaryDevices(withIDs: deviceIDs, info: info, complete: complete)
            }
        }
    }

    // MARK: 只能获取到ask配件
    /// 获取对应设备种类和设备id的设备列表
    public func getDevices(withDeviceString deviceString: DinGetDeviceString, panelId: String, andInfo info: Any?, onlyLoadCache: Bool = false, includeDeleted: Bool = false, complete:  ((Bool, [DinHomeDeviceProtocol]?) -> Void)?) {
        for deviceManager in deviceManagers ?? [] {
            let _ = deviceManager.getDevices(withDeviceString: deviceString, panelId: panelId, andInfo: info, onlyLoadCache: onlyLoadCache) { success, devices in
                let returnDevices = devices?.filter({ device in
                    !(device.info["isDeleted"] as? Bool ?? false) || includeDeleted
                })
                complete?(success, returnDevices)
            }
        }
    }

    /// 获取新设备
    /// - Parameter complete: 获取到新设备的回调（可能会回调多次）
    ///  (String, [DinHomeDeviceProtocol]?) = (categoryString, devices)
    public func getNewDevices(complete: DinHomeDeviceManagerProtocol.GetNewDeviceCompletion?) {
        for deviceManager in deviceManagers ?? [] {
            deviceManager.getNewDevices { [weak self] success, categoryID, allDevices, brandNewDevices in
                if success {
                    allDevices?.forEach{ self?.addDevice( $0, isAddedToManager: true, withNotify: false) }
                    complete?(success, categoryID, allDevices, brandNewDevices)
                }
            }
        }
    }

    /// 获取新设备
    /// - Parameter complete: 获取到新设备的回调（可能会回调多次）
    public func getNewDevices(withCategoryIDs categoryIDs: [String], notify: Bool, complete: DinHomeDeviceManagerProtocol.GetNewDeviceCompletion?) {
        for categoryID in categoryIDs {
            for deviceManager in deviceManagers ?? [] where deviceManager.categoryID == categoryID {
                deviceManager.getNewDevices { [weak self] success, categoryID, allDevices, brandNewDevices in
                    if success {
                        // 这里已经在manager里面添加好了
                        allDevices?.forEach{ self?.addDevice($0, isAddedToManager: true, withNotify: notify) }
                        complete?(success, categoryID, allDevices, brandNewDevices)
                    }
                }
                break
            }
        }
    }

    /// 获取新配件
    /// - Parameter complete: 获取到新配件的回调（可能会回调多次）
    /// - note: (String, [DinHomeDeviceProtocol]?) = (deviceTypeString, devices)
    public func getNewPlugins(panelId: String, complete: DinHomeDeviceManagerProtocol.GetNewDeviceCompletion?) {
        for deviceManager in deviceManagers ?? [] {
            //新增加的ask配件
            let deviceStrings:[DinGetDeviceString] = [.doorWindowSensor,.smartPlugin, .signalRepeaterPlug]
            deviceStrings.forEach { deviceString in
                let _ = deviceManager.getNewDevices(withDeviceString: deviceString, panelId: panelId) { success, categoryID, allDevices, brandNewDevices in
                    if success {
                        complete?(success, categoryID, allDevices, brandNewDevices)
                    }
                }
            }
        }
    }


    /// 刷新某种类型的设备
    ///
    /// - note: 和fetchSpecificDevices方法的作用很相似，区别在于最后发出的是sync事件，包含了更多信息
    public func syncDevices(categoryID: String) {
        let targetManagers = deviceManagers?
            .filter { $0.categoryID == categoryID }
            .compactMap { $0 as? DinDeviceListSyncProtocol } ?? []
        // 刷新设备
        targetManagers.forEach { deviceManager in
            deviceManager.syncDevices { [weak self] result in
                switch result {
                case .success(let response):
                    self?.refreshDevices(response.devices, deviceCategoryID: deviceManager.categoryID, notify: false, complete: {
                        let reason: DevicesUpdateReason = .sync(addedDevices: response.addedDevices, removedDeviceIds: response.removedDeviceIDs)
                        DinCore.homeDelegate?.dinCoreHomeDevicesDidUpdate(categoryID: deviceManager.categoryID, reason: reason)
                    })
                case .failure(_):
                    break
                }
            }
        }
    }

}
