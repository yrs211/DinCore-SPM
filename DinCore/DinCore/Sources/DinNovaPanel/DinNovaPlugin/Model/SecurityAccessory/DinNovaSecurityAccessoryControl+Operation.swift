//
//  DinNovaSecurityAccessoryControl+Operation.swift
//  DinCore
//
//  Created by Jin on 2021/6/22.
//

import Foundation
import DinSupport

extension DinNovaSecurityAccessoryControl {
    func configBlock(_ data: [String: Any]) {
        guard let block = data["block"] as? Int else {
            acceptLackOfParamsFail(withCMD: DinNovaPluginControl.CMD_CONFIGBLOCK)
            return
        }
        operationInfoHolder.configBlockMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.configBlockMID ?? "",
                                      cmd: DinNovaPluginCommand.setPluginBlock.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        if plugin.checkIsASKPlugin() {
            let newASKInfo: [String: Any] = ["plugin_id": plugin.id,
                                             "sendid": (plugin as? DinNovaSecurityAccessory)?.sendid ?? "",
                                             "stype": plugin.subCategory]
            let request = DinNovaPluginOperationRequest.setPluginBlock(deviceToken: panelOperator.panelControl.panel.token,
                                                                       eventID: operationInfoHolder.configBlockMID ?? "",
                                                                       data: newASKInfo,
                                                                       block: block, homeID: DinCore.user?.curHome?.id ?? "")
            DinHttpProvider.request(request, success: nil, fail: nil)
        } else {

        }
    }

    func deleteConfig(_ data: [String: Any]) {
        guard let data = data["data"] as? String else {
            acceptLackOfParamsFail(withCMD: DinNovaPluginControl.CMD_PLUG_DELETEBINDCONFIG)
            return
        }

        operationInfoHolder.deletePlugBindConfigMID = String.UUID()

        let event = DinNovaPanelEvent(id: operationInfoHolder.deletePlugBindConfigMID ?? "",
                                      cmd: DinNovaPluginCommand.updatePluginConfig.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPluginOperationRequest.updatePluginConfig(deviceToken: panelOperator.panelControl.panel.token,
                                                                       eventID: operationInfoHolder.deletePlugBindConfigMID ?? "",
                                                                       sendID: (plugin as? DinNovaSecurityAccessory)?.sendid ?? "",
                                                                       datas: [["action": data, "action_conf": [:]]],
                                                                       stype: plugin.subCategory, homeID: DinCore.user?.curHome?.id ?? "")
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    func setConfig(_ data: [String: Any]) {
        guard let datas = data["datas"] as? [[String: Any]] else {
            acceptLackOfParamsFail(withCMD: DinNovaPluginControl.CMD_PLUG_UPDATEBINDCONFIG)
            return
        }

        operationInfoHolder.updatePlugBindConfigMID = String.UUID()

        let event = DinNovaPanelEvent(id: operationInfoHolder.updatePlugBindConfigMID ?? "",
                                      cmd: DinNovaPluginCommand.updatePluginConfig.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPluginOperationRequest.updatePluginConfig(deviceToken: panelOperator.panelControl.panel.token,
                                                                       eventID: operationInfoHolder.updatePlugBindConfigMID ?? "",
                                                                       sendID: (plugin as? DinNovaSecurityAccessory)?.sendid ?? "",
                                                                       datas: datas,
                                                                       stype: plugin.subCategory, homeID: DinCore.user?.curHome?.id ?? "")
        DinHttpProvider.request(request, success: nil, fail: nil)
    }
    
    func byPassPlugin5Min(_ data: [String: Any]) {
        operationInfoHolder.byPassPlugin5MinMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.byPassPlugin5MinMID ?? "",
                                      cmd: DinNovaPluginCommand.byPassPlugin5Min.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPluginOperationRequest.byPassPlugin5Min(deviceToken: panelOperator.panelControl.panel.token, homeID: DinCore.user?.curHome?.id ?? "", eventID: operationInfoHolder.byPassPlugin5MinMID ?? "", pluginID: plugin.id, sendID: (plugin as? DinNovaSecurityAccessory)?.sendid ?? "", stype: plugin.subCategory)
            DinHttpProvider.request(request, success: nil, fail: nil)
    }
    
    func setSensitivity(_ data: [String: Any]) {
        let sensitivity = data["sensitivity"] as? Int ?? 0
        operationInfoHolder.setSensitivityMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.setSensitivityMID ?? "",
                                      cmd: DinNovaPluginCommand.setSensitivity.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPluginOperationRequest.setSensitivity(deviceToken: panelOperator.panelControl.panel.token, homeID: DinCore.user?.curHome?.id ?? "", eventID: operationInfoHolder.setSensitivityMID ?? "", pluginID: plugin.id, sendID: (plugin as? DinNovaSecurityAccessory)?.sendid ?? "", sensitivity: sensitivity, stype: plugin.subCategory)
            DinHttpProvider.request(request, success: nil, fail: nil)
    }
    
    func exitPIRSettingMode(_ data: [String: Any]) {
        operationInfoHolder.exitPIRSettingModeMID = String.UUID()
        let event = DinNovaPanelEvent(id: operationInfoHolder.exitPIRSettingModeMID ?? "",
                                      cmd: DinNovaPluginCommand.exitPIRSettingMode.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPluginOperationRequest.exitPIRSettingMode(deviceToken: panelOperator.panelControl.panel.token, homeID: DinCore.user?.curHome?.id ?? "", eventID: operationInfoHolder.exitPIRSettingModeMID ?? "", pluginID: plugin.id, sendID: (plugin as? DinNovaSecurityAccessory)?.sendid ?? "", stype: plugin.subCategory)
            DinHttpProvider.request(request, success: nil, fail: nil)
    }
}
