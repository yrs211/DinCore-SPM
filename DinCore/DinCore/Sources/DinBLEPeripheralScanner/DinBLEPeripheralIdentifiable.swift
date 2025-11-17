//
//  DinBLEPeripheralIdentifiable.swift
//  DinCore
//
//  Created by monsoir on 6/4/21.
//

import Foundation
import CoreBluetooth

public protocol DinBLEPeripheralIdentifiable {
    func createID(for peripheral: CBPeripheral, advertisementData: [String: Any]) -> String
}

/// 主机 ID 命名规则
public class DinDevicePeripheralIDGenerator: DinBLEPeripheralIdentifiable {

    public init() {}

    public func createID(for peripheral: CBPeripheral, advertisementData: [String : Any]) -> String {
        let result = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? ""
        return result
    }
}
