//
//  DinNovaPanelOperationRequest.swift
//  DinNovaPanel
//
//  Created by Jin on 2021/5/11.
//

import UIKit
import Moya
import DinSupport

public enum DinNovaPanelCommand: String {
    case arm = "TASK_ARM"
    case disarm = "TASK_DISARM"
    case homeArm = "TASK_HOMEARM"
    case sos = "TASK_SOS"
    case duressAlarm = "TASK_INTIMIDATIONALARM_SOS"
    case antiInterferenceAlarm = "TASK_ANTIINTERFER_SOS"
    case setSirenTime = "SET_SIRENTIME"
    case setExitDelay = "SET_EXITDELAY_2"
    case setEntryDelay = "SET_ENTRYDELAY_2"
//    case setKnockOverToSOS = "SET_KNOCK_OVER_TO_SOS"
    case setHomeArm = "SET_HOMEARM"
    case resetDevicePassword = "RESET_PASSWORD"
    case initDuressAlarm = "SET_INTIMIDATIONALARM_DATA_ON"
    case setDuressAlarmEnable = "SET_INTIMIDATIONALARM_ENABLE"
    case setDuressAlarmPassword = "SET_INTIMIDATIONALARM_PASSWORD"
    case setDuressAlarmText = "SET_INTIMIDATIONALARM_PUSH_TXT"
    case resetDevice = "RESET_DEVICE"
    case powerChanged = "UP_POWER"
    case roleChanged = "UPDATE_AUTH"
    case deviceUpgrading = "UPDATEING_SYSTEM"
    case customRemote = "CUSTOMIZE_REMOTE_CONTROL"
    case setMessage = "SET_DEVICE_TEXT"
    case setPushLang = "SET_DEVICE_TEXT_NEW"
    case deviceLowPower = "LOW_BATTERY"
    case authorityChanged = "UPDATE_CONTACT"
    case setContactID = "SET_CONTACTID"
    case setTimezone = "SET_DEVICE_TIMEZONE_2"
    case online = "ONLINE_STATE"
    case setDeviceName = "SET_DEVICE_NAME"
    case ipcMotionDetect = "IPC_MOTION_DETECTED"
    case switchOn = "SET_SMART_PLUG_ENABLE_ON"
    case switchOff = "SET_SMART_PLUG_ENABLE_OFF"
    case timerTask = "TASK_TIMER"
//    case doorbellRecord = "DOORBELL_CAPTURE"
    case setReadyToArm = "SET_READYTOARM"
    case getUnClosedSensor = "TASK_DS_STATUS_OP"
    case followingTask = "TASK_SMARTFOLLOWING"
    case fcSOS = "TASK_FC_SOS"     // 配件防拆报警cmd
    case panelFCSOS = "TASK_FC_SOS_PANEL"     // 主机防拆报警cmd
    case setPlaySoundSetting = "SET_PLAYSOUND"     //继电器控制
    case openDeviceBluetooth = "SET_BT"      //设置蓝牙
    case getDeviceSearchSmartBotResult = "TASK_SWITCH_BOT_STATUS"      //主机扫描附近的SmartBot得到的列表
    case followSmartBot = "COLLECT_SWITCHBOT"      //收藏SmartBot
    case unfollowSmartBot = "DELETE_SWITCHBOT"      //取消收藏SmartBot
    case setSmartBot = "SET_SWITCH_BOT"      //SmartBot的开关打开/关闭/反转/功能设置
    case set4GConfiguration = "SET_4G_INFO"        // 修改4G设置
    case setCMSInfo = "SET_CMS_INFO"  // 修改CMS设置
    case setRestrictMode = "SET_OFFLINE_MODE_SMS"
    case taskPluginException = "TASK_PLUGIN_EXCETION"

#warning("TODO: 涂鸦相关展示由于服务器还在，暂时不删除")
    case setTuyaPlugOn = "TY_SWITCH_ON"
    case setTuyaPlugOff = "TY_SWITCH_OFF"
    case setTuyaBlubOn = "TY_BLUB_ON"
    case setTuyaBlubOff = "TY_BLUB_OFF"
    case deleteTuyaPlugins = "DELETE_TUYA_PLUGIN"
    case updateTuyaPluginsName = "UPDATE_TUYA_NAME"
    
