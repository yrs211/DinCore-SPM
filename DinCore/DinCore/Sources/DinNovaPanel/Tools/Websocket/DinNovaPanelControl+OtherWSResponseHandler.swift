//
//  DinNovaPanelControl+OtherWSResponseHandler.swift
//  DinCore
//
//  Created by Jin on 2021/5/19.
//

import Foundation
import DinSupport

extension DinNovaPanelControl {
    // 主机offline（ws主动通知）
    static let CMD_OFFLINE = "panel_offline"
    // 主机新的Event（ws主动通知）
    static let CMD_NEWEVENT = "panel_new_event"
    // 主机Ping相关信息（ws主动通知）
    static let CMD_PING_INFO = "panel_ping_info"
    // 主机Sim卡信息（ws主动通知）
    static let CMD_SIM_INFO = "panel_sim_info"
    // 用户权限更变
    static let CMD_USER_ROLECHANGED = "user_role_changed"
    // 看护模式，超时没有配件触发通知
    static let CMD_CAREMODE_NOACTION = "caremode_noaction"
    // 断电/接电 通知
    static let CMD_POWER_CHANGED = "panel_powerchanged"
    // 正在升级
    static let CMD_UPGRADING = "panel_upgrading"
    // 低电提醒
    static let CMD_LOWPOWER = "panel_lowpower"
    // 授权改变
    static let CMD_AUTHORITY_CHANGED = "panel_authority_changed"
    // 设备在线通知
    static let CMD_PANEL_ONLINE = "panel_online_notify"
    // 设备名字改变
    static let CMD_PANELNAME_CHANGED = "panel_set_panelname"
    // 定时任务通知
    static let CMD_TIMER_TASK = "panel_timer_task"
    // 智能跟随通知
    static let CMD_FOLLOWING_TASK = "panel_following_task"
    /// 配件上线
    static let CMD_PLUGIN_ONLINE_ALERT  = "panel_plugin_online"
    /// 配件下线
    static let CMD_PLUGIN_OFFLINE_ALERT = "panel_plugin_offline"
    /// 配件低点
    static let CMD_PLUGIN_LOWPOWER_ALERT = "panel_plugin_lowpower"

}

extension DinNovaPanelControl {
    /// 单独的回调，不用主动触发的
    func observeOtherWSResult() {
        observePanelOffline()
        observePanelNewEvent()
        observePanelPingInfo()
        observePanelSimInfo()
        observeUserRoleChangeResult()
        observeCareModeNoActionNoticeResult()
        observePowerChangedResult()
        observePanelUpgradingChanged()
        observePanelLowPower()
        observePanelAuthorityChanged()
        observePanelOnlineNotify()
        observePanelNameChanged()
        observePanelTimerTask()
        observePanelSmartFollowing()
        observePanelPluginLowPower()
        observePanelPluginOnline()
        observePanelPluginOffline()
        observePanelPluginStatus()
    }

    /// ws alert offline
    private func observePanelOffline() {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.offline.rawValue
        }.subscribe(onNext: { [weak self] (_) in
            self?.setOffline(usingSync: false, complete: nil)
        }).disposed(by: disposeBag)
    }

    /// ws receive new event from eventlist
    private func observePanelNewEvent() {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.event.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_NEWEVENT,
                                                                owner: false,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_NEWEVENT,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_NEWEVENT,
                                                            owner: false,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }

    /// ws received panel ping info
    private func observePanelPingInfo() {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.ping.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                        guard let self = self else { return }
                        let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_PING_INFO,
                                                                    owner: false,
                                                                    result: resultDict)
                        if let isCharge = resultDict["ischarge"] as? Bool {
                            self.updatePanelChargeType(isCharge, usingSync: true, complete: nil)
                        }
                        if let batteryLevel = resultDict["batterylevel"] as? Int {
                            self.updatePanelBatteryLevel(batteryLevel, usingSync: true, complete: nil)
                        }
                        if let netType = resultDict["nettype"] as? Int {
                            self.updatePanelNetType(netType, usingSync: true, complete: nil)
                        }
                        if let ipaddr = resultDict["ipaddr"] as? String {
                            self.updatePanelIP(ipaddr, usingSync: true, complete: nil)
                        }
                        if let wifiRSSI = resultDict["wifi_rssi"] as? Int {
                            self.updateWifiRSSI(wifiRSSI, usingSync: true, complete: nil)
                        }
                        DispatchQueue.global().async { [weak self] in
                            self?.accept(panelOperationResult: returnDict)
                        }
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PING_INFO,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PING_INFO,
                                                            owner: false,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }

    /// ws received panel sim info
    private func observePanelSimInfo() {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.sim.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result),
                    let simStatus = resultDict["sim"] as? Int {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SIM_INFO,
                                                                owner: false,
                                                                result: resultDict)
                    self.updatePanelSimStatus(simStatus, usingSync: false) { [weak self] in
                        self?.accept(panelOperationResult: returnDict)
                }
                } else if let simStatus = Int(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SIM_INFO,
                                                                owner: false,
                                                                result: [:])
                    self.updatePanelSimStatus(simStatus, usingSync: false) { [weak self] in
                        self?.accept(panelOperationResult: returnDict)
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SIM_INFO,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SIM_INFO,
                                                            owner: false,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }

    /// 用户权限变化
    private func observeUserRoleChangeResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.roleChanged.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result),
                    let role = resultDict["newpermission"] as? Int {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_USER_ROLECHANGED,
                                                                owner: false,
                                                                result: resultDict)
