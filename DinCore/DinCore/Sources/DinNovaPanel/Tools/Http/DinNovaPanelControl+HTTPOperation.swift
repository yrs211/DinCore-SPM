//
//  DinNovaPanelControl+HTTPOperation.swift
//  DinCore
//
//  Created by Jin on 2021/5/16.
//

import Foundation

// MARK: - http 的 CMD
extension DinNovaPanelControl {
    // 获取主机的Sim卡信息
    static let CMD_GET_PANEL_SIMINFO = "get_simcard_info"
    // 制作主机布撤防的短信内容
    static let CMD_RESTRICT_SMS_STRING = "restrict_sms_string"
    // 获取延时布防信息
    static let CMD_GET_EXITDELAY = "get_exitdelay"
    // 获取延时报警信息
    static let CMD_GET_ENTRYDELAY = "get_entrydelay"
    // 获取警笛鸣响时间
    static let CMD_GET_SIRENTIME = "get_sirentime"
    // 获取HomeArm数据
    static let CMD_GET_HOMEARMINFO = "get_homearm_info"
    // 获取胁迫报警设置
    static let CMD_GET_DURESSINFO = "get_duress_info"
    // 删除主机
    static let CMD_DELETE_PANEL = "delete_panel"
    // 解绑用户
    static let CMD_UNBIND_USER = "unbind_user"
    // 修改主机名字
    static let CMD_RENAME_PANEL = "rename_panel"
    // 验证主机密码
    static let CMD_PANEL_VERPWD = "verify_panel_password"
    // 获取主机指定时间开始的EventList
    static let CMD_PANEL_SPECIFYEVENTLIST = "get_panel_specifyeventlist"
    // 获取主机的QRCode
    static let CMD_PANEL_QRCODE = "get_panel_qrcode"
    // 获取主机的SOSinfo
    static let CMD_PANEL_SOSINFO = "get_panel_sosinfo"
    // 修改主机成员
    static let CMD_MODIFY_MEMBER = "modify_member"
    // 获取EmergencyContacts
    static let CMD_PANEL_EMERCONTACTS = "get_panel_emergencycontacts"
    // 修改EmergencyContacts
    static let CMD_MODIFY_EMERCONTACTS = "modify_emergencycontacts"
    // 添加EmergencyContacts
    static let CMD_ADD_EMERCONTACTS = "add_emergencycontacts"
    // 删除EmergencyContacts
    static let CMD_REMOVE_EMERCONTACTS = "remove_emergencycontacts"
    // 获取Message
    static let CMD_GET_MESSAGE = "get_panel_message"
    // 获取CID
    static let CMD_GET_CIDDATA = "get_panel_ciddata"
    // 获取时区配置
    static let CMD_GET_TIMEZONE = "get_timezone"
    // 获取ReadyToArm状态
    static let CMD_GET_RTASTATUS = "get_readytoarm_status"
    // 获取AdvancedSettings
    static let CMD_GET_ADVANCED = "get_advanced_setting"
    // 获取4G信息
    static let CMD_GET_4GINFO = "get_4g_info"
    // 获取CMS信息
    static let CMD_GET_CMSINFO = "get_cms_info"
    // 获取care mode守护模式配置数据
    static let CMD_GET_CAREMODE = "get_caremode"
    // 获取eventlist的设置
    static let CMD_GET_EVENTLIST_SETTING = "get_eventlist_setting"
    // 通知缓存的Plugin有变（通过请求服务器接口，对比发现得出的配件信息改变，不包含主动或者被动通知的增删查改）
    static let CMD_PLUGINS_CHANGED_AFTERLOAD = "panel_plugins_update"
    /// 添加配件
    static let CMD_PLUGIN_ADD = "plugin_add"
    /// 删除配件
    static let CMD_PLUGIN_DELETE = "plugin_delete"
    /// 批量删除配件
    static let CMD_PLUGINS_DELETE = "plugins_delete"
    /// 获取指定配件列表
    static let CMD_PLUGIN_LIST = "get_plugin_list"

    /// 获取主机防干扰的设置
    static let CMD_WIDGET_GET_ANTIINTERFERENCE_STATUS = "widget_get_anti_interference_status"

