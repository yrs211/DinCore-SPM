//
//  DinStorageBatteryPowerStoreControl.swift
//  DinCore
//
//  Created by williamhou on 2024/7/24.
//

import Foundation

final
/// 三相逆变器
class DinStorageBatteryPowerStoreControl: DinStorageBatteryControl {

    override var parser: DinStorageBatteryPayloadParser { _parser }

    private let _parser: DinStorageBatteryPayloadParser = .init(phase: .three)

    override var provider: String { DinStorageBatteryPowerStore.provider }

}
