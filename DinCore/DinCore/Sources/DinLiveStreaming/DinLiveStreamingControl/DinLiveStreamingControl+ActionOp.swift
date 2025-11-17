//
//  DinLiveStreamingControl+ActionOp.swift
//  DinCore
//
//  Created by Jin on 2021/6/10.
//

import Foundation
import DinSupport

extension DinLiveStreamingControl {
    func requestLive(qualityHD: Bool) {
        guard let dataEncryptor = communicateControl?.dataEncryptor as? DinChannelEncryptor else {
            return
        }
        // 增加触发类型
        var dataDict: [String: Any] = [:]
        dataDict["__time"] = Int64(Date().timeIntervalSince1970)
        guard let encryptData = dataEncryptor.encryptedKcpData(DinDataConvertor.convertToData(dataDict) ?? Data()) else {
            return
        }
        getAvailableManagerByPriority()?.requestLive(qualityHD: qualityHD, liveData: encryptData)
    }
    func stopLive() {
        proxyKcpManager?.deactiveLive()
        p2pKcpManager?.deactiveLive()
        lanKcpManager?.deactiveLive()
    }

    func requestAudio() {
        guard let dataEncryptor = communicateControl?.dataEncryptor as? DinChannelEncryptor else {
            return
        }
        // 增加触发类型
        var dataDict: [String: Any] = [:]
        dataDict["__time"] = Int64(Date().timeIntervalSince1970)
        guard let encryptData = dataEncryptor.encryptedKcpData(DinDataConvertor.convertToData(dataDict) ?? Data()) else {
            return
        }
        getAvailableManagerByPriority()?.requestAudio(withData: encryptData)
    }
    func stopAudio() {
        proxyKcpManager?.deactiveAudio()
        p2pKcpManager?.deactiveAudio()
        lanKcpManager?.deactiveAudio()
    }

    func beginTalking(withVoiceData data: Data) {
        guard let dataEncryptor = communicateControl?.dataEncryptor as? DinChannelEncryptor else {
            return
        }
        guard let encryptData = dataEncryptor.encryptedKcpData(data) else {
            return
        }
        getAvailableManagerByPriority()?.beginTalking(withVoiceData: encryptData)
    }
    func stopTalk() {
        proxyKcpManager?.deactiveTalk()
        p2pKcpManager?.deactiveTalk()
        lanKcpManager?.deactiveTalk()
    }

    func beginDownload(withFileName fileName: String, type: String) {
//        guard let dataEncryptor = communicateControl?.dataEncryptor as? DinChannelEncryptor else {
//            return
//        }
//        guard let encryptData = dataEncryptor.encryptedKcpData(data) else {
//            return
//        }
//        getAvailableManagerByPriority()?.beginTalking(withVoiceData: encryptData)
//        let dataDict: [String: Any] = ["filename": fileName]
//        getAvailableManagerByPriority()?.download(withData: DinDataConvertor.convertToData(dataDict) ?? Data())
        getAvailableManagerByPriority()?.beginFetchFile(withFileName: fileName, fileType: type)
    }
    func stopDownload() {
        proxyKcpManager?.stopFetch()
        p2pKcpManager?.stopFetch()
        lanKcpManager?.stopFetch()
        proxyKcpManager?.deactiveDownload()
        p2pKcpManager?.deactiveDownload()
        lanKcpManager?.deactiveDownload()
    }
}
