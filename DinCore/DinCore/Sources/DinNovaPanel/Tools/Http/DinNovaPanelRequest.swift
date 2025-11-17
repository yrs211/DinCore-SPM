//
//  DinNovaPanelRequest.swift
//  DinCore
//
//  Created by Jin on 2021/5/12.
//

import UIKit
import Moya

let kEventLimit: Int = 10

enum DinNovaPanelRequest {
    /// 获取指定家庭下的主机token
    case listDeviceTokens(addTime: TimeInterval, homeID: String, order: String, pageSize: Int)
    /// 获取care mode 当前状态
    case getCareModeStatus(deviceID: String, homeID: String)
    /// 获取指定主机信息
    case searchDevices(ids: [String], homeID: String)
    /// 获取首页主机信息
    case getPanelInfo(id: String, homeID: String)
    /// 获取sim卡具体数据
    case getSIMCardInfo(id: String, homeID: String)
    /// 获取EntryDelay数据
    case getEntryDelay(id: String, homeID: String)
    /// 获取ExitDelay数据
    case getExitDelay(id: String, homeID: String)
    /// 获取警笛鸣响时间
    case getSirenTime(id: String, homeID: String)
    /// 获取HomeArm数据
    case getHomeArmInfo(id: String, homeID: String)
    /// 获取胁迫报警设置
    case getDuressAlarmSetting(id: String, homeID: String)
    /// 移除主机
    case removeDevice(id: String)
    /// 解绑用户
    case unbindUser(id: String, uid: String)
    /// 重命名主机
    case renameDevice(id: String, name: String, homeID: String)
    /// 验证主机密码
    case verifyPassword(id: String, pwd: String)
    /// 获取指定时间开始的Eventlist
    case getEvents(id: String, timestamp: Int64, homeID: String)
    /// 获取主机分享二维码
    case getDeviceQRCode(id: String, role: Int)
    /// 获取触发SOS的信息
    case getSOSInfo(id: String, homeID: String)
    /// 修改主机用户信息
    case modifyDeviceMember(id: String, uid: String, role: Int, push: Bool, sms: Bool, pushSystem: Bool, pushStatus: Bool, pushAlarm: Bool, smsSystem: Bool, smsStatus: Bool, smsAlarm: Bool)
    /// 获取紧急联系人
    case getEmergencyContacts(id: String)
    /// 修改其他紧急联系人
    case modifyEmergencyContact(id: String, uid: String, name: String, phone: String, sms: Bool, smsSystem: Bool, smsStatus: Bool, smsAlarm: Bool)
    /// 修改其他紧急联系人
    case addEmergencyContacts(id: String, contacts: String)
    /// 删除紧急联系人
    case removeEmergencyContact(id: String, uid: String)
    /// 获取消息模板
    case getMessage(id: String, homeID: String)
    /// 获取消息模板
    case getCID(id: String, homeID: String)
    /// 获取时区
    case getTimezoneSetting(id: String, homeID: String)
    /// 获取ReadyToArm配置
    case readyToArmStatus(id: String, homeID: String)
    /// 获取AdvancedSetting信息
    case getAdvancedSettings(id: String, homeID: String)
    /// 获取4G设置
    case getSIM4GData(id: String, homeID: String)
    /// 获取CMS设置
    case getCMSData(id: String, homeID: String)
    /// 获取care mode守护模式配置数据
    case getCareModeData(id: String, homeID: String)
    /// 获取eventlist的设置
    case getEventListSetting(id: String, homeID: String)
    /// 获取主机指定类型的插件信息
    case getAccessoryByType(id: String, type: Int, homeID: String)
    ///  按时间获取配件的信息
    case getAccessoryByAddTime(addTime: Int64, deviceID: String, homeID: String, stypes: [String])
    ///  查找指定配件的数据
    case searchAccessories(accessories:[[String:Any]], deviceID: String, homeID: String)
    /// 获取配件数量
    case countPlugins(homeID: String, panelID: String)
    /// 绑定主机家庭
    case bindPanelToHome(homeID: String, panelID: String)
    /// 获取继电器列表
    case relayAccessoryList(id: String, homeID: String)
}

extension DinNovaPanelRequest: DinHttpRequest {
    var requestPath: String {
        baseURL.absoluteString + path
    }

