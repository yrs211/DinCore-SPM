//
//  DinNovaPanel.swift
//  DinCore
//
//  Created by Jin on 2021/5/7.
//

import UIKit
import HandyJSON

public enum DinNovaPanelArmStatus: Int {
    case arm
    case homeArm
    case disarm
}

public enum DinNovaPanelRole: Int {
    case admin = 30
    case user = 20
    case guest = 10
}

/// Nova系列的主机
public class DinNovaPanel: DinModel {

    static public let panelCategoryID = "DinNovaPanel"

    /// id
    public var id: String = ""
    /// device status
    public var online = false
    /// 名称
    public var name: String = ""
    /// 操作token
    public var token: String = ""
    /// 是否在SOS状态
    public var sos: Bool = false
    /// 布撤防状态
    public var armStatus: Int = 0
    /// 布撤防状态发生的时间
    public var armStatusTime: NSNumber = 0
    /// Sim卡
    public var simStatus: Int = 0
    /// 0:有线；1:无线
    public var netType: Int = 0
    /// 电池电量
    public var batteryLevel: Int = 100
    /// 是否插电
    public var isCharge: Bool = false
    /// 是否设置报警信息模板
    public var isMessageSet: Bool = false
    /// 键盘数量
    public var keypadAccessoryCount: Int = 0
    /// 门磁数量
    public var doorSensorCount: Int = 0
    /// 智能开关数量
    public var smartPlugCount: Int = 0
    /// smart button数量
    public var smartButtonCount: Int = 0
    /// 警笛数量
    public var sirenCount: Int = 0
    /// 遥控数量
    public var remoteControlCount: Int = 0
    /// 安防配件数量
    public var securityAccessoryCount: Int = 0
    /// 继电器数量
    public var relayAccessoryCount: Int = 0
    /// 信号中继插座数量
    public var signalRepeaterPlugCount: Int = 0
    /// 当前版本
    public var currentVersion: String = ""
    /// 延迟布防
    public var exitDelay: Int = 0
    /// 延迟报警
    public var entryDelay: Int = 0
    
    /// 表示主机当前是否处于升级状态
    public var upgrading: Bool = false
    /// 局域网IP
    public var lanIP: String = ""
    /// 时区
    public var timezone: String = ""
    /// SSID 连接WiFi的时候显示
    public var ssid: String = ""
    /// care mode 上次care mode提示时间
    public var lastNoActionTimestamp: NSNumber = 0
    /// care mode 延时报警时间
    public var careModeAlarmDelayTime: Int = 0
    /// care mode 没有生命活动的最长时间
    public var careModeNoActionTime: Int = 0
    /// 无线mac地址
    public var wifiMacAddress: String = ""
    /// 无线信号强度格数
    public var wifiRSSI: Int = 0
    /// restrict mode phone number
    public var restrictModePhone = ""
    /// device loading
    public var isLoading = false
    /// device deleted
    public var isDeleted = false

    public override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)
        mapper <<<
            self.id <-- ["device_id", "deviceid"]
        mapper <<<
            self.online <-- "online"
        mapper <<<
            self.upgrading <-- "update"
        mapper <<<
            self.sos <-- "sos"
        mapper <<<
            self.armStatus <-- "arm_state"
        mapper <<<
            self.batteryLevel <-- "battery_level"
        mapper <<<
            self.isCharge <-- "charge"
        mapper <<<
            self.simStatus <-- "sim"
        mapper <<<
            self.netType <-- "network"
        mapper <<<
            self.wifiRSSI <-- "wifi_rssi"
        mapper <<<
            self.ssid <-- "ssid"
        mapper <<<
            self.lanIP <-- "ip"
        mapper <<<
            self.wifiMacAddress <-- "wifi_mac_addr"
        mapper <<<
            self.exitDelay <-- "exitdelay"
        mapper <<<
            self.entryDelay <-- "entrydelay"
        mapper <<<
            self.timezone <-- "timezone"
        mapper <<<
            self.currentVersion <-- "firmware_version"
        mapper <<<
            self.isMessageSet <-- "has_device_text_set"

        // 修正SIM卡状态
        if netType == 2 && simStatus != 1 {
            simStatus = 1
        }
    }

    func refresh(withPanel newPanel: DinNovaPanel) {
        guard newPanel.id.count > 0 && newPanel.id != id else {
            return
        }
        token = newPanel.token
        sos = newPanel.sos
        armStatus = newPanel.armStatus
        simStatus = newPanel.simStatus
        netType = newPanel.netType
        batteryLevel = newPanel.batteryLevel
        isCharge = newPanel.isCharge
        isMessageSet = newPanel.isMessageSet
        currentVersion = newPanel.currentVersion
        exitDelay = newPanel.exitDelay
        entryDelay = newPanel.entryDelay
        upgrading = newPanel.upgrading
        lanIP = newPanel.lanIP
        timezone = newPanel.timezone
        ssid = newPanel.ssid
        lastNoActionTimestamp = newPanel.lastNoActionTimestamp
        careModeAlarmDelayTime = newPanel.careModeAlarmDelayTime
        careModeNoActionTime = newPanel.careModeNoActionTime
        wifiRSSI = newPanel.wifiRSSI
        wifiMacAddress = newPanel.wifiMacAddress
    }

    /// 更新主机的Arm状态
    /// - Parameters:
    ///   - newArmStatus: 新的Arm状态
    ///   - time: 操作的时间。若操作发生在当前状态的时间之前，不处理
    public func updateArmStatus(_ newArmStatus: Int, time: NSNumber) {
        if time.int64Value > self.armStatusTime.int64Value {
            self.armStatus = newArmStatus
            self.armStatusTime = time
            if self.armStatus == DinNovaPanelArmStatus.disarm.rawValue {
                self.sos = false
            }
        }
    }
}
