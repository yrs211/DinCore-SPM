//
//  DinThirdPartyCameraRequest.swift
//  DinCore
//
//  Created by Jin on 2021/6/15.
//

import Foundation
import Moya
import DinSupport

enum DinThirdPartyCameraRequest {
    /// 注册第三方厂商IPC
    case addThirdPartyIPC(name: String, homeID: String, data: [String: Any])
    /// 删除第三方厂商IPC
    case deleteThirdPartyIPC(pid: String, homeID: String, provider: String)
    /// 获取第三方厂商IPC列表
    case getThirdPartyIPCList(homeID: String, provider: [String], pageSize: Int, addTime: Int64)
    /// 查询指定 pid 的第三方 ipc
    case searchThirdPartyIPCList(homeID: String, pids: [[String: Any]])
    /// 重命名第三方IPC
    case renameThirdPartyIPC(homID: String, pid: String, name: String, provider: String)
    /// 修改第三方IPC配置
    case updateThirdPartyIPCInfo(pid: String, homeID: String, data: [String: Any])
    /// 获取第三方IPC服务设置
    case getThirdPartyIPCServiceSetting(pid: String, homeID: String, provider: String)
    /// 修改第三方IPC服务设置
    case saveThirdPartyIPCServiceSetting(pid: String, homeID: String, provider: String, alertMode: String)
}

extension DinThirdPartyCameraRequest: DinHttpRequest {
    var requestPath: String {
        baseURL.absoluteString + path
    }

    var requestParam: DinHttpParams? {
        var jsonDict = [String: Any]()
        jsonDict["gmtime"] = Int64(Date().timeIntervalSince1970*1000000000)
        let token = DinCore.user?.userToken ?? ""

        switch self {
        case .addThirdPartyIPC(let name, let homeID, let data):
            jsonDict["name"] = name
            jsonDict["home_id"] = homeID
            data.forEach {
                jsonDict[$0] = $1
            }
        case .deleteThirdPartyIPC(let pid, let homeID, let provider):
            jsonDict["pid"] = pid
            jsonDict["home_id"] = homeID
            jsonDict["provider"] = provider

        case .getThirdPartyIPCList(let homeID, let provider, let pageSize, let addTime):
//            let jsonData = try? JSONSerialization.data(withJSONObject: provider, options: [])
            jsonDict["providers"] = provider
            jsonDict["page_size"] = pageSize
            jsonDict["home_id"] = homeID
            jsonDict["addtime"] = addTime
            jsonDict["order"] = "asc"
            
        case .searchThirdPartyIPCList(let homeID, let pids):
            jsonDict["home_id"] = homeID
            jsonDict["pids"] = pids

        case .renameThirdPartyIPC(let homeID, let pid, let name, let provider):
            jsonDict["pid"] = pid
            jsonDict["home_id"] = homeID
            jsonDict["name"] = name
            jsonDict["provider"] = provider

        case .updateThirdPartyIPCInfo(let pid, let homeID, let data):
            jsonDict["pid"] = pid
            jsonDict["home_id"] = homeID
            data.forEach {
                jsonDict[$0] = $1
            }
        case .getThirdPartyIPCServiceSetting(let pid, let homeID, let provider):
            jsonDict["pid"] = pid
            jsonDict["home_id"] = homeID
            jsonDict["provider"] = provider
        case .saveThirdPartyIPCServiceSetting(let pid, let homeID, let provider, let alertMode):
            jsonDict["pid"] = pid
            jsonDict["home_id"] = homeID
            jsonDict["provider"] = provider
            jsonDict["alert_mode"] = alertMode
            
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
        var requestPath = "/ipc/"

        switch self {
        case .addThirdPartyIPC:
            requestPath += "new-tp-ipc/"
        case .deleteThirdPartyIPC:
            requestPath += "del-tp-ipc/"
        case .getThirdPartyIPCList:
            requestPath += "list-tp-ipc/"
        case .searchThirdPartyIPCList:
            requestPath += "search-tp-ipc/"
        case .renameThirdPartyIPC:
            requestPath += "rename-tp-ipc/"
        case .updateThirdPartyIPCInfo:
            requestPath += "update-tp-ipc/"
        case .getThirdPartyIPCServiceSetting:
            requestPath += "get-ipc-service-settings/"
        case .saveThirdPartyIPCServiceSetting:
            requestPath += "update-ipc-service-settings/"
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
