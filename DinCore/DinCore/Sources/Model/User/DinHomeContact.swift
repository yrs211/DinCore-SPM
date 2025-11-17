//
//  DinHomeContact.swift
//  DinCore
//
//  Created by 郑少玲 on 2021/6/7.
//

import Foundation
import HandyJSON

open class DinHomeContact: DinModel, NSCopying {
    /// 用户名
    open var name: String = ""
    /// 用户id
    open var contactId: String = ""
    /// 联系人电话
    open var phone: String = ""
    /// 用户加入纳秒时间戳
    open var joinTimestamp: Int = 0
    /// 短信总开关
    open var sms: Bool = false
    /// 系统 短信 通知开关
    open var systemSMS: Bool = false
    /// 状态 短信 通知开关
    open var infoSMS: Bool = false
    /// 报警 短信 通知开关
    open var sosSMS: Bool = false

    public required init() {
        super.init()
    }

    open override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)
        mapper <<<
            self.contactId <-- "contact_id"
        mapper <<<
            self.joinTimestamp <-- "addtime"
        mapper <<<
            self.systemSMS <-- "sms_sys"
        mapper <<<
            self.infoSMS <-- "sms_info"
        mapper <<<
            self.sosSMS <-- "sms_sos"
        
        
    }

    /// 深复制一个对象
    open func copy(with zone: NSZone? = nil) -> Any {
        let copyContact = DinHomeContact()
        copyContact.name = self.name
        copyContact.contactId = self.contactId
        copyContact.phone = self.phone
        copyContact.joinTimestamp = self.joinTimestamp
        copyContact.sms = self.sms
        copyContact.systemSMS = self.systemSMS
        copyContact.infoSMS = self.infoSMS
        copyContact.sosSMS = self.sosSMS
        return copyContact
    }
}

