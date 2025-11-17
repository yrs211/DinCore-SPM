//
//  DinFixRequest.swift
//  DinCore
//
//  Created by williamhou on 2024/4/26.
//

import Foundation
import Moya

enum DinFixRequest {
    // 生成家庭授权转移码，用于移交设备
    case genHomeQrcode(GenHomeQrcodeParameters)
    // 安装人员转移设备
    case operatorTransfer(OperatorTransferParameters)
}

extension DinFixRequest: DinHttpRequest {
    var requestPath: String {
        baseURL.absoluteString + path
    }

    var requestParam: DinHttpParams? {
        var jsonDict = [String: Any]()
        jsonDict["gmtime"] = Int64(Date().timeIntervalSince1970*1000000000)
        let token = DinCore.user?.userToken ?? ""

        switch self {
        case .genHomeQrcode(let parameters):
            jsonDict["home_id"] = parameters.homeID
        case .operatorTransfer(let parameters):
            jsonDict["bmt_id"] = parameters.bmtId
            jsonDict["model"] = parameters.model
            jsonDict["qr_code"] = parameters.qrCode
            jsonDict["ticket_id"] = parameters.ticketId
        }

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
        case .genHomeQrcode(let genHomeQrcodeParameters):
            result += "gen-home-qrcode/"
        case .operatorTransfer(let operatorTransferParameters):
            result += "operator/transfer/"
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
