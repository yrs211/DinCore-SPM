//
//  DinChannelUDPControl.swift
//  DinCore
//
//  Created by Jin on 2021/7/21.
//

import UIKit
import DinSupport

class DinChannelUDPControl: DinDeviceControl {
    init(with proxyDeliver: DinProxyDeliver, communicationDevice: DinCommunicationDevice, communicationIdentity: DinCommunicationIdentity, dataEncryptor: DinCommunicationEncryptor) {
        super.init(with: proxyDeliver, communicationDevice: communicationDevice, communicationIdentity: communicationIdentity, dataEncryptor: dataEncryptor, needKeepLive: true, useLanAndP2P: true)
    }

    override func requestKeepliveCommunication(deliverType: DinDeviceUDPDeliverType, withSuccess success: DinCommunicationCallback.SuccessBlock?, fail: DinCommunicationCallback.FailureBlock?, timeout: DinCommunicationCallback.TimeoutBlock?) -> DinCommunication? {
        if deliverType == .lan {
            return lanKeepliveCommunication(withSuccess: success, fail: fail, timeout: timeout)
        } else if deliverType == .p2p {
            return p2pKeepliveCommunication(withSuccess: success, fail: fail, timeout: timeout)
        } else {
            return proxyKeepliveCommunication(withSuccess: success, fail: fail, timeout: timeout)
        }
    }

    private func lanKeepliveCommunication(withSuccess success: DinCommunicationCallback.SuccessBlock?, fail: DinCommunicationCallback.FailureBlock?, timeout: DinCommunicationCallback.TimeoutBlock?) -> DinCommunication? {
        return wake(withTargetID: communicationDevice.uniqueID, success: success, fail: fail, timeout: timeout)
    }
    private func p2pKeepliveCommunication(withSuccess success: DinCommunicationCallback.SuccessBlock?, fail: DinCommunicationCallback.FailureBlock?, timeout: DinCommunicationCallback.TimeoutBlock?) -> DinCommunication? {
        return wake(withTargetID: communicationDevice.uniqueID, success: success, fail: fail, timeout: timeout)
    }
    private func proxyKeepliveCommunication(withSuccess success: DinCommunicationCallback.SuccessBlock?, fail: DinCommunicationCallback.FailureBlock?, timeout: DinCommunicationCallback.TimeoutBlock?) -> DinCommunication? {
        return wake(withTargetID: communicationDevice.uniqueID, success: success, fail: fail, timeout: timeout)
    }

    private func wake(withTargetID targetID: String,
                      success: DinCommunicationCallback.SuccessBlock?,
                      fail: DinCommunicationCallback.FailureBlock?,
                      timeout: DinCommunicationCallback.TimeoutBlock?) -> DinCommunication? {
        let msgID = String.UUID()
        let ackCallback = DinCommunicationCallback(successBlock: success, failureBlock: fail, timeoutBlock: timeout)

        let params = DinOperateTaskParams(with: dataEncryptor,
                                          source: communicationIdentity,
                                          destination: communicationDevice,
                                          messageID: msgID,
                                          sendInfo: "",
                                          ignoreSendInfoInNil: false)
        return DinCommunicationGenerator.wake(params, targetID: targetID, ackCallback: ackCallback, entryCommunicator: nil)
    }
}
