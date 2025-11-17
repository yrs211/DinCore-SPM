//
//  DinNovaPanelControl+InfoHandler.swift
//  DinCore
//
//  Created by AdrianHor on 2023/2/22.
//

import Foundation

// MARK: - 主机连接状态相关
extension DinNovaPanelControl {
    /// 刷新设备重连ws，更新info即可，无需通知上层
    private func refreshPanel() {
        updatePanelInfo(complete: nil)
    }
}

// MARK: - 修改Info字典信息
extension DinNovaPanelControl {
    func updatePanelInfo(complete: (()->())?) {
        DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.updatePanelID(self.panel.id, usingSync: true, complete: nil)
            self.updateIsOnline(self.panel.online, usingSync: true, complete: nil)
            self.updateWSConnection(usingSync: true, complete: nil)
            self.updateArmStatus(self.panel.armStatus, usingSync: true, complete: nil)
            self.updateSOS(self.panel.sos, usingSync: true, complete: nil)
//            self.updateRole(self.panel.role, usingSync: true, complete: nil)
            self.updateExitDelay(self.panel.exitDelay, usingSync: true, complete: nil)
            self.updateEntryDelay(self.panel.entryDelay, usingSync: true, complete: nil)
            self.updateMessageSet(self.panel.isMessageSet, usingSync: true, complete: nil)
            self.updateTimezone(self.panel.timezone, usingSync: true, complete: nil)
            self.updatePanelName(self.panel.name, usingSync: true, complete: nil)
            self.updatePanelBatteryLevel(self.panel.batteryLevel, usingSync: true, complete: nil)
            self.updatePanelChargeType(self.panel.isCharge, usingSync: true, complete: nil)
            self.updatePanelNetType(self.panel.netType, usingSync: true, complete: nil)
            self.updatePanelIP(self.panel.lanIP, usingSync: true, complete: nil)
            self.updatePanelSimStatus(self.panel.simStatus, usingSync: true, complete: nil)
            self.updatePanelUpgradeStatus(self.panel.upgrading, usingSync: true, complete: nil)
            self.updatePanelToken(self.panel.token, usingSync: true, complete: nil)
            self.updatePanelSSID(self.panel.ssid, usingSync: true, complete: nil)
            // 更新设备配件数量
            self.updatePanelSecurityAccessoryCount(self.panel.securityAccessoryCount, usingSync: true, complete: nil)
            self.updatePanelRemoteControlCount(self.panel.remoteControlCount, usingSync: true, complete: nil)
            self.updatePanelKeypadAccessoryCount(self.panel.keypadAccessoryCount, usingSync: true, complete: nil)
            self.updatePanelSmartButtonCount(self.panel.smartButtonCount, usingSync: true, complete: nil)
            self.updatePanelDoorSensorCount(self.panel.doorSensorCount, usingSync: true, complete: nil)
            self.updatePanelSmartPlugCount(self.panel.smartPlugCount, usingSync: true, complete: nil)
            self.updatePanelSirenCount(self.panel.sirenCount, usingSync: true, complete: nil)
            self.updatePanelRelayAccessoryCount(self.panel.relayAccessoryCount, usingSync: true, complete: nil)
            self.updatePanelSignalRepeaterPlugCount(self.panel.signalRepeaterPlugCount, usingSync: true, complete: nil)
            self.updatePanelVersion(self.panel.currentVersion, usingSync: true, complete: nil)
            // caremode
            self.updatePanelLastNoActionTimestamp(self.panel.lastNoActionTimestamp, usingSync: true, complete: nil)
            self.updatePanelCareModeNoActionTime(self.panel.careModeNoActionTime, usingSync: true, complete: nil)
            self.updatePanelCareModeAlarmDelayTime(self.panel.careModeAlarmDelayTime, usingSync: true, complete: nil)

            self.updateWifiRSSI(self.panel.wifiRSSI, usingSync: true, complete: nil)
            self.updateWifiMacAddress(self.panel.wifiMacAddress, usingSync: true, complete: nil)

            // restrict mode phone number
            self.updatePanelRestrictModePhone(self.panel.restrictModePhone, usingSync: true, complete: nil)
            // is device loading
            self.updateIsLoading(self.panel.isLoading, usingSync: true, complete: nil)
            self.updateIsDeleted(self.panel.isDeleted, usingSync: true, complete: nil)

            DispatchQueue.global().async {
                complete?()
            }
        }
    }

    func updatePanelID(_ panelID: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.id = panelID
            unsafeInfo[DinNovaPanelControl.panelIDInfoKey] = panelID
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.id = panelID
                self.unsafeInfo[DinNovaPanelControl.panelIDInfoKey] = panelID
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// panel的ws连接状况 connection
    /// - Parameters:
    ///   - alert: 通知上层
    ///   - inOtherQueue: 是否需要独立线程处理
    func updateIsOnline(_ online: Bool,
                        usingSync sync: Bool,
                        complete: (()->())?,
                        alert: Bool = true) {
        if sync {
            panel.online = online
            unsafeInfo[DinNovaPanelControl.isOnlineInfoKey] = online
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.online = online
                self.unsafeInfo[DinNovaPanelControl.isOnlineInfoKey] = online
                // 防止通过 DinUser.homeDeviceInfoQueue 出去，然后在DinUser.homeDeviceInfoQueue里面请求info
                // 导致 async 和 sync 之间冲突
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    /// panel的ws连接状况 connection
    func updateWSConnection(usingSync sync: Bool, complete: (()->())?) {
        if sync {
            unsafeInfo[DinNovaPanelControl.connectionInfoKey] = panelWSConnectionState.rawValue
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.unsafeInfo[DinNovaPanelControl.connectionInfoKey] = self.panelWSConnectionState.rawValue
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// panel的布防状态。0 : arm状态 1 : home arm状态 2 : disarm状态 3 : 自定义场景模式状态
    func updateArmStatus(_ armStatus: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.armStatus = armStatus
            unsafeInfo[DinNovaPanelControl.armStatusInfoKey] = armStatus
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.armStatus = armStatus
                self.unsafeInfo[DinNovaPanelControl.armStatusInfoKey] = armStatus
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// panel的sos状态
    func updateSOS(_ sos: Bool, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.sos = sos
            unsafeInfo[DinNovaPanelControl.sosInfoKey] = sos
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.sos = sos
                self.unsafeInfo[DinNovaPanelControl.sosInfoKey] = sos
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 用户权限, 10:guest, 20:user, 30:admin
//    func updateRole(_ role: Int, usingSync sync: Bool, complete: (()->())?) {
//        if sync {
//            panel.role = role
//            unsafeInfo[DinNovaPanelControl.roleInfoKey] = role
//        } else {
//            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
//                guard let self = self else { return }
//                self.panel.role = role
//                self.unsafeInfo[DinNovaPanelControl.roleInfoKey] = role
//                DispatchQueue.global().async {
//                    complete?()
//                }
//            }
//        }
//    }

    /// panel的延迟布防字段
    func updateExitDelay(_ exitDelay: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.exitDelay = exitDelay
            unsafeInfo[DinNovaPanelControl.exitDelayInfoKey] = exitDelay
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.exitDelay = exitDelay
                self.unsafeInfo[DinNovaPanelControl.exitDelayInfoKey] = exitDelay
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// panel的延迟报警字段
    func updateEntryDelay(_ entryDelay: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.entryDelay = entryDelay
            unsafeInfo[DinNovaPanelControl.entryDelayInfoKey] = entryDelay
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.entryDelay = entryDelay
                self.unsafeInfo[DinNovaPanelControl.entryDelayInfoKey] = entryDelay
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新 设置通知的短信，push内容标识
    func updateMessageSet(_ isMessageSet: Bool, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.isMessageSet = isMessageSet
            unsafeInfo[DinNovaPanelControl.isMessageSetInfoKey] = isMessageSet
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.isMessageSet = isMessageSet
                self.unsafeInfo[DinNovaPanelControl.isMessageSetInfoKey] = isMessageSet
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新时区字段
    func updateTimezone(_ timezone: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.timezone = timezone
            unsafeInfo[DinNovaPanelControl.timezoneInfoKey] = timezone
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.timezone = timezone
                self.unsafeInfo[DinNovaPanelControl.timezoneInfoKey] = timezone
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新主机名字
    func updatePanelName(_ name: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.name = name
            unsafeInfo[DinNovaPanelControl.nameInfoKey] = name
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.name = name
                self.unsafeInfo[DinNovaPanelControl.nameInfoKey] = name
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新电源类型
    func updatePanelChargeType(_ isCharge: Bool, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.isCharge = isCharge
            unsafeInfo[DinNovaPanelControl.isChargeInfoKey] = isCharge
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.isCharge = isCharge
                self.unsafeInfo[DinNovaPanelControl.isChargeInfoKey] = isCharge
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新电量数值0~100
    func updatePanelBatteryLevel(_ batteryLevel: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.batteryLevel = batteryLevel
            unsafeInfo[DinNovaPanelControl.batteryLevelInfoKey] = batteryLevel
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.batteryLevel = batteryLevel
                self.unsafeInfo[DinNovaPanelControl.batteryLevelInfoKey] = batteryLevel
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新主机网络类型：有线、无线
    func updatePanelNetType(_ netType: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.netType = netType
            unsafeInfo[DinNovaPanelControl.netTypeInfoKey] = netType
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.netType = netType
                self.unsafeInfo[DinNovaPanelControl.netTypeInfoKey] = netType
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新主机IP
    func updatePanelIP(_ lanIP: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.lanIP = lanIP
            unsafeInfo[DinNovaPanelControl.lanIPInfoKey] = lanIP
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.lanIP = lanIP
                self.unsafeInfo[DinNovaPanelControl.lanIPInfoKey] = lanIP
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新Sim卡状态
    func updatePanelSimStatus(_ simStatus: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.simStatus = simStatus
            unsafeInfo[DinNovaPanelControl.simStatusInfoKey] = simStatus
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.simStatus = simStatus
                self.unsafeInfo[DinNovaPanelControl.simStatusInfoKey] = simStatus
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新UpGrade状态
    func updatePanelUpgradeStatus(_ upgrading: Bool, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.upgrading = upgrading
            unsafeInfo[DinNovaPanelControl.upgradeStatusInfoKey] = upgrading
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.upgrading = upgrading
                self.unsafeInfo[DinNovaPanelControl.upgradeStatusInfoKey] = upgrading
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新设备token
    func updatePanelToken(_ token: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.token = token
            unsafeInfo[DinNovaPanelControl.deviceTokenInfoKey] = token
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.token = token
                self.unsafeInfo[DinNovaPanelControl.deviceTokenInfoKey] = token
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    /// 更新设备SSID
    func updatePanelSSID(_ ssid: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.ssid = ssid
            unsafeInfo[DinNovaPanelControl.ssidInfoKey] = ssid
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.ssid = ssid
                self.unsafeInfo[DinNovaPanelControl.ssidInfoKey] = ssid
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新设备安防配件
    func updatePanelSecurityAccessoryCount(_ securityAccessoryCount: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.securityAccessoryCount = securityAccessoryCount
            unsafeInfo[DinNovaPanelControl.securityAccessoryCountInfoKey] = securityAccessoryCount
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.securityAccessoryCount = securityAccessoryCount
                self.unsafeInfo[DinNovaPanelControl.securityAccessoryCountInfoKey] = securityAccessoryCount
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新设备遥控数量
    func updatePanelRemoteControlCount(_ remoteControlCount: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.remoteControlCount = remoteControlCount
            unsafeInfo[DinNovaPanelControl.remoteControlCountInfoKey] = remoteControlCount
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.remoteControlCount = remoteControlCount
                self.unsafeInfo[DinNovaPanelControl.remoteControlCountInfoKey] = remoteControlCount
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新设备 键盘/RFID卡数量
    func updatePanelKeypadAccessoryCount(_ keypadAccessoryCount: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.keypadAccessoryCount = keypadAccessoryCount
            unsafeInfo[DinNovaPanelControl.keypadAccessoryCountInfoKey] = keypadAccessoryCount
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.keypadAccessoryCount = keypadAccessoryCount
                self.unsafeInfo[DinNovaPanelControl.keypadAccessoryCountInfoKey] = keypadAccessoryCount
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新设备智能按钮数量
    func updatePanelSmartButtonCount(_ smartButtonCount: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.smartButtonCount = smartButtonCount
            unsafeInfo[DinNovaPanelControl.smartButtonCountInfoKey] = smartButtonCount
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.smartButtonCount = smartButtonCount
                self.unsafeInfo[DinNovaPanelControl.smartButtonCountInfoKey] = smartButtonCount
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新设备门窗探测器数量
    func updatePanelDoorSensorCount(_ doorSensorCount: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.doorSensorCount = doorSensorCount
            unsafeInfo[DinNovaPanelControl.doorSensorCountInfoKey] = doorSensorCount
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.doorSensorCount = doorSensorCount
                self.unsafeInfo[DinNovaPanelControl.doorSensorCountInfoKey] = doorSensorCount
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新设备只能插座数量
    func updatePanelSmartPlugCount(_ smartPlugCount: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.smartPlugCount = smartPlugCount
            unsafeInfo[DinNovaPanelControl.SmartPlugCountInfoKey] = smartPlugCount
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.smartPlugCount = smartPlugCount
                self.unsafeInfo[DinNovaPanelControl.SmartPlugCountInfoKey] = smartPlugCount
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新设备无线警笛数量
    func updatePanelSirenCount(_ sirenCount: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.sirenCount = sirenCount
            unsafeInfo[DinNovaPanelControl.sirenCountInfoKey] = sirenCount
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.sirenCount = sirenCount
                self.unsafeInfo[DinNovaPanelControl.sirenCountInfoKey] = sirenCount
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新设备继电器数量
    func updatePanelRelayAccessoryCount(_ relayAccessoryCount: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.relayAccessoryCount = relayAccessoryCount
            unsafeInfo[DinNovaPanelControl.relayAccessoryCountInfoKey] = relayAccessoryCount
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.relayAccessoryCount = relayAccessoryCount
                self.unsafeInfo[DinNovaPanelControl.relayAccessoryCountInfoKey] = relayAccessoryCount
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    /// 更新设备中继插座数量
    func updatePanelSignalRepeaterPlugCount(_ signalRepeaterPlugCount: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.signalRepeaterPlugCount = signalRepeaterPlugCount
            unsafeInfo[DinNovaPanelControl.signalRepeaterPlugCountInfoKey] = signalRepeaterPlugCount
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.signalRepeaterPlugCount = signalRepeaterPlugCount
                self.unsafeInfo[DinNovaPanelControl.signalRepeaterPlugCountInfoKey] = signalRepeaterPlugCount
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新设备版本信息
    func updatePanelVersion(_ currentVersion: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.currentVersion = currentVersion
            unsafeInfo[DinNovaPanelControl.curVersionKey] = currentVersion
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.currentVersion = currentVersion
                self.unsafeInfo[DinNovaPanelControl.curVersionKey] = currentVersion
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新care mode 上次care mode提示时间
    func updatePanelLastNoActionTimestamp(_ lastNoActionTimestamp: NSNumber, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.lastNoActionTimestamp = lastNoActionTimestamp
            unsafeInfo[DinNovaPanelControl.lastNoActionTimestampKey] = Int64(lastNoActionTimestamp.intValue) / 1000000000
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.lastNoActionTimestamp = lastNoActionTimestamp
                self.unsafeInfo[DinNovaPanelControl.lastNoActionTimestampKey] = Int64(lastNoActionTimestamp.intValue) / 1000000000
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新care mode 延时报警时间
    func updatePanelCareModeAlarmDelayTime(_ careModeAlarmDelayTime: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.careModeAlarmDelayTime = careModeAlarmDelayTime
            unsafeInfo[DinNovaPanelControl.careModeAlarmDelayTimeKey] = careModeAlarmDelayTime
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.careModeAlarmDelayTime = careModeAlarmDelayTime
                self.unsafeInfo[DinNovaPanelControl.careModeAlarmDelayTimeKey] = careModeAlarmDelayTime
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新care mode 没有生命活动的最长时间
    func updatePanelCareModeNoActionTime(_ careModeNoActionTime: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.careModeNoActionTime = careModeNoActionTime
            unsafeInfo[DinNovaPanelControl.careModeNoActionTimeKey] = careModeNoActionTime
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.careModeNoActionTime = careModeNoActionTime
                self.unsafeInfo[DinNovaPanelControl.careModeNoActionTimeKey] = careModeNoActionTime
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新wifi signal
    func updateWifiRSSI(_ wifiRSSI: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.wifiRSSI = wifiRSSI
            unsafeInfo[DinNovaPanelControl.wifiRSSIKey] = wifiRSSI
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.wifiRSSI = wifiRSSI
                self.unsafeInfo[DinNovaPanelControl.wifiRSSIKey] = wifiRSSI
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新mac address
    func updateWifiMacAddress(_ wifiMacAddress: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.wifiMacAddress = wifiMacAddress
            unsafeInfo[DinNovaPanelControl.wifiMacAddressKey] = wifiMacAddress
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.wifiMacAddress = wifiMacAddress
                self.unsafeInfo[DinNovaPanelControl.wifiMacAddressKey] = wifiMacAddress
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// 更新restrict mode phone number
    func updatePanelRestrictModePhone(_ restrictModePhone: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.restrictModePhone = restrictModePhone
            unsafeInfo[DinNovaPanelControl.restrictModePhoneKey] = restrictModePhone
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.restrictModePhone = restrictModePhone
                self.unsafeInfo[DinNovaPanelControl.restrictModePhoneKey] = restrictModePhone
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// is device loading
    func updateIsLoading(_ isLoading: Bool, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            panel.isLoading = isLoading
            unsafeInfo[DinNovaPanelControl.loadingKey] = isLoading
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.isLoading = isLoading
                self.unsafeInfo[DinNovaPanelControl.loadingKey] = isLoading
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    /// is device deleted
    func updateIsDeleted(_ isDeleted: Bool, usingSync sync: Bool, complete: (() -> ())?) {
        if sync {
            panel.isDeleted = isDeleted
            unsafeInfo[DinNovaPanelControl.deletedKey] = isDeleted
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.isDeleted = isDeleted
                self.unsafeInfo[DinNovaPanelControl.deletedKey] = isDeleted
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
}


