//
//  DinNovaPanelPing.swift
//  DinCore
//
//  Created by Jin on 2021/5/7.
//

import UIKit
import HandyJSON

public class DinNovaPanelPing: DinModel {
    /// ping的时长 (纳秒)
    public var duration: NSNumber = 0
    /// ping的开始时间
    public var time: NSNumber = 0

    public override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)
        mapper <<<
            self.duration <-- "pingduration"
        mapper <<<
            self.time <-- "pingtime"
    }
}
