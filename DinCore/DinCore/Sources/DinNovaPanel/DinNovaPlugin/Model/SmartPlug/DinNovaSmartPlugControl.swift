//
//  DinNovaSmartPlugControl.swift
//  DinCore
//
//  Created by Jin on 2021/6/2.
//

import UIKit
import DinSupport

class DinNovaSmartPlugControl: DinNovaPluginControl {

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
        case DinNovaPluginControl.CMD_ENABLE_PLUG:
            setEnable(data)
        case DinNovaPluginControl.CMD_PLUG_DETAIL:
            getDetail(data)
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
        case DinNovaPluginCommand.setSmartPlugEnable.rawValue,
             DinNovaPluginCommand.setNewSmartPlugEnable.rawValue:
            handleEnableChanged(result, failEvent: nil)
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
        case DinNovaPluginCommand.setSmartPlugEnable.rawValue,
             DinNovaPluginCommand.setNewSmartPlugEnable.rawValue:
            handleEnableChanged(nil, failEvent: event)
        default:
            break
        }
    }
}

// MARK: - 更新info
extension DinNovaSmartPlugControl {

    override func updatePluginInfo(complete: (()->())?) {
        super.updatePluginInfo {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.updateSendID((self.plugin as? DinNovaSmartPlug)?.sendid ?? "", usingSync: true, complete: nil)
                self.updateCanDetectOnline(usingSync: true, complete: nil)
                self.updateIsEnable((self.plugin as? DinNovaSmartPlug)?.isEnable ?? false, usingSync: true, complete: nil)
                self.updateTime((self.plugin as? DinNovaSmartPlug)?.time ?? 0, usingSync: true, complete: nil)
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateCanDetectOnline(usingSync sync: Bool, complete: (()->())?) {
        if sync {
            unsafeInfo["canDetectOnline"] = (plugin as? DinNovaSmartPlug)?.canDetectOnline ?? ""
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.unsafeInfo["canDetectOnline"] = (self.plugin as? DinNovaSmartPlug)?.canDetectOnline ?? ""
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateIsEnable(_ isEnable: Bool, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            (plugin as? DinNovaSmartPlug)?.isEnable = isEnable
            unsafeInfo["isEnable"] = isEnable
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                (self.plugin as? DinNovaSmartPlug)?.isEnable = isEnable
                self.unsafeInfo["isEnable"] = isEnable
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateSendID(_ sendid: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            (plugin as? DinNovaSmartPlug)?.sendid = sendid
            unsafeInfo["sendid"] = sendid
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                (self.plugin as? DinNovaSmartPlug)?.sendid = sendid
                self.unsafeInfo["sendid"] = sendid
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateTime(_ time: TimeInterval, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            (plugin as? DinNovaSmartPlug)?.time = time
            unsafeInfo["time"] = time
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                (self.plugin as? DinNovaSmartPlug)?.time = time
                self.unsafeInfo["time"] = time
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
}
