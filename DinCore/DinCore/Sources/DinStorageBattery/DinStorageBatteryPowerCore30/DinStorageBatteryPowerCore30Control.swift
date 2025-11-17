//
//  DinStorageBatteryPowerCore30Control.swift
//  Pods
//
//  Created by Shaoling on 2024/12/6.
//

import Foundation

final
/// 三相逆变器
class DinStorageBatteryPowerCore30Control: DinStorageBatteryControl {

    override var parser: DinStorageBatteryPayloadParser { _parser }

    private let _parser: DinStorageBatteryPayloadParser = .init(phase: .three)

    override var provider: String { DinStorageBatteryPowerCore30.provider }

}

