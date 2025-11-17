//
//  DinStorageBatteryPowerCore30Manager.swift
//  Pods
//
//  Created by Shaoling on 2024/12/6.
//

import Foundation

final
public class DinStorageBatteryPowerCore30Manager: DinStorageBatteryManager {

    public override var categoryID: String { DinStorageBatteryPowerCore30.categoryID }

    override var model: String { DinStorageBatteryPowerCore30.provider }

    override var cacheKey: String { "DinHom_\(homeID)_\(userID)_\(DinStorageBatteryPowerCore30.categoryID)" }
    
    override var saveTimeKey: String { "DinHom_\(homeID)_\(userID)_\(DinStorageBatteryPowerCore30.categoryID)_SaveTime" }

    public override init(homeID: String, userID: String) {
        super.init(homeID: homeID, userID: userID)
    }

    override func createModel(from rawData: [String : Any]) -> DinStorageBattery? {
        DinStorageBatteryPowerCore30.deserialize(from: rawData)
    }

    override func createControl(from model: DinStorageBattery, homeID: String) -> DinStorageBatteryControl {
        guard model is DinStorageBatteryPowerCore30 else { fatalError("Incorrect type of model") }
        let result = DinStorageBatteryPowerCore30Control(model: model, homeID: homeID)
        return result
    }

    override func createOperator(from control: DinStorageBatteryControl) -> DinStorageBatteryOperator {
        guard control is DinStorageBatteryPowerCore30Control else { fatalError("Incorrect type of control") }
        let result = DinStorageBatteryPowerCore30Operator(control: control)
        return result
    }

    public override func addDevice(_ device: DinHomeDeviceProtocol, complete: @escaping ()->(), inSafeQueue: Bool = false) {
        guard let `operator` = device as? DinStorageBatteryPowerCore30Operator else { return }
        super.addDevice(`operator`, complete: complete, inSafeQueue: inSafeQueue)
    }

    override func createOperator(from rawString: String, homeID: String) -> DinStorageBatteryOperator? {
        DinStorageBatteryPowerCore30Operator(homeID: homeID, rawString: rawString)
    }

    public override func shouldHandleNotification(_ notification: [String : Any]) -> Bool {
        (["new-bmt", "del-bmt", "rename-bmt", "bmt-ver-num-updated"].contains(notification["cmd"] as? String ?? "")) &&
        notification["model"] as? String == DinStorageBatteryPowerCore30.provider &&
        (notification["id"] as? String)?.isEmpty == false
    }

    public override func handleGroupNotification(_ notification: [String : Any], completion: ((Bool, [DinHomeDeviceProtocol]?, DinHomeNotificationIntent) -> Void)?) {
        guard let cmd = notification["cmd"] as? String, !cmd.isEmpty else {
            completion?(false, nil, .ignore)
            return
        }

        switch cmd {
        case "new-bmt":
            getNewDevices { [weak self] success, catID, allDevices, brandNewDevices in
                guard let self = self, let bmtID = notification["id"] as? String else { return }
                guard let allDevices = allDevices, let _ = allDevices.first(where: { $0.id == bmtID}) else {
                    completion?(false, nil, .ignore)
                    return
                }
                // 如果缓存有该设备，就提示refresh，否则就是新添加
                completion?(true, self.operators, (brandNewDevices?.isEmpty ?? true) ? .refreshDevices(allDevices) : .addDevices(brandNewDevices ?? []))
            }
        case "rename-bmt":
            renameDevice(
                identifiable: notification["id"] as? String ?? "",
                newName: notification["name"] as? String ?? "---") {
                    completion?(true, self.operators, .renameDevice(deviceID: notification["id"] as? String ?? ""))
                }
        case "del-bmt":
            removeDeviceLocally(identifiable: notification["id"] as? String ?? "") { [weak self] in
                guard let self = self else {
                    completion?(false, nil, .ignore)
                    return
                }
                completion?(true, self.operators, .removeDevices(deviceIds: [notification["id"] as? String ?? ""]))
            }
        case "bmt-ver-num-updated":
//            if let device = cameraOperators.first(where: { $0.id == notification["id"] as? String }),
//               let versions = notification["versions"] as? [[String: String]] {
//                device.liveStreamingControl.update(versions: versions)
//                completion?(true, self.cameraOperators)
//                return
//            }
//            completion?(false, self.operators)
            completion?(false, nil, .ignore)
        default:
            completion?(false, nil, .ignore)
        }
    }
}

