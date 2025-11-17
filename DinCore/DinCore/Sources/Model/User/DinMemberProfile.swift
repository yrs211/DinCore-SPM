//
//  DinMemberProfile.swift
//  DinCore
//
//  Created by 郑少玲 on 2021/7/12.
//

import UIKit
import HandyJSON

open class DinMemberProfile: DinModel, NSCopying {
    /// 用户名
    open var name: String = ""
    /// 头像
    var avatar: String = ""
    
    public var photo: String {
        return avatar
    }

    public required init() {
        super.init()
    }

    open override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)
    }

    /// 深复制一个对象
    open func copy(with zone: NSZone? = nil) -> Any {
        let copyMember = DinMemberProfile()
        copyMember.name = self.name
        copyMember.avatar = self.avatar
        return copyMember
    }
    
    public static func generateAvatarUrl(with key: String) -> String {
        return DinCoreCDN_Host + key
    }

}
