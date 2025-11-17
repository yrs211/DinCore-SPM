//
//  DinNovaWidgetRequest.swift
//  DinCore
//
//  Created by monsoir on 6/17/21.
//

import Foundation
import Moya

enum DinNovaWidgetRequest {

    /// 获取主机防干扰设置
    case getAntiInterferenceStatus(parameter: Parameter.GetAntiInterferenceStatus)

    /// 修改主机防干扰设置
    case modifyConfCover(parameter: Parameter.ModifyConfCover)
    case listTimerConf(parameter: Parameter.ListTimerConf)
    case modifyConf(parameter: Parameter.ModifyConf)
    case deleteConf(parameter: Parameter.DeleteConf)
    case listAddonConf(parameter: Parameter.ListAddOnConf)

    var path: String {
        var url = "/deviceaddon/"
        switch self {
        case .getAntiInterferenceStatus:
            url += "listoneaddonconf/"
        case .modifyConfCover:
            url += "modifyconfcover/"
        case .listTimerConf:
            url += "listtimerconf/"
        case .modifyConf:
            url += "modifyconf/"
        case .deleteConf:
            url += "deleteconf/"
        case .listAddonConf:
            url += "listaddonconf/"
        }

        return url + (DinCore.appID ?? "")
    }

    var parameters: [String : Any]? {
        requestParam?.uploadDict
    }

    var task: Moya.Task {
        if let parameters = parameters {
            return .requestParameters(
                parameters: parameters,
                encoding: URLEncoding.default
            )
        }
        return .requestPlain
    }

    var baseURL: URL { DinApi.getURL() }

    var method: Moya.Method {
        return .post
    }

    var sampleData: Data {
        "Half measures are as bad as nothing at all."
            .data(using: .utf8)!
    }

    var headers: [String: String]? {
        [
            "Host": DinCoreDomain,
            "X-Online-Host": DinCoreDomain,
        ]
    }
}

extension DinNovaWidgetRequest: DinHttpRequest {
    var requestPath: String { baseURL.absoluteString + path }

    var requestParam: DinHttpParams? {
        var dict = [String: Any]()
        dict["gmtime"] = Int64(Date().timeIntervalSince1970 * 1000000000)

        switch self {
        case .getAntiInterferenceStatus(let parameter):
            dict["deviceid"] = parameter.deviceID
            dict["addontype"] = parameter.addOnType
        case .modifyConfCover(let parameter):
            dict["deviceid"] = parameter.deviceID
            dict["addontype"] = parameter.addOnType
            if let confString = parameter.confString {
                dict["conf"] = confString
            }
        case .modifyConf(let parameter):
            dict["deviceid"] = parameter.deviceID
            dict["addontype"] = parameter.addOnType
            if let addOnID = parameter.addOnID { dict["addonid"] = addOnID }
            if let type = parameter.type { dict["type"] = type }
            dict["conf"] = parameter.conf
        case .deleteConf(let parameter):
            dict["deviceid"] = parameter.deviceID
            dict["addontype"] = parameter.addOnType
            dict["addonid"] = parameter.addOnID
        case .listAddonConf(let parameter):
            dict["deviceid"] = parameter.deviceID
            dict["addontype"] = parameter.addOnType
        case .listTimerConf(let parameter):
            dict["deviceid"] = parameter.deviceID
        }

        return DinHttpParams(
            with: ["gm": 1, "token": DinCore.user?.userToken ?? ""],
            dataParams: dict,
            encryptSecret: DinCore.appSecret ?? ""
        )
    }
}
