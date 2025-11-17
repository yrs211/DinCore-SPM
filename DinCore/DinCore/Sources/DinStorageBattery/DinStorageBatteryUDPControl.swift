//
//  DinStorageBatteryUDPControl.swift
//  DinCore
//
//  Created by monsoir on 12/1/22.
//

import Foundation
import DinSupport

//udp控制代理
protocol DinStorageBatteryUDPControlDelegate: AnyObject {
    func dinStorageBatteryUDPControl(
        _ control: DinStorageBatteryUDPControl,
        didReceive command: DinStorageBatteryMSCTCommand,
        messageID: String,
        result: Result<Data, Swift.Error>
    )
}

//udp控制处理器
final
class DinStorageBatteryUDPControl: DinDeviceControl {

    weak var delegate: DinStorageBatteryUDPControlDelegate?
      ///接收其他通信结果
    override func receiveOtherCommunicationResult(_ result: DinMSCTResult) {
        if let cmd = DinStorageBatteryMSCTCommand.commandOfBytes(result.method) {
            self.delegate?.dinStorageBatteryUDPControl(self, didReceive: cmd, messageID: result.messageID, result: .success(result.payloadData ?? Data()))
        }
    }
///请求保持实时通信
    override func requestKeepliveCommunication(deliverType: DinDeviceUDPDeliverType, withSuccess success: DinCommunicationCallback.SuccessBlock?, fail: DinCommunicationCallback.FailureBlock?, timeout: DinCommunicationCallback.TimeoutBlock?) -> DinCommunication? {
        if deliverType == .lan {
//            return lanKeepliveCommunication(withSuccess: success, fail: fail, timeout: timeout)
            return lanKeepliveCommunication(
                withSuccess: { result in
                    success?(result)
                },
                fail: { error in
                    fail?(error)
                },
                timeout: { msgID in
                    timeout?(msgID)
                }
            )
        } else if deliverType == .p2p {
//            return p2pKeepliveCommunication(withSuccess: success, fail: fail, timeout: timeout)
            return p2pKeepliveCommunication(
                withSuccess: { result in
                    success?(result)
                },
                fail: { error in
                    fail?(error)
                },
                timeout: { msgID in
                    timeout?(msgID)
                }
            )
        } else {
//            return proxyKeepliveCommunication(withSuccess: success, fail: fail, timeout: timeout)
            return proxyKeepliveCommunication(
                withSuccess: { result in
                    success?(result)
                },
                fail: { error in
                    fail?(error)
                },
                timeout: { msgID in
                    timeout?(msgID)
                }
            )
        }
    }

    private func lanKeepliveCommunication(withSuccess success: DinCommunicationCallback.SuccessBlock?, fail: DinCommunicationCallback.FailureBlock?, timeout: DinCommunicationCallback.TimeoutBlock?) -> DinCommunication? {
        return heartbeat(withTargetID: communicationDevice.uniqueID, success: success, fail: fail, timeout: timeout)
    }
    private func p2pKeepliveCommunication(withSuccess success: DinCommunicationCallback.SuccessBlock?, fail: DinCommunicationCallback.FailureBlock?, timeout: DinCommunicationCallback.TimeoutBlock?) -> DinCommunication? {
        return heartbeat(withTargetID: communicationDevice.uniqueID, success: success, fail: fail, timeout: timeout)
    }
    private func proxyKeepliveCommunication(withSuccess success: DinCommunicationCallback.SuccessBlock?, fail: DinCommunicationCallback.FailureBlock?, timeout: DinCommunicationCallback.TimeoutBlock?) -> DinCommunication? {
        return heartbeat(withTargetID: communicationDevice.uniqueID, success: success, fail: fail, timeout: timeout)
    }

    private func heartbeat(
        withTargetID targetID: String,
        success: DinCommunicationCallback.SuccessBlock?,
        fail: DinCommunicationCallback.FailureBlock?,
        timeout: DinCommunicationCallback.TimeoutBlock?
    ) -> DinCommunication? {
        let msgID = String.UUID()
        let ackCallback = DinCommunicationCallback(successBlock: success, failureBlock: fail, timeoutBlock: timeout)

        let params = DinOperateTaskParams(
            with: dataEncryptor,
            source: communicationIdentity,
            destination: communicationDevice,
            messageID: msgID,
            sendInfo: nil,
            ignoreSendInfoInNil: true
        )
        return DinCommunicationGenerator.heartbeat(
            params,
            targetID: targetID,
            ackCallback: ackCallback,
            entryCommunicator: nil
        )
    }
}

extension DinStorageBatteryUDPControl {

