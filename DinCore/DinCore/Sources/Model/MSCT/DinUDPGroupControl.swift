//
//  DinUDPGroupControl.swift
//  DinCore
//
//  Created by Jin on 2021/6/10.
//

import UIKit
import DinSupport

protocol DinUDPGroupControlDelegate: NSObjectProtocol {
    func control(_ control: DinUDPGroupControl, receivedGroupNotifyInfo info: [String: Any])
}

public class DinCommunicationGroup: NSObject, DinCommunicationDevice {
    public var groupID: String
    public var groupSecret: String

    public init(withGroupID groupID: String, groupSecret: String) {
        self.groupID = groupID
        self.groupSecret  = groupSecret
        super.init()
    }

    public var deviceID: String {
        ""
    }

    public var uniqueID: String {
        self.groupID
    }

    public var token: String {
        ""
    }

    public var area: String {
        ""
    }

    public var p2pAddress: String {
        set {}
        get {""}
    }

    public var p2pPort: UInt16 {
        0
    }

    public var lanAddress: String {
        set {}
        get {""}
    }

    public var lanPort: UInt16 {
        set {}
        get {0}
    }
}

/// 用于维持组心跳的控制器
public class DinUDPGroupControl: DinDeviceControl {
    weak var delegate: DinUDPGroupControlDelegate?

    public init?(withCommunicationGroup communicationGroup: DinCommunicationGroup, groupUser: DinGroupCommunicator) {
        guard let proxyDelivery = DinCore.proxyDeliver else {
            return nil
        }
        super.init(with: proxyDelivery,
                   communicationDevice: communicationGroup,
                   communicationIdentity: groupUser,
                   dataEncryptor: DinGroupEncryptor(withGroupSecret: communicationGroup.groupSecret, communicationSecret: groupUser.commSecret))
    }

    public override func receiveOtherCommunicationResult(_ result: DinMSCTResult) {
        super.receiveOtherCommunicationResult(result)
        var payloadDict = result.payloadDict
        // 接收者的ID（自己），有可能是空的
        let receiverData = result.msctDatas.first?.optionHeader?[DinMSCTOptionID.destinationMSCTID]?.data ?? Data()
        let receiverID = DinDataConvertor.convertToString(receiverData)
        payloadDict["receiverID"] = receiverID
        delegate?.control(self, receivedGroupNotifyInfo: payloadDict)
    }
}
