//
//  DinScannedMasterControlPeripheral.swift
//  DinCore
//
//  Created by monsoir on 6/4/21.
//

import Foundation
import CoreBluetooth
import HandyJSON
import DinSupport

public protocol DinPanelPeripheralDelegate: AnyObject {

    /// 指令执行完成
    /// - Parameters:
    ///   - peripheral: 执行指令的设备
    ///   - token: 指令执行标记 token
    ///   - result: 指令执行完成结果
    func dinPanelPeripheral(
        _ peripheral: DinPanelPeripheral,
        completeCommand token: DinPanelPeripheral.ExecutionToken,
        didReceiveResponse result: Result<DinPanelPeripheral.Command.Response, DinPanelPeripheral.CommandExecutionError>
    )

    /// 收到设备主动推送的指令
    /// - Parameters:
    ///   - peripheral: 发送指令的设备 
    ///   - command: 指令
    ///   - content: 指令携带信息
    func dinPanelPeripheral(
        _ peripheral: DinPanelPeripheral,
        receiveCommand command: DinPanelPeripheral.Command,
        content: DinPanelPeripheral.Command.Response
    )
}

/// 扫描到的主机设备
/// - 特指主机设备
final public class DinPanelPeripheral: DinPeripheral {

    public weak var delegate: DinPanelPeripheralDelegate?

    /// 把持特征完成后的回调
    /// - 在把持完成后即会置 `nil`
    private var hookCharacteristicsCompletion: ((Result<Void, HookCharacterisctisError>) -> Void)?

    /// 写特征
    private var writeCharacteristic: CBCharacteristic?

    /// 通知特征
    private var notifyCharacteristic: CBCharacteristic?

    /// 等待响应的指令回执
    private var executionToken: ExecutionToken?

    /// 连接Services超时计数器
    private var connectServicesWatch: DinGCDTimer?
    /// 连接Characteristics超时计数器
    private var connectCharacteristicsWatch: DinGCDTimer?
    /// 指令执行时间观察者
    private var taskWatch: DinGCDTimer?

    /// 设备广播出来的状态
    public var boardcastingStatus: BoardcastingStatus {
        guard infoString.count > 2 else { return .default }

        let result = BoardcastingStatus(
            isOnline: infoString[1] == "1",
            isNew: infoString[0] == "1",
            isNewFactoryFirmware: infoString[2] == "1",
            isSIMSupported: infoString[3] == "1"
        )
        return result
    }

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

    deinit {
        stopConnectServicesWatching()
        stopConnectCharacteristicsWatching()
        stopWatching()
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
        // 现发现，有时候低版本的系统在蓝牙连接期间，调用discoverServices()之后， peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) 没有返回
        // 所以增加超时报错
        startConnectServicesWatching()
    }

    // MARK: 处理外设数据更新

    /// 处理外设通知更新的数据
    /// - Parameter data: 外设通知的更新数据
    private func handleNotifiedUpdate(data: Data) {

        guard
            let rawString = String(data: data, encoding: .utf8), !rawString.isEmpty,
            rawString != Self.heartbeatValue
        else { return }

        let cleanUp: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.executionToken = nil
            self.stopWatching()
            self.stopConnectServicesWatching()
            self.stopConnectCharacteristicsWatching()
        }

        guard let response = Self.parseCommandResponse(rawString) else {
            if let token = executionToken {
                // 如果是获取wifi列表的指令，其中一个wifi名字解析不出来(乱码导致parseCommandResponse -> nil)
                // 则抛弃，但是不影响其他wifi名的收集，并且此指令继续运行
                // 其余指令统一抛弃，并返回错误
                if token.command != Command.getWifiList {
                    cleanUp()
                }
                delegate?.dinPanelPeripheral(
                    self,
                    completeCommand: token,
                    didReceiveResponse: .failure(.responseMalform)
                )
            }
            return
        }

        guard let command = Command(rawValue: response.cmd) else {
            // 未知指令，忽略
            return
        }

        switch command.sender {
        case .device:
            delegate?.dinPanelPeripheral(self, receiveCommand: command, content: response)
        case .client:
            guard
                let token = executionToken,
                // 过滤不同指令返回的结果，相同指令才继续流程
                // - 比如获取 GetWifiList，是一个陆续回来的结果，此时可能会直接发送一个 setDHCP 指令，而这个指令的返回可能比 GetWifiList 更早完成
                token.command.rawValue == response.cmd
            else { return }
            if response.status != .moreComing {
                cleanUp()
            }
            delegate?.dinPanelPeripheral(self, completeCommand: token, didReceiveResponse: .success(response))
        }
    }

    /// 转换外设通知更新的数据
    /// - Parameter rawString: 外设通知更新的数据，字符串形式
    /// - Returns: 转换后的结果
    private static func parseCommandResponse(_ rawString: String) -> Command.Response? {
        let result = Command.Response.deserialize(
            from: DinCore.cryptor.rc4DecryptHexString(
                rawString,
                key: DinCore.appSecret ?? ""
            )
        )
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
            let encryptedData = DinCore.cryptor.rc4EncryptToHexString(with: jsonString, key: DinCore.appSecret ?? "")?.data(using: .utf8)
        else { return nil }

        executionToken = nil
        if cmd.needsWatching {
            let token = ExecutionToken(id: UUID(), command: cmd)
            executionToken = token
            startWatching(token: token)
        }
        cbPeripheral.writeValue(encryptedData, for: characteristic, type: .withoutResponse)

        return executionToken
    }

    private func startWatching(token: ExecutionToken) {
        stopWatching()
        guard token.command.needsWatching else { return }

        let handleTimeout: () -> Void = { [weak self] in
            guard let self = self else { return }
            guard self.executionToken === token else { return }

            self.executionToken = nil
            self.delegate?.dinPanelPeripheral(
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

    private func startConnectServicesWatching() {
        stopConnectServicesWatching()

        let handleTimeout: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.hookCharacteristicsCompletion?(.failure(.servicesNotFound))
        }

        let timer = DinGCDTimer(
            timerInterval: .seconds(5),
            isRepeat: false,
            executeBlock: handleTimeout,
            queue: DispatchQueue.main
        )
        connectServicesWatch = timer
    }
    private func stopConnectServicesWatching() {
        connectServicesWatch = nil
    }

    private func startCharacteristicsWatching() {
        stopConnectCharacteristicsWatching()

        let handleTimeout: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.hookCharacteristicsCompletion?(.failure(.characteristicsNotFound))
        }

        let timer = DinGCDTimer(
            timerInterval: .seconds(5),
            isRepeat: false,
            executeBlock: handleTimeout,
            queue: DispatchQueue.main
        )
        connectCharacteristicsWatch = timer
    }
    private func stopConnectCharacteristicsWatching() {
        connectCharacteristicsWatch = nil
    }
}

