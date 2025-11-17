//
//  DinHttpRequest.swift
//  DinCore
//
//  Created by Jin on 2021/4/21.
//

import Foundation
import Moya

public protocol DinHttpRequest: TargetType {
    /// 请求路径
    var requestPath: String { get }
    /// 请求参数
    var requestParam: DinHttpParams? { get }
}
