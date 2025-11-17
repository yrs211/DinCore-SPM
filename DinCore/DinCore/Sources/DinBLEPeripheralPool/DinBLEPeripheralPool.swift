//
//  DSBLEPool.swift
//  DinCore
//
//  Created by monsoir on 6/1/21.
//

import Foundation
import CoreBluetooth
import DinSupport

public protocol DinBLEPeripheralPoolDelegate: AnyObject {
    func dinBLEPeripheralPool(_ thePool: DinBLEPeripheralPool, didUpdateState state: CBManagerState)

    /// 扫描到设备回调
    /// - Parameters:
    ///   - thePool: 扫描器对象
    ///   - device: 扫到的设备
    ///   - isFirstMet: 是否第一次扫描到
    /// - 该回调在非主队列中调用，若调用方处涉及 UI 处理，需由调用方进行队列切换
    func dinBLEPeripheralPool(_ thePool: DinBLEPeripheralPool, didScan peripheral: DinScannedBLEPeripheral, isFirstMet: Bool)

    func dinBLEPeripheralPool(_ thePool: DinBLEPeripheralPool, didConnect peripheral: DinScannedBLEPeripheral)

    func dinBLEPeripheralPool(_ thePool: DinBLEPeripheralPool, didFailToConnect peripheral: DinScannedBLEPeripheral, error: DinBLEPeripheralPool.ConnectError)

    func dinBLEPeripheralPool(_ thePool: DinBLEPeripheralPool, didDisconnect peripheral: DinScannedBLEPeripheral, error: DinBLEPeripheralPool.ConnectError)

    /// 之前已扫描到的设备信息过期了
    /// - Parameters:
    ///   - thePool: 扫描器对象
    ///   - devices: 信息过期的设备
    func dinBLEPeripheralPool(_ thePool: DinBLEPeripheralPool, didExpire peripherals: [DinScannedBLEPeripheral])
}

/// 蓝牙设备扫描器
/// - 只负责扫描及建立与外设连接，不负责与外设连接成功后续的事务：如收发数据处理
/// - 想象成若干蓝牙设备组成的池塘，每一次扫描到设备，理解为「钓」到一条鱼
public class DinBLEPeripheralPool: NSObject {

    public weak var delegate: DinBLEPeripheralPoolDelegate?

    /// 设备的服务 UUID 们
    private let serviceUUIDs: [CBUUID]?
    private let idGenerator: DinBLEPeripheralIdentifiable

    private lazy var scanner: DinBLEPeripheralScanner = {
        let result = DinBLEPeripheralScanner(
            serviceUUIDs: serviceUUIDs,
            idGenerator: idGenerator,
            operationQueue: queue
        )
        result.delegate = self
        return result
    }()

    /// 当前连接的设备
    /// - 上钩的鱼
    /// - 弱引用，减轻内存管理心智负担，反正断开连接后就不需要了
    private weak var connectedPeripheral: DinScannedBLEPeripheral?

    /// 扫描到的设备处理串行队列
    private lazy var queue = DispatchQueue(label: "com.dinsafer.DinCore.DSBLEDevicePool", qos: .userInitiated)

    /// 扫描到的设备
    public private(set) lazy var scannedPeripherals = [DinScannedBLEPeripheral]()

    /// 检查保鲜定时器
    private var keepFreshTimer: DinGCDTimer?

    /// 检查保鲜频率
    private let keepFreshRequency = DinTimerInterval.seconds(1)

    /// 扫描到的蓝牙设备过期时间
    private let expiredThreshold: TimeInterval = 5 // as seconds

    public init(
        serviceUUIDs: [CBUUID]?,
        idGenerator: DinBLEPeripheralIdentifiable
    ) {
        self.serviceUUIDs = serviceUUIDs
        self.idGenerator = idGenerator
    }

    /// 开启扫描蓝牙设备
    /// - 开始钓鱼
    public func startScanning(_ completion: ((Result<Void, ScanError>) -> Void)? = nil) {

        let scanStartedSuccessfullyHandler: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.queue.async { [weak self] in
                guard let self = self else { return }
                let removedPeripherals = self.scannedPeripherals
                self.delegate?.dinBLEPeripheralPool(self, didExpire: removedPeripherals)
                self.scannedPeripherals.removeAll()
                self.keepFreshTimer = self.startCheckingFreshness()
                completion?(.success(()))
            }
        }

