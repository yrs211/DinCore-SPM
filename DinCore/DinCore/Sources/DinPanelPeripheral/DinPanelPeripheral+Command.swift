//
//  DinPanelPeripheral+Command.swift
//  DinCore
//
//  Created by monsoir on 6/8/21.
//

import Foundation

extension DinPanelPeripheral {

    enum KeyRawValue {
        static let cmd = "cmd"
        fileprivate static let name = "name"
        fileprivate static let password = "password"
        fileprivate static let uid = "uid"
        fileprivate static let userID = "userid"
        fileprivate static let homeID = "home_id"
        fileprivate static let system = "system"
        fileprivate static let ip = "ip"
        fileprivate static let netmask = "netmask"
        fileprivate static let gateway = "gateway"
        fileprivate static let dns = "dns"

        /* def 以下的 key, 由于需要尽量压缩蓝牙数据大小，因此都使用了简称 */

        fileprivate static let set4GAutomatically = "a"
        fileprivate static let set4GNodeName = "n"
        fileprivate static let set4GUserName = "u"
        fileprivate static let set4GPassword = "p"

        /* end 以下的 key, 由于需要尽量压缩蓝牙数据大小，因此都使用了简称 */

        fileprivate static let set4GHomeID = "home_id"
        fileprivate static let set4GUserID = "userid"
    }

