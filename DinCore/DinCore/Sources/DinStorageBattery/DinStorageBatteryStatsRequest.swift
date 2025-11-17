//
//  DinStorageBatteryStatsRequest.swift
//  DinCore
//
//  Created by williamhou on 2023/2/27.
//

import Foundation
import Moya

enum DinStorageBatteryStatsRequest {
    case getStatsLoadusage(GetStatsParameters)
    case getStatsBattery(GetStatsParameters)
    case getStatsBatteryPowerlevel(GetStatsParameters)
    case getStatsGrid(GetStatsGridParameters)
    case getStatsMppt(GetStatsParameters)
    case getStatsRevenue(GetStatsParameters)
    case getStatsEco(GetStatsParameters)
    case getBSensorStatus(GetBSensorStatusParameters)
    case getStatsLoadusageV2(GetStatsParameters)
    case getStatsBatteryV2(GetStatsParameters)
    case getStatsMpptV2(GetStatsParameters)
    case getStatsRevenueV2(GetStatsParameters)
    case getStatsEcoV2(GetStatsParameters)
    case getChargingDischargingPlans(GetChargingDischargingPlansParameters)
    case getChargingDischargingPlansV2(GetChargingDischargingPlansParameters)
    case getChargingDischargingPlansV2Minute(GetChargingDischargingPlansParameters)
    
}

extension DinStorageBatteryStatsRequest: DinHttpRequest {
    var requestPath: String {
        baseURL.absoluteString + path
    }

    var requestParam: DinHttpParams? {
        var jsonDict = [String: Any]()
        jsonDict["gmtime"] = Int64(Date().timeIntervalSince1970*1000000000)
        let token = DinCore.user?.userToken ?? ""

        switch self {
        case .getStatsLoadusage(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
            jsonDict["offset"] = parameters.offset
        case .getStatsBattery(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
            jsonDict["offset"] = parameters.offset
        case .getStatsBatteryPowerlevel(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
            jsonDict["offset"] = parameters.offset
        case .getStatsGrid(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
            jsonDict["offset"] = parameters.offset
            jsonDict["get_real"] = parameters.get_real
            jsonDict["query_interval"] = parameters.query_interval
        case .getStatsMppt(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
            jsonDict["offset"] = parameters.offset
        case .getStatsRevenue(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
            jsonDict["offset"] = parameters.offset
        case .getStatsEco(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
            jsonDict["offset"] = parameters.offset
        case .getBSensorStatus(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
        case .getStatsLoadusageV2(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
            jsonDict["offset"] = parameters.offset
        case .getStatsBatteryV2(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
            jsonDict["offset"] = parameters.offset
        case .getStatsMpptV2(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
            jsonDict["offset"] = parameters.offset
        case .getStatsRevenueV2(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
            jsonDict["offset"] = parameters.offset
        case .getStatsEcoV2(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
            jsonDict["offset"] = parameters.offset
        case .getChargingDischargingPlans(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
            jsonDict["offset"] = parameters.offset
        case .getChargingDischargingPlansV2(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
        case .getChargingDischargingPlansV2Minute(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["id"] = parameters.deviceID
            jsonDict["model"] = parameters.model
        }

        return DinHttpParams(
            with: ["gm": 1, "token": token],
            dataParams: jsonDict,
            encryptSecret: DinCore.appSecret ?? ""
        )
    }

    var baseURL: URL {
        return URL(string: "https://\(DinCoreStatisticsDomain)") ?? DinApi.getURL()
    }

    var path: String {
        var result = "/bmt/"
        print("统计接口类型：\(self)")
        switch self {
        case .getStatsLoadusage(let getStatsParameters):
            result += "stats/load/usage/\(getStatsParameters.interval)/"
        case .getStatsBattery(let getStatsParameters):
            result += "stats/battery/\(getStatsParameters.interval)/"
        case .getStatsBatteryPowerlevel(let getStatsParameters):
            result += "stats/battery/power-level/\(getStatsParameters.interval)/"
        case .getStatsGrid(let getStatsParameters):
            result += "stats/grid/\(getStatsParameters.interval)/"
        case .getStatsMppt(let getStatsParameters):
            result += "stats/mppt/\(getStatsParameters.interval)/"
        case .getStatsRevenue(let getStatsParameters):
            result += "stats/revenue/\(getStatsParameters.interval)/"
        case .getStatsEco(let getStatsParameters):
            result += "stats/eco/\(getStatsParameters.interval)/"
        case .getBSensorStatus:
            result += "stats/b-sensor/"
        case .getStatsLoadusageV2(let getStatsParameters):
            result += "stats/load/usage-v2/\(getStatsParameters.interval)/"
        case .getStatsBatteryV2(let getStatsParameters):
            result += "stats/battery-v2/\(getStatsParameters.interval)/"
        case .getStatsMpptV2(let getStatsParameters):
            result += "stats/mppt-v2/\(getStatsParameters.interval)/"
        case .getStatsRevenueV2(let getStatsParameters):
            result += "stats/revenue-v2/\(getStatsParameters.interval)/"
        case .getStatsEcoV2(let getStatsParameters):
            result += "stats/eco-v2/\(getStatsParameters.interval)/"
        case .getChargingDischargingPlans(let getChargingDischargingPlansParameters):
            result += "stats/get-charging-discharging-plans/"
        case .getChargingDischargingPlansV2(let getChargingDischargingPlansParameters):
            result += "stats/get-charging-discharging-plans-v3/"
        case .getChargingDischargingPlansV2Minute(let getChargingDischargingPlansParameters):
            result += "stats/get-charging-discharging-plans-v2-minute/"
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
        return ["Host": DinCoreStatisticsDomain ?? "", "X-Online-Host": DinCoreStatisticsDomain ?? ""]
    }


}