    /// 修改主机防干扰设置
    static let CMD_WIDGET_MODIFY_CONF_COVER = "widget_modify_conf_cover"

    /// 获取定时任务列表
    static let CMD_WIDGET_GET_TIMER_TASK_LIST = "widget_get_timer_task_list"

    /// 开/关定时任务
    static let CMD_WIDGET_TOGGLE_TIMER_TASK_ABILITY = "widget_toggle_timer_task_ability"

    /// 删除定时任务
    static let CMD_WIDGET_DELETE_TIMER_TASK = "widget_delete_timer_task"

    /// 创建定时任务
    static let CMD_WIDGET_CREATE_TIMER_TASK = "widget_create_timer_task"

    /// 更新定时任务
    static let CMD_WIDGET_UPDATE_TIMER_TASK = "widget_update_timer_task"

    /// 获取配置好规则智能跟随规则的配件
    static let CMD_WIDGET_GET_RULED_PLUGINS = "widget_get_ruled_plugins"
    
    /// 获取配件数量
    static let CMD_COUNT_PLUGIN = "count_plugin"
    
    /// 绑定主机家庭
    static let CMD_BIND_PANEL_HOME = "bind_panel_to_home"

    /// 请求主机固件升级
    static let CMD_REQUEST_PANEL_UPGRADE = "request_panel_upgrade"

    // [触发配对]开始监听配件信号
    static let CMD_LEARNMODE_ASKINFO = "get_learnmode_askinfo"
}

extension DinNovaPanelControl {
    /// 获取主机的Sim卡信息
    func getSimInfo() {
        let request = DinNovaPanelRequest.getSIMCardInfo(id: panel.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleGetSimInfo(result, error: nil)
        } fail: { [weak self] error in
            self?.handleGetSimInfo(nil, error: error)
        }
    }

    /// 制作主机布撤防的短信内容
    func getRestrictSMS(_ data: [String: Any]) {
        guard let operationCMD = data["operationCMD"] as? String,
              let phone = data["phoneNum"] as? String else {
            handleGetRestrictSMS(nil, phone: "", error: DinNetwork.Error.lackParams(""))
            return
        }
        handleGetRestrictSMS(["cmd": operationCMD,
                              "userid": DinCore.user?.name ?? "",
                              "gmtime": Int64(Date().timeIntervalSince1970*1000000000)],
                             phone: phone,
                             error: nil)
    }

    /// 获取延时布防信息
    func getExitDelay() {
        let request = DinNovaPanelRequest.getExitDelay(id: panel.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleExitDelayInfo(result, error: nil)
        } fail: { [weak self] error in
            self?.handleExitDelayInfo(nil, error: error)
        }
    }

    /// 获取延时报警信息
    func getEntryDelay() {
        let request = DinNovaPanelRequest.getEntryDelay(id: panel.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleEntryDelayInfo(result, error: nil)
        } fail: { [weak self] error in
            self?.handleEntryDelayInfo(nil, error: error)
        }
    }

    /// 获取警笛鸣响时间
    func getSirenTime() {
        let request = DinNovaPanelRequest.getSirenTime(id: panel.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleSirenTime(result, error: nil)
        } fail: { [weak self] error in
            self?.handleSirenTime(nil, error: error)
        }
    }

    /// 获取HomeArm信息配置
    func getHomeArmInfo() {
        let request = DinNovaPanelRequest.getHomeArmInfo(id: panel.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleHomeArmInfo(result, error: nil)
        } fail: { [weak self] error in
            self?.handleHomeArmInfo(nil, error: error)
        }
    }

    /// 获取胁迫报警设置
    func getDuressInfo() {
        let request = DinNovaPanelRequest.getDuressAlarmSetting(id: panel.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleDuressInfo(result, error: nil)
        } fail: { [weak self] error in
            self?.handleDuressInfo(nil, error: error)
        }
    }

