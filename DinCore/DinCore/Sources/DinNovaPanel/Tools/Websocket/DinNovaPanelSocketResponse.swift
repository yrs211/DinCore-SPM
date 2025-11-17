//
//  DinNovaPanelSocketResponse.swift
//  DinCore
//
//  Created by Jin on 2021/5/13.
//

import UIKit
import HandyJSON

public enum DinNovaPanelResponseAction: String {
    case result = "/device/result"
    case event = "/device/revice"
    case ping = "/device/ping"
    case offline = "/device/offline"
    case sim = "/device/sim"
    case ack = "/device/cmdack"
}

class DinNovaPanelSocketResponse: DinModel {
    /// 状态
    public var status: Int = 0
    /// 错误描述
    public var error: String = ""
    /// 返回结果
    public var result: String = ""
    /// 操作cmd
    public var cmd: String = ""
    /// 操作类型
    public var action: String = ""
    /// 操作message id
    public var messageID: String = ""

    public override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)
        mapper <<<
            self.status <-- "Status"
        mapper <<<
            self.error <-- "ErrorMessage"
        mapper <<<
            self.result <-- "Result"
        mapper <<<
            self.cmd <-- "Cmd"
        mapper <<<
            self.action <-- "Action"
        mapper <<<
            self.messageID <-- "MessageId"
    }

}
