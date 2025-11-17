//
//  DinStorageBatteryHP5000Control.swift
//  DinCore
//
//  Created by Monsoir on 2022/12/6.
//

import Foundation

final
/// 三相逆变器
class DinStorageBatteryHP5000Control: DinStorageBatteryControl {

    override var parser: DinStorageBatteryPayloadParser { _parser }

    private let _parser: DinStorageBatteryPayloadParser = .init(phase: .three)

    override var provider: String { DinStorageBatteryHP5000.provider }

}
