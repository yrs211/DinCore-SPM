//
//  DinUserRequest.swift
//  DinCore
//
//  Created by Jin on 2021/4/21.
//

import Foundation
import Moya
import DinSupport

enum DinUserRequest {
    /// 登录 1:phone, 2:
    case login(phone: String? = nil, email: String? = nil, uid: String? = nil, password: String)
    /// 登出
    case logout
    /// 邮箱注册，发送验证码
    case registerEmailRequestCode(email: String)
    /// 电话号码注册，发送验证码
    case registerPhoneRequestCode(phone: String, specialId: String, verifyCode: String, verifyId: String)
    /// 邮箱注册，校验验证码
    case registerEmailVerifyCode(email: String, code: String)
    /// 电话号码注册，校验验证码
    case registerPhoneVerifyCode(phone: String, code: String)
    /// 邮箱绑定/改绑，发送验证码
    case bindEmailRequestCode(email: String)
    /// 电话号码绑定/改绑，发送验证码
    case bindPhoneRequestCode(phone: String, specialId: String, verifyCode: String, verifyId: String)
    /// 邮箱绑定/改绑，校验验证码
    case bindEmailVerifyCode(email: String, code: String)
    /// 电话号码绑定/改绑，校验验证码
    case bindPhoneVerifyCode(phone: String, code: String)
    /// 电话号码 解绑，发送验证码
    case unbindPhoneRequestCode(phone: String, specialId: String, verifyCode: String, verifyId: String)
    /// 电话号码 解绑，校验验证码
    case unbindPhoneVerifyCode(phone: String, code: String)
    /// 邮箱 解绑，发送验证码
    case unbindEmailRequestCode(email: String)
    /// 邮箱 解绑，校验验证码
    case unbindEmailVerifyCode(email: String, code: String)
    /// 邮箱找回密码，发送验证码
    case emailForgetPwdRequestCode(account: String)
    /// 电话号码找回密码，发送验证码
    case phoneForgetPwdRequestCode(account: String, specialId: String, verifyCode: String, verifyId: String)
    /// 校验验证码
    case verfiyCode(account: String, code: String)
    /// 邮箱忘记密码，重置密码
    case emailForgetPwdResetPwd(account: String, code: String, password: String)
    /// 电话号码找回密码，重置密码
    case phoneForgetPwdResetPwd(account: String, code: String, password: String)
    /// 修改密码
    case changePassword(account: String, password: String)
    /// 校验原密码
    case checkPassword(password: String)
    /// 修改用户名
    case modifyUserName(name: String)
    /// 删除用户
    case deleteUser
    /// 第三方登录
    /// 直接注册一个用户以供使用，只有token返回
    case thirdPartyLogin(uid: String, password: String)
    ///  刷新图片验证码
    case refreshVerifyCode(specialId: String)
}

extension DinUserRequest: DinHttpRequest {
    var requestPath: String {
        baseURL.absoluteString + path
    }