    #if ENABLE_IAP
    case ipcAlertExhausted = "IPC_ALERT_EXHAUSTED" // 移动侦条数用尽
    #endif
    case setCareModeData = "SET_CAREMODE_DATA"
    case setCareModePlugin = "SET_CAREMODE_PLUGIN"
    case careModeNoActionNotice = "NO_ACTION_NOTICE"    // 看护模式，超时没有配件触发通知
    case cancelCareModeNoActionSOS = "CANCEL_NO_ACTION_SOS"   // 关闭看护模式报警倒计时
    case careModeNoActionSOS = "NO_ACTION_SOS"    // 看护模式 报警
    // 修改eventlist设置
    case updateEventListSetting = "UPDATE_EVENTLIST_SETTING_2"
    // 添加
    case addPlugin = "ADD_PLUGIN"
    case addASKPlugin = "ADD_NEWASKPLUGIN"
    // 删除
    case deletePlugin = "DELETE_PLUGIN"
    case deleteASKPLugin = "DELETE_NEWASKPLUGIN"
    // 主动请求获取配件状态
    case pluginPowerValueChanged = "TASK_PLUGIN_STATUS"

    /// 升级主机固件
    case requestPanelUpgrade = "SYSTEM_UPDATERESET"

    /// 触发配对自定义cmd
    case learnModeOps = "learnModeOps"
    /// 主机启用 zt
    case enableZTAuth = "ZT_AUTH"
}

enum DinNovaPanelOperationRequest {
    /// 布防
    case arm(deviceToken: String, eventID: String, force:Bool, homeID: String)
    /// 撤防
    case disarm(deviceToken: String, eventID: String, homeID: String)
    /// 在家布防
    case homeArm(deviceToken: String, eventID: String, force:Bool, homeID: String)
    /// 报警
    case sos(deviceToken: String, eventID: String, homeID: String)
    /// 设置延迟布防
    case setExitDelay(deviceToken: String, eventID: String, time: Int, soundEnable: Bool, homeID: String)
    /// 设置延迟报警
    case setEntryDelay(deviceToken: String, eventID: String, time: Int, soundEnable: Bool, datas: String, thirdPartyDatas: String, newASKDatas: String, homeID: String)
    /// 设置警笛鸣响时间
    case setSirenTime(deviceToken: String, eventID: String, time: Int, homeID: String)
    /// HomeArm设置
    case setHomeArm(deviceToken: String, eventID: String, datas: String, thirdPartyDatas: String, newASKDatas: String, homeID: String)
    /// 初始化胁迫报警
    case initDuressAlarm(deviceToken: String, eventID: String, password: String, text: String, homeID: String)
    /// 设置胁迫报警开关
    case setDuressAlarmEnable(deviceToken: String, eventID: String, enable: Bool, homeID: String)
    /// 设置胁迫报警密码
    case setDuressAlarmPassword(deviceToken: String, eventID: String, password: String, homeID: String)
    /// 设置胁迫报警文字
    case setDuressAlarmText(deviceToken: String, eventID: String, text: String, homeID: String)
    /// 设置推送语言ID
    case setPushLang(deviceToken: String, eventID: String, langID: String, homeID: String)
    /// 设置消息模板
    case setMessage(deviceToken: String, eventID: String, langID: String, message: String, homeID: String)
    /// 设置时区
    case setTimezone(deviceToken: String, eventID: String, timezone: String, homeID: String)
    /// 设置ReadyToArm配置
    case setReadyToArm(deviceToken: String, eventID: String, enable: Bool, homeID: String)
    /// 设置布撤防声音
    case setPlaySoundSetting(deviceToken: String, eventID: String, ison: Bool, homeID: String)
    /// 设置限制模式开关
    case setRestrictMode(deviceToken: String, eventID: String, ison: Bool, homeID: String)
    /// 设置主机密码
    case resetDevicePassword(deviceToken: String, eventID: String, newPwd: String, oldPwd: String, homeID: String)
    /// 通知主机打开蓝牙
    case openDeviceBluetooth(deviceToken: String, eventID: String, bt: Bool, homeID: String)
    /// 修改4G设置
    case set4GConfig(deviceToken: String, eventID: String, data: String, homeID: String)
    /// 修改CMS设置
    case saveCMSData(deviceToken: String, eventID: String, protocolName: String, info: [String: Any], homeID: String)
    /// 看护模式设置总开关或时间
    case setCareModeData(deviceToken: String, eventID: String, delayTime: NSNumber?, noActionTime: NSNumber?, mode: Bool?, homeID: String)
    /// 看护模式设置配件开关
    case setCareModePlugin(deviceToken: String, eventID: String, datas: String, homeID: String)
    /// 修改eventlist设置
    case updateEventListSetting(deviceToken: String, eventID: String, doorWindow: Bool?, tamper: Bool?, homeID: String)
    /// 关闭看护模式报警倒计时
    case cancelCareModeNoActionSOS(deviceToken: String, eventID: String, homeID: String)
    /// 看护模式 报警
    case careModeNoActionSOS(deviceToken: String, eventID: String, homeID: String)
    /// 重置主机
    case resetDevice(deviceToken: String, eventID: String, password: String, retainPlugins: Bool, homeID: String)
    /// 获取异常配件列表(低电及打开的)
    case getTaskPluginException(deviceToken: String, eventID: String, homeID: String)
    /// 获取未闭合的门磁列表（ready to arm）
    case getUnClosedSensor(deviceToken: String, eventID: String, task: String, homeID: String)
    // 添加配件
    case addPlugin(deviceToken: String, eventID: String, pluginID: String, forDecodeID: String, pluginName: String, category: Int, subCategory: String, ipcData: String?, sirenSetting: String?, homeID: String)
    // 添加新ASK配件
    case addASKPlugin(deviceToken: String, eventID: String, plugin: String, homeID: String)
    // 删除配件
    case deletePlugin(deviceToken: String, eventID: String, pluginID: String, category: Int, homeID: String)
    // 删除新ASK配件
    case deleteASKPlugin(deviceToken: String, eventID: String, data: [String: Any], homeID: String)
    // 通过类型获取配件信息
    case getPluginStatus(deviceToken: String, eventID: String, stypes: String, homeID: String)

