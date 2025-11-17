//
//  DinLiveStreamingControl+SettingOp.swift
//  DinCore
//
//  Created by Jin on 2021/6/10.
//

import Foundation
import DinSupport

extension DinLiveStreamingControl {
    func submitData(_ actionDict: [String: Any]) {
        if let cmd = actionDict["cmd"] as? String {
            operationManager.startOperation(withCmd: cmd)
            switch cmd {
            case DinLiveStreamingControl.CMD_GET_PARAMS,
                DinLiveStreamingControl.CMD_SET_MOTIONDETECT,
                DinLiveStreamingControl.CMD_SET_MOTIONDETECT_LEVEL,
                DinLiveStreamingControl.CMD_SET_MOTIONDETECT_ALARM,
                DinLiveStreamingControl.CMD_SET_PIR_LEVEL,
                DinLiveStreamingControl.CMD_SET_MDTIME,
                DinLiveStreamingControl.CMD_RESTORE,
                DinLiveStreamingControl.CMD_RESET,
                DinLiveStreamingControl.CMD_REBOOT,
                DinLiveStreamingControl.CMD_FORMAT_TF,
                DinLiveStreamingControl.CMD_SET_GRAY,
                DinLiveStreamingControl.CMD_SET_HFLIP,
                DinLiveStreamingControl.CMD_SET_VFLIP,
                DinLiveStreamingControl.CMD_SET_TIMEZONE,
                DinLiveStreamingControl.CMD_SET_FLOOD_LIGHT,
                DinLiveStreamingControl.CMD_SET_AUTO_FLOOD_LIGHT,
                DinLiveStreamingControl.CMD_SET_MOTION_DETECT_FOLLOW,
                DinLiveStreamingControl.CMD_SET_DAILY_MEMORIES,
                DinLiveStreamingControl.CMD_SET_RECORD_SCHEDULE:
                sendCMD(actionDict)
            case DinLiveStreamingControl.CMD_RECORDLIST,
                DinLiveStreamingControl.CMD_RECORDLIST_V2,
                DinLiveStreamingControl.CMD_DEL_RECORDFILE,
                DinLiveStreamingControl.CMD_UPGRADE:
                sendCMD(genOwnIdentifyActionDict(actionDict, withCMD: cmd))
            case DinLiveStreamingControl.CMD_SET_NAME:
                rename(actionDict)
            case DinLiveStreamingControl.CMD_GET_ALERTMODE:
                getAlertMode(actionDict)
            case DinLiveStreamingControl.CMD_SET_ALERTMODE:
                setAlertMode(actionDict)
            case DinLiveStreamingControl.CMD_GET_SERVICE_SETTINGS:
                getServiceSettings()
            case DinLiveStreamingControl.CMD_UPDATE_SERVICE_SETTINGS:
                updateServiceSettings(actionDict)
            default:
                break
            }
        }
    }
}

extension DinLiveStreamingControl {
    private func genOwnIdentifyActionDict(_ actionDict: [String: Any], withCMD cmd: String) -> [String: Any] {
        var ownIDData = actionDict
        switch cmd {
        case DinLiveStreamingControl.CMD_RECORDLIST:
            self.getRecordListMessageID = String.UUID()
            ownIDData["messageid"] = self.getRecordListMessageID
            break
        case DinLiveStreamingControl.CMD_RECORDLIST_V2:
            self.getRecordListMessageIDV2 = String.UUID()
            ownIDData["messageid"] = self.getRecordListMessageIDV2
            break
        case DinLiveStreamingControl.CMD_DEL_RECORDFILE:
            self.deleteRecordFileMessageID = String.UUID()
            ownIDData["messageid"] = self.deleteRecordFileMessageID
            break
        case DinLiveStreamingControl.CMD_UPGRADE:
            self.upgradeFirmwareMessageID = String.UUID()
            ownIDData["messageid"] = self.upgradeFirmwareMessageID
        default:
            break
        }
        return ownIDData
    }

    private func rename(_ actionDict: [String: Any]) {
        guard let name = actionDict["name"] as? String else {
            operationManager.receiveOperationResult(["cmd": DinLiveStreamingControl.CMD_SET_NAME, "status": 0, "errorMessage": "lack of params", "result": [:]])
            return
        }
        let request = DinLiveStreamingRequest.renameDevice(
            homeID: homeID,
            deviceID: device.id,
            newName: name,
            provider: deviceProvider
        )
        DinHttpProvider.request(request) { [weak self] result in
            self?.rename(name, complete: nil)
        } fail: { [weak self] _ in
            self?.operationManager.receiveOperationResult(["cmd": DinLiveStreamingControl.CMD_SET_NAME, "status": 0, "errorMessage": "api error", "result": [:]])
        }
    }

