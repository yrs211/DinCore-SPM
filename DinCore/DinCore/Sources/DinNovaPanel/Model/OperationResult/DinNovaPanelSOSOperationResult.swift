//
//  DinNovaPanelSOSOperationResult.swift
//  DinCore
//
//  Created by Jin on 2021/5/16.
//

import UIKit
import HandyJSON
import DinSupport

class DinNovaPanelSOSOperationResult: DinModel {
    /// sos的开始时间
    var time: NSNumber = 0
    /// 触发sos的用户
    var uid: String = ""
    /// 触发sos的用户的头像
    var avatar: String = ""
    /// 触发sos的配件ID
    var pluginID: String = ""
    /// 触发sos的配件名称
    var pluginName: String = ""
    /// 是否主机触发
    var isdevice: Bool = false
    /// 用户定义的报警内容
    var message: String = ""
    var category: String = ""
    var subCategory: String = ""
    /// string, 报警类型 TASK_INTIMIDATIONALARM_SOS,TASK_SOS,TASK_ANTIINTERFER_SOS,TASK_FC_SOS,TASK_FC_SOS_PANEL
    var sosType: String = ""

    override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)
        mapper <<<
            self.avatar <-- "photo"
        mapper <<<
            self.pluginID <-- "pluginid"
        mapper <<<
            self.pluginName <-- "pluginname"
        mapper <<<
            self.message <-- "intimidationmessage"
        mapper <<<
            self.subCategory <-- "subcategory"
        mapper <<<
            self.subCategory <-- "sostype"
    }

}
