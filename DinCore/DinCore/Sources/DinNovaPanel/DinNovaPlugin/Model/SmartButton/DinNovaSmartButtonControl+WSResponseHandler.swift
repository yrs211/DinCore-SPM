//
//  DinNovaSmartButtonControl+WSResponseHandler.swift
//  DinCore
//
//  Created by Jin on 2021/6/4.
//

import Foundation
import DinSupport

extension DinNovaSmartButtonControl {
    func handlePowerValueChange(_ result: [String: Any]) {
        guard let plugins = result["plugins"] as? [[String: Any]] else {
            return
        }

        for plugin in plugins {
            if plugin["id"] as? String == self.plugin.id {
                if self.plugin.checkIsASKPlugin() {
                    DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                        guard let self = self else { return }
                        if let batteryLevel = plugin["battery_level"] {
                            self.plugin.askData?["battery_level"] = batteryLevel
                        }
                        if let charging = plugin["charging"] {
                            self.plugin.askData?["charging"] = charging
                        }
                        if let tamper = plugin["tamper"] {
                            self.plugin.askData?["tamper"] = tamper
                        }
                        if let rssi = plugin["rssi"] {
                            self.plugin.askData?["rssi"] = rssi
                        }
                        self.updateASKData(self.plugin.askData ?? [:], usingSync: true, complete: nil)
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

    func handlePowerState(_ result: [String: Any], isLow: Bool) {
        guard let pluginID = result["pluginid"] as? String else {
            return
        }
        if pluginID == self.plugin.id, var askData = self.plugin.askData {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                askData["power"] = isLow
                self.updateASKData(askData, usingSync: true, complete: nil)
                DispatchQueue.global().async { [weak self] in
                    guard let self = self else { return }
                    self.accept(deviceOperationResult: self.makeResultSuccessInfo(withCMD: "plugin_power_change", owner: false, result: [:]))
                }
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
                self.plugin.askData?["keeplive"] = online
                self.updateIsOnline(online, usingSync: true, complete: nil)
                self.updateASKData(self.plugin.askData ?? [:], usingSync: true, complete: nil)
                DispatchQueue.global().async { [weak self] in
                    self?.accept(deviceOnlineState: online)
                }
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
        if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
            if let pluginID = resultDict["pluginid"] as? String, pluginID.count > 0 {
                if self.plugin.id == pluginID {
                    ownData = true
                }
            }
            if ownData {
                if response.status == 1 {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_PLUG_UPDATEBINDCONFIG,
                                                                owner: isSelf,
                                                                result: [:])
                    accept(deviceOperationResult: returnDict)
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
        if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
            if let pluginID = resultDict["pluginid"] as? String, pluginID.count > 0 {
                if self.plugin.id == pluginID {
                    ownData = true
                }
            }
            if ownData {
                if response.status == 1 {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_PLUG_DELETEBINDCONFIG,
                                                                owner: isSelf,
                                                                result: [:])
                    accept(deviceOperationResult: returnDict)
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
}
