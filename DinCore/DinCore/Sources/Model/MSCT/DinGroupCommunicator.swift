//
//  DinGroupCommunicator.swift
//  DinCore
//
//  Created by Jin on 2021/6/9.
//

import UIKit
import DinSupport

/// 组内沟通角色
public class DinGroupCommunicator: NSObject, DinCommunicationIdentity {

    public var uniqueID: String
    public var groupID: String
    public var commSecret: String

    public var id: String {
        ""
    }

    public var communicateKey: String {
        commSecret
    }

    public var name: String {
        ""
    }

    public init(withUniqueID uniqueID: String, groupID: String, commSecret: String) {
        self.uniqueID = uniqueID
        self.groupID = groupID
        self.commSecret = commSecret
        super.init()
    }
}