    /// 设置名称
    @discardableResult
    public func setName(_ name: String) -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.setDeviceName.rawValue,
            KeyRawValue.name: name,
        ]

        return send(rawData)
    }

    /// 设置密码
    @discardableResult
    public func setPassword(_ password: String) -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.setDevicePassword.rawValue,
            KeyRawValue.password:password,
        ]

        return send(rawData)
    }

    /// 验证主机密码
    @discardableResult
    public func verifyPassword(_ password: String) -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.verifyDevicePassword.rawValue,
            KeyRawValue.password: password,
        ]

        return send(rawData)
    }

    /// 绑定设备
    @discardableResult
    public func bindDevice(config: BindConfig) -> ExecutionToken? {
        var rawData: SendingRawData = [
            KeyRawValue.cmd: Command.bindDevice.rawValue,
        ]

        switch config.style {
        case .user(let uid):
            rawData[KeyRawValue.uid] = uid
        case .family(let userID, let homeID):
            rawData[KeyRawValue.userID] = userID
            rawData[KeyRawValue.homeID] = homeID
        }

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
    
    /// 请求判断是否4G主机
    @discardableResult
    public func checkIf4GPanel() -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.get4G.rawValue,
        ]

        return send(rawData)
    }
    

    /// 设置 Wi-Fi 名称
    @discardableResult
    public func setWifiName(_ name: String) -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.setWifiName.rawValue,
            KeyRawValue.name: name,
        ]

        return send(rawData)
    }

    /// 设置 Wi-Fi 密码
    @discardableResult
    public func setWifiPassword(_ password: String) -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.setWifiPassword.rawValue,
            KeyRawValue.password: password,
        ]

        return send(rawData)
    }

    public enum BindConfigStyle {
        case user(uid: String)
        case family(userID: String, homeID: String)
    }

    /// 主机开始配置网络的配置
    public struct BindConfig {
        public let style: BindConfigStyle
        public let clientDeviceModel: String
        public let clientDeviceSystemVersion: String

        var clientSystemInfoString: String { "\(clientDeviceModel) / \(clientDeviceSystemVersion)" }

        public init(
            style: BindConfigStyle,
            clientDeviceModel: String,
            clientDeviceSystemVersion: String
        ) {
            self.style = style
            self.clientDeviceModel = clientDeviceModel
            self.clientDeviceSystemVersion = clientDeviceSystemVersion
        }
    }

    /// 主机开始配置 Wi-Fi
    /// - 需要先调用 `setWifiName(_ name:)` 和 `setWifiPassword(_ password:)` 方法，但这两个方法不会有蓝牙回调，要等到此方法完成后才有
    @discardableResult
    public func setWifi(config: BindConfig) -> ExecutionToken? {
        var rawData: SendingRawData = [
            KeyRawValue.cmd: Command.setWifi.rawValue,
        ]

        switch config.style {
        case .user(let uid):
            rawData[KeyRawValue.uid] = uid
        case .family(let userID, let homeID):
            rawData[KeyRawValue.userID] = userID
            rawData[KeyRawValue.homeID] = homeID
        }

        return send(rawData)
    }

    /// 主机配置有线动态获取 IP
    @discardableResult
    public func enableLanDHCP(config: BindConfig) -> ExecutionToken? {
        var rawData: SendingRawData = [
            KeyRawValue.cmd: Command.setDHCP.rawValue,
        ]

        switch config.style {
        case .user(let uid):
            rawData[KeyRawValue.uid] = uid
        case .family(let userID, let homeID):
            rawData[KeyRawValue.userID] = userID
            rawData[KeyRawValue.homeID] = homeID
        }

        return send(rawData)
    }

    /// 设置设备 IP 地址
    @discardableResult
    public func setIPAddress(_ ipAddress: String) -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.setIP.rawValue,
            KeyRawValue.ip: ipAddress,
        ]

        return send(rawData)
    }

    /// 设置设备子网掩码
    @discardableResult
    public func setNetmask(_ netmask: String) -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.setNetmask.rawValue,
            KeyRawValue.netmask: netmask,
        ]

        return send(rawData)
    }

    /// 设置网关地址
    @discardableResult
    public func setGatewayAddress(_ gatewayAddress: String) -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.setGateway.rawValue,
            KeyRawValue.gateway: gatewayAddress,
        ]

        return send(rawData)
    }

    /// 设置设备 DNS 地址
    @discardableResult
    public func setDNSAddress(_ dnsAddress: String) -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.setDNS.rawValue,
            KeyRawValue.dns: dnsAddress,
        ]

        return send(rawData)
    }

    /// 设置设备静态 IP
    /// - 需要先调用 `setIPAddress(_ ipAddress:)`, `setNetmask(_ netmask:)`, `setGatewayAddress(_ gatewayAddress:)`, `setDNSAddress(_ dnsAddress: String)`方法，但这些方法并不会有蓝牙回调，要等到此方法完成才有
    @discardableResult
    public func setStaticIPAddress(config: BindConfig) -> ExecutionToken? {
        var rawData: SendingRawData = [
            KeyRawValue.cmd: Command.setStaticIP.rawValue,
        ]

        switch config.style {
        case .user(let uid):
            rawData[KeyRawValue.uid] = uid
        case .family(let userID, let homeID):
            rawData[KeyRawValue.userID] = userID
            rawData[KeyRawValue.homeID] = homeID
        }

        return send(rawData)
    }

    /// 关闭蓝牙
    @discardableResult
    public func shutdownBluetooth() -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.stopBLE.rawValue,
        ]

        return send(rawData)
    }

    /// 获取 SIM 卡状态
    @discardableResult
    public func getSIMStatus() -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.getSIMStatus.rawValue,
        ]

        return send(rawData)
    }
    
    /// 发送debug指令
    @discardableResult
    public func sendRunZT() -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.runZT.rawValue,
        ]

        return send(rawData)
    }


    public struct Cellular4GConnectConfiguration {
        let nodeName: String
        let userName: String
        let password: String

        public init(nodeName: String, userName: String, password: String) {
            self.nodeName = nodeName
            self.userName = userName
            self.password = password
        }
    }

    /// 设置 4G 联网信息
    /// - 当 `config` 为 `nil` 时，将使用自动模式；否则，则使用提供的 `config` 进行配置
    /// - Parameter config: 配置信息
    @discardableResult
    public func set4GConnectConfig(_ config: Cellular4GConnectConfiguration?) -> ExecutionToken? {
        let rawData: SendingRawData = {
            switch config {
            case .some(let config):
                return [
                    KeyRawValue.cmd: Command.set4GConnectConfig.rawValue,
                    KeyRawValue.set4GAutomatically: "0",
                    KeyRawValue.set4GNodeName: config.nodeName,
                    KeyRawValue.set4GUserName: config.userName,
                    KeyRawValue.set4GPassword: config.password,
                ]
            case .none:
                return [
                    KeyRawValue.cmd: Command.set4GConnectConfig.rawValue,
                    KeyRawValue.set4GAutomatically: "1",
                ]
            }
        }()

        return send(rawData)
    }

    public struct Cellular4GUserConfiguration {
        let homeID: String
        let userID: String

        public init(homeID: String, userID: String) {
            self.homeID = homeID
            self.userID = userID
        }
    }

    /// 设置 4G 联网
    /// - Parameter config: 联网时的用户信息
    public func set4GUserConfig(_ config: Cellular4GUserConfiguration) -> ExecutionToken? {
        let rawData: SendingRawData = [
            KeyRawValue.cmd: Command.set4GUserConfig.rawValue,
            KeyRawValue.set4GHomeID: config.homeID,
            KeyRawValue.set4GUserID: config.userID
        ]

        return send(rawData)
    }
}
