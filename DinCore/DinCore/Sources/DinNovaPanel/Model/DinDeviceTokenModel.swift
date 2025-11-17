//
//  DinDeviceTokenModel.swift
//  DinCore
//
//  Created by dinsafer on 2023/3/7.
//

import Foundation
import HandyJSON

public class DinDeviceTokenModel: DinModel {
    /// 设备id
    var id: String = ""
    /// token
    var token: String = ""

    public override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)
        mapper <<<
            self.id <-- "messageid"
        mapper <<<
            self.token <-- "token"
    }
    
}