    //发送指令
    func execute(command: DinStorageBatteryMSCTCommand, messageID: String, parameters: Any? = nil) {
        ///指令成功回调
        let ackCallback = DinCommunicationCallback(
            successBlock: { [weak self] result in
                guard let self = self else { return }
                self.delegate?.dinStorageBatteryUDPControl(self, didReceive: command, messageID: result.messageID, result: .success(result.payloadData ?? Data()))

            },
            failureBlock: { [weak self] error in
                guard let self = self else { return }
                self.delegate?.dinStorageBatteryUDPControl(self, didReceive: command, messageID: messageID, result: .failure(ExecutionFailure(reason: error)))
            },
            timeoutBlock: { [weak self] msgID in
                guard let self = self else { return }
                self.delegate?.dinStorageBatteryUDPControl(self, didReceive: command, messageID: msgID, result: .failure(TimeoutFailure()))
            }
        )

        var customCMDTimeout: TimeInterval = 0
        if command == .setRegion {
            // iOT需要6s时间和服务器进行友好交流，所以这里需要等10s保底
            customCMDTimeout = 10
        }

        var options = [OptionHeader]()
        options.append(OptionHeader(id: DinMSCTOptionID.method, data: command.header))
        let params = DinOperateTaskParams(
            with: dataEncryptor,
            source: communicationIdentity,
            destination: communicationDevice,
            messageID: messageID,
            sendInfo: parameters,
            ignoreSendInfoInNil: true,
            optionHeaders: options
        )
        _ = DinCommunicationGenerator.operateTask(
            params,
            ackCallback: ackCallback,
            resultCallback: nil,
            ackTimeoutSec: customCMDTimeout,
            entryCommunicator: communicator
        )
    }
}

extension DinStorageBatteryUDPControl {

    struct TimeoutFailure: Swift.Error {
        let reason = "request timeout"
    }

    struct ExecutionFailure: Swift.Error {
        let reason: String
    }
}

extension DinStorageBatteryMSCTCommand {

    static func commandOfBytes(_ bytes: [UInt8]?) -> DinStorageBatteryMSCTCommand? {
        guard let bytes = bytes else { return nil }
        switch bytes {

        // inverter
        case [0x01, 0x10]: return .getInverterOutputInfo
        case [0x02, 0x10]: return .getInverterInputInfo
        case [0x04, 0x10]: return .getInverterInfoByIndex
        case [0x02, 0x20]: return .inverterExceptionsNotify
        case [0x32, 0xA0]: return .resetInverter

        // battery
        case [0x0C, 0x10]: return .getBatteryAccessoryStateByIndex
        case [0x06, 0x10]: return .getBatteryInfoByIndex
        case [0x03, 0x20]: return .batteryExceptionsNotify
        case [0x05, 0x10]: return .batchGetBatteryInfo
        case [0x02, 0x00]: return .batchTurnOffBattery
        case [0x06, 0x20]: return .batteryAccessoryStateChangedNotify
        case [0x15, 0xA0]: return .batteryAccessoryStateChangedCustomNotify
        case [0x01, 0x20]: return .batteryIndexChangedNotify
        case [0x14, 0xA0]: return .batteryStatusInfoNotify

        // EV
        case [0x0A, 0x10]: return .getEVState
        case [0x05, 0x20]: return .evExceptionsNotify

        // MPPT
        case [0x08, 0x10]: return .getMPPTState
        case [0x04, 0x20]: return .mpptExceptionsNotify

        // MCU
        case [0x03, 0x10]: return .getMCUInfo

        // Cabinet
        case [0x0E, 0x10]: return .getCabinetInfo
        case [0x0D, 0x10]: return .getCabinetStateByIndex
        case [0x07, 0x20]: return .cabinetStateChangedNotify
        case [0x08, 0x20]: return .cabinetIndexChangedNotify
        case [0x09, 0x20]: return .cabinetExceptionChangedNotify

            // Global
        case [0x07, 0x10]: return .getGlobalLoadState
        case [0x00, 0x10]: return .getGlobalExceptions
        case [0x33, 0xA0]: return .getGlobalDisplayExceptions
        case [0x04, 0x00]: return .setGlobalLoaderOpen
        case [0x0A, 0x20]: return .systemExceptionsNotify
        case [0x0B, 0x20]: return .communicationExceptionsNotify
        case [0x30, 0xA0]: return .getGlobalCurrentFlowInfo

            // Strategy
        case [0x02, 0xA0]: return .getEmergencyChargingSettings
        case [0x01, 0xA0]: return .setEmergencyCharging
        case [0x5D, 0xA0]: return .getGridChargeMargin
        case [0x03, 0xA0]: return .setChargingStrategies
        case [0x04, 0xA0]: return .getChargingStrategies
        case [0x05, 0xA0]: return .setVirtualPowerPlant
        case [0x06, 0xA0]: return .getVirtualPowerPlant
        case [0x07, 0xA0]: return .getSignals
        case [0x08, 0xA0]: return .reset
        case [0x09, 0xA0]: return .reboot
        case [0x10, 0xA0]: return .getAdvanceInfo
        case [0x09, 0x10]: return .getMode

            // Charge, Discharge
        case [0x16, 0xA0]: return .getCurrentReserveMode
        case [0x17, 0xA0]: return .getPriceTrackReserveMode
        case [0x18, 0xA0]: return .getScheduleReserveMode
        case [0x19, 0xA0]: return .setReserveMode
        case [0x20, 0xA0]: return .getCurrentEVChargingMode
        case [0x21, 0xA0]: return .getEVChargingModeSchedule
        case [0x22, 0xA0]: return .setEVChargingMode
        case [0x31, 0xA0]: return .setEVChargingModeInstant
        case [0x25, 0xA0]: return .getCurrentEVAdvanceStatus
        case [0x26, 0xA0]: return .evAdvanceStatusChangedNotify
        case [0x27, 0xA0]: return .getEVChargingInfo
        case [0x29, 0xA0]: return .setEvchargingModeInstantcharge
        case [0x50, 0xA0]: return .getSmartEvStatus
        case [0x51, 0xA0]: return .setSmartEvStatus
        case [0x24, 0xA0]: return .setRegion
        case [0x28, 0xA0]: return .setExceptionIgnore
        case [0x34, 0xA0]: return .getGridConnectionConfig
        case [0x35, 0xA0]: return .updateGridConnectionConfig
        case [0x36, 0xA0]: return .resumeGridConnectionConfig
        case [0x1a, 0xA0]: return .setReserveModeAI
        case [0x1b, 0xA0]: return .getCustomScheduleModeAI

        case [0x37, 0xA0]: return .getFirmwares
            
        case [0x38, 0xA0]: return .setFuseSpecs
        case [0x39, 0xA0]: return .getFuseSpecs
        case [0x45, 0xA0]: return .getRegulateFrequencyState
        case [0x46, 0xA0]: return .getCustomScheduleMode
        case [0x47, 0xA0]: return .getPVDist
        case [0x48, 0xA0]: return .setPVDist
        case [0x52, 0xA0]: return .getAllSupportFeatures
        default:
            return nil
        }
    }

