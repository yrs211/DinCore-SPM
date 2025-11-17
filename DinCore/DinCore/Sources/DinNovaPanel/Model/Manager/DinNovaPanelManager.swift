//
//  DinNovaPanelManager.swift
//  DinCore
//
//  Created by Jin on 2021/5/12.
//

import UIKit
import HandyJSON
import RxSwift
import DinSupport

public class DinNovaPanelManager: NSObject, DinHomeDeviceManagerProtocol {

    public var homeID: String
    public var userID: String

    public var categoryID: String {
        DinNovaPanel.panelCategoryID
    }

    /// 用于监听每个主机的rx对象，如果主机删除，对应的disposeBag去掉
    private var disposeBagDict: [String: DisposeBag] = [:]

    private var unsafePanelOperators: [DinNovaPanelOperator]? = []
    var panelOperators: [DinNovaPanelOperator]? {
        var tempOperators: [DinNovaPanelOperator]?
        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        DinUser.homeDevicesSyncQueue.sync {
            tempOperators = self.unsafePanelOperators
        }
        return tempOperators
    }

    private var unsafePluginOperators: [String: [DinNovaPluginOperator]]? = [:]
    var pluginOperators: [String: [DinNovaPluginOperator]]? {
        var tempOperators: [String: [DinNovaPluginOperator]]?
        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        DinUser.homeDevicesSyncQueue.sync {
            tempOperators = self.unsafePluginOperators
        }
        return tempOperators
    }

    var addPlugsComplete: ((Bool, Bool, [DinHomeDeviceProtocol]?, DinHomeDeviceProtocol?) -> Void)?

