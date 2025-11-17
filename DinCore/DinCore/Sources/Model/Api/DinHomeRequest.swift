//
//  DinHomeRequest.swift
//  DinCore
//
//  Created by 郑少玲 on 2021/5/31.
//

import Foundation
import Moya
import DinSupport

/// 家庭的相关信息设置
public struct DinHomeRequestInfo {
    /// 家庭推送语言
    public let pushLanguage: String
    /// 家庭的名字
    public let homeName: String
    /// 用户在家庭下的权限等级
    public let level: Int
    /// 家庭相关信息是否推送
    public let isPush: Bool
    /// 推送设置代号
    public let notification: Int64

    public init(pushLanguage: String, homeName: String, level: Int, isPush: Bool, notification: Int64) {
        self.pushLanguage = pushLanguage
        self.homeName = homeName
        self.level = level
        self.isPush = isPush
        self.notification = notification
    }
}

enum DinHomeRequest {
    /// 新建家庭
    case createHome(name: String, language: String)
    /// 修改家庭的名称
    case renameHome(homeID: String, name: String)
    /// 删除家庭
    case deleteHome(homeID: String)
    /// 列出用户的所有家庭
    case listHomes
    /// 生成家庭成员邀请码
    case generateHomeInvitationCode(homeID: String, level: Int)
    /// 校验邀请码
    case verifyHomeInvitationCode(code: String)
    /// 列出指定家庭的所有成员
    case listHomeMembers(homeID: String, pageSize: Int, level: Int, joinTime: Int)
    /// 修改成员信息
    case updateMemberInfo(homeID: String, member: DinMember)
    /// 删除指定成员
    case deleteMember(homeID: String, userID: String)
    /// 获取家庭基本信息
    case getHomeDetailInfo(homeID: String)
    /// 添加家庭联系人
    case addHomeContact(homeID: String, SMS: Bool, systemSMS: Bool, infoSMS: Bool, sosSMS: Bool, contacts: [[String: Any]])
    /// 联系人列表
    case listContacts(homeID: String, pageSize: Int, contactID: String)
    /// 删除指定联系人
    case deleteContact(homeID: String, contactID: String)
    /// 修改家庭联系人信息
    case updateContact(homeID: String, contact: DinHomeContact)
    /// 设置家庭推送语言
    case updateHomePushLanguage(homeID: String, language: String)
    /// 获取家庭推送语言
    case getHomePushLanguage(homeID: String)
    /// 获取3个用户头像+用户数量
    case countContact(homeID: String)
    /// 删除主机
    case deletePanel(panelID: String)
    /// 获取 Eventlist，含过滤
    /// 2.1以前旧接口
    case getFilteredEventsOld(panelID: String, timestamp: Int64, homeID: String, filters: [Int])
    /// 2.1以后新接口
    case getFilteredEvents(timestamp: Int64, homeID: String, filters: [Int])
    /// MSCT通讯登录
    case msctLogin(homeID: String)
    /// MSCT通讯登出
    case msctLogout(homeID: String)
    /// 获取指定provider的ipc数量
    case countCam(providers: [String], homeID: String)
    /// 获取IPC, 门铃和叮咚数量
    case countCamAndDoorBell(homeID: String)
    /// 判断是否唯一管理员
    case checkIfOnlyAdmin(homeID: String)
    /// 强制删除家庭(唯一管理员时调用)
    case forceDeleteHome(homeID: String)

    /// 新建自定义规则家庭
    case createThirdPartyHome(bindID: String, bindToken: String, homeInfo: DinHomeRequestInfo)
    /// 删除通过自定义规则新建的成员
    case deleteThirdPartyMember(homeID: String, userID: String)
    /// 删除自定义规则家庭
    case deleteThirdPartyHome(homeID: String)

    /// 主机键盘密码-用户
    case getMemberPWDInfo(panelID: String, homeID: String, userID: String)
    case resetMemberPWDInfo(panelID: String, homeID: String, userID: String)
    case updateMemberPWDInfo(panelID: String, homeID: String, userID: String, enable: Bool)

    /// 获取指定每日回忆视频 url 链接
    case getDailyMemoriesVideoURL(homeID: String, recordID: String)
}

extension DinHomeRequest: DinHttpRequest {
    var requestPath: String {
        baseURL.absoluteString + path
    }

