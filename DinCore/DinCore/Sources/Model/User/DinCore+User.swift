//
//  DinCore+User.swift
//  DinCore
//
//  Created by Jin on 2021/4/21.
//

import Foundation
import HandyJSON
import Qiniu

extension DinCore {
    /// 登录
    /// - Parameters:
    ///   - account: 用户名
    ///   - password: 密码
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public static func login(phone: String?, email: String?, uid: String?, password: String, success: ((DinUser) -> Void)?, fail: ApiFailure?) {
        let loginRequest = DinUserRequest.login(phone: phone, email: email, uid: uid, password: password)
        DinHttpProvider.request(loginRequest, success: { result in
            if let returnDict = result, let user = DinUser.deserialize(from: returnDict) {
                DinCore.user = user
                DinCore.user?.password = password
                DinCore.dataBase.saveUser(user)
                success?(user)
            } else {
                DinCore.user = nil
                fail?(DinNetwork.Error.modelConvertFail("DinUser"))
            }
        }, fail: { error in
            DinCore.user = nil
            fail?(error)
        })
    }

    /// 登出
    public static func logout(complete: (() -> Void)?) {
        let target = DinUserRequest.logout
        DinHttpProvider.request(target) { (result) in
            DinCore.user = nil
            complete?()
        } fail: { (_) in
            DinCore.user = nil
            complete?()
        }
    }
    
