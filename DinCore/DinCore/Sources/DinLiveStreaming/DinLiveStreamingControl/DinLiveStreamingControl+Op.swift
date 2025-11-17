//
//  DinLiveStreamingControl+Op.swift
//  DinCore
//
//  Created by Jin on 2021/6/10.
//

import Foundation
import DinSupport

extension DinLiveStreamingControl {
    // 连接设备
    static let CMD_CONNECT = "connect"
    // 连接设备
    static let CMD_DISCONNECT = "disconnect"
    // 直播申请
    static let CMD_REQUESTLIVE = "request_live"
    // 直播音频申请
    static let CMD_REQUESTLIVE_AUDIO = "request_live_audio"
    // 发送语音数据
    static let CMD_SEND_AUDIO = "send_audio"
    // 发送语音数据通道异常
    static let CMD_SEND_AUDIOFAIL = "send_audio_fail"
    // 获取设置参数
    static let CMD_GET_PARAMS = "get_params"
    // 设置时区
    static let CMD_SET_TIMEZONE = "set_tz"
    // 设置移动侦测开关（就是PIR的开关）
    static let CMD_SET_MOTIONDETECT = "set_md"
    // 设置移动侦测等级
    static let CMD_SET_MOTIONDETECT_LEVEL = "set_md_level"
    // 设置移动侦测报警
    static let CMD_SET_MOTIONDETECT_ALARM = "set_md_alarm"
    // 设置设置PIR等级（距离）
    static let CMD_SET_PIR_LEVEL = "set_pir_level"
    // 设置垂直翻转
    static let CMD_SET_VFLIP = "set_vflip"
    // 设置水平翻转
    static let CMD_SET_HFLIP = "set_hflip"
    // 格式化TF卡
    static let CMD_FORMAT_TF = "format_tf"
    // 恢复默认设置
    static let CMD_RESTORE = "restore_default"
    // 重置设备
    static let CMD_RESET = "reset"
    // 通知ipc可以直接重置了
    static let CMD_REBOOT = "reboot"
    // 重命名设备
    static let CMD_SET_NAME = "set_name"
    // 设置移动侦测生效时间
    static let CMD_SET_MDTIME = "set_md_time"
    // 获取ipc移动侦测服务设置
    static let CMD_GET_ALERTMODE = "get_alert_mode"
    // 设置ipc移动侦测服务
    static let CMD_SET_ALERTMODE = "set_alert_mode"
    // 获取截图
    static let CMD_GET_PIC = "get_snapshot"
    // 关闭截图功能
    static let CMD_CLOSE_SNAPSHOT = "close_snapshot"
    // 关闭命令功能
    static let CMD_CLOSE_CMD = "close_setting"
    // 设置灰色/彩色显示（低光照情况下）
    static let CMD_SET_GRAY = "set_gray"
    // 升级
    static let CMD_UPGRADE = "upgrade"
    // 获取SD卡里面的视频列表 1.1.5版本之后
    static let CMD_RECORDLIST_V2 = "get_record_list_v2"
    // 获取SD卡里面的视频列表
    static let CMD_RECORDLIST = "get_record_list"
    // 获取TF卡的录像视频或者图片
    // 此方法会同时检测有没有打开获取TF卡的功能开启，如果没有，则开启，开启后需要调用者手动关闭
    static let CMD_RECORDFILE = "get_record_file"
    // 删除TF卡的录像视频或者图片
    static let CMD_DEL_RECORDFILE = "del_record_file"
    // 关闭获取TF卡文件的功能
    static let CMD_STOP_RECORDFILE = "stop_record_file_fetch"
    // IPC 版本号更新
    static let CMD_IPC_VERISON_UPGRADED = "ipc-ver-num-updated"

    static let CMD_GET_SERVICE_SETTINGS = "get_service_settings"
    static let CMD_UPDATE_SERVICE_SETTINGS = "update_service_settings"

    /// 设置照明灯
    static let CMD_SET_FLOOD_LIGHT = "set_floodlight"

    /// 设置自动照明灯
    static let CMD_SET_AUTO_FLOOD_LIGHT = "set_auto_floodlight"
    /// 设置移动侦测跟随主机状态
    static let CMD_SET_MOTION_DETECT_FOLLOW = "set_md_follow"

    /// 设置每日回忆
    static let CMD_SET_DAILY_MEMORIES = "set_daily_memories"

    /// 设置计划录像
    static let CMD_SET_RECORD_SCHEDULE = "set_scheduled"
}

