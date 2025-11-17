//
//  DinNovaRemoteControlControl.swift
//  DinCore
//
//  Created by Jin on 2021/6/7.
//

import UIKit
import DinSupport

class DinNovaRemoteControlControl: DinNovaPluginControl {

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
extension DinNovaRemoteControlControl {

    override func updatePluginInfo(complete: (()->())?) {
        super.updatePluginInfo { [weak self] in
            self?.updateSendID((self?.plugin as? DinNovaRemoteControl)?.sendid ?? "", usingSync: false, complete: complete)
        }
    }

    func updateSendID(_ sendid: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            (plugin as? DinNovaRemoteControl)?.sendid = sendid
            unsafeInfo["sendid"] = sendid
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                (self.plugin as? DinNovaRemoteControl)?.sendid = sendid
                self.unsafeInfo["sendid"] = sendid
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
}
