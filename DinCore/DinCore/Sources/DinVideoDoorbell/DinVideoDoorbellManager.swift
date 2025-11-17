//
//  DinVideoDoorbellManager.swift
//  DinCore
//
//  Created by Monsoir on 2021/11/17.
//

import Foundation
import RxSwift

public class DinVideoDoorbellManager: NSObject, DinHomeDeviceManagerProtocol {
        
    public var homeID: String

    public var userID: String
    
    public var categoryID: String {
        DinVideoDoorbell.categoryID
    }
    private var unsafeOperatorsDisposeBag: DisposeBag?

    private var unsafeOperators: [DinVideoDoorbellOperator]? = [] {
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
                    if cmd == DinLiveStreamingControl.CMD_SET_NAME {
                        self.save()
                    }
                }).disposed(by: disposeBag)
            }
            unsafeOperatorsDisposeBag = disposeBag
        }
    }
    var operators: [DinVideoDoorbellOperator]? {
        var tempOperators: [DinVideoDoorbellOperator]?
        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        DinUser.homeDevicesSyncQueue.sync {
            tempOperators = self.unsafeOperators
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
//        let `operator` = operators.first
//        `operator`?.liveStreamingControl
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
                self.unsafeOperators = self.getCache() ?? []
                DispatchQueue.main.async {
                    complete?(self.operators, nil)
                    semaphore.signal()
                }
            }
            semaphore.wait()
            return operators
        }
        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        let request = DinLiveStreamingRequest.getDevices(homeID: homeID, providers: [DinVideoDoorbell.provider])
        DinHttpProvider.request(request) { result in
            if let camerasArr = result?["list"] as? [[String: Any]] {
                // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
                DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
                    self.unsafeOperators?.removeAll()
                    var camIDs = [String]()
                    for i in 0 ..< camerasArr.count {
                        let cameraDict = camerasArr[i]
                        if let camera = DinVideoDoorbell.deserialize(from: cameraDict) {
                            self.unsafeOperators?.append(DinVideoDoorbellOperator(liveStreamingControl: DinLiveStreamingControl(withCommunicationDevice: camera, belongsToHome: self.homeID )))
                            camIDs.append(camera.id)
                        }
                    }
                    DispatchQueue.main.async {
                        self.save()
                        complete?(self.operators ?? [], nil)
                    }
                }
                //                if self?.cameraOperators.count ?? 0 > 0 {
                //                    self?.getCameraCommunicationIDs(camIDs)
                //                }
            } else {
                complete?(self.operators ?? [], nil)
            }
        } fail: {error in
            // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
            DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
                self.unsafeOperators = self.getCache() ?? []
                DispatchQueue.main.async {
                    complete?(self.operators ?? [], nil)
                }
            }
        }
        // 同步一下修改线程，阻塞等待
        let semaphore = DispatchSemaphore(value: 1)
        // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
        DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
            self.unsafeOperators = self.getCache() ?? []
            semaphore.signal()
        }
        semaphore.wait()
        return operators
    }

    public func getDevices(withDeviceString deviceString: DinGetDeviceString, andInfo info: Any?, complete: DinHomeGetDevicesBlock?) -> Bool {
        false
    }

    public func addDevice(_ device: DinHomeDeviceProtocol, complete: @escaping ()->(), inSafeQueue: Bool = false) {
        guard let newOperator = device as? DinVideoDoorbellOperator else {
            complete()
            return
        }
        if inSafeQueue {
            // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
            self.unsafeOperators?.append(newOperator)
            DispatchQueue.global().async {
                self.save()
            }
            // 保证在同一个线程
            complete()
        } else {
            // 这里不用 [weak self] 是需要在deinit前，把self retain count +1 ，以防在下面线程执行时，main线程dealloc
            DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
                self.unsafeOperators?.append(newOperator)
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
                if `operator`?.id == deviceID || `operator`?.info["cameraPID"] as? String == deviceID {
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
        cache(doorbells: operators)
    }

    public func getNewDevices(complete: GetNewDeviceCompletion?) {
        complete?(false, categoryID, [], [])
    }

    public func shouldHandleNotification(_ notification: [String : Any]) -> Bool {
        (["new-door-bell", "del-door-bell", "rename-door-bell"].contains(notification["cmd"] as? String ?? "")) &&
        notification["provider"] as? String == DinVideoDoorbell.categoryID &&
        (notification["pid"] as? String)?.isEmpty == false
    }

    public func handleGroupNotification(_ notification: [String : Any], completion: ((Bool, [DinHomeDeviceProtocol]?, DinHomeNotificationIntent) -> Void)?) {
        guard let cmd = notification["cmd"] as? String, !cmd.isEmpty else {
            completion?(false, nil, .ignore)
            return
        }

        switch cmd {
        case "new-door-bell":
            getNewDevices { [weak self] success, categoryID, allDevices, brandNewDevices  in
                guard let self = self, let camID = notification["pid"] as? String else { return }
                guard let allDevices = allDevices, let _ = allDevices.first(where: { $0.id == camID }) else {
                    completion?(false, nil, .ignore)
                    return
                }

                // 如果缓存有该设备，就提示refresh，否则就是新添加
                completion?(true, self.operators, (brandNewDevices?.isEmpty ?? true) ? .refreshDevices(allDevices) : .addDevices(brandNewDevices ?? []))
            }
        case "rename-door-bell":
            renameDevice(
                identifiable: notification["pid"] as? String ?? "",
                newName: notification["name"] as? String ?? "---") {
                    guard let camID = notification["pid"] as? String else {
                        completion?(false, nil, .ignore)
                        return
                    }
                    completion?(true, self.operators, .renameDevice(deviceID: camID))
                }
        case "del-door-bell":
            removeDeviceLocally(identifiable: notification["pid"] as? String ?? "") { [weak self] in
                guard let self = self, let camID = notification["pid"] as? String else {
                    completion?(false, nil, .ignore)
                    return
                }
                completion?(true, self.operators, .removeDevices(deviceIds: [camID]))
            }
        default:
            completion?(false, nil, .ignore)
        }
    }

    private func getDevice(identifiable: String, completion: ((Bool, DinVideoDoorbellOperator?) -> Void)?) {
        let request = DinLiveStreamingRequest.getDevices(homeID: homeID, providers: [DinVideoDoorbell.provider])
        DinHttpProvider.request(request) { [weak self] result in
            guard let self = self else { return }
            guard
                let list = result?["list"] as? [[String: Any]],
                let newDevice = list
                    .compactMap({ DinVideoDoorbell.deserialize(from: $0) })
                    .first(where: { $0.id == identifiable })
            else {
                completion?(false, nil)
                return
            }

            let result = DinVideoDoorbellOperator(
                liveStreamingControl: DinLiveStreamingControl(
                    withCommunicationDevice: newDevice,
                    belongsToHome: self.homeID
                )
            )
            completion?(true, result)
        } fail: { error in
            completion?(false, nil)
        }
    }

    private func renameDevice(identifiable: String, newName: String, complete: (()->())?) {
        guard let `operator` = operators?.first(where: { $0.id == identifiable }) else { return }
        `operator`.liveStreamingControl.rename(newName) {
            complete?()
        }
    }

    private func removeDeviceLocally(identifiable: String, complete: @escaping ()->()) {
        guard let index = operators?.firstIndex(
            where: { $0.id == identifiable || $0.info["cameraPID"] as? String == identifiable }
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
    
    public func setDeviceAsDeleted(_ deviceID: String, complete: ((Bool, [DinHomeDeviceProtocol]?, DinHomeDeviceProtocol?) -> Void)?) {
        complete?(false, nil, nil)
    }

    private func getCache() -> [DinVideoDoorbellOperator]? {
        guard let cacheCamerasStrings = DinCore.dataBase.hasValue(withKey: saveKey()) as? [String] else {
            return nil
        }
        var operators = [DinVideoDoorbellOperator]()
        for cacheCamerasString in cacheCamerasStrings {
            if let cameraOperator = DinVideoDoorbellOperator(deviceInfo: cacheCamerasString, homeID: homeID) {
                operators.append(cameraOperator)
            }
        }
        guard operators.count > 0 else {
            return nil
        }
        return operators
    }

    private func removeCache() {
        DinCore.dataBase.removeValueAsync(withKey: saveKey())
    }

    private func saveKey() -> String {
        "DinHome_\(homeID)_\(userID)_\(DinVideoDoorbell.categoryID)"
    }

    private func cache(doorbells doorbellsOrNil: [DinVideoDoorbellOperator]?) {
        guard let doorbells = doorbellsOrNil else {
            removeCache()
            return
        }

        var saveStrings = [String]()
        for doorbell in doorbells {
            let saveString = doorbell.saveJsonString
            if saveString.count > 0 {
                saveStrings.append(saveString)
            }
        }
        guard saveStrings.count > 0 else {
            removeCache()
            return
        }
        DinCore.dataBase.saveValueAsync(withKey: saveKey(), value: saveStrings)
    }
    
    public func searchDeviceFromServer(withIDs deviceIDs: [String], info: Any?, complete: ((Bool, [any DinHomeDeviceProtocol]?) -> Void)?) {
        complete?(false, [])
    }
    
    public func acquireTemporaryDevices(withIDs deviceIDs: [String], info: Any?, complete: ((Bool, [any DinHomeDeviceProtocol]?) -> Void)?) {
        complete?(false, [])
    }
    
    public func getDevices(withDeviceString deviceString: DinGetDeviceString, panelId: String, andInfo info: Any?, onlyLoadCache: Bool, complete:  ((Bool, [DinHomeDeviceProtocol]?) -> Void)?) -> Bool { false }
    
    public func getNewDevices(withDeviceString deviceString: DinGetDeviceString, panelId: String, complete: GetNewDeviceCompletion?) -> Bool { false }
    
    public func shouldAdd(deviceInfo: Any, extraInfo info: Any?) -> Bool { false }
    
    public func add(deviceInfo: Any, extraInfo info: Any?, complete: ((_ success: Bool, _ shouldNotifyGlobal: Bool, _ info: [DinHomeDeviceProtocol]?, _ deviceAdded: DinHomeDeviceProtocol?) -> Void)?) { complete?(false, false, nil, nil) }
    
    public func supportRemove(deviceInfo: Any, extraInfo info: Any?) -> Bool { false }
    
    public func remove(deviceInfo: Any, extraInfo info: Any?, complete: ((_ success: Bool, _ shouldNotifyGlobal: Bool, _ info: [DinHomeDeviceProtocol]?, _ deviceRemoved: String?) -> Void)?)  { complete?(false, false, nil, nil) }
}
