//
//  DinConstants.swift
//  DinCore
//
//  Created by Jin on 2021/4/21.
//

import Foundation

public struct DinConstants {
    /// 连接的Websocket是否需要WSS加密通讯
    static let useWSS = true

    static let ipcCrytoKey = "df0fce537e4190037ccd16a7f49207cc"
    static let ipcCrytoIV = "3bf788a38df5c9da"

    static let storageBatteryCrytoKey = "fbade9e36a3f36d3d676c1b808451dd7"
    static let storageBatteryCrytoIV = "dfcf28d0734569a6"

    /// http dns secret
    static let httpdnsSecret = "d180fdf58e9c03ca8894f700441d8b44"
}
