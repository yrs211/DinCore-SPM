//
//  DinDoorbellPeripheral.swift
//  DinCore
//
//  Created by Monsoir on 2021/6/24.
//

import Foundation
import CoreBluetooth
import DinSupport
import HandyJSON

public protocol DinDoorbellPeripheralDelegate: AnyObject {
    func dinDoorbellPeripheral(
        _ peripheral: DinDoorbellPeripheral,
        completeCommand token: DinDoorbellPeripheral.ExecutionToken,
        didReceiveResponse result: Result<DinDoorbellPeripheral.Command.Response, DinIPCPeripheral.CommandExecutionError>
    )
}

/// 扫描到的 IPC 设备
final public class DinDoorbellPeripheral: DinPeripheral {

    public weak var delegate: DinDoorbellPeripheralDelegate?

    /// 设备广播出来的状态
    public var boardcastingStatus: BoardcastingStatus {
        guard infoString.count > 2 else { return .default }

        let result = BoardcastingStatus(
            isOnline: infoString[1] == "1",
            isNew: infoString[0] == "1"
        )
        return result
    }

    /// 把持特征完成后的回调
    /// - 在把持完成后即会置 `nil`
    private var hookCharacteristicsCompletion: ((Result<Void, HookCharacterisctisError>) -> Void)?

    /// 写特征
    private var writeCharacteristic: CBCharacteristic?

    /// 通知特征
    private var notifyCharacteristic: CBCharacteristic?

    /// 等待响应的指令回执
    private var executionToken: ExecutionToken?

    /// 指令执行时间观察者
    private var taskWatch: DinGCDTimer?

    private lazy var cryptoKeyBytes = [UInt8](DinConstants.ipcCrytoKey.data(using: .utf8) ?? Data())
    private lazy var cryptoIVBytes = [UInt8](DinConstants.ipcCrytoIV.data(using: .utf8) ?? Data())
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

    // MARK: 处理外设数据更新

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
                delegate?.dinDoorbellPeripheral(
                    self,
                    completeCommand: token,
                    didReceiveResponse: .failure(.responseMalform)
                )
            }
            return
        }

        guard let token = executionToken else { return }
        if response.status != .moreComing {
            cleanUp()
        }
        delegate?.dinDoorbellPeripheral(
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
            let cmd = Command(rawValue: cmdRawValue),
            let jsonData = try? JSONSerialization.data(withJSONObject: rawData, options: []),
            let jsonString = String(data: jsonData, encoding: .utf8),
            let encryptedData = cryptor?.aesEncrypt(string: jsonString)
        else { return nil }

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
            self.delegate?.dinDoorbellPeripheral(
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

extension DinDoorbellPeripheral: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard peripheral === cbPeripheral else { return }
        if let error = error {
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

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Swift.Error?) {
        guard peripheral === cbPeripheral else { return }
        if error != nil {
            return
        }
    }
}

extension DinDoorbellPeripheral {

    typealias SendingRawData = [String: String]

    /// Din IPC 蓝牙指令
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
        public let isOnline: Bool
        public let isNew: Bool

        static var `default`: Self {
            BoardcastingStatus(
                isOnline: false,
                isNew: false
            )
        }
    }
}

extension DinDoorbellPeripheral.Command {

    /// 蓝牙指令执行完成的结果
    public struct Response: HandyJSON {

        public init() {}

        public mutating func mapping(mapper: HelpingMapper) {
            mapper <<< code <-- "status"
            mapper <<< content <-- "result"
            mapper <<< groupID <-- "group_id"
            mapper <<< pid <-- "pid"
        }

        public enum Status {

            /// 成功
            case succeeded

            /// 失败
            case failed

            /// 添加ipc时，该ipc已经被添加过，添加失败
            case duplicate

            /// 该家庭已经添加>=100个ipc
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
        case .initialNetwork, .register:
            return 30
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
