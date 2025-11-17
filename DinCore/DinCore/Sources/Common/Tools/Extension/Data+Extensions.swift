//
//  Data+Extensions.swift
//  DinCore
//
//  Created by williamxie on 2025/7/8.
//

import Foundation

extension Array where Element == Bool {
    /// 将 [Bool]（长度 ≤ 7）编码为单字节 Data（bitmask）
    func toWeekdayData() -> Data {
        var bitmask: UInt8 = 0
        for (i, value) in self.enumerated() where i < 7 {
            if value {
                bitmask |= (1 << i)
            }
        }
        return Data([bitmask])
    }
    
    /// 将 [Bool] 数组 每个转为一个字节（true → 1, false → 0）
    func toRawByteData() -> Data {
        let bytes = self.map { $0 ? UInt8(1) : UInt8(0) }
        return Data(bytes)
    }
    
}

extension Data {
    /// 从单字节 Data 解码为 [Bool]（7 位）
    func weekdaysFromBitmask() -> [Bool] {
        guard let byte = self.first else {
            return Array(repeating: false, count: 7)
        }
        return (0..<7).map { (byte & (1 << $0)) != 0 }
    }
}

extension Bool {
    /// 将 Bool 转为 UInt8 Data（1字节，true 为 0x01，false 为 0x00）
    func toUInt8Data() -> Data {
        return Data([self ? UInt8(1) : UInt8(0)])
    }
}
