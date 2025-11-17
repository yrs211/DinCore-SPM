//
//  DinNovaPanelControl+HTTPResponseHandler.swift
//  DinCore
//
//  Created by Jin on 2021/5/16.
//

import UIKit
import DinSupport

extension DinNovaPanelControl {
    func handleGetSimInfo(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            let phoneNum = data?["d_phone"] as? String ?? ""
            let sim = data?["sim"] as? Int ?? 2   //2 表明有问题，作为默认值
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_GET_PANEL_SIMINFO,
                                                  result: ["d_phone": phoneNum, "sim": sim])
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.updatePanelRestrictModePhone(phoneNum, usingSync: true, complete: nil)
                self.updatePanelSimStatus(sim, usingSync: true, complete: nil)
                DispatchQueue.global().async { [weak self] in
                    self?.accept(panelOperationResult: returnDict)
                }
            }
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_PANEL_SIMINFO,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
            accept(panelOperationResult: returnDict)
        }
    }

    func handleGetRestrictSMS(_ data: [String: Any]?, phone: String, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            if let dict = data,
               let dataString = DinDataConvertor.convertToString(dict),
               let encryptString = DinCore.cryptor.rc4EncryptToData(with: dataString, key: DinCore.appSecret ?? "")?.base64EncodedString(), encryptString.count > 0 {
                returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_RESTRICT_SMS_STRING,
                                                      result: ["sms_string": encryptString,
                                                               "phoneNum": phone])
            } else {
                returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_RESTRICT_SMS_STRING,
                                                          errorMessage: "encrypt error",
                                                          result: [:])
            }
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_RESTRICT_SMS_STRING,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handleExitDelayInfo(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            let exitTime = data?["time"] as? Int ?? 0
            let exitEnable = data?["exitdelaysound"] as? Bool ?? false
            let timeOptions: [Int] = data?["options"] as? [Int] ?? []
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_GET_EXITDELAY,
                                                  result: ["time": exitTime, "exitdelaysound": exitEnable, "options":timeOptions])
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.updateExitDelay(exitTime, usingSync: true, complete: nil)
                DispatchQueue.global().async { [weak self] in
                    self?.accept(panelOperationResult: returnDict)
                }
            }
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_EXITDELAY,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
            accept(panelOperationResult: returnDict)
        }
    }

    func handleEntryDelayInfo(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            let time = data?["time"] as? Int ?? 0
            let enable = data?["entrydelaysound"] as? Bool ?? false
            let timeOptions: [Int] = data?["options"] as? [Int] ?? []
            let plugins = data?["plugins"] as? [[String: Any]] ?? []
            let thirdpartyplugins = data?["thirdpartyplugins"] as? [[String: Any]] ?? []
            let newaskplugin = data?["newaskplugin"] as? [[String: Any]] ?? []
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_GET_ENTRYDELAY,
                                                  result: ["time": time,
                                                           "entrydelaysound": enable,
                                                           "options": timeOptions,
                                                           "plugins": plugins,
                                                           "thirdpartyplugins": thirdpartyplugins,
                                                           "newaskplugin": newaskplugin])
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.updateEntryDelay(time, usingSync: true, complete: nil)
                DispatchQueue.global().async { [weak self] in
                    self?.accept(panelOperationResult: returnDict)
                }
            }
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_ENTRYDELAY,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
            accept(panelOperationResult: returnDict)
        }
    }

    func handleSirenTime(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            let time = data?["time"] as? Int ?? 0
            let timeOptions: [Int] = data?["options"] as? [Int] ?? []
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_GET_SIRENTIME,
                                                  result: ["time": time,
                                                           "options": timeOptions])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_SIRENTIME,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handleHomeArmInfo(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            let oldPlugin = data?["homearmsetting"] as? [[String: Any]] ?? []
            let thirdparty = data?["thirdpartyhomearmsetting"] as? [[String: Any]] ?? []
            let newaskPlugin = data?["newaskplugin"] as? [[String: Any]] ?? []
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_GET_HOMEARMINFO,
                                                  result: ["homearmsetting": oldPlugin,
                                                           "thirdpartyhomearmsetting": thirdparty,
                                                           "newaskplugin": newaskPlugin])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_HOMEARMINFO,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handleDuressInfo(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            let enable = data?["enable"] as? Bool ?? false
            let hasPassword = data?["password"] as? Bool ?? false
            let sms = data?["sms"] as? String ?? ""
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_GET_DURESSINFO,
                                                  result: ["enable": enable,
                                                           "password": hasPassword,
                                                           "sms": sms])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_DURESSINFO,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handleDeletePanelResult(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_DELETE_PANEL,
                                                  result: [:])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_DELETE_PANEL,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handleUnbindUserResult(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_UNBIND_USER,
                                                  result: [:])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_UNBIND_USER,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handleRenamePanelResult(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_RENAME_PANEL,
                                                  result: [:])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_RENAME_PANEL,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handleVerifyPasswordResult(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_PANEL_VERPWD,
                                                  result: [:])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_PANEL_VERPWD,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handleSpecifyEventListResult(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            let eventList = data?["eventlist"] as? [[String: Any]] ?? []
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_PANEL_SPECIFYEVENTLIST,
                                                  result: ["eventlist": eventList])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_PANEL_SPECIFYEVENTLIST,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handleQRCode(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            let sharecode = data?["sharecode"] as? String ?? ""
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_PANEL_QRCODE,
                                                  result: ["sharecode": sharecode])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_PANEL_QRCODE,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handleSOSInfo(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_PANEL_SOSINFO,
                                                  result: data ?? [:])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_PANEL_SOSINFO,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handleModifyMemberResult(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_MODIFY_MEMBER,
                                                  result: [:])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_MODIFY_MEMBER,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handleEmergencyContacts(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            let devicecontacts = data?["devicecontacts"] as? [[String: Any]] ?? []
            let usercontacts = data?["usercontacts"] as? [[String: Any]] ?? []
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_PANEL_EMERCONTACTS,
                                                  result: ["devicecontacts": devicecontacts,
                                                           "usercontacts": usercontacts])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_PANEL_EMERCONTACTS,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handleModifyEmergencyContacts(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_MODIFY_EMERCONTACTS,
                                                  result: [:])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_MODIFY_EMERCONTACTS,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handleAddEmergencyContacts(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_ADD_EMERCONTACTS,
                                                  result: [:])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_ADD_EMERCONTACTS,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handleRemoveEmergencyContacts(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_REMOVE_EMERCONTACTS,
                                                  result: [:])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_REMOVE_EMERCONTACTS,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handlePanelMessageResult(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_GET_MESSAGE,
                                                  result: data ?? [:])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_MESSAGE,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handlePanelCIDData(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_GET_CIDDATA,
                                                  result: data ?? [:])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_CIDDATA,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handlePanelTimezoneSetting(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_GET_TIMEZONE,
                                                  result: data ?? [:])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_TIMEZONE,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handleReadyToArmStatus(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_GET_RTASTATUS,
                                                  result: data ?? [:])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_RTASTATUS,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handleAdvancedSetting(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_GET_ADVANCED,
                                                  result: data ?? [:])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_ADVANCED,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handle4GInfo(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_GET_4GINFO,
                                                  result: data ?? [:])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_4GINFO,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handleCMSInfo(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_GET_CMSINFO,
                                                  result: data ?? [:])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_CMSINFO,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }
    
    func handlePlugCountResult(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil, let plugins = data?["plugin"] as? [String: Any] {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.updatePanelSecurityAccessoryCount(plugins["security_accessories"] as? Int ?? 0, usingSync: true, complete: nil)
                self.updatePanelRemoteControlCount(plugins["remote_controller"] as? Int ?? 0, usingSync: true, complete: nil)
                self.updatePanelKeypadAccessoryCount(plugins["keypad"] as? Int ?? 0, usingSync: true, complete: nil)
                self.updatePanelSmartButtonCount(plugins["smart_button"] as? Int ?? 0, usingSync: true, complete: nil)
                self.updatePanelDoorSensorCount(plugins["door_window"] as? Int ?? 0, usingSync: true, complete: nil)
                self.updatePanelSmartPlugCount(plugins["smart_plug"] as? Int ?? 0, usingSync: true, complete: nil)
                self.updatePanelSirenCount(plugins["siren"] as? Int ?? 0, usingSync: true, complete: nil)
                self.updatePanelRelayAccessoryCount(plugins["roller_shutter"] as? Int ?? 0, usingSync: true, complete: nil)
                self.updatePanelSignalRepeaterPlugCount(plugins["signal_repeater_plug"] as? Int ?? 0, usingSync: true, complete: nil)

                returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_COUNT_PLUGIN,
                                                      result: data ?? [:])
                DispatchQueue.global().async { [weak self] in
                    self?.accept(panelOperationResult: returnDict)
                }
            }
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_COUNT_PLUGIN,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
            accept(panelOperationResult: returnDict)
        }
    }

    func handleCareModeData(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_GET_CAREMODE,
                                                  result: data ?? [:])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_CAREMODE,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handleEventListSetting(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_GET_EVENTLIST_SETTING,
                                                  result: data ?? [:])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_EVENTLIST_SETTING,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handlePluginListResult(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_LIST,
                                                  result: data ?? [:])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_LIST,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }
    
    func handleBindPanelToHome(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_BIND_PANEL_HOME,
                                                  result: data ?? [:])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_BIND_PANEL_HOME,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }

    func handleLearnModeAskInfoResult(_ data: [String: Any]?, error: Error?) {
        var returnDict: [String: Any] = [:]
        if error == nil {
            returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPanelControl.CMD_LEARNMODE_ASKINFO,
                                                  result: data ?? [:])
        } else {
            returnDict = self.makeHTTPFailureInfo(withCMD: DinNovaPanelControl.CMD_LEARNMODE_ASKINFO,
                                                  errorMessage: error?.localizedDescription ?? "",
                                                  result: [:])
        }
        accept(panelOperationResult: returnDict)
    }
}

