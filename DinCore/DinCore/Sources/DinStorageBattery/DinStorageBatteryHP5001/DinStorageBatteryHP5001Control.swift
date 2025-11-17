//
//  DinStorageBatteryHP5001Control.swift
//  DinCore
//
//  Created by Monsoir on 2022/12/6.
//

import Foundation

final
/// 单相逆变器
class DinStorageBatteryHP5001Control: DinStorageBatteryControl {

    override var parser: DinStorageBatteryPayloadParser { _parser }

    private let _parser: DinStorageBatteryPayloadParser = .init(phase: .single)

    override var provider: String { DinStorageBatteryHP5001.provider }

}
