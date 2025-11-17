//
//  DinNovaSmartButtonControl+Operation.swift
//  DinCore
//
//  Created by Jin on 2021/6/4.
//

import Foundation

extension DinNovaSmartButtonControl {
    func getConfig(_ data: [String: Any]) {
        let request = DinNovaPluginRequest.getSmartBtnConfig(deviceID: panelOperator.id,
                                                             sendID: (plugin as? DinNovaSmartButton)?.sendid ?? "",
                                                             stype: plugin.subCategory, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            let returnDict = self?.makeHTTPSuccessInfo(withCMD: DinNovaPluginControl.CMD_SMARTBUTTON_CONFIG,
                                                       result: result ?? [:]) ?? [:]
            self?.accept(deviceOperationResult: returnDict)
        } fail: { [weak self] error in
            let returnDict = self?.makeHTTPFailureInfo(withCMD: DinNovaPluginControl.CMD_SMARTBUTTON_CONFIG,
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
                                                                       sendID: (plugin as? DinNovaSmartButton)?.sendid ?? "",
                                                                       datas: [["action": data, "action_conf": [:]]],
                                                                       stype: plugin.subCategory, homeID: homeID)
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
                                                                       sendID: (plugin as? DinNovaSmartButton)?.sendid ?? "",
                                                                       datas: datas,
                                                                       stype: plugin.subCategory, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }
}