    var requestParam: DinHttpParams? {
        var jsonDict = [String: Any]()
        jsonDict["gmtime"] = Int64(Date().timeIntervalSince1970*1000000000)
        let token = DinCore.user?.userToken ?? ""

        switch self {
        case .createHome(let name, let language):
            jsonDict["home_name"] = name
            jsonDict["language"] = language

        case .renameHome(let homeID, let name):
            jsonDict["home_id"] = homeID
            jsonDict["home_name"] = name

        case .deleteHome(let homeID):
            jsonDict["home_id"] = homeID

        case .generateHomeInvitationCode(let homeID, let level):
            jsonDict["home_id"] = homeID
            jsonDict["level"] = level

        case .verifyHomeInvitationCode(let code):
            jsonDict["code"] = code

        case .listHomeMembers(let homeID, let pageSize, let level, let joinTime):
            jsonDict["home_id"] = homeID
            jsonDict["page_size"] = pageSize
            if level != 0 {
                jsonDict["level"] = level
            }
            jsonDict["addtime"] = joinTime

        case .updateMemberInfo(let homeID, let member):
            jsonDict["home_id"] = homeID
            jsonDict["user_id"] = member.userId
            jsonDict["level"] = member.level
            jsonDict["push"] = member.push
            jsonDict["sms"] = member.sms
            jsonDict["push_sos"] = member.sosPush
            jsonDict["push_info"] = member.infoPush
            jsonDict["push_sys"] = member.systemPush
            jsonDict["sms_sos"] = member.sosSMS
            jsonDict["sms_info"] = member.infoSMS
            jsonDict["sms_sys"] = member.systemSMS

        case .deleteMember(let homeID, let userID):
            jsonDict["home_id"] = homeID
            jsonDict["user_id"] = userID

        case .getHomeDetailInfo(let homeID):
            jsonDict["home_id"] = homeID

        case .addHomeContact(let homeID, let SMS, let systemSMS, let infoSMS, let sosSMS, let contacts):
            jsonDict["home_id"] = homeID
            jsonDict["sms"] = SMS
            jsonDict["sms_sys"] = systemSMS
            jsonDict["sms_info"] = infoSMS
            jsonDict["sms_sos"] = sosSMS
            jsonDict["contacts"] = contacts

        case .listContacts(let homeID, let pageSize, let contactID):
            jsonDict["home_id"] = homeID
            jsonDict["page_size"] = pageSize
            jsonDict["contact_id"] = contactID

        case .deleteContact(let homeID, let contactID):
            jsonDict["home_id"] = homeID
            jsonDict["contact_id"] = contactID

        case .updateContact(let homeID, let contact):
            jsonDict["home_id"] = homeID
            jsonDict["contact_id"] = contact.contactId
            jsonDict["name"] = contact.name
            jsonDict["phone"] = contact.phone
            jsonDict["sms"] = contact.sms
            jsonDict["sms_sys"] = contact.systemSMS
            jsonDict["sms_info"] = contact.infoSMS
            jsonDict["sms_sos"] = contact.sosSMS

        case .updateHomePushLanguage(let homeID, let language):
            jsonDict["home_id"] = homeID
            jsonDict["language"] = language

        case .getHomePushLanguage(let homeID):
            jsonDict["home_id"] = homeID

        case .countContact(let homeID):
            jsonDict["home_id"] = homeID

        case .deletePanel(let panelID):
            jsonDict["deviceid"] = panelID

        case .getFilteredEventsOld(let panelID, let timestamp, let homeID, let filters):
            jsonDict["deviceid"] = panelID
            jsonDict["timestamp"] = timestamp
            jsonDict["limit"] = 20
            jsonDict["home_id"] = homeID
            jsonDict["filters"] = filters

        case .getFilteredEvents(let timestamp, let homeID, let filters):
            jsonDict["time"] = timestamp
            jsonDict["limit"] = 20
            jsonDict["home_id"] = homeID
            jsonDict["type_ids"] = filters

        case .msctLogin(let homeID):
            jsonDict["home_id"] = homeID
            if let thirdpartyUID = DinCore.user?.thirdpartyUID, !thirdpartyUID.isEmpty {
                jsonDict["user_id"] = thirdpartyUID
            }
        case .msctLogout(let homeID):
            jsonDict["home_id"] = homeID
            if let thirdpartyUID = DinCore.user?.thirdpartyUID, !thirdpartyUID.isEmpty {
                jsonDict["user_id"] = thirdpartyUID
            }
        case .countCam(let providers, let homeID):
            jsonDict["providers"] = providers
            jsonDict["home_id"] = homeID

        case .countCamAndDoorBell(let homeID):
            jsonDict["home_id"] = homeID

        case .checkIfOnlyAdmin(let homeID):
            jsonDict["home_id"] = homeID

        case .forceDeleteHome(let homeID):
            jsonDict["home_id"] = homeID

        case .createThirdPartyHome(let bindID, let bindToken, let homeInfo):
            jsonDict["device_id"] = bindID
            jsonDict["device_token"] = bindToken
            jsonDict["language"] = homeInfo.pushLanguage
            jsonDict["device_name"] = homeInfo.homeName
            jsonDict["level"] = homeInfo.level
            jsonDict["push"] = homeInfo.isPush
            jsonDict["notification"] = homeInfo.notification

        case .deleteThirdPartyMember(let homeID, let userID):
            jsonDict["home_id"] = homeID
            jsonDict["user_id"] = userID

        case .deleteThirdPartyHome(let homeID):
            jsonDict["home_id"] = homeID

        case .getMemberPWDInfo(let panelID, let homeID, let userID):
            jsonDict["device_id"] = panelID
            jsonDict["home_id"] = homeID
            jsonDict["user_id"] = userID

        case .resetMemberPWDInfo(let panelID, let homeID, let userID):
            jsonDict["device_id"] = panelID
            jsonDict["home_id"] = homeID
            jsonDict["user_id"] = userID

        case .updateMemberPWDInfo(let panelID, let homeID, let userID, let enable):
            jsonDict["device_id"] = panelID
            jsonDict["home_id"] = homeID
            jsonDict["user_id"] = userID
            jsonDict["pwd_enable"] = enable
        case .getDailyMemoriesVideoURL(let homeID, let recordID):
            jsonDict["home_id"] = homeID
            jsonDict["record_id"] = recordID

        default:
            jsonDict.removeAll()
        }

        let encryptSecret = DinCore.appSecret ?? ""
        return DinHttpParams(with: ["gm": 1, "token": token],
                             dataParams: jsonDict,
                             encryptSecret: encryptSecret)
    }