        scanner.startScanning { result in
            switch result {
            case .success:
                scanStartedSuccessfullyHandler()
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    /// 停止扫描蓝牙设备
    /// - 停止钓鱼
    public func stopScanning() {
        scanner.stopScanning()
        stopCheckingFreshness()
    }

    /// 连接设备
    public func connect(peripheral: DinScannedBLEPeripheral) {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard let thePeripheral = self.scannedPeripherals.first(where: { $0.id == peripheral.id }) else { return }
            self.scanner.connect(peripheral: thePeripheral)
        }
    }

    /// 断开当前设备连接
    public func disconnectPeripheral() {
        guard let thePeripheral = connectedPeripheral else { return }
        scanner.cancelPeripheralConnection(thePeripheral)
    }

    private func handleDidScanPeripheral(_ peripheral: DinScannedBLEPeripheral) {
        if let existingPeripheral = scannedPeripherals.first(where: { $0.id == peripheral.id }) {
            // 设备已存在，更新
            existingPeripheral.update(
                peripheral: peripheral.peripheral,
                advertisementData: peripheral.advertisementData,
                rssi: peripheral.rssi
            )
            delegate?.dinBLEPeripheralPool(self, didScan: existingPeripheral, isFirstMet: false)
        } else {
            // 设备不存在，新增
            scannedPeripherals.append(peripheral)
            delegate?.dinBLEPeripheralPool(self, didScan: peripheral, isFirstMet: true)
        }
    }

    /// 检查并剔除长时间没有更新的「已扫描到」的蓝牙设备
    /// - 保鲜
    private func startCheckingFreshness() -> DinGCDTimer {
        let check: () -> Void = { [weak self] in
            guard let self = self else { return }
            guard !self.scannedPeripherals.isEmpty else { return }

            let nowTimestamp = Date().timeIntervalSince1970
            let expiredPeripherals = self.scannedPeripherals.filter { nowTimestamp - $0.updatedAt.timeIntervalSince1970 >= self.expiredThreshold }
            self.scannedPeripherals.removeAll(where: { nowTimestamp - $0.updatedAt.timeIntervalSince1970 >= self.expiredThreshold})
            self.delegate?.dinBLEPeripheralPool(self, didExpire: expiredPeripherals)
        }

        let timer = DinGCDTimer(
            timerInterval: keepFreshRequency,
            isRepeat: true,
            executeBlock: check,
            queue: queue
        )
        return timer
    }

    private func stopCheckingFreshness() {
        keepFreshTimer = nil
    }
}

extension DinBLEPeripheralPool: DinBLEPeripheralScannerDelegate {
    public func dinBLEPeripheralScanner(_ theScanner: DinBLEPeripheralScanner, didUpdateState state: CBManagerState) {
        guard theScanner === scanner else { return }
        delegate?.dinBLEPeripheralPool(self, didUpdateState: state)
    }

    public func dinBLEPeripheralScanner(_ theScanner: DinBLEPeripheralScanner, didScanPeripheral peripheral: DinScannedBLEPeripheral) {
        guard theScanner === scanner else { return }
        handleDidScanPeripheral(peripheral)
    }

    public func dinBLEPeripheralScanner(_ theScanner: DinBLEPeripheralScanner, didConnect peripheral: DinScannedBLEPeripheral) {
        guard theScanner === scanner else { return }
        guard let connectedPeripheral = scannedPeripherals.first(where: { $0.id == peripheral.id }) else { return }
        self.connectedPeripheral = connectedPeripheral

        delegate?.dinBLEPeripheralPool(self, didConnect: connectedPeripheral)
    }

    public func dinBLEPeripheralScanner(_ theScanner: DinBLEPeripheralScanner, didFailToConnect peripheral: DinScannedBLEPeripheral, error: DinBLEPeripheralScanner.ConnectError) {
        guard theScanner === scanner else { return }
        guard let thePeripheral = scannedPeripherals.first(where: { $0.id == peripheral.id }) else { return }
        delegate?.dinBLEPeripheralPool(self, didFailToConnect: thePeripheral, error: error)
    }

    public func dinBLEPeripheralSCanner(_ theScanner: DinBLEPeripheralScanner, didDisconnect peripheral: DinScannedBLEPeripheral, error: DinBLEPeripheralScanner.ConnectError) {
        guard theScanner === scanner else { return }
        guard let thePeripheral = scannedPeripherals.first(where: { $0.id == peripheral.id }) else { return }
        if connectedPeripheral != nil { connectedPeripheral = nil }
        delegate?.dinBLEPeripheralPool(self, didDisconnect: thePeripheral, error: error)
    }
}

extension DinBLEPeripheralPool {
    public typealias ScanError = DinBLEPeripheralScanner.ScanError
    public typealias ConnectError = DinBLEPeripheralScanner.ConnectError
}
