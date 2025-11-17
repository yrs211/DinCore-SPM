//
//  DinStorageBatteryPowerPulse.swift
//  DinCore
//
//  Created by williamhou on 2024/10/9.
//

import Foundation

final
/// 三相逆变器
class DinStorageBatteryPowerPulse: DinStorageBattery {

    override class var categoryID: String { "VB1-BAK5-HS10" }

    override class var provider: String { "VB1-BAK5-HS10" }
}
