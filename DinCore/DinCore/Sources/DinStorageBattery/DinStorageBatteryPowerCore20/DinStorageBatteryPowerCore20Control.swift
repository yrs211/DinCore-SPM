//
//  DinStorageBatteryPowerCore20Control.swift
//  DinCore
//
//  Created by williamhou on 2024/7/1.
//

import Foundation

final
/// 三相逆变器
class DinStorageBatteryPowerCore20Control: DinStorageBatteryControl {

    override var parser: DinStorageBatteryPayloadParser { _parser }

    private let _parser: DinStorageBatteryPayloadParser = .init(phase: .three)

    override var provider: String { DinStorageBatteryPowerCore20.provider }

}
