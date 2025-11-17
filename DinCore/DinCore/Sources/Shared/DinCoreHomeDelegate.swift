//
//  DinCoreHomeDelegate.swift
//  DinCore
//
//  Created by Monsoir on 2021/10/20.
//

import Foundation

public protocol DinCoreHomeDelegate {

    func dinCoreHomeWillChange(to homeID: String)

    func dinCoreHomeDidUpdate()

    /// 收到家庭信息通知
    func dinCoreHomeDidReceiveNotification(_ notification: [String: Any])

    /// 家庭设备列表更新
    /// - Parameters:
    ///   - categoryID: categoryID
    ///   - reason: 列表更新的原因
    func dinCoreHomeDevicesDidUpdate(categoryID: String, reason: DevicesUpdateReason)
    
}

public enum DevicesUpdateReason {
    /// 设备改名
    case renameDevices(deviceId: String)
    /// 设备删除
    case removeDevices(deviceIds: [String])
    /// 设备添加（家庭中的其他用户添加了设备，当前用户获取新增加的设备时，有可能会得到多个设备）
    case addDevices(devices: [DinHomeDeviceProtocol])
    /// 刷新实例的设备
    case refreshed(devices: [DinHomeDeviceProtocol])
    /// 设备列表同步，和refresh事件类似，但包含了更多信息
    case sync(addedDevices: [DinHomeDeviceProtocol], removedDeviceIds: [String])
    /// 设备地区更新
    case regionUpdated(deviceId: String)
}

