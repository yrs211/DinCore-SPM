//
//  DinNovaPanelOperator+ResponseHandler.swift
//  DinCore
//
//  Created by Jin on 2021/5/15.
//

import Foundation

extension DinNovaPanelOperator {
    func handlePanelControl(returnData returnDict: [String: Any]) {
        // 检查有没有cmd
        guard let cmd = returnDict["cmd"] as? String, cmd.count > 0 else {
            return
        }
        switch cmd {
        case DinNovaPanelControl.CMD_OFFLINE:
            accept(deviceOnlineState: panelControl.panel.online)
            accept(deviceOperationResult: returnDict)
        default:
            accept(deviceOperationResult: returnDict)
        }
    }
}
