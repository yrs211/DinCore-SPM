//
//  DinHttpParams.swift
//  DinCore
//
//  Created by Jin on 2021/4/21.
//

import UIKit
import Snappy
import DinSupport

public class DinHttpParams: NSObject {
    /*  服务器需要的格式模板
     {
         "token":"",   // string，user token
         "domain":"",  // string，区域信息
         "gm":1,  // int，表示使用的加密版本，目前为1
         "data":{
             "device_id": "12345667890",
             "unique_id": "",    // string，设备的unique id
             "limit": 10,
             "skip": 0,
             "time": 123456789 // int64，单位秒
         }
     }
     */
    public private(set) var uploadData: Data
    public private(set) var uploadDict: [String: Any]
    private var params: [String: Any]
    private var dataParams: [String: Any]
    private var encryptSecret: String

    /// 生成对应的Api需要的参数格式
    /// - Parameters:
    ///   - params: 外层的参数
    ///   - dataParams: data的加密参数
    public init?(with params: [String: Any], dataParams: [String: Any], encryptSecret: String) {
        self.uploadDict = DinHttpParams.convertParams(with: params,
                                                      dataParams: dataParams,
                                                      encryptSecret: encryptSecret)
        guard let uploadData = DinDataConvertor.convertToData(uploadDict) else {
            return nil
        }
        self.uploadData = uploadData
        self.params = params
        self.dataParams = dataParams
        self.encryptSecret = encryptSecret
        super.init()
    }

    func decodeDataString(_ dataString: String) -> [String: Any]? {
        // 检查是否能解密
        guard let decodeData = DinHttpParams.decryptDataString(dataString, with: encryptSecret) else {
            return nil
        }
        guard let returnDic = DinDataConvertor.convertToDictionary(decodeData) else {
            return nil
        }
        return returnDic
    }

    func logParams() -> String {
        return "inner params:\(dataParams)\noutter params:\(uploadDict)"
    }
}

// MARK: - 转换类方法
extension DinHttpParams {
    /// 参数字典转换成对应的加密String
    /// - Parameter dataParams: 为空
    public class func convertDataParams(_ dataParams: [String: Any], encryptSecret: String) -> String? {
        guard let jsonData = DinDataConvertor.convertToData(dataParams) else {
            return nil
        }
        guard let jsonStr = String(data: jsonData, encoding: .utf8) else {
            return nil
        }

        return DinCore.cryptor.rc4EncryptToHexString(with: jsonStr, key: encryptSecret) ?? ""
    }

    private class func convertParams(with params: [String: Any], dataParams: [String: Any], encryptSecret: String) -> [String: Any] {
        var mutableDict = params
        if dataParams.count > 0, let dataParamsString = convertDataParams(dataParams, encryptSecret: encryptSecret) {
            mutableDict["json"] = dataParamsString
        }
        return mutableDict
    }

    /// 解密字符串
    private class func decryptDataString(_ dataString: String, with encryptSecret: String) -> Data? {
        guard let encryptData = dataString.dataFromHexadecimalString() else {
            return nil
        }
        guard let decryptData = DinCore.cryptor.rc4Decrypt(encryptData, key: encryptSecret) else {
            return nil
        }
        return (decryptData as NSData).snappy_decompressed()
    }
}
