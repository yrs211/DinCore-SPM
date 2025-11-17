//
//  DinStorageBatteryPowerPulseOperator.swift
//  DinCore
//
//  Created by williamhou on 2024/10/9.
//

import Foundation

final
class DinStorageBatteryPowerPulseOperator: DinStorageBatteryOperator {

    override var manageTypeID: String { DinStorageBatteryPowerPulse.categoryID }

    override var category: String { DinStorageBatteryPowerPulse.categoryID }

    override var subCategory: String { DinStorageBatteryPowerPulse.categoryID }

    override class func createControl(from model: DinStorageBattery, homeID: String) -> DinStorageBatteryControl {
        return DinStorageBatteryPowerPulseControl(model: model, homeID: homeID)
    }
}