    func rename(_ name: String, complete: (()->())?) {
        updateName(name, usingSync: false) { [weak self] in
            guard let self = self else { return }
            self.operationManager.receiveOperationResult(
                [
                    "cmd": DinLiveStreamingControl.CMD_SET_NAME,
                    "status": 1,
                    "errorMessage": "",
                    "result": ["name": name]
                ]
            )
            complete?()
        }
    }

    /// 发送cmd kcp
    /// - Parameters:
    ///   - actionDict: cmd 数据
    ///   - manager: kcp管理器
    func sendCMD(_ actionDict: [String: Any], manager: DinChannelKcpObjectManager? = nil) {
        // 增加手机识别，是iOS还是安卓的
        var infoIDDict = actionDict
        infoIDDict["client"] = "iOS"
        if let actionData = DinDataConvertor.convertToData(infoIDDict) {
            guard let dataEncryptor = communicateControl?.dataEncryptor as? DinChannelEncryptor else {
                return
            }
            guard let encryptData = dataEncryptor.encryptedKcpData(actionData) else {
                return
            }
            // 如果是KeepLive，所有通道都发送
            if actionDict["cmd"] as? String == "keepalive" {
                manager?.sendCMD(data: encryptData)
            } else {
                getAvailableManagerByPriority()?.sendCMD(data: encryptData)
            }
        }
    }
    func stopCMDKcp() {
        proxyKcpManager?.deactiveCMDKcp()
        p2pKcpManager?.deactiveCMDKcp()
        lanKcpManager?.deactiveCMDKcp()
    }

    private func getAlertMode(_ actionDict: [String: Any]) {
        let request = DinLiveStreamingRequest.getMotionDetectAlertMode(
            homeID: homeID,
            deviceID: device.id,
            provider: deviceProvider
        )
        DinHttpProvider.request(request) { [weak self] result in
            if let alertModeDict = result?["ipc_service"] as? [String: Any],
               let alertMode = alertModeDict["alert_mode"] as? String {
                self?.updateAlertMode(alertMode, usingSync: false, complete: { [weak self] in
                    self?.operationManager.receiveOperationResult(["cmd": DinLiveStreamingControl.CMD_GET_ALERTMODE, "status": 1, "errorMessage": "", "result": ["alert_mode": alertMode]])
                })
            } else {
                self?.operationManager.receiveOperationResult(["cmd": DinLiveStreamingControl.CMD_GET_ALERTMODE, "status": 0, "errorMessage": "convert fail", "result": [:]])
            }
        } fail: { [weak self] _ in
            self?.operationManager.receiveOperationResult(["cmd": DinLiveStreamingControl.CMD_GET_ALERTMODE, "status": 0, "errorMessage": "api error", "result": [:]])
        }
    }

    private func setAlertMode(_ actionDict: [String: Any]) {
        guard let alertMode = actionDict["alert_mode"] as? String else {
            operationManager.receiveOperationResult(["cmd": DinLiveStreamingControl.CMD_SET_ALERTMODE,
                                                     "status": 0,
                                                     "errorMessage": "lack of params",
                                                     "result": [:]])
            return
        }
        let request = DinLiveStreamingRequest.setMotionDetectAlertMode(
            homeID: homeID,
            deviceID: device.id,
            alertMode: alertMode,
            provider: deviceProvider
        )
        DinHttpProvider.request(request) { [weak self] result in
            self?.updateAlertMode(alertMode, usingSync: false, complete: { [weak self] in
                self?.operationManager.receiveOperationResult(["cmd": DinLiveStreamingControl.CMD_SET_ALERTMODE, "status": 1, "errorMessage": "", "result": ["alert_mode": alertMode]])
            })
        } fail: { [weak self] _ in
            self?.operationManager.receiveOperationResult(["cmd": DinLiveStreamingControl.CMD_SET_ALERTMODE, "status": 0, "errorMessage": "api error", "result": [:]])
        }
    }

