//
//  DinCameraV015Operator.swift
//  DinCore
//
//  Created by dinsafer on 2023/6/1.
//

import UIKit

final class DinCameraV015Operator: DinLiveStreamingOperator {
    override var manageTypeID: String { DinCameraV015.categoryID }

    override var category: String { "2" }

    override var subCategory: String { DinCameraV015.categoryID }

    override class func liveStreamingControl(withJsonString jsonString: String) -> DinLiveStreaming? {
        guard jsonString.count > 0 else {
            return nil
        }
        guard let decodeString = DinCore.cryptor.rc4DecryptHexString(jsonString, key: Self.encryptString()) else {
            return nil
        }
        return DinCameraV015.deserialize(from: decodeString)
    }
}