// MARK: 小工具
extension DinNovaPanelControl {
    func handleGetAntiInterferenceStatus(_ data: [String: Any]?, error: Error?) {
        var dict: [String: Any] = [:]
        if error == nil {
            dict = self.makeHTTPSuccessInfo(
                withCMD: DinNovaPanelControl.CMD_WIDGET_GET_ANTIINTERFERENCE_STATUS,
                result: data ?? [:]
            )
        } else {
            dict = self.makeHTTPFailureInfo(
                withCMD: DinNovaPanelControl.CMD_WIDGET_GET_ANTIINTERFERENCE_STATUS,
                errorMessage: error?.localizedDescription ?? "",
                result: [:]
            )
        }

        accept(panelOperationResult: dict)
    }

    func handleModifyConfCover(_ data: [String: Any]?, error: Error?) {
        var dict: [String: Any] = [:]
        if error == nil {
            dict = self.makeHTTPSuccessInfo(
                withCMD: DinNovaPanelControl.CMD_WIDGET_MODIFY_CONF_COVER,
                result: data ?? [:]
            )
        } else {
            dict = self.makeHTTPFailureInfo(
                withCMD: DinNovaPanelControl.CMD_WIDGET_MODIFY_CONF_COVER,
                errorMessage: error?.localizedDescription ?? "",
                result: [:]
            )
        }

        accept(panelOperationResult: dict)
    }

