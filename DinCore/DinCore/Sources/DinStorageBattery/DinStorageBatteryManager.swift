//
//  DinStorageBatteryManager.swift
//  DinCore
//
//  Created by monsoir on 11/28/22.
//

import Foundation
import HandyJSON
import RxSwift

public class DinStorageBatteryManager: NSObject, DinHomeDeviceManagerProtocol {

    public var homeID: String

    public var userID: String

    public var categoryID: String { "" }

    var model: String { fatalError("Implement in subclass") }

    private var unsafeOperatorsDisposeBag: DisposeBag?

    private var unsafeOperators: [DinStorageBatteryOperator]? = []{
        didSet {
            //  The property observers willSet and didSet are directly called from within the setter method, immediately before/after the new value is stored, so all this executes on the same thread.
            unsafeOperatorsDisposeBag = nil
            let disposeBag = DisposeBag()
            for unsafeOperator in unsafeOperators ?? [] {
                // 当前监听仅用于 修改名字后保存
                unsafeOperator.deviceCallback.subscribe(onNext: { [weak self] result in
                    guard let self = self else { return }
                    guard let cmd = result["cmd"] as? String else {
                        return
                    }
                    if cmd == DinStorageBatteryHTTPCommand.rename.rawValue {
                        self.save()
                    }
                }).disposed(by: disposeBag)
            }
            unsafeOperatorsDisposeBag = disposeBag
        }
    }

    var operators: [DinStorageBatteryOperator]? {
        var tempOperators: [DinStorageBatteryOperator]?
        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        DinUser.homeDevicesSyncQueue.sync {
            tempOperators = self.unsafeOperators
        }
        return tempOperators
    }

    var cacheKey: String { fatalError("Implement in subclass") }
    //use for save devices's last addtime
    var saveTimeKey: String  { fatalError("Implement in subclass") }

    init(homeID: String,userID: String) {
        self.homeID = homeID
        self.userID = userID
        super.init()
    }

    deinit {
        // 这里不能save了，因为数据不在同一个线程操作
//        save()
    }

    func createModel(from rawData: [String : Any]) -> DinStorageBattery? {
        fatalError("Implement in subclass")
    }

    func createControl(from model: DinStorageBattery, homeID: String) -> DinStorageBatteryControl {
        fatalError("Implement in subclass")
    }