//                    self.updateRole(role, usingSync: false) { [weak self] in
                    self.accept(panelOperationResult: returnDict)
//                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_USER_ROLECHANGED,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_USER_ROLECHANGED,
                                                            owner: false,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }

    /// 看护模式，超时没有配件触发通知
    private func observeCareModeNoActionNoticeResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.careModeNoActionNotice.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result),
                   let alarmDelayTime = resultDict["alarm_delay_time"] as? Int,
                   let noActionTime = resultDict["no_action_time"] as? Int,
                   let lastNoActionTimestamp = resultDict["last_no_action_time"] as? NSNumber {
                        let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_CAREMODE_NOACTION,
                                                                    owner: false,
                                                                    result: resultDict)
                        DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                            guard let self = self else { return }
                            self.updatePanelLastNoActionTimestamp(lastNoActionTimestamp, usingSync: true, complete: nil)
                            self.updatePanelCareModeAlarmDelayTime(alarmDelayTime, usingSync: true, complete: nil)
                            self.updatePanelCareModeNoActionTime(noActionTime, usingSync: true, complete: nil)
                            DispatchQueue.global().async { [weak self] in
                                self?.accept(panelOperationResult: returnDict)
                            }
                        }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_CAREMODE_NOACTION,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_CAREMODE_NOACTION,
                                                            owner: false,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }

    /// 断电/接电 通知
    private func observePowerChangedResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.powerChanged.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result),
                    let isCharge = resultDict["ischarge"] as? Bool {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_POWER_CHANGED,
                                                                owner: false,
                                                                result: resultDict)
                    self.updatePanelChargeType(isCharge, usingSync: false) { [weak self] in
                        self?.accept(panelOperationResult: returnDict)
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_POWER_CHANGED,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_POWER_CHANGED,
                                                            owner: false,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }

    /// 正在升级
    private func observePanelUpgradingChanged()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.deviceUpgrading.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_UPGRADING,
                                                                owner: false,
                                                                result: resultDict)
                    self.updatePanelUpgradeStatus(true, usingSync: false) { [weak self] in
                        self?.accept(panelOperationResult: returnDict)
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_UPGRADING,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_UPGRADING,
                                                            owner: false,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }

    /// 低电提醒
    private func observePanelLowPower()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.deviceLowPower.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_LOWPOWER,
                                                                owner: false,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_LOWPOWER,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_LOWPOWER,
                                                            owner: false,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }

    /// 授权改变
    private func observePanelAuthorityChanged()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.authorityChanged.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_AUTHORITY_CHANGED,
                                                                owner: false,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_AUTHORITY_CHANGED,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_AUTHORITY_CHANGED,
                                                            owner: false,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }

    /// 设备在线通知
    private func observePanelOnlineNotify()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.online.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_PANEL_ONLINE,
                                                                owner: false,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PANEL_ONLINE,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PANEL_ONLINE,
                                                            owner: false,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }

    /// 设备名字改变
    private func observePanelNameChanged()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.setDeviceName.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result),
                    let deviceid = resultDict["deviceid"] as? String,
                    let deviceName = resultDict["name"] as? String,
                    deviceid == self.panel.id, deviceName.count > 0 {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_PANELNAME_CHANGED,
                                                                owner: false,
                                                                result: resultDict)
                    self.updatePanelName(deviceName, usingSync: false) { [weak self] in
                        self?.accept(panelOperationResult: returnDict)
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PANELNAME_CHANGED,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PANELNAME_CHANGED,
                                                            owner: false,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }

    /// 定时任务通知
    private func observePanelTimerTask()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.timerTask.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_TIMER_TASK,
                                                                owner: false,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_TIMER_TASK,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_TIMER_TASK,
                                                            owner: false,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }

    /// 智能跟随通知
    private func observePanelSmartFollowing()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.followingTask.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_FOLLOWING_TASK,
                                                                owner: false,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_FOLLOWING_TASK,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_FOLLOWING_TASK,
                                                            owner: false,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }

    /// 主机的配件低电通知
    private func observePanelPluginLowPower()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPluginCommand.pluginLowPower.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_LOWPOWER_ALERT,
                                                                owner: false,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_LOWPOWER_ALERT,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_LOWPOWER_ALERT,
                                                            owner: false,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }

    /// 配件的在线提醒
    private func observePanelPluginOnline()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPluginCommand.pluginOnline.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_ONLINE_ALERT,
                                                                owner: false,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_ONLINE_ALERT,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_ONLINE_ALERT,
                                                            owner: false,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }

    /// 主机配件离线通知
    private func observePanelPluginOffline()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPluginCommand.pluginOffline.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_OFFLINE_ALERT,
                                                                owner: false,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_OFFLINE_ALERT,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_OFFLINE_ALERT,
                                                            owner: false,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }

    /// 主机配件状态通知
    private func observePanelPluginStatus()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPluginCommand.pluginEnableState.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPluginControl.CMD_DOOR_WINDOW_SENSOR_STATUS_CHANGED,
                                                                owner: false,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_DOOR_WINDOW_SENSOR_STATUS_CHANGED,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPluginControl.CMD_DOOR_WINDOW_SENSOR_STATUS_CHANGED,
                                                            owner: false,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
}
