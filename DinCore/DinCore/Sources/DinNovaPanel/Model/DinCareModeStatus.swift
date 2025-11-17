//
//  DinCareModeStatus.swift
//  DinCore
//
//  Created by dinsafer on 2023/3/7.
//

import Foundation
import HandyJSON

public class DinCareModeStatus: DinModel {
    /// 上次care mode提示的时间
    var lastNoActionTime: NSNumber = 0
    ///
    var alarmDelayTime: Int = 0
    ///
    var enable: Bool = false
    ///
    var noActionTime: Int = 0
    required init() {}

    public override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)
        mapper <<<
            self.lastNoActionTime <-- "messageid"
        mapper <<<
            self.alarmDelayTime <-- "setting.alarm_delay_time"
        mapper <<<
            self.enable <-- "setting.enabled"
        mapper <<<
            self.noActionTime <-- "setting.no_action_time"
    }
    
}
