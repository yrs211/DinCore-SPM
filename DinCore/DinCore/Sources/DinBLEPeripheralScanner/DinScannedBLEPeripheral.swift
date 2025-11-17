//
//  DinScannedBLEPeripheral.swift
//  DinCore
//
//  Created by monsoir on 6/1/21.
//

import Foundation
import CoreBluetooth

/// 扫描到的蓝牙设备对象
public class DinScannedBLEPeripheral: NSCopying {
    
    public typealias AdvertisementData = [String: Any]
    public typealias ID = String

    public let id: ID
    public private(set) var peripheral: CBPeripheral
    public private(set) var advertisementData: AdvertisementData
    public private(set) var rssi: NSNumber

    /// 最近更新时间
    private(set) var updatedAt: Date

    init(
        id: ID,
        peripheral: CBPeripheral,
        advertisementData: AdvertisementData,
        rssi: NSNumber
    ) {
        self.id = id
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.rssi = rssi
        self.updatedAt = Date()
    }

    func update(peripheral: CBPeripheral, advertisementData: AdvertisementData, rssi: NSNumber) {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.rssi = rssi
        self.updatedAt = Date()
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = DinScannedBLEPeripheral(
            id: self.id,
            peripheral: self.peripheral,
            advertisementData: self.advertisementData,
            rssi: self.rssi
        )
        copy.updatedAt == self.updatedAt
        return copy
    }
}
