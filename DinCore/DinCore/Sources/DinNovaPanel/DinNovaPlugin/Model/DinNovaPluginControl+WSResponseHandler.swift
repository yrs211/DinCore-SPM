//
//  DinNovaPluginControl+WSResponseHandler.swift
//  DinCore
//
//  Created by Jin on 2021/5/29.
//

import Foundation
import DinSupport

extension DinNovaPluginControl {
    func handleSetASKPlugNameResult(_ result: DinNovaPanelSocketResponse?, failEvent: DinNovaPanelEvent?) {
        guard failEvent == nil, let response = result else {
            let isSelf = failEvent?.id ?? "" == self.operationInfoHolder.setNameMID
            if isSelf {
                self.operationInfoHolder.setNameMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_SET_NAME,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            accept(deviceOperationResult: returnDict)
            return
        }
        let isSelf = response.messageID == self.operationInfoHolder.setNameMID
        if isSelf {
            self.operationTimeoutChecker.removeEvent(id: response.messageID)
            self.operationInfoHolder.setNameMID = nil
        }
        // 是否是属于自己的配件
        var ownData = false
        if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
            if let pluginID = resultDict["plugin_id"] as? String, pluginID.count > 0 {
                if self.plugin.id == pluginID {
                    ownData = true
                }
            } else if let sendid = resultDict["id"] as? String, sendid.count > 0 {
                var selfSendid = ""
                if let selfPlugin = plugin as? DinNovaSmartPlug {
                    selfSendid = selfPlugin.sendid
                } else if let selfPlugin = plugin as? DinNovaDoorWindowSensor {
                    selfSendid = selfPlugin.sendid
                } else if let selfPlugin = plugin as? DinNovaSmartButton {
                    selfSendid = selfPlugin.sendid
                } else if let selfPlugin = plugin as? DinNovaSiren {
                    selfSendid = selfPlugin.sendid
                } else if let selfPlugin = plugin as? DinNovaRemoteControl {
                    selfSendid = selfPlugin.sendid
                } else if let selfPlugin = plugin as? DinNovaRelay {
                    selfSendid = selfPlugin.sendid
                } else if let selfPlugin = plugin as? DinNovaSecurityAccessory {
                    selfSendid = selfPlugin.sendid
                } else if let selfPlugin = plugin as? DinNovaKeypad {
                    selfSendid = selfPlugin.sendid
                }
                if selfSendid == sendid {
                    ownData = true
                }
            }
            if ownData {
                if response.status == 1 {
                    if let name = resultDict["name"] as? String {
                        DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                            guard let self = self else { return }
                            self.updateName(name, usingSync: true, complete: nil)
                            if var askData = self.plugin.askData {
                                askData["name"] = name
                                self.updateASKData(askData, usingSync: true, complete: nil)
                            }
                            DispatchQueue.global().async { [weak self] in
                                guard let self = self else { return }
                                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_SET_NAME,
                                                                            owner: isSelf,
                                                                            result: resultDict)
                                self.accept(deviceOperationResult: returnDict)
                            }
                        }
                    } else {
                        let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_SET_NAME,
                                                                    owner: isSelf,
                                                                    result: resultDict)
                        accept(deviceOperationResult: returnDict)
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_SET_NAME,
                                                                owner: isSelf,
                                                                errorMessage: response.error,
                                                                result: [:])
                    self.accept(deviceOperationResult: returnDict)
                }
            }
        }
        if isSelf && !ownData {
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_SET_NAME,
                                                            owner: isSelf,
                                                            result: [:])
                accept(deviceOperationResult: returnDict)
            } else {
                // 如果是自己的message，转化不了dict也要报错误
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_SET_NAME,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(deviceOperationResult: returnDict)
            }
        }
    }

    func handleSetOldPlugNameResult(_ result: DinNovaPanelSocketResponse?, failEvent: DinNovaPanelEvent?) {
        guard failEvent == nil, let response = result else {
            let isSelf = failEvent?.id ?? "" == self.operationInfoHolder.setNameMID
            if isSelf {
                self.operationInfoHolder.setNameMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_SET_NAME,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            accept(deviceOperationResult: returnDict)
            return
        }
        let isSelf = response.messageID == self.operationInfoHolder.setNameMID
        if isSelf {
            self.operationTimeoutChecker.removeEvent(id: response.messageID)
            self.operationInfoHolder.setNameMID = nil
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
                    if let name = resultDict["plugin_item_name"] as? String {
                        DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                            guard let self = self else { return }
                            self.updateName(name, usingSync: true, complete: nil)
                            if var askData = self.plugin.askData {
                                askData["name"] = name
                                self.updateASKData(askData, usingSync: true, complete: nil)
                            }
                            DispatchQueue.global().async { [weak self] in
                                guard let self = self else { return }
                                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_SET_NAME,
                                                                            owner: isSelf,
                                                                            result: resultDict)
                                self.accept(deviceOperationResult: returnDict)
                            }
                        }
                    } else {
                        let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_SET_NAME,
                                                                    owner: isSelf,
                                                                    result: resultDict)
                        accept(deviceOperationResult: returnDict)
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_SET_NAME,
                                                                owner: isSelf,
                                                                errorMessage: response.error,
                                                                result: [:])
                    self.accept(deviceOperationResult: returnDict)
                }
            }
        }
        if isSelf && !ownData {
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_SET_NAME,
                                                            owner: isSelf,
                                                            result: [:])
                accept(deviceOperationResult: returnDict)
            } else {
                // 如果是自己的message，转化不了dict也要报错误
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_SET_NAME,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(deviceOperationResult: returnDict)
            }
        }
    }
}

