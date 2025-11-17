//
//  DinNovaDoorWindowSensorControl.swift
//  DinCore
//
//  Created by Jin on 2021/5/28.
//

import UIKit
import DinSupport

class DinNovaDoorWindowSensorControl: DinNovaPluginControl {

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
        case DinNovaPluginControl.CMD_PLUG_DETAIL:
            getDetail(data)
        case DinNovaPluginControl.CMD_PLUG_DELETEBINDCONFIG:
            deleteConfig(data)
        case DinNovaPluginControl.CMD_PLUG_UPDATEBINDCONFIG:
            setConfig(data)
        case DinNovaPluginControl.CMD_SET_DOOR_WINDOW_PUSH_STATUS:
            configDoorWindowPushStatus(data)
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
        case DinNovaPluginCommand.setPluginBlock.rawValue:
            handleBlockConfig(result, failEvent: nil)
        case DinNovaPluginCommand.updatePluginConfig.rawValue:
            handleUpdatedConfig(result, failEvent: nil)
        case DinNovaPluginCommand.setDoorWindowPushStatus.rawValue:
            handleSettingDoorWindowPushStatus(result, failEvent: nil)
        case DinNovaPluginCommand.pluginEnableState.rawValue:
            handleDoorWindowSensorStatusChanged(result, failEvent: nil)
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
        case DinNovaPluginCommand.setDoorWindowPushStatus.rawValue:
            handleSettingDoorWindowPushStatus(nil, failEvent: event)
        default:
            break
        }
    }
}

// MARK: - 更新info
extension DinNovaDoorWindowSensorControl {
    override func updatePluginInfo(complete: (()->())?) {
        super.updatePluginInfo { 
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.updateCanDetectOnline(usingSync: true, complete: nil)
                self.updateIsApart((self.plugin as? DinNovaDoorWindowSensor)?.isApart ?? false, usingSync: true, complete: nil)
                self.updateCanDetectApart(usingSync: true, complete: nil)
                self.updateBlock((self.plugin as? DinNovaDoorWindowSensor)?.block ?? -1, usingSync: true, complete: nil)
                self.updateSendID((self.plugin as? DinNovaDoorWindowSensor)?.sendid ?? "", usingSync: true, complete: nil)
                self.updateTime((self.plugin as? DinNovaDoorWindowSensor)?.time ?? 0, usingSync: true, complete: nil)
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateCanDetectOnline(usingSync sync: Bool, complete: (()->())?) {
        if sync {
            unsafeInfo["canDetectOnline"] = (plugin as? DinNovaDoorWindowSensor)?.canDetectOnline ?? false
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.unsafeInfo["canDetectOnline"] = (self.plugin as? DinNovaDoorWindowSensor)?.canDetectOnline ?? false
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateIsApart(_ isApart: Bool, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            (plugin as? DinNovaDoorWindowSensor)?.isApart = isApart
            unsafeInfo["isApart"] = isApart
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                (self.plugin as? DinNovaDoorWindowSensor)?.isApart = isApart
                self.unsafeInfo["isApart"] = isApart
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    func updateCanDetectApart(usingSync sync: Bool, complete: (()->())?) {
        if sync {
            unsafeInfo["canDetectApart"] = (plugin as? DinNovaDoorWindowSensor)?.canDetectApart ?? false
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.unsafeInfo["canDetectApart"] = (self.plugin as? DinNovaDoorWindowSensor)?.canDetectApart ?? false
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateBlock(_ block: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            (plugin as? DinNovaDoorWindowSensor)?.block = block
            unsafeInfo["block"] = block
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                (self.plugin as? DinNovaDoorWindowSensor)?.block = block
                self.unsafeInfo["block"] = block
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateSendID(_ sendid: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            (plugin as? DinNovaDoorWindowSensor)?.sendid = sendid
            unsafeInfo["sendid"] = sendid
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                (self.plugin as? DinNovaDoorWindowSensor)?.sendid = sendid
                self.unsafeInfo["sendid"] = sendid
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateTime(_ time: TimeInterval, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            (plugin as? DinNovaDoorWindowSensor)?.time = time
            unsafeInfo["time"] = time
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                (self.plugin as? DinNovaDoorWindowSensor)?.time = time
                self.unsafeInfo["time"] = time
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
}
