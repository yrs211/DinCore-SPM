//
//  DinStorageBatteryPeripheral.swift
//  DinCore
//
//  Created by monsoir on 12/8/22.
//

import Foundation
import HandyJSON
import CoreBluetooth
import DinSupport
import OSLog
import UIKit

public protocol DinStorageBatteryPeripheralDelegate: AnyObject {
    func dinStorageBatteryPeripheral(
        _ peripheral: DinStorageBatteryPeripheral,
        completeCommand token: DinStorageBatteryPeripheral.ExecutionToken,
        didReceiveResponse result: Result<DinStorageBatteryPeripheral.Command.Response, DinStorageBatteryPeripheral.CommandExecutionError>
    )
}

/// 扫描到的储能电池设备
final
public class DinStorageBatteryPeripheral: DinPeripheral {

    public weak var delegate: DinStorageBatteryPeripheralDelegate?

    /// 设备广播出来的状态
    public var boardcastingStatus: BoardcastingStatus {
        guard infoString.count > 2 else { return .default }

        let result = BoardcastingStatus(
            isBricked: infoString[1] == "1",
            isNew: infoString[0] == "1"
        )
        return result
    }

    /// 把持特征完成后的回调
    /// - 在把持完成后即会置 `nil`
    private var hookCharacteristicsCompletion: ((Result<Void, HookCharacterisctisError>) -> Void)?

    private var writeCharacteristic: CBCharacteristic?

    private var notifyCharacteristic: CBCharacteristic?

    /// 等待响应的指令回执
    private var executionToken: ExecutionToken?

    /// 指令执行时间观察者
    private var taskWatch: DinGCDTimer?

    private lazy var cryptoKeyBytes = [UInt8](DinConstants.storageBatteryCrytoKey.data(using: .utf8) ?? Data())
    private lazy var cryptoIVBytes = [UInt8](DinConstants.storageBatteryCrytoIV.data(using: .utf8) ?? Data())
    private lazy var cryptor: DinsaferAESCBCCryptor? = DinsaferAESCBCCryptor(withSecret: cryptoKeyBytes, iv: cryptoIVBytes)
    
    private var infoString: String {
        guard
            let ruby = (dinPeripheral.advertisementData["kCBAdvDataServiceData"] as? [CBUUID: Data])?[CBUUID(string: "0D00")]
        else { return "" }

        let nums = [UInt8](ruby)
        guard !nums.isEmpty else { return "" }

        let result = String(nums[0], radix: 2).padLeftZero(width: 8)
        return result
    }

    public override init(peripheral: DinScannedBLEPeripheral) {
        super.init(peripheral: peripheral)
        self.cbPeripheral.delegate = self
    }

    /// 把持住蓝牙特征
    /// - Parameters:
    ///   - serviceUUIDs: 需要把持的蓝牙特征对应的服务 UUID
    ///   - completion: 把持完成回调
    public func hookCharacteristics(
        serviceUUIDs: [CBUUID]?,
        completion: ((Result<Void, HookCharacterisctisError>) -> Void)? = nil
    ) {
        hookCharacteristicsCompletion = completion
        cbPeripheral.discoverServices(serviceUUIDs)
    }

    /// 处理外设通知更新的数据
    /// - Parameter data: 外设通知的更新数据
    private func handleNotifiedUpdate(data: Data) {

        let cleanUp: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.executionToken = nil
            self.stopWatching()
        }

        guard let response = parseCommandResponse(data) else {
            if let token = executionToken {
                // 如果是获取wifi列表的指令，其中一个wifi名字解析不出来(乱码导致parseCommandResponse -> nil)
                // 则抛弃，但是不影响其他wifi名的收集，并且此指令继续运行
                // 其余指令统一抛弃，并返回错误
                if token.command != Command.getWifiList {
                    cleanUp()
                }
                delegate?.dinStorageBatteryPeripheral(
                    self,
                    completeCommand: token,
                    didReceiveResponse: .failure(.responseMalform)
                )
            }
            return
        }

        guard let token = executionToken else { return }
        
        guard token.command.rawValue == response.cmd else { return }

