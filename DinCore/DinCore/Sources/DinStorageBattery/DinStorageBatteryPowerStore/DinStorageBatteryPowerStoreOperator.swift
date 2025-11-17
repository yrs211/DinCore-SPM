//
//  DinStorageBatteryPowerStoreOperator.swift
//  DinCore
//
//  Created by williamhou on 2024/7/24.
//

import Foundation

final
class DinStorageBatteryPowerStoreOperator: DinStorageBatteryOperator {

    override var manageTypeID: String { DinStorageBatteryPowerStore.categoryID }

    override var category: String { DinStorageBatteryPowerStore.categoryID }

    override var subCategory: String { DinStorageBatteryPowerStore.categoryID }

    override class func createControl(from model: DinStorageBattery, homeID: String) -> DinStorageBatteryControl {
        return DinStorageBatteryPowerStoreControl(model: model, homeID: homeID)
    }
}
