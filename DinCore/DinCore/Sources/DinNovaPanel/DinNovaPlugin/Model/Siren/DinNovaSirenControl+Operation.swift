//
//  DinNovaSirenControl+Operation.swift
//  DinCore
//
//  Created by Jin on 2021/6/6.
//

import Foundation

extension DinNovaSirenControl {
    func testSiren(_ data: [String: Any]) {
        let volume = data["volume"] as? Int
        let music = data["music"] as? Int

        operationInfoHolder.testSirenMID = String.UUID()

        let event = DinNovaPanelEvent(id: operationInfoHolder.testSirenMID ?? "",
                                      cmd: DinNovaPluginCommand.testSiren.rawValue,
                                      type: DinNovaPanelEventType.setting.rawValue)
        operationTimeoutChecker.enter(event)

        let request = DinNovaPluginOperationRequest.testSiren(deviceToken: panelOperator.panelControl.panel.token,
                                                              eventID: operationInfoHolder.testSirenMID ?? "",
                                                              sendID: (plugin as? DinNovaSiren)?.sendid ?? "",
                                                              stype: plugin.subCategory,
                                                              volume: volume,
                                                              music: music, homeID: homeID)
        DinHttpProvider.request(request, success: nil, fail: nil)
    }

    func setSiren(_ data: [String: Any]) {
        guard let sirenSetting = data["sirenSetting"] as? String else {
            acceptLackOfParamsFail(withCMD: DinNovaPluginControl.CMD_SETSIREN)
            return
        }

        if plugin.checkIsASKPlugin() {
            operationInfoHolder.setASKSirenMID = String.UUID()

            let event = DinNovaPanelEvent(id: operationInfoHolder.setASKSirenMID ?? "",
                                          cmd: DinNovaPluginCommand.setNewSiren.rawValue,
                                          type: DinNovaPanelEventType.setting.rawValue)
            operationTimeoutChecker.enter(event)

            let request = DinNovaPluginOperationRequest.setNewSiren(deviceToken: panelOperator.panelControl.panel.token,
                                                                    eventID: operationInfoHolder.setASKSirenMID ?? "",
                                                                    sendID: (plugin as? DinNovaSiren)?.sendid ?? "",
                                                                    type: plugin.subCategory,
                                                                    settings: sirenSetting, homeID: homeID)
            DinHttpProvider.request(request, success: nil, fail: nil)
        } else {
            operationInfoHolder.setSirenMID = String.UUID()

            let event = DinNovaPanelEvent(id: operationInfoHolder.setSirenMID ?? "",
                                          cmd: DinNovaPluginCommand.setSiren.rawValue,
                                          type: DinNovaPanelEventType.setting.rawValue)
            operationTimeoutChecker.enter(event)

            let request = DinNovaPluginOperationRequest.setSiren(deviceToken: panelOperator.panelControl.panel.token,
                                                                 eventID: operationInfoHolder.setSirenMID ?? "",
                                                                 sirenID: plugin.id, setting: sirenSetting)
            DinHttpProvider.request(request, success: nil, fail: nil)
        }
    }
//
//    func deleteConfig(_ data: [String: Any]) {
//        guard let data = data["data"] as? String else {
//            acceptLackOfParamsFail(withCMD: DinNovaPluginControl.CMD_SMARTBUTTON_DELETECONFIG)
//            return
//        }
//
//        operationInfoHolder.deleteSmartButtonConfigMID = String.UUID()
//
//        let event = DinNovaPanelEvent(id: operationInfoHolder.deleteSmartButtonConfigMID ?? "",
//                                      cmd: DinNovaPluginCommand.updatePluginConfig.rawValue,
//                                      type: DinNovaPanelEventType.setting.rawValue)
//        operationTimeoutChecker.enter(event)
//
//        let request = DinNovaPluginOperationRequest.updatePluginConfig(deviceToken: panelOperator.panelControl.panel.token,
//                                                                       eventID: operationInfoHolder.deleteSmartButtonConfigMID ?? "",
//                                                                       sendID: (plugin as? DinNovaSmartButton)?.sendid ?? "",
//                                                                       datas: [["action": data, "action_conf": [:]]],
//                                                                       stype: plugin.subCategory)
//        DinHttpProvider.request(request, success: nil, fail: nil)
//    }
//
//    func setConfig(_ data: [String: Any]) {
//        guard let datas = data["datas"] as? [[String: Any]] else {
//            acceptLackOfParamsFail(withCMD: DinNovaPluginControl.CMD_SMARTBUTTON_UPDATECONFIG)
//            return
//        }
//
//        operationInfoHolder.updateSmartButtonConfigMID = String.UUID()
//
//        let event = DinNovaPanelEvent(id: operationInfoHolder.updateSmartButtonConfigMID ?? "",
//                                      cmd: DinNovaPluginCommand.updatePluginConfig.rawValue,
//                                      type: DinNovaPanelEventType.setting.rawValue)
//        operationTimeoutChecker.enter(event)
//
//        let request = DinNovaPluginOperationRequest.updatePluginConfig(deviceToken: panelOperator.panelControl.panel.token,
//                                                                       eventID: operationInfoHolder.updateSmartButtonConfigMID ?? "",
//                                                                       sendID: (plugin as? DinNovaSmartButton)?.sendid ?? "",
//                                                                       datas: datas,
//                                                                       stype: plugin.subCategory)
//        DinHttpProvider.request(request, success: nil, fail: nil)
//    }
}
