//
//  DinCameraOperator.swift
//  DinCore
//
//  Created by Jin on 2021/6/15.
//

import UIKit

class DinCameraOperator: DinLiveStreamingOperator {
    override var manageTypeID: String { DinCamera.categoryID }

    override var category: String { "2" }

    override var subCategory: String { DinCamera.categoryID }

    override class func liveStreamingControl(withJsonString jsonString: String) -> DinLiveStreaming? {
        guard jsonString.count > 0 else {
            return nil
        }
        guard let decodeString = DinCore.cryptor.rc4DecryptHexString(jsonString, key: Self.encryptString()) else {
            return nil
        }
        return DinCamera.deserialize(from: decodeString)
    }
}
