//
//  DinCameraV006Operator.swift
//  DinCore
//
//  Created by monsoir on 4/13/22.
//

import Foundation

final class DinCameraV006Operator: DinLiveStreamingOperator {
    override var manageTypeID: String { DinCameraV006.categoryID }

    override var category: String { "2" }

    override var subCategory: String { DinCameraV006.categoryID }

    override class func liveStreamingControl(withJsonString jsonString: String) -> DinLiveStreaming? {
        guard jsonString.count > 0 else {
            return nil
        }
        guard let decodeString = DinCore.cryptor.rc4DecryptHexString(jsonString, key: Self.encryptString()) else {
            return nil
        }
        return DinCameraV006.deserialize(from: decodeString)
    }
}
