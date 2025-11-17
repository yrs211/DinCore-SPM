//
//  DinCameraManager.swift
//  DinCore
//
//  Created by Jin on 2021/6/16.
//

import UIKit
import HandyJSON
import RxSwift
import DinSupport

/// DinCameraManager's add devices entry point
/// 1.public func getDevices(onlyLoadCache: Bool, complete: DinHomeGetDevicesBlock?) -> [DinHomeDeviceProtocol]?
/// 2.public func shouldHandleNotification(_ notification: [String : Any]) -> Bool
/// 3.public func getNewDevices(complete: ((Bool, [DinHomeDeviceProtocol]?) -> Void)?)

public class DinCameraManager: NSObject, DinHomeDeviceManagerProtocol {

    public var homeID: String

    public var userID: String

    public var categoryID: String {
        DinCamera.categoryID
    }
    private var unsafeOperatorsDisposeBag: DisposeBag?

    private var unsafeCameraOperators: [DinCameraOperator]? = [] {
        didSet {
            //  The property observers willSet and didSet are directly called from within the setter method, immediately before/after the new value is stored, so all this executes on the same thread.
            unsafeOperatorsDisposeBag = nil
            let disposeBag = DisposeBag()
            for unsafeCameraOperator in unsafeCameraOperators ?? [] {
                // 当前监听仅用于 修改名字后保存
                unsafeCameraOperator.deviceCallback.subscribe(onNext: { [weak self] result in
                    guard let self = self else { return }
                    guard let cmd = result["cmd"] as? String else {
                        return
                    }
                    if cmd == DinLiveStreamingControl.CMD_SET_NAME {
                        self.save()
                    }
                }).disposed(by: disposeBag)
            }
            unsafeOperatorsDisposeBag = disposeBag
        }
    }

    var cameraOperators: [DinCameraOperator]? {
        var tempOperators: [DinCameraOperator]?
        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        DinUser.homeDevicesSyncQueue.sync {
            tempOperators = self.unsafeCameraOperators
        }
        return tempOperators
    }

    public init(withHomeID homeID: String, userID: String) {
        self.homeID = homeID
        self.userID = userID
        super.init()
    }

    deinit {
        // 这里不能save了，因为数据不在同一个线程操作
//        save()
    }

    func receive(info: Any) {
//        let camera = cameraOperators.first
//        camera?.liveStreamingControl
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
                self.unsafeCameraOperators = self.getCache() ?? []
                DispatchQueue.main.async {
                    complete?(self.cameraOperators, nil)
                    semaphore.signal()
                }
            }
            semaphore.wait()
            return cameraOperators
        }
        //2.0的API
        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        let request = DinLiveStreamingRequest.getDevicesByAddtime(addTime: 1, homeID: homeID, providers: [DinCamera.provider])
        DinHttpProvider.request(request) { result in
            if let camerasArr = result?["list"] as? [[String: Any]] {
                let deviceIDsToCheck = self.cameraOperators?.map{ $0.id } ?? []
                self.updateLocalDevices(deviceIDs: deviceIDsToCheck, deviceDictArr: camerasArr, complete: { _, addedDevices in
                    // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
                    DispatchQueue.main.async {
                        self.save()
                        complete?(self.cameraOperators, addedDevices)
                    }
                })
            } else {
                complete?(self.cameraOperators, nil)
            }
        } fail: { error in
            // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
            DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
                self.unsafeCameraOperators = self.getCache() ?? []
                DispatchQueue.main.async {
                    complete?(self.cameraOperators, nil)
                }
            }
        }
        // 同步一下修改线程，阻塞等待
        let semaphore = DispatchSemaphore(value: 1)
        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
            self.unsafeCameraOperators = self.getCache() ?? []
            semaphore.signal()
        }
        semaphore.wait()
        return cameraOperators
    }


    /// 获取与ipc同一个组的通讯id
