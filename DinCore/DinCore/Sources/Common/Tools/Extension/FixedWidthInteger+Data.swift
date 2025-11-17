//
//  FixedWidthInteger+Data.swift
//  DinCore
//
//  Created by monsoir on 12/5/22.
//

import Foundation

extension FixedWidthInteger {
    var bytes: [UInt8] {
        var copied = self
        return withUnsafePointer(to: &copied) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout.size(ofValue: self)) { pointer in
                Array(UnsafeBufferPointer(start: pointer, count: MemoryLayout.size(ofValue: self)))
            }
        }
    }

    var bigEndianData: Data {
        Data(bigEndian.bytes)
    }

    var littleEndianData: Data {
        Data(littleEndian.bytes)
    }
}
