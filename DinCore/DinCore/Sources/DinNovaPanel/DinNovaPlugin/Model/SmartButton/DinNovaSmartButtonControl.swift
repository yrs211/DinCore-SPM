//
//  DinNovaSmartButtonControl.swift
//  DinCore
//
//  Created by Jin on 2021/6/4.
//

import UIKit
import DinSupport

class DinNovaSmartButtonControl: DinNovaPluginControl {

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
        case DinNovaPluginControl.CMD_SMARTBUTTON_CONFIG:
            getConfig(data)
        case DinNovaPluginControl.CMD_PLUG_DELETEBINDCONFIG:
            deleteConfig(data)
        case DinNovaPluginControl.CMD_PLUG_UPDATEBINDCONFIG:
            setConfig(data)
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
        case DinNovaPluginCommand.pluginLowPower.rawValue:
            handlePowerState(resultDict, isLow: false)
        case DinNovaPluginCommand.pluginPowerUp.rawValue:
            handlePowerState(resultDict, isLow: true)
        case DinNovaPluginCommand.pluginOnline.rawValue:
            handleOnline(resultDict, online: true)
        case DinNovaPluginCommand.pluginOffline.rawValue:
            handleOnline(resultDict, online: false)
        case DinNovaPluginCommand.updatePluginConfig.rawValue:
            handleUpdatedConfig(result, failEvent: nil)
        default:
            break
        }
    }

    /// timeout
    override func handleTimeout(_ event: DinNovaPanelEvent) {
        super.handleTimeout(event)
        switch event.cmd {
        case DinNovaPluginCommand.updatePluginConfig.rawValue:
            handleUpdatedConfig(nil, failEvent: event)
        default:
            break
        }
    }
}


// MARK: - 更新info
extension DinNovaSmartButtonControl {

    override func updatePluginInfo(complete: (()->())?) {
        super.updatePluginInfo {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.updateSendID((self.plugin as? DinNovaSmartButton)?.sendid ?? "", usingSync: true, complete: nil)
                self.updateCanDetectOnline(usingSync: true, complete: nil)
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateCanDetectOnline(usingSync sync: Bool, complete: (() -> ())?) {
        if sync {
            unsafeInfo["canDetectOnline"] = (plugin as? DinNovaSmartButton)?.canDetectOnline ?? false
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.unsafeInfo["canDetectOnline"] = (self.plugin as? DinNovaSmartButton)?.canDetectOnline ?? false
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateSendID(_ sendid: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            (plugin as? DinNovaSmartButton)?.sendid = sendid
            unsafeInfo["sendid"] = sendid
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                (self.plugin as? DinNovaSmartButton)?.sendid = sendid
                self.unsafeInfo["sendid"] = sendid
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
}