    var requestParam: DinHttpParams? {
        var jsonDict = [String: Any]()
        jsonDict["gmtime"] = Int64(Date().timeIntervalSince1970*1000000000)
        let token = DinCore.user?.userToken ?? "" 

        switch self {
        case .listDeviceTokens(let addTime, let homeID, let order, let pageSize):
            jsonDict["addtime"] = addTime
            jsonDict["home_id"] = homeID
            jsonDict["order"] = order
            jsonDict["page_size"] = pageSize
        case .getCareModeStatus(let deviceID, let homeID):
            jsonDict["device_id"] = deviceID
            jsonDict["home_id"] = homeID
        case .searchDevices(let deviceIDs, let homeID):
            jsonDict["device_ids"] = deviceIDs
            jsonDict["home_id"] = homeID
        
        case .getPanelInfo(let id, let homeID):
            jsonDict["device_id"] = id
            jsonDict["home_id"] = homeID

        case .getSIMCardInfo(let id, let homeID):
            jsonDict["deviceid"] = id
            jsonDict["home_id"] = homeID

        case .getEntryDelay(let id, let homeID):
            jsonDict["deviceid"] = id
            jsonDict["home_id"] = homeID

        case .getExitDelay(let id, let homeID):
            jsonDict["deviceid"] = id
            jsonDict["home_id"] = homeID

        case .getSirenTime(let id, let homeID):
            jsonDict["deviceid"] = id
            jsonDict["home_id"] = homeID

        case .getHomeArmInfo(let id, let homeID):
            jsonDict["deviceid"] = id
            jsonDict["home_id"] = homeID

        case .getDuressAlarmSetting(let id, let homeID):
            jsonDict["deviceid"] = id
            jsonDict["home_id"] = homeID

        case .removeDevice(let id):
            jsonDict["deviceid"] = id

        case .unbindUser(let id, let uid):
            jsonDict["deviceid"] = id
            jsonDict["unbinduid"] = uid

        case .renameDevice(let id, let name, let homeID):
            jsonDict["deviceid"] = id
            jsonDict["name"] = name
            jsonDict["home_id"] = homeID

        case .verifyPassword(let id, let pwd):
            jsonDict["deviceid"] = id
            jsonDict["password"] = pwd

        case .getEvents(let id, let timestamp, let homeID):
            jsonDict["deviceid"] = id
            jsonDict["timestamp"] = timestamp
            jsonDict["home_id"] = homeID

        case .getDeviceQRCode(let id, let role):
            jsonDict["deviceid"] = id
            jsonDict["newuserpermission"] = role

        case .getSOSInfo(let id, let homeID):
            jsonDict["deviceid"] = id
            jsonDict["home_id"] = homeID

        case .modifyDeviceMember(let id, let uid, let role, let push, let sms, let pushSystem, let pushStatus, let pushAlarm, let smsSystem, let smsStatus, let smsAlarm):
            jsonDict["deviceid"] = id
            jsonDict["uid"] = uid
            jsonDict["newpermission"] = role
            jsonDict["push"] = push
            jsonDict["push_sys"] = pushSystem
            jsonDict["push_info"] = pushStatus
            jsonDict["push_sos"] = pushAlarm
            jsonDict["sms"] = sms
            jsonDict["sms_sys"] = smsSystem
            jsonDict["sms_info"] = smsStatus
            jsonDict["sms_sos"] = smsAlarm

        case .getEmergencyContacts(let id):
            jsonDict["deviceid"] = id

        case .modifyEmergencyContact(let id, let uid, let name, let phone, let sms, let smsSystem, let smsStatus, let smsAlarm):
            jsonDict["deviceid"] = id
            jsonDict["contactid"] = uid
            jsonDict["name"] = name
            jsonDict["phone"] = phone
            jsonDict["sms"] = sms
            jsonDict["sms_sys"] = smsSystem
            jsonDict["sms_info"] = smsStatus
            jsonDict["sms_sos"] = smsAlarm

        case .addEmergencyContacts(let id, let contacts):
            jsonDict["deviceid"] = id
            jsonDict["contacts"] = contacts

        case .removeEmergencyContact(let id, let uid):
            jsonDict["deviceid"] = id
            jsonDict["contactid"] = uid

        case .getMessage(let id, let homeID):
            jsonDict["deviceid"] = id
            jsonDict["home_id"] = homeID

        case .getCID(let id, let homeID):
            jsonDict["deviceid"] = id
            jsonDict["home_id"] = homeID

        case .getTimezoneSetting(let id, let homeID):
            jsonDict["deviceid"] = id
            jsonDict["home_id"] = homeID

        case .readyToArmStatus(let id, let homeID):
            jsonDict["deviceid"] = id
            jsonDict["home_id"] = homeID

        case .getAdvancedSettings(let id, let homeID):
            jsonDict["deviceid"] = id
            jsonDict["home_id"] = homeID

        case .getSIM4GData(let id, let homeID):
            jsonDict["deviceid"] = id
            jsonDict["home_id"] = homeID

        case .getCMSData(let id, let homeID):
            jsonDict["deviceid"] = id
            jsonDict["home_id"] = homeID

        case .getCareModeData(let id, let homeID):
            jsonDict["device_id"] = id
            jsonDict["home_id"] = homeID

        case .getEventListSetting(let id, let homeID):
            jsonDict["device_id"] = id
            jsonDict["home_id"] = homeID

        case .getAccessoryByType(let id, let type, let homeID):
            jsonDict["deviceid"] = id
            jsonDict["category"] = type
            jsonDict["home_id"] = homeID
                        
        case .getAccessoryByAddTime(let addTime, let deviceID, let homeID, let stypes):
            jsonDict["addtime"] = addTime
            jsonDict["device_id"] = deviceID
            jsonDict["order"] = "asc"
            jsonDict["home_id"] = homeID
            jsonDict["stypes"] = stypes
            
        case .searchAccessories(let accessories, let deviceID, let homeID):
            jsonDict["accessories"] = accessories
            jsonDict["add_time"] = 0
            jsonDict["device_id"] = deviceID
            jsonDict["home_id"] = homeID
            
        case .countPlugins(let homeID, let panelID):
            jsonDict["home_id"] = homeID
            jsonDict["deviceid"] = panelID

        case .bindPanelToHome(let homeID, let panelID):
            jsonDict["home_id"] = homeID
            jsonDict["deviceid"] = panelID

        case .relayAccessoryList(let id, let homeID):
            jsonDict["deviceid"] = id
            jsonDict["home_id"] = homeID
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
        var requestPath = "/device/"

        switch self {
        case .listDeviceTokens:
            requestPath += "list-device-tokens/"
        case .getCareModeStatus:
            requestPath += "get-care-mode-status/"
        case .searchDevices:
            requestPath += "search-devices/"
        // 提交参数不变，只修改url，旧版本使用旧接口，去主机版本使用/get-device-info/v2/:appid
        case .getPanelInfo:
            requestPath += "get-device-info/v2/"
        case .getSIMCardInfo:
            requestPath += "getsimdata/"
        case .getEntryDelay:
            requestPath += "listentrydelaysetting/v4/"
        case .getExitDelay:
            requestPath += "exitdelaytime/"
        case .getSirenTime:
            requestPath += "sirentime/"
        case .getHomeArmInfo:
            requestPath += "listhomearmsetting/v4/"
        case .getDuressAlarmSetting:
            requestPath += "getintimidationalarmsetting/"
        case .removeDevice:
            requestPath += "removeuserdevice/"
        case .unbindUser:
            requestPath += "unbinduser/"
        case .renameDevice:
            requestPath += "modifydevicename/"
        case .verifyPassword:
            requestPath += "userverifydevicepwd/"
        case .getEvents:
            requestPath += "listeventlist/"
        case .getDeviceQRCode:
            requestPath += "generatesharecode/"
        case .getSOSInfo:
            requestPath += "getsosstate/"
        case .modifyDeviceMember:
            requestPath += "modifydevicecontact/v2/"
        case .getEmergencyContacts:
            requestPath += "listemergencycontacts/v2/"
        case .modifyEmergencyContact:
            requestPath += "modifycontactmanually/v2/"
        case .addEmergencyContacts:
            requestPath += "addmulticontactmanually/v2/"
        case .removeEmergencyContact:
            requestPath += "deletecontactmanually/"
        case .getMessage:
            requestPath += "getdevicetext/"
        case .getCID:
            requestPath += "getciddata/"
        case .getTimezoneSetting:
            requestPath += "gettimezonesetting/"
        case .readyToArmStatus:
            requestPath += "getrdasetting/"
        case .getAdvancedSettings:
            requestPath += "get-advanced-settings/"
        case .getSIM4GData:
            requestPath += "getsim4gdata/"
        case .getCMSData:
            requestPath += "getcmsdata/"
        case .getCareModeData:
            requestPath += "get-care-mode-data/"
        case .getEventListSetting:
            requestPath += "get-eventlist-setting/"
        case .getAccessoryByType:
            requestPath += "listspecifypluginsetting/v4/"
        case .getAccessoryByAddTime:
            requestPath += "list-accessories/"
        case .searchAccessories:
            requestPath += "search-accessories/"
        case .countPlugins:
            requestPath += "count-plugin/"
        case .bindPanelToHome:
            requestPath += "bind-home/"
        case .relayAccessoryList:
            requestPath += "listrelaysetting/"
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
