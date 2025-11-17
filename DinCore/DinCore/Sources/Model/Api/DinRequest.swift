//
//  DinRequest.swift
//  DinCore
//
//  Created by Jin on 2021/6/1.
//

import Foundation
import Moya

enum DinRequest {
    /// 获取配件信息
    case getPluginInfo(content: String)
    /// 获取NEW ASK配件信息(触发配对)
    case getNewASKInfo(panelId: String, stype: String, sendid: String, homeID: String)
    /// 获取手机出现网络不稳定的log
    case uploadNetworkStateLog(errMessage: String)
}

extension DinRequest: DinHttpRequest {
    var requestPath: String {
        baseURL.absoluteString + path
    }

    var requestParam: DinHttpParams? {
        var jsonDict = [String: Any]()
        jsonDict["gmtime"] = Int64(Date().timeIntervalSince1970*1000000000)
        let token = DinCore.user?.userToken ?? ""

        switch self {
        case .getPluginInfo:
            break
        case .getNewASKInfo(let panelId, let stype, let sendid, let homeID):
            jsonDict["stype"] = stype
            jsonDict["sendid"] = sendid
            jsonDict["deviceid"] = panelId
            jsonDict["home_id"] = homeID

        case .uploadNetworkStateLog(let errorMessage):
            jsonDict["system"] = "iOS"
            jsonDict["log"] = errorMessage
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
        switch self {
        case .getPluginInfo(let content):
            return "/qrcode/scan/"+content+"/"+(DinCore.appID ?? "")+"/"
        case .getNewASKInfo:
            return "/pluginqrcode/getnewaskdata/"+(DinCore.appID ?? "")
        case .uploadNetworkStateLog:
            return "/device/addclientlog/v2/"+(DinCore.appID ?? "")
        }
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