    /// 删除主机（退出主机）
    func delete() {
        let request = DinNovaPanelRequest.removeDevice(id: panel.id)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleDeletePanelResult(result, error: nil)
        } fail: { [weak self] error in
            self?.handleDeletePanelResult(nil, error: error)
        }
    }

    /// 解除用户和主机的关系
    func unbindUser(_ data: [String: Any]) {
        guard let userid = data["userid"] as? String else {
            handleUnbindUserResult(nil, error: DinNetwork.Error.lackParams(""))
            return 
        }
        let request = DinNovaPanelRequest.unbindUser(id: panel.id, uid: userid)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleUnbindUserResult(result, error: nil)
        } fail: { [weak self] error in
            self?.handleUnbindUserResult(nil, error: error)
        }
    }

    /// 主机改名
    func renamePanel(_ data: [String: Any]) {
        guard let name = data["name"] as? String else {
            handleRenamePanelResult(nil, error: DinNetwork.Error.lackParams(""))
            return
        }
        let request = DinNovaPanelRequest.renameDevice(id: panel.id, name: name, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleRenamePanelResult(result, error: nil)
        } fail: { [weak self] error in
            self?.handleRenamePanelResult(nil, error: error)
        }
    }

    /// 验证主机密码
    func verifyPanelPassword(_ data: [String: Any]) {
        guard let password = data["password"] as? String else {
            handleVerifyPasswordResult(nil, error: DinNetwork.Error.lackParams(""))
            return
        }
        let request = DinNovaPanelRequest.verifyPassword(id: panel.id, pwd: password)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleVerifyPasswordResult(result, error: nil)
        } fail: { [weak self] error in
            self?.handleVerifyPasswordResult(nil, error: error)
        }
    }

    /// 获取指定时间的EventList
    func getSpecifyEventList(_ data: [String: Any]) {
        guard let timestamp = data["timestamp"] as? Int64 else {
            handleSpecifyEventListResult(nil, error: DinNetwork.Error.lackParams(""))
            return
        }
        let request = DinNovaPanelRequest.getEvents(id: panel.id, timestamp: timestamp, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleSpecifyEventListResult(result, error: nil)
        } fail: { [weak self] error in
            self?.handleSpecifyEventListResult(nil, error: error)
        }
    }

    /// 获取主机QRCode
    func getQRCode(_ data: [String: Any]) {
        guard let role = data["role"] as? Int else {
            handleQRCode(nil, error: DinNetwork.Error.lackParams(""))
            return
        }
        let request = DinNovaPanelRequest.getDeviceQRCode(id: panel.id, role: role)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleQRCode(result, error: nil)
        } fail: { [weak self] error in
            self?.handleQRCode(nil, error: error)
        }
    }

    /// 获取主机的SOS信息
    func getSOSInfo() {
        let request = DinNovaPanelRequest.getSOSInfo(id: panel.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleSOSInfo(result, error: nil)
        } fail: { [weak self] error in
            self?.handleSOSInfo(nil, error: error)
        }
    }

    /// 获取修改成员配置
    func modifyMember(_ data: [String: Any]) {
        guard let role = data["role"] as? Int,
              let uid = data["userid"] as? String,
              let push = data["push"] as? Bool,
              let sms = data["sms"] as? Bool,
              let pushSystem = data["pushSystem"] as? Bool,
              let pushStatus = data["pushStatus"] as? Bool,
              let pushAlarm = data["pushAlarm"] as? Bool,
              let smsSystem = data["smsSystem"] as? Bool,
              let smsStatus = data["smsStatus"] as? Bool,
              let smsAlarm = data["smsAlarm"] as? Bool else {
            handleModifyMemberResult(nil, error: DinNetwork.Error.lackParams(""))
            return
        }
        let request = DinNovaPanelRequest.modifyDeviceMember(id: panel.id,
                                                             uid: uid,
                                                             role: role,
                                                             push: push,
                                                             sms: sms,
                                                             pushSystem: pushSystem,
                                                             pushStatus: pushStatus,
                                                             pushAlarm: pushAlarm,
                                                             smsSystem: smsSystem,
                                                             smsStatus: smsStatus,
                                                             smsAlarm: smsAlarm)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleModifyMemberResult(result, error: nil)
        } fail: { [weak self] error in
            self?.handleModifyMemberResult(nil, error: error)
        }
    }

    /// 获取紧急联系人
    func getEmergencyContacts() {
        let request = DinNovaPanelRequest.getEmergencyContacts(id: panel.id)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleEmergencyContacts(result, error: nil)
        } fail: { [weak self] error in
            self?.handleEmergencyContacts(nil, error: error)
        }
    }

    /// 修改EmergencyContacts
    func modifyEmergencyContacts(_ data: [String: Any]) {
        guard let contactid = data["contactid"] as? String,
              let name = data["name"] as? String,
              let phone = data["phone"] as? String,
              let sms = data["sms"] as? Bool,
              let smsSystem = data["smsSystem"] as? Bool,
              let smsStatus = data["smsStatus"] as? Bool,
              let smsAlarm = data["smsAlarm"] as? Bool else {
            handleModifyEmergencyContacts(nil, error: DinNetwork.Error.lackParams(""))
            return
        }
        let request = DinNovaPanelRequest.modifyEmergencyContact(id: panel.id,
                                                                 uid: contactid,
                                                                 name: name,
                                                                 phone: phone,
                                                                 sms: sms,
                                                                 smsSystem: smsSystem,
                                                                 smsStatus: smsStatus,
                                                                 smsAlarm: smsAlarm)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleModifyEmergencyContacts(result, error: nil)
        } fail: { [weak self] error in
            self?.handleModifyEmergencyContacts(nil, error: error)
        }
    }

    /// 添加EmergencyContacts
    func addEmergencyContacts(_ data: [String: Any]) {
        guard let contacts = data["contacts"] as? String else {
            handleAddEmergencyContacts(nil, error: DinNetwork.Error.lackParams(""))
            return
        }
        let request = DinNovaPanelRequest.addEmergencyContacts(id: panel.id, contacts: contacts)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleAddEmergencyContacts(result, error: nil)
        } fail: { [weak self] error in
            self?.handleAddEmergencyContacts(nil, error: error)
        }
    }

    /// 删除EmergencyContacts
    func deleteEmergencyContacts(_ data: [String: Any]) {
        guard let uid = data["userid"] as? String else {
            handleRemoveEmergencyContacts(nil, error: DinNetwork.Error.lackParams(""))
            return
        }
        let request = DinNovaPanelRequest.removeEmergencyContact(id: panel.id, uid: uid)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleRemoveEmergencyContacts(result, error: nil)
        } fail: { [weak self] error in
            self?.handleRemoveEmergencyContacts(nil, error: error)
        }
    }

    /// 获取消息模板
    func getPanelMessage() {
        let request = DinNovaPanelRequest.getMessage(id: panel.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handlePanelMessageResult(result, error: nil)
        } fail: { [weak self] error in
            self?.handlePanelMessageResult(nil, error: error)
        }
    }

    /// 获取Cid Data
    func getPanelCIDData() {
        let request = DinNovaPanelRequest.getCID(id: panel.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handlePanelCIDData(result, error: nil)
        } fail: { [weak self] error in
            self?.handlePanelCIDData(nil, error: error)
        }
    }

    /// 获取Timezone配置
    func getPanelTimezone() {
        let request = DinNovaPanelRequest.getTimezoneSetting(id: panel.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handlePanelTimezoneSetting(result, error: nil)
        } fail: { [weak self] error in
            self?.handlePanelTimezoneSetting(nil, error: error)
        }
    }

    /// 获取ReadyToArm配置
    func getReadyToArmStatus() {
        let request = DinNovaPanelRequest.readyToArmStatus(id: panel.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleReadyToArmStatus(result, error: nil)
        } fail: { [weak self] error in
            self?.handleReadyToArmStatus(nil, error: error)
        }
    }

    /// 获取高级配置
    func getAdvancedSetting() {
        let request = DinNovaPanelRequest.getAdvancedSettings(id: panel.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleAdvancedSetting(result, error: nil)
        } fail: { [weak self] error in
            self?.handleAdvancedSetting(nil, error: error)
        }
    }

    /// 获取4G配置
    func get4GInfo() {
        let request = DinNovaPanelRequest.getSIM4GData(id: panel.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handle4GInfo(result, error: nil)
        } fail: { [weak self] error in
            self?.handle4GInfo(nil, error: error)
        }
    }

    /// 获取CMS配置
    func getCMSInfo() {
        let request = DinNovaPanelRequest.getCMSData(id: panel.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleCMSInfo(result, error: nil)
        } fail: { [weak self] error in
            self?.handleCMSInfo(nil, error: error)
        }
    }

    /// 获取care mode守护模式配置数据
    func getCareMode() {
        let request = DinNovaPanelRequest.getCareModeData(id: panel.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleCareModeData(result, error: nil)
        } fail: { [weak self] error in
            self?.handleCareModeData(nil, error: error)
        }
    }

    /// 获取eventlist的设置
    func getEventListSetting() {
        let request = DinNovaPanelRequest.getEventListSetting(id: panel.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleEventListSetting(result, error: nil)
        } fail: { [weak self] error in
            self?.handleEventListSetting(nil, error: error)
        }
    }

    /// 获取eventlist的设置
    func getPluginList(_ data: [String: Any]) {
        guard let category = data["category"] as? Int else {
            handlePluginListResult(nil, error: DinNetwork.Error.lackParams(""))
            return
        }
        let request = DinNovaPanelRequest.getAccessoryByType(id: panel.id, type: category, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handlePluginListResult(result, error: nil)
        } fail: { [weak self] error in
            self?.handlePluginListResult(nil, error: error)
        }
    }
    
    func countPlugins(_ data: [String: Any]) {
        guard let homeID = data["homeid"] as? String, let panelID = data["deviceid"] as? String else {
            handlePlugCountResult(nil, error: DinNetwork.Error.lackParams(""))
            return
        }
        let request = DinNovaPanelRequest.countPlugins(homeID: homeID, panelID: panelID)
        DinHttpProvider.request(request) {[weak self] result in
            self?.handlePlugCountResult(result, error: nil)
        } fail: {[weak self] error in
            self?.handlePlugCountResult(nil, error: error)
        }
    }
}

