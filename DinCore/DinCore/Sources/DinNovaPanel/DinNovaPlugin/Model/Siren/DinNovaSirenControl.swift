//
//  DinNovaSirenControl.swift
//  DinCore
//
//  Created by Jin on 2021/6/6.
//

import UIKit
import DinSupport

class DinNovaSirenControl: DinNovaPluginControl {

    override init(withPlugin plugin: DinNovaPlugin, panelOperator: DinNovaPanelOperator) {
        super.init(withPlugin: plugin, panelOperator: panelOperator)
        updatePluginInfo(complete: nil)
    }

    /// 操作
    override func operateData(_ data: [String : Any]) {
        super.operateData(data)
        guard let cmd = data["cmd"] as? String else {
            return
        }
        switch cmd {
        case DinNovaPluginControl.CMD_TESTSIREN:
            testSiren(data)
        case DinNovaPluginControl.CMD_SETSIREN:
            setSiren(data)
//        case DinNovaPluginControl.CMD_SMARTBUTTON_UPDATECONFIG:
//            setConfig(data)
        default:
            break
        }
    }

    /// result
    override func handle(result: DinNovaPanelSocketResponse) {
        super.handle(result: result)
        guard let resultDict = DinDataConvertor.convertToDictionary(result.result) else {
            return
        }
        switch result.cmd {
        case DinNovaPanelCommand.pluginPowerValueChanged.rawValue:
            handlePowerValueChange(resultDict)
//        case DinNovaPluginCommand.pluginLowPower.rawValue:
//            handlePowerState(resultDict, isLow: false)
//        case DinNovaPluginCommand.pluginPowerUp.rawValue:
//            handlePowerState(resultDict, isLow: true)
        case DinNovaPluginCommand.pluginOnline.rawValue:
            handleOnline(resultDict, online: true)
        case DinNovaPluginCommand.pluginOffline.rawValue:
            handleOnline(resultDict, online: false)
//        case DinNovaPluginCommand.updatePluginConfig.rawValue:
//            handleUpdatedConfig(result, failEvent: nil)
        case DinNovaPluginCommand.testSiren.rawValue:
            handleTestResult(result, failEvent: nil)
        case DinNovaPluginCommand.setSiren.rawValue:
            handleSettingResult(result, failEvent: nil)
        case DinNovaPluginCommand.setNewSiren.rawValue:
            handleASKSettingResult(result, failEvent: nil)
        default:
            break
        }
    }

    /// timeout
    override func handleTimeout(_ event: DinNovaPanelEvent) {
        super.handleTimeout(event)
        switch event.cmd {
        case DinNovaPluginCommand.testSiren.rawValue:
            handleTestResult(nil, failEvent: event)
        case DinNovaPluginCommand.setSiren.rawValue:
            handleSettingResult(nil, failEvent: event)
        case DinNovaPluginCommand.setNewSiren.rawValue:
            handleASKSettingResult(nil, failEvent: event)
        default:
            break
        }
    }
}

// MARK: - 更新info
extension DinNovaSirenControl {

    override func updatePluginInfo(complete: (()->())?) {
        super.updatePluginInfo {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.updateSendID((self.plugin as? DinNovaSiren)?.sendid ?? "", usingSync: true, complete: nil)
                self.updateSirenSetting((self.plugin as? DinNovaSiren)?.sirenSetting ?? "", usingSync: true, complete: nil)
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateSendID(_ sendid: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            (plugin as? DinNovaSiren)?.sendid = sendid
            unsafeInfo["sendid"] = sendid
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                (self.plugin as? DinNovaSiren)?.sendid = sendid
                self.unsafeInfo["sendid"] = sendid
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateSirenSetting(_ sirenSetting: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            (plugin as? DinNovaSiren)?.sirenSetting = sirenSetting
            unsafeInfo["sirenSetting"] = sirenSetting
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                (self.plugin as? DinNovaSiren)?.sirenSetting = sirenSetting
                self.unsafeInfo["sirenSetting"] = sirenSetting
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
}
