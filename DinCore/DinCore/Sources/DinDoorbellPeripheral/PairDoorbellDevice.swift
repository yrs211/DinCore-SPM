//
//  PairDoorbellDevice.swift
//  DinCore
//
//  Created by monsoir on 11/18/21.
//

import Foundation

/// 配对 IPC 命名空间
public enum PairDoorbellDevice {}

extension PairDoorbellDevice {

    public enum PairError: Swift.Error {

        /// 请求数据有误
        case badRequest

        /// 响应格式有误
        case reponseMalform

        /// 操作超时
        case timeout

        /// 设备报告失败
        case failed

        /// json解析错误
        case jsonParseError

        /// 登陆超时
        case loginTimeout

        /// 当前网络响应超时或信息缺少
        case curNetworkError
    }
}