extension DinNovaPanelControl {

    func getAntiInterferenceStatus() {
        let parameter = DinNovaWidgetRequest.Parameter.GetAntiInterferenceStatus(
            deviceID: panel.id,
            addOnType: "ANTINTERER"
        )
        let request = DinNovaWidgetRequest.getAntiInterferenceStatus(parameter: parameter)
        DinHttpProvider.request(
            request,
            success: { [weak self] resultOrNil in
                self?.handleGetAntiInterferenceStatus(resultOrNil, error: nil)
            },
            fail: { [weak self] error in
                self?.handleGetAntiInterferenceStatus(nil, error: error)
            }
        )
    }

    func modifyAntiInterference(_ data: [String: Any]) {
        let parameter = DinNovaWidgetRequest.Parameter.ModifyConfCover(
            deviceID: panel.id,
            addOnType: "ANTINTERER",
            enable: data["enable"] as? Bool ?? false,
            message: data["message"] as? String ?? ""
        )

        let request = DinNovaWidgetRequest.modifyConfCover(parameter: parameter)
        DinHttpProvider.request(
            request,
            success: { [weak self] resultOrNil in
                self?.handleModifyConfCover(resultOrNil, error: nil)
            },
            fail: { [weak self] error in
                self?.handleModifyConfCover(nil, error: error)
            }
        )
    }

