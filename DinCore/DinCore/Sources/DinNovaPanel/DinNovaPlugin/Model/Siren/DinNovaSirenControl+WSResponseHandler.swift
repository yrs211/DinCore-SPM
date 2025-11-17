//
//  DinNovaSirenControl+WSResponseHandler.swift
//  DinCore
//
//  Created by Jin on 2021/6/6.
//

import Foundation
import DinSupport

extension DinNovaSirenControl {
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
        if sendid == (self.plugin as? DinNovaSmartButton)?.sendid ?? "" {
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

    func handleTestResult(_ result: DinNovaPanelSocketResponse?, failEvent: DinNovaPanelEvent?) {
        guard failEvent == nil, let response = result else {
            let isSelf = failEvent?.id ?? "" == self.operationInfoHolder.testSirenMID
            if isSelf {
                self.operationInfoHolder.testSirenMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_TESTSIREN,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            accept(deviceOperationResult: returnDict)
            return
        }

        let isSelf = response.messageID == self.operationInfoHolder.testSirenMID
        if isSelf {
            self.operationTimeoutChecker.removeEvent(id: response.messageID)
            self.operationInfoHolder.testSirenMID = nil
        }

        // 是否是属于自己的配件
        var ownData = false
        if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
            if let pluginID = resultDict["pluginid"] as? String, pluginID.count > 0 {
                if self.plugin.id == pluginID {
                    ownData = true
                }
            }
            if ownData {
                if response.status == 1 {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_TESTSIREN,
                                                                owner: isSelf,
                                                                result: resultDict)
                    accept(deviceOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_TESTSIREN,
                                                                owner: isSelf,
                                                                errorMessage: response.error,
                                                                result: [:])
                    self.accept(deviceOperationResult: returnDict)
                }
            }
        }
        if isSelf && !ownData {
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_TESTSIREN,
                                                            owner: isSelf,
                                                            result: [:])
                accept(deviceOperationResult: returnDict)
            } else {
                // 如果是自己的message，转化不了dict也要报错误
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_TESTSIREN,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(deviceOperationResult: returnDict)
            }
        }
    }

    func handleSettingResult(_ result: DinNovaPanelSocketResponse?, failEvent: DinNovaPanelEvent?) {
        guard failEvent == nil, let response = result else {
            let isSelf = failEvent?.id ?? "" == self.operationInfoHolder.setSirenMID
            if isSelf {
                self.operationInfoHolder.setSirenMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_SETSIREN,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            accept(deviceOperationResult: returnDict)
            return
        }

        let isSelf = response.messageID == self.operationInfoHolder.setSirenMID
        if isSelf {
            self.operationTimeoutChecker.removeEvent(id: response.messageID)
            self.operationInfoHolder.setSirenMID = nil
        }

        // 是否是属于自己的配件
        var ownData = false
        if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
            if let pluginID = resultDict["pluginid"] as? String, pluginID.count > 0 {
                if self.plugin.id == pluginID {
                    ownData = true
                }
            }  else if let sendid = resultDict["sendid"] as? String, sendid.count > 0 {
                if (self.plugin as? DinNovaSiren)?.sendid == sendid {
                    ownData = true
                }
            }
            if ownData {
                if response.status == 1 {
                    if let advancesetting = resultDict["advancesetting"] as? String {
                        DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                            guard let self = self else { return }
                            self.updateSirenSetting(advancesetting, usingSync: true, complete: nil)
                            if var askData = self.plugin.askData {
                                askData["sirenSetting"] = advancesetting
                                self.updateASKData(askData, usingSync: true, complete: nil)
                            }
                            DispatchQueue.global().async { [weak self] in
                                guard let self = self else { return }
                                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_SETSIREN,
                                                                            owner: isSelf,
                                                                            result: resultDict)
                                self.accept(deviceOperationResult: returnDict)
                            }
                        }
                    } else {
                        let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_SETSIREN,
                                                                    owner: isSelf,
                                                                    result: resultDict)
                        accept(deviceOperationResult: returnDict)
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_SETSIREN,
                                                                owner: isSelf,
                                                                errorMessage: response.error,
                                                                result: [:])
                    self.accept(deviceOperationResult: returnDict)
                }
            }
        }
        if isSelf && !ownData {
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_SETSIREN,
                                                            owner: isSelf,
                                                            result: [:])
                accept(deviceOperationResult: returnDict)
            } else {
                // 如果是自己的message，转化不了dict也要报错误
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_SETSIREN,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(deviceOperationResult: returnDict)
            }
        }
    }

    func handleASKSettingResult(_ result: DinNovaPanelSocketResponse?, failEvent: DinNovaPanelEvent?) {
        guard failEvent == nil, let response = result else {
            let isSelf = failEvent?.id ?? "" == self.operationInfoHolder.setASKSirenMID
            if isSelf {
                self.operationInfoHolder.setASKSirenMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_SETSIREN,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            accept(deviceOperationResult: returnDict)
            return
        }

        let isSelf = response.messageID == self.operationInfoHolder.setASKSirenMID
        if isSelf {
            self.operationTimeoutChecker.removeEvent(id: response.messageID)
            self.operationInfoHolder.setASKSirenMID = nil
        }

        // 是否是属于自己的配件
        var ownData = false
        if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
            if let pluginID = resultDict["pluginid"] as? String, pluginID.count > 0 {
                if self.plugin.id == pluginID {
                    ownData = true
                }
            } else if let sendid = resultDict["sendid"] as? String, sendid.count > 0 {
                if (self.plugin as? DinNovaSiren)?.sendid == sendid {
                    ownData = true
                }
            }
            if ownData {
                if response.status == 1 {
                    if let advancesetting = resultDict["advancesetting"] as? String {
                        DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                            guard let self = self else { return }

                            self.updateSirenSetting(advancesetting, usingSync: true, complete: nil)
                            if var askData = self.plugin.askData {
                                askData["sirenSetting"] = advancesetting
                                self.updateASKData(askData, usingSync: true, complete: nil)
                            }

                            DispatchQueue.global().async { [weak self] in
                                guard let self = self else { return }
                                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_SETSIREN,
                                                                            owner: isSelf,
                                                                            result: resultDict)
                                self.accept(deviceOperationResult: returnDict)
                            }

                        }
                    } else {
                        let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_SETSIREN,
                                                                    owner: isSelf,
                                                                    result: resultDict)
                        accept(deviceOperationResult: returnDict)
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_SETSIREN,
                                                                owner: isSelf,
                                                                errorMessage: response.error,
                                                                result: [:])
                    self.accept(deviceOperationResult: returnDict)
                }
            }
        }
        if isSelf && !ownData {
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_SETSIREN,
                                                            owner: isSelf,
                                                            result: [:])
                accept(deviceOperationResult: returnDict)
            } else {
                // 如果是自己的message，转化不了dict也要报错误
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_SETSIREN,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(deviceOperationResult: returnDict)
            }
        }
    }
}
