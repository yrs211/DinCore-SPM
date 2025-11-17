//
//  DinNovaPluginControl+Operation.swift
//  DinCore
//
//  Created by Jin on 2021/5/29.
//

import Foundation
import DinSupport

extension DinNovaPluginControl {
    /// 设置配件名字
    static let CMD_SET_NAME = "plugin_setname"
    /// 设置配件是否绕开监测
    static let CMD_CONFIGBLOCK = "plugin_configblock"
    /// 设置门磁推送
    static let CMD_SET_DOOR_WINDOW_PUSH_STATUS = "set_door_window_push_status"
    /// 门磁开合状态变化推送
    static let CMD_DOOR_WINDOW_SENSOR_STATUS_CHANGED = "set_door_window_sensor_status_changed"
    /// 设置配件是否绕开监测
    static let CMD_ADD = "plugin_add"
    /// 删除配件
    static let CMD_DELETE = "plugin_delete"
    /// 打开开关
    static let CMD_ENABLE_PLUG = "plugin_enable"
    /// 获取配件详细信息
    static let CMD_PLUG_DETAIL = "plugin_detailinfo"
    /// 获取配件自定义详细信息
    static let CMD_SMARTBUTTON_CONFIG = "plugin_smartbutton_config"
    /// 删除配件自定义详细信息
    static let CMD_PLUG_DELETEBINDCONFIG = "plugin_delete_bindconfig"
    /// 更新配件自定义详细信息
    static let CMD_PLUG_UPDATEBINDCONFIG = "plugin_update_bindconfig"
    /// 测试警笛
    static let CMD_TESTSIREN = "plugin_testsiren"
    /// 设置警笛
    static let CMD_SETSIREN = "plugin_setsiren"
    /// 操作继电器
    static let CMD_RELAY_ACTION = "plugin_action"
    /// 临时屏蔽红外触发
    static let CMD_BYPASS_PLUGIN_5_MIN = "bypass_plugin_5_min"
    /// 通知红外已经进入配置模式
    static let CMD_PIR_SETTING_ENABLED = "pir_setting_enabled"
    /// 设置红外灵敏度设置模式
    static let CMD_SET_SENSITIVITY = "set_sensitivity"
    /// 退出红外设置模式
    static let CMD_EXIT_PIR_SETTING_MODE = "exit_pir_setting_mode"
}

// 操作
extension DinNovaPluginControl {
    func acceptLackOfParamsFail(withCMD cmd: String) {
        let returnDict = makeResultFailureInfo(withCMD: cmd,
                                               owner: true,
                                               errorMessage: "invoke api without parameters",
                                               result: [:])
        accept(deviceOperationResult: returnDict)
    }

    func acceptPluginUnsupportedFail(withCMD cmd: String) {
        let returnDict = makeResultFailureInfo(withCMD: cmd,
                                               owner: true,
                                               errorMessage: "Plugin unsupported",
                                               result: [:])
        accept(deviceOperationResult: returnDict)
    }

    func setName(_ data: [String: Any]) {
        guard let name = data["name"] as? String else {
            acceptLackOfParamsFail(withCMD: DinNovaPluginControl.CMD_SET_NAME)
            return
        }
        operationInfoHolder.setNameMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.setNameMID ?? "",
                                      cmd: DinNovaPluginCommand.setASKPlugin.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        if plugin.checkIsASKPlugin() {
            var sendid = ""
            if let selfPlugin = plugin as? DinNovaSmartPlug {
                sendid = selfPlugin.sendid
            } else if let selfPlugin = plugin as? DinNovaDoorWindowSensor {
                sendid = selfPlugin.sendid
            } else if let selfPlugin = plugin as? DinNovaSmartButton {
                sendid = selfPlugin.sendid
            } else if let selfPlugin = plugin as? DinNovaSiren {
                sendid = selfPlugin.sendid
            } else if let selfPlugin = plugin as? DinNovaRemoteControl {
                sendid = selfPlugin.sendid
            } else if let selfPlugin = plugin as? DinNovaRelay {
                sendid = selfPlugin.sendid
            } else if let selfPlugin = plugin as? DinNovaSecurityAccessory {
                sendid = selfPlugin.sendid
            } else if let selfPlugin = plugin as? DinNovaKeypad {
                sendid = selfPlugin.sendid
            }
            let newASKInfo = ["stype": plugin.subCategory,
                              "sendid": sendid,
                              "name": name]
            let request = DinNovaPluginOperationRequest.setASKPlugin(deviceToken: panelOperator.panelControl.panel.token,
                                                                     eventID: operationInfoHolder.setNameMID ?? "",
                                                                     data: newASKInfo, homeID: homeID)
            DinHttpProvider.request(request, success: nil, fail: nil)
        } else {
            let request = DinNovaPluginOperationRequest.modifyPlugin(deviceToken: panelOperator.panelControl.panel.token,
                                                                     eventID: operationInfoHolder.setNameMID ?? "",
                                                                     pluginID: plugin.id,
                                                                     pluginName: name,
                                                                     category: plugin.category, homeID: homeID)
            DinHttpProvider.request(request, success: nil, fail: nil)
        }
    }

    func addPlugin(_ data: [String: Any]) {
        //
    }

    func deletePlugin(_ data: [String: Any]) {
        panelOperator.panelControl.deletePlugin(data)
//        let pluginID = data["pluginID"] as? String ?? ""
//        let category = data["category"] as? Int ?? 0
//        let subCategory = data["subCategory"] as? String ?? ""
//        let sendid = data["sendid"] as? String ?? ""
//
//        let isASK = subCategory.count > 0 && sendid.count > 0
//
//        guard (pluginID.count > 0 || isASK) else {
//            acceptLackOfParamsFail(withCMD: DinNovaPluginControl.CMD_DELETE)
//            return
//        }
//        operationInfoHolder.deletPluginMID = String.UUID()
//        let event = DinNovaPanelEvent(id: operationInfoHolder.deletPluginMID ?? "",
//                                      cmd: DinNovaPluginCommand.deleteASKPLugin.rawValue,
//                                      type: DinNovaPanelEventType.setting.rawValue)
//        operationTimeoutChecker.enter(event)
//
//        if isASK {
//            let request = DinNovaPluginOperationRequest.deleteASKPlugin(deviceToken: panelOperator.panelControl.panel.token,
//                                                                        eventID: operationInfoHolder.deletPluginMID ?? "",
//                                                                        data: ["stype": subCategory, "sendid": sendid], homeID: homeID)
//            DinHttpProvider.request(request, success: nil, fail: nil)
//        } else {
//            let request = DinNovaPluginOperationRequest.deletePlugin(deviceToken: panelOperator.panelControl.panel.token,
//                                                                     eventID: operationInfoHolder.deletPluginMID ?? "",
//                                                                     pluginID: pluginID,
//                                                                     category: category, homeID: homeID)
//            DinHttpProvider.request(request, success: nil, fail: nil)
//        }
    }
}
