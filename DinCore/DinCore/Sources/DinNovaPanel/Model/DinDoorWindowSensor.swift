//
//  DinDoorWindowSensor.swift
//  DinCore
//
//  Created by Jin on 2021/5/7.
//

import UIKit
import HandyJSON
import DinSupport

public class DinDoorWindowSensor: DinModel, DinHomeDeviceSelection, NSCopying {
    /// sensor name
    public var name = ""

    /// sensor id
    public var id = ""

    // int，配件屏蔽设置，0：不屏蔽；1、屏蔽tamper alarm；2：屏蔽整个配件；3：chime
    public var block: Int = -1
    public var sendid = ""
    public var stype = ""
    public var time: TimeInterval = 0

    // default selected to show
    public var isSelected: Bool = true
    public var isEditing: Bool = false

    public var decodeID: String = ""
    public var category: Int?

    // is loading state
    public var isLoading: Bool = false

    public var isOnline: Bool = true
    public var canDetectOnline: Bool {
        return DinAccessory.askDoorWindowsStypes.contains(stype)
    }

    // apart
    public var isApart: Bool = false
    public var canDetectApart: Bool {
        return DinAccessory.showApartStatusPlugins.contains(stype)
    }

    public var tapable: Bool = true

    public func copy(with zone: NSZone? = nil) -> Any {
        let sensor = DinDoorWindowSensor()
        sensor.name = self.name
        sensor.id = self.id
        sensor.decodeID = self.decodeID
        sensor.isOnline = self.isOnline
        sensor.block = self.block
        sensor.category = self.category
        sensor.sendid = self.sendid
        sensor.stype = self.stype
        sensor.time = self.time
        sensor.isApart = self.isApart
        sensor.isSelected = self.isSelected
        sensor.isEditing = self.isEditing
        sensor.isLoading = self.isLoading
        sensor.tapable = self.tapable
        return sensor
    }

    public override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)
        mapper <<<
            self.decodeID <-- "decodeid"
        mapper <<<
            self.isOnline <-- "keeplive"
    }
}