    func createOperator(from control: DinStorageBatteryControl) -> DinStorageBatteryOperator {
        fatalError("Implment in subclass")
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
                self.unsafeOperators = self.getCache()
                DispatchQueue.main.async {
                    complete?(self.operators, nil)
                    semaphore.signal()
                }
            }
            semaphore.wait()
            return operators
        }

        let parameters = DinStorageBatteryRequest.GetDevicesParameters(homeID: homeID, models: [model], order: "asc", addTime: 1)
        let request = DinStorageBatteryRequest.getDevices(parameters)
        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        DinHttpProvider.request(
            request,
            success: { result in
                guard let items = result?["bmts"] as? [[String: Any]] else {
                    complete?(self.operators, nil)
                    return
                }
                let deviceIDsToCheck = self.operators?.map{ $0.id } ?? []
                self.updateLocalOperators(deviceIDs: deviceIDsToCheck, deviceDictArr: items) { resultDevices, addedDevices in
                    // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
                    DispatchQueue.main.async {
                        self.save()
                        complete?(self.operators, addedDevices)
                    }
                }
            },
            fail: { error in
                // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
                DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
                    self.unsafeOperators = self.getCache()
                    DispatchQueue.main.async {
                        complete?(self.operators, nil)
                    }
                }
            }
        )
        // 同步一下修改线程，阻塞等待
        let semaphore = DispatchSemaphore(value: 1)
        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
            self.unsafeOperators = self.getCache()
            semaphore.signal()
        }
        semaphore.wait()
        return operators
    }

    private func createOperators(from result:[[String: Any]]) -> [DinStorageBatteryOperator]{
        let resultDevices:[DinStorageBatteryOperator] = result.compactMap {
            guard let model = self.createModel(from: $0) else { return nil }
            let control = self.createControl(from: model, homeID: self.homeID)
            return self.createOperator(from: control)
        }
        return resultDevices
    }

    public func getDevices(withDeviceString deviceString: DinGetDeviceString, andInfo info: Any?, complete: DinHomeGetDevicesBlock?) -> Bool {
        false
    }

    public func addDevice(_ device: DinHomeDeviceProtocol, complete: @escaping ()->(), inSafeQueue: Bool = false) {
        // check type correction in subclass
        guard let `operator` = device as? DinStorageBatteryOperator else {
            complete()
            return
        }
        if inSafeQueue {
            // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
            self.unsafeOperators?.append(`operator`)
            DispatchQueue.global().async {
                self.save()
            }
            // 保证在同一个线程
            complete()
        } else {
            // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
            DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
                self.unsafeOperators?.append(`operator`)
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
            for i in 0 ..< (self.unsafeOperators?.count ?? 0) {
                let `operator` = self.unsafeOperators?[i]
                if `operator`?.id == deviceID {
                    self.unsafeOperators?.remove(at: i)
                    DispatchQueue.global().async {
                        self.save()
                        complete?(true)
                    }
                    return
                }
            }
            DispatchQueue.global().async {
                complete?(false)
            }
        }
    }

    public func save() {
        cache(operators: operators ?? [])
    }

    private func cache(operators: [DinStorageBatteryOperator]) {
        if operators.isEmpty {
            removeCache()
            return
        }

        let saveTime = operators.lastAddTime

        let rawStrings = operators.compactMap {
            let result = $0.saveJsonString
            return result.isEmpty ? nil : result
        }

        if rawStrings.isEmpty {
            removeCache()
            return
        }

        DinCore.dataBase.saveValueAsync(withKey: cacheKey, value: rawStrings)
        DinCore.dataBase.saveValueAsync(withKey: saveTimeKey, value: saveTime)
    }

    func createOperator(from rawString: String, homeID: String) -> DinStorageBatteryOperator? {
        fatalError("Implement in subclass")
    }

    private func getCache() -> [DinStorageBatteryOperator] {
        guard
            let rawStrings = DinCore.dataBase.hasValue(withKey: cacheKey) as? [String],
            !rawStrings.isEmpty
        else { return [] }

        let result = rawStrings.compactMap { createOperator(from: $0, homeID: homeID) }
        return result
    }

    private func getSaveTime() -> Int64{
        return (DinCore.dataBase.hasValue(withKey: saveTimeKey) as? Int64 ?? 1) + 1
    }

    private func removeCache() {
        DinCore.dataBase.removeValueAsync(withKey: cacheKey)
        DinCore.dataBase.removeValueAsync(withKey: saveTimeKey)
    }

    func renameDevice(identifiable: String, newName: String, complete: (()->())?) {
        guard let tempOp = operators?.first(where: { $0.id == identifiable }) else { return }
        tempOp.control.rename(newName, command: .rename, complete: complete)
    }
    
    func applyRegionUpdated(identifiable: String, countryCode: String, deliveryArea: String, complete: (()->())?) {
        guard let tempOp = operators?.first(where: { $0.id == identifiable }) else { return }
        tempOp.control.applyRegionUpdated(countryCode: countryCode, deliveryArea: deliveryArea) {
            complete?()
        }
    }

    func removeDeviceLocally(identifiable: String, complete: @escaping ()->()) {
        guard let index = operators?.firstIndex(
                where: { $0.id == identifiable }
        ) else {
            complete()
            return
        }
        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
            self.unsafeOperators?.remove(at: index)
            DispatchQueue.global().async {
                self.save()
                complete()
            }
        }
    }

    public func shouldHandleNotification(_ notification: [String : Any]) -> Bool {
        fatalError("Implement in subclass")
    }

    public func handleGroupNotification(_ notification: [String : Any], completion: ((Bool, [DinHomeDeviceProtocol]?, DinHomeNotificationIntent) -> Void)?) {
        fatalError("Implement in subclass")
    }
    
    public func getDevices(withDeviceString deviceString: DinGetDeviceString, panelId: String, andInfo info: Any?, onlyLoadCache: Bool, complete:  ((Bool, [DinHomeDeviceProtocol]?) -> Void)?) -> Bool { false }
    
    public func getNewDevices(withDeviceString deviceString: DinGetDeviceString, panelId: String, complete: GetNewDeviceCompletion?) -> Bool { false }
    
    public func shouldAdd(deviceInfo: Any, extraInfo info: Any?) -> Bool { false }
    
    public func add(deviceInfo: Any, extraInfo info: Any?, complete: ((_ success: Bool, _ shouldNotifyGlobal: Bool, _ info: [DinHomeDeviceProtocol]?, _ deviceAdded: DinHomeDeviceProtocol?) -> Void)?) { complete?(false, false, nil, nil) }
    
    public func supportRemove(deviceInfo: Any, extraInfo info: Any?) -> Bool { false }
    
    public func remove(deviceInfo: Any, extraInfo info: Any?, complete: ((_ success: Bool, _ shouldNotifyGlobal: Bool, _ info: [DinHomeDeviceProtocol]?, _ deviceRemoved: String?) -> Void)?)  { complete?(false, false, nil, nil) }
}

