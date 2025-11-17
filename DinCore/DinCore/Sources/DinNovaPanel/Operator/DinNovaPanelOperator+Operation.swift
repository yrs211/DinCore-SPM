//
//  DinNovaPanelOperator+Operation.swift
//  DinCore
//
//  Created by Jin on 2021/5/13.
//

import Foundation

extension DinNovaPanelOperator {
    func wsConnection(_ data: [String: Any]) {
        guard let connValue = data["connection"] as? Int else {
            return
        }
        if connValue == 1 {
            panelControl.connect()
        } else {
            panelControl.disconnect()
        }
    }

    func armOperation(_ data: [String: Any]) {
        guard let armValue = data["armStatus"] as? Int else {
            return
        }
        switch armValue {
        case DinNovaPanelArmStatus.arm.rawValue:
            panelControl.arm(force: data["forceAciton"] as? Bool ?? false)
        case DinNovaPanelArmStatus.disarm.rawValue:
            panelControl.disarm(check: data["recordDisarm"] as? Bool ?? false)
        case DinNovaPanelArmStatus.homeArm.rawValue:
            panelControl.homearm(force: data["forceAciton"] as? Bool ?? false)
        default:
            break
        }
    }
}
