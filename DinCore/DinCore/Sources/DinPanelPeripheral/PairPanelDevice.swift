//
//  PairPanelDevice.swift
//  DinCore
//
//  Created by monsoir on 6/1/21.
//

import Foundation

/// 配对设备的命名空间
public enum PairPanelDevice {}

extension PairPanelDevice {

    public typealias BindConfig = DinPanelPeripheral.BindConfig

    /// 配对主机时设置的 Wi-Fi 信息
    public struct WifiConfig {
        public let ssid: String
        public let password: String

        public init(
            ssid: String,
            password: String
        ) {
            self.ssid = ssid
            self.password = password
        }
    }

    /// 配对主机时设置静态 IP 的 Lan 信息
    public struct StaticIPLanConfig {
        public let ipAddress: String
        public let netmask: String
        public let gateway: String
        public let dnsAddress: String

        public init(
            ipAddress: String = "",
            netmask: String = "",
            gateway: String = "",
            dnsAddress: String = ""
        ) {
            self.ipAddress = ipAddress
            self.netmask = netmask
            self.gateway = gateway
            self.dnsAddress = dnsAddress
        }
    }

    /// 配对主机时发生的错误
    public enum PairError: Swift.Error {

        /// 请求数据有误
        case badRequest

        /// 响应格式有误
        case reponseMalform

        /// 操作超时
        case timeout

        /// 设备报告失败，一般的失败
        case failed

        /// 设备早已被绑定家庭
        case alreadyBound

        /// 停止了
        case stopped
    }
}
