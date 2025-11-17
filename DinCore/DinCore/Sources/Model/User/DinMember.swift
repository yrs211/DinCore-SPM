//
//  DinMember.swift
//  DinCore
//
//  Created by Jin on 2021/4/20.
//

import UIKit
import HandyJSON

open class DinMember: DinModel, NSCopying {
    /// 用户名
    open var name: String = ""
    /// 头像
    var avatar: String = ""
    
    var avatarLink: String = ""
    
    public var photo: String {
        if avatarLink.count > 0 {
            return avatarLink
        } else if avatar.count > 0 {
            return DinMemberProfile.generateAvatarUrl(with: avatar)
        }
        return ""
    }
    /// 权限
    open var level: Int = 10
    /// 用户id
    open var userId: String = ""
    /// 用户加入纳秒时间戳
    open var joinTimestamp: Int = 0
    /// 该成员是否有绑定电话号码
    open var bindPhone: Bool = false
    /// 推送总开关
    open var push: Bool = false
    /// 短信总开关
    open var sms: Bool = false
    /// 系统 推送 通知开关
    open var systemPush: Bool = false
    /// 状态 推送 通知开关
    open var infoPush: Bool = false
    /// 报警 推通 知送开关
    open var sosPush: Bool = false
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
            self.level <-- "level"
        mapper <<<
            self.userId <-- "user_id"
        mapper <<<
            self.name <-- "uid"
        mapper <<<
            self.joinTimestamp <-- "addtime"
        mapper <<<
            self.bindPhone <-- "bind_phone"
        mapper <<<
            self.systemPush <-- "push_sys"
        mapper <<<
            self.infoPush <-- "push_info"
        mapper <<<
            self.sosPush <-- "push_sos"
        mapper <<<
            self.systemSMS <-- "sms_sys"
        mapper <<<
            self.infoSMS <-- "sms_info"
        mapper <<<
            self.sosSMS <-- "sms_sos"
        mapper <<<
            self.avatarLink <-- "avatar_link"
        
    }

    /// 深复制一个对象
    open func copy(with zone: NSZone? = nil) -> Any {
        let copyMember = DinMember()
        copyMember.name = self.name
        copyMember.avatar = self.avatar
        copyMember.level = self.level
        copyMember.userId = self.userId
        copyMember.joinTimestamp = self.joinTimestamp
        copyMember.bindPhone = self.bindPhone
        copyMember.push = self.push
        copyMember.sms = self.sms
        copyMember.systemPush = self.systemPush
        copyMember.infoPush = self.infoPush
        copyMember.sosPush = self.sosPush
        copyMember.systemSMS = self.systemSMS
        copyMember.infoSMS = self.infoSMS
        copyMember.sosSMS = self.sosSMS
        return copyMember
    }
}
