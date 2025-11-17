//
//  DinNovaSecurityAccessory.swift
//  DinCore
//
//  Created by Jin on 2021/6/22.
//

import UIKit
import DinSupport
import HandyJSON

class DinNovaSecurityAccessory: DinNovaPlugin {

    // 配件屏蔽设置，-1: 不支持，0：不屏蔽；1、屏蔽tamper alarm；2：屏蔽整个配件；3：chime
    var block: Int = -1

    // 发送的码
    var sendid = ""

    override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)
        mapper <<< block <-- "block"
    }
}
