//
//  DinDataManager+User.swift
//  DinCore
//
//  Created by Jin on 2021/4/21.
//

import Foundation

/// 用户模块
extension DinDataManager {
    /// 存储用户信息
    static let saveUserKey = "\(DinCore.appID ?? "")_User"

    func saveUser(_ user: DinUser?) {
        guard let newUser = user else {
            removeUser()
            return
        }
        /// 异步保存
        if let userJson = newUser.toJSONString() {
            let encryptData = DinCore.cryptor.rc4EncryptToData(with: userJson, key: DinCore.appSecret ?? "") ?? Data()
            saveValueAsync(withKey: DinDataManager.saveUserKey, value: encryptData)
        }
    }

    func getUser() -> DinUser? {
        if let encryptData = hasValue(withKey: DinDataManager.saveUserKey) as? Data {
            if let decryptData = DinCore.cryptor.rc4Decrypt(encryptData, key:  DinCore.appSecret ?? "") {
                if let decryptString = String(data: decryptData, encoding: .utf8) {
                    return DinUser.deserialize(from: decryptString)
                }
            }
        }
        return nil
    }

    func removeUser() {
        removeValueAsync(withKey: DinDataManager.saveUserKey)
    }
}
