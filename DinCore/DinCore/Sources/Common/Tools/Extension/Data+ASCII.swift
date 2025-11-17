//
//  Data+ASCII.swift
//  DinCore
//
//  Created by monsoir on 12/1/22.
//

import Foundation

extension Data {
    var stringFromACSIIScalar: String {
        var result = ""
        forEach { result.unicodeScalars.append(UnicodeScalar($0)) }
        return result
    }
}
