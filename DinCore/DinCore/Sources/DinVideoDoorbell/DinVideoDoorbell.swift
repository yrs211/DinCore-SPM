//
//  DinVideoDoorbell.swift
//  DinCore
//
//  Created by Monsoir on 2021/11/17.
//

import Foundation

public class DinVideoDoorbell: DinLiveStreaming {
    override class var categoryID: String { "DSDOORBELL" }

    override class var provider: String { categoryID }
}