    private func getServiceSettings() {
        let parameters = DinLiveStreamingRequest.GetServiceSettingParameters(
            homeID: homeID,
            provider: deviceProvider,
            deviceID: device.id
        )
        let request = DinLiveStreamingRequest.getServiceSettings(parameters: parameters)
        DinHttpProvider.request(request) { [weak self] result in
            guard let self = self else { return }
            if let payload = result?["ipc_service"] as? [String: Any] {
                self.updateServiceSettings(payload, usingSync: false) { [weak self] in
                    self?.operationManager.receiveOperationResult(
                        [
                            "cmd": DinLiveStreamingControl.CMD_GET_SERVICE_SETTINGS,
                            "status": 1,
                            "errorMessage": "",
                            "result": payload
                        ]
                    )
                }
            } else {
                self.operationManager.receiveOperationResult(
                    [
                        "cmd": DinLiveStreamingControl.CMD_GET_SERVICE_SETTINGS,
                        "status": 0,
                        "errorMessage": "convert fail",
                        "result": [:]
                    ]
                )
            }
        } fail: { [weak self] _ in
            guard let self = self else { return }
            self.operationManager.receiveOperationResult(
                [
                    "cmd": DinLiveStreamingControl.CMD_GET_SERVICE_SETTINGS,
                    "status": 0,
                    "errorMessage": "api error",
                    "result": [:]
                ]
            )
        }
    }

    private func updateServiceSettings(_ input: [String: Any]) {
        guard
            let alertMode = input["alert_mode"] as? String, !alertMode.isEmpty,
            let isCloudStorageEnabled = input["cloud_storage"] as? Bool,
            let arm = input["arm"] as? Bool,
            let disarm = input["disarm"] as? Bool,
            let homearm = input["home_arm"] as? Bool,
            let sos = input["sos"] as? Bool
        else {
            operationManager.receiveOperationResult(
                [
                    "cmd": DinLiveStreamingControl.CMD_UPDATE_SERVICE_SETTINGS,
                    "status": 0,
                    "errorMessage": "lack of params",
                    "result": [:]
                ]
            )
            return
        }

        let parameters = DinLiveStreamingRequest.UpdateServiceSettingParameters(
            homeID: homeID,
            provider: deviceProvider,
            deviceID: device.id,
            alertMode: alertMode,
            isCloudStorageEnabled: isCloudStorageEnabled,
            arm: arm,
            disarm: disarm,
            homeArm: homearm,
            sos: sos
        )
        let request = DinLiveStreamingRequest.updateServiceSettings(parameters: parameters)
        DinHttpProvider.request(request) { [weak self] result in
            guard let self = self else { return }
            let payload: [String: Any] = [
                "alert_mode": alertMode,
                "cloud_storage": isCloudStorageEnabled,
                "arm": arm,
                "disarm": disarm,
                "home_arm": homearm,
                "sos": sos,
            ]
            self.updateServiceSettings(payload, usingSync: false) { [weak self] in
                self?.operationManager.receiveOperationResult(
                    [
                        "cmd": DinLiveStreamingControl.CMD_UPDATE_SERVICE_SETTINGS,
                        "status": 1,
                        "errorMessage": "",
                        "result": payload
                    ]
                )
            }
        } fail: { [weak self] _ in
            guard let self = self else { return }
            self.operationManager.receiveOperationResult(
                [
                    "cmd": DinLiveStreamingControl.CMD_UPDATE_SERVICE_SETTINGS,
                    "status": 0,
                    "errorMessage": "api error",
                    "result": [:]
                ]
            )
        }
    }

    func update(versions: [[String: String]], complete: (()->())?) {
        updateVersions(versions, usingSync: false, complete: complete)
    }
    
    func setIsDeleted(_ isDeleted: Bool, usingSync sync: Bool, complete: (() -> ())?) {
        updateIsDeleted(isDeleted, usingSync: sync, complete: complete)
    }

    func update(dailyMemoriesStartTimestamp: Int64, completion: (() -> Void)?) {
        
    }
    
    func updateLocal(dict: [String: Any], usingSync sync: Bool, complete: (()->())?) {
        if sync {
            // 没有complete 就直接在同步线程处理
            if let name = dict["name"] as? String {
                self.updateName(name, usingSync: true, complete: nil)
            }
            if let endID = dict["end_id"] as? String {
                self.device.uniqueID = endID
            }
            if let groupID = dict["group_id"] as? String {
                self.device.groupID = groupID
            }
            if let addtime = dict["addtime"] as? Int64 {
                self.updateAddtime(addtime, usingSync: true, complete: nil)
            }
            // pid和provider不需要处理
            // let pid = dict["pid"] as? String
            // let provider = dict["provider"] as? String
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                if let name = dict["name"] as? String {
                    self.updateName(name, usingSync: true, complete: nil)
                }
                if let endID = dict["end_id"] as? String {
                    self.device.uniqueID = endID
                }
                if let groupID = dict["group_id"] as? String {
                    self.device.groupID = groupID
                }
                if let addtime = dict["addtime"] as? Int64 {
                    self.updateAddtime(addtime, usingSync: true, complete: nil)
                }
                // pid和provider不需要处理
                // let pid = dict["pid"] as? String
                // let provider = dict["provider"] as? String
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
}