    public var baseURL: URL {
        return DinApi.getURL()
    }

    public var path: String {
        var requestPath = "/home/"

        switch self {
        case .createHome:
            requestPath += "new-home/"
        case .renameHome:
            requestPath += "rename-home/"
        case .deleteHome:
            requestPath += "delete-home/"
        case .listHomes:
            requestPath += "list-homes/"
        case .generateHomeInvitationCode:
            requestPath += "new-invitation-code/"
        case .verifyHomeInvitationCode:
            requestPath += "check-invitation-code/"
        case .listHomeMembers:
            requestPath += "list-members/"
        case .updateMemberInfo:
            requestPath += "update-member/"
        case .deleteMember:
            requestPath += "delete-member/"
        case .getHomeDetailInfo:
            requestPath += "get-info/"
        case .addHomeContact:
            requestPath += "new-contacts/"
        case .listContacts:
            requestPath += "list-contacts/"
        case .deleteContact:
            requestPath += "delete-contact/"
        case .updateContact:
            requestPath += "update-contact/"
        case .updateHomePushLanguage:
            requestPath += "set-notifications-language/"
        case .getHomePushLanguage:
            requestPath += "get-notifications-language/"
        case .countContact:
            requestPath += "count-contact/"
        case .msctLogin:
            requestPath += "e2e-login/"
        case .msctLogout:
            requestPath += "e2e-logout/"
        case .deletePanel:
            return "/device/delete-device/" + (DinCore.appID ?? "")
        case .getFilteredEventsOld:
            return "/device/list-eventlists/" + (DinCore.appID ?? "")
        case .getFilteredEvents:
            return "/device/get-event-list/" + (DinCore.appID ?? "")
        case .countCam:
            return "/ipc/count-ipc-by-providers/" + (DinCore.appID ?? "")
        case .countCamAndDoorBell:
            return "/ipc/count-ipc-door-bell/" + (DinCore.appID ?? "")
        case .checkIfOnlyAdmin:
            requestPath += "is-only-admin/"
        case .forceDeleteHome:
            requestPath += "force-delete-home/"
        case .createThirdPartyHome:
            requestPath += "ext/init-home-and-member/"
        case .deleteThirdPartyMember:
            requestPath += "ext/delete-member/"
        case .deleteThirdPartyHome:
            requestPath += "ext/delete-home/"
        case .getMemberPWDInfo:
            requestPath += "get-member-pwd-info/"
        case .resetMemberPWDInfo:
            requestPath += "reset-member-pwd/"
        case .updateMemberPWDInfo:
            requestPath += "update-member-pwd-info/"
        case .getDailyMemoriesVideoURL:
            return "/ipc/md/get-daily-memories-video-url/" + (DinCore.appID ?? "")
        }

        return requestPath + (DinCore.appID ?? "")
    }

    public var method: Moya.Method {
        return .post
    }

    public var parameters: [String : Any]? {
        requestParam?.uploadDict
    }

    public var task: Moya.Task {
        if parameters != nil {
            return .requestParameters(parameters: parameters!, encoding: URLEncoding.default)
        } else {
            return .requestPlain
        }
    }

    public var validate: Bool {
        return true
    }

    public var sampleData: Data {
        return "Half measures are as bad as nothing at all.".data(using: .utf8)!
    }

    public var headers: [String: String]? {
        return ["Host": DinCoreDomain, "X-Online-Host": DinCoreDomain]
    }
}