    /// 新添加的配件的ID
    private var unsafePotentialPluginID: String? = ""
    var potentialPluginID: String? {
        var tempID: String?
        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        DinUser.homeDevicesSyncQueue.sync {
            tempID = self.unsafePotentialPluginID
        }
        return tempID
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        // 这里不能save了，因为数据不在同一个线程操作
//        saveAll()
    }
    public init(withHomeID homeID: String, userID: String) {
        self.homeID = homeID
        self.userID = userID
        super.init()
        self.fetchCachedDevice(complete: {})
        /// 如果app进入后台
        NotificationCenter.default.addObserver(self, selector: #selector(saveAll), name: UIApplication.willResignActiveNotification, object: nil)
        /// 如果app准备被kill
        NotificationCenter.default.addObserver(self, selector: #selector(saveAll), name: UIApplication.willTerminateNotification, object: nil)
    }

    @objc private func saveAll() {
        // 保存主机信息
        save()
        // 保存主机配件信息
        for panelOperator in panelOperators ?? [] {
            if let plugins = pluginOperators?[pluginKey(WithPanelID: panelOperator.id, deviceString: .doorWindowSensor)] {
                cachePlugins(plugins: plugins, deviceString: .doorWindowSensor, panelID: panelOperator.id)
                }
            if let plugins = pluginOperators?[pluginKey(WithPanelID: panelOperator.id, deviceString: .smartPlugin)] {
                cachePlugins(plugins: plugins, deviceString: .smartPlugin, panelID: panelOperator.id)
            }
            if let plugins = pluginOperators?[pluginKey(WithPanelID: panelOperator.id, deviceString: .signalRepeaterPlug)] {
                cachePlugins(plugins: plugins, deviceString: .signalRepeaterPlug, panelID: panelOperator.id)
            }
        }
    }

    private func fetchCachedDevice(complete: @escaping ()->()) {
        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
            self.unsafePanelOperators = self.getCache()
            self.unsafePanelOperators?.forEach({ panelOperator in
                let pluginKey = self.pluginKey(WithPanelID: panelOperator.id, deviceString: .doorWindowSensor)
                let plugins = self.getCachedPlugin(withDeviceString: .doorWindowSensor, panelOperator: panelOperator) ?? []
                self.unsafePluginOperators?[pluginKey] = plugins
            })
            self.unsafePanelOperators?.forEach({ panelOperator in
                let pluginKey = self.pluginKey(WithPanelID: panelOperator.id, deviceString: .smartPlugin)
                let plugins = self.getCachedPlugin(withDeviceString: .smartPlugin, panelOperator: panelOperator) ?? []
                self.unsafePluginOperators?[pluginKey] = plugins
            })
            self.unsafePanelOperators?.forEach({ panelOperator in
                let pluginKey = self.pluginKey(WithPanelID: panelOperator.id, deviceString: .signalRepeaterPlug)
                let plugins = self.getCachedPlugin(withDeviceString: .signalRepeaterPlug, panelOperator: panelOperator) ?? []
                self.unsafePluginOperators?[pluginKey] = plugins
            })
            DispatchQueue.global().async {
                complete()
            }
        }
    }

    static func listDeviceTokens(addTime: TimeInterval, homeID: String, order: String, pageSize: Int, complete: @escaping ([DinDeviceTokenModel]?)->()) {
        let request = DinNovaPanelRequest.listDeviceTokens(addTime: addTime, homeID: homeID, order: order, pageSize: pageSize)
        DinHttpProvider.request(request) { result in
            if let tokenDicts = result?["tokens"] as? [[String: Any]], let tokens = [DinDeviceTokenModel].deserialize(from: tokenDicts)?.compactMap({ $0 }) {
                complete(tokens)
            } else {
                complete(nil)
            }
        } fail: { (error) in
            complete(nil)
        }

    }

    static func getCareModeStatus(deviceID: String, homeID: String, complete: @escaping (DinCareModeStatus)->()) {
        let request = DinNovaPanelRequest.getCareModeStatus(deviceID: deviceID, homeID: homeID)
        DinHttpProvider.request(request) { result in
            if let careMode = DinCareModeStatus.deserialize(from: result) {
                complete(careMode)
            } else {
                complete(DinCareModeStatus())
            }
        } fail: { error in
            complete(DinCareModeStatus())
        }
    }

    /// 向服务器请求数据，获取最新的设备Device信息
    /// - Parameters:
    ///   - deviceID: 设备ID
    ///   - complete: 异步获取的设备。如果是nil则，获取失败
    static func getDevice(withIDs deviceIDs: [String], homeID: String, complete: @escaping (DinNovaPanel?)->()) {
        // 请求设备token
        DinNovaPanelManager.listDeviceTokens(addTime: 0, homeID: homeID, order: "asc", pageSize: 0) { tokens in
            if let tokenModel = tokens?.first {
                // 请求主机信息
                let getDeviceRequest = DinNovaPanelRequest.searchDevices(ids: deviceIDs, homeID: homeID)
                DinHttpProvider.request(getDeviceRequest) { (result) in
                    if let panels = result?["devices"] as? [[String: Any]],
                       let panel = DinNovaPanel.deserialize(from: panels.first) {
                        if panel.id.count < 1 {
                            panel.id = deviceIDs.first ?? ""
                        }
                        panel.token = tokenModel.token
                        panel.isLoading = false
                        if panel.online {
                            // 请求care mode当前状态
                            DinNovaPanelManager.getCareModeStatus(deviceID: tokenModel.id, homeID: homeID) { careMode in
                                panel.lastNoActionTimestamp = careMode.lastNoActionTime
                                panel.careModeNoActionTime = careMode.noActionTime
                                panel.careModeAlarmDelayTime = careMode.alarmDelayTime
                                complete(panel)
                            }
                        } else {
                            complete(panel)
                        }
                    } else {
                        complete(nil)
                    }
                } fail: { (error) in
                    complete(nil)
                }

            } else {
                complete(nil)
            }
        }
    }

    public func getHardDiskCachedDevices(complete: DinHomeGetDevicesBlock?) {
        complete?(getCache())
    }

    public func getDevices(onlyLoadCache: Bool, complete: DinHomeGetDevicesDiffBlock?) -> [DinHomeDeviceProtocol]? {
        if onlyLoadCache {
            // 同步一下修改线程，阻塞等待
            let semaphore = DispatchSemaphore(value: 1)
            // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
            DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
                // 主机的在线是false， loading = true
                self.unsafePanelOperators = self.getCache() ?? []
                DispatchQueue.main.async {
                    complete?(self.panelOperators ?? [], nil)
                    semaphore.signal()
                }
            }
            semaphore.wait()
            return panelOperators
        }

        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        DinCore.getHomeDetailInfo(homeID: homeID) { [weak self] home in
            if let panelDict = home.panelInfo,
               let deviceID = panelDict["deviceid"] as? String,
               !deviceID.isEmpty {
                DinNovaPanelManager.getDevice(withIDs: [deviceID], homeID: self?.homeID ?? "") { [weak self] result in
                    guard let self = self else { return }
                    // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
                    DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
                        if let panel = result {
                            panel.name = home.panelInfo?["name"] as? String ?? ""
                            let panelOperator = DinNovaPanelOperator(withPanelControl: DinNovaPanelControl(withPanel: panel, homeID: self.homeID))
                            self.unsafePanelOperators = [panelOperator]
                        } else {
                            if let panel = DinNovaPanel.deserialize(from: panelDict) {
                                panel.name = home.panelInfo?["name"] as? String ?? ""
                                panel.online = false
                                panel.isLoading = false
                                let panelOperator = DinNovaPanelOperator(withPanelControl: DinNovaPanelControl(withPanel: panel, homeID: self.homeID))
                                self.unsafePanelOperators = [panelOperator]
                            }
                        }
                        self.updateDisposeBagsInSafeQueue()
                        DispatchQueue.main.async {
                            self.save()
                            complete?(self.panelOperators, nil)
                        }
                    }
                }
            } else {
                guard let self = self else { return }
                // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
                DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
                    // 设置对应的delete
                    self.unsafePanelOperators = self.getCache() ?? []
                    // 在安全线程里面设置属性
                    DinUser.homeDeviceInfoQueue.async(flags: .barrier) {
                        for panelOperator in self.panelOperators ?? [] {
                            panelOperator.panelControl.updateIsLoading(false, usingSync: true, complete: nil)
                            panelOperator.setIsDeleted(true, usingSync: true, complete: nil)
                        }
                        DispatchQueue.main.async {
                            self.save()
                            complete?(self.panelOperators ?? [], nil)
                        }
                    }
                }
            }
        } fail: { _ in
            // 主机的在线是false， loading = false
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                for panelOperator in self.panelOperators ?? [] {
                    panelOperator.panelControl.updateIsLoading(false, usingSync: true, complete: nil)
                }
                DispatchQueue.main.async {
                    self.save()
                    complete?(self.panelOperators, nil)
                }
            }
        }
        // 同步一下修改线程，阻塞等待
        let semaphore = DispatchSemaphore(value: 1)
        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
            // 主机的在线是false， loading = true
            self.unsafePanelOperators = self.getCache() ?? []
            semaphore.signal()
        }
        semaphore.wait()
        return panelOperators
    }

    public func addDevice(_ device: DinHomeDeviceProtocol, complete: @escaping ()->(), inSafeQueue: Bool = false) {
        guard let newOperator = device as? DinNovaPanelOperator else {
            return
        }
        if inSafeQueue {
            // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
            unsafePanelOperators?.append(newOperator)
            updateDisposeBag(withPanelOperator: newOperator)
            DispatchQueue.global().async {
                self.save()
            }
            // 保证在同一个线程
            complete()
        } else {
            // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
            DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
                self.unsafePanelOperators?.append(newOperator)
                self.updateDisposeBag(withPanelOperator: newOperator)
                DispatchQueue.global().async {
                    self.save()
                    complete()
                }
            }
        }
    }

    public func removeDevice(_ deviceID: String, complete: DinHomeRemoveDeviceBlock?) {
        guard deviceID.count > 0 else {
            complete?(false)
            return
        }
        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
            guard let cacheOperators = self.unsafePanelOperators else {
                DispatchQueue.global().async {
                    complete?(false)
                }
                return
            }
            var exist = false
            for i in 0 ..< cacheOperators.count {
                let cacheOperator = cacheOperators[i]
                if cacheOperator.id == deviceID {
                    exist = true

                    let semaphore = DispatchSemaphore(value: 0)

                    // 从unsafePluginOperators中移除该主机的配件
                    let plugins: [DinNovaPluginOperator] = DinGetDeviceString.allCases
                        .compactMap { deviceString in
                            let pluginKey = self.pluginKey(WithPanelID: deviceID, deviceString: deviceString)
                            return self.unsafePluginOperators?.removeValue(forKey: pluginKey) }
                        .flatMap{ $0 }

                    // 移除缓存，并向上层抛出事件
                    DispatchQueue.main.async {
                        // MARK: ⚠️这里面不要访问和调用到任何涉及pluginOperators和panelOperators的方法，因为homeDevicesSyncQueue所在的线程处于阻塞状态，一访问就卡住了。
                        self.removePluginCache(panelID: deviceID)
                        cacheOperator.accept(deviceOperationResult: ["cmd": DinNovaPanelControl.CMD_PLUGINS_DELETE,
                                                                     "pluginIDs": plugins.map{ $0.id }])
                        semaphore.signal()
                    }

                    // 等待事件抛出后再移除主机
                    semaphore.wait()

                    self.removeDisposeBag(withPanelOperator: cacheOperator)
                    self.unsafePanelOperators?.remove(at: i)
                    DispatchQueue.global().async {
                        self.save()
                        complete?(true)
                    }
                    break
                }
            }
            if !exist {
                DispatchQueue.global().async {
                    complete?(false)
                }
            }
        }
    }
    
    public func setDeviceAsDeleted(_ deviceID: String, complete: ((Bool, [DinHomeDeviceProtocol]?, DinHomeDeviceProtocol?) -> Void)?) {
        guard deviceID.count > 0 else {
            complete?(false, nil, nil)
            return
        }
        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
            // 在安全线程里面设置属性
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) {
                if let panelOperator = self.panelOperators?.first(where: { $0.id == deviceID }) {
                    panelOperator.panelControl.updateIsLoading(false, usingSync: true, complete: nil)
                    panelOperator.setIsDeleted(true, usingSync: true, complete: nil)
                    DispatchQueue.main.async {
                        self.save()
                        complete?(true, self.panelOperators, panelOperator)
                    }
                } else {
                    DispatchQueue.main.async {
                        complete?(false, nil, nil)
                    }
                }
            }
        }
    }

    public func supportRemove(deviceInfo: Any, extraInfo info: Any?) -> Bool {
        ((deviceInfo as? [String: Any])?["cmd"] as? String == "DeviceRemoved" || (deviceInfo as? [String: Any])?["cmd"] as? String == DinNovaPanelControl.CMD_PLUGIN_DELETE) &&
        info is String
    }
    public func remove(deviceInfo: Any, extraInfo info: Any?, complete: ((Bool, Bool, [DinHomeDeviceProtocol]?, String?) -> Void)?) {
        guard
            let panelID = info as? String,
            let infoDict = deviceInfo as? [String: Any],
            let deviceInfoDict = infoDict["pluginInfo"] as? [String: Any],
            let targetID = deviceInfoDict["pluginid"] as? String
        else {
            complete?(false, false, nil, nil)
            return
        }

        var targetPanelOperator: DinNovaPanelOperator?
        for panelOperator in panelOperators ?? [] {
            if panelOperator.panelControl.panel.id == panelID {
                targetPanelOperator = panelOperator
            }
        }
        guard let panelOperator = targetPanelOperator else {
            complete?(false, false, nil, nil)
            return
        }

        checkPluginRemove(withDeviceID: targetID, toPanelOperator: panelOperator, complete: complete)
    }

    public func save() {
        cache(panels: panelOperators)
    }
}

