//
//  DinStorageBatteryPowerCore30Operator.swift
//  Pods
//
//  Created by Shaoling on 2024/12/6.
//

import Foundation

final
class DinStorageBatteryPowerCore30Operator: DinStorageBatteryOperator {

    override var manageTypeID: String { DinStorageBatteryPowerCore30.categoryID }

    override var category: String { DinStorageBatteryPowerCore30.categoryID }

    override var subCategory: String { DinStorageBatteryPowerCore30.categoryID }

    override class func createControl(from model: DinStorageBattery, homeID: String) -> DinStorageBatteryControl {
        return DinStorageBatteryPowerCore30Control(model: model, homeID: homeID)
    }
}