    func getTimerTaskList() {
        let parameter = DinNovaWidgetRequest.Parameter.ListTimerConf(deviceID: panel.id)
        let request = DinNovaWidgetRequest.listTimerConf(parameter: parameter)
        DinHttpProvider.request(
            request,
            success: { [weak self] resultOrNil in
                self?.handleGetTimerTaskList(resultOrNil, error: nil)
            },
            fail: { [weak self] error in
                self?.handleGetTimerTaskList(nil, error: error)
            }
        )
    }

    func toggleTimerTaskAbility(_ data: [String: Any]) {
        let parameter = DinNovaWidgetRequest.Parameter.ModifyConf(
            deviceID: panel.id,
            addOnType: "TIMER",
            addOnID: data["addOnID"] as? String ?? "",
            type: nil,
            conf: data["conf"] as? String ?? ""
        )
        let request = DinNovaWidgetRequest.modifyConf(parameter: parameter)
        DinHttpProvider.request(
            request,
            success: { [weak self] resultOrNil in
                self?.handleToggleTimerTaskAbility(resultOrNil, error: nil)
            },
            fail: { [weak self] error in
                self?.handleToggleTimerTaskAbility(nil, error: error)
            }
        )
    }

    func deleteTimerTask(_ data: [String: Any]) {
        let parameter = DinNovaWidgetRequest.Parameter.DeleteConf(
            deviceID: panel.id,
            addOnType: "TIMER",
            addOnID: data["addOnID"] as? String ?? ""
        )
        let request = DinNovaWidgetRequest.deleteConf(parameter: parameter)
        DinHttpProvider.request(
            request,
            success: { [weak self] resultOrNil in
                self?.handleDeleteTimerTask(data, error: nil)
            },
            fail: { [weak self] error in
                self?.handleDeleteTimerTask(nil, error: error)
            }
        )
    }

