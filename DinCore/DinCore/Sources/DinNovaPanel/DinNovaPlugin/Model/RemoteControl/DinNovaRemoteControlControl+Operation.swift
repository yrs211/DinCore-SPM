//
//  DinNovaRemoteControlControl+Operation.swift
//  DinCore
//
//  Created by Jin on 2021/6/7.
//

import Foundation

extension DinNovaRemoteControlControl {
    func setConfig(_ data: [String: Any]) {
        guard let datas = data["datas"] as? [[String: Any]] else {
            acceptLackOfParamsFail(withCMD: DinNovaPluginControl.CMD_PLUG_UPDATEBINDCONFIG)
            return
        }

        operationInfoHolder.updateRemoteControlConfigMID = String.UUID()

        let event = DinNovaPanelEvent(id: operationInfoHolder.updateRemoteControlConfigMID ?? "",
                                      cmd: DinNovaPluginCommand.updatePluginConfig.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPluginOperationRequest.updatePluginConfig(deviceToken: panelOperator.panelControl.panel.token,
                                                                       eventID: operationInfoHolder.updateRemoteControlConfigMID ?? "",
                                                                       sendID: (plugin as? DinNovaRemoteControl)?.sendid ?? "",
                                                                       datas: datas,
                                                                       stype: plugin.subCategory, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    func deleteConfig(_ data: [String: Any]) {
        guard let data = data["data"] as? String else {
            acceptLackOfParamsFail(withCMD: DinNovaPluginControl.CMD_PLUG_DELETEBINDCONFIG)
            return
        }

        operationInfoHolder.deleteRemoteControlConfigMID = String.UUID()

        let event = DinNovaPanelEvent(id: operationInfoHolder.deleteRemoteControlConfigMID ?? "",
                                      cmd: DinNovaPluginCommand.updatePluginConfig.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPluginOperationRequest.updatePluginConfig(deviceToken: panelOperator.panelControl.panel.token,
                                                                       eventID: operationInfoHolder.deleteRemoteControlConfigMID ?? "",
                                                                       sendID: (plugin as? DinNovaRemoteControl)?.sendid ?? "",
                                                                       datas: [["action": data, "action_conf": [:]]],
                                                                       stype: plugin.subCategory, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }
}