        if response.status != .moreComing {
            cleanUp()
        }
        delegate?.dinStorageBatteryPeripheral(
            self,
            completeCommand: token,
            didReceiveResponse: .success(response)
        )
    }

    /// 转换外设通知更新的数据
    /// - Parameter rawString: 外设通知更新的数据，字符串形式
    /// - Returns: 转换后的结果
    private func parseCommandResponse(_ rawData: Data) -> Command.Response? {
        let rawBytes = cryptor?.aesDecrypt(bytes: [UInt8](rawData)) ?? []
        let result = Command.Response.deserialize(from: String(data: Data(rawBytes), encoding: .utf8))
        return result
    }

    /// 向外设发送数据
    /// - Parameter data: 二进制数据
    func send(_ rawData: SendingRawData) -> ExecutionToken? {
        guard let characteristic = writeCharacteristic, !rawData.isEmpty else { return nil }
        guard
            let cmdRawValue = rawData[KeyRawValue.cmd],
            let cmd = Command(rawValue: cmdRawValue as? String ?? ""),
            let jsonData = try? JSONSerialization.data(withJSONObject: rawData, options: []),
            let jsonString = String(data: jsonData, encoding: .utf8),
            let encryptedData = cryptor?.aesEncrypt(string: jsonString)
        else { return nil }

        if executionToken != nil {
            delegate?.dinStorageBatteryPeripheral(
                self,
                completeCommand: executionToken!,
                didReceiveResponse: .failure(.aborted)
            )
        }
        
        executionToken = nil
        if cmd.needsWatching {
            let token = ExecutionToken(id: UUID(), command: cmd)
            executionToken = token
            startWatching(token: token)
        }

        cbPeripheral.writeValue(Data(encryptedData), for: characteristic, type: .withoutResponse)

        return executionToken
    }

    private func startWatching(token: ExecutionToken) {
        stopWatching()
        guard token.command.needsWatching else { return }

        let handleTimeout: () -> Void = { [weak self] in
            guard let self = self else { return }
            guard self.executionToken === token else { return }

            self.executionToken = nil
            self.delegate?.dinStorageBatteryPeripheral(
                self,
                completeCommand: token,
                didReceiveResponse: .failure(.timeout)
            )
        }

        let timer = DinGCDTimer(
            timerInterval: .seconds(token.command.waitingDuration),
            isRepeat: false,
            executeBlock: handleTimeout
        )
        taskWatch = timer
    }

    private func stopWatching() {
        taskWatch = nil
    }
}

extension DinStorageBatteryPeripheral: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard peripheral === cbPeripheral else { return }
        if error != nil {
            defer { hookCharacteristicsCompletion = nil }
            hookCharacteristicsCompletion?(.failure(.servicesNotFound))
            return
        }

        guard let theService = peripheral.services?.first else {
            defer { hookCharacteristicsCompletion = nil }
            hookCharacteristicsCompletion?(.failure(.servicesNotFound))
            return
        }

        peripheral.discoverCharacteristics(nil, for: theService)
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard peripheral === cbPeripheral else { return }
        defer { hookCharacteristicsCompletion = nil }
        guard let characteristics = service.characteristics else {
            hookCharacteristicsCompletion?(.failure(.characteristicsNotFound))
            return
        }

        var writeCharacteristicOrNil: CBCharacteristic?
        var notifyCharacteristicOrNil: CBCharacteristic?

        for ele in characteristics {
            if ele.properties.contains(.writeWithoutResponse) || ele.properties.contains(.write) {
                writeCharacteristicOrNil = ele
            }

            if ele.properties.contains(.notify) || ele.properties.contains(.notifyEncryptionRequired) {
                notifyCharacteristicOrNil = ele
                peripheral.setNotifyValue(true, for: ele)
            }
        }

        guard let write = writeCharacteristicOrNil, let notify = notifyCharacteristicOrNil else {
            hookCharacteristicsCompletion?(.failure(.characteristicsNotFound))
            return
        }

        writeCharacteristic = write
        notifyCharacteristic = notify

        hookCharacteristicsCompletion?(.success(()))
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard peripheral === cbPeripheral else { return }
        guard error == nil, let data = characteristic.value else { return }
        handleNotifiedUpdate(data: data)
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard peripheral === cbPeripheral else { return }
        if error != nil {
            return
        }
    }
}

extension DinStorageBatteryPeripheral {
    typealias SendingRawData = [String: Any]

    /// Din BMT 蓝牙指令
    public enum Command: String {

        /// 设置 App ID
        case setAppID = "set_app_id"

        /// 设置 App key
        case setAppKey = "set_app_key"

        /// 设置 App secret
        case setAppSecret = "set_app_secret"

        /// 设置 HTTP Host
        case setHTTPHost = "set_http_host"

        /// 设置 UDP Host
        case setUDPHost = "set_udp_host"

        /// 设置 数据统计 HTTP Host
        case setStatisticsHTTPHost = "set_data_host"

        /// 设置家庭 ID
        case setFamilyID = "set_home"

        /// 设置设备名称
        case setDeviceName = "set_name"

        /// 获取 Wi-Fi 列表
        case getWifiList = "get_wifi_list"

        /// 设置 Wi-Fi SSID
        case setWifiSSID = "set_wifi_name"

        /// 设置 Wi-Fi 密码
        case setWifiPassword = "set_wifi_password"

        /// 开始配网
        case initialNetwork = "set_network"

        /// 注册设备
        case register = "register"

