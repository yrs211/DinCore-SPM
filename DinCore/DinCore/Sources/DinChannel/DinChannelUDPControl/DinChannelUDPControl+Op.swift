//
//  DinChannelUDPControl+Op.swift
//  DinCore
//
//  Created by Jin on 2021/7/27.
//

import Foundation

// MARK: - 唤醒
extension DinChannelUDPControl {
    /// 唤醒目标设备
//    public static func wake(_ params: DinOperateTaskParams,
//                            targetID: String?,
//                            ackCallback: DinCommunicationCallback?,
//                            entryCommunicator: DinCommunicator?)  -> DinCommunication? {
//        let msgID = String.UUID()
//
//        // header
//        let msctHeader = Header(msgType: .CON, channel: .NORCHAN3)
//        // optionHeader
//        let userMSCTID = params.source.uniqueID
//        let groupID = params.destination.groupID
//        let proxyData = Data(Int(1).lyz_to4Bytes())
//
//        //        let domain = params.destination.area
//        //        dsLog("package userMSCTID:\(userMSCTID),deviceID:\(deviceID)")
//
//        var options = [OptionHeader]()
//        options.append(OptionHeader(id: DinMSCTOptionID.appID, data: (DinSupport.appID ?? "").data(using: .utf8)))
//        options.append(OptionHeader(id: DinMSCTOptionID.method, data: "wake".data(using: .utf8)))
//        options.append(OptionHeader(id: DinMSCTOptionID.sourceMSCTID, data: userMSCTID.data(using: .utf8)))
//        options.append(OptionHeader(id: DinMSCTOptionID.groupMSCTID, data: groupID.data(using: .utf8)))
//        if let destinationMSCTID = targetID, destinationMSCTID.count > 0 {
//            options.append(OptionHeader(id: DinMSCTOptionID.destinationMSCTID, data: destinationMSCTID.data(using: .utf8)))
//        }
//        options.append(OptionHeader(id: DinMSCTOptionID.proxyMSCTID, data: proxyData))
//        //        options.append(OptionHeader(id: DinMSCTOptionID.domain, data: domain.data(using: .utf8)))
//        options.append(OptionHeader(id: DinMSCTOptionID.msgID, data: msgID.data(using: .utf8)))
//
//        // 增加触发类型
//        var dataDict = (params.sendInfo as? [String: Any]) ?? [:]
//        //        dataDict["triggertype"] = DinSupportConstants.triggerOperationTypeiOS
//        //        dataDict["triggerid"] = params.source.id
//        //        dataDict["triggername"] = params.source.name
//        dataDict["__time"] = Int64(Date().timeIntervalSince1970)
//
//        // request
//        if let request = DinMSCTRequest(withRequestDict: DinDataConvertor.convertToData(dataDict) ?? Data(),
//                                            encryptor: params.dataEncryptor,
//                                            header: msctHeader,
//                                            optionHeader: options) {
//            let params = DinAddOperationParams(with: params.dataEncryptor,
//                                               messageID: msgID,
//                                               request: request,
//                                               resendTimes: nil)
//            return DinCommunicationGenerator.addOperation(with: params,
//                                                          ackCallback: ackCallback,
//                                                          resultCallback: nil,
//                                                          progressCallback: nil,
//                                                          resultTimeoutSec: 0,
//                                                          entryCommunicator: entryCommunicator)
//        }
//        return nil
//    }
}

