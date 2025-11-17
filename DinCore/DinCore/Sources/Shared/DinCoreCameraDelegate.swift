//
//  DinCoreCameraDelegate.swift
//  DinCore
//
//  Created by Monsoir on 2021/10/20.
//

import Foundation

public protocol DinCoreCameraDelegate {
    func dinCoreCameraDidReceiveGroupNotification(_ info: [String: Any])
}