    var requestParam: DinHttpParams? {
        var jsonDict = [String: Any]()
        jsonDict["gmtime"] = Int64(Date().timeIntervalSince1970*1000000000)
        var token = DinCore.user?.userToken ?? ""

        switch self {
        case .login(let phone, let email, let uid, let password):
            token = ""
            if phone != nil {
                jsonDict["phone"] = phone
            } else if email != nil {
                jsonDict["email"] = email
            } else {
                jsonDict["uid"] = uid
            }
            jsonDict["password"] = password
        case .registerEmailRequestCode(let email):
            jsonDict["account"] = email

        case .registerPhoneRequestCode(let phone, let specialId, let verifyCode, let verifyId):
            jsonDict["account"] = phone
            jsonDict["special_id"] = specialId
            jsonDict["verify_code"] = verifyCode
            jsonDict["verify_id"] = verifyId
            
        case .registerEmailVerifyCode(let email, let code):
            jsonDict["account"] = email
            jsonDict["code"] = code
            
        case .registerPhoneVerifyCode(let phone, let code):
            jsonDict["account"] = phone
            jsonDict["code"] = code

        case .bindEmailRequestCode(let email):
            jsonDict["account"] = email

        case .bindPhoneRequestCode(let phone, let specialId, let verifyCode, let verifyId):
            jsonDict["account"] = phone
            jsonDict["special_id"] = specialId
            jsonDict["verify_code"] = verifyCode
            jsonDict["verify_id"] = verifyId

        case .bindEmailVerifyCode(let email, let code):
            jsonDict["account"] = email
            jsonDict["code"] = code
            
        case .bindPhoneVerifyCode(let phone, let code):
            jsonDict["account"] = phone
            jsonDict["code"] = code
            
        case .unbindPhoneRequestCode(let phone, let specialId, let verifyCode, let verifyId):
            jsonDict["account"] = phone
            jsonDict["special_id"] = specialId
            jsonDict["verify_code"] = verifyCode
            jsonDict["verify_id"] = verifyId
            
        case .unbindPhoneVerifyCode(let phone, let code):
            jsonDict["account"] = phone
            jsonDict["code"] = code
        case .unbindEmailRequestCode(let email):
            jsonDict["account"] = email
            
        case .unbindEmailVerifyCode(let email, let code):
            jsonDict["account"] = email
            jsonDict["code"] = code

        case .emailForgetPwdRequestCode(let account):
            jsonDict["account"] = account

        case .phoneForgetPwdRequestCode(let account, let specialId, let verifyCode, let verifyId):
            jsonDict["account"] = account
            jsonDict["special_id"] = specialId
            jsonDict["verify_code"] = verifyCode
            jsonDict["verify_id"] = verifyId
            
        case .verfiyCode(let account, let code):
            jsonDict["account"] = account
            jsonDict["code"] = code
            
        case .emailForgetPwdResetPwd(let account, let code, let password):
            jsonDict["account"] = account
            jsonDict["code"] = code
            jsonDict["new_password"] = password
            
        case .phoneForgetPwdResetPwd(let account, let code, let password):
            jsonDict["account"] = account
            jsonDict["code"] = code
            jsonDict["new_password"] = password
            
        case .changePassword(let account, let password):
            jsonDict["account"] = account
            jsonDict["password"] = password
            
        case .checkPassword(let password):
            jsonDict["password"] = password
            
        case .modifyUserName(let name):
            jsonDict["account"] = name
            
        case .deleteUser:
            break

        case .thirdPartyLogin(let uid, let password):
            token = ""
            jsonDict["user_id"] = uid
            jsonDict["password"] = password
            
        case .refreshVerifyCode(let specialId):
            jsonDict["special_id"] = specialId

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
//        var requestPath = "/auth/"
        var requestPath = "/user/"

        switch self {
        case .login:
//            requestPath += "getusersetting/"
            requestPath += "login/"
        case .logout:
//            requestPath += "logout/v2/"
            requestPath += "logout/"
        case .registerEmailRequestCode:
            requestPath += "sign-up-email-send-code/"
        case .registerPhoneRequestCode:
            requestPath += "sign-up-phone-send-code-v3/"
        case .registerEmailVerifyCode:
            requestPath += "sign-up-email-verify-code/"
        case .registerPhoneVerifyCode:
            requestPath += "sign-up-phone-verify-code/"
        case .bindEmailRequestCode:
            requestPath += "change-email-binding-send-code/"
        case .bindPhoneRequestCode:
            requestPath += "change-phone-binding-send-code-v3/"
        case .bindEmailVerifyCode:
            requestPath += "change-email-binding-verify-code/"
        case .bindPhoneVerifyCode:
            requestPath += "change-phone-binding-verify-code/"
        case .unbindPhoneRequestCode:
            requestPath += "unbind-phone-send-code-v3/"
        case .unbindPhoneVerifyCode:
            requestPath += "unbind-phone-verify-code/"
        case .unbindEmailRequestCode:
            requestPath += "unbind-email-send-code/"
        case .unbindEmailVerifyCode:
            requestPath += "unbind-email-verify-code/"
        case .emailForgetPwdRequestCode:
            requestPath += "forget-password-email-send-code/"
        case .phoneForgetPwdRequestCode:
            requestPath += "forget-password-phone-send-code-v3/"
        case .verfiyCode:
            requestPath += "only-verify-code/"
        case .emailForgetPwdResetPwd:
            requestPath += "forget-password-email-verify-code/"
        case .phoneForgetPwdResetPwd:
            requestPath += "forget-password-phone-verify-code/"
        case .changePassword:
            requestPath += "change-password/"
        case .checkPassword:
            requestPath += "check-password/"
        case .modifyUserName:
            requestPath += "change-uid/"
        case .deleteUser:
            requestPath += "logoff/"
        case .thirdPartyLogin:
            requestPath += "ext/login/"
        case .refreshVerifyCode:
            requestPath += "refresh-verify-code/"
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