// MARK: - 基本操作
extension DinLiveStreamingControl {
//    /// 基本的设备cmd操作（arm/disarm/homearm/sos etc.）
//    ///
//    /// - Parameters:
//    ///   - payloadDic: 需要传递的payload字典
//    ///   - messageID: 操作的唯一标识
//    ///   - resultCallback: 回调实例
//    func operateCMD(_ payloadDic: [String: Any], messageID: String, ackCallback: DinCommunicationCallback?, resultCallback: DinCommunicationCallback?, resultTimeoutSec: TimeInterval = 0) {
//        let params = DinOperateTaskParams(with: dataEncryptor,
//                                          source: communicationIdentity,
//                                          destination: communicationDevice,
//                                          messageID: messageID,
//                                          sendInfo: payloadDic)
//        _ = DinCommunicationGenerator.operateTask(params,
//                                                 ackCallback: ackCallback,
//                                                 resultCallback: resultCallback,
//                                                 entryCommunicator: communicator)
//    }

    /// 建立kcp通道
    /// - Parameter complete: 是否成功
    public func establishKcpConnection(withKcpSessionID sessionID: UInt16,
                                       channelID: UInt16,
                                       complete: ((Bool) -> Void)?) {
        guard group != nil else {
            complete?(false)
            return
        }
        group?.establishKcpCommunication(withKcpSessionID: sessionID, channelID: channelID, kcpTowardsID: device.uniqueID) { [weak self] _ in
            complete?(true)
        } fail: { [weak self] _ in
            complete?(false)
        } timeout: { [weak self] _ in
            complete?(false)
        }
    }

    /// 关闭kcp通道
    /// - Parameter complete: 是否成功
    public func resignKcpConnection(withKcpSessionID sessionID: UInt16) {
        group?.resignKcpCommunication(withKcpSessionID: sessionID, success: nil, fail: nil, timeout: nil)
    }

//    /// 唤醒IPC
//    /// - Parameter complete: 是否成功
//    public func wakeIPC(complete: ((Bool) -> Void)?) {
//        guard group != nil, communicateControl != nil else {
//            complete?(false)
//            return
//        }
//        group?.wake(withTargetID: communicateControl?.communicationDevice.uniqueID ?? "") { [weak self] _ in
//            complete?(true)
//        } fail: { [weak self] _ in
//            complete?(false)
//        } timeout: { [weak self] _ in
//            complete?(false)
//        }
//    }
}

