//
//  DinHttpProvider.swift
//  DinCore
//
//  Created by Jin on 2021/4/21.
//

import UIKit
import DinSupport

public typealias ApiSuccess = (_ result: [String: Any]?) -> Void
public typealias ApiFailure = (_ error: Error) -> Void

public struct DinHttpProvider {
    public static func request(_ httpRequest: DinHttpRequest, withoutResultChecked: Bool = false, success: ApiSuccess?, fail: ApiFailure?) {
        DinServer.shared.requestServer(with: httpRequest) { (data, _, error) in
            // 查看是否有网络错误
            if let requestError = error {
                fail?(requestError)
                return
            }

            let apiName = DinCore.apiDomain ?? "" + httpRequest.requestPath
            // 如果请求没有错误，需要获取请求的返回的data（此data不为空，且可以解析）
            guard let returnData = data else {
                fail?(DinNetwork.Error.noDataReturn(apiName))
                return
            }
            guard let returnDic = DinDataConvertor.convertToDictionary(returnData) else {
                if withoutResultChecked {
                    success?(["resultData": returnData])
                    return
                }
                fail?(DinNetwork.Error.dictionaryConvertFail(apiName))
                return
            }
            if withoutResultChecked {
                success?(returnDic)
                return
            }
            // 检查状态，status必须存在
            guard let status = returnDic["Status"] as? Int else {
                fail?(DinNetwork.Error.dataStatusNotFound(apiName))
                return
            }
            // 检查完毕，开始处理数据
            handleData(httpRequest, status: status, returnDict: returnDic, success: success, fail: fail)
        }
    }
}

// MARK: - 处理数据
extension DinHttpProvider {
    /// 处理接口返回的数据
    /// - Parameters:
    ///   - httpRequest: 请求的实例，在这里用作解密
    ///   - status: 接口返回的状态码
    ///   - returnDict: 接口返回的字典类型数据
    ///   - success: 成功回调
    ///   - fail: 失败回调
    static func handleData(_ httpRequest: DinHttpRequest, status: Int, returnDict: [String: Any], success: ApiSuccess?, fail: ApiFailure?) {
        if status != 1 {
            if httpRequest.requestPath.contains("logout") || !isUserAccountError(with: status) {
                let apiName = DinCore.apiDomain ?? "" + httpRequest.requestPath
                // 错误处理
                let errorMsg = returnDict["ErrorMessage"] as? String ?? ""
                fail?(DinNetwork.Error.statusFail(apiName, status, errorMsg))
            }
        } else {
            if let resultString = returnDict["Result"] as? String, resultString != "" {
                if let decoder = httpRequest.requestParam, let returnDic = decoder.decodeDataString(resultString) {
                    success?(returnDic)
                } else {
                    let apiName = DinCore.apiDomain ?? "" + httpRequest.requestPath
                    fail?(DinNetwork.Error.dictionaryConvertFail(apiName))
                }
            } else {
                // 结果为空字符串, 无需解密，直接返回
                success?(nil)
            }
        }
    }

    /// 如果是用户账号出问题了，不用上报错误，直接弹窗退出用户，返回到登录界面
    static private func isUserAccountError(with errorStatus: Int) -> Bool {
        // 如果检测到错误信息是
        // -11 没有找到该用户，包括修改密码时账户不存在的情况
        // -12 token过期
        // 马上弹框登出用户
        if errorStatus == -12 {
            DinCore.userDelegate?.dinCoreUserStateDidChange(state: .tokenExpired)
            return true
        }
        return false
    }
}
