//
//  DinNovaSiren.swift
//  DinCore
//
//  Created by Jin on 2021/6/6.
//

import UIKit
import DinSupport
import HandyJSON

class DinNovaSiren: DinNovaPlugin {

    // 警笛的设置信息
    var sirenSetting = ""

    // 发送的码
    var sendid = ""

    override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)
        mapper <<< sirenSetting <-- ["siren_setting", "advancesetting"]
    }
}