/// 主机配件相关操作
extension DinNovaPanelManager {
    func pluginKey(WithPanelID panelID: String, deviceString: DinGetDeviceString) -> String {
        "\(panelID)_\(deviceString.rawValue)"
    }
    func panelIDAndGetDeviceString(withPluginKey pluginKey: String) -> (String, String) {
        let stringArr = pluginKey.components(separatedBy: "_")
        guard stringArr.count > 1 else {
            return ("","")
        }
        return (stringArr[0], stringArr[1])
    }
    /// 获取指定的配件
    /// - Parameters:
    ///   - deviceString: 指定配件种类
    ///   - info: 指定的主机id
    ///   - complete: 完成block
    /// - Returns: 是否符合操作条件
    public func getDevices(withDeviceString deviceString: DinGetDeviceString, andInfo info: Any?, complete: DinHomeGetDevicesBlock?) -> Bool {
        guard let deviceid = info as? String else {
            complete?(nil)
            return false
        }
        var targetPanelOperator: DinNovaPanelOperator?
        for panelOperator in panelOperators ?? [] {
            if panelOperator.panelControl.panel.id == deviceid {
                targetPanelOperator = panelOperator
            }
        }
        guard let panelOperator = targetPanelOperator else {
            complete?(nil)
            return false
        }
        switch deviceString {
        case .doorWindowSensor:
            // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
            getDoorWindowSensorList(WithPanelOperator: panelOperator, complete: { plugins in
                DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
                    var addedDevices: [DinNovaPluginOperator]? = nil
                    if let potentialPluginID = self.unsafePotentialPluginID {
                        addedDevices = plugins.filter{ $0.id == potentialPluginID }
                        self.unsafePotentialPluginID = nil
                    }
                    let pluginKey = self.pluginKey(WithPanelID: panelOperator.id, deviceString: .doorWindowSensor)
                    let pluginIDsToCheck = self.unsafePluginOperators?[pluginKey]?.map{ $0.id } ?? []
                    self.merge(deviceString: .doorWindowSensor, panelOperator: panelOperator, deviceIDs: pluginIDsToCheck, addedDevices: addedDevices, devicesResult: plugins, complete: { _, _ in
                        // main thread
                        complete?(plugins)
                    })
                }
            })
        case .smartPlugin:
            // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
            getSmartPlugList(WithPanelOperator: panelOperator) { plugins in
                DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
                    var addedDevices: [DinNovaPluginOperator]? = nil
                    if let potentialPluginID = self.unsafePotentialPluginID {
                        addedDevices = plugins.filter{ $0.id == potentialPluginID }
                        self.unsafePotentialPluginID = nil
                    }
                    let pluginKey = self.pluginKey(WithPanelID: panelOperator.id, deviceString: .smartPlugin)
                    let pluginIDsToCheck = self.unsafePluginOperators?[pluginKey]?.map{ $0.id } ?? []
                    self.merge(deviceString: .smartPlugin, panelOperator: panelOperator, deviceIDs: pluginIDsToCheck, addedDevices: addedDevices, devicesResult: plugins, complete: { _, _ in
                        // main thread
                        complete?(plugins)
                    })
                }
            }
        case .smartButton:
            getSmartButtonList(WithPanelOperator: panelOperator) { plugins in
                complete?(plugins)
            }
        case .siren:
            getSirenList(WithPanelOperator: panelOperator) { plugins in
                complete?(plugins)
            }
        case .remoteControl:
            getRemoteControlList(WithPanelOperator: panelOperator) { plugins in
                complete?(plugins)
            }
        case .relay:
            getRelayList(WithPanelOperator: panelOperator) { plugins in
                complete?(plugins)
            }
        case .securityAccessory:
            getSecurityAccessoryList(WithPanelOperator: panelOperator) { plugins in
                complete?(plugins)
            }
        case .keypad:
            getKeypadList(WithPanelOperator: panelOperator) { plugins in
                complete?(plugins)
            }
        case .signalRepeaterPlug:
            getSignalRepeaterPlugList(WithPanelOperator: panelOperator) { plugins in
                DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
                    var addedDevices: [DinNovaPluginOperator]? = nil
                    if let potentialPluginID = self.unsafePotentialPluginID {
                        addedDevices = plugins.filter{ $0.id == potentialPluginID }
                        self.unsafePotentialPluginID = nil
                    }
                    let pluginKey = self.pluginKey(WithPanelID: panelOperator.id, deviceString: .signalRepeaterPlug)
                    let pluginIDsToCheck = self.unsafePluginOperators?[pluginKey]?.map{ $0.id } ?? []
                    self.merge(deviceString: .signalRepeaterPlug, panelOperator: panelOperator, deviceIDs: pluginIDsToCheck, addedDevices: addedDevices, devicesResult: plugins, complete: { _, _ in
                        // main thread
                        complete?(plugins)
                    })
                }
            }
        case .smartPlugAndSignalRepeaterPlug:
            getSmartPlugAndSignalRepeaterPlugList(WithPanelOperator: panelOperator) { plugins in
                complete?(plugins)
            }
        }
        return true
    }

    public func shouldAdd(deviceInfo: Any, extraInfo info: Any?) -> Bool {
        ((deviceInfo as? [String: Any])?["cmd"] as? String == "DeviceAdded" || (deviceInfo as? [String: Any])?["cmd"] as? String == DinNovaPanelControl.CMD_PLUGIN_ADD) &&
        info is String
    }

    ///  添加特定的设备
    public func add(deviceInfo: Any, extraInfo info: Any?, complete: ((_ success: Bool, _ shouldNotifyGlobal: Bool, _ info: [DinHomeDeviceProtocol]?, _ deviceAdded: DinHomeDeviceProtocol?) -> Void)?) {
        guard
            let infoDict = deviceInfo as? [String: Any],
            let panelID = info as? String
        else {
            complete?(false, false, nil, nil)
            return
        }

        var targetPanelOperator: DinNovaPanelOperator?
        for panelOperator in panelOperators ?? [] {
            if panelOperator.panelControl.panel.id == panelID {
                targetPanelOperator = panelOperator
            }
        }
        guard let panelOperator = targetPanelOperator else {
            complete?(false, false, nil, nil)
            return
        }
        addPlugsComplete = complete
        panelOperator.panelControl.addPlugin(infoDict)
    }

