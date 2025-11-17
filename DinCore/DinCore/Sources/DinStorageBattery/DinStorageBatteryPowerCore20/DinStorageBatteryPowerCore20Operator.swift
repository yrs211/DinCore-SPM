//
//  DinStorageBatteryPowerCore20Operator.swift
//  DinCore
//
//  Created by williamhou on 2024/7/1.
//

import Foundation

final
class DinStorageBatteryPowerCore20Operator: DinStorageBatteryOperator {

    override var manageTypeID: String { DinStorageBatteryPowerCore20.categoryID }

    override var category: String { DinStorageBatteryPowerCore20.categoryID }

    override var subCategory: String { DinStorageBatteryPowerCore20.categoryID }

    override class func createControl(from model: DinStorageBattery, homeID: String) -> DinStorageBatteryControl {
        return DinStorageBatteryPowerCore20Control(model: model, homeID: homeID)
    }
}
