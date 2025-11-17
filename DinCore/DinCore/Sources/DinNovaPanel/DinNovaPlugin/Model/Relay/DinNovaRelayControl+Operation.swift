//
//  DinNovaRelayControl+Operation.swift
//  DinCore
//
//  Created by Jin on 2021/6/22.
//

import Foundation

extension DinNovaRelayControl {
    func setRelayAction(_ data: [String: Any]) {
        guard let type = data["actionType"] as? String else {
            acceptLackOfParamsFail(withCMD: DinNovaPluginControl.CMD_RELAY_ACTION)
            return
        }

        var aciton = "00"
        if type == "backward" {
            aciton = "02"
        } else if type == "forward" {
            aciton = "01"
        }

        operationInfoHolder.relayActionMID = String.UUID()

        let sendid = (plugin as? DinNovaRelay)?.sendid ?? ""

        let event = DinNovaPanelEvent(id: operationInfoHolder.relayActionMID ?? "",
                                      cmd: DinNovaPluginCommand.setRelayAction.rawValue,
                                      type: DinNovaPanelEventType.action.rawValue)
        operationTimeoutChecker.enter(event)

        if panelOperator.panelControl.lanCommunicator?.isCOAPAvailable ?? false {
            let makeCoapSucceed = panelOperator.panelControl.lanCommunicator?.sendSetRelayOperationSuccess(withMessageID: event.id, action: aciton, sendid: sendid) ?? false
            if !makeCoapSucceed {
                let request = DinNovaPluginOperationRequest.setRelayAction(deviceToken: panelOperator.panelControl.panel.token, eventID: operationInfoHolder.relayActionMID ?? "", action: aciton, sendid: sendid, homeID: DinCore.user?.curHome?.id ?? "")
                DinHttpProvider.request(request, success: nil, fail: nil)
            }
        } else {
            let request = DinNovaPluginOperationRequest.setRelayAction(deviceToken: panelOperator.panelControl.panel.token, eventID: operationInfoHolder.relayActionMID ?? "", action: aciton, sendid: sendid, homeID: DinCore.user?.curHome?.id ?? "")
            DinHttpProvider.request(request, success: nil, fail: nil)
        }
    }
}
