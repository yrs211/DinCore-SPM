//
//  DinAuthRequest.swift
//  DinCore
//
//  Created by 郑少玲 on 2021/5/26.
//

import Foundation
import Moya
import DinSupport

enum DinAuthRequest {

    case changePassword(oldPwd: String, newPwd: String)             // 修改密码
    case changeAvatar(key: String)                                  // 修改头像
    case changeR2Avatar(key: String, source: Int)                   // R2版本修改头像
    case getUserData                                                // 获取用户信息
}

extension DinAuthRequest: DinHttpRequest {
    var requestPath: String {
        baseURL.absoluteString + path
    }

    var requestParam: DinHttpParams? {
        var jsonDict = [String: Any]()
        jsonDict["gmtime"] = Int64(Date().timeIntervalSince1970*1000000000)
        var token = DinCore.user?.userToken ?? ""

        switch self {
        case .changePassword(let oldPwd, let newPwd):
            jsonDict["oldpassword"] = oldPwd
            jsonDict["password"] = newPwd
            
        case .changeAvatar(let key):
            jsonDict["photo"] = key
            
        case .changeR2Avatar(let key, let source):
            jsonDict["photo"] = key
            jsonDict["source"] = source

        default:
            jsonDict.removeAll()
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
        var requestPath = "/auth/"

        switch self {
        case .changePassword:
            requestPath += "changepwd/v2/"
        case .changeAvatar:
            requestPath += "modifyuserinfos/v3/"
        case .changeR2Avatar:
            requestPath += "modifyuserinfos/v3/"
        case .getUserData:
            requestPath += "getuserdata/"
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
