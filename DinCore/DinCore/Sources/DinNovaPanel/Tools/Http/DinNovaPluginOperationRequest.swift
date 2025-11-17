//
//  DinNovaPluginOperationRequest.swift
//  DinCore
//
//  Created by Jin on 2021/5/29.
//

import Foundation
import Moya
import DinSupport

public enum DinNovaPluginCommand: String {
    case setASKPlugin = "SET_NEWASKPLUGINDATA"
    case modifyPlugin = "SET_PLUGINDATA"

    case pluginLowPower = "EVENT_LOWERPOWER"
    case pluginOnline = "PLUGIN_ONLINE"
    case pluginOffline = "PLUGIN_OFFLINE"
    case pluginPowerUp = "EVENT_FULLPOWER"
    case setPluginBlock = "SET_PLUGIN_BLOCK"
    
    case setSmartPlugEnable = "SET_SMART_PLUG_ENABLE"
    case setNewSmartPlugEnable = "SET_NEW_SMART_PLUG_ON"

    // 修改配件配置
    case updatePluginConfig = "UPDATE_PLUGIN_CONF"

    // 修改门磁推送配置
    case setDoorWindowPushStatus = "SET_DOOR_WINDOW_PUSH_STATUS"

    // 测试警笛
    case testSiren = "TEST_SIREN"

    // 设置警笛
    case setSiren = "SET_WIRELESS_SIREN_ADVANCED_SETTING"

    // 设置ask警笛
    case setNewSiren = "SET_NEWASKSIRENDATA"

    // 继电器控制
    case setRelayAction = "RELAY_ACTION"

    // 配件的状态改变，暂时用在门磁开合弹窗提示
    case pluginEnableState = "TASK_DS_STATUS"
    /// 临时屏蔽红外触发
    case byPassPlugin5Min = "BYPASS_PLUGIN_5_MIN"
    /// 通知红外已经进入配置模式
    case pirSettingEnabled = "PIR_SETTING_ENABLED"
    /// 设置红外灵敏度设置模式
    case setSensitivity = "SET_SENSITIVITY"
    /// 退出红外设置模式
    case exitPIRSettingMode = "EXIT_PIR_SETTING_MODE"
}

enum DinNovaPluginOperationRequest {
    // 修改新ASK配件
    case setASKPlugin(deviceToken: String, eventID: String, data: [String: Any], homeID: String)
    // 修改配件
    case modifyPlugin(deviceToken: String, eventID: String, pluginID: String, pluginName: String, category: Int, homeID: String)
    // 修改配件屏蔽配置
    case setPluginBlock(deviceToken: String, eventID: String, data: [String: Any], block: Int, homeID: String)
    /// 修改门磁推送状态
    case setDoorWindowPushStatus(deviceToken: String, eventID: String, data: [String: Any], pushStatus: Bool, homeID: String)
    // 设置智能开关
    case setSmartPlugEnable(deviceToken: String, eventID: String, pluginID: String, enable: Bool, homeID: String)
    // 设置新的智能开关
    case setNewSmartPlugEnable(deviceToken: String, eventID: String, pluginID: String, enable: Bool, sendID: String, stype: String, homeID: String)
    // 修改配件配置
    case updatePluginConfig(deviceToken: String, eventID: String, sendID: String, datas: [[String: Any]], stype: String, homeID: String)
    // 测试警笛
    case testSiren(deviceToken: String, eventID: String, sendID: String, stype: String, volume: Int? = nil, music: Int? = nil, homeID: String)
    // 设置警笛
    case setNewSiren(deviceToken: String, eventID: String, sendID: String, type: String, settings: String, homeID: String)
    // 设置警笛声光
    case setSiren(deviceToken: String, eventID: String, sirenID: String, setting: String)
    //继电器
    case setRelayAction(deviceToken: String, eventID: String, action: String, sendid: String, homeID: String)
    /// 临时屏蔽红外触发
    case byPassPlugin5Min(deviceToken: String, homeID: String, eventID: String, pluginID: String, sendID: String, stype: String)
    /// 设置红外灵敏度设置模式
    case setSensitivity(deviceToken: String, homeID: String, eventID: String, pluginID: String, sendID: String, sensitivity: Int, stype: String)
    /// 退出红外设置模式
    case exitPIRSettingMode(deviceToken: String, homeID: String, eventID: String, pluginID: String, sendID: String, stype: String)
}

extension DinNovaPluginOperationRequest: DinHttpRequest {
    var requestPath: String {
        baseURL.absoluteString + path
    }

