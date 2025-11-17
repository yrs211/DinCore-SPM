//
//  DinNovaPanelArmOperationResult.swift
//  DinCore
//
//  Created by Jin on 2021/5/15.
//

import UIKit
import HandyJSON
import DinSupport

class DinNovaPanelArmOperationResult: DinModel {
    /// 是否已经强制执行了
    var force: Bool = false
    /// 操作时间
    var armTime: NSNumber = 0
    /// 操作者的Category
    var category: String = ""
    /// 操作者的subcategory
    var subcategory: String = ""
    /// 操作者的名字
    var plugName: String = ""
    /// 操作者的id
    var plugId: String = ""
    /// ReadyToArm还没关好的配件列表
    var plugs: [[String: String]] = []
    /// 屏蔽布防报警的配件
    var blockPlugs: [String] = []

    override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)
        mapper <<<
            self.armTime <-- "gmtime"
        mapper <<<
            self.plugName <-- "pluginname"
        mapper <<<
            self.plugId <-- "pluginid"
        mapper <<<
            self.plugs <-- "plugins"
        mapper <<<
            self.blockPlugs <-- "block"
    }
}
