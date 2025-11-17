//
//  DinStorageBatteryHP5000Operator.swift
//  DinCore
//
//  Created by Monsoir on 2022/12/6.
//

import Foundation

final
class DinStorageBatteryHP5000Operator: DinStorageBatteryOperator {

    override var manageTypeID: String { DinStorageBatteryHP5000.categoryID }

    override var category: String { DinStorageBatteryHP5000.categoryID }

    override var subCategory: String { DinStorageBatteryHP5000.categoryID }

    override class func createControl(from model: DinStorageBattery, homeID: String) -> DinStorageBatteryControl {
        return DinStorageBatteryHP5000Control(model: model, homeID: homeID)
    }
}
