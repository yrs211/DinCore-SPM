//
//  DinLiveStreamingControl+KCPObjectDelegate.swift
//  DinCore
//
//  Created by Jin on 2021/6/11.
//

import Foundation
import DinSupport

extension DinLiveStreamingControl: DinChannelKcpObjectManagerDelegate {
    func manager(_ manager: DinChannelKcpObjectManager, requestSendData rawData: Data, withDeliverType type: DinDeviceUDPDeliverType) {
        self.communicateControl?.sendRawData(withDeliverType: type, rawData: rawData)
    }

    func manager(_ manager: DinChannelKcpObjectManager, requestEstabKcp sessionID: UInt16, channelID: UInt16, complete: ((Bool) -> Void)?) {
        estab(withKcpSessionID: sessionID, channelID: channelID, complete: complete)
    }

    func manager(_ manager: DinChannelKcpObjectManager, requestResignKcp sessionID: UInt16) {
        resignKcpConnection(withKcpSessionID: sessionID)
    }

    func manager(_ manager: DinChannelKcpObjectManager, receivedCMDData data: Data?, isReset: Bool) {
        guard let dataEncryptor = communicateControl?.dataEncryptor as? DinChannelEncryptor else {
            return
        }
        if let rawData = data, let decryptData = dataEncryptor.decryptedKcpData(rawData) {
            guard let returnDict = DinDataConvertor.convertToDictionary(decryptData) else {
                return
            }
            let cmd = returnDict["cmd"] as? String
            guard let status = returnDict["status"] as? Int else {
                return
            }
            // 刷新摄像头信息
            if status == 1 {
                switch cmd {
                case DinLiveStreamingControl.CMD_GET_PARAMS,
                     DinLiveStreamingControl.CMD_RESTORE,
                    DinLiveStreamingControl.CMD_IPC_VERISON_UPGRADED,
                    DinLiveStreamingControl.CMD_SET_TIMEZONE,
                    DinLiveStreamingControl.CMD_SET_DAILY_MEMORIES,
                    DinLiveStreamingControl.CMD_SET_RECORD_SCHEDULE:
                    refreshCameraSetting(returnDict) { [weak self] in
                        guard let self = self else { return }
                        self.operationManager.receiveOperationResult(returnDict)
                    }
                case DinLiveStreamingControl.CMD_SET_MOTIONDETECT:
                    refreshCameraMD(returnDict) { [weak self] in
                        guard let self = self else { return }
                        self.operationManager.receiveOperationResult(returnDict)
                    }
                case DinLiveStreamingControl.CMD_SET_MOTIONDETECT_LEVEL:
                    refreshCameraMDLevel(returnDict) { [weak self] in
                        guard let self = self else { return }
                        self.operationManager.receiveOperationResult(returnDict)
                    }
                case DinLiveStreamingControl.CMD_SET_MOTIONDETECT_ALARM:
                    refreshCameraMDAlarm(returnDict) { [weak self] in
                        guard let self = self else { return }
                        self.operationManager.receiveOperationResult(returnDict)
                    }
                case DinLiveStreamingControl.CMD_SET_PIR_LEVEL:
                    refreshCameraPIRLevel(returnDict) { [weak self] in
                        guard let self = self else { return }
                        self.operationManager.receiveOperationResult(returnDict)
                    }
                case DinLiveStreamingControl.CMD_SET_MDTIME:
                    refreshCameraMDTime(returnDict) { [weak self] in
                        guard let self = self else { return }
                        self.operationManager.receiveOperationResult(returnDict)
                    }
                case DinLiveStreamingControl.CMD_SET_GRAY:
                    refreshCameraGray(returnDict) { [weak self] in
                        guard let self = self else { return }
                        self.operationManager.receiveOperationResult(returnDict)
                    }
                case DinLiveStreamingControl.CMD_SET_HFLIP:
                    refreshCameraHFlip(returnDict) { [weak self] in
                        guard let self = self else { return }
                        self.operationManager.receiveOperationResult(returnDict)
                    }
                case DinLiveStreamingControl.CMD_SET_VFLIP:
                    refreshCameraVFlip(returnDict) { [weak self] in
                        guard let self = self else { return }
                        self.operationManager.receiveOperationResult(returnDict)
                    }
                case DinLiveStreamingControl.CMD_SET_AUTO_FLOOD_LIGHT:
                    refreshAutoFloodlight(returnDict) { [weak self] in
                        guard let self = self else { return }
                        self.operationManager.receiveOperationResult(returnDict)
                    }
                case DinLiveStreamingControl.CMD_SET_MOTION_DETECT_FOLLOW:
                    refreshMotionDetectFollowStatus(returnDict) { [weak self] in
                        guard let self = self else { return }
                        self.operationManager.receiveOperationResult(returnDict)
                    }
                case DinLiveStreamingControl.CMD_RECORDLIST:
                    var ownDict = returnDict
                    let isOwn = returnDict["messageid"] as? String == self.getRecordListMessageID
                    // 标志是否是自己的
                    ownDict["owned"] = isOwn
                    if isOwn {
                        self.getRecordListMessageID = ""
                    }
                    ownDict.removeValue(forKey: "messageid")
                    operationManager.receiveOperationResult(ownDict)
                    return
                case DinLiveStreamingControl.CMD_RECORDLIST_V2:
                    var ownDict = returnDict
                    let isOwn = returnDict["messageid"] as? String == self.getRecordListMessageIDV2
                    // 标志是否是自己的
                    ownDict["owned"] = isOwn
                    if isOwn {
                        self.getRecordListMessageIDV2 = ""
                    }
                    ownDict.removeValue(forKey: "messageid")
                    operationManager.receiveOperationResult(ownDict)
                    return
                case DinLiveStreamingControl.CMD_DEL_RECORDFILE:
                    var ownDict = returnDict
                    let isOwn = returnDict["messageid"] as? String == self.deleteRecordFileMessageID
                    // 标志是否是自己的
                    ownDict["owned"] = isOwn
                    if isOwn {
                        self.deleteRecordFileMessageID = ""
                    }
                    if ownDict["status"] as? Int == 1, let fileName = returnDict["file"] as? String, fileName.count > 0 {
                        manager.fileFetcher?.removeCache(fullFileName: "\(fileName).jpg")
                    }
                    ownDict.removeValue(forKey: "messageid")
                    operationManager.receiveOperationResult(ownDict)
                    return
                case DinLiveStreamingControl.CMD_UPGRADE:
                    update(versions: []) { [weak self] in
                        var ownDict = returnDict
                        let isOwn = returnDict["messageid"] as? String == self?.upgradeFirmwareMessageID
                        // 标志是否是自己的
                        ownDict["owned"] = isOwn
                        ownDict.removeValue(forKey: "messageid")
                        self?.operationManager.receiveOperationResult(ownDict)
                    }
                    return
                default:
                    operationManager.receiveOperationResult(returnDict)
                }
            } else {
                switch cmd {
                case DinLiveStreamingControl.CMD_UPGRADE:
                    var ownDict = returnDict
                    let isOwn = returnDict["messageid"] as? String == self.upgradeFirmwareMessageID
                    // 标志是否是自己的
                    ownDict["owned"] = isOwn
                    ownDict.removeValue(forKey: "messageid")
                    operationManager.receiveOperationResult(ownDict)
                    return
                default:
                    operationManager.receiveOperationResult(returnDict)
                }
            }
        } else {
        }
    }

