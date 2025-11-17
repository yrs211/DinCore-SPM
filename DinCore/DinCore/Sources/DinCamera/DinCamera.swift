//
//  DinCamera.swift
//  DinCore
//
//  Created by Jin on 2021/6/9.
//

import UIKit
import DinSupport
import HandyJSON

public class DinCamera: DinLiveStreaming {
    override class var categoryID: String { "dscam" }

    override class var provider: String { "DSCAM" }
}