extension DinPanelPeripheral: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard peripheral === cbPeripheral else { return }
        stopConnectServicesWatching()
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
        startCharacteristicsWatching()
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard peripheral === cbPeripheral else { return }
        stopConnectCharacteristicsWatching()
        defer { hookCharacteristicsCompletion = nil }
        guard let characteristics = service.characteristics else {
            hookCharacteristicsCompletion?(.failure(.characteristicsNotFound))
            return
        }

        var writeCharacteristicOrNil: CBCharacteristic?
        var notifyCharacteristicOrNil: CBCharacteristic?

        for ele in characteristics {
            if ele.properties.contains(.write) {
                writeCharacteristicOrNil = ele
            }

            if ele.properties.contains(.notify) {
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

extension DinPanelPeripheral {

    typealias SendingRawData = [String: String]

    /// 心跳包响应内容
    private static let heartbeatValue = "NON"

    /// 蓝牙指令
    public enum Command: String {
        case checkIsNewDevice = "IsNewDevice"
        case setDeviceName = "SetDeviceName"
        case setDevicePassword = "SetDevicePassword"
        case verifyDevicePassword = "VerifyDevicePassword"
        case getWifiList = "GetWifiList"
        case setWifiName = "SetWifiName"
        case setWifiPassword = "SetWifiPassword"
        case setWifi = "SetWifi"
        case setDHCP = "SetDHCP"
        case setIP = "SetIP"
        case setNetmask = "SetNetmask"
        case setGateway = "SetGateway"
        case setDNS = "SetDNS"
        case setStaticIP = "SetSIP" 
        case deviceOnline = "DeviceOnline"
        case bindDevice = "BindDevice"
        case stopBLE = "StopBLE"
        case getSIMStatus = "GetSIM"
        case set4GConnectConfig = "Set4GInfo"
        case set4GUserConfig = "Set4G"
        case get4G = "Get4G"
        case runZT = "RunZT"
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

        /// 出厂固件是否为新固件
        public let isNewFactoryFirmware: Bool

        /// 是否支持家庭
        public var isFamilyModeSupported: Bool { isNewFactoryFirmware }

        /// 是否支持 SIM 卡
        public var isSIMSupported: Bool

        /// 是否支持 4G
        public var is4GSupported: Bool { isSIMSupported }

        static var `default`: Self {
            BoardcastingStatus(
                isOnline: false,
                isNew: false,
                isNewFactoryFirmware: false,
                isSIMSupported: false
            )
        }
    }
}

extension DinPanelPeripheral.Command {

    /// 指令发送的角色
    enum Sender {

        /// 客户端本端
        case client

        /// 蓝牙外设
        case device
    }

    /// 蓝牙指令执行完成的结果
    public struct Response: HandyJSON {

        public init() {}

        public mutating func mapping(mapper: HelpingMapper) {
            mapper <<< code <-- "status"
            mapper <<< content <-- "result"
        }

        public enum Status {

            /// 成功
            case succeeded

            /// 失败
            case failed

            /// 设备早已被绑定
            case alreadyBound

            /// 还有更多
            case moreComing
        }

        private var code: Int = 0
        public private(set) var content: String?
        private(set) var cmd: String = ""
        public private(set) var rssi: Int?
        public private(set) var auth: Bool?

        public var status: Status {
            switch code {
            case 1: return .succeeded
            case 2: return .moreComing
            case -67: return .alreadyBound
            default: return .failed
            }
        }
    }

    /// 指令执行超时时间(seconds)
    public var waitingDuration: TimeInterval {
        switch self {
        case .setDeviceName, .setDevicePassword, .verifyDevicePassword, .bindDevice, .getWifiList:
            return 20
        case .setWifi, .deviceOnline, .setDHCP, .setStaticIP:
            return 60
        default:
            return 20
        }
    }

    /// 指令执行是否需要监听超时
    var needsWatching: Bool {
        switch self {
        case .setDeviceName, .setDevicePassword, .verifyDevicePassword, .bindDevice, .getWifiList,
                .setWifi, .deviceOnline, .setDHCP, .setStaticIP, .getSIMStatus, .set4GConnectConfig, .set4GUserConfig, .get4G, .runZT:
            return true
        default:
            return false
        }
    }

    /// 指令的响应是否为分段
    var fragmented: Bool {
        switch self {
        case .getWifiList: return true
        default: return false
        }
    }

    /// 指令发送的角色
    var sender: Sender {
        switch self {
        case .deviceOnline: return .device
        default: return .client
        }
    }
}

