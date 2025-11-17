//
//  DSBLEDeviceScanner.swift
//  DinCore
//
//  Created by monsoir on 6/4/21.
//

import Foundation
import CoreBluetooth

public protocol DinBLEPeripheralScannerDelegate: AnyObject {
    func dinBLEPeripheralScanner(_ theScanner: DinBLEPeripheralScanner, didUpdateState state: CBManagerState)

    func dinBLEPeripheralScanner(_ theScanner: DinBLEPeripheralScanner, didScanPeripheral peripheral: DinScannedBLEPeripheral)

    func dinBLEPeripheralScanner(_ theScanner: DinBLEPeripheralScanner, didConnect peripheral: DinScannedBLEPeripheral)

    func dinBLEPeripheralScanner(_ theScanner: DinBLEPeripheralScanner, didFailToConnect peripheral: DinScannedBLEPeripheral, error: DinBLEPeripheralScanner.ConnectError)

    func dinBLEPeripheralSCanner(_ theScanner: DinBLEPeripheralScanner, didDisconnect peripheral: DinScannedBLEPeripheral, error: DinBLEPeripheralScanner.ConnectError)
}

/// 蓝牙设备扫描器
/// - 对系统的 `CBCentralManager` 的进一步封装，并使用 `DSScannedBLEPeripheral` 代替 `CBPeripheral` 作为产出
/// - `DSScannedBLEPeripheral` 使用了自定义的 ID 命名规则
public class DinBLEPeripheralScanner: NSObject {

    public weak var delegate: DinBLEPeripheralScannerDelegate?

    private let serviceUUIDs: [CBUUID]?
    private let operationQueue: DispatchQueue
    private let idGenerator: DinBLEPeripheralIdentifiable

    private lazy var centralManager: CBCentralManager = {
        let result = CBCentralManager(delegate: self, queue: operationQueue)
        return result
    }()

    private var bleState: CBManagerState { centralManager.state }
    private var bleAvailable: Bool { bleState == .poweredOn }
    private var isScanning: Bool { centralManager.isScanning }
    private var bleOptions: [String: Any] { [CBCentralManagerScanOptionAllowDuplicatesKey: true] }

    private var connectingPeripheral: DinScannedBLEPeripheral?
    private var connectedPeripheral: DinScannedBLEPeripheral?

    public init(
        serviceUUIDs: [CBUUID]?,
        idGenerator: DinBLEPeripheralIdentifiable,
        operationQueue: DispatchQueue = .main
    ) {
        self.serviceUUIDs = serviceUUIDs
        self.idGenerator = idGenerator
        self.operationQueue = operationQueue
    }

    public func startScanning(_ completion: ((Result<Void, ScanError>) -> Void)? = nil) {
        if isScanning {
            centralManager.stopScan()
        }

        // workaround: 创建了 centralManager 后立即查询蓝牙状态会返回 `.unknown`
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }

            guard self.bleAvailable else {
                completion?(.failure(.unavailable(state: self.bleState)))
                return
            }

            self.centralManager.scanForPeripherals(withServices: self.serviceUUIDs, options: self.bleOptions)
            completion?(.success(()))
        }
    }

    public func stopScanning() {
        guard isScanning else { return }
        centralManager.stopScan()
    }

    public func connect(peripheral: DinScannedBLEPeripheral) {
        connectedPeripheral = nil
        connectingPeripheral = peripheral
        centralManager.connect(peripheral.peripheral, options: nil)
    }

    public func cancelPeripheralConnection(_ peripheral: DinScannedBLEPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral.peripheral)
    }

    public func disconnectPeripheral() {
        if let peripheral = connectedPeripheral {
            cancelPeripheralConnection(peripheral)
        }
    }
    
}

extension DinBLEPeripheralScanner: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central === centralManager else { return }
        delegate?.dinBLEPeripheralScanner(self, didUpdateState: central.state)
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard central === centralManager else { return }

        let deviceID = idGenerator.createID(for: peripheral, advertisementData: advertisementData)
        let scannedPeripheral = DinScannedBLEPeripheral(
            id: deviceID,
            peripheral: peripheral,
            advertisementData: advertisementData,
            rssi: RSSI
        )
        delegate?.dinBLEPeripheralScanner(self, didScanPeripheral: scannedPeripheral)
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard central === centralManager else { return }
        guard let connectingDSPeripheral = connectingPeripheral, peripheral === connectingDSPeripheral.peripheral else { return }

        delegate?.dinBLEPeripheralScanner(self, didConnect: connectingDSPeripheral)
        self.connectedPeripheral = connectingDSPeripheral
        self.connectingPeripheral = nil
        stopScanning()
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Swift.Error?) {
        guard central === centralManager else { return }
        guard let connectingDSPeripheral = connectingPeripheral, peripheral === connectingDSPeripheral.peripheral else { return }

        if let error = error {
            delegate?.dinBLEPeripheralScanner(
                self,
                didFailToConnect: connectingDSPeripheral,
                error: .failedToConnect(error: error)
            )
        } else {
            delegate?.dinBLEPeripheralScanner(
                self,
                didFailToConnect: connectingDSPeripheral,
                error: .disconected
            )
        }
        self.connectingPeripheral = nil
        self.connectedPeripheral = nil
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Swift.Error?) {
        guard central === centralManager else { return }
        guard let connectedDSPeripheral = connectedPeripheral, peripheral === connectedDSPeripheral.peripheral else { return }

        if let error = error {
            delegate?.dinBLEPeripheralSCanner(
                self,
                didDisconnect: connectedDSPeripheral,
                error: .failedToConnect(error: error)
            )
        } else {
            delegate?.dinBLEPeripheralSCanner(
                self,
                didDisconnect: connectedDSPeripheral,
                error: .disconected
            )
        }
        self.connectingPeripheral = nil
        self.connectedPeripheral = nil
    }
}

extension DinBLEPeripheralScanner {
    public enum ScanError: Swift.Error {

        /// 蓝牙不可用
        case unavailable(state: CBManagerState)
    }

    public enum ConnectError: Swift.Error {

        /// 连接设备失败
        case failedToConnect(error: Swift.Error)

        /// 断开连接
        case disconected
    }
}
