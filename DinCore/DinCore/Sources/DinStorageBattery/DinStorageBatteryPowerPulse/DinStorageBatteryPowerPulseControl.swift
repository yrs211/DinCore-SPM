//
//  DinStorageBatteryPowerPulseControl.swift
//  DinCore
//
//  Created by williamhou on 2024/10/9.
//

import Foundation

final
/// 三相逆变器
class DinStorageBatteryPowerPulseControl: DinStorageBatteryControl {

    override var parser: DinStorageBatteryPayloadParser { _parser }

    private let _parser: DinStorageBatteryPayloadParser = .init(phase: .three)

    override var provider: String { DinStorageBatteryPowerPulse.provider }

}
