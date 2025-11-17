//
//  DinStorageBatteryRequest+Parameters.swift
//  DinCore
//
//  Created by monsoir on 11/29/22.
//

import Foundation

extension DinStorageBatteryRequest {
    struct GetDevicesParameters {
        let homeID: String
        let models: [String]
        let order: String? // `asc` or `desc`
        let addTime: Int64

        init(
            homeID: String,
            models: [String],
            order: String? = nil,
            addTime: Int64 = 0
        ) {
            self.homeID = homeID
            self.models = models
            self.order = order
            self.addTime = addTime
        }
    }

    typealias GetDevicesEndIDsParameters = SearchDeviceParameters

    struct LoginDevicesParameters {
        let homeID: String
        let devices: [Device]
        let models: [String]

        struct Device {
            let id: String
            let model: String
        }
    }

    typealias LogoutDevicesParameters = LoginDevicesParameters

    struct DeleteDeviceParameters {
        let homeID: String
        let deviceID: String
        let model: String
    }

    struct GetBatteryCellsCountParameters {
        let homeID: String
        let models: [String]
    }

    struct RegisterDeviceParameters {
        let homeID: String
        let deviceID: String
        let model: String
        let name: String
        let registerToken: String

#warning("structure is not confirmed yet")
        let versions: [String: String]
    }

    struct ConfirmDeviceRegisterationParameters {
        let registerToken: String
    }

    struct RenameParameters {
        let homeID: String
        let deviceID: String
        let model: String
        let name: String
    }

    struct SearchDeviceParameters {
        let homeID: String
        let conditions: [Condition]

        struct Condition {
            let deviceID: String
            let model: String
        }
    }

    struct UpdateRegionParameters {
        let homeID: String
        let deviceID: String
        let countryCode: String
        let model: String
        let region: String
        let timezone: String
    }

    struct GetRegionParameters {
        let homeID: String
        let deviceID: String
        let model: String
    }

    struct BindInverterParameters {
        let bmtId: String
        let homeID: String
        let inverterID: String
        let mcuID: String
        let model: String
    }
    
    struct GetElecPriceInfoParameters {
        let homeID: String
        let deviceID: String
        let model: String
        // 天的偏移量（0 表示当天的数据，-n 表示前 n 天的数据）
        let offset: Int
    }
    
    struct GetFusePowerCapsParameters {
        let json: [String:Any]
    }    
    
    struct GetDualPowerOpenParameters {
        let homeID: String
        let deviceID: String
    }

    struct GetFeatureParameters {
        let homeID: String
        let deviceID: String
        let model: String
    }
    
    struct ContractInfoParameters {
        let homeID: String
        let data: [String: Any]
    }
    
    struct ContractR2InfoParameters {
        let homeID: String
        let data: [String: Any]
        let source: Int
    }
    
    struct UpdateElectricityContractParameters {
        let homeID: String
        let electricityContractName: String
        let electricityContract: String
    }
    
    struct GetRegionElectricitySupplierListParameters {
        let countryCode: String
    }
    
    struct GetRegionElectricitySupplierListV3Parameters {
        let countryCode: String
        let homeID: String
    }
    
    struct TeminateBalanceContactParameters {
        let homeID: String
        let sign: String
    }
    
    struct TeminateR2BalanceContactParameters {
        let homeID: String
        let sign: String
        let source: Int
    }
    
    struct GetBalanceContractRecordsParameter {
        let createTime: Int64
        let homeID: String
        let pageSize: Int
    }
    
    struct GetBalanceContractRecordByIdParameter {
        let homeID: String
        let recordId: String
    }
    
    struct CheckStorageBatteryBalanceContractStatusParameters {
        let deviceID: String
        let homeID: String
    }
    
    struct UpdateBalanceContractBankParameters {
        let IBAN: String
        let homeID: String
        let password: String
        let cardholder: String
    }
    
    struct GetBalanceContractUnsignTempleteParameter {
        let homeID: String
    }
    
    struct GetAIModeSettingsParameter {
        let homeID: String
        let deviceID: String
        let model: String
    }
    
    struct SetLocallySwitchParameter {
        let homeID: String
        let deviceID: String
        let model: String
        let enable: Bool
    }
    
    struct SetBmtInitPeakShavingParameter {
        let id: String
        let initPeakShaving: Bool
    }
    
    struct GetHomeLocationParameter {
        let homeID: String
    }
    
    struct SaveHomeLocationParameter {
        let homeID: String
        let latitude: Double
        let longitude: Double
    }
    
    struct GetBmtLocationParameter {
        let homeID: String
        let deviceID: String
        let model: String
    }
    
    struct AddBalanceContractParticipationHoursParameter {
        let homeID: String
        let allDay: Bool
        let start: String   // 格式：10:00
        let end: String
        let repeatDays: [Int] // 0-6，分别代表周日到周六
    }
    
    struct UpdateBalanceContractParticipationHoursParameter {
        let homeID: String
        let id: String
        let allDay: Bool
        let start: String   // 格式：10:00
        let end: String
        let repeatDays: [Int] // 0-6，分别代表周日到周六
    }
    
    struct DeleteBalanceContractParticipationHoursParameter {
        let homeID: String
        let id: String
    }
    
    struct GetBalanceContractParticipationHoursListParameter {
        let createTime: Int64
        let homeID: String
        let pageSize: Int
    }
    
    typealias getIsTaskTimeInUpdatedRangeParameters = UpdateBalanceContractParticipationHoursParameter
    
    
}
