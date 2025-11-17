//
//  DinNovaPanelControl+InfoKey.swift
//  DinCore
//
//  Created by AdrianHor on 2023/2/22.
//

import Foundation

/// Info字段
extension DinNovaPanelControl {
    static let panelIDInfoKey = "panelID"
    static let isOnlineInfoKey = "isOnline"
    static let connectionInfoKey = "connection"
    static let armStatusInfoKey = "armStatus"
    static let sosInfoKey = "sos"
    static let roleInfoKey = "role"
    static let exitDelayInfoKey = "exitDelay"
    static let entryDelayInfoKey = "entryDelay"
    static let isMessageSetInfoKey = "isMessageSet"
    static let timezoneInfoKey = "timezone"
    static let nameInfoKey = "name"
    static let isChargeInfoKey = "isCharge"
    static let batteryLevelInfoKey = "batteryLevel"
    static let netTypeInfoKey = "netType"
    static let lanIPInfoKey = "lanIP"
    static let simStatusInfoKey = "simStatus"
    static let upgradeStatusInfoKey = "upgrading"
    static let deviceTokenInfoKey = "deviceToken"
    static let ssidInfoKey = "ssid"

    static let securityAccessoryCountInfoKey = "securityAccessoryCount"
    static let remoteControlCountInfoKey = "remoteControlCount"
    static let keypadAccessoryCountInfoKey = "keypadAccessoryCount"
    static let ipCameraCountInfoKey = "ipCameraCount"
    static let smartButtonCountInfoKey = "smartButtonCount"
    static let doorSensorCountInfoKey = "doorSensorCount"
    static let SmartPlugCountInfoKey = "smartPlugCount"
    static let sirenCountInfoKey = "sirenCount"
    static let relayAccessoryCountInfoKey = "relayAccessoryCount"
    static let signalRepeaterPlugCountInfoKey = "signalRepeaterPlugCount"
    static let memberCountInfoKey = "memberCount"

    static let membersInfoKey = "memberInfos"
    static let curVersionKey = "curVersion"

    static let lastNoActionTimestampKey = "lastNoActionTimestamp"
    static let careModeAlarmDelayTimeKey = "careModeAlarmDelayTime"
    static let careModeNoActionTimeKey = "careModeNoActionTime"

    static let wifiRSSIKey = "wifiRSSI"
    static let wifiMacAddressKey = "wifiMacAddress"

    // restrict mode phone number
    static let restrictModePhoneKey = "restrictModePhone"
    // is device loading
    static let loadingKey = "isLoading"
    // is device deleted
    static let deletedKey = "isDeleted"
}