    func handleGetTimerTaskList(_ data: [String: Any]?, error: Error?) {
        var dict: [String: Any] = [:]
        if error == nil {
            dict = self.makeHTTPSuccessInfo(
                withCMD: DinNovaPanelControl.CMD_WIDGET_GET_TIMER_TASK_LIST,
                result: data ?? [:]
            )
        } else {
            dict = self.makeHTTPFailureInfo(
                withCMD: DinNovaPanelControl.CMD_WIDGET_GET_TIMER_TASK_LIST,
                errorMessage: error?.localizedDescription ?? "",
                result: [:]
            )
        }

        accept(panelOperationResult: dict)
    }

    func handleToggleTimerTaskAbility(_ data: [String: Any]?, error: Error?) {
        var dict: [String: Any] = [:]
        if error == nil {
            dict = self.makeHTTPSuccessInfo(
                withCMD: DinNovaPanelControl.CMD_WIDGET_TOGGLE_TIMER_TASK_ABILITY,
                result: data ?? [:]
            )
        } else {
            dict = self.makeHTTPFailureInfo(
                withCMD: DinNovaPanelControl.CMD_WIDGET_TOGGLE_TIMER_TASK_ABILITY,
                errorMessage: error?.localizedDescription ?? "",
                result: [:]
            )
        }

        accept(panelOperationResult: dict)
    }

