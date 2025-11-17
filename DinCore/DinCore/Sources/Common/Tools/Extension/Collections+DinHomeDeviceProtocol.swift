//
//  Collections+DinHomeDeviceProtocol.swift
//  DinCore
//
//  Created by williamhou on 2022/11/26.
//

import Foundation

public extension Array where Element: DinHomeDeviceProtocol {

    /// 合并服务器返回的数据
    /// - Parameter devices: 服务器返回的设备
    /// - Returns: 合并后的设备列表/原来没有的设备(全新的)
    func merge(devices: [Self.Element]) -> ([Self.Element], [Self.Element]) {
        var result: [Self.Element] = []
        var ids = Set<String>()
        //用新的设备对象替换旧的设备对象
        self.forEach { originalDevice in
            if !ids.contains(originalDevice.id) {
                if let newDevice = devices.first(where: {$0.id == originalDevice.id}) {
                    result.append(newDevice)
                } else {
                    result.append(originalDevice)
                }
                ids.insert(originalDevice.id)
            }
        }
        //将未添加的设备添加进去
        var brandNewDevices: [Self.Element] = []
        devices.forEach { newDevice in
            if !ids.contains(newDevice.id) {
                ids.insert(newDevice.id)
                result.append(newDevice)
                brandNewDevices.append(newDevice)
            }
        }
        return (result, brandNewDevices)
    }
}

public extension Array where Element: DinHomeDeviceProtocol & Deletable {

    /// 合并服务器返回的数据
    /// - Parameters:
    ///   - deviceIDs: 需要检查是否已删除的设备ID数组（如果 devices 中不存在该设备，则视为已删除）
    ///   - devices: 服务器返回的设备
    /// - Returns: 合并后的设备列表/原来没有的设备(全新的)
    func merge(deviceIDs:[String], devices:[Self.Element], inSafeQueue: Bool, complete: @escaping (([Self.Element], [Self.Element]))->()) {
        if inSafeQueue {
            complete(merge(inSafeQueue: deviceIDs, devices: devices))
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) {
                let result = merge(inSafeQueue: deviceIDs, devices: devices)
                DispatchQueue.global().async {
                    complete(result)
                }
            }
        }
    }

    private func merge(inSafeQueue deviceIDs:[String], devices:[Self.Element]) -> ([Self.Element], [Self.Element]) {
        //先合并数组
        let (resultDevices, brandNewDevices) = self.merge(devices: devices)
        //确定被删除的设备有哪些
        let deletedDeviceIDs = deviceIDs.filter { deviceID in
            !devices.contains(where: { $0.id == deviceID })
        }
        //将对应的设备标记为已删除
        resultDevices.forEach { device in
            if deletedDeviceIDs.contains(device.id) {
                device.setIsDeleted(true, usingSync: true, complete: nil)
            }
        }
        return (resultDevices, brandNewDevices)
    }
}

public extension Array where Element: DinHomeDeviceProtocol{
    //最近的设备添加时间(主要用于下次请求服务器时拿到新添加的设备:这个时间点之后的设备都是新设备)
    var lastAddTime: Int64{
        self.map{ $0.info["addtime"] as? Int64 ?? 1 }.max() ?? 1
    }
}


//MARK: Deletable
///某个设备如果被删除了，它对应的缓存不再是直接删除了,而是标识为已被删除.
///当设备卡片获取到标识为被删除的设备缓存时，显示UnAvailable(不可用)状态
public protocol Deletable{
    var isDeleted: Bool { get }
    func setIsDeleted(_ isDeleted:Bool, usingSync sync: Bool, complete: (()->())?)
}

extension Deletable where Self:DinHomeDeviceProtocol{
    var isDeleted: Bool{
        info["isDeleted"] as? Bool ?? false
    }
}

#if ENABLE_DINCORE_LIVESTREAMING

extension DinCameraOperator: Deletable {
    func setIsDeleted(_ isDeleted: Bool, usingSync sync: Bool, complete: (() -> ())?) {
        liveStreamingControl.setIsDeleted(isDeleted, usingSync: sync, complete: complete)
    }
}

extension DinCameraV006Operator: Deletable {
    func setIsDeleted(_ isDeleted: Bool, usingSync sync: Bool, complete: (() -> ())?) {
        liveStreamingControl.setIsDeleted(isDeleted, usingSync: sync, complete: complete)
    }
}

extension DinCameraV015Operator: Deletable {
    func setIsDeleted(_ isDeleted: Bool, usingSync sync: Bool, complete: (() -> ())?) {
        liveStreamingControl.setIsDeleted(isDeleted, usingSync: sync, complete: complete)
    }
}

#endif

#if ENABLE_DINCORE_PANEL

extension DinNovaPanelOperator: Deletable {
    func setIsDeleted(_ isDeleted: Bool, usingSync sync: Bool, complete: (() -> ())?) {
        panelControl.updateIsDeleted(isDeleted, usingSync: sync, complete: complete)
    }
}

extension DinNovaPluginOperator: Deletable {
    func setIsDeleted(_ isDeleted: Bool, usingSync sync: Bool, complete: (() -> ())?) {
        pluginControl.setIsDeleted(isDeleted, usingSync: sync, complete: complete)
    }
}

#endif

#if ENABLE_DINCORE_STORAGE_BATTERY

extension DinStorageBatteryOperator: Deletable {
    func setIsDeleted(_ isDeleted: Bool, usingSync sync: Bool, complete: (() -> ())?) {
        control.setIsDeleted(isDeleted, usingSync: sync, complete: complete)
    }
}

#endif
