//
//  DinCoreStorageBatteryDelegate.swift
//  DinCore
//
//  Created by monsoir on 11/29/22.
//

import Foundation

public protocol DinCoreStorageBatteryDelegate {
    func dinCoreStorageBatteryDidReceiveGroupNotification(_ info: [String: Any])
}