extension DinStorageBatteryManager {

    public func searchDeviceFromServer(withIDs deviceIDs: [String], info: Any?, complete: ((Bool, [DinHomeDeviceProtocol]?) -> Void)?) {
        typealias Condition = DinStorageBatteryRequest.SearchDeviceParameters.Condition
        let conditions = deviceIDs.map { deviceID in
            Condition(deviceID: deviceID, model: model)
        }
        let parameters = DinStorageBatteryRequest.SearchDeviceParameters(homeID: homeID, conditions: conditions)
        let request = DinStorageBatteryRequest.searchDevice(parameters)
        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        DinHttpProvider.request(
            request,
            success: { result in
                guard let items = result?["bmts"] as? [[String: Any]] else {
                    // 没有bmts字段时视为请求失败。如果找不到对应设备，一般都会返回数组，但是内容为空的
                    // {"bmts":[],"count":0,"gmtime":1709107212127320152}
                    complete?(false, [])
                    return
                }
                // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
                self.updateLocalOperators(deviceIDs: deviceIDs, deviceDictArr: items) { resultOpts, _ in
                    DispatchQueue.main.async {
                        self.save()
                        complete?(true, resultOpts)
                    }
                }
            },
            fail: { [weak self] error in
                guard let _ = self else { return }
                complete?(false, [])
            }
        )
    }
    ///获取临时设备列表
    public func acquireTemporaryDevices(withIDs deviceIDs: [String], info: Any?, complete: ((Bool, [any DinHomeDeviceProtocol]?) -> Void)?) {
        typealias Condition = DinStorageBatteryRequest.SearchDeviceParameters.Condition
        let conditions = deviceIDs.map { deviceID in
            Condition(deviceID: deviceID, model: model)
        }
        let parameters = DinStorageBatteryRequest.SearchDeviceParameters(homeID: homeID, conditions: conditions)
        let request = DinStorageBatteryRequest.searchDevice(parameters)
        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        DinHttpProvider.request(
            request,
            success: { [weak self] result in
                guard let items = result?["bmts"] as? [[String: Any]] else {
                    // 没有bmts字段时视为请求失败。如果找不到对应设备，一般都会返回数组，但是内容为空的
                    // {"bmts":[],"count":0,"gmtime":1709107212127320152}
                    complete?(false, [])
                    return
                }
                let resultOpts = self?.createOperators(from: items) ?? []
                complete?(true, resultOpts)
            },
            fail: { [weak self] error in
                guard let _ = self else { return }
                complete?(false, [])
            }
        )
    }