// MARK: - 建立，撤除KCP通道
//extension DinChannelUDPControl {
//    public static func establishKcpCommunication(_ params: DinOperateTaskParams,
//                                                 ackCallback: DinCommunicationCallback?,
//                                                 entryCommunicator: DinCommunicator?)  -> DinCommunication? {
//        let msgID = String.UUID()
//
//        // header
//        let msctHeader = Header(msgType: .CON, channel: .NORCHAN3)
//        // optionHeader
//        let userMSCTID = params.source.uniqueID
//        let groupID = params.destination.groupID
////        let deviceID = params.destination.uniqueID
//
//        //        let domain = params.destination.area
//        //        dsLog("package userMSCTID:\(userMSCTID),deviceID:\(deviceID)")
//
//        var options = [OptionHeader]()
//        options.append(OptionHeader(id: DinMSCTOptionID.appID, data: (DinSupport.appID ?? "").data(using: .utf8)))
//        options.append(OptionHeader(id: DinMSCTOptionID.method, data: "estab".data(using: .utf8)))
//        options.append(OptionHeader(id: DinMSCTOptionID.sourceMSCTID, data: userMSCTID.data(using: .utf8)))
//        options.append(OptionHeader(id: DinMSCTOptionID.groupMSCTID, data: groupID.data(using: .utf8)))
////        options.append(OptionHeader(id: DinMSCTOptionID.destinationMSCTID, data: deviceID.data(using: .utf8)))
//        //        options.append(OptionHeader(id: DinMSCTOptionID.domain, data: domain.data(using: .utf8)))
//        options.append(OptionHeader(id: DinMSCTOptionID.msgID, data: msgID.data(using: .utf8)))
//
//        // 增加触发类型
//        var dataDict = (params.sendInfo as? [String: Any]) ?? [:]
//        //        dataDict["triggertype"] = DinSupportConstants.triggerOperationTypeiOS
//        //        dataDict["triggerid"] = params.source.id
//        //        dataDict["triggername"] = params.source.name
//        dataDict["__time"] = Int64(Date().timeIntervalSince1970)
//
//        // request
//        if let request = DinMSCTRequest(withRequestDict: DinDataConvertor.convertToData(dataDict) ?? Data(),
//                                            encryptor: params.dataEncryptor,
//                                            header: msctHeader,
//                                            optionHeader: options) {
//            let params = DinAddOperationParams(with: params.dataEncryptor,
//                                               messageID: msgID,
//                                               request: request,
//                                               resendTimes: nil)
//            return DinCommunicationGenerator.addOperation(with: params,
//                                                          ackCallback: ackCallback,
//                                                          resultCallback: nil,
//                                                          progressCallback: nil,
//                                                          resultTimeoutSec: 0,
//                                                          entryCommunicator: entryCommunicator)
//        }
//        return nil
//    }
//
//    public static func resignKcpCommunication(_ params: DinOperateTaskParams,
//                                              ackCallback: DinCommunicationCallback?,
//                                              entryCommunicator: DinCommunicator?)  -> DinCommunication? {
//        let msgID = String.UUID()
//
//        // header
//        let msctHeader = Header(msgType: .CON, channel: .NORCHAN3)
//        // optionHeader
//        let userMSCTID = params.source.uniqueID
//        let groupID = params.destination.groupID
//        let deviceID = params.destination.uniqueID
//
//        //        let domain = params.destination.area
//        //        dsLog("package userMSCTID:\(userMSCTID),deviceID:\(deviceID)")
//
//        var options = [OptionHeader]()
//        options.append(OptionHeader(id: DinMSCTOptionID.appID, data: (DinSupport.appID ?? "").data(using: .utf8)))
//        options.append(OptionHeader(id: DinMSCTOptionID.method, data: "term".data(using: .utf8)))
//        options.append(OptionHeader(id: DinMSCTOptionID.sourceMSCTID, data: userMSCTID.data(using: .utf8)))
//        options.append(OptionHeader(id: DinMSCTOptionID.groupMSCTID, data: groupID.data(using: .utf8)))
//        options.append(OptionHeader(id: DinMSCTOptionID.destinationMSCTID, data: deviceID.data(using: .utf8)))
//        //        options.append(OptionHeader(id: DinMSCTOptionID.domain, data: domain.data(using: .utf8)))
//        options.append(OptionHeader(id: DinMSCTOptionID.msgID, data: msgID.data(using: .utf8)))
//
//        // 增加触发类型
//        var dataDict = (params.sendInfo as? [String: Any]) ?? [:]
//        //        dataDict["triggertype"] = DinSupportConstants.triggerOperationTypeiOS
//        //        dataDict["triggerid"] = params.source.id
//        //        dataDict["triggername"] = params.source.name
//        dataDict["__time"] = Int64(Date().timeIntervalSince1970)
//
//        // request
//        if let request = DinMSCTRequest(withRequestDict: DinDataConvertor.convertToData(dataDict) ?? Data(),
//                                            encryptor: params.dataEncryptor,
//                                            header: msctHeader,
//                                            optionHeader: options) {
//            let params = DinAddOperationParams(with: params.dataEncryptor,
//                                               messageID: msgID,
//                                               request: request,
//                                               resendTimes: nil)
//            return DinCommunicationGenerator.addOperation(with: params,
//                                                          ackCallback: ackCallback,
//                                                          resultCallback: nil,
//                                                          progressCallback: nil,
//                                                          resultTimeoutSec: 0,
//                                                          entryCommunicator: entryCommunicator)
//        }
//        return nil
//    }
//}
