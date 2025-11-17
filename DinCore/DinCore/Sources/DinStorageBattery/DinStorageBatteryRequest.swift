//
//  DinStorageBatteryRequest.swift
//  DinCore
//
//  Created by monsoir on 11/29/22.
//

import Foundation
import Moya

enum DinStorageBatteryRequest {

    case getDevices(GetDevicesParameters)

    case getDevicesEndid(GetDevicesEndIDsParameters)

    case loginDevices(LoginDevicesParameters)

    case logoutDevices(LogoutDevicesParameters)

    case deleteDevice(DeleteDeviceParameters)

    case getBatteryCellsCount(GetBatteryCellsCountParameters)

    case getRegionList

    case registerDevice(RegisterDeviceParameters)

    case confirmDeviceRegisterations(ConfirmDeviceRegisterationParameters)

    case rename(RenameParameters)

    case searchDevice(SearchDeviceParameters)

    case updateRegion(UpdateRegionParameters)

    case getRegion(GetRegionParameters)

    case bindInverter(BindInverterParameters)
    
    case getElecPriceInfo(GetElecPriceInfoParameters)
    
    case getFusePowerCaps(GetFusePowerCapsParameters)
    
    case getDualPowerOpen(GetDualPowerOpenParameters)

    case getFeature(GetFeatureParameters)
    
    case saveFamilyContractInfo(ContractInfoParameters)
    
    case updateElectricityContract(UpdateElectricityContractParameters)

    case saveR2FamilyContractInfo(ContractR2InfoParameters)
    
    case getFamilyContractInfo(String)
    
    case updateBalanceContractData(String)

    case getRegionElectricitySupplierList(GetRegionElectricitySupplierListParameters)
    
    case getRegionElectricitySupplierListV3(GetRegionElectricitySupplierListV3Parameters)
    
    case terminateBalanceContract(TeminateBalanceContactParameters)
    
    case terminateR2BalanceContract(TeminateR2BalanceContactParameters)
    
    case getBalanceContractRecords(GetBalanceContractRecordsParameter)
    
    case GetBalanceContractRecordById(GetBalanceContractRecordByIdParameter)
    
    case checkStorageBatteryBalanceContractStatus(CheckStorageBatteryBalanceContractStatusParameters)
    
    case updateBalanceContractBank(UpdateBalanceContractBankParameters)
    
    case getBalanceContractUnsignTemplete(GetBalanceContractUnsignTempleteParameter)
    
    case getBalanceContractSignTemplete(String)
    
    case getAIModeSettings(GetAIModeSettingsParameter)
    
    case getLocallySwitch(GetAIModeSettingsParameter)
    case setLocallySwitch(SetLocallySwitchParameter)
    
    case getHomeLocation(GetHomeLocationParameter)
    
    case saveHomeLocation(SaveHomeLocationParameter)
    
    case getBmtLocation(GetBmtLocationParameter)
    
    case addBalanceContractParticipationHours(AddBalanceContractParticipationHoursParameter)
    
    case updateBalanceContractParticipationHours(UpdateBalanceContractParticipationHoursParameter)
    
    case deleteBalanceContractParticipationHours(DeleteBalanceContractParticipationHoursParameter)
    
    case getBalanceContractParticipationHoursList(GetBalanceContractParticipationHoursListParameter)
    
    case getIsTaskTimeInUpdatedRange(getIsTaskTimeInUpdatedRangeParameters)
    
    case setBmtInitPeakShaving(SetBmtInitPeakShavingParameter)
}

extension DinStorageBatteryRequest: DinHttpRequest {
    var requestPath: String {
        baseURL.absoluteString + path
    }