//    public func add(deviceInfo: Any, extraInfo info: Any?, complete:((Bool, Any?) -> Void)?) -> Bool {
//        guard let infoDict = deviceInfo as? [String: Any], let panelID = info as? String else {
//            complete?(false, nil)
//            return false
//        }
//
//        var targetPanelOperator: DinNovaPanelOperator?
//        for panelOperator in panelOperators ?? [] {
//            if panelOperator.panelControl.panel.id == panelID {
//                targetPanelOperator = panelOperator
//            }
//        }
//        guard let panelOperator = targetPanelOperator else {
//            complete?(false, nil)
//            return false
//        }
//        addPlugsComplete = complete
//        panelOperator.panelControl.addPlugin(infoDict)
//        return true
//    }

    /// 缓存主机下的配件信息
    /// - Parameters:
    ///   - plugins: 最新的配件信息
    ///   - removedPluginIDs: 和服务器对比之后，删除的配件信息（注意：这里只是标注delete，如果是主动清理，会在别的地方去除）
    ///   - addedPlugins: 添加的配件信息
    ///   - deviceString: 配件类型字符串
    ///   - panelID: 主机ID
    ///   - needCache: 是否需要缓存
    private func cacheAndAlertPluginsChanged(plugins: [DinNovaPluginOperator]?,
                                             removedPluginIDs: [String]? = nil,
                                             addedPlugins: [DinNovaPluginOperator]? = nil,
                                             deviceString: DinGetDeviceString?,
                                             panelID: String,
                                             needCache: Bool = true) {
        guard let deviceString = deviceString else {
            return
        }
        if needCache {
            cachePlugins(plugins: plugins, deviceString: deviceString, panelID: panelID)
        }
        /// 找到对应的主机通知出去
        var targetPanelOperator: DinNovaPanelOperator?
        for panelOperator in panelOperators ?? [] {
            if panelOperator.panelControl.panel.id == panelID {
                targetPanelOperator = panelOperator
            }
        }
        guard let panelOperator = targetPanelOperator else {
            return
        }
        // 推出去的配件需要过滤一下
        let availablePlugins = plugins?.filter{ !$0.isDeleted }
        panelOperator.accept(deviceOperationResult: ["cmd": DinNovaPanelControl.CMD_PLUGINS_CHANGED_AFTERLOAD,
                                                     "typeString": deviceString.rawValue,
                                                     "plugins": availablePlugins ?? [],
                                                     "allPlugins": plugins ?? [],
                                                     "removedPluginIDs": removedPluginIDs ?? [],
                                                     "addedPlugins": addedPlugins ?? []])
    }

    public func shouldHandleNotification(_ notification: [String : Any]) -> Bool {
        return false
    }

    public func handleGroupNotification(_ notification: [String : Any], completion: ((Bool, [DinHomeDeviceProtocol]?, DinHomeNotificationIntent) -> Void)?) {
        completion?(false, nil, .ignore)
    }
}

/// 增加持有的主机回调监听，用来监听主机里面的配件的ws回调，然后更新配件信息和状态
extension DinNovaPanelManager {
    private func updateDisposeBagsInSafeQueue() {
        disposeBagDict.removeAll()
        for panelOperator in unsafePanelOperators ?? [] {
            updateDisposeBag(withPanelOperator: panelOperator)
        }
    }

    private func updateDisposeBag(withPanelOperator panelOperator: DinNovaPanelOperator) {
        let disposeBag = DisposeBag()
        disposeBagDict[panelOperator.id] = disposeBag
        addObserver(toPanelOperator: panelOperator, withDisposeBag: disposeBag)
    }

    private func removeDisposeBag(withPanelOperator panelOperator: DinNovaPanelOperator) {
        disposeBagDict.removeValue(forKey: panelOperator.id)
    }

