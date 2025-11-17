//
//  DinNovaPluginRequest.swift
//  DinCore
//
//  Created by Jin on 2021/5/27.
//

import Foundation
import Moya

enum DinNovaPluginRequest {
    /// 获取门磁类型配件
    case doorSensorList(id: String, homeID: String)
    /// get plugin detail to push plugin detail view. Temporary use in main view
    case getPluginDetail(deviceID: String, category: Int, stype: String, sendID: String, pluginID: String, homeID: String)
    /// get main view show plugins
    case getDeviceMainPlugins(deviceID: String, homeID: String)
    // 获取智能按钮列表
    case getSmartBtnList(deviceID: String, homeID: String)
    // 获取智能按钮配置
    case getSmartBtnConfig(deviceID: String, sendID: String, stype: String, homeID: String)
    // 获取主安防插件信息
    case getSecurityPluginList(deviceID: String, homeID: String)
}

extension DinNovaPluginRequest: DinHttpRequest {
    var requestPath: String {
        baseURL.absoluteString + path
    }

    var requestParam: DinHttpParams? {
        var jsonDict = [String: Any]()
        jsonDict["gmtime"] = Int64(Date().timeIntervalSince1970*1000000000)
        let token = DinCore.user?.userToken ?? ""

        switch self {
        case .doorSensorList(let id, let homeID):
            jsonDict["deviceid"] = id
            jsonDict["home_id"] = homeID

        case .getPluginDetail(let deviceID, let category, let stype, let sendID, let pluginID, let homeID):
            jsonDict["device_id"] = deviceID
            jsonDict["category"] = category
            jsonDict["stype"] = stype
            jsonDict["sendid"] = sendID
            jsonDict["id"] = pluginID
            jsonDict["home_id"] = homeID

        case .getDeviceMainPlugins(let deviceID, let homeID):
            jsonDict["device_id"] = deviceID
            jsonDict["home_id"] = homeID

        case .getSmartBtnList(let deviceID, let homeID):
            jsonDict["deviceid"] = deviceID
            jsonDict["home_id"] = homeID

        case .getSmartBtnConfig(let deviceID, let sendID, let stype, let homeID):
            jsonDict["deviceid"] = deviceID
            jsonDict["sendid"] = sendID
            jsonDict["stype"] = stype
            jsonDict["home_id"] = homeID

        case .getSecurityPluginList(let deviceID, let homeID):
            jsonDict["deviceid"] = deviceID
            jsonDict["home_id"] = homeID
        }

        let encryptSecret = DinCore.appSecret ?? ""
        return DinHttpParams(with: ["gm": 1, "token": token],
                             dataParams: jsonDict,
                             encryptSecret: encryptSecret)
    }

    public var baseURL: URL {
        return DinApi.getURL()
    }

    public var path: String {
        var requestPath = "/device/"

        switch self {
        case .doorSensorList:
            requestPath += "listdoorsensorsetting/v2/"
        case .getPluginDetail:
            requestPath += "get-plugin-details/"
        case .getDeviceMainPlugins:
            requestPath += "get-plugin-info/"
        case .getSmartBtnList:
            requestPath += "list-smart-button/"
        case .getSmartBtnConfig:
            requestPath += "get-smart-button-conf/"
        case .getSecurityPluginList:
            requestPath += "listaccessorysetting/v2/"
        }

        return requestPath + (DinCore.appID ?? "")
    }

    public var method: Moya.Method {
        return .post
    }

    public var parameters: [String : Any]? {
        requestParam?.uploadDict
    }

    public var task: Moya.Task {
        if parameters != nil {
            return .requestParameters(parameters: parameters!, encoding: URLEncoding.default)
        } else {
            return .requestPlain
        }
    }

    public var validate: Bool {
        return true
    }

    public var sampleData: Data {
        return "Half measures are as bad as nothing at all.".data(using: .utf8)!
    }

    public var headers: [String: String]? {
        return ["Host": DinCoreDomain, "X-Online-Host": DinCoreDomain]
    }
}
