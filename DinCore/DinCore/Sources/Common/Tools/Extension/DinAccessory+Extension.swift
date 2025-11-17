//
//  DinAccessory+Extension.swift
//  DinCore
//
//  Created by Jin on 2021/4/24.
//

import Foundation
import DinSupport

public extension DinAccessory {
    /// 通过pluginID或者decodeID判断是不是Keypad
    static func isKeypad(pluginID: String, decodeID: String?) -> Bool {
        var dinID = ""
        if let did = decodeID, did.count > 0 {
            dinID = did
        } else {
            dinID = DinAccessoryUtil.str64(toHexStr: pluginID) 
        }
        let dType = dinID[0...0]
        let sType = dinID[1...2]
        if dType == "7" {
            return true
        } else if sType == "1B" || sType == "2F" {
            return true
        } else if sType == "37" {
            // RFID tag
            return true
        }
        else {
            return false
        }
    }
}