// MARK: - 更新IPC信息
extension DinLiveStreamingControl {
    func updateInfoDict(complete: (()->())?) {
        DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.updateName(self.device.name, usingSync: true, complete: nil)
            self.updateNetworkState(self.device.networkState, usingSync: true, complete: nil)
            self.updateHD(self.device.isHD, usingSync: true, complete: nil)
            self.updateVFlip(self.device.verticalFlip, usingSync: true, complete: nil)
            self.updateHFlip(self.device.horizontalFlip, usingSync: true, complete: nil)
            self.updateTimezone(self.device.timezone, usingSync: true, complete: nil)
            self.updateSSID(self.device.ssid, usingSync: true, complete: nil)
            self.updateIP(self.device.ip, usingSync: true, complete: nil)
            self.updateBattery(self.device.battery, usingSync: true, complete: nil)
            self.updateCharging(self.device.charging, usingSync: true, complete: nil)
            self.updateTFCapacity(self.device.tfCapacity, usingSync: true, complete: nil)
            self.updateTFUsed(self.device.tfUsed, usingSync: true, complete: nil)
            self.updateMotionDetect(self.device.motionDetect, usingSync: true, complete: nil)
            self.updateMotionDetectLevel(self.device.motionDetectLevel, usingSync: true, complete: nil)
            self.updateMDAlarm(self.device.mdAlarm, usingSync: true, complete: nil)
            self.updateMDStartTime(self.device.mdStartTime, usingSync: true, complete: nil)
            self.updateMDEndTime(self.device.mdEndTime, usingSync: true, complete: nil)
            self.updateMDShouldFollowPanel(self.device.mdShouldFollowPanel, usingSync: true, complete: nil)
            self.updateMDFollowStatus(self.device.followStatus, usingSync: true, complete: nil)
            self.updateVersion(self.device.version, usingSync: true, complete: nil)
            self.updateVersions(self.device.versions, usingSync: true, complete: nil)
            self.updateMac(self.device.mac, usingSync: true, complete: nil)
            self.updateRSSI(self.device.rssi, usingSync: true, complete: nil)
            self.updateGray(self.device.gray, usingSync: true, complete: nil)
            self.updateChip(self.device.chip, usingSync: true, complete: nil)
            self.updateAutoFloodlight(self.device.autoFloodlight, usingSync: true, complete: nil)
            self.updateAddtime(self.device.addtime, usingSync: true, complete: nil)
            self.updateIsDeleted(self.device.isDeleted, usingSync: true, complete: nil)
            self.update(dailyMemoriesStartTimestamp: self.device.dailyMemoriesStartTimestamp, usingSync: true, complete: nil)
            self.updateRecordSchedule(enabled: self.device.scheduledRecordEnabled, schedule: self.device.recordSchedule, usingSync: true, complete: nil)

            DispatchQueue.global().async {
                complete?()
            }
        }
    }

    func updateName(_ name: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.name = name
            unsafeInfo["name"] = name
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.name = name
                self.unsafeInfo["name"] = name
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateAddtime(_ addtime: Int64, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.addtime = addtime
            unsafeInfo["addtime"] = addtime
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.addtime = addtime
                self.unsafeInfo["addtime"] = addtime
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateNetworkState(_ state: DinLiveStreaming.NetworkState, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.networkState = state
            unsafeInfo["networkState"] = state.rawValue
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.networkState = state
                self.unsafeInfo["networkState"] = state.rawValue
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateHD(_ isHD: Bool, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.isHD = isHD
            unsafeInfo["hd"] = isHD
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.isHD = isHD
                self.unsafeInfo["hd"] = isHD
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateVFlip(_ verticalFlip: Bool, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.verticalFlip = verticalFlip
            unsafeInfo["vflip"] = verticalFlip
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.verticalFlip = verticalFlip
                self.unsafeInfo["vflip"] = verticalFlip
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateHFlip(_ horizontalFlip: Bool, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.horizontalFlip = horizontalFlip
            unsafeInfo["hflip"] = horizontalFlip
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.horizontalFlip = horizontalFlip
                self.unsafeInfo["hflip"] = horizontalFlip
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateTimezone(_ timezone: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.timezone = timezone
            unsafeInfo["tz"] = timezone
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.timezone = timezone
                self.unsafeInfo["tz"] = timezone
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateSSID(_ ssid: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.ssid = ssid
            unsafeInfo["ssid"] = ssid
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.ssid = ssid
                self.unsafeInfo["ssid"] = ssid
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateIP(_ ip: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.lanAddress = ip
            device.ip = ip
            unsafeInfo["ip"] = ip
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.lanAddress = ip
                self.device.ip = ip
                self.unsafeInfo["ip"] = ip
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateBattery(_ battery: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.battery = battery
            unsafeInfo["battery"] = battery
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.battery = battery
                self.unsafeInfo["battery"] = battery
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateCharging(_ charging: Bool, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.charging = charging
            unsafeInfo["charging"] = charging
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.charging = charging
                self.unsafeInfo["charging"] = charging
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateTFCapacity(_ tfCapacity: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.tfCapacity = tfCapacity
            unsafeInfo["tfCapacity"] = tfCapacity
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.tfCapacity = tfCapacity
                self.unsafeInfo["tfCapacity"] = tfCapacity
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateTFUsed(_ tfUsed: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.tfUsed = tfUsed
            unsafeInfo["tfUsed"] = tfUsed
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.tfUsed = tfUsed
                self.unsafeInfo["tfUsed"] = tfUsed
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateMotionDetect(_ motionDetect: Bool, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.motionDetect = motionDetect
            unsafeInfo["md"] = motionDetect
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.motionDetect = motionDetect
                self.unsafeInfo["md"] = motionDetect
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateMotionDetectLevel(_ motionDetectLevel: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.motionDetectLevel = motionDetectLevel
            unsafeInfo["mdLevel"] = motionDetectLevel
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.motionDetectLevel = motionDetectLevel
                self.unsafeInfo["mdLevel"] = motionDetectLevel
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateMDAlarm(_ mdAlarm: Bool, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.mdAlarm = mdAlarm
            unsafeInfo["md_alarm"] = mdAlarm
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.mdAlarm = mdAlarm
                self.unsafeInfo["md_alarm"] = mdAlarm
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updatePIRLevel(_ pirLevel: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.pirLevel = pirLevel
            unsafeInfo["pirLevel"] = pirLevel
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.pirLevel = pirLevel
                self.unsafeInfo["pirLevel"] = pirLevel
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateMDStartTime(_ mdStartTime: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.mdStartTime = mdStartTime
            unsafeInfo["mdBeginTime"] = mdStartTime
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.mdStartTime = mdStartTime
                self.unsafeInfo["mdBeginTime"] = mdStartTime
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateMDEndTime(_ mdEndTime: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.mdEndTime = mdEndTime
            unsafeInfo["mdEndTime"] = mdEndTime
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.mdEndTime = mdEndTime
                self.unsafeInfo["mdEndTime"] = mdEndTime
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateMDShouldFollowPanel(_ mdShouldFollowPanel: Bool, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.mdShouldFollowPanel = mdShouldFollowPanel
            unsafeInfo["panel_follow"] = mdShouldFollowPanel
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.mdShouldFollowPanel = mdShouldFollowPanel
                self.unsafeInfo["panel_follow"] = mdShouldFollowPanel
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateMDFollowStatus(_ followStatus: [String], usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.followStatus = followStatus
            unsafeInfo["follow_status"] = followStatus
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.followStatus = followStatus
                self.unsafeInfo["follow_status"] = followStatus
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateVersion(_ version: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.version = version
            unsafeInfo["version"] = version
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.version = version
                self.unsafeInfo["version"] = version
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateVersions(_ versions: [[String: String]], usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.versions = versions
            unsafeInfo["versions"] = versions
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.versions = versions
                self.unsafeInfo["versions"] = versions
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateAlertMode(_ alertMode: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.alertMode = alertMode
            unsafeInfo["alertMode"] = alertMode
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.alertMode = alertMode
                self.unsafeInfo["alertMode"] = alertMode
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateMac(_ mac: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.mac = mac
            unsafeInfo["mac"] = mac
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.mac = mac
                self.unsafeInfo["mac"] = mac
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateRSSI(_ rssi: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.rssi = rssi
            unsafeInfo["rssi"] = rssi
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.rssi = rssi
                self.unsafeInfo["rssi"] = rssi
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateGray(_ gray: Bool, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.gray = gray
            unsafeInfo["gray"] = gray
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.gray = gray
                self.unsafeInfo["gray"] = gray
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateChip(_ chip: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.chip = chip
            unsafeInfo["chip"] = chip
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.chip = chip
                self.unsafeInfo["chip"] = chip
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateServiceSettings(_ serviceSettings: [String: Any], usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.serviceSettings = serviceSettings
            unsafeInfo["service-settings"] = serviceSettings
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.serviceSettings = serviceSettings
                self.unsafeInfo["service-settings"] = serviceSettings
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateAutoFloodlight(_ autoFloodlight: Bool, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.autoFloodlight = autoFloodlight
            unsafeInfo["auto_floodlight"] = autoFloodlight
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.autoFloodlight = autoFloodlight
                self.unsafeInfo["auto_floodlight"] = autoFloodlight
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateIsDeleted(_ isDeleted: Bool, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            device.isDeleted = isDeleted
            unsafeInfo["isDeleted"] = isDeleted
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.isDeleted = isDeleted
                self.unsafeInfo["isDeleted"] = isDeleted
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func update(dailyMemoriesStartTimestamp timestamp: Int64, usingSync sync: Bool, complete: (() -> Void)?) {
        if sync {
            device.dailyMemoriesStartTimestamp = timestamp
            unsafeInfo["dailyMemories"] = timestamp
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.device.dailyMemoriesStartTimestamp = timestamp
                self.unsafeInfo["dailyMemories"] = timestamp
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateRecordSchedule(
        enabled: Bool? = nil,
        schedule: DinLiveStreaming.RecordSchedule? = nil,
        usingSync sync: Bool,
        complete: (() -> Void)?
    ) {
        if sync {
            if let value = enabled {
                device.scheduledRecordEnabled = value
                unsafeInfo["scheduled"] = value
            }

            if let value = schedule {
                device.recordSchedule = value
                unsafeInfo["scheduledTime"] = value
            }
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                if let value = enabled {
                    self.device.scheduledRecordEnabled = value
                    self.unsafeInfo["scheduled"] = value
                }

                if let value = schedule {
                    self.device.recordSchedule = value
                    self.unsafeInfo["scheduledTime"] = value
                }
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
}