    func handleDeleteTimerTask(_ data: [String: Any]?, error: Error?) {
        var dict: [String: Any] = [:]
        if error == nil {
            dict = self.makeHTTPSuccessInfo(
                withCMD: DinNovaPanelControl.CMD_WIDGET_DELETE_TIMER_TASK,
                result: data ?? [:]
            )
        } else {
            dict = self.makeHTTPFailureInfo(
                withCMD: DinNovaPanelControl.CMD_WIDGET_DELETE_TIMER_TASK,
                errorMessage: error?.localizedDescription ?? "",
                result: [:]
            )
        }

        accept(panelOperationResult: dict)
    }

    func handleCreateTimerTask(_ data: [String: Any]?, error: Error?) {
        var dict: [String: Any] = [:]
        if error == nil {
            dict = self.makeHTTPSuccessInfo(
                withCMD: DinNovaPanelControl.CMD_WIDGET_CREATE_TIMER_TASK,
                result: data ?? [:]
            )
        } else {
            dict = self.makeHTTPFailureInfo(
                withCMD: DinNovaPanelControl.CMD_WIDGET_CREATE_TIMER_TASK,
                errorMessage: error?.localizedDescription ?? "",
                result: [:]
            )
        }

        accept(panelOperationResult: dict)
    }

    func handleUpdateTimerTask(_ data: [String: Any]?, error: Error?) {
        var dict: [String: Any] = [:]
        if error == nil {
            dict = self.makeHTTPSuccessInfo(
                withCMD: DinNovaPanelControl.CMD_WIDGET_UPDATE_TIMER_TASK,
                result: data ?? [:]
            )
        } else {
            dict = self.makeHTTPFailureInfo(
                withCMD: DinNovaPanelControl.CMD_WIDGET_UPDATE_TIMER_TASK,
                errorMessage: error?.localizedDescription ?? "",
                result: [:]
            )
        }

        accept(panelOperationResult: dict)
    }

    func handleGetPluginsWithRuledTask(_ data: [String: Any]?, error: Error?) {
        var dict: [String: Any] = [:]
        if error == nil {
            dict = self.makeHTTPSuccessInfo(
                withCMD: DinNovaPanelControl.CMD_WIDGET_GET_RULED_PLUGINS,
                result: data ?? [:]
            )
        } else {
            dict = self.makeHTTPFailureInfo(
                withCMD: DinNovaPanelControl.CMD_WIDGET_GET_RULED_PLUGINS,
                errorMessage: error?.localizedDescription ?? "",
                result: [:]
            )
        }

        accept(panelOperationResult: dict)
    }
}

extension DinNovaPanelControl {
    func makeHTTPSuccessInfo(withCMD cmd: String, result: [String: Any]) -> [String: Any] {
        return ["cmd": cmd, "status": 1, "owner": true, "errorMessage": "", "result": result]
    }
    private func makeHTTPFailureInfo(withCMD cmd: String, errorMessage: String, result: [String: Any]) -> [String: Any] {
        return ["cmd": cmd, "status": 0, "owner": true, "errorMessage": errorMessage, "result": result]
    }
}