    var requestParam: DinHttpParams? {
        var jsonDict = [String: Any]()
        jsonDict["gmtime"] = Int64(Date().timeIntervalSince1970*1000000000)
        let token = DinCore.user?.userToken ?? ""

        switch self {
        case .getDevices(let parameters):
            jsonDict["addtime"] = parameters.addTime
            jsonDict["home_id"] = parameters.homeID
            jsonDict["models"] = parameters.models
            if let value = parameters.order {
                jsonDict["order"] = value
            }
            jsonDict["page_size"] = 50
        case .getDevicesEndid(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["ids"] = parameters.conditions.map {
                [
                    "id": $0.deviceID,
                    "model": $0.model,
                ]
            }
        case .loginDevices(let parameters):
            jsonDict["addtime"] = 0
            jsonDict["home_id"] = parameters.homeID
            if let value = parameters.devices.first {
                jsonDict["ids"] = [
                    [
                        "id": value.id,
                        "model": value.model,
                    ],
                ]
            }
            jsonDict["models"] = parameters.models
            jsonDict["page_size"] = 100
            if let thirdpartyUID = DinCore.user?.thirdpartyUID, !thirdpartyUID.isEmpty {
                jsonDict["user_id"] = thirdpartyUID
            }
        case .logoutDevices(let parameters):
            jsonDict["addtime"] = 0
            jsonDict["home_id"] = parameters.homeID
            if let value = parameters.devices.first {
                jsonDict["ids"] = [
                    [
                        "id": value.id,
                        "model": value.model,
                    ],
                ]
            }
            jsonDict["models"] = parameters.models
            jsonDict["page_size"] = 100
            if let thirdpartyUID = DinCore.user?.thirdpartyUID, !thirdpartyUID.isEmpty {
                jsonDict["user_id"] = thirdpartyUID
            }
        case .deleteDevice(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
        case .getBatteryCellsCount(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["models"] = parameters.models
        case .getRegionList:
            break
        case .registerDevice(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
            jsonDict["name"] = parameters.name
            jsonDict["reg_token"] = parameters.registerToken

#warning("structure is not confirmed yet")
            jsonDict["versions"] = parameters.versions
        case .confirmDeviceRegisterations(let parameters):
            jsonDict["reg_token"] = parameters.registerToken
        case .rename(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
            jsonDict["name"] = parameters.name
        case .searchDevice(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["ids"] = parameters.conditions.map {
                [
                    "id": $0.deviceID,
                    "model": $0.model,
                ]
            }
        case .updateRegion(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["country_code"] = parameters.countryCode
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
            jsonDict["region"] = parameters.region
            jsonDict["timezone"] = parameters.timezone
        case .getRegion(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
        case .bindInverter(let parameters):
            jsonDict["bmt_id"] = parameters.bmtId
            jsonDict["home_id"] = parameters.homeID
            jsonDict["inverter_id"] = parameters.inverterID
            jsonDict["mcu_id"] = parameters.mcuID
            jsonDict["model"] = parameters.model
        case .getElecPriceInfo(let parameters):
            jsonDict["bmt_id"] = parameters.deviceID
            jsonDict["home_id"] = parameters.homeID
            jsonDict["model"] = parameters.model
            jsonDict["offset"] = parameters.offset
            jsonDict["force"] = false
        case .getFusePowerCaps(let parameters):
            jsonDict["json"] = parameters.json
        case .getDualPowerOpen(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["bmt_id"] = parameters.deviceID
        case .getFeature(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
        case .saveFamilyContractInfo(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["data"] = parameters.data
        case .saveR2FamilyContractInfo(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["data"] = parameters.data
            jsonDict["source"] = parameters.source
        case .updateElectricityContract(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["electricity_contract_name"] = parameters.electricityContractName
            jsonDict["electricity_contract"] = parameters.electricityContract
        case .getFamilyContractInfo(let homeID):
            jsonDict["home_id"] = homeID
        case .updateBalanceContractData(let homeID):
            jsonDict["home_id"] = homeID
        case .getRegionElectricitySupplierList(let parameters):
            jsonDict["country_code"] = parameters.countryCode
        case .getRegionElectricitySupplierListV3(let parameters):
            jsonDict["country_code"] = parameters.countryCode
            jsonDict["home_id"] = parameters.homeID
        case .terminateBalanceContract(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["sign"] = parameters.sign
        case .terminateR2BalanceContract(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["sign"] = parameters.sign
            jsonDict["source"] = parameters.source
        case .getBalanceContractRecords(let parameters):
            jsonDict["create_time"] = parameters.createTime
            jsonDict["home_id"] = parameters.homeID
            jsonDict["page_size"] = parameters.pageSize
        case .GetBalanceContractRecordById(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["record_id"] = parameters.recordId
        case .checkStorageBatteryBalanceContractStatus(let parameters):
            jsonDict["device_id"] = parameters.deviceID
            jsonDict["home_id"] = parameters.homeID
        case .updateBalanceContractBank(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["pwd"] = parameters.password
            jsonDict["cardholder"] = parameters.cardholder
            jsonDict["IBAN"] = parameters.IBAN
        case .getBalanceContractUnsignTemplete(let parameters):
            jsonDict["home_id"] = parameters.homeID
        case .getBalanceContractSignTemplete(let countryCode):
            jsonDict["country_code"] = countryCode
        case .getAIModeSettings(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
        case .getLocallySwitch(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
        case .setLocallySwitch(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
            jsonDict["enable"] = parameters.enable
        case .getHomeLocation(let parameters):
            jsonDict["home_id"] = parameters.homeID
        case .saveHomeLocation(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["latitude"] = parameters.latitude
            jsonDict["longitude"] = parameters.longitude
        case .getBmtLocation(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["bmt_id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
        case .addBalanceContractParticipationHours(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["all_day"] = parameters.allDay
            jsonDict["start"] = parameters.start
            jsonDict["end"] = parameters.end
            jsonDict["repeat"] = parameters.repeatDays
        case .updateBalanceContractParticipationHours(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.id
            jsonDict["all_day"] = parameters.allDay
            jsonDict["start"] = parameters.start
            jsonDict["end"] = parameters.end
            jsonDict["repeat"] = parameters.repeatDays
        case .deleteBalanceContractParticipationHours(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.id
        case .getBalanceContractParticipationHoursList(let parameters):
            jsonDict["create_time"] = parameters.createTime
            jsonDict["home_id"] = parameters.homeID
            jsonDict["page_size"] = parameters.pageSize
        case .getIsTaskTimeInUpdatedRange(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.id
            jsonDict["all_day"] = parameters.allDay
            jsonDict["start"] = parameters.start
            jsonDict["end"] = parameters.end
            jsonDict["repeat"] = parameters.repeatDays
        case .setBmtInitPeakShaving(let parameters):
            jsonDict["id"] = parameters.id
            jsonDict["init_peak_shaving"] = parameters.initPeakShaving
        }

        print("jsonDict:\(jsonDict)")
        return DinHttpParams(
            with: ["gm": 1, "token": token],
            dataParams: jsonDict,
            encryptSecret: DinCore.appSecret ?? ""
        )
    }

    var baseURL: URL { DinApi.getURL() }

    var path: String {
        var result = "/bmt/"

        switch self {
        case .getDevices:
            result += "list-bmt/"
        case .getDevicesEndid:
            result += "search-bmt/"
        case .loginDevices:
            result += "e2e-user-login/"
        case .logoutDevices:
            result += "e2e-user-logout/"
        case .deleteDevice:
            result += "delete/"
        case .getBatteryCellsCount:
            result += "get-bmt-count/"
        case .getRegionList:
            result += "list-region-countries/"
        case .registerDevice:
            result += "new-bmt/"
        case .confirmDeviceRegisterations:
            result += "reg-token-ack/"
        case .rename:
            result += "rename/"
        case .searchDevice:
            result += "search-bmt/"
        case .updateRegion:
            result += "update-region/"
        case .getRegion:
            result += "get-region/"
        case .bindInverter:
            result += "bind-inverter/"
        case .getElecPriceInfo:
            result += "get-elec-price-info/"
        case .getFusePowerCaps(_):
            result += "get-fuse-power-caps-v2/"
        case .getDualPowerOpen(_):
            result += "is-dual-power-open/"
        case .getFeature(_):
            result += "get-feature/"
        case .saveFamilyContractInfo(_):
            result += "save-family-balance-contract-info-v3/"
        case .updateElectricityContract(_):
            result += "update-balance-contract-electricity-contract/"
        case .saveR2FamilyContractInfo(_):
            result += "save-family-balance-contract-info-v3/"
        case .getFamilyContractInfo(_):
            result += "get-family-balance-contract-info/"
        case .updateBalanceContractData(_):
            result += "update-balance-contract-data/"
        case .getRegionElectricitySupplierList(_):
            result += "list-region-electricity-supplier-v2/"
        case .getRegionElectricitySupplierListV3(_):
            result += "list-region-electricity-supplier-v3/"
        case .terminateBalanceContract:
            result += "terminate-balance-contract-v3/"
        case .terminateR2BalanceContract:
            result += "terminate-balance-contract-v3/"
        case .getBalanceContractRecords:
            result += "get-balance-contract-records-v3/"
        case .GetBalanceContractRecordById:
            result += "get-balance-contract-record-by-id/"
        case .checkStorageBatteryBalanceContractStatus:
            result += "check-device-balance-contract-status/"
        case .updateBalanceContractBank:
            result += "update-balance-contract-bank/"
        case .getBalanceContractUnsignTemplete:
            result += "get-balance-contract-unsign-template-v3/"
        case .getBalanceContractSignTemplete:
            result += "get-balance-contract-sign-template/"
        case .getAIModeSettings(_):
            result += "get-default-price-percent/"
        case .getLocallySwitch(_):
            result += "get-locally-switch/"
        case .setLocallySwitch(_):
            result += "set-locally-switch/"
        case .getHomeLocation(_):
            result += "get-home-location/"
        case .saveHomeLocation(_):
            result += "save-location/"
        case .getBmtLocation(_):
            result += "get-bmt-location/"
        case .addBalanceContractParticipationHours(_):
            result += "add-balance-contract-participation-hours/"
        case .updateBalanceContractParticipationHours(_):
            result += "update-balance-contract-participation-hours/"
        case .deleteBalanceContractParticipationHours(_):
            result += "delete-balance-contract-participation-hours/"
        case .getBalanceContractParticipationHoursList(_):
            result += "list-balance-contract-participation-hours/"
        case .getIsTaskTimeInUpdatedRange(_):
            result += "is-task-time-in-updated-range/"
        case .setBmtInitPeakShaving(_):
            result += "set-bmt-init-peak-shaving/"
        }

        return result + (DinCore.appID ?? "")
    }

    var method: Moya.Method { .post }

    public var parameters: [String : Any]? {
        requestParam?.uploadDict
    }

    var task: Moya.Task {
        if parameters != nil {
            return .requestParameters(parameters: parameters!, encoding: URLEncoding.default)
        } else {
            return .requestPlain
        }
    }

    var headers: [String : String]? {
        ["Host": DinCoreDomain, "X-Online-Host": DinCoreDomain]
    }


}
