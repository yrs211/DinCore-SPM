//
//  MSCTCommandUserInfo.swift
//  DinCore
//
//  Created by Monsoir on 2022/12/14.
//

import Foundation

protocol MSCTCommandUserInfo {}

/// 只补偿 index 的 user info
struct MSCTCommandIndexCompensationUserInfo: MSCTCommandUserInfo {
    let index: Int
}
