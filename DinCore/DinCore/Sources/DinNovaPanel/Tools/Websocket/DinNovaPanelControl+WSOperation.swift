//
//  DinNovaPanelControl+WSOperation.swift
//  DinCore
//
//  Created by Jin on 2021/5/16.
//

import Foundation
import DinSupport

// MARK: - Websocket 的 CMD
extension DinNovaPanelControl {
    // 连接websocket
    static let CMD_WS_CONN = "operation_ws_connection"
    // 连接websocket
    static let CMD_WS_STATE_CHANGED = "operation_ws_statechanged"
    // 连接websocket
    static let CMD_RENEW = "panel_renew"
    // 布撤防
    static let CMD_ARM = "operation_arm"
    // 主动报警
    static let CMD_SOS = "operation_sos"
    // 设置延时布防信息
    static let CMD_SET_EXITDELAY = "set_exitdelay"
    // 设置延时报警信息
    static let CMD_SET_ENTRYDELAY = "set_entrydelay"
    // 设置警笛鸣响时间
    static let CMD_SET_SIRENTIME = "set_sirentime"
    // 设置HomeArm数据
    static let CMD_SET_HOMEARMINFO = "set_homearm_info"
    // 设置胁迫报警设置
    static let CMD_INIT_DURESSINFO = "init_duress_info"
    // 设置胁迫报警设置
    static let CMD_ENABLE_DURESS = "enable_duress"
    // 设置胁迫报警设置
    static let CMD_SET_DURESSPWD = "set_duress_password"
    // 设置胁迫报警设置
    static let CMD_SET_DURESSTEXT = "set_duress_text"
    // 设置通知的短信，push内容
    static let CMD_SET_MESSAGELANG = "set_message_language"
    // 设置消息模板
    static let CMD_SET_MESSAGETEMPLATE = "set_message_template"
    // 设置消息模板
    static let CMD_SET_TIMEZONE = "set_timezone"
    // 设置ReadyToArm配置
    static let CMD_SET_RTASTATUS = "set_readytoarm_status"
    // 设置布撤防声音
    static let CMD_SET_ARMSOUND = "set_arm_sound"
    // 设置限制模式开关
    static let CMD_SET_RESTRICTMODE = "set_restrict_mode"
    // 重置主机密码
    static let CMD_SET_PANELPWD = "set_panel_password"
    // 开启主机蓝牙
    static let CMD_OPEN_BLE = "open_panel_bluetooth"
    // 设置4G信息
    static let CMD_SET_4GINFO = "set_4g_info"
    // 设置CMS信息
    static let CMD_SET_CMSINFO = "set_cms_info"
    // 设置守护模式配置
    static let CMD_SET_CAREMODE = "set_caremode"
    // 设置守护模式的配件行为
    static let CMD_SET_CAREMODEPLUGS = "set_caremode_plugins"
    // 关闭看护模式报警倒计时
    static let CMD_CAREMODE_CANCELSOS = "caremode_cancel_sos"
    // 看护模式 报警
    static let CMD_CAREMODE_NOACTION_SOS = "caremode_noaction_sos"
    // 设置eventlist的配置
    static let CMD_SET_EVENTLIST_SETTING = "set_eventlist_setting"
    // 重置主机
    static let CMD_RESET_PANEL = "reset_panel"
    // 获取异常配件列表(低电及打开的)
    static let CMD_GET_EXCETION_PLUGS = "get_exception_plugs"
    // 获取未闭合的门磁列表（ready to arm）
    static let CMD_GET_UNCLOSEPLUGS = "get_unclose_plugs"
    // 获取配件列表中配件状态
    static let CMD_GET_PLUGSSTATUS = "get_plugin_list_status"

    // [触发配对]激活主机接收配件信号功能
    static let CMD_LEARNMODE_ACTIVE = "start_learnmode"
    // [触发配对]关闭主机接收配件信号功能
    static let CMD_LEARNMODE_DEACTIVE = "stop_learnmode"
    // [触发配对]开始监听配件信号
    static let CMD_LEARNMODE_LISTEN = "start_learnmode_listen"
    /// 主机启用 zt
    static let CMD_ZT_AUTH = "enable_zt_auth"
}

