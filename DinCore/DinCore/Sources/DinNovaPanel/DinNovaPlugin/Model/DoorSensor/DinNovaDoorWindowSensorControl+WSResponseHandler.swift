//
//  DinNovaDoorWindowSensorControl+WSResponseHandler.swift
//  DinCore
//
//  Created by Jin on 2021/5/31.
//

import Foundation
import DinSupport

// MARK: - Handler
extension DinNovaDoorWindowSensorControl {
    func handlePowerValueChange(_ result: [String: Any]) {
        guard let plugins = result["plugins"] as? [[String: Any]] else {
            return
        }

        for plugin in plugins {
            if plugin["id"] as? String == self.plugin.id {
                if self.plugin.checkIsASKPlugin() {
                    DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                        guard let self = self else { return }
                        if let enable = plugin["enable"] as? Bool {
                            self.plugin.askData?["enable"] = enable
                            self.updateIsApart(enable, usingSync: true, complete: nil)
                        }
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
                    self.accept(deviceOperationResult:
                            self.makeResultSuccessInfo(withCMD: "plugin_power_change", owner: false, result: [:]))
                }
            }
        }
    }

    func handleOnline(_ result: [String: Any], online: Bool) {
        guard let sendid = result["sendid"] as? String else {
            return
        }
        if sendid == (self.plugin as? DinNovaDoorWindowSensor)?.sendid ?? "" {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.plugin.askData?["keeplive"] = online
                self.updateIsOnline(online, usingSync: true, complete: nil)
                self.updateASKData(self.plugin.askData ?? [:], usingSync: true, complete: nil)
                DispatchQueue.global().async { [weak self] in
                    guard let self = self else { return }
                    self.accept(deviceOnlineState: online)
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
                if (self.plugin as? DinNovaDoorWindowSensor)?.sendid == sendid {
                    ownData = true
                }
            }
            if ownData {
                if response.status == 1 {
                    if let block = resultDict["block"] as? Int {
                        DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                            guard let self = self else { return }
                            self.plugin.askData?["block"] = block
                            self.updateBlock(block, usingSync: true, complete: nil)
                            self.updateASKData(self.plugin.askData ?? [:], usingSync: true, complete: nil)
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

    func handleSettingDoorWindowPushStatus(_ result: DinNovaPanelSocketResponse?, failEvent: DinNovaPanelEvent?) {
        guard failEvent == nil, let response = result else {
            let isSelf = failEvent?.id ?? "" == self.operationInfoHolder.setDoorWindowPushStatusMID
            if isSelf {
                self.operationInfoHolder.setDoorWindowPushStatusMID = nil
            }
            let returnDict = self.makeResultFailureInfo(
                withCMD: DinNovaPluginControl.CMD_SET_DOOR_WINDOW_PUSH_STATUS,
                owner: isSelf,
                errorMessage: "timout",
                result: [:]
            )
            accept(deviceOperationResult: returnDict)
            return
        }
        let isSelf = response.messageID == self.operationInfoHolder.setDoorWindowPushStatusMID
        if isSelf {
            self.operationTimeoutChecker.removeEvent(id: response.messageID)
            self.operationInfoHolder.setDoorWindowPushStatusMID = nil
        }
        // 是否是属于自己的配件
        var ownData = false
        if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
            if let pluginID = resultDict["plugin_id"] as? String, pluginID.count > 0 {
                if self.plugin.id == pluginID {
                    ownData = true
                }
            } else if let sendid = resultDict["sendid"] as? String, sendid.count > 0 {
                if (self.plugin as? DinNovaDoorWindowSensor)?.sendid == sendid {
                    ownData = true
                }
            }
            if ownData {
                if response.status == 1 {
                    if let pushStatus = resultDict["push_status"] as? Int {
                        DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                            guard let self = self else { return }
                            self.plugin.askData?["push_status"] = pushStatus
                            self.updateASKData(self.plugin.askData ?? [:], usingSync: true, complete: nil)
                            DispatchQueue.global().async { [weak self] in
                                guard let self = self else { return }
                                let returnDict = self.makeResultSuccessInfo(
                                    withCMD: DinNovaPluginControl.CMD_SET_DOOR_WINDOW_PUSH_STATUS,
                                    owner: isSelf,
                                    result: resultDict
                                )
                                self.accept(deviceOperationResult: returnDict)
                            }
                        }
                    } else {
                        let returnDict = self.makeResultSuccessInfo(
                            withCMD: DinNovaPluginControl.CMD_SET_DOOR_WINDOW_PUSH_STATUS,
                            owner: isSelf,
                            result: resultDict
                        )
                        accept(deviceOperationResult: returnDict)
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(
                        withCMD: DinNovaPluginControl.CMD_SET_DOOR_WINDOW_PUSH_STATUS,
                        owner: isSelf,
                        errorMessage: response.error,
                        result: [:]
                    )
                    self.accept(deviceOperationResult: returnDict)
                }
            }
        }
        if isSelf && !ownData {
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(
                    withCMD: DinNovaPluginControl.CMD_SET_DOOR_WINDOW_PUSH_STATUS,
                    owner: isSelf,
                    result: [:]
                )
                accept(deviceOperationResult: returnDict)
            } else {
                // 如果是自己的message，转化不了dict也要报错误
                let returnDict = self.makeResultFailureInfo(
                    withCMD: DinNovaPluginControl.CMD_SET_DOOR_WINDOW_PUSH_STATUS,
                    owner: isSelf,
                    errorMessage: response.error,
                    result: [:]
                )
                self.accept(deviceOperationResult: returnDict)
            }
        }
    }

    func handleDoorWindowSensorStatusChanged(_ result: DinNovaPanelSocketResponse?, failEvent: DinNovaPanelEvent?) {
        guard let response = result else { return }

        // 是否是属于自己的配件
        guard
            let resultDict = DinDataConvertor.convertToDictionary(response.result),
            let plugin = (resultDict["plugins"] as? [[String: Any]])?.first,
            plugin["id"] as? String == self.plugin.id
        else { return }

        if response.status == 1 {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.updateIsApart((plugin["enable"] as? Int) == 1, usingSync: true, complete: nil)
                self.plugin.askData?["enable"] = (plugin["enable"] as? Int ?? 0) == 1
                self.updateASKData(self.plugin.askData ?? [:], usingSync: true, complete: nil)
                DispatchQueue.global().async { [weak self] in
                    guard let self = self else { return }
                    let returnDict = self.makeResultSuccessInfo(
                        withCMD: DinNovaPluginControl.CMD_DOOR_WINDOW_SENSOR_STATUS_CHANGED,
                        owner: false,
                        result: resultDict
                    )
                    self.accept(deviceOperationResult: returnDict)
                }
            }
        } else {
            let returnDict = self.makeResultFailureInfo(
                withCMD: DinNovaPluginControl.CMD_DOOR_WINDOW_SENSOR_STATUS_CHANGED,
                owner: false,
                errorMessage: response.error,
                result: [:]
            )
            self.accept(deviceOperationResult: returnDict)
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
                    if (self.plugin as? DinNovaDoorWindowSensor)?.sendid == sendid {
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
                            if let value = infoDict, value.count > 0 {
                                self.plugin.askData?[key] = infoDict
                            } else {
                                self.plugin.askData?.removeValue(forKey: key)
                            }
                            self.updateASKData(self.plugin.askData ?? [:], usingSync: true, complete: nil)
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
    
    func handleGetDetail(_ result: [String: Any]?) {
        let returnDict = self.makeHTTPSuccessInfo(withCMD: DinNovaPluginControl.CMD_PLUG_DETAIL,
                                                   result: result ?? [:])
        
        DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            if self.plugin.checkIsASKPlugin() {
                if let block = result?["block"] as? Int {
                    self.plugin.askData?["block"] = block
                    self.updateBlock(block, usingSync: true, complete: nil)
                }
                self.updateASKData(self.plugin.askData ?? [:], usingSync: true, complete: nil)
            }
            DispatchQueue.global().async { [weak self] in
                guard let self = self else { return }
                self.accept(deviceOperationResult: returnDict)
            }
        }
        
    }
}
