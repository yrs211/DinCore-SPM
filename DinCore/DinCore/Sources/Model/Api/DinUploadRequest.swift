//
//  DinUploadRequest.swift
//  DinCore
//
//  Created by 郑少玲 on 2021/5/6.
//

import Foundation
import Moya
import DinSupport

enum DinUploadRequest {
    case getUploadToken
    case getR2Toekn(_ parameters: DinR2FileForm)
}

extension DinUploadRequest: DinHttpRequest {
    var requestPath: String {
        baseURL.absoluteString + path
    }

    var requestParam: DinHttpParams? {
        var jsonDict = [String: Any]()
        jsonDict["gmtime"] = Int64(Date().timeIntervalSince1970*1000000000)
        let token = DinCore.user?.userToken ?? ""

        switch self {
        case .getR2Toekn(let parameters):
            jsonDict["content_length"] = parameters.contentLength
            jsonDict["content_type"] = parameters.contentType
            jsonDict["file_extension"] = parameters.fileExtension
            jsonDict["type"] = parameters.type
            jsonDict["home_id"] = parameters.homeID
            jsonDict["file_name"] = parameters.fileName
            break
        default:
            jsonDict.removeAll()
        }

        let encryptSecret = DinCore.appSecret ?? ""
        if jsonDict.count == 0 {
            return DinHttpParams(with: ["token": "\(token)", "gm": 1],
                                 dataParams: [:],
                                 encryptSecret: encryptSecret)
        } else {
            return DinHttpParams(with: ["gm": 1],
                                 dataParams: jsonDict,
                                 encryptSecret: encryptSecret)
        }
    }

    public var baseURL: URL {
        return DinApi.getURL()
    }

    public var path: String {
        var requestPath = "/uploader/"

        switch self {
        case .getUploadToken:
            requestPath += "getuptoken/"
            break
        case .getR2Toekn:
            requestPath = "/bmt/get-app-cloudflare-r2-upload-token/"
            
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
