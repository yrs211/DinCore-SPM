//
//  DinHomeDeviceSelection.swift
//  DinCore
//
//  Created by Jin on 2021/5/7.
//

import UIKit

public protocol DinHomeDeviceSelection {
    var id: String { get }
    var isSelected: Bool { get }
    var isEditing: Bool { get }
    var tapable: Bool { get }
}
