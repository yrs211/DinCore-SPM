//
//  DinHttpParams+Default.swift
//  DinCore
//
//  Created by Jin on 2021/5/11.
//

import Foundation

public extension DinHttpParams {
    /// 使用DinCore的信息为参数打入User凭证
    /// - Parameters:
    ///   - params: 外层的参数
    ///   - dataParams: data的加密参数
    static func getParamsByUser(with params: [String: Any], dataParams: [String: Any]) -> DinHttpParams? {
        guard let user = DinCore.user else {
            return nil
        }
        // 自动添加
        let encryptSecret = DinCore.appSecret ?? ""
        // 增加用户id
        var encryptParams = dataParams
        encryptParams["userid"] = user.name

        var outterParams = params
        outterParams["gm"] = 1
        outterParams["token"] = user.userToken

        return DinHttpParams(with: outterParams,
                             dataParams: encryptParams,
                             encryptSecret: encryptSecret)
    }
}
