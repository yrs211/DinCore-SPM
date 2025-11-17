//
//  DinHomeDeviceManagerProtocol.swift
//  DinCore
//
//  Created by Jin on 2021/5/12.
//

import UIKit

public enum DinHomeNotificationIntent {
    case addDevices(_ devices: [DinHomeDeviceProtocol])
    case renameDevice(deviceID: String)
    case removeDevices(deviceIds: [String])
    case versionUpdated(deviceID: String)
    case refreshDevices(_ devices: [DinHomeDeviceProtocol])
    case regionUpdated(deviceID: String)
    case other
    case ignore         // 一些错误情况，不需要处理
}

public protocol DinHomeDeviceManagerProtocol: AnyObject {
    /// 获取最新设备完成的回调
    /// 注：因为Home或者设备manager里面有缓存（已删除的设备），获取回来的设备会经过合并对比，如果缓存有，就更新对应设备
    /// 所以参数是：
    /// 是否成功/设备的categoryID/服务器根据时间返回的设备数组/本地缓存不存在的设备数组（也就是前者的子集，经过筛选）
    typealias GetNewDeviceCompletion = (Bool, String, [DinHomeDeviceProtocol]?, [DinHomeDeviceProtocol]?) -> Void

    /// 所属的房间id
    var homeID: String { get }
    /// 所属的设备类型
    var categoryID: String { get }
    /// 获取当前沙盒里面的Devices缓存
    /// 注意！！！这里不会覆盖当前内存上的缓存
    func getHardDiskCachedDevices(complete: DinHomeGetDevicesBlock?)
    /// 获取缓存的设备，首先会马上返回缓存的数据
    /// - Parameters:
    ///   - complete: 通过服务器拿回来的数据，如果请求失败，返回nil
    ///   - onlyLoadCache: 只加载缓存，目前只用于界面预加载，不做数据同步
    func getDevices(onlyLoadCache: Bool, complete: DinHomeGetDevicesDiffBlock?) -> [DinHomeDeviceProtocol]?
    /// 获取特定的设备列表，如果符合返回 true
    func getDevices(withDeviceString deviceString: DinGetDeviceString, andInfo info: Any?, complete: DinHomeGetDevicesBlock?) -> Bool
    /// 获取指定ID的设备(2.0加入的方法)
    func searchDeviceFromServer(withIDs deviceIDs:[String], info: Any?, complete: ((Bool, [DinHomeDeviceProtocol]?) -> Void)?)
    /// 获取指定ID的设备，获取的设备不更新DinHome设备列表
    func acquireTemporaryDevices(withIDs deviceIDs:[String], info: Any?, complete: ((Bool, [DinHomeDeviceProtocol]?) -> Void)?)
    /// 获取指定的配件列表，如果符合返回 true(2.0加入的方法)
    func getDevices(withDeviceString deviceString: DinGetDeviceString, panelId: String, andInfo info: Any?, onlyLoadCache: Bool, complete:  ((Bool, [DinHomeDeviceProtocol]?) -> Void)?) -> Bool
    /// 获取新设备(2.0加入的方法)
    func getNewDevices(complete: GetNewDeviceCompletion?)
    /// 获取特定的新设备，如果符合返回 true(2.0加入的方法)
    func getNewDevices(withDeviceString deviceString: DinGetDeviceString, panelId: String, complete: GetNewDeviceCompletion?) -> Bool
    /// 是否确定添加特定的设备
    func shouldAdd(deviceInfo: Any, extraInfo info: Any?) -> Bool
    ///  添加特定的设备
    func add(deviceInfo: Any, extraInfo info: Any?, complete: ((_ success: Bool, _ shouldNotifyGlobal: Bool, _ info: [DinHomeDeviceProtocol]?, _ deviceAdded: DinHomeDeviceProtocol?) -> Void)?)

    func shouldHandleNotification(_ notification: [String: Any]) -> Bool
    func handleGroupNotification(_ notification: [String: Any], completion: ((Bool, [DinHomeDeviceProtocol]?, DinHomeNotificationIntent) -> Void)?)

    /// 添加设备
    func addDevice(_ device: DinHomeDeviceProtocol, complete: @escaping ()->(), inSafeQueue: Bool)
    /// 删除设备
    func removeDevice(_ deviceID: String, complete: DinHomeRemoveDeviceBlock?)
    /// 将设备标记为已删除
    func setDeviceAsDeleted(_ deviceID: String, complete: ((Bool, [DinHomeDeviceProtocol]?, DinHomeDeviceProtocol?) -> Void)?)

    /// 是否支持删除特定的设备缓存
    func supportRemove(deviceInfo: Any, extraInfo info: Any?) -> Bool
    ///  删除特定的设备缓存
    func remove(deviceInfo: Any, extraInfo info: Any?, complete: ((_ success: Bool, _ shouldNotifyGlobal: Bool, _ info: [DinHomeDeviceProtocol]?, _ deviceRemoved: String?) -> Void)?)

    /// 保存数据
    func save()
}

public protocol DinDeviceListSyncProtocol where Self: DinHomeDeviceManagerProtocol {
    typealias SyncResponse = (devices: [DinHomeDeviceProtocol], addedDevices: [DinHomeDeviceProtocol], removedDeviceIDs: [String])
    func syncDevices(complete: ((_ result: Result<SyncResponse, Error>) -> Void)?)
}

    