extension DinNovaPluginControl {
    @objc func updatePluginInfo(complete: (()->())?) { 
        DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.updateName(self.plugin.name, usingSync: true, complete: nil)
            self.updateIsOnline(self.plugin.isOnline, usingSync: true, complete: nil)
            self.updateDecodeID(self.plugin.decodeID, usingSync: true, complete: nil)
            self.updateASKData(self.plugin.askData, usingSync: true, complete: nil)
            self.updateAddTime(self.plugin.addtime, usingSync: true, complete: nil)
            self.updateIsDeleted(self.plugin.isDeleted, usingSync: true, complete: nil)
            DispatchQueue.global().async {
                complete?()
            }
        }
    }

    func updateName(_ name: String, usingSync sync: Bool, complete: (() -> ())?) {
        if sync {
            plugin.name = name
            unsafeInfo["name"] = name
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.plugin.name = name
                self.unsafeInfo["name"] = name
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateIsOnline(_ isOnline: Bool, usingSync sync: Bool, complete: (() -> ())?) {
        if sync {
            plugin.isOnline = isOnline
            unsafeInfo["isOnline"] = isOnline
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.plugin.isOnline = isOnline
                self.unsafeInfo["isOnline"] = isOnline
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateIsDeleted(_ isDeleted: Bool, usingSync sync: Bool, complete: (() -> ())?) {
        if sync {
            plugin.isDeleted = isDeleted
            unsafeInfo["isDeleted"] = isDeleted
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.plugin.isDeleted = isDeleted
                self.unsafeInfo["isDeleted"] = isDeleted
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateDecodeID(_ decodeID: String, usingSync sync: Bool, complete: (() -> ())?) {
        if sync {
            plugin.decodeID = decodeID
            unsafeInfo["decodeID"] = decodeID
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.plugin.decodeID = decodeID
                self.unsafeInfo["decodeID"] = decodeID
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateASKData(_ askData: [String: Any]?, usingSync sync: Bool, complete: (() -> ())?) {
        if sync {
            plugin.askData = askData
            unsafeInfo["askData"] = askData
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.plugin.askData = askData
                self.unsafeInfo["askData"] = askData
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateAddTime(_ addtime: Int64, usingSync sync: Bool, complete: (() -> ())?) {
        if sync {
            plugin.addtime = addtime
            unsafeInfo["addtime"] = plugin.addtime
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.plugin.addtime = addtime
                self.unsafeInfo["addtime"] = addtime
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
}
