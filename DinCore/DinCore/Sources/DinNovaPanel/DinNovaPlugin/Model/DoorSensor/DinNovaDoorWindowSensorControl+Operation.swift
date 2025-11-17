//
//  DinNovaDoorWindowSensorControl+Operation.swift
//  DinCore
//
//  Created by Jin on 2021/5/31.
//

import Foundation
import DinSupport

// MARK: - operator
extension DinNovaDoorWindowSensorControl {
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
                                             "sendid": (plugin as? DinNovaDoorWindowSensor)?.sendid ?? "",
                                             "stype": plugin.subCategory]
            let request = DinNovaPluginOperationRequest.setPluginBlock(deviceToken: panelOperator.panelControl.panel.token,
                                                                       eventID: operationInfoHolder.configBlockMID ?? "",
                                                                       data: newASKInfo,
                                                                       block: block, homeID: DinCore.user?.curHome?.id ?? "")
            DinHttpProvider.request(request, success: nil, fail: nil)
        } else {

        }
    }

    func configDoorWindowPushStatus(_ data: [String: Any]) {
        guard let pushStatus = data["push_status"] as? Bool else {
            acceptLackOfParamsFail(withCMD: DinNovaPluginControl.CMD_SET_DOOR_WINDOW_PUSH_STATUS)
            return
        }
        let eventID = String.UUID()
        operationInfoHolder.setDoorWindowPushStatusMID = eventID
        let event = DinNovaPanelEvent(
            id: operationInfoHolder.setDoorWindowPushStatusMID ?? "",
            cmd: DinNovaPluginCommand.setDoorWindowPushStatus.rawValue,
            type: DinNovaPanelEventType.setting.rawValue
        )
        operationTimeoutChecker.enter(event)

        if plugin.checkIsASKPlugin() &&
            DinAccessory.supportSettingDoorWindowPushStatusTypes.contains(plugin.subCategory) {
            let data: [String: Any] = [
                "plugin_id": plugin.id,
                "sendid": (plugin as? DinNovaDoorWindowSensor)?.sendid ?? "",
                "stype": plugin.subCategory,
            ]
            let request = DinNovaPluginOperationRequest.setDoorWindowPushStatus(
                deviceToken: panelOperator.panelControl.panel.token,
                eventID: eventID,
                data: data,
                pushStatus: pushStatus,
                homeID: DinCore.user?.curHome?.id ?? ""
            )
            DinHttpProvider.request(request, success: nil, fail: nil)
        } else {
            acceptPluginUnsupportedFail(withCMD: DinNovaPluginControl.CMD_SET_DOOR_WINDOW_PUSH_STATUS)
        }
    }

    func getDetail(_ data: [String: Any]) {
        let request = DinNovaPluginRequest.getPluginDetail(deviceID: panelOperator.id,
                                                           category: plugin.category,
                                                           stype: plugin.subCategory,
                                                           sendID: (plugin as? DinNovaDoorWindowSensor)?.sendid ?? "",
                                                           pluginID: plugin.id, homeID: DinCore.user?.curHome?.id ?? "")
        DinHttpProvider.request(request) { [weak self] result in
            self?.handleGetDetail(result)
        } fail: { [weak self] error in
            let returnDict = self?.makeHTTPFailureInfo(withCMD: DinNovaPluginControl.CMD_PLUG_DETAIL,
                                                      errorMessage: error.localizedDescription,
                                                      result: [:]) ?? [:]
            self?.accept(deviceOperationResult: returnDict)
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
                                                                       sendID: (plugin as? DinNovaDoorWindowSensor)?.sendid ?? "",
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
                                                                       sendID: (plugin as? DinNovaDoorWindowSensor)?.sendid ?? "",
                                                                       datas: datas,
                                                                       stype: plugin.subCategory, homeID: DinCore.user?.curHome?.id ?? "")
        DinHttpProvider.request(request, success: nil, fail: nil)
    }
}
