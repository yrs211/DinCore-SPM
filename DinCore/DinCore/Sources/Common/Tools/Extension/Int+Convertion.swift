//
//  Int+Convertion.swift
//  DinCore
//
//  Created by monsoir on 12/16/22.
//

import Foundation

extension Int {
    var uint8: UInt8 { UInt8(bitPattern: Int8(self)) }
}
