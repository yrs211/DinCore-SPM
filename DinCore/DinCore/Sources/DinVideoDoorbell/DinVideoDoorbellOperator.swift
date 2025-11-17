//
//  DinVideoDoorbellOperator.swift
//  DinCore
//
//  Created by Monsoir on 2021/11/17.
//

import Foundation

class DinVideoDoorbellOperator: DinLiveStreamingOperator {
    override var manageTypeID: String { DinVideoDoorbell.categoryID }

    override var category: String { "2" }

    override var subCategory: String { DinVideoDoorbell.categoryID }

    override class func liveStreamingControl(withJsonString jsonString: String) -> DinLiveStreaming? {
        guard jsonString.count > 0 else {
            return nil
        }
        guard let decodeString = DinCore.cryptor.rc4DecryptHexString(jsonString, key: Self.encryptString()) else {
            return nil
        }
        return DinVideoDoorbell.deserialize(from: decodeString)
    }

    override func submitData(_ data: [String : Any]) {
        guard let cmdRawValue = data["cmd"] as? String else { return }

        guard Command(rawValue: cmdRawValue) != nil else {
            super.submitData(data)
            return
        }

        liveStreamingControl.submitData(data)
    }
}

extension DinVideoDoorbellOperator {
    enum Command: String {
        case addChime = "add_chime"
        case getChimeList = "get_chime_list"
        case deleteChime = "del_chime"
        case renameChime = "rename_chime"
        case testChime = "test_chime"
    }
}
