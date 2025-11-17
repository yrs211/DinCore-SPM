//
//  DinNovaPanelEvent.swift
//  DinCore
//
//  Created by Jin on 2021/5/7.
//

import UIKit
import HandyJSON

public enum DinNovaPanelEventType: String {
    case action = "Action"
    case setting = "Setting"
}

public class DinNovaPanelEvent: DinModel {
    /// 事件操作的用户
    var user: String = ""
    /// 用户头像
    var photo: String = ""
    /// 命令
    var cmd: String = ""
    /// 类型
    var type: String = ""
    /// 发送时间
    var time: NSNumber = 0
    /// 执行时长
    var duration: NSNumber = 0
    /// 执行结果
    /*      -2: 收到ack
            -1：请求中
            0：失败
            1：成功
            2：HTTP完成
    */
    var result: Int = -1
    /// 事件ID
    var id: String = ""

    var pluginID = ""
    var subCategory: String?
    var data: [String: Any]?

    var retry: Int = 0

    init(id: String, cmd: String, type: String) {
        self.id = id
        self.cmd = cmd
        self.user = DinCore.user?.id ?? ""
        self.photo = DinCore.user?.avatar ?? ""
        self.time = NSNumber(value: Int64(Date().timeIntervalSince1970*1000000000) as Int64)
        self.type = type
    }

    public required init() {
        fatalError("init() has not been implemented")
    }

    public override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)
        mapper <<<
            self.id <-- "messageid"
        mapper <<<
            self.cmd <-- "cmdname"
        mapper <<<
            self.pluginID <-- "pluginid"
        mapper <<<
            self.subCategory <-- "subcategory"
    }
}
