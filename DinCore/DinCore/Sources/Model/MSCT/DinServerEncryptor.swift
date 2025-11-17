//
//  DinServerEncryptor.swift
//  DinCore
//
//  Created by Jin on 2021/5/6.
//

import UIKit
import DinSupport

/// 用于和服务器进行MSCT通讯的服务器
class DinServerEncryptor: NSObject, DinCommunicationEncryptor {
    func checkOptionHeaders(_ headers: [OptionHeader]) -> [OptionHeader] {
        return headers
    }

    func encryptedData(_ requestData: Data) -> Data? {
        encryptData(with: requestData)
    }
    func decryptedData(_ responseData: Data, msctHeaders: [UInt8 : OptionHeader]?) -> Data? {
        decryptData(with: responseData)
    }

    func encryptedKcpData(_ requestData: Data) -> Data? {
        // 不处理kcp data
        return nil
    }
    func decryptedKcpData(_ responseData: Data) -> Data? {
        // 不处理kcp data
        return nil
    }
}

// MARK: - 加密逻辑
extension DinServerEncryptor {
    /// 加密
    private func encryptData(with requestData: Data) -> Data? {
//        // 寻找对应的secret
//        let secret = normalEncryptSecret()
//        return DinCore.cryptor.rc4EncryptToData(with: requestData, key: secret)
        #warning("TODO: 目前不加密")
        return requestData
    }

    /// 解密
    private func decryptData(with responseData: Data) -> Data? {
//        let secret = normalDecryptSecret()
//        return DinCore.cryptor.rc4Decrypt(responseData, key: secret)
        #warning("TODO: 目前不解密")
        return responseData
    }
}

// MARK: - 加密secret的获取
extension DinServerEncryptor {
    private func secret(withKey key: String) -> String {
        return key
    }

    /// 【普通模式下】加密的时候使用用户对设备的唯一token
    private func normalEncryptSecret() -> String {
        return secret(withKey: DinCore.user?.communicateKey ?? "")
    }
    /// 【普通模式下】解密的时候 使用设备的token
    private func normalDecryptSecret() -> String {
        return secret(withKey: DinCore.user?.communicateKey ?? "")
    }
}
