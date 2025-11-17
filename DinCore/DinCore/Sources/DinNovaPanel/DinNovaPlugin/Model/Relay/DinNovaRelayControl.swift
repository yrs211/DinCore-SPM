//
//  DinNovaRelayControl.swift
//  DinCore
//
//  Created by Jin on 2021/6/22.
//

import UIKit
import DinSupport

class DinNovaRelayControl: DinNovaPluginControl {

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
        case DinNovaPluginControl.CMD_RELAY_ACTION:
            setRelayAction(data)
        default:
            break
        }
    }

    /// result
    override func handle(result: DinNovaPanelSocketResponse) {
        super.handle(result: result)
        guard let resultDict = DinDataConvertor.convertToDictionary(result.result) else {
            // 继电器的操作没有result, 特殊处理
            if result.cmd == DinNovaPluginCommand.setRelayAction.rawValue {
                handleRelayAction(result, failEvent: nil)
            }
            return
        }
        switch result.cmd {
        case DinNovaPanelCommand.pluginPowerValueChanged.rawValue:
            handlePowerValueChange(resultDict)
        case DinNovaPluginCommand.pluginOnline.rawValue:
            handleOnline(resultDict, online: true)
        case DinNovaPluginCommand.pluginOffline.rawValue:
            handleOnline(resultDict, online: false)
        default:
            break
        }
    }

    /// timeout
    override func handleTimeout(_ event: DinNovaPanelEvent) {
        super.handleTimeout(event)
        switch event.cmd {
        case DinNovaPluginCommand.setRelayAction.rawValue:
            handleRelayAction(nil, failEvent: event)
        default:
            break
        }
    }

}

// MARK: - 更新info
extension DinNovaRelayControl {

    override func updatePluginInfo(complete: (()->())?) {
        super.updatePluginInfo { [weak self] in
            self?.updateSendID((self?.plugin as? DinNovaRelay)?.sendid ?? "", usingSync: false, complete: complete)
        }
    }
    
    func updateSendID(_ sendid: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            (plugin as? DinNovaRelay)?.sendid = sendid
            unsafeInfo["sendid"] = sendid
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                (self.plugin as? DinNovaRelay)?.sendid = sendid
                self.unsafeInfo["sendid"] = sendid
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
}