    func createTimerTask(_ data: [String: Any]) {
        let paramter = DinNovaWidgetRequest.Parameter.ModifyConf(
            deviceID: panel.id,
            addOnType: "TIMER",
            addOnID: nil,
            type: nil,
            conf: data["conf"] as? String ?? ""
        )
        let request = DinNovaWidgetRequest.modifyConf(parameter: paramter)

        DinHttpProvider.request(
            request,
            success: { [weak self] resultOrNil in
                self?.handleCreateTimerTask(resultOrNil, error: nil)
            },
            fail: { [weak self] error in
                self?.handleCreateTimerTask(nil, error: error)
            }
        )
    }

    func updateTimerTask(_ data: [String: Any]) {
        let paramter = DinNovaWidgetRequest.Parameter.ModifyConf(
            deviceID: panel.id,
            addOnType: "TIMER",
            addOnID: data["addOnID"] as? String ?? "",
            type: nil,
            conf: data["conf"] as? String ?? ""
        )
        let request = DinNovaWidgetRequest.modifyConf(parameter: paramter)

        DinHttpProvider.request(
            request,
            success: { [weak self] resultOrNil in
                self?.handleUpdateTimerTask(resultOrNil, error: nil)
            },
            fail: { [weak self] error in
                self?.handleUpdateTimerTask(nil, error: error)
            }
        )
    }

    func getPluginsWithRuledTask(_ data: [String: Any]) {
        let parameter = DinNovaWidgetRequest.Parameter.ListAddOnConf(
            deviceID: panel.id,
            addOnType: "SMARTFOLLOWING"
        )
        let request = DinNovaWidgetRequest.listAddonConf(parameter: parameter)
        DinHttpProvider.request(
            request,
            success: { [weak self] resultOrNil in
                self?.handleGetPluginsWithRuledTask(resultOrNil, error: nil)
            },
            fail: { [weak self] error in
                self?.handleGetPluginsWithRuledTask(nil, error: error)
            }
        )
    }

    /// [触发配对]获取ask配件信息
    func getLearnModeAskInfo(_ data: [String: Any]) {
        guard let sendid = data["sendid"] as? String, let stype = data["stype"] as? String else {
            handleLearnModeAskInfoResult(nil, error: DinNetwork.Error.lackParams(""))
            return
        }
        let request = DinRequest.getNewASKInfo(panelId: panel.id, stype: stype, sendid: sendid, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleLearnModeAskInfoResult(result, error: nil)
        } fail: { [weak self] error in
            self?.handleLearnModeAskInfoResult(nil, error: error)
        }
    }

    func requestPanelUpgrade(_ data: [String: Any]) {
        guard
            let token = data["device_token"] as? String, !token.isEmpty,
            let userID = data["user_id"] as? String, !userID.isEmpty,
            let messageID = data["message_id"] as? String, !messageID.isEmpty
        else { return }

        let request = DinNovaPanelOperationRequest.requestPanelUpgrade(
            deviceToken: token,
            homeID: homeID,
            userID: userID,
            messageID: messageID
        )
        DinHttpProvider.request(
            request,
            success: nil,
            fail: nil
        )
    }
}
