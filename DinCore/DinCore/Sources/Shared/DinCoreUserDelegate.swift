//
//  DinCoreUserDelegate.swift
//  DinCore
//
//  Created by Monsoir on 2021/10/19.
//

import Foundation

public protocol DinCoreUserDelegate {
    func dinCoreUserStateDidChange(state: DinCore.UserState)
}
