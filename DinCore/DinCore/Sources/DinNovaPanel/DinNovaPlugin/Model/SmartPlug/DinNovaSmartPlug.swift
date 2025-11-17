//
//  DinNovaSmartPlug.swift
//  DinCore
//
//  Created by Jin on 2021/6/2.
//

import UIKit
import DinSupport
import HandyJSON

class DinNovaSmartPlug: DinNovaPlugin {
    override var canDetectOnline: Bool {
        return DinAccessory.askSmartPlugStypes.contains(subCategory)
    }

    var isEnable: Bool = false
    // 发送的码
    var sendid = ""
    // 时间
    var time: TimeInterval = 0

    override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)

        mapper <<< isEnable <-- ["enable", "plugin_item_smart_plug_enable"]
        mapper <<< category <-- "category"
    }
}
