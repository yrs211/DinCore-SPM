//
//  DinCoreLogger.swift
//  DinCore
//
//  Created by AdrianHor on 2023/4/19.
//

#if ENABLE_LOG

import Foundation
import DinSupport
import os.log

@available(iOS 14.0, *)
public typealias DinCoreLogger = DinSupportLogger

@available(iOS 14.0, *)
public extension DinSupportLogger {
    // http/https
    static let https = loggerWithCategory("HTTPS")

    // 蓝牙通讯类别
    static let bluetoothCommunication = loggerWithCategory("BLEComm")

    // MSCT推送
    static let msctNotification = loggerWithCategory("MsctNotification")
}

#endif