    func manager(_ manager: DinChannelKcpObjectManager, receivedHDLiveData data: Data?, isReset: Bool) {
        guard let dataEncryptor = communicateControl?.dataEncryptor as? DinChannelEncryptor else {
            return
        }
        decryQueue?.async { [weak self] in
            if let rawData = data, let decryptData = dataEncryptor.decryptedKcpData(rawData) {
                self?.accept(deviceOperationResult: ["cmd": DinLiveStreamingControl.CMD_REQUESTLIVE, "data": decryptData])
            }
        }
    }

    func manager(_ manager: DinChannelKcpObjectManager, receivedSTDLiveData data: Data?, isReset: Bool) {
        guard let dataEncryptor = communicateControl?.dataEncryptor as? DinChannelEncryptor else {
            return
        }
        decryQueue?.async { [weak self] in
            if let rawData = data, let decryptData = dataEncryptor.decryptedKcpData(rawData) {
                self?.accept(deviceOperationResult: ["cmd": DinLiveStreamingControl.CMD_REQUESTLIVE, "data": decryptData])
            }
        }
    }

    func manager(_ manager: DinChannelKcpObjectManager, receivedAudioData data: Data?, isReset: Bool) {
        guard let dataEncryptor = communicateControl?.dataEncryptor as? DinChannelEncryptor else {
            return
        }
        if let rawData = data, let decryptData = dataEncryptor.decryptedKcpData(rawData) {
            accept(deviceOperationResult: ["cmd": DinLiveStreamingControl.CMD_REQUESTLIVE_AUDIO, "data": decryptData])
        }
    }

