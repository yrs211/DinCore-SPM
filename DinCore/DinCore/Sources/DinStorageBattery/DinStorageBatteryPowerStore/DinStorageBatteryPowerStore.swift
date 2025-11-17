//
//  DinStorageBatteryPowerStore.swift
//  DinCore
//
//  Created by williamhou on 2024/7/24.
//

import Foundation

final
/// 三相逆变器
class DinStorageBatteryPowerStore: DinStorageBattery {

    override class var categoryID: String { "PS1-BAK10-HS10" }

    override class var provider: String { "PS1-BAK10-HS10" }
}