    var requestParam: DinHttpParams? {
        var jsonDict = [String: Any]()
        jsonDict["gmtime"] = Int64(Date().timeIntervalSince1970*1000000000)

        switch self {
            
        case .setASKPlugin(let deviceToken, let eventID, let data, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPluginCommand.setASKPlugin.rawValue
            jsonDict["stype"] = data["stype"] as? String ?? ""
            jsonDict["sendid"] = data["sendid"] as? String ?? ""
            jsonDict["name"] = data["name"] as? String ?? ""
            jsonDict["home_id"] = homeID
            
        case .modifyPlugin(let deviceToken, let eventID, let pluginID, let pluginName, let category, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPluginCommand.modifyPlugin.rawValue
            jsonDict["pluginid"] = pluginID
            jsonDict["plugin_item_name"] = pluginName
            jsonDict["category"] = category
            jsonDict["home_id"] = homeID
            
        case .setPluginBlock(let deviceToken, let eventID, let data, let block, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPluginCommand.setPluginBlock.rawValue
            jsonDict["plugin_id"] = data["plugin_id"]
            jsonDict["sendid"] = data["sendid"]
            jsonDict["stype"] = data["stype"]
            jsonDict["block"] = block
            jsonDict["home_id"] = homeID
            
        case .setDoorWindowPushStatus(let deviceToken, let eventID, let data, let pushStatus, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPluginCommand.setDoorWindowPushStatus.rawValue
            jsonDict["plugin_id"] = data["id"]
            jsonDict["sendid"] = data["sendid"]
            jsonDict["stype"] = data["stype"]
            jsonDict["push_status"] = pushStatus
            jsonDict["home_id"] = homeID
            
        case .setSmartPlugEnable(let deviceToken, let eventID, let pluginID, let enable, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPluginCommand.setSmartPlugEnable.rawValue
            jsonDict["pluginid"] = pluginID
            jsonDict["plugin_item_smart_plug_enable"] = enable.toInt()
            jsonDict["home_id"] = homeID
            
        case .setNewSmartPlugEnable(let deviceToken, let eventID, let pluginID, let enable, let sendID, let stype, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPluginCommand.setNewSmartPlugEnable.rawValue
            jsonDict["pluginid"] = pluginID
            jsonDict["plugin_item_smart_plug_enable"] = enable.toInt()
            jsonDict["sendid"] = sendID
            jsonDict["stype"] = stype
            jsonDict["dtype"] = 10
            jsonDict["home_id"] = homeID
            
        case .updatePluginConfig(let deviceToken, let eventID, let sendID, let datas, let stype, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPluginCommand.updatePluginConfig.rawValue
            jsonDict["sendid"] = sendID
            jsonDict["stype"] = stype
            jsonDict["datas"] = datas
            jsonDict["home_id"] = homeID
            
        case .testSiren(let deviceToken, let eventID, let sendID, let stype, let volume, let music, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPluginCommand.testSiren.rawValue
            jsonDict["sendid"] = sendID
            jsonDict["stype"] = stype
            jsonDict["volume"] = volume
            jsonDict["music"] = music
            jsonDict["home_id"] = homeID
            
        case .setNewSiren(let deviceToken, let eventID, let sendID, let type, let settings, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPluginCommand.setNewSiren.rawValue
            jsonDict["stype"] = type
            jsonDict["sendid"] = sendID
            jsonDict["advancesetting"] = settings
            jsonDict["home_id"] = homeID
            
        case .setRelayAction(let deviceToken, let eventID, let action, let sendid, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPluginCommand.setRelayAction.rawValue
            jsonDict["action"] = action
            jsonDict["sendid"] = sendid
            jsonDict["home_id"] = homeID
            
        case .setSiren(let deviceToken, let eventID, let sirenID, let setting):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPluginCommand.setSiren.rawValue
            jsonDict["pluginid"] = sirenID
            jsonDict["siren_setting"] = setting
        case .byPassPlugin5Min(let deviceToken, let homeID, let eventID, let pluginID, let sendID, let stype):
            jsonDict["cmd"] = DinNovaPluginCommand.byPassPlugin5Min.rawValue
            jsonDict["devtoken"] = deviceToken
            jsonDict["home_id"] = homeID
            jsonDict["messageid"] = eventID
            jsonDict["plugin_id"] = pluginID
            jsonDict["sendid"] = sendID
            jsonDict["stype"] = stype
        case .setSensitivity(deviceToken: let deviceToken, homeID: let homeID, eventID: let eventID, pluginID: let pluginID, sendID: let sendID, sensitivity: let sensitivity, stype: let stype):
            jsonDict["cmd"] = DinNovaPluginCommand.setSensitivity.rawValue
            jsonDict["devtoken"] = deviceToken
            jsonDict["home_id"] = homeID
            jsonDict["messageid"] = eventID
            jsonDict["plugin_id"] = pluginID
            jsonDict["sendid"] = sendID
            jsonDict["sensitivity"] = sensitivity
            jsonDict["stype"] = stype
        case .exitPIRSettingMode(deviceToken: let deviceToken, homeID: let homeID, eventID: let eventID, pluginID: let pluginID, sendID: let sendID, stype: let stype):
            jsonDict["cmd"] = DinNovaPluginCommand.exitPIRSettingMode.rawValue
            jsonDict["devtoken"] = deviceToken
            jsonDict["home_id"] = homeID
            jsonDict["messageid"] = eventID
            jsonDict["plugin_id"] = pluginID
            jsonDict["sendid"] = sendID
            jsonDict["stype"] = stype
        }
        return DinHttpParams.getParamsByUser(with: [:],
                                             dataParams: jsonDict)
    }

    public var baseURL: URL {
        return DinApi.getURL()
    }

    public var path: String {
        return "/device/sendcmd/" + (DinCore.appID ?? "")
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
