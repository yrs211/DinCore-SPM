//
//  DinLiveStreaming.swift
//  DinCore
//
//  Created by Monsoir on 2021/11/17.
//

import Foundation
import DinSupport
import HandyJSON

public class DinLiveStreaming: DinModel, DinCommunicationDevice {
    class var categoryID: String { "" }

    class var provider: String { "" }

    /// 设备id
    var id: String = ""
    /// 名字
    var name: String = ""
    /// 摄像头用于通讯的id
    public var uniqueID: String = ""
    /// 临时获取的与IPC通讯的id，当userID存在，同时ipc的uniqueID存在，才判定为可通讯（在线）
    var userID: String = ""
    /// ipc所在的通讯组ID
    public var groupID: String = ""
    /// true:高清, false:标清
    var isHD: Bool = false
    /// 垂直翻转
    var verticalFlip: Bool = false
    /// 水平翻转
    var horizontalFlip: Bool = false
    /// 时区
    var timezone: String = ""
    /// 当前的无线网络
    var ssid: String = ""
    /// 局域网IP
    var ip: String = ""
    /// 电池百分比（如果没有获取到，默认-1）
    var battery: Int = -1
    /// 是否充电
    var charging: Bool = false
    /// TF卡容量 KB
    var tfCapacity: Int = 0
    /// TF已使用 KB
    var tfUsed: Int = 0
    /// 移动侦测开关
    var motionDetect: Bool = false
    /// 移动侦测等级， 1:低 pir唤醒就录像 2:中 pir唤醒,ipc检测到画面变化才录像 3:高 pir唤醒,ipc检测到人才录像
    var motionDetectLevel: Int = 1
    /// 移动侦测报警
    var mdAlarm: Bool = false
    /// PIR等级， 1:低  2:中  3:高
    var pirLevel: Int = 1
    /// 芯片标识
    var chip: String = ""
    /// 固件版本 3518/3861/ble
    var version: String = ""
    /// 固件版本
    var versions: [[String: String]] = []
    /// 添加时间，界面排序用
    var addtime: Int64 = 0
    /// 是否在线 -1.离线, 0.连接中, 1.在线
    /// cam的在线条件比较苛刻，需要联通了ipc的kcp才能确认在线 默认离线
    var networkState: NetworkState = .offline
    /// 移动侦测开始时间
    var mdStartTime: String = "00:00"
    /// 移动侦测结束时间
    var mdEndTime: String = "00:00"
    /// 移动侦测服务设置 目前只有这个设置，取值 "critical"/"normal"/"backup"
    var alertMode: String = "backup"
    /// mac地址
    var mac: String = ""
    /// wifi的信号量
    var rssi: Int = 0
    /// 灰度
    var gray: Bool = false

    /// 自动泛光灯
    var autoFloodlight = false

    /// 服务设置
    var serviceSettings: [String: Any] = [:]

    /// 0 为关闭，其它值为开启
    var dailyMemoriesStartTimestamp: Int64 = 0

    /// 是否开启计划录像
    var scheduledRecordEnabled: Bool = false

    /// 计划录像的计划
    var recordSchedule: RecordSchedule = RecordSchedule(repeating: 0, count: 7)

    /// 局域网的ip
    public var lanAddress: String = ""
    /// 局域网的端口
    public var lanPort: UInt16 = 0

    /// p2p的ip
    public var p2pAddress: String = ""
    /// p2p的端口
    public var p2pPort: UInt16 = 0
    /// 移动侦测功能是根据时间还是跟随主机状态
    public var mdShouldFollowPanel: Bool = false
    /// 移动侦测功能跟随的主机状态
    public var followStatus: [String] = []
    
    public var isDeleted: Bool = false

    public init(withGroupID groupID: String, cameraID: String) {
        super.init()
        self.groupID = groupID
        self.id = cameraID
    }

    public required init() {
        //
    }

    public var deviceID: String {
        self.id
    }

    public var token: String {
        ""
    }

    public var area: String {
        ""
    }

    public override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)

        mapper <<< self.id <-- "pid"
        mapper <<< self.groupID <-- "group_id"
        mapper <<< self.uniqueID <-- "end_id"
    }
}

extension DinLiveStreaming {
    enum NetworkState: Int {
        case offline = -1
        case connecting = 0
        case online = 1
    }

    typealias RecordDaySchedule = Int32
    typealias RecordSchedule = [RecordDaySchedule]
}

extension DinLiveStreaming {
    static func transformIPCProviderToAccessoryManageID(_ provider: String) -> String {
        switch provider {
        case DinCameraV006.provider:
            return DinCameraV006.categoryID
        case DinCameraV015.provider:
            return DinCameraV015.categoryID
        default:
            return DinCamera.categoryID
        }
    }
}