    private func addObserver(toPanelOperator panelOperator: DinNovaPanelOperator, withDisposeBag disposeBag: DisposeBag) {
        panelOperator.deviceCallback.subscribe(onNext: { [weak self] result in
            if result["status"] as? Int == 1,
               let resultDict = result["result"] as? [String: Any] {
                if result["cmd"] as? String  == DinNovaPanelControl.CMD_PLUGIN_ADD {
                    self?.checkPluginAdded(withInfo: resultDict, toPanelOperator: panelOperator)
                } else if result["cmd"] as? String  == DinNovaPanelControl.CMD_PLUGIN_DELETE {
                    var pluginID = resultDict["plugin_id"] as? String ?? ""
                    if pluginID.isEmpty {
                        pluginID = resultDict["pluginid"] as? String ?? ""
                    }
                    self?.checkPluginRemove(withDeviceID: pluginID, toPanelOperator: panelOperator)
                }
            }
        }).disposed(by: disposeBag)
    }

    private func checkPluginAdded(withInfo info: [String: Any], toPanelOperator panelOperator: DinNovaPanelOperator) {
        let subCategory = info["stype"] as? String ?? ""
        let category = info["category"] as? Int ?? 0
        var pluginID = info["plugin_id"] as? String ?? ""
        if pluginID.isEmpty {
            pluginID = info["pluginid"] as? String ?? ""
        }
//                if DinAccessory.askSmartPlugStypes.contains(subCategory) || category == 3 {
//                    _ = self?.getDevices(withDeviceString: .smartPlugin, andInfo: panelOperator.id) { devices in
//                        let addDevice = devices?.first(where: { $0.id == pluginID })
//                        self?.addPlugsComplete?(true, false, devices, addDevice)
//                    }
//                } else {
//                    _ = self?.getDevices(withDeviceString: .doorWindowSensor, andInfo: panelOperator.id) { devices in
//                        let addDevice = devices?.first(where: { $0.id == pluginID })
//                        self?.addPlugsComplete?(true, false, devices, addDevice)
//                    }
//                }
        let isSmartPlugin = DinAccessory.smartPlugStypes.contains(subCategory) || category == 3
        let isRepeaterPlugin = DinAccessory.signalRepeaterPlugStypes.contains(subCategory)
        let isDoorWindowSensor = DinAccessory.askDoorWindowsStypes.contains(subCategory) || DinAccessory.oldDoorWindowsStypes.contains(subCategory)
        if isRepeaterPlugin || isSmartPlugin || isDoorWindowSensor {
            var deviceString: DinGetDeviceString {
                if isRepeaterPlugin {
                    return .signalRepeaterPlug
                } else if isSmartPlugin {
                    return .smartPlugin
                } else {
                    return .doorWindowSensor
                }
            }
            // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
            DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
                self.unsafePotentialPluginID = pluginID
                // getDevices(withDeviceString 里面有访问数组时候调用 DinUser.homeDevicesSyncQueue.sync 导致崩溃，这里切去子线程保平安
                DispatchQueue.global().async {
                    _ = self.getDevices(withDeviceString: deviceString, andInfo: panelOperator.id) { devices in
                        let addDevice = devices?.first(where: { $0.id == pluginID } ) as? DinNovaPluginOperator
                        self.addPlugsComplete?(true, false, devices, addDevice)
                    }
                }
            }
        }
    }
    private func checkPluginRemove(withDeviceID deviceID: String,
                                   toPanelOperator panelOperator: DinNovaPanelOperator,
                                   complete: ((Bool, Bool, [DinHomeDeviceProtocol]?, String?) -> Void)? = nil) {
        guard let pluginOperators = pluginOperators, !deviceID.isEmpty else {
            complete?(false, false, nil, nil)
            return
        }

        var targetKey = ""
        var targetIndex = -1
        let allKeys = Array(pluginOperators.keys)
        for key in allKeys {
            let values = pluginOperators[key] ?? []
            for i in 0 ..< values.count {
                let value = values[i]
                if value.id == deviceID {
                    targetKey = key
                    targetIndex = i
                    break
                }
            }
            // 找到了跳出循环
            if targetIndex >= 0 {
                break
            }
        }

        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
            self.unsafePluginOperators?[targetKey]?.remove(at: targetIndex)
            let (panelID, deviceString) = self.panelIDAndGetDeviceString(withPluginKey: targetKey)

            DispatchQueue.main.async {
                self.cacheAndAlertPluginsChanged(plugins: self.pluginOperators?[targetKey],
                                                  removedPluginIDs: [deviceID],
                                                  deviceString: DinGetDeviceString(rawValue: deviceString),
                                                  panelID: panelID)
                complete?(true, false, self.pluginOperators?[targetKey], deviceID)
            }
        }
    }
}

extension DinNovaPanelManager {
    private func saveKey() -> String {
        "DinHome_\(homeID)_\(DinNovaPanel.panelCategoryID)"
    }

    private func saveTimeKey() -> String {
        "DinHome_\(homeID)_\(DinNovaPanel.panelCategoryID)_SaveTime"
    }

    private func cache(panels: [DinNovaPanelOperator]?) {
        guard let cachePanels = panels else {
            removeCache()
            return
        }
        let saveTime = cachePanels.lastAddTime
        var saveStrings = [String]()
        for cachePanel in cachePanels {
            let saveString = cachePanel.saveJsonString
            if saveString.count > 0 {
                saveStrings.append(saveString)
            }
        }
        guard saveStrings.count > 0 else {
            removeCache()
            return
        }
        DinCore.dataBase.saveValueAsync(withKey: saveKey(), value: saveStrings)
        DinCore.dataBase.saveValueAsync(withKey: saveTimeKey(), value: saveTime)
    }

    private func getCache() -> [DinNovaPanelOperator]? {
        guard let cachePanelsStrings = DinCore.dataBase.hasValue(withKey: saveKey()) as? [String] else {
            return nil
        }
        var operators = [DinNovaPanelOperator]()
        for cachePanelsString in cachePanelsStrings {
            if let panelOperator = DinNovaPanelOperator(withPanelString: cachePanelsString, homeID: homeID) {
                operators.append(panelOperator)
            }
        }
        guard operators.count > 0 else {
            return nil
        }
        return operators
    }

    private func getSaveTime() -> Int64{
        return (DinCore.dataBase.hasValue(withKey: saveTimeKey()) as? Int64 ?? 1) + 1
    }

