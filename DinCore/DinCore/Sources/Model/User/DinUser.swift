//
//  DinUser.swift
//  DinCore
//
//  Created by Jin on 2021/4/20.
//

import UIKit
import HandyJSON
import DinSupport

open class DinUser: DinModel {

    /// 获取/更新用户下的家庭，家庭列表
    static let homeInfoQueue = DispatchQueue.init(label: DinQueueName.getHomeInfo, attributes: .concurrent)
    static let homeQueue = DispatchQueue.init(label: DinQueueName.getHome, attributes: .concurrent)
    static let homeDeviceInfoQueue = DispatchQueue.init(label: DinQueueName.homeDeviceDataSync, attributes: .concurrent)
    static let homeDevicesSyncQueue = DispatchQueue.init(label: DinQueueName.homeDevicesSync, attributes: .concurrent)

    /// 用户id
    open var id: String = ""
    /// 头像
    var avatar: String = ""
    /// 用于MSCT通讯的ID
    open var uniqueID: String = ""
    /// 通讯者的通讯加密key
    open var communicateKey: String = ""
    /// 用户昵称
    open var name: String = ""
    /// 邮箱
    open var mail: String = ""
    /// 手机号码
    open var phone: String = ""
    /// 操作token
    open var token: String = ""
    /// 密码
    open var password: String = ""
    /// 安装人员uid
    open var thirdpartyUID: String = ""
    
    //r2版本开始使用
    open var avatarUrl: String = ""

    private var unsafeCurHome: DinHome?
    open var curHome: DinHome? {
        var tempHome: DinHome?
        DinUser.homeQueue.sync { [weak self] in
            tempHome = self?.unsafeCurHome
        }
        return tempHome
    }
    /// 家庭列表
    private var unsafeHomes: [DinHome]? = []
    open var homes: [DinHome]? {
        var tempHomes: [DinHome]?
        DinUser.homeQueue.sync { [weak self] in
            tempHomes = self?.unsafeHomes
        }
        return tempHomes
    }

    open override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)
        mapper <<<
            self.id <-- "user_id"
        mapper <<<
            self.name <-- "uid"
        mapper <<<
            self.mail <-- "email"
        mapper <<<
            self.avatarUrl <-- "avatar_url"
    }

    public static func homeDevicesAsyncQueue(_ complete: @escaping ()->()) {
        DinUser.homeDevicesSyncQueue.async(flags: .barrier) {
            complete()
        }
    }
    public static func homeDevicesSyncQueue(_ complete:  @escaping ()->()) {
        DinUser.homeDevicesSyncQueue.sync {
            complete()
        }
    }

    public var userToken: String {
        if thirdpartyUID.isEmpty {
            return DinCore.cryptor.rc4EncryptToHexString(with: "\(token)_\(Int64(Date().timeIntervalSince1970*1000000000))", key: DinCore.appSecret ?? "") ?? ""
        } else {
            return DinCore.cryptor.rc4EncryptToHexString(with: "\(token)", key: DinCore.appSecret ?? "") ?? ""
        }
    }

    public var photo: String {
        if avatarUrl.count > 0 {
            return avatarUrl
        } else if avatar.count > 0 {
            return DinMemberProfile.generateAvatarUrl(with: avatar)
        }
        return ""
    }

    /// 设置当前家庭
    /// 新增逻辑，如果是同一个家庭，更新里面的信息，不替换实例
    /// - Parameters:
    ///   - home: 需要设置的实例
    ///   - replace: 是否强制替换实例
    ///   - complete: 更新完毕后，返回是否是同一个家庭
    public func setCurHome(_ home: DinHome?, replace: Bool, complete: ((Bool)-> ())?){
        DinUser.homeQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            let isSame = self.unsafeCurHome?.id == home?.id
            if isSame, !replace, let newhome = home {
                // 同一个家庭, 不强制替换
                // 则替换对应信息
                self.unsafeCurHome?.refreshData(by: newhome)
            } else {
                self.unsafeCurHome?.cache()
                self.unsafeCurHome = home
            }
            DinCore.dataBase.saveUser(self)
            DispatchQueue.global().async {
                complete?(isSame)
            }
        }
    }

    public func setHomeList(_ homeList: [DinHome]?) {
        DinUser.homeQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.unsafeHomes = homeList
            DinCore.dataBase.saveUser(self)
        }
    }
    public func addHomes(_ homeList: [DinHome]) {
        guard homeList.count > 0 else {
            return
        }
        DinUser.homeQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.unsafeHomes?.append(contentsOf: homeList)
            DinCore.dataBase.saveUser(self)
        }
    }
    public func deleteHome(withID homeID: String) {
        guard homeID.count > 0 else {
            return
        }
        DinUser.homeQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            let optionIndex = self.unsafeHomes?.firstIndex(where: { home in
                home.id == homeID
            })
            if let index = optionIndex {
                self.unsafeHomes?.remove(at: index)
            }
            DinCore.dataBase.saveUser(self)
        }
    }
}
