//
//  UInt8+Convertion.swift
//  DinCore
//
//  Created by monsoir on 12/16/22.
//

import Foundation

extension UInt8 {
    var bool: Bool { self == 0x01 }
    var int: Int { Int(bitPattern: UInt(self)) }
    var signedInt: Int { Int(Int8(bitPattern: self)) } // 不能直接转Int，需要先转成Int8
}