    private var bytes: [UInt8] {
        switch self {
        case .connect, .disconnect, .connectStatusChangedNotify: return []

            // inverter
        case .getInverterOutputInfo: return [0x10, 0x01]
        case .getInverterInputInfo: return [0x10, 0x02]
        case .getInverterInfoByIndex: return [0x10, 0x04]
        case .inverterExceptionsNotify: return [0x20, 0x02]
        case .resetInverter: return [0xA0, 0x32]

            // battery
        case .getBatteryAccessoryStateByIndex: return [0x10, 0x0C]
        case .getBatteryInfoByIndex: return [0x10, 0x06]
        case .batteryExceptionsNotify: return [0x20, 0x03]
        case .batchGetBatteryInfo: return [0x10, 0x05]
        case .batchTurnOffBattery: return [0x00, 0x02]
        case .batteryAccessoryStateChangedNotify: return [0x20, 0x06]
        case .batteryAccessoryStateChangedCustomNotify: return [0xA0, 0x15]
        case .batteryIndexChangedNotify: return [0x20, 0x01]
        case .batteryStatusInfoNotify: return [0xA0, 0x14]

            // EV
        case .getEVState: return [0x10, 0x0A]
        case .evExceptionsNotify: return [0x20, 0x05]
        case .getCurrentEVAdvanceStatus: return [0xA0, 0x25]
        case .evAdvanceStatusChangedNotify: return [0xA0, 0x26]
        case .getEVChargingInfo: return [0xA0, 0x27]
        case .getSmartEvStatus: return [0xA0, 0x50]
        case .setSmartEvStatus: return [0xA0, 0x51]

            // MPPT
        case .getMPPTState: return [0x10, 0x08]
        case .mpptExceptionsNotify: return [0x20, 0x04]

            // MCU
        case .getMCUInfo: return [0x10, 0x03]

            // Cabinet
        case .getCabinetInfo: return [0x10, 0x0E]
        case .getCabinetStateByIndex: return [0x10, 0x0D]
        case .cabinetStateChangedNotify: return [0x20, 0x07]
        case .cabinetIndexChangedNotify: return [0x20, 0x08]
        case .cabinetExceptionChangedNotify: return [0x20, 0x09]

            // Global
        case .getGlobalLoadState: return [0x10, 0x07]
        case .getGlobalExceptions: return [0x10, 0x00]
        case .getGlobalDisplayExceptions: return [0xA0, 0x33]
        case .setGlobalLoaderOpen: return [0x00, 0x04]
        case .systemExceptionsNotify: return [0x20, 0x0A]
        case .communicationExceptionsNotify: return [0x20, 0x0B]
        case .getGlobalCurrentFlowInfo: return [0xA0, 0x30]

            // Strategy
        case .getEmergencyChargingSettings: return [0xA0, 0x02]
        case .setEmergencyCharging: return [0xA0, 0x01]
        case .getGridChargeMargin: return [0xA0, 0x5D]
        case .setChargingStrategies: return [0xA0, 0x03]
        case .getChargingStrategies: return [0xA0, 0x04]
        case .setVirtualPowerPlant: return [0xA0, 0x05]
        case .getVirtualPowerPlant: return [0xA0, 0x06]
        case .getSellingProtection: return [0xA0, 0x5F]
        case .setSellingProtection: return [0xA0, 0x5E]

            // setting
        case .getSignals: return [0xA0, 0x07]
        case .reset: return [0xA0, 0x08]
        case .reboot: return [0xA0, 0x09]
        case .getAdvanceInfo: return [0xA0, 0x10]
        case .getMode: return [0x10, 0x09]
        case .getModeV2: return [0xA0, 0x43]
        case .getChipsStatus: return [0xA0, 0x11]
        case .getChipsUpdateProgress: return [0xA0, 0x12]
        case .updateChips: return [0xA0, 0x13]

            // Charge, Discharge
        case .getCurrentReserveMode: return [0xA0, 0x16]
        case .getPriceTrackReserveMode: return [0xA0, 0x17]
        case .getScheduleReserveMode: return [0xA0, 0x18]
        case .setReserveMode: return [0xA0, 0x19]
        case .getCurrentEVChargingMode: return [0xA0, 0x20]
        case .getEVChargingModeSchedule: return [0xA0, 0x21]
        case .setEVChargingMode: return [0xA0, 0x22]
        case .setEVChargingModeInstant: return [0xA0, 0x31]
        case .setEvchargingModeInstantcharge: return [0xA0, 0x29]
        case .setReserveModeAI: return [0xA0, 0x1a]
        case .getCustomScheduleModeAI: return [0xA0, 0x1b]

        case .setRegion: return [0xA0, 0x24]
        case .setExceptionIgnore: return [0xA0, 0x28]
        case .getGridConnectionConfig: return [0xA0, 0x34]
        case .updateGridConnectionConfig: return [0xA0, 0x35]
        case .resumeGridConnectionConfig: return [0xA0, 0x36]
            
        case .getFirmwares: return [0xA0, 0x37]
            
        case .setFuseSpecs: return [0xA0, 0x38]
        case .getFuseSpecs: return [0xA0, 0x39]
            
        case .getThirdPartyPVInfo: return [0xA0, 0x40]
        case .setThirdPartyPVOn: return [0xA0, 0x41]
        case .getRegulateFrequencyState: return [0xA0, 0x45]
        case .getCustomScheduleMode: return [0xA0, 0x46]
            
        case .getPVDist: return [0xA0, 0x47]
        case .setPVDist: return [0xA0, 0x48]
        case .getAllSupportFeatures: return [0xA0, 0x52]
            
        case .getBrightnessSettings: return [0xA0, 0x53]
        case .setBrightnessSettings: return [0xA0, 0x54]
        case .getSoundSettings: return [0xA0, 0x55]
        case .setSoundSettings: return [0xA0, 0x56]
        // peak shaving
        case .togglPeakShaving: return [0xA0,0x57]
        case .setPeakShavingPoints:return [0xA0,0x58]
        case .setPeakShavingRedundancy:return [0xA0,0x59]
        case .getPeakShavingConfig:return [0xA0,0x5b]
        case .getPeakShavingSchedule:return [0xA0,0x5c]
        case .addPeakShavingSchedule:return [0xA0,0x5a]
        case .delPeakShavingSchedule:return [0xA0,0x77]
        }
    }

    fileprivate var header: Data {
        let theBytes = bytes
        switch theBytes.isEmpty {
        case true: return Data()
        case false: return Data(theBytes.reversed())
        }
    }
}