//    private func getCameraCommunicationIDs(_ cameraIDs: [String]) {
//        let request = DinCameraRequest.loginCameras(homeID: homeID, camIDs: cameraIDs)
//        DinHttpProvider.request(request, success: { [weak self] result in
//            if let infoArr = result?["ipcs"] as? [[String: Any]] {
//                for info in infoArr {
//                    if let pid = info["pid"] as? String, let endid = info["end_id"] as? String {
//                        for camOperator in self?.cameraOperators ?? [] {
//                            if camOperator.id == pid {
//                                _ = camOperator.cameraControl.updateCameraCommunicator(withID: endid)
//                                break
//                            }
//                        }
//                    }
//                }
//            }
//        }, fail: nil)
//    }

    public func getDevices(withDeviceString deviceString: DinGetDeviceString, andInfo info: Any?, complete: DinHomeGetDevicesBlock?) -> Bool {
        false
    }

    public func addDevice(_ device: DinHomeDeviceProtocol, complete: @escaping ()->(), inSafeQueue: Bool = false) {
        guard let newOperator = device as? DinCameraOperator else {
            complete()
            return
        }
        if inSafeQueue {
            // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
            self.unsafeCameraOperators?.append(newOperator)
            DispatchQueue.global().async {
                self.save()
            }
            // 保证在同一个线程
            complete()
        } else {
            // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
            DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
                self.unsafeCameraOperators?.append(newOperator)
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
            for i in 0 ..< (self.unsafeCameraOperators?.count ?? 0) {
                let camOperator = self.unsafeCameraOperators?[i]
                if camOperator?.id == deviceID || camOperator?.info["cameraPID"] as? String == deviceID {
                    self.unsafeCameraOperators?.remove(at: i)
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
        cache(cameras: cameraOperators)
    }

    public func shouldHandleNotification(_ notification: [String : Any]) -> Bool {
        (["new-ipc", "del-ipc", "rename-ipc", "ipc-ver-num-updated"].contains(notification["cmd"] as? String ?? "")) &&
        notification["provider"] as? String == DinCamera.provider &&
        (notification["pid"] as? String)?.isEmpty == false
    }

    public func handleGroupNotification(_ notification: [String : Any], completion: ((Bool, [DinHomeDeviceProtocol]?, DinHomeNotificationIntent) -> Void)?) {
        guard let cmd = notification["cmd"] as? String, !cmd.isEmpty else {
            completion?(false, nil, .ignore)
            return
        }

        switch cmd {
        case "new-ipc":
            getNewDevices { [weak self] success, catID, allDevices, brandNewDevices in
                guard let self = self, let camID = notification["pid"] as? String else { return }
                guard let allDevices = allDevices, let _ = allDevices.first(where: { $0.id == camID }) else {
                    completion?(false, nil, .ignore)
                    return
                }
                // 如果缓存有该设备，就提示refresh，否则就是新添加
                completion?(true, self.cameraOperators, (brandNewDevices?.isEmpty ?? true) ? .refreshDevices(allDevices) : .addDevices(brandNewDevices ?? []))
            }
        case "rename-ipc":
            renameDevice(
                identifiable: notification["pid"] as? String ?? "",
                newName: notification["name"] as? String ?? "---") {
                    guard let camID = notification["pid"] as? String else {
                        completion?(false, nil, .ignore)
                        return
                    }
                    completion?(true, self.cameraOperators, .renameDevice(deviceID: camID))
                }
        case "del-ipc":
            removeDeviceLocally(identifiable: notification["pid"] as? String ?? "") { [weak self] in
                guard let self = self, let camID = notification["pid"] as? String else {
                    completion?(false, nil, .ignore)
                    return
                }
                completion?(true, self.cameraOperators, .removeDevices(deviceIds: [camID]))
            }
        case "ipc-ver-num-updated":
            if let device = cameraOperators?.first(where: { $0.id == notification["pid"] as? String }),
               let versions = notification["versions"] as? [[String: String]] {
                device.liveStreamingControl.update(versions: versions) { [weak self] in
                    guard let self = self else { return }
                    completion?(true, self.cameraOperators, .versionUpdated(deviceID: notification["pid"] as? String ?? ""))
                }
                return
            }
            completion?(false, self.cameraOperators, .ignore)
        default:
            completion?(false, nil, .ignore)
        }
    }

    private func getDevice(identifiable: String, completion: ((Bool, DinCameraOperator?) -> Void)?) {
        let request = DinLiveStreamingRequest.getDevices(homeID: homeID, providers: [DinCamera.provider])
        DinHttpProvider.request(request) { [weak self] result in
            guard let self = self else { return }
            guard
                let camerasArr = result?["list"] as? [[String: Any]],
                let newCamera = camerasArr
                    .compactMap({ DinCamera.deserialize(from: $0) })
                    .first(where: { $0.id == identifiable })
            else {
                completion?(false, nil)
                return
            }

            let result = DinCameraOperator(
                liveStreamingControl: DinLiveStreamingControl(
                    withCommunicationDevice: newCamera,
                    belongsToHome: self.homeID
                )
            )
            completion?(true, result)
        } fail: { error in
            completion?(false, nil)
        }
    }

    private func renameDevice(identifiable: String, newName: String, complete: (()->())?) {
        guard let camera = cameraOperators?.first(where: { $0.id == identifiable }) else { return }
        camera.liveStreamingControl.rename(newName) {
            complete?()
        }
    }

    private func removeDeviceLocally(identifiable: String, complete: @escaping ()->()) {
        guard let index = cameraOperators?.firstIndex(
                where: { $0.id == identifiable || $0.info["cameraPID"] as? String == identifiable }
        ) else {
            complete()
            return
        }
        DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
            self.unsafeCameraOperators?.remove(at: index)
            DispatchQueue.global().async {
                self.save()
                complete()
            }
        }
    }
    
    public func getDevices(withDeviceString deviceString: DinGetDeviceString, panelId: String, andInfo info: Any?, onlyLoadCache: Bool, complete:  ((Bool, [DinHomeDeviceProtocol]?) -> Void)?) -> Bool { false }
    
    public func getNewDevices(withDeviceString deviceString: DinGetDeviceString, panelId: String, complete: GetNewDeviceCompletion?) -> Bool { false }
    
    public func shouldAdd(deviceInfo: Any, extraInfo info: Any?) -> Bool { false }
    
    public func add(deviceInfo: Any, extraInfo info: Any?, complete: ((_ success: Bool, _ shouldNotifyGlobal: Bool, _ info: [DinHomeDeviceProtocol]?, _ deviceAdded: DinHomeDeviceProtocol?) -> Void)?) { complete?(false, false, nil, nil) }
    
    public func supportRemove(deviceInfo: Any, extraInfo info: Any?) -> Bool { false }
    
    public func remove(deviceInfo: Any, extraInfo info: Any?, complete: ((_ success: Bool, _ shouldNotifyGlobal: Bool, _ info: [DinHomeDeviceProtocol]?, _ deviceRemoved: String?) -> Void)?)  { complete?(false, false, nil, nil) }
}

extension DinCameraManager {
    private func saveKey() -> String {
        "DinHome_\(homeID)_\(userID)_\(DinCamera.categoryID)"
    }

    private func saveTimeKey() -> String {
        "DinHome_\(homeID)_\(userID)_\(DinCamera.categoryID)_SaveTime"
    }

    private func cache(cameras: [DinCameraOperator]?) {
        guard let cacheCameras = cameras else {
            removeCache()
            return
        }

        let saveTime = cacheCameras.lastAddTime
        var saveStrings = [String]()
        for cacheCamera in cacheCameras {
            let saveString = cacheCamera.saveJsonString
            if saveString.count > 0 {
                saveStrings.append(saveString)
            }
        }
        guard saveStrings.count > 0 else {
            removeCache()
            return
        }
        DinCore.dataBase.saveValueAsync(withKey: saveTimeKey(), value: saveTime)
        DinCore.dataBase.saveValueAsync(withKey: saveKey(), value: saveStrings)
    }

    private func getCache() -> [DinCameraOperator]? {
        guard let cacheCamerasStrings = DinCore.dataBase.hasValue(withKey: saveKey()) as? [String] else {
            return nil
        }
        var operators = [DinCameraOperator]()
        for cacheCamerasString in cacheCamerasStrings {
            if let cameraOperator = DinCameraOperator(deviceInfo: cacheCamerasString, homeID: homeID) {
                operators.append(cameraOperator)
            }
        }
        guard operators.count > 0 else {
            return nil
        }
        return operators
    }



    private func getSaveTime() -> Int64 {
        return (DinCore.dataBase.hasValue(withKey: saveTimeKey()) as? Int64 ?? 1) + 1
    }

    private func removeCache() {
        DinCore.dataBase.removeValueAsync(withKey: saveKey())
        DinCore.dataBase.removeValueAsync(withKey: saveTimeKey())
    }
}

//MARK: 2.0新增的方法
extension DinCameraManager {
    //获取对应id的设备
    public func searchDeviceFromServer(withIDs deviceIDs: [String], info: Any?, complete: ((Bool, [DinHomeDeviceProtocol]?) -> Void)?) {
        let pids = deviceIDs.map { pid in
            var item: [String: String] = [:]
            item["pid"] = pid
            item["provider"] = DinCamera.provider
            return item
        }
        let request = DinLiveStreamingRequest.searchDevices(homeID: homeID, pids: pids)
        DinHttpProvider.request(request) { [weak self] result in
            if let camerasArr = result?["list"] as? [[String: Any]] {
                self?.updateLocalDevices(deviceIDs: deviceIDs, deviceDictArr: camerasArr, complete: { resultDevices, _ in
                    DispatchQueue.main.async { [weak self] in
                        self?.cache(cameras: self?.cameraOperators)
                        complete?(true, resultDevices)
                    }
                })
            } else {
                complete?(false, [])
            }
        } fail: { error in
            complete?(false, [])
        }
    }
    
    public func acquireTemporaryDevices(withIDs deviceIDs: [String], info: Any?, complete: ((Bool, [any DinHomeDeviceProtocol]?) -> Void)?) {
        let pids = deviceIDs.map { pid in
            var item: [String: String] = [:]
            item["pid"] = pid
            item["provider"] = DinCamera.provider
            return item
        }
        let request = DinLiveStreamingRequest.searchDevices(homeID: homeID, pids: pids)
        DinHttpProvider.request(request) { [weak self] result in
            if let camerasArr = result?["list"] as? [[String: Any]] {
                var resultDevices: [DinCameraOperator] = []
                for cameraArr in camerasArr {
                    if let deviceID = cameraArr["pid"] as? String, let camera = DinCamera.deserialize(from: cameraArr) {
                        resultDevices.append(DinCameraOperator(liveStreamingControl: DinLiveStreamingControl(withCommunicationDevice: camera, belongsToHome: self?.homeID ?? "")))
                    }
                }
                complete?(true, resultDevices)
            } else {
                complete?(false, [])
            }
        } fail: { error in
            complete?(false, [])
        }
    }

    //获取新设备
    public func getNewDevices(complete: DinHomeDeviceManagerProtocol.GetNewDeviceCompletion?) {
        let lastAddTime = getSaveTime()
        let request = DinLiveStreamingRequest.getDevicesByAddtime(addTime: lastAddTime, homeID: homeID, providers: [DinCamera.provider])
        DinHttpProvider.request(request) { [weak self] result in
            if let camerasArr = result?["list"] as? [[String: Any]] {
                self?.updateLocalDevices(deviceDictArr: camerasArr, complete: { resultDevices, brandNewDevices in
                    DispatchQueue.main.async { [weak self] in
                        self?.cache(cameras: self?.cameraOperators)
                        complete?(true, self?.categoryID ?? "", resultDevices, brandNewDevices)
                    }
                })
            } else {
                complete?(false, self?.categoryID ?? "", [], [])
            }
        } fail: { [weak self] error in
            complete?(false, self?.categoryID ?? "", [], [])
        }
    }
    
    public func setDeviceAsDeleted(_ deviceID: String, complete: ((Bool, [DinHomeDeviceProtocol]?, DinHomeDeviceProtocol?) -> Void)?) {
        guard deviceID.count > 0 else {
            complete?(false, nil, nil)
            return
        }
        self.updateLocalDevices(deviceIDs: [deviceID], deviceDictArr: [], complete: { devices, _ in
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
    private func updateLocalDevices(deviceDictArr: [[String: Any]],
                                    complete: @escaping ([DinHomeDeviceProtocol], [DinHomeDeviceProtocol]?)->()) {
        // 在安全线程处理属性
        DinUser.homeDeviceInfoQueue.async(flags: .barrier) {
            var tempOriDevices = self.cameraOperators ?? []
            var updatedDevices: [DinCameraOperator] = []
            var brandNewDevices: [DinCameraOperator] = []
            for deviceDict in deviceDictArr {
                if let deviceID = deviceDict["pid"] as? String {
                    var found = false
                    // 如果设备已存在，更新设备信息
                    for cameraOperator in tempOriDevices {
                        if cameraOperator.id == deviceID {
                            cameraOperator.liveStreamingControl.updateLocal(dict: deviceDict, usingSync: true, complete: nil)
                            cameraOperator.setIsDeleted(false, usingSync: true, complete: nil)
                            updatedDevices.append(cameraOperator)
                            found = true
                            break
                        }
                    }
                    // 如果设备不存在，创建新设备
                    if !found {
                        if let camera = DinCamera.deserialize(from: deviceDict) {
                            let deivice = DinCameraOperator(liveStreamingControl: DinLiveStreamingControl(withCommunicationDevice: camera, belongsToHome: self.homeID))
                            tempOriDevices.append(deivice)
                            updatedDevices.append(deivice)
                            brandNewDevices.append(deivice)
                        }
                    }
                }
            }

            // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
            DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
                self.unsafeCameraOperators = tempOriDevices
                DispatchQueue.main.async {
                    complete(updatedDevices, brandNewDevices)
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
    private func updateLocalDevices(deviceIDs: [String],
                                    deviceDictArr: [[String: Any]],
                                    complete: @escaping ([DinHomeDeviceProtocol], [DinHomeDeviceProtocol]?)->()) {
        // 先处理好设备的更新和添加，再进行删除状态的检测
        updateLocalDevices(deviceDictArr: deviceDictArr) { updatedDevices, brandNewDevices in
            // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) {
                var resultDevices = updatedDevices
                // 如果设备已被删除，标记为已删除
                let dataDeviceIDs = Set(deviceDictArr.map { $0["pid"] as? String })
                for deviceID in deviceIDs {
                    if !dataDeviceIDs.contains(deviceID) {
                        if let device = self.cameraOperators?.first(where: { $0.id == deviceID }) {
                            device.setIsDeleted(true, usingSync: true, complete: nil)
                            resultDevices.append(device)
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