// MARK: - 布撤防、报警
extension DinNovaPanelControl {
    func arm(force: Bool) {
        operationInfoHolder.isArmForce = force
        operationInfoHolder.armActionEventID = String.UUID()
        let cmd = DinNovaPanelCommand.arm.rawValue
        let request = DinNovaPanelOperationRequest.arm(deviceToken: panel.token,
                                                       eventID: operationInfoHolder.armActionEventID ?? "",
                                                       force: operationInfoHolder.isArmForce, homeID: homeID)
        makeArmOperation(request: request, armCMD: cmd)
    }

    /// 撤防
    /// - Parameter check: 记录一下messageid看是否需要匹配
    func disarm(check: Bool) {
        operationInfoHolder.armActionEventID = String.UUID()
        if check {
            operationInfoHolder.disarmMessageID = operationInfoHolder.armActionEventID
        }
        let cmd = DinNovaPanelCommand.disarm.rawValue
        let request = DinNovaPanelOperationRequest.disarm(deviceToken: panel.token, eventID: operationInfoHolder.armActionEventID ?? "", homeID: homeID)
        makeArmOperation(request: request, armCMD: cmd)
    }

    func homearm(force: Bool) {
        operationInfoHolder.isArmForce = force
        operationInfoHolder.armActionEventID = String.UUID()
        let cmd = DinNovaPanelCommand.homeArm.rawValue
        let request = DinNovaPanelOperationRequest.homeArm(deviceToken: panel.token,
                                                           eventID: operationInfoHolder.armActionEventID ?? "",
                                                           force: operationInfoHolder.isArmForce, homeID: homeID)
        makeArmOperation(request: request, armCMD: cmd)
    }

    func sos() {
        operationInfoHolder.sosActionEventID = String.UUID()
        let request = DinNovaPanelOperationRequest.sos(deviceToken: panel.token, eventID: operationInfoHolder.sosActionEventID ?? "", homeID: homeID)
        let event = DinNovaPanelEvent(id: operationInfoHolder.sosActionEventID ?? "",
                                      cmd: DinNovaPanelCommand.sos.rawValue,
                                      type: DinNovaPanelEventType.action.rawValue)
        operationTimeoutChecker.enter(event)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }
}

extension DinNovaPanelControl {
    private func makeArmOperation(request: DinNovaPanelOperationRequest, armCMD: String) {
        let event = DinNovaPanelEvent(id: operationInfoHolder.armActionEventID ?? "",
                                      cmd: armCMD,
                                      type: DinNovaPanelEventType.action.rawValue)
        operationTimeoutChecker.enter(event)

        if lanCommunicator?.isCOAPAvailable ?? false {
            let makeCoapSucceed = lanCommunicator?.sendOperationSuccess(withCMD: armCMD,
                                                                        messageID: operationInfoHolder.armActionEventID ?? "",
                                                                        force: operationInfoHolder.isArmForce) ?? false
            if !makeCoapSucceed {
                sendCMD(request: request, event: event)
            }
        }
        else {
            sendCMD(request: request, event: event)
        }
        operationInfoHolder.isArmForce = false
    }

    private func sendCMD(request: DinNovaPanelOperationRequest, event: DinNovaPanelEvent) {
        DinHttpProvider.request(request, success: nil, fail: nil)

        delay(5) { [weak self] in
            if self?.operationTimeoutChecker.eventCount ?? 0 == 0 {
                return
            }
            if event.retry == 3 || event.result == 1 || event.result == -2 {
                return
            }
            event.retry = event.retry + 1
            self?.sendCMD(request: request, event: event)
        }
    }

    private func acceptLackOfParamsFail(withCMD cmd: String) {
        let returnDict = makeResultFailureInfo(withCMD: cmd,
                                               owner: true,
                                               errorMessage: "invoke api without parameters",
                                               result: [:])
        self.accept(panelOperationResult: returnDict)
    }
}

