//
//  DinNovaSecurityAccessoryControl.swift
//  DinCore
//
//  Created by Jin on 2021/6/22.
//

import UIKit
import DinSupport

class DinNovaSecurityAccessoryControl: DinNovaPluginControl {

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
        case DinNovaPluginControl.CMD_CONFIGBLOCK:
            configBlock(data)
        case DinNovaPluginControl.CMD_PLUG_DELETEBINDCONFIG:
            deleteConfig(data)
        case DinNovaPluginControl.CMD_PLUG_UPDATEBINDCONFIG:
            setConfig(data)
        case DinNovaPluginControl.CMD_BYPASS_PLUGIN_5_MIN:
            byPassPlugin5Min(data)
        case DinNovaPluginControl.CMD_SET_SENSITIVITY:
            setSensitivity(data)
        case DinNovaPluginControl.CMD_EXIT_PIR_SETTING_MODE:
            exitPIRSettingMode(data)
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
        case DinNovaPluginCommand.pluginOnline.rawValue:
            handleOnline(resultDict, online: true)
        case DinNovaPluginCommand.pluginOffline.rawValue:
            handleOnline(resultDict, online: false)
        case DinNovaPluginCommand.setPluginBlock.rawValue:
            handleBlockConfig(result, failEvent: nil)
        case DinNovaPluginCommand.updatePluginConfig.rawValue:
            handleUpdatedConfig(result, failEvent: nil)
        case DinNovaPluginCommand.byPassPlugin5Min.rawValue:
            handleByPassPlugin5MinResult(result, failEvent: nil)
        case DinNovaPluginCommand.pirSettingEnabled.rawValue:
            handlePIRSettingEnable(result, failEvent: nil)
        case DinNovaPluginCommand.setSensitivity.rawValue:
            handleSetSensitivityResult(result, failEvent: nil)
        case DinNovaPluginCommand.exitPIRSettingMode.rawValue:
            handleExitPIRSettingModeResult(result, failEvent: nil)
        default:
            break
        }
    }

    /// timeout
    override func handleTimeout(_ event: DinNovaPanelEvent) {
        super.handleTimeout(event)
        switch event.cmd {
        case DinNovaPluginCommand.setPluginBlock.rawValue:
            handleBlockConfig(nil, failEvent: event)
        case DinNovaPluginCommand.updatePluginConfig.rawValue:
            handleUpdatedConfig(nil, failEvent: event)
        case DinNovaPluginCommand.byPassPlugin5Min.rawValue:
            handleByPassPlugin5MinResult(nil, failEvent: event)
        case DinNovaPluginCommand.setSensitivity.rawValue:
            handleSetSensitivityResult(nil, failEvent: event)
        case DinNovaPluginCommand.exitPIRSettingMode.rawValue:
            handleExitPIRSettingModeResult(nil, failEvent: event)
        default:
            break
        }
    }
}

// MARK: - 更新info
extension DinNovaSecurityAccessoryControl {

    override func updatePluginInfo(complete: (()->())?) {
        super.updatePluginInfo {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.updateSendID((self.plugin as? DinNovaSecurityAccessory)?.sendid ?? "", usingSync: true, complete: nil)
                self.updateBlock((self.plugin as? DinNovaSecurityAccessory)?.block ?? -1, usingSync: true, complete: nil)
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateSendID(_ sendid: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            (plugin as? DinNovaSecurityAccessory)?.sendid = sendid
            unsafeInfo["sendid"] = sendid
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                (self.plugin as? DinNovaSecurityAccessory)?.sendid = sendid
                self.unsafeInfo["sendid"] = sendid
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateBlock(_ block: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            (plugin as? DinNovaSecurityAccessory)?.block = block
            unsafeInfo["block"] = block
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                (self.plugin as? DinNovaSecurityAccessory)?.block = block
                self.unsafeInfo["block"] = block
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateSensitivity(_ sensitivity: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            unsafeInfo["sensitivity"] = sensitivity
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.unsafeInfo["sensitivity"] = sensitivity
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
}
