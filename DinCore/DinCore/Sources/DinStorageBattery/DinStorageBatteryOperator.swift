//
//  DinStorageBatteryOperator.swift
//  DinCore
//
//  Created by monsoir on 11/28/22.
//

import Foundation
import RxSwift
import HandyJSON
//经营类
class DinStorageBatteryOperator: NSObject, DinHomeDeviceProtocol {

    var id: String { control.model.id }

    var manageTypeID: String { "" }

    var category: String { "" }

    var subCategory: String { "" }

    var info: [String : Any] { control.info ?? [:] }

    var fatherID: String?

    var deviceCallback: Observable<[String : Any]> { control.deviceCallback }

    var deviceStatusCallback: Observable<Bool> { control.deviceStatusCallback }

    var saveJsonString: String {
        DinCore.cryptor.rc4EncryptToHexString(
            with: control.model.toJSONString() ?? "",
            key: DinStorageBatteryOperator.encryptString()
        ) ?? ""
    }

    let control: DinStorageBatteryControl

    let disposeBag = DisposeBag()

    init?(homeID: String, rawString: String) {
        guard
            let decodeString = DinCore.cryptor.rc4DecryptHexString(rawString, key: Self.encryptString()),
            let model = DinStorageBattery.deserialize(from: decodeString)
        else { return nil }

        self.control = Self.createControl(from: model, homeID: homeID)

        super.init()
        DinCore.eventBus.basic.udpSocketDisconnectObservable.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.control.disconnect()
        }).disposed(by: disposeBag)
    }

    class func createControl(from model: DinStorageBattery, homeID: String) -> DinStorageBatteryControl {
        fatalError("Implement in subclass")
    }

    init(control: DinStorageBatteryControl) {
        self.control = control
        super.init()

        DinCore.eventBus.basic.udpSocketDisconnectObservable.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.control.disconnect()
        }).disposed(by: disposeBag)
    }

    func submitData(_ data: [String : Any]) {
        if let command = DinStorageBatteryMSCTCommand(rawValue: (data["cmd"] as? String) ?? "") {
            submit(msctCommand: command, parameters: data)
        }

        if let command = DinStorageBatteryHTTPCommand(rawValue: (data["cmd"] as? String) ?? "") {
            submit(httpCommand: command, parameters: data)
        }
    }

    private func submit(msctCommand command: DinStorageBatteryMSCTCommand, parameters: [String: Any]) {
        print("发送msctCommand数据----\(command)")
        switch command {

            // Connection
        case .connect:
            control.connect(discardCache: parameters["discardCache"] as? Bool ?? false)
        case .disconnect:
            control.disconnect()
        case .connectStatusChangedNotify: break

            // Inverter
        case .getInverterInputInfo:
            control.getInverterInputInfo()
        case .getInverterOutputInfo:
            control.getInverterOutputInfo()
        case .getInverterInfoByIndex:
            control.getInverterInfo(at: parameters["index"] as? Int)
        case .inverterExceptionsNotify: break
        case .resetInverter:
            control.resetInverter()
            
            // Battery
        case .getBatteryAccessoryStateByIndex:
            control.getBatteryAccessoryState(at: parameters["index"] as? Int)
        case .getBatteryInfoByIndex:
            control.getBatteryInfo(at: parameters["index"] as? Int)
        case .batchGetBatteryInfo:
            control.getBatteryAllInfo()
        case .batchTurnOffBattery:
            control.batchTurnOffBattery()
        case .batteryAccessoryStateChangedNotify: break
        case .batteryAccessoryStateChangedCustomNotify: break
        case .batteryIndexChangedNotify: break
        case .batteryExceptionsNotify: break
        case .batteryStatusInfoNotify: break

            // EV
        case .getEVState:
            control.getEVState()
        case .evExceptionsNotify: break

            // MPPT
        case .getMPPTState:
            control.getMPPTState()
        case .mpptExceptionsNotify: break

            // MCU
        case .getMCUInfo:
            control.getMCUInfo()

            // Cabinet
        case .getCabinetInfo:
            control.getCabinetInfo()
        case .getCabinetStateByIndex:
            control.getCaninetState(at: parameters["index"] as? Int)
        case .cabinetIndexChangedNotify: break
        case .cabinetStateChangedNotify: break
        case .cabinetExceptionChangedNotify: break

            // Global
        case .getGlobalLoadState:
            control.getGlobalLoadState()
        case .getGlobalExceptions:
            control.getGlobalExceptions()
        case .getGlobalDisplayExceptions:
            control.getGlobalDisplayExceptions()
        case .systemExceptionsNotify: break
        case .communicationExceptionsNotify: break

            // Strategy
        case .getEmergencyChargingSettings:
            control.getEmergencyChargeSettings()
        case .setEmergencyCharging:
            control.setEmergencyCharging(
                isOn: parameters["on"] as? Bool,
                startTime: {
                    if let value = parameters["startTime"] as? TimeInterval { return UInt32(value) }
                    return nil
                }(),
                endTime: {
                    if let value = parameters["endTime"] as? TimeInterval { return UInt32(value) }
                    return nil
                }()
            )
        case .getGridChargeMargin:
            control.getGridChargeMargin()
        case .setChargingStrategies:
            control.setChargeStrategy(
                strategyType: parameters["strategyType"] as? Int,
                smartReserve: parameters["smartReserve"] as? Int,
                goodPricePercentage: parameters["goodPricePercentage"] as? Int,
                emergencyReserve: parameters["emergencyReserve"] as? Int,
                acceptablePricePercentage: parameters["acceptablePricePercentage"] as? Int
            )
        case .getChargingStrategies:
            control.getChargingStrategies()
        case .setVirtualPowerPlant:
            control.setVirtualPowerPlant(userID: parameters["userID"] as? String, isOn: parameters["on"] as? Bool)
        case .getVirtualPowerPlant:
            control.getVirtualPowerPlant()
        case .setSellingProtection:
            control.setSellingProtection(
                isOn: parameters["on"] as? Bool,
                threshold: parameters["threshold"] as? Int
            )
        case .getSellingProtection:
            control.getSellingProtection()
        case .getSignals:
            control.getSignals()
        case .reset:
            control.resetDevice()
        case .reboot:
            control.rebootDevice()
        case .getAdvanceInfo:
            control.getAdvanceInfo()
        case .setGlobalLoaderOpen:
            control.setGlobalLoaderOpen(parameters["open"] as? Bool)
        case .getMode:
            control.getMode()
        case .getModeV2:
            control.getModeV2()
        case .getChipsStatus:
            control.getChipsStatus()
        case .getChipsUpdateProgress:
            control.getChipsUpdateProgress()
        case .updateChips:
            control.updateChips()

            // Charge, Discharge
        case .getCurrentReserveMode:
            control.getCurrentReserveMode()
        case .getPriceTrackReserveMode:
            control.getPriceTrackReserveMode()
        case .getScheduleReserveMode:
            control.getScheduleReserveMode()
        case .getCustomScheduleMode:
            control.getCustomScheduleMode()
        case .setReserveMode:
            control.setReserveMode(parameters["reserveMode"] as? Int, smart: parameters["smart"] as? Int, emergency: parameters["emergency"] as? Int, weekdays: parameters["weekdays"] as? [Int], weekends: parameters["weekend"] as? [Int], sync: parameters["sync"] as? Bool,type: parameters["type"] as? Int)
        case .getCurrentEVChargingMode:
            control.getCurrentEVChargingMode()
        case .getEVChargingModeSchedule:
            control.getEVChargingModeSchedule()
        case .setEVChargingMode:
            control.setEVChargingMode(parameters["evChargingMode"] as? Int, weekdays: parameters["weekdays"] as? [Int], weekends: parameters["weekend"] as? [Int], sync: parameters["sync"] as? Bool)
        case .setEVChargingModeInstant:
            control.setEVChargingModeInstant(parameters["evChargingMode"] as? Int, fixed: parameters["fixed"] as? Int)
        case .setEvchargingModeInstantcharge:
            control.setEvchargingModeInstantcharge(parameters["open"] as? Bool)
        case .getSmartEvStatus:
            control.getSmartEvStatus()
        case .setSmartEvStatus:
            control.setSmartEvStatus(toggleStatus: parameters["toggleStatus"] as? Int, requestRestart: parameters["requestRestart"] as? Bool)
        case .getCurrentEVAdvanceStatus:
            control.getCurrentEVAdvancestatus()
        case .evAdvanceStatusChangedNotify: break
        case .getEVChargingInfo:
            control.getEVChargingInfo()
        case .getCustomScheduleModeAI:
            control.getCustomScheduleModeAI()
        case .setReserveModeAI:
            control.setReserveModeAi(
                smart: parameters["smart"] as? Int,
                emergency: parameters["emergency"] as? Int,
                chargeDischargeData: parameters["chargeDischargeData"] as? [Int],
                type: parameters["type"] as? Int
            )
        case .setRegion:
            control.setRegion(
                isPriceTrackingSupported: parameters["is_price_tracking_supported"] as? Bool,
                countryCode: parameters["country_code"] as? String,
                countryName: parameters["country_name"] as? String,
                cityName: parameters["city_name"] as? String,
                timezone: parameters["timezone"] as? String,
                deliveryArea: parameters["delivery_area"] as? String
            )
        case .setExceptionIgnore:
            control.setExceptionIgnore(parameters["ignoreException"] as? Int)
        case .getGlobalCurrentFlowInfo:
            control.getGlobalCurrentFlowInfo(parameters["dataMode"] as? UInt8)
        case .getGridConnectionConfig:
            control.getGridConnectionConfig()
        case .updateGridConnectionConfig:
            control.updateGridConnectionConfig(
                powerPercent: parameters["powerPercent"] as? Float,
                appFastPowerDown: parameters["appFastPowerDown"] as? Bool,
                quMode: parameters["quMode"] as? Bool,
                cosMode: parameters["cosMode"] as? Bool,
                antiislandingMode: parameters["antiislandingMode"] as? Bool,
                highlowMode: parameters["highlowMode"] as? Bool,
                
                activeSoftStartRate: parameters["activeSoftStartRate"] as? Float,
                overfrequencyLoadShedding: parameters["overfrequencyLoadShedding"] as? Float,
                overfrequencyLoadSheddingSlope: parameters["overfrequencyLoadSheddingSlope"] as? Float,
                underfrequencyLoadShedding: parameters["underfrequencyLoadShedding"] as? Float,
                underfrequencyLoadSheddingSlope: parameters["underfrequencyLoadSheddingSlope"] as? Float,
                powerFactor: parameters["powerFactor"] as? Float,
                reconnectTime: parameters["reconnectTime"] as? Float,
                gridOvervoltage1: parameters["gridOvervoltage1"] as? Float,
                gridOvervoltage1ProtectTime: parameters["gridOvervoltage1ProtectTime"] as? Float,
                gridOvervoltage2: parameters["gridOvervoltage2"] as? Float,
                gridOvervoltage2ProtectTime: parameters["gridOvervoltage2ProtectTime"] as? Float,
                gridUndervoltage1: parameters["gridUndervoltage1"] as? Float,
                gridUndervoltage1ProtectTime: parameters["gridUndervoltage1ProtectTime"] as? Float,
                gridUndervoltage2: parameters["gridUndervoltage2"] as? Float,
                gridUndervoltage2ProtectTime: parameters["gridUndervoltage2ProtectTime"] as? Float,

                gridOverfrequency1: parameters["gridOverfrequency1"] as? Float,
                gridOverfrequencyProtectTime: parameters["gridOverfrequencyProtectTime"] as? Int,
                gridOverfrequency2: parameters["gridOverfrequency2"] as? Float,
                gridUnderfrequency1: parameters["gridUnderfrequency1"] as? Float,
                gridUnderfrequencyProtectTime: parameters["gridUnderfrequencyProtectTime"] as? Int,
                gridUnderfrequency2: parameters["gridUnderfrequency2"] as? Float,

                reconnectSlope: parameters["reconnectSlope"] as? Float,
                rebootGridOvervoltage: parameters["gridUndervoltage2ProtectTime"] as? Float,
                rebootGridUndervoltage: parameters["gridUndervoltage2ProtectTime"] as? Float,
                rebootGridOverfrequency: parameters["gridUndervoltage2ProtectTime"] as? Float,
                rebootGridUnderfrequency: parameters["gridUndervoltage2ProtectTime"] as? Float
            )
        case .resumeGridConnectionConfig:
            control.resumeGridConnectionConfig()
        case .getFirmwares:
            control.getFirmwares(parameters["type"] as? Int)
        case .setFuseSpecs:
            control.setFuseSpecs(powerCap: parameters["power_cap"] as? Int, spec: parameters["spec"] as? String)
        case .getFuseSpecs:
            control.getFuseSpecs()
        case .getThirdPartyPVInfo:
            control.getThirdPartyPVInfo()
        case .setThirdPartyPVOn:
            control.setThirdPartyPVOn(isOn: parameters["on"] as? Bool)
        case .getRegulateFrequencyState:
            control.getRegulateFrequencyState()
        case .getPVDist:
            control.getPVDist()
        case .setPVDist:
            control.setPVDist(
                ai: parameters["ai"] as? Int,
                scheduled: parameters["scheduled"] as? Int
            )
        case .getAllSupportFeatures:
            control.getAllSupportFeatures()
        case .getBrightnessSettings:
            control.getBrightnessSettings()
        case .getSoundSettings:
            control.getSoundSettings()
        case .setBrightnessSettings:
            control.setBrightnessSettings(brightness: parameters["brightness"] as? Int)
        case .setSoundSettings:
            control.setSoundSettings(systemTones: parameters["systemTones"] as? Bool,
                                     reminderAlerts: parameters["reminderAlerts"] as? Bool )
        // peakshaving
        case .togglPeakShaving:
            control.togglPeakShaving(isOn: parameters["isOn"] as? Bool )
        case .setPeakShavingPoints:
            control.setPeakShavingPoints(
                point1: parameters["point1"] as? Int,
                point2: parameters["point2"] as? Int
            )
        case .setPeakShavingRedundancy:
            control.setPeakShavingRedundancy(
                redundancy:parameters["redundancy"] as? Int
            )
        case .getPeakShavingConfig:
            control.getPeakShavingConfig()
        case .getPeakShavingSchedule:
            control.getPeakShavingSchedule()
        case .addPeakShavingSchedule:
            control.addPeakShavingSchedule(
                schedules:parameters["schedules"] as? [[String: Any]]
            )
        case .delPeakShavingSchedule:
            control.delPeakShavingSchedule(
                scheduleId:parameters["scheduleId"] as? Int
            )
        }
    }

    private func submit(httpCommand command: DinStorageBatteryHTTPCommand, parameters: [String: Any]) {
        print("发送httpCommand数据----\(command)")
        switch command {
        case .getRegionList:
            control.getRegionList()
        case .updateRegion:
            control.updateRegion(
                countryCode: parameters["country_code"] as? String ?? "",
                countryName: parameters["country_name"] as? String ?? "",
                cityName: parameters["city_name"] as? String ?? "",
                timezone: parameters["timezone"] as? String ?? ""
            )
        case .getRegion:
            control.getRegion()
        case .rename:
            control.rename(parameters)
        case .getStatsLoadusage:
            control.getStatsLoadusage(
                interval: parameters["interval"] as? String ?? "",
                offset: parameters["offset"] as? Int ?? 0)
        case .getStatsLoadusageV2:
            control.getStatsLoadusageV2(
                interval: parameters["interval"] as? String ?? "",
                offset: parameters["offset"] as? Int ?? 0)
        case .getStatsBattery:
            control.getStatsBattery(
                interval: parameters["interval"] as? String ?? "",
                offset: parameters["offset"] as? Int ?? 0)
        case .getStatsBatteryV2:
            control.getStatsBatteryV2(
                interval: parameters["interval"] as? String ?? "",
                offset: parameters["offset"] as? Int ?? 0)
        case .getStatsBatteryPowerlevel:
            control.getStatsBatteryPowerlevel(
                interval: parameters["interval"] as? String ?? "",
                offset: parameters["offset"] as? Int ?? 0)
        case .getStatsGrid:
            control.getStatsGrid(
                interval: parameters["interval"] as? String ?? "",
                offset: parameters["offset"] as? Int ?? 0,
                get_real: parameters["get_real"] as? Bool ?? false,
                query_interval: parameters["query_interval"] as? Int ?? 1)
        case .getStatsMppt:
            control.getStatsMppt(
                interval: parameters["interval"] as? String ?? "",
                offset: parameters["offset"] as? Int ?? 0)
        case .getStatsMpptV2:
            control.getStatsMpptV2(
                interval: parameters["interval"] as? String ?? "",
                offset: parameters["offset"] as? Int ?? 0)
        case .getStatsRevenue:
            control.getStatsRevenue(
                interval: parameters["interval"] as? String ?? "",
                offset: parameters["offset"] as? Int ?? 0)
        case .getStatsRevenueV2:
            control.getStatsRevenueV2(
                interval: parameters["interval"] as? String ?? "",
                offset: parameters["offset"] as? Int ?? 0)
        case .getStatsEco:
            control.getStatsEco(
                interval: parameters["interval"] as? String ?? "",
                offset: parameters["offset"] as? Int ?? 0)
        case .getStatsEcoV2:
            control.getStatsEcoV2(
                interval: parameters["interval"] as? String ?? "",
                offset: parameters["offset"] as? Int ?? 0)
        case .getElecPriceInfo:
            control.getElecPriceInfo(offset: parameters["offset"] as? Int ?? 0)
        case .getChargingDischargingPlans:
            control.getChargingDischargingPlans(offset: parameters["offset"] as? Int ?? 0)
        case .getChargingDischargingPlansV2:
            control.getChargingDischargingPlansV2()
        case .getChargingDischargingPlansV2Minute:
            control.getChargingDischargingPlansV2Minute()
        case .getBSensorStatus:
            control.getBSensorStatus()
        case .bindInverter:
            control.bindInverter(
                inverterID: parameters["inverter_id"] as? String ?? "",
                mcuID: parameters["mcu_id"] as? String ?? "")
        case .getFusePowerCaps:
            control.getFusePowerCaps()
        case .getDualPowerOpen:
            control.getDualPowerOpen()
        case .getFeature:
            control.getFeature()
        case .getAIModeSettings:
            control.getAIModeSettings()
        case .getLocallySwitch:
            control.getLocallySwitch()
        case .setLocallySwitch:
            control.setLocallySwitch(isEnable: parameters["enable"] as? Bool ?? false)
        case .getBmtLocation:
            control.getBmtLocation()
        case .setBmtInitPeakShaving:
            control.setBmtInitPeakShaving(isEnable: parameters["enable"] as? Bool ?? false)
        }
    }

    func destory() {}

    static func encryptString() -> String { DinCore.appSecret ?? "" }
}
