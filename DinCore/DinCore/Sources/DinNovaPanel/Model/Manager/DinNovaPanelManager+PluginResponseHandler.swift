//
//  DinNovaPanelManager+PluginResponseHandler.swift
//  DinCore
//
//  Created by Jin on 2021/5/28.
//

import Foundation
import DinSupport

//extension DinNovaPanelManager {
//
//    func handlePluginWSResult(_ result: DinNovaPanelSocketResponse, byPanelID panelID: String) {
//        switch result.cmd {
//        case DinNovaPanelCommand.pluginPowerValueChanged.rawValue:
//            handlePluginPowerValue(result: result, byPanelID: panelID)
//        default:
//            break
//        }
//    }
//
//    private func handlePluginPowerValue(result: DinNovaPanelSocketResponse, byPanelID panelID: String) {
//        sendResultToPlugin(byPanelID: panelID, deviceString: .doorWindowSensor, result: result)
//    }
//
//
//    func pluginKey(WithPanelID panelID: String, deviceString: DinGetDeviceString) -> String {
//        panelID + deviceString.rawValue
//    }
//    func sendResultToPlugin(byPanelID panelID: String, deviceString: DinGetDeviceString, result: DinNovaPanelSocketResponse) {
//        let pluginKey = pluginKey(WithPanelID: panelID, deviceString: deviceString)
//        let targetDevices = pluginOperators?[pluginKey] ?? []
//        if targetDevices.count > 0 {
//            for pluginOperator in targetDevices {
//                pluginOperator.pluginControl.handle(result: result)
//            }
//        }
//    }
//}