    private func removeCache() {
        DinCore.dataBase.removeValueAsync(withKey: saveKey())
        DinCore.dataBase.removeValueAsync(withKey: saveTimeKey())
    }
}

// 保存需要保存的配件
extension DinNovaPanelManager {
    private func savePluginKey(withDeviceString deviceString: DinGetDeviceString, panelID: String) -> String {
        "DinHome_\(homeID)_\(userID)_\(panelID)_\(deviceString.rawValue)"
    }

    private func savePluginTimeKey(withDeviceString deviceString: DinGetDeviceString, panelID: String) -> String {
        "DinHome_\(homeID)_\(userID)_\(panelID)_\(deviceString.rawValue)_SaveTime"
    }

    private func cachePlugins(plugins: [DinNovaPluginOperator]?, deviceString: DinGetDeviceString?, panelID: String) {
        guard let deviceString = deviceString else {
            return
        }
        guard panelID.count > 0 else {
            return
        }
        guard let cachePlugins = plugins else {
            removePluginCache(withDeviceString: deviceString, panelID: panelID)
            return
        }
        let saveTime = cachePlugins.lastAddTime
        var saveStrings = [String]()
        for cachePlugin in cachePlugins {
            let saveString = cachePlugin.saveJsonString
            if saveString.count > 0 {
                saveStrings.append(saveString)
            }
        }
        guard saveStrings.count > 0 else {
            removePluginCache(withDeviceString: deviceString, panelID: panelID)
            return
        }
        DinCore.dataBase.saveValueAsync(withKey: savePluginKey(withDeviceString: deviceString, panelID: panelID), value: saveStrings)
        DinCore.dataBase.saveValueAsync(withKey: savePluginTimeKey(withDeviceString: deviceString, panelID: panelID), value: saveTime)
    }

    func getPluginCache(withDeviceString deviceString: DinGetDeviceString, panelOperator: DinNovaPanelOperator, panelID: String) -> [DinNovaPluginOperator]? {
        guard panelID.count > 0,
              let cachePluginsStrings = DinCore.dataBase.hasValue(withKey: savePluginKey(withDeviceString: deviceString, panelID: panelID)) as? [String] else {
            return nil
        }
        var operators = [DinNovaPluginOperator]()
        for cachePluginsString in cachePluginsStrings {
            if let pluginControl = getPluginControl(withDeviceString: deviceString, cachePluginsString: cachePluginsString, panelOperator: panelOperator) {
                let pluginOperator = DinNovaPluginOperator(withPluginControl: pluginControl)
                operators.append(pluginOperator)
            }
        }
        guard operators.count > 0 else {
            return nil
        }
        return operators
    }
    private func getPluginControl(withDeviceString deviceString: DinGetDeviceString, cachePluginsString: String, panelOperator: DinNovaPanelOperator) -> DinNovaPluginControl? {
        guard cachePluginsString.count > 0 else { return nil }
        switch deviceString {
        case .doorWindowSensor:
            if let plugin = DinNovaDoorWindowSensor.deserialize(from: cachePluginsString) {
                // 从缓存读取的话，离线
                plugin.isOnline = false
                return DinNovaDoorWindowSensorControl(withPlugin: plugin, panelOperator: panelOperator)
            }
        case .smartPlugin:
            if let plugin = DinNovaSmartPlug.deserialize(from: cachePluginsString) {
                // 从缓存读取的话，离线
                plugin.isOnline = false
                return DinNovaSmartPlugControl(withPlugin: plugin, panelOperator: panelOperator)
            }
            break
        case .signalRepeaterPlug:
            if let plugin = DinNovaSmartPlug.deserialize(from: cachePluginsString) {
                // 从缓存读取的话，离线
                plugin.isOnline = false
                return DinNovaSmartPlugControl(withPlugin: plugin, panelOperator: panelOperator)
            }
        default:
            break
        }
        return nil
    }

    private func getPluginSaveTime(withDeviceString deviceString: DinGetDeviceString, panelID: String)  -> Int64 {
        return (DinCore.dataBase.hasValue(withKey: savePluginTimeKey(withDeviceString: deviceString, panelID: panelID)) as? Int64 ?? 1) + 1
    }

    private func removePluginCache(withDeviceString deviceString: DinGetDeviceString, panelID: String) {
        guard panelID.count > 0 else {
            return
        }
        DinCore.dataBase.removeValueAsync(withKey: savePluginKey(withDeviceString: deviceString, panelID: panelID))
        DinCore.dataBase.removeValueAsync(withKey: savePluginTimeKey(withDeviceString: deviceString, panelID: panelID))
    }

    private func removePluginCache(panelID: String) {
        guard panelID.count > 0 else {
            return
        }
        DinGetDeviceString.allCases.forEach { deviceString in
            removePluginCache(withDeviceString: deviceString, panelID: panelID)
        }
    }
}

//MARK: 2.0新增的方法
extension DinNovaPanelManager{

    //请直接使用getDevices(onlyLoadCache: false)
    public func searchDeviceFromServer(withIDs deviceIDs: [String], info: Any?, complete: ((Bool, [DinHomeDeviceProtocol]?) -> Void)?) {
        complete?(false, [])
    }
    
    public func acquireTemporaryDevices(withIDs deviceIDs: [String], info: Any?, complete: ((Bool, [any DinHomeDeviceProtocol]?) -> Void)?) {
        complete?(false, [])
    }

    //请直接使用getDevices(onlyLoadCache: false)
    public func getNewDevices(complete: DinHomeDeviceManagerProtocol.GetNewDeviceCompletion?) {
        complete?(false, categoryID, [], [])
    }

    //首页用，目前只支持ask配件
    public func getDevices(withDeviceString deviceString: DinGetDeviceString, panelId: String, andInfo info: Any?, onlyLoadCache: Bool, complete: ((Bool, [DinHomeDeviceProtocol]?) -> Void)?) -> Bool {
        guard let targetPanelOperator = panelOperators?.first(where: { $0.panelControl.panel.id == panelId }) else{
            complete?(false,[])
            return false
        }
        if onlyLoadCache {
            if deviceString == .doorWindowSensor,
               let plugins = pluginOperators?[pluginKey(WithPanelID: panelId, deviceString: .doorWindowSensor)] {
                complete?(true, plugins)
            }
            if deviceString == .smartPlugin,
               let plugins = pluginOperators?[pluginKey(WithPanelID: panelId, deviceString: .smartPlugin)] {
                complete?(true, plugins)
            }
            if deviceString == .signalRepeaterPlug,
               let plugins = pluginOperators?[pluginKey(WithPanelID: panelId, deviceString: .signalRepeaterPlug)] {
                complete?(true, plugins)
            }
            return true
        }

        if let info = info as? [[String:String]] {
            searchAskPlugin(withInfos: info, panelOperator: targetPanelOperator, homeID: homeID, deviceString: deviceString) { success, resultDevice, _ in
                complete?(success, resultDevice)
            }
        } else {
            getAskDevices(panelOperator: targetPanelOperator, homeID: homeID, deviceString: deviceString) { success, resultDevice, _ in
                complete?(success, resultDevice)
            }
        }
        return true
    }

