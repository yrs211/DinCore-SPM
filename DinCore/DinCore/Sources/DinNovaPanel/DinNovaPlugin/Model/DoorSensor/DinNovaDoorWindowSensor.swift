//
//  DinNovaDoorWindowSensor.swift
//  DinCore
//
//  Created by Jin on 2021/5/27.
//

import UIKit
import DinSupport
import HandyJSON

class DinNovaDoorWindowSensor: DinNovaPlugin {
    override var canDetectOnline: Bool {
        return DinAccessory.askDoorWindowsStypes.contains(subCategory)
    }

    // apart
    var isApart: Bool = false
    var canDetectApart: Bool {
        return DinAccessory.showApartStatusPlugins.contains(subCategory)
    }

    // 配件屏蔽设置，-1: 不支持，0：不屏蔽；1、屏蔽tamper alarm；2：屏蔽整个配件；3：chime
    var block: Int = -1
    // 发送的码
    var sendid = ""
    // 时间
    var time: TimeInterval = 0

    /// 是否推送
    var pushStatus: Bool { askData?["push_status"] as? Bool ?? false }

    override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)

        mapper <<< isApart <-- "enable"
        mapper <<< block <-- "block"
    }
    
    override func didFinishMapping() {
        super.didFinishMapping()
        // 支持门磁block模式的，强制把-1转换为0
        if DinAccessory.supportSettingDoorWindowPushStatusTypes.contains(subCategory), block == -1 {
            block = 0
        }
    }
}
