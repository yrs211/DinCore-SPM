//
//  Data+Integer.swift
//  DinCore
//
//  Created by monsoir on 12/1/22.
//

import Foundation

extension Data {
    var uint16: UInt16 { withUnsafeBytes { $0.load(as: UInt16.self) } }

    var int16: Int16 { withUnsafeBytes { $0.load(as: Int16.self) } }

    var uint32: UInt32 { withUnsafeBytes { $0.load(as: UInt32.self) } }

    var int32: Int32 { withUnsafeBytes { $0.load(as: Int32.self)} }
    
    var uint64: UInt64 { withUnsafeBytes { $0.load(as: UInt64.self) } }
    
    var int64: Int64 { withUnsafeBytes { $0.load(as: Int64.self) } }
    
    var copiedUInt16: UInt16 { Data(self).uint16 }

    var copiedInt16: Int16 { Data(self).int16 }

    var copiedUInt32: UInt32 { Data(self).uint32 }

    var copiedInt32: Int32 { Data(self).int32 }
    
    var copiedUInt64: UInt64 { Data(self).uint64 }
    
    var copiedInt64: Int64 { Data(self).int64 }
    
}
