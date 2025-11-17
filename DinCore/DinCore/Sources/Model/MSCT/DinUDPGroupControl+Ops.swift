//
//  DinUDPGroupControl+Ops.swift
//  DinCore
//
//  Created by Jin on 2021/6/11.
//

import Foundation
import DinSupport

extension DinUDPGroupControl {
    public func establishKcpCommunication(withKcpSessionID sessionID: UInt16,
                                          channelID: UInt16,
                                          kcpTowardsID: String,
                                          success: DinCommunicationCallback.SuccessBlock?,
                                          fail: DinCommunicationCallback.FailureBlock?,
                                          timeout: DinCommunicationCallback.TimeoutBlock?) {
        let payloadDic: [String: Any] = ["sess_id": sessionID, "readable": true, "channel_white_list":[channelID]]
        let msgID = String.UUID()
        let ackCallback = DinCommunicationCallback(successBlock: success, failureBlock: fail, timeoutBlock: timeout)

        let params = DinOperateTaskParams(with: dataEncryptor,
                                          source: communicationIdentity,
                                          destination: communicationDevice,
                                          messageID: msgID,
                                          sendInfo: payloadDic,
                                          ignoreSendInfoInNil: false)
        _ = DinCommunicationGenerator.establishKcpCommunication(params,
                                                                kcpTowardsID: kcpTowardsID,
                                                                ackCallback: ackCallback,
                                                                entryCommunicator: communicator)
    }

    public func resignKcpCommunication(withKcpSessionID sessionID: UInt16,
                                       success: DinCommunicationCallback.SuccessBlock?,
                                       fail: DinCommunicationCallback.FailureBlock?,
                                       timeout: DinCommunicationCallback.TimeoutBlock?) {
        let payloadDic: [String: Any] = ["sess_id": sessionID]
        let msgID = String.UUID()
        let ackCallback = DinCommunicationCallback(successBlock: success, failureBlock: fail, timeoutBlock: timeout)

        let params = DinOperateTaskParams(with: dataEncryptor,
                                          source: communicationIdentity,
                                          destination: communicationDevice,
                                          messageID: msgID,
                                          sendInfo: payloadDic,
                                          ignoreSendInfoInNil: false)
        _ = DinCommunicationGenerator.resignKcpCommunication(params,
                                                             ackCallback: ackCallback,
                                                             entryCommunicator: communicator)
    }

//    public func wake(withTargetID targetID: String,
//                     success: DinCommunicationCallback.SuccessBlock?,
//                     fail: DinCommunicationCallback.FailureBlock?,
//                     timeout: DinCommunicationCallback.TimeoutBlock?) {
//        let msgID = String.UUID()
//        let ackCallback = DinCommunicationCallback(successBlock: success, failureBlock: fail, timeoutBlock: timeout)
//
//        let params = DinOperateTaskParams(with: dataEncryptor,
//                                          source: communicationIdentity,
//                                          destination: communicationDevice,
//                                          messageID: msgID,
//                                          sendInfo: "")
//        _ = DinCommunicationGenerator.wake(params, targetID: targetID, ackCallback: ackCallback, entryCommunicator: communicator)
//    }
}
