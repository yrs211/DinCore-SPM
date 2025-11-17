//
//  DinQRCodeRequest.swift
//  DinCore
//
//  Created by 郑少玲 on 2021/6/9.
//

import Foundation
import Moya
import DinSupport

enum DinQRCodeRequest {
    /// 扫描配件
    case getPluginInfoWithCode(codeStr: String)
    /// 扫描ipc二维码
    case getCameraDataWithCode(codeStr: String, homeID: String)
}

extension DinQRCodeRequest: DinHttpRequest {
    var requestPath: String {
        baseURL.absoluteString + path
    }

    var requestParam: DinHttpParams? {
        var jsonDict = [String: Any]()
        jsonDict["gmtime"] = Int64(Date().timeIntervalSince1970*1000000000)
        let token = DinCore.user?.userToken ?? ""

        switch self {
        case .getCameraDataWithCode(_, let homeID):
            jsonDict["home_id"] = homeID
        default:
            break
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
        var requestPath = "/qrcode/"

        switch self {
        case .getPluginInfoWithCode(let codeStr):
            requestPath += "scan/" + codeStr + "/"
        case .getCameraDataWithCode(let codeStr, _):
            requestPath += "scan/ipc/" + codeStr + "/"
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
