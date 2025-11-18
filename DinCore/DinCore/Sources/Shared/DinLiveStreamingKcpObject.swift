//
//  DinLiveStreamingKcpObject.swift
//  DinCore
//
//  Created by Jin on 2021/6/30.
//

import UIKit
import DinSupport
import DinSupportObjC
class DinLiveStreamingKcpObject: NSObject {

    let convString: String
    let convID: UInt32
    let sessionID: UInt16
    let channelID: UInt16
    let kcpObject: KCPObject

    init?(withKcpType type: DinKcpType, outputDataHandle: @escaping KCPObjectOutputDataHandle) {
        sessionID = DinKCPConvUtil.genSessionID()
        guard let genChannelID = DinKCPConvUtil.channelIDWithType(type),
              let genConvID = DinKCPConvUtil.convWithType(type, sessionID: sessionID) else {
            return nil
        }
        channelID = genChannelID
        convID = genConvID
        kcpObject = KCPObject(convID: convID, outputDataHandle: outputDataHandle)
        convString = kcpObject.convString
        super.init()
    }
}
