//
//  DinPeripheral.swift
//  DinCore
//
//  Created by Monsoir on 2021/6/24.
//

import Foundation
import CoreBluetooth

// Din 设备
public class DinPeripheral: NSObject {

    /// 设备 ID
    public var id: ID { dinPeripheral.id }

    /// 针对 Din 封装的 peripheral 对象
    public let dinPeripheral: DinScannedBLEPeripheral

    /// 系统原生的 peripheral 对象
    public var cbPeripheral: CBPeripheral { dinPeripheral.peripheral }

    /// 显示名称
    public var displayName: String {
        guard id.count > 4 else { return "" }

        let endIndex = id.index(before: id.endIndex)
        let startIndex = id.index(endIndex, offsetBy: -4, limitedBy: id.startIndex) ?? id.startIndex
        let result = String(id[startIndex...endIndex])
        return result
    }

    init(peripheral: DinScannedBLEPeripheral) {
        self.dinPeripheral = peripheral
        super.init()
    }
}

extension DinPeripheral {
    public typealias ID = String

    /// 把持特征时的错误
    public enum HookCharacterisctisError: Swift.Error {
        case servicesNotFound
        case characteristicsNotFound
    }

    /// 蓝牙指令执行的错误
    public enum CommandExecutionError: Swift.Error {

        /// 响应数据有问题
        case responseMalform

        /// 执行超时
        case timeout
        
        /// 丢弃指令
        //起因：先发送了获取Wi-Fi列表指令，然后结果没有这么快返回来，然后发送了配网一些列指令，期间获取Wi-Fi列表的指令这时候才返回结果，这时候token的command是配网的其中一个指令（如："set_app_secret"），而蓝牙返回结果response的cmd是"get_wifi_list"，从而token的command与蓝牙返回的response的cmd不匹配
        //现在做法：当上一个指令发送了还没返回结果，就发送下一个指令，就报错并把上一个指令抛弃掉
        case aborted
    }

    /// 蓝牙指令执行回执
    /// - caller 可以根据回执判等结果识别是否为需要处理的回应结果
    public class ExecutionToken {
        public let id: UUID

        init(id: UUID) {
            self.id = id
        }
    }
}