    //首页用，目前只支持ask配件
    public func getNewDevices(withDeviceString deviceString: DinGetDeviceString, panelId: String, complete: DinHomeDeviceManagerProtocol.GetNewDeviceCompletion?) -> Bool {
        guard let panelOperator = panelOperators?.first(where: { $0.id == panelId }) else {
            return false
        }
        getNewAskDevice(panelOperator: panelOperator, homeID: homeID, deviceString: deviceString) { success, allDevices, brandNewDevices in
            complete?(success, deviceString.rawValue, allDevices, brandNewDevices)
        }
        return true
    }

    // 2.0获取首页的门磁和插座
    private func getAskDevices(panelOperator: DinNovaPanelOperator,
                               homeID: String,
                               deviceString: DinGetDeviceString,
                               complete: ((Bool, [DinNovaPluginOperator]?, [DinNovaPluginOperator]?)->())?) {
        let panelId = panelOperator.id
        if deviceString == .doorWindowSensor {
            let request = DinNovaPanelRequest.getAccessoryByAddTime(addTime: 1, deviceID: panelId, homeID: homeID, stypes: DinAccessory.supportSettingDoorWindowPushStatusTypes)
            DinHttpProvider.request(request) { [weak self] result in
                guard let self = self else { return }
                self.handleAskPluginData(deviceString: deviceString, panelOperator: panelOperator, deviceIDs: nil, responseDatas: result) { resultOperators, brandNewOperators in
                    complete?(true, resultOperators, brandNewOperators)
                }
            } fail: { error in
                complete?(false, [], [])
            }
        } else if deviceString == .smartPlugin {
            let request = DinNovaPanelRequest.getAccessoryByAddTime(addTime: 1, deviceID: panelId, homeID: homeID, stypes: DinAccessory.smartPlugStypes)
            DinHttpProvider.request(request) { [weak self] result in
                guard let self = self else { return }
                self.handleAskPluginData(deviceString: deviceString, panelOperator: panelOperator, deviceIDs: nil, responseDatas: result) { resultOperators, brandNewOperators in
                    complete?(true, resultOperators, brandNewOperators)
                }
            } fail: { error in
                complete?(false, [], [])
            }
        } else if deviceString == .signalRepeaterPlug {
            let request = DinNovaPanelRequest.getAccessoryByAddTime(addTime: 1, deviceID: panelId, homeID: homeID, stypes: DinAccessory.signalRepeaterPlugStypes)
            DinHttpProvider.request(request) { [weak self] result in
                guard let self = self else { return }
                self.handleAskPluginData(deviceString: deviceString, panelOperator: panelOperator, deviceIDs: nil, responseDatas: result) { resultOperators, brandNewOperators in
                    complete?(true, resultOperators, brandNewOperators)
                }
            } fail: { error in
                complete?(false, [], [])
            }
        }
    }

    // 2.0获取首页的门磁和插座
    private func getNewAskDevice(panelOperator: DinNovaPanelOperator,
                                 homeID: String,
                                 deviceString: DinGetDeviceString,
                                 complete: ((Bool, [DinNovaPluginOperator]?, [DinNovaPluginOperator]?)->())?) {
        let lastAddTime = self.getPluginSaveTime(withDeviceString: deviceString, panelID: panelOperator.id)
        if deviceString == .doorWindowSensor {
            let request = DinNovaPanelRequest.getAccessoryByAddTime(addTime: lastAddTime,
                                                                    deviceID: panelOperator.id,
                                                                    homeID: homeID,
                                                                    stypes: DinAccessory.supportSettingDoorWindowPushStatusTypes)
            DinHttpProvider.request(request) { [weak self] result in
                guard let self = self else { return }
                self.handleAskPluginData(deviceString: deviceString, panelOperator: panelOperator, deviceIDs: nil, responseDatas: result) { resultOperators, brandNewOperators  in
                    complete?(true, resultOperators, brandNewOperators)
                }
            } fail: { error in
                complete?(false, [], [])
            }
        }else if(deviceString == .smartPlugin){
            let request = DinNovaPanelRequest.getAccessoryByAddTime(addTime: lastAddTime, deviceID: panelOperator.id, homeID: homeID, stypes: DinAccessory.smartPlugStypes)
            DinHttpProvider.request(request) { [weak self] result in
                guard let self = self else { return }
                self.handleAskPluginData(deviceString: deviceString, panelOperator: panelOperator, deviceIDs: nil, responseDatas: result) { resultOperators, brandNewOperators  in
                    complete?(true, resultOperators, brandNewOperators)
                }
            } fail: { error in
                complete?(false, [], [])
            }
        } else if deviceString == .signalRepeaterPlug {
            let request = DinNovaPanelRequest.getAccessoryByAddTime(addTime: lastAddTime, deviceID: panelOperator.id, homeID: homeID, stypes: DinAccessory.signalRepeaterPlugStypes)
            DinHttpProvider.request(request) { [weak self] result in
                guard let self = self else { return }
                self.handleAskPluginData(deviceString: deviceString, panelOperator: panelOperator, deviceIDs: nil, responseDatas: result) { resultOperators, brandNewOperators  in
                    complete?(true, resultOperators, brandNewOperators)
                }
            } fail: { error in
                complete?(false, [], [])
            }
        }
    }