    //获取新设备
    public func getNewDevices(complete: DinHomeDeviceManagerProtocol.GetNewDeviceCompletion?) {
        let lastAddtime = getSaveTime()
        let parameters = DinStorageBatteryRequest.GetDevicesParameters(homeID: homeID, models: [model], order: "asc", addTime: lastAddtime)
        let request = DinStorageBatteryRequest.getDevices(parameters)
        DinHttpProvider.request(
            request,
            success: { [weak self] result in
                guard let self = self else { return }
                guard let items = result?["bmts"] as? [[String: Any]] else {
                    complete?(true, self.categoryID, [], [])
                    return
                }
                self.updateLocalOperators(deviceDictArr: items) { resultDevices, brandNewDevices in
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.save()
                        complete?(true, self.categoryID, resultDevices, brandNewDevices)
                    }
                }
            },
            fail: { [weak self] error in
                guard let self = self else { return }
                complete?(false, self.categoryID, [], [])
            }
        )
    }
    
    public func setDeviceAsDeleted(_ deviceID: String, complete: ((Bool, [DinHomeDeviceProtocol]?, DinHomeDeviceProtocol?) -> Void)?) {
        guard deviceID.count > 0 else {
            complete?(false, nil, nil)
            return
        }
        self.updateLocalOperators(deviceIDs: [deviceID], deviceDictArr: [], complete: { devices, _ in
            // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
            DispatchQueue.main.async {
                self.save()
                complete?(true, devices, devices.first(where: {$0.id == deviceID}))
            }
        })
    }

    /// 根据给定的设备数据更新本地设备
    /// 处理了某些设备需要更新或需要新添加的情况
    /// - Parameters:
    ///   - deviceDictArr: 服务器返回的设备数据
    ///   - complete: 完成回调
    ///               第一个参数是已更新的设备数组
    ///               第二个参数是新增设备的数组（如果有的话）
    private func updateLocalOperators(deviceDictArr: [[String: Any]],
                                      complete: @escaping ([DinHomeDeviceProtocol], [DinHomeDeviceProtocol]?)->()) {

        // 在安全线程处理属性
        DinUser.homeDeviceInfoQueue.async(flags: .barrier) {
            var tempOriDevices = self.operators ?? []
            var updatedOperators: [DinStorageBatteryOperator] = []
            var brandNewOperators: [DinStorageBatteryOperator] = []
            // Update the local cache with the new device information
            for deviceDict in deviceDictArr {
                if let deviceID = deviceDict["id"] as? String {
                    var found = false
                    // 如果设备已存在，更新设备信息
                    for `operator` in tempOriDevices {
                        if `operator`.id == deviceID {
                            `operator`.control.updateLocal(dict: deviceDict, usingSync: true, complete: nil)
                            `operator`.setIsDeleted(false, usingSync: true, complete: nil)
                            updatedOperators.append(`operator`)
                            found = true
                            break
                        }
                    }
                    // 如果设备不存在，创建新设备
                    if !found {
                        if let `operator` = self.createOperators(from: [deviceDict]).first {
                            tempOriDevices.append(`operator`)
                            updatedOperators.append(`operator`)
                            brandNewOperators.append(`operator`)
                        }
                    }
                }
            }

            // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
            DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
                self.unsafeOperators = tempOriDevices
                DispatchQueue.main.async {
                    complete(updatedOperators, brandNewOperators)
                }
            }
        }
    }

    /// 根据给定的设备ID和设备数据更新本地设备
    /// 处理了某些设备需要更新或需要新添加的情况，以及某些设备需要标记为已删除的情况
    /// - Parameters:
    ///   - deviceIDs: 需要检查是否已删除的设备ID数组（如果 deviceDictArr 中不存在该设备，则视为已删除）
    ///   - deviceDictArr: 服务器返回的设备数据
    ///   - complete: 完成回调
    ///               第一个参数是已更新的设备数组
    ///               第二个参数是新增设备的数组（如果有的话）
    private func updateLocalOperators(deviceIDs: [String],
                                      deviceDictArr: [[String: Any]],
                                      complete: @escaping ([DinHomeDeviceProtocol], [DinHomeDeviceProtocol]?)->()) {
        // 先处理好设备的更新和添加，再进行删除状态的检测
        updateLocalOperators(deviceDictArr: deviceDictArr) { updatedDevices, brandNewDevices in
            // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) {
                var resultDevices = updatedDevices
                let dataDeviceIDs = Set(deviceDictArr.map { $0["id"] as! String })
                for deviceID in deviceIDs {
                    // 如果设备已被删除，标记为已删除
                    if !dataDeviceIDs.contains(deviceID) {
                        if let `operator` = self.operators?.first(where: { $0.id == deviceID }){
                            `operator`.setIsDeleted(true, usingSync: true, complete: nil)
                            resultDevices.append(`operator`)
                        }
                    }
                }

                DispatchQueue.main.async {
                    complete(resultDevices, brandNewDevices)
                }
            }
        }
    }

}