    public static func registerEmailRequestCode(email: String, success: (() -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.registerEmailRequestCode(email: email)
        DinHttpProvider.request(target) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func registerEmailVerifyCode(email: String, code: String, success: ((DinUser) -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.registerEmailVerifyCode(email: email, code: code)
        DinHttpProvider.request(target) { result in
            if let returnDict = result, let user = DinUser.deserialize(from: returnDict) {
                DinCore.user = user
                DinCore.user?.mail = email
                DinCore.dataBase.saveUser(user)
                success?(user)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinUser"))
            }
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func registerPhoneRequestCode(phone: String, specialId: String, verifyCode: String, verifyId: String, success: (() -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.registerPhoneRequestCode(phone: phone, specialId: specialId, verifyCode: verifyCode, verifyId: verifyId)
        DinHttpProvider.request(target) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func registerPhoneVerifyCode(phone: String, code: String, success: ((DinUser) -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.registerPhoneVerifyCode(phone: phone, code: code)
        DinHttpProvider.request(target) { result in
            if let returnDict = result, let user = DinUser.deserialize(from: returnDict) {
                DinCore.user = user
                DinCore.user?.phone = phone
                DinCore.dataBase.saveUser(user)
                success?(user)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinUser"))
            }
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func emailForgetPwdRequestCode(account: String, success: (() -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.emailForgetPwdRequestCode(account: account)
        DinHttpProvider.request(target) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func verifyCode(account: String, code: String, success: ((Bool) -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.verfiyCode(account: account, code: code)
        DinHttpProvider.request(target) { result in
            if let returnDict = result, let isSucceed = returnDict["result"] as? Bool {
                success?(isSucceed)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinUser"))
            }
        } fail: { error in
            fail?(error)
        }

    }
    
    public static func emailForgetPwdResetPwd(account: String, code: String, password: String, success: (() -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.emailForgetPwdResetPwd(account: account, code: code, password: password)
        DinHttpProvider.request(target) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func phoneForgetPwdRequestCode(account: String, specialId: String, verifyCode: String, verifyId: String, success: (() -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.phoneForgetPwdRequestCode(account: account, specialId: specialId, verifyCode: verifyCode, verifyId: verifyId)
        DinHttpProvider.request(target) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func phoneForgetPwdResetPwd(account: String, code: String, password: String, success: (() -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.phoneForgetPwdResetPwd(account: account, code: code, password: password)
        DinHttpProvider.request(target) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func changePassword(account: String, password: String, success: (() -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.changePassword(account: account, password: password)
        DinHttpProvider.request(target) { result in
            DinCore.user?.password = password
            DinCore.dataBase.saveUser(user)
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func checkPassword(password: String, success: ((Bool) -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.checkPassword(password: password)
        DinHttpProvider.request(target) { result in
            if let returnDict = result, let isSucceed = returnDict["result"] as? Bool {
                success?(isSucceed)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinUser"))
            }
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func bindEmailRequestCode(email: String, success: (() -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.bindEmailRequestCode(email: email)
        DinHttpProvider.request(target) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func bindEmailVerifyCode(email: String, code: String, success: (() -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.bindEmailVerifyCode(email: email, code: code)
        DinHttpProvider.request(target) { result in
            DinCore.user?.mail = email
            DinCore.dataBase.saveUser(user)
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func bindPhoneRequestCode(phone: String, specialId: String, verifyCode: String, verifyId: String, success: (() -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.bindPhoneRequestCode(phone: phone, specialId: specialId, verifyCode: verifyCode, verifyId: verifyId)
        DinHttpProvider.request(target) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func bindPhoneVerifyCode(phone: String, code: String, success: (() -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.bindPhoneVerifyCode(phone: phone, code: code)
        DinHttpProvider.request(target) { result in
            DinCore.user?.phone = phone
            DinCore.dataBase.saveUser(user)
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func unbindPhoneRequestCode(phone: String, specialId: String, verifyCode: String, verifyId: String, success: (() -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.unbindPhoneRequestCode(phone: phone, specialId: specialId, verifyCode: verifyCode, verifyId: verifyId)
        DinHttpProvider.request(target) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func unbindPhoneVerifyCode(phone: String, code: String, success: (() -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.unbindPhoneVerifyCode(phone: phone, code: code)
        DinHttpProvider.request(target) { result in
            DinCore.user?.phone = ""
            DinCore.dataBase.saveUser(user)
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func unbindEmailRequestCode(email: String, success: (() -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.unbindEmailRequestCode(email: email)
        DinHttpProvider.request(target) { result in
            success?()
        } fail: { error in
            fail?(error)
        }

    }
    
    public static func unbindEmailVerifyCode(email: String, code: String, success: (() -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.unbindEmailVerifyCode(email: email, code: code)
        DinHttpProvider.request(target) { result in
            DinCore.user?.mail = ""
            DinCore.dataBase.saveUser(user)
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func refreshVerifyCode(specialId: String, success: (([String: Any]) -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.refreshVerifyCode(specialId: specialId)
        DinHttpProvider.request(target) { result in
            if let returnDict = result {
                success?(returnDict)
            } else {
                fail?(DinNetwork.Error.noDataReturn(""))
            }
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func modifyUserName(name: String, success: (() -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.modifyUserName(name: name)
        DinHttpProvider.request(target) { result in
            DinCore.user?.name = name
            DinCore.dataBase.saveUser(user)
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    
    public static func changePassword(oldPwd: String, newPwd: String, success: ((String) -> Void)?, fail: ApiFailure?) {
        let target = DinAuthRequest.changePassword(oldPwd: oldPwd, newPwd: newPwd)
        DinHttpProvider.request(target) { (result) in
            if let returnDict = result, let token = returnDict["token"] as? String {
                DinCore.user?.token = token
                DinCore.user?.password = newPwd
                DinCore.dataBase.saveUser(user)
                success?(token)
            } else {
                fail?(DinNetwork.Error.noDataReturn(""))
            }
        } fail: { (error) in
            fail?(error)
        }
    }
    
    public static func changeAvatar(imageData: Data, success: ((String) -> Void)?, fail: ApiFailure?) {
        // 先把头像上传到七牛，再把七牛返回的地址返回到服务器
        let target = DinUploadRequest.getUploadToken
        DinHttpProvider.request(target) { (result) in
            if let returnDict = result, let temp = returnDict["token"] as? String {
                let token = temp.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                // 上传到七牛
                let upManager = QNUploadManager()
                upManager!.put(imageData, key: nil, token: token, complete: { (info, key, resp) in
                    if (info!.statusCode == 200 && resp != nil) {
                        // 修改用户头像
                        DinCore.uploadAvatarUrl(key: resp!["key"] as! String, success: success, fail: fail)
                    } else {
                        fail?(DinNetwork.Error.apiFail("", -992))
                    }
                }, option: nil)
            } else {
                fail?(DinNetwork.Error.noDataReturn(""))
            }
        } fail: { (error) in
            fail?(error)
        }
    }
    
    public static func changeR2Avatar(imageData: Data, source: Int, success: ((String) -> Void)?, fail: ApiFailure?) {
        // 先把头像文件信息上传到服务器，再把返回的token上传到R2

        
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let dateString = formatter.string(from: currentDate)
        
        let fileName = dateString + "_" + (DinCore.user?.id ?? "")
        let fileInfo = DinFileUploadManager.getAndPrintFileInfo(data: imageData)
        let parameters = DinR2FileForm(
            contentLength: fileInfo.size,
            contentType: fileInfo.mimeType,
            fileExtension: "",
            uploadtype: DinR2UploadType.avatar,
            homeID: DinCore.user?.curHome?.id ?? "",
            fileName: fileName)
        let target = DinUploadRequest.getR2Toekn(parameters)
        DinHttpProvider.request(target) { (result) in
            if let returnDict = result, let temp = returnDict["token"] as? String, let key = returnDict["key"] as? String, let access = returnDict["access"] as? String {
                let token = temp.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                // 上传到R2
                DinFileUploadManager.uploadData(imageData, fileName: fileName, preSignedURL: token, completion: { result in
                    
                    switch result {
                    case .success:
                        // 修改用户头像
                        DinCore.uploadR2AvatarUrl(key: key, source: source, access: access, success: success, fail: fail)
                        break
                        
                    case .failure:
                        fail?(DinNetwork.Error.apiFail("", -992))
                        break
                    }
            })
            } else {
                fail?(DinNetwork.Error.noDataReturn(""))
            }
        } fail: { (error) in
            fail?(error)
        }
    }
    
    static func uploadAvatarUrl(key: String, success: ((String) -> Void)?, fail: ApiFailure?) {
        let target = DinAuthRequest.changeAvatar(key: key)
        DinHttpProvider.request(target) { (result) in
            DinCore.user?.avatar = key
            DinCore.dataBase.saveUser(DinCore.user)
            success?(DinCore.user?.photo ?? "")
        } fail: { (error) in
            fail?(error)
        }
    }
    
    static func uploadR2AvatarUrl(key: String, source: Int, access: String, success: ((String) -> Void)?, fail: ApiFailure?) {
        let target = DinAuthRequest.changeR2Avatar(key: key, source: source)
        DinHttpProvider.request(target) { (result) in
            DinCore.user?.avatarUrl = access
            DinCore.dataBase.saveUser(DinCore.user)
            success?(DinCore.user?.photo ?? "")
        } fail: { (error) in
            fail?(error)
        }
    }
    
    public static func getUserData(success: ((DinUser?) -> Void)?, fail: ApiFailure?) {
        let target = DinAuthRequest.getUserData
        DinHttpProvider.request(target) { (result) in
            if let returnResult = result, let mail = returnResult["mail"] as? String, let phone = returnResult["phone"] as? String {
                DinCore.user?.mail = mail
                DinCore.user?.phone = phone
                DinCore.dataBase.saveUser(DinCore.user)
                success?(DinCore.user)
            } else {
                fail?(DinNetwork.Error.noDataReturn(""))
            }
        } fail: { (error) in
            fail?(error)
        }
    }
    
    public static func deleteUser(success: (() -> Void)?, fail: ApiFailure?) {
        let target = DinUserRequest.deleteUser
        DinHttpProvider.request(target) { (result) in
            DinCore.user = nil
            success?()
        } fail: { (error) in
            fail?(error)
        }
    }


    /// 自定义登录
    /// - Parameters:
    ///   - uid: 用户唯一id
    ///   - password: 密码
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public static func thirdPartyLogin(uid: String, password: String, success: ((DinUser) -> Void)?, fail: ApiFailure?) {
        let loginRequest = DinUserRequest.thirdPartyLogin(uid: uid, password: password.md5().md5())
        DinHttpProvider.request(loginRequest, success: { result in
            if let returnDict = result, let user = DinUser.deserialize(from: returnDict) {
                DinCore.user = user
                DinCore.user?.password = password
                DinCore.dataBase.saveUser(user)
                success?(user)
            } else {
                DinCore.user = nil
                fail?(DinNetwork.Error.modelConvertFail("DinUser"))
            }
        }, fail: { error in
            DinCore.user = nil
            fail?(error)
        })
    }
    
    public static func setUser(userID: String, token: String, thirdpartyUID: String) {
        let user = DinUser()
        user.id = userID
        user.token = token
        user.thirdpartyUID = thirdpartyUID
        DinCore.user = user
        DinCore.dataBase.saveUser(user)
    }
}