    func manager(_ manager: DinChannelKcpObjectManager, receivedTalkData data: Data?, isReset: Bool) {
        // 如果说话通道收到reset，取消说话通道的kcp，通知上层
        if isReset {
            manager.deactiveTalk()
            accept(deviceOperationResult: ["cmd": DinLiveStreamingControl.CMD_SEND_AUDIOFAIL])
        }
    }

    func manager(_ manager: DinChannelKcpObjectManager, receivedFileAt filePath: String, fileName: String, fileType: String, status: DinChannelKcpObjectFileFetchStatus) {
        accept(deviceOperationResult: ["cmd": DinLiveStreamingControl.CMD_RECORDFILE,
                                       "status": status.rawValue,
                                       "filePath": filePath,
                                       "type": fileType,
                                       "fileName": fileName])
//        switch status {
//        case .success:
//        case .saveFileFailure:
//        case .dataFormatFailure:
//        case .kcpReset:
//        case .timeout:
//        case .paramsError:
//        case .interrupt:
//        }
    }
}

extension DinLiveStreamingControl {
    private func refreshCameraMDLevel(_ setting: [String: Any], complete: (()->())?) {
        if let mdLevel = setting["md_level"] as? Int {
            updateMotionDetectLevel(mdLevel, usingSync: false, complete: complete)
        }
    }
    
    private func refreshCameraMDAlarm(_ setting: [String: Any], complete: (()->())?) {
        if let mdAlarm = setting["md_alarm"] as? Bool {
            updateMDAlarm(mdAlarm, usingSync: false, complete: complete)
        }
    }

    private func refreshCameraPIRLevel(_ setting: [String: Any], complete: (()->())?) {
        if let pirLevel = setting["pir_level"] as? Int {
            updatePIRLevel(pirLevel, usingSync: false, complete: complete)
        }
    }

