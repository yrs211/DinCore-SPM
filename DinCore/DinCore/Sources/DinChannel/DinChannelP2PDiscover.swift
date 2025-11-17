//
//  DinChannelP2PDiscover.swift
//  DinCore
//
//  Created by Jin on 2021/8/6.
//

import UIKit

class DinChannelP2PDiscover: NSObject {

    /// 生成获取本机P2P通道的公网地址请求数据
    /// - Returns: 请求数据
    class func genGetSelfP2PAddressRequestData() -> Data {
        let requestData = NSData(bytes: [0x67] as [UInt8], length: 1)
        return Data(requestData)
    }


}
