//
//  DinStorageBatteryHP5001Operator.swift
//  DinCore
//
//  Created by Monsoir on 2022/12/6.
//

import Foundation

final
class DinStorageBatteryHP5001Operator: DinStorageBatteryOperator {

    override var manageTypeID: String { DinStorageBatteryHP5001.categoryID }

    override var category: String { DinStorageBatteryHP5001.categoryID }

    override var subCategory: String { DinStorageBatteryHP5001.categoryID }

    override class func createControl(from model: DinStorageBattery, homeID: String) -> DinStorageBatteryControl {
        return DinStorageBatteryHP5001Control(model: model, homeID: homeID)
    }
}
