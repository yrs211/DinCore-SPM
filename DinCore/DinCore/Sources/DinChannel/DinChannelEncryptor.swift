//
//  DinChannelEncryptor.swift
//  DinCore
//
//  Created by Jin on 2021/6/9.
//

import UIKit
import DinSupport

/// 用于和服务器进行MSCT通讯的服务器
public class DinChannelEncryptor: NSObject, DinCommunicationEncryptor {
    let secret: String
    // msctiviv 随机生成，并给外面访问，供msct使用
    var msctiv: String
    // kcpiv 随机生成，并给外面访问，供kcp使用
    var kcpiv: String
    private let secretBytes: [UInt8]
    private let msctivBytes: [UInt8]
    private let kcpivBytes: [UInt8]
    private let msctCryptor: DinsaferAESCBCCryptor?
    private let kcpCrytor: DinsaferAESCBCCryptor?

    init(withSecret secret: String) {
        self.secret = secret

        // 自己生成
        self.msctiv = "872fd12eef68a401"
        let randomString = String.UUID()
        if randomString.count > 15 {
            self.msctiv = randomString[0...15]
        }

        // kcp
        var kcpIVString = self.secret.md5()
        if kcpIVString.count > 15 {
            kcpIVString = kcpIVString[0...15]
        }
        self.kcpiv = kcpIVString

        self.secretBytes = self.secret.bytes
        self.msctivBytes = self.msctiv.bytes
        self.kcpivBytes = self.kcpiv.bytes
        self.msctCryptor = DinsaferAESCBCCryptor(withSecret: self.secretBytes, iv: self.msctivBytes)
        self.kcpCrytor = DinsaferAESCBCCryptor(withSecret: self.secretBytes, iv: self.kcpivBytes)
        super.init()
    }

    public func checkOptionHeaders(_ headers: [OptionHeader]) -> [OptionHeader] {
        var optionHeaders = headers
        optionHeaders.append(OptionHeader(id: DinMSCTOptionID.aesIV, data: msctiv.data(using: .utf8)))
        return optionHeaders
    }

    public func encryptedData(_ requestData: Data) -> Data? {
        encryptData(with: requestData)
    }
    public func decryptedData(_ responseData: Data, msctHeaders: [UInt8 : OptionHeader]?) -> Data? {
        decryptData(responseData, withMSCTHeaders: msctHeaders)
    }

    public func encryptedKcpData(_ requestData: Data) -> Data? {
        encryptKCPData(with: requestData)
    }
    public func decryptedKcpData(_ responseData: Data) -> Data? {
        decryptKCPData(responseData)
    }
}

// MARK: - 加密逻辑
extension DinChannelEncryptor {
    /// MSCT加密
    private func encryptData(with requestData: Data) -> Data? {
        return msctCryptor?.aesEncrypt(bytes: requestData.dataBytes)?.data
    }
    /// MSCT解密
    private func decryptData(_ responseData: Data, withMSCTHeaders msctHeaders: [UInt8 : OptionHeader]?) -> Data? {
        if let ivBytes = msctHeaders?[DinMSCTOptionID.aesIV]?.data?.dataBytes {
            let tempCryptor = DinsaferAESCBCCryptor(withSecret: self.secretBytes, iv: ivBytes)
            return tempCryptor?.aesDecrypt(bytes: responseData.dataBytes)?.data
        }
        return nil
    }

    /// KCP加密
    private func encryptKCPData(with requestData: Data) -> Data? {
        return kcpCrytor?.aesEncrypt(bytes: requestData.dataBytes)?.data
    }
    /// KCP解密
    private func decryptKCPData(_ responseData: Data) -> Data? {
        return kcpCrytor?.aesDecrypt(bytes: responseData.dataBytes)?.data
    }
}