// MARK: - 基础操作
extension DinNovaPanelControl {
    /// 设置延时布防
    func setExitDelay(_ data: [String: Any]) {
        guard let time = data["time"] as? Int, let enable = data["soundEnable"] as? Bool else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_SET_EXITDELAY)
            return
        }
        operationInfoHolder.setExitDelayMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.setExitDelayMID ?? "",
                                      cmd: DinNovaPanelCommand.setExitDelay.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.setExitDelay(deviceToken: panel.token,
                                                                eventID: operationInfoHolder.setExitDelayMID ?? "",
                                                                time: time,
                                                                soundEnable: enable, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 设置延时报警
    func setEntryDelay(_ data: [String: Any]) {
        guard let time = data["time"] as? Int,
              let enable = data["soundEnable"] as? Bool,
              let datas = data["datas"] as? String,
              let thirdpartydatas = data["thirdpartydatas"] as? String,
              let newaskdatas = data["newaskdatas"] as? String else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_SET_ENTRYDELAY)
            return
        }
        operationInfoHolder.setEntryDelayMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.setEntryDelayMID ?? "",
                                      cmd: DinNovaPanelCommand.setEntryDelay.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.setEntryDelay(deviceToken: panel.token,
                                                                 eventID: operationInfoHolder.setEntryDelayMID ?? "",
                                                                 time: time,
                                                                 soundEnable: enable,
                                                                 datas: datas,
                                                                 thirdPartyDatas: thirdpartydatas,
                                                                 newASKDatas: newaskdatas, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 设置警笛鸣响时间
    func setSirenTime(_ data: [String: Any]) {
        guard let time = data["time"] as? Int else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_SET_SIRENTIME)
            return
        }
        operationInfoHolder.setSirenTimeMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.setSirenTimeMID ?? "",
                                      cmd: DinNovaPanelCommand.setSirenTime.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.setSirenTime(deviceToken: panel.token,
                                                                eventID: operationInfoHolder.setSirenTimeMID ?? "",
                                                                time: time, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 设置HomeArm信息配置
    func setHomeArmInfo(_ data: [String: Any]) {
        guard let datas = data["datas"] as? String,
              let thirdpartydatas = data["thirdpartydatas"] as? String,
              let newaskdatas = data["newaskdatas"] as? String else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_SET_HOMEARMINFO)
            return
        }
        operationInfoHolder.setHomeArmInfoMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.setHomeArmInfoMID ?? "",
                                      cmd: DinNovaPanelCommand.setHomeArm.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.setHomeArm(deviceToken: panel.token,
                                                              eventID: operationInfoHolder.setHomeArmInfoMID ?? "",
                                                              datas: datas,
                                                              thirdPartyDatas: thirdpartydatas,
                                                              newASKDatas: newaskdatas, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 初始化胁迫报警
    func initDuressInfo(_ data: [String: Any]) {
        guard let password = data["password"] as? String, let text = data["sms"] as? String else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_INIT_DURESSINFO)
            return
        }
        operationInfoHolder.initDuressInfoMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.initDuressInfoMID ?? "",
                                      cmd: DinNovaPanelCommand.initDuressAlarm.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.initDuressAlarm(deviceToken: panel.token,
                                                                   eventID: operationInfoHolder.initDuressInfoMID ?? "",
                                                                   password: password,
                                                                   text: text, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 开启胁迫报警
    func enableDuressAlarm(_ data: [String: Any]) {
        guard let enable = data["enable"] as? Bool else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_ENABLE_DURESS)
            return
        }
        operationInfoHolder.enableDuressMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.enableDuressMID ?? "",
                                      cmd: DinNovaPanelCommand.setDuressAlarmEnable.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)


        let request = DinNovaPanelOperationRequest.setDuressAlarmEnable(deviceToken: panel.token,
                                                                        eventID: operationInfoHolder.enableDuressMID ?? "",
                                                                        enable: enable, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 设置胁迫报警密码
    func setDuressPassword(_ data: [String: Any]) {
        guard let password = data["password"] as? String else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_SET_DURESSPWD)
            return
        }
        operationInfoHolder.setDuressPasswordMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.setDuressPasswordMID ?? "",
                                      cmd: DinNovaPanelCommand.setDuressAlarmPassword.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.setDuressAlarmPassword(deviceToken: panel.token,
                                                                          eventID: operationInfoHolder.setDuressPasswordMID ?? "",
                                                                          password: password, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 设置胁迫报警描述
    func setDuressText(_ data: [String: Any]) {
        guard let text = data["sms"] as? String else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_SET_DURESSTEXT)
            return
        }
        operationInfoHolder.setDuressTextMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.setDuressTextMID ?? "",
                                      cmd: DinNovaPanelCommand.setDuressAlarmText.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.setDuressAlarmText(deviceToken: panel.token,
                                                                      eventID: operationInfoHolder.setDuressTextMID ?? "",
                                                                      text: text, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 设置通知的短信，push内容
    func setMessageLang(_ data: [String: Any]) {
        guard let langID = data["langID"] as? String else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_SET_MESSAGELANG)
            return
        }
        operationInfoHolder.setMessageLanguageMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.setMessageLanguageMID ?? "",
                                      cmd: DinNovaPanelCommand.setPushLang.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.setPushLang(deviceToken: panel.token,
                                                               eventID: operationInfoHolder.setMessageLanguageMID ?? "", langID: langID, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 设置消息模板
    func setMessageTemplate(_ data: [String: Any]) {
        guard let langID = data["langID"] as? String, let message = data["message"] as? String else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_SET_MESSAGETEMPLATE)
            return
        }
        operationInfoHolder.setMessageTemplateMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.setMessageTemplateMID ?? "",
                                      cmd: DinNovaPanelCommand.setMessage.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.setMessage(deviceToken: panel.token,
                                                              eventID: operationInfoHolder.setMessageTemplateMID ?? "",
                                                              langID: langID,
                                                              message: message, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 设置时区
    func setTimezone(_ data: [String: Any]) {
        guard let timezone = data["timezone"] as? String else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_SET_TIMEZONE)
            return
        }
        operationInfoHolder.setTimezoneMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.setTimezoneMID ?? "",
                                      cmd: DinNovaPanelCommand.setTimezone.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.setTimezone(deviceToken: panel.token,
                                                               eventID: operationInfoHolder.setTimezoneMID ?? "",
                                                               timezone: timezone, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 设置时区
    func setReadyToArm(_ data: [String: Any]) {
        guard let enable = data["enable"] as? Bool else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_SET_RTASTATUS)
            return
        }
        operationInfoHolder.setReadyToArmMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.setReadyToArmMID ?? "",
                                      cmd: DinNovaPanelCommand.setReadyToArm.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.setReadyToArm(deviceToken: panel.token,
                                                                 eventID: operationInfoHolder.setReadyToArmMID ?? "",
                                                                 enable: enable, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 设置布撤防声音
    func setArmSound(_ data: [String: Any]) {
        guard let on = data["on"] as? Bool else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_SET_ARMSOUND)
            return
        }
        operationInfoHolder.setArmSoundMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.setArmSoundMID ?? "",
                                      cmd: DinNovaPanelCommand.setPlaySoundSetting.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)
        let request = DinNovaPanelOperationRequest.setPlaySoundSetting(deviceToken: panel.token,
                                                                       eventID: operationInfoHolder.setArmSoundMID ?? "",
                                                                       ison: on, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 设置限制模式开关
    func setRestrictMode(_ data: [String: Any]) {
        guard let on = data["on"] as? Bool else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_SET_RESTRICTMODE)
            return
        }
        operationInfoHolder.setRestrictModeMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.setRestrictModeMID ?? "",
                                      cmd: DinNovaPanelCommand.setRestrictMode.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.setRestrictMode(deviceToken: panel.token,
                                                                   eventID: operationInfoHolder.setRestrictModeMID ?? "",
                                                                   ison: on, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 设置主机密码
    func resetPanelPassword(_ data: [String: Any]) {
        guard let password = data["password"] as? String, let oldPassword = data["old_password"] as? String else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_SET_PANELPWD)
            return
        }
        operationInfoHolder.setPanelPasswordMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.setPanelPasswordMID ?? "",
                                      cmd: DinNovaPanelCommand.resetDevicePassword.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.resetDevicePassword(deviceToken: panel.token,
                                                                     eventID: operationInfoHolder.setPanelPasswordMID ?? "",
                                                                     newPwd: password, oldPwd: oldPassword, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 设置主机蓝牙开关
    func setPanelBluetooth(_ data: [String: Any]) {
        guard let on = data["on"] as? Bool else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_OPEN_BLE)
            return
        }
        operationInfoHolder.setPanelBluetoothMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.setPanelBluetoothMID ?? "",
                                      cmd: DinNovaPanelCommand.openDeviceBluetooth.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.openDeviceBluetooth(deviceToken: panel.token,
                                                                       eventID: operationInfoHolder.setPanelBluetoothMID ?? "",
                                                                       bt: on, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 设置4G信息
    func set4GInfo(_ data: [String: Any]) {
        guard let info = data["info"] as? String else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_SET_4GINFO)
            return
        }
        operationInfoHolder.set4GInfoMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.set4GInfoMID ?? "",
                                      cmd: DinNovaPanelCommand.openDeviceBluetooth.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.set4GConfig(deviceToken: panel.token,
                                                               eventID: operationInfoHolder.set4GInfoMID ?? "",
                                                               data: info, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 设置CMS信息
    func setCMSInfo(_ data: [String: Any]) {
        guard let info = data["info"] as? [String: Any], let protocolName = data["protocolName"] as? String else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_SET_CMSINFO)
            return
        }
        operationInfoHolder.setCMSInfoMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.setCMSInfoMID ?? "",
                                      cmd: DinNovaPanelCommand.setCMSInfo.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.saveCMSData(deviceToken: panel.token,
                                                               eventID: operationInfoHolder.setCMSInfoMID ?? "",
                                                               protocolName: protocolName,
                                                               info: info, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 设置守护模式配置
    func setCareMode(_ data: [String: Any]) {
        operationInfoHolder.setCareModeMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.setCareModeMID ?? "",
                                      cmd: DinNovaPanelCommand.setCareModeData.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)
        let on = data["on"] as? Bool
        let noActionTime = data["noActionTime"] as? NSNumber
        let delayTime = data["alarmDelayTime"] as? NSNumber
        let request = DinNovaPanelOperationRequest.setCareModeData(deviceToken: panel.token,
                                                                   eventID: operationInfoHolder.setCareModeMID ?? "",
                                                                   delayTime: delayTime,
                                                                   noActionTime: noActionTime,
                                                                   mode: on, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 设置守护模式配件配置
    func setCareModePlugs(_ data: [String: Any]) {
        guard let datas = data["plugins"] as? String else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_SET_CAREMODEPLUGS)
            return
        }
        operationInfoHolder.setCareModePlugsMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.setCareModePlugsMID ?? "",
                                      cmd: DinNovaPanelCommand.setCareModePlugin.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.setCareModePlugin(deviceToken: panel.token,
                                                                     eventID: operationInfoHolder.setCareModePlugsMID ?? "",
                                                                     datas: datas, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 关闭看护模式报警倒计时
    func cancelCareModeNoActionSOS() {
        operationInfoHolder.cancelCareModeNoActionSOSMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.cancelCareModeNoActionSOSMID ?? "",
                                      cmd: DinNovaPanelCommand.cancelCareModeNoActionSOS.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.cancelCareModeNoActionSOS(deviceToken: panel.token,
                                                                             eventID: operationInfoHolder.cancelCareModeNoActionSOSMID ?? "", homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 看护模式 报警
    func careModeSOSNoAction() {
        operationInfoHolder.careModeSOSNoActionMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.careModeSOSNoActionMID ?? "",
                                      cmd: DinNovaPanelCommand.careModeNoActionSOS.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.careModeNoActionSOS(deviceToken: panel.token,
                                                                       eventID: operationInfoHolder.careModeSOSNoActionMID ?? "", homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 设置eventlist的配置
    func setEventListSetting(_ data: [String: Any]) {
        operationInfoHolder.setEventListSettingMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.setEventListSettingMID ?? "",
                                      cmd: DinNovaPanelCommand.updateEventListSetting.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let doorWindow = data["doorWindow"] as? Bool
        let tamper = data["tamper"] as? Bool
        let request = DinNovaPanelOperationRequest.updateEventListSetting(deviceToken: panel.token,
                                                                          eventID: operationInfoHolder.setEventListSettingMID ?? "",
                                                                          doorWindow: doorWindow,
                                                                          tamper: tamper, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 重置主机
    func resetDevice(_ data: [String: Any]) {
        guard let password = data["password"] as? String, let retainPlugins = data["retainPlugins"] as? Bool else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_RESET_PANEL)
            return
        }
        operationInfoHolder.resetDeviceMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.resetDeviceMID ?? "",
                                      cmd: DinNovaPanelCommand.resetDevice.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.resetDevice(deviceToken: panel.token,
                                                               eventID: operationInfoHolder.resetDeviceMID ?? "",
                                                               password: password,
                                                               retainPlugins: retainPlugins, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 获取异常配件列表(低电及打开的)
    func getExceptionPlugs() {
        operationInfoHolder.getExceptionPlugsMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.getExceptionPlugsMID ?? "",
                                      cmd: DinNovaPanelCommand.taskPluginException.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.getTaskPluginException(deviceToken: panel.token, eventID: operationInfoHolder.getExceptionPlugsMID ?? "", homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// 获取未闭合的门磁列表（ready to arm）
    func getUnclosePlugs(_ data: [String: Any]) {
        guard let task = data["task"] as? String else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_GET_UNCLOSEPLUGS)
            return
        }
        operationInfoHolder.getUnclosePlugsMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.getUnclosePlugsMID ?? "",
                                      cmd: DinNovaPanelCommand.getUnClosedSensor.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.getUnClosedSensor(deviceToken: panel.token,
                                                                     eventID: operationInfoHolder.getUnclosePlugsMID ?? "",
                                                                     task: task, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }


    /// 添加主机配件
    func addPlugin(_ infoDict: [String: Any]) {
        guard let cmd = infoDict["cmd"] as? String, cmd == DinNovaPanelControl.CMD_PLUGIN_ADD,
              let isASK = infoDict["isASK"] as? Bool else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_PLUGIN_ADD)
            return
        }
        if isASK {
            guard let askPluginInfo = infoDict["askPluginInfo"] as? [String: Any] else {
                acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_PLUGIN_ADD)
                return
            }
            operationInfoHolder.addPlugsMID = String.UUID()
            let event = DinNovaPanelEvent(id: operationInfoHolder.addPlugsMID ?? "",
                                          cmd: DinNovaPanelCommand.addASKPlugin.rawValue,
                                          type: DinNovaPanelEventType.setting.rawValue)
            operationTimeoutChecker.enter(event)

            let askPluginString = DinDataConvertor.convertToString(askPluginInfo)
            let request = DinNovaPanelOperationRequest.addASKPlugin(deviceToken: panel.token,
                                                                    eventID: operationInfoHolder.addPlugsMID ?? "",
                                                                    plugin: askPluginString ?? "", homeID: homeID)
            DinHttpProvider.request(request, success: nil, fail: nil)
        } else {
            guard let deviceInfoDict = infoDict["pluginInfo"] as? [String: Any],
                  let pluginID = deviceInfoDict["pluginID"] as? String,
                  let pluginName = deviceInfoDict["pluginName"] as? String,
                  let category = deviceInfoDict["category"] as? Int,
                  let subCategory = deviceInfoDict["subCategory"] as? String else {
                acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_PLUGIN_ADD)
                return
            }
            let decodeID = deviceInfoDict["decodeID"] as? String ?? ""
            let ipcData = deviceInfoDict["ipcData"] as? String ?? ""
            let sirenSetting = deviceInfoDict["sirenSetting"] as? String ?? ""
            operationInfoHolder.addPlugsMID = String.UUID()
            let event = DinNovaPanelEvent(id: operationInfoHolder.addPlugsMID ?? "",
                                          cmd: DinNovaPanelCommand.addPlugin.rawValue,
                                          type: DinNovaPanelEventType.setting.rawValue)
            operationTimeoutChecker.enter(event)

            let request = DinNovaPanelOperationRequest.addPlugin(deviceToken: panel.token,
                                                                 eventID: operationInfoHolder.addPlugsMID ?? "",
                                                                 pluginID: pluginID,
                                                                 forDecodeID: decodeID,
                                                                 pluginName: pluginName,
                                                                 category: category,
                                                                 subCategory: subCategory,
                                                                 ipcData: ipcData,
                                                                 sirenSetting: sirenSetting, homeID: homeID)
            DinHttpProvider.request(request, success: nil, fail: nil)
        }
    }

    /// 删除主机配件
    func deletePlugin(_ data: [String: Any]) {
        let pluginID = data["pluginID"] as? String ?? ""
        let category = data["category"] as? Int ?? 0
        let subCategory = data["subCategory"] as? String ?? ""
        let sendid = data["sendid"] as? String ?? ""

        let isASK = subCategory.count > 0 && sendid.count > 0

        guard (pluginID.count > 0 || isASK) else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_PLUGIN_DELETE)
            return
        }

        if isASK {
            operationInfoHolder.deletePlugsMID = String.UUID()
            let event = DinNovaPanelEvent(id: operationInfoHolder.deletePlugsMID ?? "",
                                          cmd: DinNovaPanelCommand.deleteASKPLugin.rawValue,
                                          type: DinNovaPanelEventType.setting.rawValue)
            operationTimeoutChecker.enter(event)

            let request = DinNovaPanelOperationRequest.deleteASKPlugin(deviceToken: panel.token,
                                                                        eventID: operationInfoHolder.deletePlugsMID ?? "",
                                                                        data: ["stype": subCategory, "sendid": sendid], homeID: homeID)
            DinHttpProvider.request(request, success: nil, fail: nil)
        } else {
            operationInfoHolder.deletePlugsMID = String.UUID()
            let event = DinNovaPanelEvent(id: operationInfoHolder.deletePlugsMID ?? "",
                                          cmd: DinNovaPanelCommand.deletePlugin.rawValue,
                                          type: DinNovaPanelEventType.setting.rawValue)
            operationTimeoutChecker.enter(event)

            let request = DinNovaPanelOperationRequest.deletePlugin(deviceToken:panel.token,
                                                                     eventID: operationInfoHolder.deletePlugsMID ?? "",
                                                                     pluginID: pluginID,
                                                                     category: category, homeID: homeID)
            DinHttpProvider.request(request, success: nil, fail: nil)
        }
    }

    /// 获取配件列表中配件状态
    func getPlugsStatus(_ data: [String: Any]) {
        guard let subCategorys = data["subCategorys"] as? String else {
            acceptLackOfParamsFail(withCMD: DinNovaPanelControl.CMD_GET_PLUGSSTATUS)
            return
        }
        operationInfoHolder.getPlugsStatusMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.getPlugsStatusMID ?? "",
                                      cmd: DinNovaPanelCommand.pluginPowerValueChanged.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.getPluginStatus(deviceToken: panel.token,
                                                                   eventID: operationInfoHolder.getPlugsStatusMID ?? "",
                                                                   stypes: subCategorys, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    /// [触发配对]激活主机接收配件信号功能
    func activeLearnMode() {
        operationInfoHolder.activeLearnModeMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.activeLearnModeMID ?? "",
                                      cmd: DinNovaPanelCommand.learnModeOps.rawValue,
                                      type: DinNovaPanelEventType.action.rawValue)
        operationTimeoutChecker.enter(event)

        learnModeCommunicator?.connect(toIp: panel.lanIP)
    }

    /// [触发配对]关闭主机接收配件信号功能
    func deactiveLearnMode() {
        operationInfoHolder.deactiveLearnModeMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.deactiveLearnModeMID ?? "",
                                      cmd: DinNovaPanelCommand.learnModeOps.rawValue,
                                      type: DinNovaPanelEventType.action.rawValue)
        operationTimeoutChecker.enter(event)

        learnModeCommunicator?.disconnnect()
    }

    /// [触发配对]开始监听配件信号
    func learnModeStartListen(_ data: [String: Any]) {
        let isOfficial = data["isOfficial"] as? Bool ?? true

        operationInfoHolder.learnModeStartListenMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.learnModeStartListenMID ?? "",
                                      cmd: DinNovaPanelCommand.learnModeOps.rawValue,
                                      type: DinNovaPanelEventType.action.rawValue)
        operationTimeoutChecker.enter(event)

        learnModeCommunicator?.startListen(toOfficial: isOfficial)
    }
    
    func enableZTAuth(_ data: [String: Any]) {
        let userId = data["userid"] as? String ?? ""
        operationInfoHolder.enableZTAuthMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.enableZTAuthMID ?? "",
                                      cmd: DinNovaPanelCommand.enableZTAuth.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPanelOperationRequest.enableZTAuth(deviceToken: panel.token, homeID: homeID, eventID: operationInfoHolder.enableZTAuthMID ?? "")
            DinHttpProvider.request(request, success: nil, fail: nil)
    }
}