    private func refreshCameraMDTime(_ setting: [String: Any], complete: (()->())?) {
        if let startTime = setting["md_begin_time"] as? String,
           let endTime = setting["md_end_time"] as? String {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                self?.updateMDStartTime(startTime, usingSync: true, complete: nil)
                self?.updateMDEndTime(endTime, usingSync: true, complete: nil)
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    private func refreshCameraMD(_ setting: [String: Any], complete: (()->())?) {
        if let motionDetect = setting["md"] as? Bool {
            updateMotionDetect(motionDetect, usingSync: false, complete: complete)
        }
    }
    private func refreshCameraGray(_ setting: [String: Any], complete: (()->())?) {
        if let gray = setting["gray"] as? Bool {
            updateGray(gray, usingSync: false, complete: complete)
        }
    }
    private func refreshCameraHFlip(_ setting: [String: Any], complete: (()->())?) {
        if let hflip = setting["hflip"] as? Bool {
            updateHFlip(hflip, usingSync: false, complete: complete)
        }
    }
    private func refreshCameraVFlip(_ setting: [String: Any], complete: (()->())?) {
        if let vflip = setting["vflip"] as? Bool {
            updateVFlip(vflip, usingSync: false, complete: complete)
        }
    }
    private func refreshAutoFloodlight(_ setting: [String: Any], complete: (()->())?) {
        if let autoFloodlight = setting["auto_floodlight"] as? Bool {
            updateAutoFloodlight(autoFloodlight, usingSync: false, complete: complete)
        }
    }
    
    private func refreshMotionDetectFollowStatus(_ setting: [String: Any], complete: (()->())?) {
        if let followStatus = setting["follow_status"] as? [String] {
            updateMDFollowStatus(followStatus, usingSync: false, complete: complete)
        }
    }

    private func refreshCameraSetting(_ setting: [String: Any], complete: (()->())?) {
        DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            if let version = setting["version"] as? String, version.count > 0 {
                self.updateVersion(version, usingSync: true, complete: nil)
            }
            if let versions = setting["versions"] as? [[String: String]] {
                self.updateVersions(versions, usingSync: true, complete: nil)
            }
            if let chip = setting["chip"] as? String {
                self.updateChip(chip, usingSync: true, complete: nil)
            }
            if let ssid = setting["ssid"] as? String, ssid.count > 0 {
                self.updateSSID(ssid, usingSync: true, complete: nil)
            }
            if let tfCapacity = setting["tf_capacity"] as? Int {
                self.updateTFCapacity(tfCapacity, usingSync: true, complete: nil)
            }
            if let timezone = setting["tz"] as? String {
                self.updateTimezone(timezone, usingSync: true, complete: nil)
            }
            if let ip = setting["ip"] as? String {
                // 用于局域网通讯信息更新, 无需更新InfoDict
                self.updateIP(ip, usingSync: true, complete: nil)
            }
            if let port = setting["port"] as? UInt16 {
                // 用于局域网通讯信息更新, 无需更新InfoDict
                self.device.lanPort = port
            }
            if let battery = setting["battery"] as? Int {
                self.updateBattery(battery, usingSync: true, complete: nil)
            }
            if let hd = setting["hd"] as? Bool {
                self.updateHD(hd, usingSync: true, complete: nil)
            }
            if let tfUsed = setting["tf_used"] as? Int {
                self.updateTFUsed(tfUsed, usingSync: true, complete: nil)
            }
            if let horizontalFlip = setting["hflip"] as? Bool {
                self.updateHFlip(horizontalFlip, usingSync: true, complete: nil)
            }
            if let vflip = setting["vflip"] as? Bool {
                self.updateVFlip(vflip, usingSync: true, complete: nil)
            }
            if let charging = setting["charging"] as? Bool {
                self.updateCharging(charging, usingSync: true, complete: nil)
            }
            if let motionDetect = setting["md"] as? Bool {
                self.updateMotionDetect(motionDetect, usingSync: true, complete: nil)
            }
            if let mdLevel = setting["md_level"] as? Int {
                self.updateMotionDetectLevel(mdLevel, usingSync: true, complete: nil)
            }
            if let mdAlarm = setting["md_alarm"] as? Bool {
                self.updateMDAlarm(mdAlarm, usingSync: true, complete: nil)
            }
            if let pirLevel = setting["pir_level"] as? Int {
                self.updatePIRLevel(pirLevel, usingSync: true, complete: nil)
            }
            if let mdStartTime = setting["md_begin_time"] as? String {
                self.updateMDStartTime(mdStartTime, usingSync: true, complete: nil)
            }
            if let mdEndTime = setting["md_end_time"] as? String {
                self.updateMDEndTime(mdEndTime, usingSync: true, complete: nil)
            }
            if let mdShouldFollowPanel = setting["panel_follow"] as? Bool {
                self.updateMDShouldFollowPanel(mdShouldFollowPanel, usingSync: true, complete: nil)
                
            }
            if let followStatus = setting["follow_status"] as? [String] {
                self.updateMDFollowStatus(followStatus, usingSync: true, complete: nil)
                
            }
            if let mac = setting["mac"] as? String {
                self.updateMac(mac, usingSync: true, complete: nil)
            }
            if let rssi = setting["rssi"] as? Int {
                self.updateRSSI(rssi, usingSync: true, complete: nil)
            }
            if let gray = setting["gray"] as? Bool {
                self.updateGray(gray, usingSync: true, complete: nil)
            }

            if let autoFloodlight = setting["auto_floodlight"] as? Bool {
                self.updateAutoFloodlight(autoFloodlight, usingSync: true, complete: nil)
            }

            if let timestamp = setting["daily_memories"] as? Int64 {
                self.update(dailyMemoriesStartTimestamp: timestamp, usingSync: true, complete: nil)
            }

            if let value = setting["scheduled"] as? Bool {
                self.updateRecordSchedule(enabled: value, usingSync: true, complete: nil)
            }

            if let value = setting["scheduled_time"] as? DinLiveStreaming.RecordSchedule {
                self.updateRecordSchedule(schedule: value, usingSync: true, complete: nil)
            }

            // 防止通过 DinUser.homeDeviceInfoQueue 出去，然后在DinUser.homeDeviceInfoQueue里面请求info
            // 导致 async 和 sync 之间冲突
            // 并且通过 DinEventBus.rxSerialQueue 串行发送数据出去
            DinEventBus.rxSerialQueue.async {
                // 通知通过 "get_params" 指令获取ipc局域网信息更新成功
                DinCore.eventBus.camera.accept(cameraLanIPReceived: self.device.id)
            }

            DispatchQueue.global().async {
                complete?()
            }
        }
    }
}

extension DinLiveStreamingControl: DinChannelKcpOperationManagerDelegate {
    func operation(result: [String : Any]) {
        accept(deviceOperationResult: result)
    }

    func operation(timeoutCMD: String) {
        accept(deviceOperationResult: ["cmd": timeoutCMD, "status": 0, "owned": true])
    }
}