    //只支持ask配件
    private func searchAskPlugin(withInfos pluginInfos: [[String:String]],
                                 panelOperator: DinNovaPanelOperator,
                                 homeID: String,
                                 deviceString: DinGetDeviceString,
                                 complete:  ((Bool, [DinNovaPluginOperator]?, [DinNovaPluginOperator]?)->())?) {
        let deviceIDs = pluginInfos.map { info in
            info["id"] ?? ""
        }.filter{ !$0.isEmpty }
        if deviceString == .doorWindowSensor {
            let request = DinNovaPanelRequest.searchAccessories(accessories: pluginInfos, deviceID: panelOperator.panelControl.panel.id, homeID: homeID)
            DinHttpProvider.request(request) { [weak self] result in
                guard let self = self else { return }
                self.handleAskPluginData(deviceString: deviceString, panelOperator: panelOperator, deviceIDs: deviceIDs, responseDatas: result) { resultOperators, brandNewOperators in
                    complete?(true, resultOperators, brandNewOperators)
                }
            } fail: { error in
                complete?(false, [], [])
            }
        }else if(deviceString == .smartPlugin){
            let request = DinNovaPanelRequest.searchAccessories(accessories: pluginInfos, deviceID: panelOperator.panelControl.panel.id, homeID: homeID)
            DinHttpProvider.request(request) { [weak self] result in
                guard let self = self else { return }
                self.handleAskPluginData(deviceString: deviceString, panelOperator: panelOperator, deviceIDs: deviceIDs, responseDatas: result) { resultOperators, brandNewOperators in
                    complete?(true, resultOperators, brandNewOperators)
                }
            } fail: { error in
                complete?(false, [], [])
            }
        } else if deviceString == .signalRepeaterPlug {
            let request = DinNovaPanelRequest.searchAccessories(accessories: pluginInfos, deviceID: panelOperator.panelControl.panel.id, homeID: homeID)
            DinHttpProvider.request(request) { [weak self] result in
                guard let self = self else { return }
                self.handleAskPluginData(deviceString: deviceString, panelOperator: panelOperator, deviceIDs: deviceIDs, responseDatas: result) { resultOperators, brandNewOperators in
                    complete?(true, resultOperators, brandNewOperators)
                }
            } fail: { error in
                complete?(false, [], [])
            }
        }
    }

    /// 对返回的数据进行处理
    /// 只处理ask配件
    /// - Parameters:
    ///   - deviceString: deviceString
    ///   - deviceIDs: deviceIDs
    ///   - responseDevices: 服务器返回的设备
    /// - Returns: 合并后的设备



    /// 对返回的数据进行处理
    /// 只处理ask配件
    /// - Parameters:
    ///   - deviceString: deviceString
    ///   - panelOperator: panel operator
    ///   - deviceIDs: deviceIDs
    ///   - responseDatas: 服务器返回的配件Data数组
    ///   - complete: 完成回调 服务器返回的配件数组/本地缓存没有对应的配件数组（也就是全新的）
    private func handleAskPluginData(deviceString: DinGetDeviceString,
                                     panelOperator: DinNovaPanelOperator,
                                     deviceIDs: [String]?,
                                     responseDatas: [String: Any]?,
                                     complete: @escaping ([DinNovaPluginOperator], [DinNovaPluginOperator]?)->()) {
        if deviceString == .doorWindowSensor {
            self.handleAskDoorWindowSensorResult(responseDatas, panelOperator: panelOperator) { [weak self] resultOperators in
                self?.merge(deviceString: deviceString, panelOperator: panelOperator, deviceIDs: deviceIDs, devicesResult: resultOperators, complete: { resultPlugins, brandNewPlugins in
                    complete(resultPlugins, brandNewPlugins)
                })
            }
        } else if deviceString == .smartPlugin {
            self.handleAskSmartPlugsResult(responseDatas, panelOperator: panelOperator, complete: { [weak self] resultOperators in
                self?.merge(deviceString: deviceString, panelOperator: panelOperator, deviceIDs: deviceIDs, devicesResult: resultOperators, complete: { resultPlugins, brandNewPlugins in
                    complete(resultPlugins, brandNewPlugins)
                })
            })
        } else if deviceString == .signalRepeaterPlug {
            self.handleAskSmartPlugsResult(responseDatas, panelOperator: panelOperator, complete: { [weak self] resultOperators in
                self?.merge(deviceString: deviceString, panelOperator: panelOperator, deviceIDs: deviceIDs, devicesResult: resultOperators, complete: { resultPlugins, brandNewPlugins in
                    complete(resultPlugins, brandNewPlugins)
                })
            })
        }
    }

    // MARK: 将数据和当前设备数据合并, 并将变化推送到对应的主机
    /// 合并缓存配件和最新配件
    /// - Parameters:
    ///   - deviceString: 配件CategoryID
    ///   - panelOperator: 主机ID
    ///   - deviceIDs: 需要检查是否已删除的设备ID数组（如果 devicesResult 中不存在该设备，则视为已删除）
    ///   - addedDevices: 增加的配件
    ///   - devicesResult: 服务器返回的配件
    ///   - complete: 合并后的设备列表/原来没有的设备
    private func merge(deviceString: DinGetDeviceString,
                       panelOperator: DinNovaPanelOperator,
                       deviceIDs: [String]?,
                       addedDevices: [DinNovaPluginOperator]? = nil,
                       devicesResult: [DinNovaPluginOperator],
                       complete: @escaping ([DinNovaPluginOperator], [DinNovaPluginOperator]?)->()) {
        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
            let pluginKey = self.pluginKey(WithPanelID: panelOperator.id, deviceString: deviceString)
            var plugins = self.unsafePluginOperators?[pluginKey] ?? []

            if let deviceIDs = deviceIDs {
                plugins.merge(deviceIDs: deviceIDs, devices: devicesResult, inSafeQueue: true) { results in
                    let (resultOperators, brandNewOperators) = results
                    self.unsafePluginOperators?[pluginKey] = resultOperators
                    let removedPluginIDs = deviceIDs.filter { requestID in
                        !devicesResult.contains(where: { $0.id == requestID })
                    }
                    DispatchQueue.main.async {
                        self.cacheAndAlertPluginsChanged(plugins: resultOperators,
                                                         removedPluginIDs: removedPluginIDs,
                                                         addedPlugins: brandNewOperators,
                                                         deviceString: deviceString,
                                                         panelID: panelOperator.id)
                        complete(resultOperators, brandNewOperators)
                    }
                }
            } else {
                let (resultPlugins, brandNewPlugins) = plugins.merge(devices: devicesResult)
                plugins = resultPlugins
                self.unsafePluginOperators?[pluginKey] = plugins
                // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
                DispatchQueue.main.async {
                    self.cacheAndAlertPluginsChanged(plugins: plugins,
                                                     addedPlugins: brandNewPlugins,
                                                     deviceString: deviceString,
                                                     panelID: panelOperator.id)
                    complete(resultPlugins, brandNewPlugins)
                }
            }
        }
    }
}
