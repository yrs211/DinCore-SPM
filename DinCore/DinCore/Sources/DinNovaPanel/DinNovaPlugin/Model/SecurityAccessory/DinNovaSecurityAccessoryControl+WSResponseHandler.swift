//
//  DinNovaSecurityAccessoryControl+WSResponseHandler.swift
//  DinCore
//
//  Created by Jin on 2021/6/22.
//

import Foundation
import DinSupport

extension DinNovaSecurityAccessoryControl {
    func handlePowerValueChange(_ result: [String: Any]) {
        guard let plugins = result["plugins"] as? [[String: Any]] else {
            return
        }

        for plugin in plugins {
            if plugin["id"] as? String == self.plugin.id {
                if self.plugin.checkIsASKPlugin() {
                    DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                        guard let self = self, var askData = self.plugin.askData else { return }

                        if let batteryLevel = plugin["battery_level"] {
                            askData["battery_level"] = batteryLevel
                        }
                        if let charging = plugin["charging"] {
                            askData["charging"] = charging
                        }
                        if let tamper = plugin["tamper"] {
                            askData["tamper"] = tamper
                        }
                        if let rssi = plugin["rssi"] {
                            askData["rssi"] = rssi
                        }
                        if let sensitivity = plugin["sensitivity"] as? Int {
                            askData["sensitivity"] = sensitivity
                            self.updateSensitivity(sensitivity, usingSync: true, complete: nil)
                        }
                        self.updateASKData(askData, usingSync: true, complete: nil)
                        DispatchQueue.global().async { [weak self] in
                            guard let self = self else { return }
                            self.accept(deviceOperationResult: self.makeResultSuccessInfo(withCMD: "plugin_state_change", owner: false, result: [:]))
                        }

                    }
                }
                break
            }
        }
    }

    func handleOnline(_ result: [String: Any], online: Bool) {
        guard let sendid = result["sendid"] as? String else {
            return
        }
        if sendid == (self.plugin as? DinNovaSecurityAccessory)?.sendid ?? "" {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.updateIsOnline(online, usingSync: true, complete: nil)
                if var askData = self.plugin.askData {
                    askData["keeplive"] = online
                    self.updateASKData(askData, usingSync: true, complete: nil)
                }
                DispatchQueue.global().async { [weak self] in
                    self?.accept(deviceOnlineState: online)
                }
            }
        }
    }
    
    func handleBlockConfig(_ result: DinNovaPanelSocketResponse?, failEvent: DinNovaPanelEvent?) {
        guard failEvent == nil, let response = result else {
            let isSelf = failEvent?.id ?? "" == self.operationInfoHolder.configBlockMID
            if isSelf {
                self.operationInfoHolder.configBlockMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_CONFIGBLOCK,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            accept(deviceOperationResult: returnDict)
            return
        }
        let isSelf = response.messageID == self.operationInfoHolder.configBlockMID
        if isSelf {
            self.operationTimeoutChecker.removeEvent(id: response.messageID)
            self.operationInfoHolder.configBlockMID = nil
        }
        // 是否是属于自己的配件
        var ownData = false
        if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
            if let pluginID = resultDict["plugin_id"] as? String, pluginID.count > 0 {
                if self.plugin.id == pluginID {
                    ownData = true
                }
            } else if let sendid = resultDict["sendid"] as? String, sendid.count > 0 {
                if (self.plugin as? DinNovaSecurityAccessory)?.sendid == sendid {
                    ownData = true
                }
            }
            if ownData {
                if response.status == 1 {
                    if let block = resultDict["block"] as? Int {
                        DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                            guard let self = self else { return }
                            self.updateBlock(block, usingSync: true, complete: nil)
                            if var askData = self.plugin.askData {
                                askData["block"] = block
                                self.updateASKData(askData, usingSync: true, complete: nil)
                            }
                            DispatchQueue.global().async { [weak self] in
                                guard let self = self else { return }
                                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_CONFIGBLOCK,
                                                                            owner: isSelf,
                                                                            result: resultDict)
                                self.accept(deviceOperationResult: returnDict)
                            }
                        }
                    } else {
                        let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_CONFIGBLOCK,
                                                                    owner: isSelf,
                                                                    result: resultDict)
                        accept(deviceOperationResult: returnDict)
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_CONFIGBLOCK,
                                                                owner: isSelf,
                                                                errorMessage: response.error,
                                                                result: [:])
                    self.accept(deviceOperationResult: returnDict)
                }
            }
        }
        if isSelf && !ownData {
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_CONFIGBLOCK,
                                                            owner: isSelf,
                                                            result: [:])
                accept(deviceOperationResult: returnDict)
            } else {
                // 如果是自己的message，转化不了dict也要报错误
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_CONFIGBLOCK,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(deviceOperationResult: returnDict)
            }
        }
    }

    func handleUpdatedConfig(_ result: DinNovaPanelSocketResponse?, failEvent: DinNovaPanelEvent?) {
        guard failEvent == nil, let response = result else {
            let isSelf = failEvent?.id ?? "" == self.operationInfoHolder.updatePlugBindConfigMID
            if isSelf {
                self.operationInfoHolder.updatePlugBindConfigMID = nil
            }
            // 看看是不是删除操作
            if !isSelf {
                if failEvent?.id ?? "" == self.operationInfoHolder.deletePlugBindConfigMID {
                    handleDelectionConfig(result, failEvent: failEvent)
                    return
                }
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_PLUG_UPDATEBINDCONFIG,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            accept(deviceOperationResult: returnDict)
            return
        }

        let isSelf = response.messageID == self.operationInfoHolder.updatePlugBindConfigMID
        if isSelf {
            self.operationTimeoutChecker.removeEvent(id: response.messageID)
            self.operationInfoHolder.updatePlugBindConfigMID = nil
        }
        // 看看是不是删除操作
        if !isSelf {
            if response.messageID == self.operationInfoHolder.deletePlugBindConfigMID {
                handleDelectionConfig(result, failEvent: failEvent)
                return
            }
        }

        // 是否是属于自己的配件
        var ownData = false
        if let covertDict = DinDataConvertor.convertToDictionary(response.result), let resultDictArr = covertDict["datas"] as? [[String: Any]] {
            var infoDict: [String: Any]?
            var infoKey: String?
            for resultDict in resultDictArr {
                if let sendid = resultDict["sendid"] as? String, sendid.count > 0 {
                    if (self.plugin as? DinNovaSecurityAccessory)?.sendid == sendid {
                        ownData = true
                        infoDict = resultDict["action_conf"] as? [String: Any]
                        infoKey = resultDict["actions"] as? String
                        break
                    }
                }
            }
            if ownData {
                if response.status == 1 {
                    if let key = infoKey, key.count > 0 {
                        DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                            guard let self = self else { return }
                            if var askData = self.plugin.askData {
                                if let value = infoDict, value.count > 0 {
                                    askData[key] = infoDict
                                } else {
                                    askData.removeValue(forKey: key)
                                }
                                self.updateASKData(askData, usingSync: true, complete: nil)
                            }
                            DispatchQueue.global().async { [weak self] in
                                guard let self = self else { return }
                                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_PLUG_UPDATEBINDCONFIG,
                                                                            owner: isSelf,
                                                                            result: [:])
                                self.accept(deviceOperationResult: returnDict)
                            }
                        }
                    } else {
                        let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_PLUG_UPDATEBINDCONFIG,
                                                                    owner: isSelf,
                                                                    result: [:])
                        accept(deviceOperationResult: returnDict)
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_PLUG_UPDATEBINDCONFIG,
                                                                owner: isSelf,
                                                                errorMessage: response.error,
                                                                result: [:])
                    self.accept(deviceOperationResult: returnDict)
                }
            }
        }
        if isSelf && !ownData {
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_PLUG_UPDATEBINDCONFIG,
                                                            owner: isSelf,
                                                            result: [:])
                accept(deviceOperationResult: returnDict)
            } else {
                // 如果是自己的message，转化不了dict也要报错误
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_PLUG_UPDATEBINDCONFIG,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(deviceOperationResult: returnDict)
            }
        }
    }

    func handleDelectionConfig(_ result: DinNovaPanelSocketResponse?, failEvent: DinNovaPanelEvent?) {
        guard failEvent == nil, let response = result else {
            let isSelf = failEvent?.id ?? "" == self.operationInfoHolder.deletePlugBindConfigMID
            if isSelf {
                self.operationInfoHolder.deletePlugBindConfigMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_PLUG_DELETEBINDCONFIG,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            accept(deviceOperationResult: returnDict)
            return
        }

        let isSelf = response.messageID == self.operationInfoHolder.deletePlugBindConfigMID
        if isSelf {
            self.operationTimeoutChecker.removeEvent(id: response.messageID)
            self.operationInfoHolder.deletePlugBindConfigMID = nil
        }

        // 是否是属于自己的配件
        var ownData = false
        if let covertDict = DinDataConvertor.convertToDictionary(response.result), let resultDictArr = covertDict["datas"] as? [[String: Any]] {
            var infoDict: [String: Any]?
            var infoKey: String?
            for resultDict in resultDictArr {
                if let sendid = resultDict["sendid"] as? String, sendid.count > 0 {
                    if (self.plugin as? DinNovaSecurityAccessory)?.sendid == sendid {
                        ownData = true
                        infoDict = resultDict["action_conf"] as? [String: Any]
                        infoKey = resultDict["actions"] as? String
                        break
                    }
                }
            }
            if ownData {
                if response.status == 1 {
                    if let key = infoKey, key.count > 0 {
                        DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                            guard let self = self else { return }
                            if var askData = self.plugin.askData {
                                if let value = infoDict, value.count > 0 {
                                    askData[key] = infoDict
                                } else {
                                    askData.removeValue(forKey: key)
                                }
                                self.updateASKData(askData, usingSync: true, complete: nil)
                            }
                            DispatchQueue.global().async { [weak self] in
                                guard let self = self else { return}
                                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_PLUG_DELETEBINDCONFIG,
                                                                            owner: isSelf,
                                                                            result: [:])
                                self.accept(deviceOperationResult: returnDict)
                            }
                        }
                    } else {
                        let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_PLUG_DELETEBINDCONFIG,
                                                                    owner: isSelf,
                                                                    result: [:])
                        accept(deviceOperationResult: returnDict)
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_PLUG_DELETEBINDCONFIG,
                                                                owner: isSelf,
                                                                errorMessage: response.error,
                                                                result: [:])
                    self.accept(deviceOperationResult: returnDict)
                }
            }
        }
        if isSelf && !ownData {
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_PLUG_DELETEBINDCONFIG,
                                                            owner: isSelf,
                                                            result: [:])
                accept(deviceOperationResult: returnDict)
            } else {
                // 如果是自己的message，转化不了dict也要报错误
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_PLUG_DELETEBINDCONFIG,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(deviceOperationResult: returnDict)
            }
        }
    }
    
    func handleByPassPlugin5MinResult(_ result: DinNovaPanelSocketResponse?, failEvent: DinNovaPanelEvent?) {
        guard failEvent == nil, let response = result else {
            let isSelf = failEvent?.id ?? "" == self.operationInfoHolder.byPassPlugin5MinMID
            if isSelf {
                self.operationInfoHolder.byPassPlugin5MinMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_BYPASS_PLUGIN_5_MIN,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            accept(deviceOperationResult: returnDict)
            return
        }
        let isSelf = response.messageID == self.operationInfoHolder.byPassPlugin5MinMID
        if isSelf {
            self.operationTimeoutChecker.removeEvent(id: response.messageID)
            self.operationInfoHolder.byPassPlugin5MinMID = nil
        }
        // 是否是属于自己的配件
        var ownData = false
        if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
            if let pluginID = resultDict["plugin_id"] as? String, pluginID.count > 0 {
                if self.plugin.id == pluginID {
                    ownData = true
                }
            } else if let sendid = resultDict["sendid"] as? String, sendid.count > 0 {
                if (self.plugin as? DinNovaSecurityAccessory)?.sendid == sendid {
                    ownData = true
                }
            }
            if ownData {
                if response.status == 1 {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_BYPASS_PLUGIN_5_MIN,
                                                                owner: isSelf,
                                                                result: resultDict)
                    self.accept(deviceOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_BYPASS_PLUGIN_5_MIN,
                                                                owner: isSelf,
                                                                errorMessage: response.error,
                                                                result: [:])
                    self.accept(deviceOperationResult: returnDict)
                }
            }
        }
        if isSelf && !ownData {
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_BYPASS_PLUGIN_5_MIN,
                                                            owner: isSelf,
                                                            result: [:])
                accept(deviceOperationResult: returnDict)
            } else {
                // 如果是自己的message，转化不了dict也要报错误
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_BYPASS_PLUGIN_5_MIN,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(deviceOperationResult: returnDict)
            }
        }
    }
    
    func handleSetSensitivityResult(_ result: DinNovaPanelSocketResponse?, failEvent: DinNovaPanelEvent?) {
        guard failEvent == nil, let response = result else {
            let isSelf = failEvent?.id ?? "" == self.operationInfoHolder.setSensitivityMID
            if isSelf {
                self.operationInfoHolder.setSensitivityMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_SET_SENSITIVITY,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            accept(deviceOperationResult: returnDict)
            return
        }
        let isSelf = response.messageID == self.operationInfoHolder.setSensitivityMID
        if isSelf {
            self.operationTimeoutChecker.removeEvent(id: response.messageID)
            self.operationInfoHolder.setSensitivityMID = nil
        }
        // 是否是属于自己的配件
        var ownData = false
        if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
            if let pluginID = resultDict["plugin_id"] as? String, pluginID.count > 0 {
                if self.plugin.id == pluginID {
                    ownData = true
                }
            } else if let sendid = resultDict["sendid"] as? String, sendid.count > 0 {
                if (self.plugin as? DinNovaSecurityAccessory)?.sendid == sendid {
                    ownData = true
                }
            }
            if ownData {
                if response.status == 1 {
                    if let sensitivity = resultDict["sensitivity"] as? Int {
                        DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                            guard let self = self else { return }
                            self.updateSensitivity(sensitivity, usingSync: true, complete: nil)
                            if var askData = self.plugin.askData {
                                askData["sensitivity"] = sensitivity
                                self.updateASKData(askData, usingSync: true, complete: nil)
                            }
                            DispatchQueue.global().async { [weak self] in
                                guard let self = self else { return }
                                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_SET_SENSITIVITY,
                                                                            owner: isSelf,
                                                                            result: resultDict)
                                self.accept(deviceOperationResult: returnDict)
                            }
                        }
                    } else {
                        let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_SET_SENSITIVITY,
                                                                    owner: isSelf,
                                                                    result: resultDict)
                        accept(deviceOperationResult: returnDict)
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_SET_SENSITIVITY,
                                                                owner: isSelf,
                                                                errorMessage: response.error,
                                                                result: [:])
                    self.accept(deviceOperationResult: returnDict)
                }
            }
        }
        if isSelf && !ownData {
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_SET_SENSITIVITY,
                                                            owner: isSelf,
                                                            result: [:])
                accept(deviceOperationResult: returnDict)
            } else {
                // 如果是自己的message，转化不了dict也要报错误
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_SET_SENSITIVITY,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(deviceOperationResult: returnDict)
            }
        }
    }
    
    func handleExitPIRSettingModeResult(_ result: DinNovaPanelSocketResponse?, failEvent: DinNovaPanelEvent?) {
        guard failEvent == nil, let response = result else {
            let isSelf = failEvent?.id ?? "" == self.operationInfoHolder.exitPIRSettingModeMID
            if isSelf {
                self.operationInfoHolder.exitPIRSettingModeMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_EXIT_PIR_SETTING_MODE,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            accept(deviceOperationResult: returnDict)
            return
        }
        let isSelf = response.messageID == self.operationInfoHolder.exitPIRSettingModeMID
        if isSelf {
            self.operationTimeoutChecker.removeEvent(id: response.messageID)
            self.operationInfoHolder.exitPIRSettingModeMID = nil
        }
        // 是否是属于自己的配件
        var ownData = false
        if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
            if let pluginID = resultDict["plugin_id"] as? String, pluginID.count > 0 {
                if self.plugin.id == pluginID {
                    ownData = true
                }
            } else if let sendid = resultDict["sendid"] as? String, sendid.count > 0 {
                if (self.plugin as? DinNovaSecurityAccessory)?.sendid == sendid {
                    ownData = true
                }
            }
            if ownData {
                if response.status == 1 {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_EXIT_PIR_SETTING_MODE,
                                                                owner: isSelf,
                                                                result: resultDict)
                    self.accept(deviceOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_EXIT_PIR_SETTING_MODE,
                                                                owner: isSelf,
                                                                errorMessage: response.error,
                                                                result: [:])
                    self.accept(deviceOperationResult: returnDict)
                }
            }
        }
        if isSelf && !ownData {
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_EXIT_PIR_SETTING_MODE,
                                                            owner: isSelf,
                                                            result: [:])
                accept(deviceOperationResult: returnDict)
            } else {
                // 如果是自己的message，转化不了dict也要报错误
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_EXIT_PIR_SETTING_MODE,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(deviceOperationResult: returnDict)
            }
        }
    }
    
    func handlePIRSettingEnable(_ result: DinNovaPanelSocketResponse?, failEvent: DinNovaPanelEvent?) {
        guard failEvent == nil, let response = result else {
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_PIR_SETTING_ENABLED,
                                                        owner: true,
                                                        errorMessage: "timout",
                                                        result: [:])
            accept(deviceOperationResult: returnDict)
            return
        }
        let isSelf = false
        // 是否是属于自己的配件
        var ownData = false
        if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
            if let pluginID = resultDict["plugin_id"] as? String, pluginID.count > 0 {
                if self.plugin.id == pluginID {
                    ownData = true
                }
            } else if let sendid = resultDict["sendid"] as? String, sendid.count > 0 {
                if (self.plugin as? DinNovaSecurityAccessory)?.sendid == sendid {
                    ownData = true
                }
            }
            if ownData {
                if response.status == 1 {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_PIR_SETTING_ENABLED,
                                                                owner: true,
                                                                result: resultDict)
                    self.accept(deviceOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_PIR_SETTING_ENABLED,
                                                                owner: true,
                                                                errorMessage: response.error,
                                                                result: [:])
                    self.accept(deviceOperationResult: returnDict)
                }
            }
        }
        if isSelf && !ownData {
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_PIR_SETTING_ENABLED,
                                                            owner: isSelf,
                                                            result: [:])
                accept(deviceOperationResult: returnDict)
            } else {
                // 如果是自己的message，转化不了dict也要报错误
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_PIR_SETTING_ENABLED,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(deviceOperationResult: returnDict)
            }
        }
    }
}
