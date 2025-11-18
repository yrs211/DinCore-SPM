//
//  DinGroupEncryptor.swift
//  DinCore
//
//  Created by Jin on 2021/8/27.
//

import UIKit
import DinSupport

/// 用于和服务器进行MSCT通讯的服务器
class DinGroupEncryptor: NSObject, DinCommunicationEncryptor {
    let groupSecret: String
    let commSecret: String
    // iv 随机生成，并给外面访问
    var groupIV: String
    private let groupSecretBytes: [UInt8]
    private let commSecretBytes: [UInt8]
    private let groupIVBytes: [UInt8]

    /// 组的通讯器从一开始就可以定下来了
    private let groupCryptor: DinsaferAESCBCCryptor?

    /// 加解密
    /// - Parameters:
    ///   - groupSecret: 群组加解密key
    ///   - commSecret: 群内成员加解密key
    init(withGroupSecret groupSecret: String, communicationSecret commSecret: String) {
        self.groupSecret = groupSecret
        self.commSecret = commSecret
        self.groupIV = "872fd12eef68a401"
        let randomString = String.UUID()
        if randomString.count > 15 {
            self.groupIV = randomString[0...15]
        }
        self.groupSecretBytes = self.groupSecret.bytes
        self.commSecretBytes = self.commSecret.bytes
        self.groupIVBytes = self.groupIV.bytes

        groupCryptor = DinsaferAESCBCCryptor(withSecret: self.groupSecretBytes, iv: self.groupIVBytes)

        super.init()
    }

    public func checkOptionHeaders(_ headers: [OptionHeader]) -> [OptionHeader] {
        var optionHeaders = headers
        optionHeaders.append(OptionHeader(id: DinMSCTOptionID.aesIV, data: groupIV.data(using: .utf8)))
        return optionHeaders
    }

    public func encryptedData(_ requestData: Data) -> Data? {
        encryptData(with: requestData)
    }
    func decryptedData(_ responseData: Data, msctHeaders: [UInt8 : OptionHeader]?) -> Data? {
        decryptData(responseData, withMSCTHeaders: msctHeaders)
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
extension DinGroupEncryptor {
    /// 加密
    private func encryptData(with requestData: Data) -> Data? {
        return groupCryptor?.aesEncrypt(bytes: requestData.dataBytes)?.data
    }
    /// 解密
    private func decryptData(_ responseData: Data, withMSCTHeaders msctHeaders: [UInt8 : OptionHeader]?) -> Data? {
        if let ivBytes = msctHeaders?[DinMSCTOptionID.aesIV]?.data?.dataBytes {
            // 如果是msct通知的话，需要用commSecret来解密
            if let optionHeader = msctHeaders?[DinMSCTOptionID.method],
               let data = optionHeader.data,
               String(data: data, encoding: .utf8) == "notice" {
                let commCryptor = DinsaferAESCBCCryptor(withSecret: self.commSecretBytes, iv: ivBytes)
                return commCryptor?.aesDecrypt(bytes: responseData.dataBytes)?.data
            } else {
                // 如果不是，用groupSecre
                let tempGroupCryptor = DinsaferAESCBCCryptor(withSecret: self.groupSecretBytes, iv: ivBytes)
                return tempGroupCryptor?.aesDecrypt(bytes: responseData.dataBytes)?.data
            }
        }
        return nil
    }
}
