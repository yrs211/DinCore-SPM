//
//  DinApi.swift
//  DinCore
//
//  Created by Jin on 2021/4/21.
//

import Foundation
import AlicloudHttpDNS
import Alamofire
import Moya

let DinCoreDomain: String = {
    if let cacheDomain = DinCore.dataBase.getDomain(), cacheDomain.count > 0 {
        return cacheDomain
    }
    return DinCore.apiDomain ?? ""
}()
let DinCoreStatisticsDomain: String = {
    if let cacheDomain = DinCore.dataBase.getStatisticsDomain(), cacheDomain.count > 0 {
        return cacheDomain
    }
    return DinCore.statisticsDomain ?? ""
}()
let DinCoreHost: String = "https://" + DinCoreDomain
let DinCoreCDN_Host: String = "http://d.din.bz/"
let DinCoreBaseURL = URL(string: DinCoreHost)!

struct DinApi {
    static func getURL() -> URL {
        if DinConstants.useWSS {
            DinCore.eventBus.basic.accept(serverIPChecked: "")
        }
        return DinCoreBaseURL
    }
}

extension MoyaProvider {
    func requestWithDoHUsingCoreSession(
            _ target: Target,
            completion: @escaping Completion
        ) {
            DinCore.dohManager.readValidIP(for: target.baseURL.host ?? DinCoreDomain) { ip in
                guard let ip = ip else {
                    // 获取 IP 失败，正常请求
                    self.request(target, completion: completion)
                    return
                }

                let endpointClosure: MoyaProvider<Target>.EndpointClosure = { target in
                    var url = target.baseURL.appendingPathComponent (target.path).absoluteString
                    
                    url = url.replacingOccurrences(of: target.baseURL.host ?? DinCoreDomain, with: ip)
                        
                    return Endpoint(url: url, sampleResponseClosure: {.networkResponse(200, target.sampleData) }, method: target.method, task: target.task, httpHeaderFields: target.headers)
                }
                
                // 创建新的 provider（只用于这次请求）
                let tempProvider = MoyaProvider<Target>(
                               endpointClosure: endpointClosure,
                               session: DinServer.shared.session //  使用DinServer提供的session
                           )
                tempProvider.request(target, completion: completion)
            }
        }
}