    /// 请求主机进行固件升级
    case requestPanelUpgrade(deviceToken: String, homeID: String, userID: String, messageID: String)
    /// 主机启用 zt
    case enableZTAuth(deviceToken: String, homeID: String, eventID: String)
}

extension DinNovaPanelOperationRequest: DinHttpRequest {
    var requestPath: String {
        baseURL.absoluteString + path
    }

    var requestParam: DinHttpParams? {
        var jsonDict = [String: Any]()
        jsonDict["gmtime"] = Int64(Date().timeIntervalSince1970*1000000000)

        switch self {
        case .arm(let deviceToken, let eventID, let force, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.arm.rawValue
            jsonDict["force"] = force
            jsonDict["home_id"] = homeID

        case .disarm(let deviceToken, let eventID, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.disarm.rawValue
            jsonDict["home_id"] = homeID

        case .homeArm(let deviceToken, let eventID, let force, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.homeArm.rawValue
            jsonDict["force"] = force
            jsonDict["home_id"] = homeID

        case .sos(let deviceToken, let eventID, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.sos.rawValue
            jsonDict["home_id"] = homeID

        case .setExitDelay(let deviceToken, let eventID, let time, let soundEnable, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.setExitDelay.rawValue
            jsonDict["time"] = time
            jsonDict["exitdelaysound"] = soundEnable
            jsonDict["home_id"] = homeID

        case .setEntryDelay(let deviceToken, let eventID, let time, let soundEnable, let datas, let thirdPartyDatas, let newASKDatas, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.setEntryDelay.rawValue
            jsonDict["time"] = time
            jsonDict["entrydelaysound"] = soundEnable
            jsonDict["datas"] = datas
            jsonDict["thirdpartydatas"] = thirdPartyDatas
            jsonDict["newaskdatas"] = newASKDatas
            jsonDict["home_id"] = homeID

        case .setSirenTime(let deviceToken, let eventID, let time, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.setSirenTime.rawValue
            jsonDict["time"] = time
            jsonDict["home_id"] = homeID

        case .setHomeArm(let deviceToken, let eventID, let datas, let thirdPartyDatas, let newASKDatas, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.setHomeArm.rawValue
            jsonDict["datas"] = datas
            jsonDict["thirdpartydatas"] = thirdPartyDatas
            jsonDict["newaskdatas"] = newASKDatas
            jsonDict["home_id"] = homeID

        case .initDuressAlarm(let deviceToken, let eventID, let password, let text, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.initDuressAlarm.rawValue
            jsonDict["password"] = password
            jsonDict["pushliterary"] = text
            jsonDict["home_id"] = homeID

        case .setDuressAlarmEnable(let deviceToken, let eventID, let enable, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.setDuressAlarmEnable.rawValue
            jsonDict["enable"] = enable
            jsonDict["home_id"] = homeID

        case .setDuressAlarmPassword(let deviceToken, let eventID, let password, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.setDuressAlarmPassword.rawValue
            jsonDict["password"] = password
            jsonDict["home_id"] = homeID

        case .setDuressAlarmText(let deviceToken, let eventID, let text, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.setDuressAlarmText.rawValue
            jsonDict["pushliterary"] = text
            jsonDict["home_id"] = homeID

        case .setPushLang(let deviceToken, let eventID, let langID, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.setPushLang.rawValue
            jsonDict["lang"] = langID
            jsonDict["home_id"] = homeID

        case .setMessage(let deviceToken, let eventID, let langID, let message, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.setMessage.rawValue
            jsonDict["lang"] = langID
            jsonDict["device_text"] = message
            jsonDict["home_id"] = homeID

        case .setTimezone(let deviceToken,let eventID, let timezone, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.setTimezone.rawValue
            jsonDict["timezone"] = timezone
            jsonDict["home_id"] = homeID

        case .setReadyToArm(let deviceToken,let eventID, let enable, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.setReadyToArm.rawValue
            jsonDict["enable"] = enable
            jsonDict["home_id"] = homeID

        case .setPlaySoundSetting(let deviceToken,let eventID, let ison, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.setPlaySoundSetting.rawValue
            jsonDict["ison"] = ison
            jsonDict["home_id"] = homeID

        case .setRestrictMode(let deviceToken,let eventID, let ison, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.setRestrictMode.rawValue
            jsonDict["offline_sms"] = ison
            jsonDict["home_id"] = homeID

        case .resetDevicePassword(let deviceToken, let eventID, let newPwd, let oldPwd, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.resetDevicePassword.rawValue
            jsonDict["password"] = newPwd
            jsonDict["old_password"] = oldPwd
            jsonDict["home_id"] = homeID

        case .openDeviceBluetooth(let deviceToken, let eventID, let bt, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.openDeviceBluetooth.rawValue
            jsonDict["bt"] = bt
            jsonDict["home_id"] = homeID

        case .setCareModeData(let deviceToken, let eventID, let delayTime, let noActionTime, let mode, let homeID):
            // 这里会传入nil， 如果其中有值是nil， json字典是删除这个key-value的
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.setCareModeData.rawValue
            jsonDict["alarm_delay_time"] = delayTime
            jsonDict["care_mode"] = mode
            jsonDict["no_action_time"] = noActionTime
            jsonDict["home_id"] = homeID

        case .updateEventListSetting(let deviceToken, let eventID, let doorWindow, let tamper, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.updateEventListSetting.rawValue
            jsonDict["dw_event_log"] = doorWindow
            jsonDict["tamper_event_log"] = tamper
            jsonDict["home_id"] = homeID

        case .set4GConfig(let deviceToken, let eventID, let data, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["info"] = data
            jsonDict["cmd"] = DinNovaPanelCommand.set4GConfiguration.rawValue
            jsonDict["home_id"] = homeID

        case .saveCMSData(let deviceToken, let eventID, let protocolName, let info, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["protocol_name"] = protocolName
            jsonDict["info"] = info
            jsonDict["cmd"] = DinNovaPanelCommand.setCMSInfo.rawValue
            jsonDict["home_id"] = homeID

        case .setCareModePlugin(let deviceToken, let eventID, let datas, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.setCareModePlugin.rawValue
            jsonDict["datas"] = datas
            jsonDict["home_id"] = homeID

        case .cancelCareModeNoActionSOS(let deviceToken, let eventID, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.cancelCareModeNoActionSOS.rawValue
            jsonDict["home_id"] = homeID

        case .careModeNoActionSOS(let deviceToken, let eventID, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.careModeNoActionSOS.rawValue
            jsonDict["home_id"] = homeID

        case .resetDevice(let deviceToken, let eventID, let password, let retainPlugins, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.resetDevice.rawValue
            jsonDict["password"] = password
            jsonDict["retainplugins"] = retainPlugins
            jsonDict["home_id"] = homeID

        case .getTaskPluginException(let deviceToken, let eventID, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.taskPluginException.rawValue
            jsonDict["home_id"] = homeID

        case .getUnClosedSensor(let deviceToken, let eventID, let task, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.getUnClosedSensor.rawValue
            jsonDict["task"] = task
            jsonDict["home_id"] = homeID

        case .addPlugin(let deviceToken, let eventID, let pluginID, let forDecodeID, let pluginName, let category, let subCategory, let ipcData, let sirenSetting, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.addPlugin.rawValue
            jsonDict["pluginname"] = pluginName
            jsonDict["category"] = category
            jsonDict["subcategory"] = subCategory
            jsonDict["home_id"] = homeID
            if category == DinAccessoryType.thirdParty.rawValue {
                jsonDict["pluginid"] = pluginID[0...3]
                jsonDict["decodeid"] = pluginID
            } else {
                jsonDict["pluginid"] = pluginID
                if forDecodeID.count > 0 {
                    jsonDict["decodeid"] = DinAccessoryUtil.str64(toHexStr: forDecodeID)
                } else {
                    jsonDict["decodeid"] = DinAccessoryUtil.str64(toHexStr: pluginID)
                }
            }
            if let ipcData = ipcData {
                jsonDict["ipcdata"] = DinCore.cryptor.rc4EncryptToHexString(with: ipcData, key: DinCore.appSecret ?? "") ?? ""
            }
            if let sirenSetting = sirenSetting {
                jsonDict["siren_setting"] = sirenSetting
            }

        case .addASKPlugin(let deviceToken, let eventID, let plugin, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.addASKPlugin.rawValue
            jsonDict["plugin"] = plugin
            jsonDict["home_id"] = homeID

        case .deletePlugin(let deviceToken, let eventID, let pluginID, let category, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.deletePlugin.rawValue
            jsonDict["pluginid"] = pluginID
            jsonDict["category"] = category
            jsonDict["home_id"] = homeID

        case .deleteASKPlugin(let deviceToken, let eventID, let data, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.deleteASKPLugin.rawValue
            jsonDict["stype"] = data["stype"] as? String ?? ""
            jsonDict["sendid"] = data["sendid"] as? String ?? ""
            jsonDict["home_id"] = homeID

        case .getPluginStatus(let deviceToken, let eventID, let stypes, let homeID):
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = eventID
            jsonDict["cmd"] = DinNovaPanelCommand.pluginPowerValueChanged.rawValue
            jsonDict["stype"] = stypes
            jsonDict["home_id"] = homeID
        case .requestPanelUpgrade(let deviceToken, let homeID, let userID, let messageID):
            jsonDict["cmd"] = DinNovaPanelCommand.requestPanelUpgrade.rawValue
            jsonDict["devtoken"] = deviceToken
            jsonDict["messageid"] = messageID
            jsonDict["userid"] = userID
            jsonDict["home_id"] = homeID
        case .enableZTAuth(deviceToken: let deviceToken, homeID: let homeID, eventID: let eventID):
            jsonDict["cmd"] = DinNovaPanelCommand.enableZTAuth.rawValue
            jsonDict["devtoken"] = deviceToken
            jsonDict["home_id"] = homeID
            jsonDict["messageid"] = eventID
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
