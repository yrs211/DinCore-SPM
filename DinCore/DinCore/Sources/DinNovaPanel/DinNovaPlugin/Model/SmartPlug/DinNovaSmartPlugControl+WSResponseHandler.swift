//
//  DinNovaSmartPlugControl+WSResponseHandler.swift
//  DinCore
//
//  Created by Jin on 2021/6/2.
//

import Foundation
import DinSupport

// MARK: - Handler
extension DinNovaSmartPlugControl {
    func handleEnableChanged(_ result: DinNovaPanelSocketResponse?, failEvent: DinNovaPanelEvent?) {
        guard failEvent == nil, let response = result else {
            let isSelf = failEvent?.id ?? "" == self.operationInfoHolder.enablePluginMID
            if isSelf {
                self.operationInfoHolder.enablePluginMID = nil
                panelOperator.panelControl.lanCommunicator?.isCOAPAvailable = false
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_ENABLE_PLUG,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            accept(deviceOperationResult: returnDict)
            return
        }

        let isSelf = response.messageID == self.operationInfoHolder.enablePluginMID
        if isSelf {
            self.operationTimeoutChecker.removeEvent(id: response.messageID)
            self.operationInfoHolder.enablePluginMID = nil
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
                    if let enable = resultDict["plugin_item_smart_plug_enable"] as? Bool {
                        DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                            guard let self = self else { return }
                            self.updateIsEnable(enable, usingSync: true, complete: nil)
                            if var askData = self.plugin.askData {
                                askData["enable"] = enable
                                self.updateASKData(askData, usingSync: true, complete: nil)
                            }
                            DispatchQueue.global().async { [weak self] in
                                guard let self = self else { return }
                                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_ENABLE_PLUG,
                                                                            owner: isSelf,
                                                                            result: resultDict)
                                self.accept(deviceOperationResult: returnDict)
                            }
                        }
                    } else {
                        let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_ENABLE_PLUG,
                                                                    owner: isSelf,
                                                                    result: resultDict)
                        accept(deviceOperationResult: returnDict)
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_ENABLE_PLUG,
                                                                owner: isSelf,
                                                                errorMessage: response.error,
                                                                result: [:])
                    self.accept(deviceOperationResult: returnDict)
                }
            }
        }
        if isSelf && !ownData {
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_ENABLE_PLUG,
                                                            owner: isSelf,
                                                            result: [:])
                accept(deviceOperationResult: returnDict)
            } else {
                // 如果是自己的message，转化不了dict也要报错误
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_ENABLE_PLUG,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(deviceOperationResult: returnDict)
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
}
