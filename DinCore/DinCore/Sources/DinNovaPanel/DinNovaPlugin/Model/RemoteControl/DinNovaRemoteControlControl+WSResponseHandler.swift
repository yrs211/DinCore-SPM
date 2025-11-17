//
//  DinNovaRemoteControlControl+WSResponseHandler.swift
//  DinCore
//
//  Created by Jin on 2021/6/7.
//

import Foundation
import DinSupport

extension DinNovaRemoteControlControl {
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
            let isSelf = failEvent?.id ?? "" == self.operationInfoHolder.updateRemoteControlConfigMID
            if isSelf {
                self.operationInfoHolder.updateRemoteControlConfigMID = nil
            }
            // 看看是不是删除操作
            if !isSelf {
                if failEvent?.id ?? "" == self.operationInfoHolder.deleteRemoteControlConfigMID {
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

        let isSelf = response.messageID == self.operationInfoHolder.updateRemoteControlConfigMID
        if isSelf {
            self.operationTimeoutChecker.removeEvent(id: response.messageID)
            self.operationInfoHolder.updateRemoteControlConfigMID = nil
        }
        // 看看是不是删除操作
        if !isSelf {
            if response.messageID == self.operationInfoHolder.deleteRemoteControlConfigMID {
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
                    if (self.plugin as? DinNovaRemoteControl)?.sendid == sendid {
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
                            let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_PLUG_UPDATEBINDCONFIG,
                                                                        owner: isSelf,
                                                                        result: [:])
                            DispatchQueue.global().async { [weak self] in
                                guard let self = self else { return }
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
            let isSelf = failEvent?.id ?? "" == self.operationInfoHolder.deleteRemoteControlConfigMID
            if isSelf {
                self.operationInfoHolder.deleteRemoteControlConfigMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_PLUG_DELETEBINDCONFIG,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            accept(deviceOperationResult: returnDict)
            return
        }

        let isSelf = response.messageID == self.operationInfoHolder.deleteRemoteControlConfigMID
        if isSelf {
            self.operationTimeoutChecker.removeEvent(id: response.messageID)
            self.operationInfoHolder.deleteRemoteControlConfigMID = nil
        }

        // 是否是属于自己的配件
        var ownData = false
        if let covertDict = DinDataConvertor.convertToDictionary(response.result), let resultDictArr = covertDict["datas"] as? [[String: Any]] {
            var infoDict: [String: Any]?
            var infoKey: String?
            for resultDict in resultDictArr {
                if let sendid = resultDict["sendid"] as? String, sendid.count > 0 {
                    if (self.plugin as? DinNovaRemoteControl)?.sendid == sendid {
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
                            let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_PLUG_DELETEBINDCONFIG,
                                                                        owner: isSelf,
                                                                        result: [:])
                            DispatchQueue.global().async { [weak self] in
                                guard let self = self else { return }
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

}
