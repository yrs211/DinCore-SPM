//
//  DinNovaSmartPlugControl+Operation.swift
//  DinCore
//
//  Created by Jin on 2021/6/2.
//

import Foundation

extension DinNovaSmartPlugControl {
    func setEnable(_ data: [String: Any]) {
        guard let enable = data["enable"] as? Bool, let isAsk = data["isAsk"] as? Bool else {
            acceptLackOfParamsFail(withCMD: DinNovaPluginControl.CMD_ENABLE_PLUG)
            return
        }

        operationInfoHolder.enablePluginMID = String.UUID()
        if isAsk {
            let sendid = data["sendid"] as? String ?? ""
            let subCategory = data["subCategory"] as? String ?? ""

            let event = DinNovaPanelEvent(id: operationInfoHolder.enablePluginMID ?? "",
                                          cmd: DinNovaPluginCommand.setNewSmartPlugEnable.rawValue,
                                          type: DinNovaPanelEventType.action.rawValue)
            operationTimeoutChecker.enter(event)

            if panelOperator.panelControl.lanCommunicator?.isCOAPAvailable ?? false {
                let makeCoapSucceed = panelOperator.panelControl.lanCommunicator?.sendSetSmartPlugEnableOperationSuccess(withMessageID: event.id, pluginID: plugin.id, enable: enable, sendID: sendid, stype: subCategory) ?? false
                if !makeCoapSucceed {
                    let request = DinNovaPluginOperationRequest.setNewSmartPlugEnable(deviceToken: panelOperator.panelControl.panel.token,
                                                                                      eventID: operationInfoHolder.enablePluginMID ?? "",
                                                                                      pluginID: plugin.id,
                                                                                      enable: enable,
                                                                                      sendID: sendid,
                                                                                      stype: subCategory, homeID: homeID)
                    DinHttpProvider.request(request, success: nil, fail: nil)
                }
            } else {

                let request = DinNovaPluginOperationRequest.setNewSmartPlugEnable(deviceToken: panelOperator.panelControl.panel.token,
                                                                                  eventID: operationInfoHolder.enablePluginMID ?? "",
                                                                                  pluginID: plugin.id,
                                                                                  enable: enable,
                                                                                  sendID: sendid,
                                                                                  stype: subCategory, homeID: homeID)
                DinHttpProvider.request(request, success: nil, fail: nil)
            }
        } else {
            let event = DinNovaPanelEvent(id: operationInfoHolder.enablePluginMID ?? "",
                                          cmd: DinNovaPluginCommand.setSmartPlugEnable.rawValue,
                                          type: DinNovaPanelEventType.action.rawValue)
            operationTimeoutChecker.enter(event)

            if panelOperator.panelControl.lanCommunicator?.isCOAPAvailable ?? false {
                let makeCoapSucceed = panelOperator.panelControl.lanCommunicator?.sendSetSmartPlugEnableOperationSuccess(withMessageID: event.id,
                                                                                                                         pluginID: plugin.id,
                                                                                                                         enable: enable) ?? false
                if !makeCoapSucceed {
                    let request = DinNovaPluginOperationRequest.setSmartPlugEnable(deviceToken: panelOperator.panelControl.panel.token,
                                                                                   eventID: operationInfoHolder.enablePluginMID ?? "",
                                                                                   pluginID: plugin.id,
                                                                                   enable: enable, homeID: homeID)
                    DinHttpProvider.request(request, success: nil, fail: nil)
                }
            } else {
                let request = DinNovaPluginOperationRequest.setSmartPlugEnable(deviceToken: panelOperator.panelControl.panel.token,
                                                                               eventID: operationInfoHolder.enablePluginMID ?? "",
                                                                               pluginID: plugin.id,
                                                                               enable: enable, homeID: homeID)
                DinHttpProvider.request(request, success: nil, fail: nil)
            }
        }
    }

    func getDetail(_ data: [String: Any]) {
        let request = DinNovaPluginRequest.getPluginDetail(deviceID: panelOperator.id,
                                                           category: plugin.category,
                                                           stype: plugin.subCategory,
                                                           sendID: (plugin as? DinNovaSmartPlug)?.sendid ?? "",
                                                           pluginID: plugin.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            let returnDict = self?.makeHTTPSuccessInfo(withCMD: DinNovaPluginControl.CMD_PLUG_DETAIL,
                                                       result: result ?? [:]) ?? [:]
            self?.accept(deviceOperationResult: returnDict)
        } fail: { [weak self] error in
            let returnDict = self?.makeHTTPFailureInfo(withCMD: DinNovaPluginControl.CMD_PLUG_DETAIL,
                                                      errorMessage: error.localizedDescription,
                                                      result: [:]) ?? [:]
            self?.accept(deviceOperationResult: returnDict)
        }
    }
}