        /// 获取 end id
        case getEndID = "get_end_id"

        /// 获取固件版本
        case getFirmwareVersion = "get_version"

        /// 设置时区
        case setTimezone = "set_tz"

        /// 更新设置
        /// - BMT 自身向服务器拉取配置，如水印
        case updateConfig = "update_config"
        
        /// 设置设备 Model
        case setModel = "set_model"
        
        /// 获取设备 Model
        case getModel = "get_model"
        
        /// 获取 IoT 支持的产品 model 型号
        case getValidModels = "get_valid_models"
        
        /// 获取IOT以太网状态
        case getEthernetState = "get_ethernet_state"
    }

    /// 蓝牙指令执行回执
    /// - caller 可以根据回执判等结果识别是否为需要处理的回应结果
    public class ExecutionToken: DinPeripheral.ExecutionToken {
        public let command: Command

        init(id: UUID, command: Command) {
            self.command = command
            super.init(id: id)
        }
    }

    /// 外设广播的状态信息
    public struct BoardcastingStatus {

        /// 设备是否变砖了
        public let isBricked: Bool
        public let isNew: Bool

        static var `default`: Self {
            BoardcastingStatus(
                isBricked: false,
                isNew: false
            )
        }
    }
}

extension DinStorageBatteryPeripheral.Command {
    /// 蓝牙指令执行完成的结果
    public struct Response: HandyJSON {

        public init() {}

        public mutating func mapping(mapper: HelpingMapper) {
            mapper <<< code <-- "status"
            mapper <<< content <-- "result"
            mapper <<< groupID <-- "group_id"
            mapper <<< pid <-- "pid"
//            mapper <<< rssi <-- "rssi"
        }

        public enum Status {

            /// 成功
            case succeeded

            /// 失败
            case failed

            /// 添加BMT时，该BMT已经被添加过，添加失败
            case duplicate

            /// 该家庭已经添加>=100个BMT
            case numberLimit

            /// 还有更多
            case moreComing

            /// json解析错误
            case jsonParseError

            /// 登陆超时
            case loginTimeout

            /// 当前网络响应超时或信息缺少
            case curNetworkError
        }

        private var code: Int = 0
        public private(set) var content: String?
        public private(set) var groupID: String?
        public private(set) var pid: String?
        public private(set) var rssi: Int = -999
        public private(set) var auth: Bool?
        private(set) var cmd: String = ""

        public var status: Status {
            switch code {
            case 1: return .succeeded
            case 2: return .moreComing
            case -70: return .duplicate
            case -73: return .numberLimit
            case -1: return .jsonParseError
            case -2: return .loginTimeout
            case -4: return .curNetworkError
            default: return .failed
            }
        }
    }

    /// 指令执行超时时间(seconds)
    public var waitingDuration: TimeInterval {
        switch self {
            // BMT的setNetwork超时时间设置成60s
        case .initialNetwork:
            return 60
        case .register:
            // 在新版本IOT下面，register的指令会在注册完，并且检查IOT版本完成之后返回，所以这里增加到70s（IOT的检查版本超时是30s）
            return 70
        case .updateConfig:
            // 等待 BMT 更新配置信息，如下载水印文件，需要较长时间
            return 180
        default:
            return 20
        }
    }

    /// 指令执行是否需要监听超时
    var needsWatching: Bool {
        // TODO: 区分哪些指令需要检察执行时间
        true
    }

    /// 指令的响应是否为分段
    var fragmented: Bool {
        switch self {
        case .getWifiList: return true
        default: return false
        }
    }
}

extension DinStorageBatteryPeripheral {
    public static func getRSSIImage(_ rssi: Int?) -> UIImage? {
        var rssiImage = UIImage(named: "wifi_24_0")
        if let rssi = rssi {
            if rssi < 0 && rssi >= -50 {
                rssiImage = UIImage(named: "wifi_24_3")
            } else if rssi < -50 && rssi >= -70 {
                rssiImage = UIImage(named: "wifi_24_2")
            } else if rssi < -70 {
                rssiImage = UIImage(named: "wifi_24_1")
            }
        } else {
            rssiImage = nil
        }
        return rssiImage
    }
    
    public static func getWhiteRSSIImage(_ rssi: Int?) -> UIImage? {
        var rssiImage = UIImage(named: "icon_plugin_wifi_0")
        if let rssi = rssi {
            if rssi < 0 && rssi >= -50 {
                rssiImage = UIImage(named: "icon_plugin_wifi_3")
            } else if rssi < -50 && rssi >= -70 {
                rssiImage = UIImage(named: "icon_plugin_wifi_2")
            } else if rssi < -70 {
                rssiImage = UIImage(named: "icon_plugin_wifi_1")
            }
        } else {
            rssiImage = nil
        }
        return rssiImage
    }
}
