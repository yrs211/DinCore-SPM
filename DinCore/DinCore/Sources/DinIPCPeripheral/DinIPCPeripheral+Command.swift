//
//  DinIPCPeripheral+Command.swift
//  DinCore
//
//  Created by Monsoir on 2021/6/24.
//

import Foundation

extension DinIPCPeripheral {

    enum KeyRawValue {
        static let cmd = "cmd"
        fileprivate static let data = "data"
        fileprivate static let modify = "modify"
        fileprivate static let timezone = "tz"
    }

    /// 设置 App ID
    @discardableResult
    public func setAppID(_ appID: String) -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.setAppID.rawValue,
            KeyRawValue.data: appID,
        ]

        return send(rawData)
    }

    /// 设置 App key
    @discardableResult
    public func setAppKey(_ appKey: String) -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.setAppKey.rawValue,
            KeyRawValue.data: appKey,
        ]

        return send(rawData)
    }

    /// 设置 App Secret
    @discardableResult
    public func setAppSecret(_ appSerect: String) -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.setAppSecret.rawValue,
            KeyRawValue.data: appSerect,
        ]

        return send(rawData)
    }

    /// 设置 HTTP Host
    @discardableResult
    public func setHTTPHost(_ host: String) -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.setHTTPHost.rawValue,
            KeyRawValue.data: host,
        ]

        return send(rawData)
    }

    /// 设置 UDP Host
    @discardableResult
    public func setUDPHost(_ host: String) -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.setUDPHost.rawValue,
            KeyRawValue.data: host,
        ]

        return send(rawData)
    }

    /// 设置家庭 ID
    @discardableResult
    public func setFamilyID(_ familyID: String) -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.setFamilyID.rawValue,
            KeyRawValue.data: familyID,
        ]

        return send(rawData)
    }

    /// 设置设备名称
    @discardableResult
    public func setDeviceName(_ deviceName: String) -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.setDeviceName.rawValue,
            KeyRawValue.data: deviceName,
        ]

        return send(rawData)
    }

    /// 获取 Wi-Fi 列表
    @discardableResult
    public func getWifiList() -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.getWifiList.rawValue,
        ]

        return send(rawData)
    }

    /// 设置 Wi-Fi SSID
    @discardableResult
    public func setWifiSSID(_ ssid: String) -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.setWifiSSID.rawValue,
            KeyRawValue.data: ssid,
        ]

        return send(rawData)
    }

    /// 设置 Wi-Fi 密码
    @discardableResult
    public func setWifiPassword(_ password: String) -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.setWifiPassword.rawValue,
            KeyRawValue.data: password,
        ]

        return send(rawData)
    }

    /// 开始配网
    @discardableResult
    public func initialNetwork() -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.initialNetwork.rawValue,
        ]

        return send(rawData)
    }

    /// 修改网络
    @discardableResult
    public func modifyNetwork() -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.initialNetwork.rawValue,
            KeyRawValue.modify: 1,
        ]

        return send(rawData)
    }

    /// 注册设备
    @discardableResult
    public func register() -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.register.rawValue,
        ]

        return send(rawData)
    }

    /// 获取 end id
    @discardableResult
    public func getEndID() -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.getEndID.rawValue,
        ]

        return send(rawData)
    }

    /// 获取固件版本
    @discardableResult
    public func getFirmwareVersion() -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.getFirmwareVersion.rawValue,
        ]

        return send(rawData)
    }

    /// 设置时区
    @discardableResult
    public func setTimezone(timezoneString: String) -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.setTimezone.rawValue,
            KeyRawValue.timezone: timezoneString,
        ]

        return send(rawData)
    }

    /// 更新配置
    @discardableResult
    public func updateConfig() -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.updateConfig.rawValue,
        ]

        return send(rawData)
    }
}
