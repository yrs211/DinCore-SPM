//
//  DinLiveStreamingRequest.swift
//  DinCore
//
//  Created by Jin on 2021/6/15.
//

import Foundation
import Moya

enum DinLiveStreamingRequest {
    /// 通讯登录（App客户端调用）
    case loginDevices(homeID: String, deviceIDs: [String]?, providers: [String])
    /// 通讯登出（App客户端调用）
    case logoutDevices(homeID: String, deviceIDs: [String]?, providers: [String])
    /// 删除自研IPC（App客户端调用）
    case deleteDevice(homeID: String, deviceID: String, provider: String)
    /// 获取自研IPC列表（App客户端调用）
    case getDevices(homeID: String, providers: [String])
    /// 获得自研IPC列表
    case getDevicesByAddtime(addTime:Int64, homeID: String, providers: [String])
    /// 获取自研IPC的EndID（App客户端调用）
    case getDevicesEndid(homeID: String, deviceIDs: [String], providers: [String])
    /// 查询指定 pid 的自研 ipc
    case searchDevices(homeID: String, pids: [[String: Any]])
    /// 重命名自研IPC（App客户端调用）
    case renameDevice(homeID: String, deviceID: String, newName: String, provider: String)
    /// 获取ipc移动侦测服务设置
    case getMotionDetectAlertMode(homeID: String, deviceID: String, provider: String)
    /// 设置ipc移动侦测服务 目前只有这个设置，取值 "critical"/"normal"/"backup"
    case setMotionDetectAlertMode(homeID: String, deviceID: String, alertMode: String, provider: String)

    /// 获取 ipc 服务相关设置
    case getServiceSettings(parameters: GetServiceSettingParameters)
    /// 设置 ipc 服务相关配置
    case updateServiceSettings(parameters: UpdateServiceSettingParameters)
    /// 获取固件版本信息
    case getVersions(providers: [String])
    /// 获取移动侦测记录
    case listMotionRecords(homeID: String, providers: [String], pageSize: Int, addTime: Int64)
    /// 删除移动侦测记录
    case deleteMotionRecords(homeID: String, recordIDs: [String])
    /// 获取视频链接
    case getIPCVideoURL(homeID: String, recordID: String)
    
    /// 获取移动侦测事件列表
    case listMotionDetectEvents(homeID: String, providers: [String], pageSize: Int, addTime: Int64)

    /// 获取指定移动侦测事件的视频总数
    case getMotionDetectEventRecordCount(homeID: String, eventID: String)

    /// 分页获取移动侦测事件视频列表
    case listMotionDetectEventRecords(homeID: String, eventID: String, startIndex: Int, pageSize: Int)

    /// 删除移动侦测事件
    case deleteMotionDetectEvent(homeID: String, eventIDs: [String])
    
    /// 获取 ipc 最新的移动侦测触发时间（页面的 ipc 排序、列表）
    case getLatestTriggerMotionDetectTime(homeID: String, startTime: TimeInterval, endTime: TimeInterval)
    /// 获取指定时间段的移动侦测事件（时间轴上的事件列表）
    case getPeriodMotionDetectEvents(cameraIDs: [String], homeID: String, startTime: TimeInterval, endTime: TimeInterval)
    /// 获取指定移动侦测事件的视频
    case getMotionDetectVideos(eventID: String, eventStartTime: TimeInterval, homeID: String, limit: Int, ipcId: String)
    /// 获取有移动侦测事件触发的日期
    case getMotionDetectEventDates(homeID: String, timezone: String)
    /// 获取指定事件的封面 url
    case getMotionDetectEventCovers(homeID: String, eventIDs: [String])
    /// 获取指定 ipc 最新的移动侦测触发时间
    case getLastTriggeredTimeByCamId(homeID: String, camId: String)
}

extension DinLiveStreamingRequest: DinHttpRequest {
    var requestPath: String {
        baseURL.absoluteString + path
    }

    var requestParam: DinHttpParams? {
        var jsonDict = [String: Any]()
        jsonDict["gmtime"] = Int64(Date().timeIntervalSince1970*1000000000)
        let token = DinCore.user?.userToken ?? ""

        switch self {
        case .loginDevices(let homeID, let deviceIDs, let providers):
            jsonDict["providers"] = providers
            jsonDict["home_id"] = homeID
            if let cids = deviceIDs {
                jsonDict["pids"] = cids
            }
            jsonDict["page_size"] = 100
            jsonDict["addtime"] = 0

        case .logoutDevices(let homeID, let deviceIDs, let providers):
            jsonDict["providers"] = providers
            jsonDict["home_id"] = homeID
            if let cids = deviceIDs {
                jsonDict["pids"] = cids
            }
            jsonDict["page_size"] = 100
            jsonDict["addtime"] = 0

        case .deleteDevice(let homeID, let deviceID, let provider):
            jsonDict["home_id"] = homeID
            jsonDict["pid"] = deviceID
            jsonDict["provider"] = provider

        case .getDevices(let homeID, let providers):
            jsonDict["providers"] = providers
            jsonDict["home_id"] = homeID
            jsonDict["page_size"] = 100
            jsonDict["addtime"] = 0
            
        case .getDevicesByAddtime(let addTime, let homeID, let providers):
            jsonDict["providers"] = providers
            jsonDict["home_id"] = homeID
            jsonDict["page_size"] = 100
            jsonDict["addtime"] = addTime
            jsonDict["order"] = "asc"

        case .getDevicesEndid(let homeID, let deviceIDs, let providers):
            jsonDict["providers"] = providers
            jsonDict["home_id"] = homeID
            jsonDict["page_size"] = 100
            jsonDict["pids"] = deviceIDs
            jsonDict["addtime"] = 0
            
        case .searchDevices(let homeID, let pids):
            jsonDict["home_id"] = homeID
            jsonDict["pids"] = pids

        case .renameDevice(let homeID, let deviceID, let name, let provider):
            jsonDict["home_id"] = homeID
            jsonDict["pid"] = deviceID
            jsonDict["name"] = name
            jsonDict["provider"] = provider

        case .getMotionDetectAlertMode(let homeID, let deviceID, let provider):
            jsonDict["home_id"] = homeID
            jsonDict["pid"] = deviceID
            jsonDict["provider"] = provider

        case .setMotionDetectAlertMode(let homeID, let deviceID, let alertMode, let provider):
            jsonDict["home_id"] = homeID
            jsonDict["pid"] = deviceID
            jsonDict["provider"] = provider
            jsonDict["alert_mode"] = alertMode

        case .getServiceSettings(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["pid"] = parameters.deviceID
            jsonDict["provider"] = parameters.provider

        case .updateServiceSettings(let parameters):
            jsonDict["home_id"] = parameters.homeID
            jsonDict["pid"] = parameters.deviceID
            jsonDict["provider"] = parameters.provider
            jsonDict["alert_mode"] = parameters.alertMode
            jsonDict["cloud_storage"] = parameters.isCloudStorageEnabled
            jsonDict["arm"] = parameters.arm
            jsonDict["disarm"] = parameters.disarm
            jsonDict["home_arm"] = parameters.homeArm
            jsonDict["sos"] = parameters.sos

        case .getVersions(let providers):
            jsonDict["providers"] = providers
            
        case .listMotionRecords(let homeID, let providers, let pageSize, let addTime):
            jsonDict["home_id"] = homeID
            jsonDict["providers"] = providers
            jsonDict["page_size"] = pageSize
            jsonDict["addtime"] = addTime

        case .deleteMotionRecords(let homeID, let recordIDs):
            jsonDict["home_id"] = homeID
            jsonDict["record_ids"] = recordIDs

        case .getIPCVideoURL(let homeID , let recordID):
            jsonDict["home_id"] = homeID
            jsonDict["record_id"] = recordID
            
        case .listMotionDetectEvents(let homeID, let providers, let pageSize, let addTime):
            jsonDict["home_id"] = homeID
            jsonDict["providers"] = providers
            jsonDict["page_size"] = pageSize
            jsonDict["addtime"] = addTime

        case .getMotionDetectEventRecordCount(let homeID, let eventID):
            jsonDict["home_id"] = homeID
            jsonDict["event_id"] = eventID

        case .listMotionDetectEventRecords(let homeID, let eventID, let startIndex, let pageSize):
            jsonDict["home_id"] = homeID
            jsonDict["event_id"] = eventID
            jsonDict["start_index"] = startIndex
            jsonDict["page_size"] = pageSize

        case .deleteMotionDetectEvent(let homeID, let eventIDs):
            jsonDict["home_id"] = homeID
            jsonDict["event_ids"] = eventIDs
            
        case .getLatestTriggerMotionDetectTime(let homeID, let startTime, let endTime):
            jsonDict["end_time"] = endTime
            jsonDict["start_time"] = startTime
            jsonDict["home_id"] = homeID
        case .getPeriodMotionDetectEvents(let cameraIDs, let homeID, let startTime, let endTime):
            jsonDict["end_time"] = endTime
            jsonDict["home_id"] = homeID
            jsonDict["ipc_ids"] = cameraIDs
            jsonDict["start_time"] = startTime
        case .getMotionDetectVideos(let eventID, let eventStartTime, let homeID, let limit, let ipcId):
            jsonDict["event_id"] = eventID
            jsonDict["event_start_time"] = eventStartTime
            jsonDict["home_id"] = homeID
            jsonDict["limit"] = limit
            jsonDict["ipc_id"] = ipcId
        case .getMotionDetectEventDates(let homeID, let timezone):
            jsonDict["home_id"] = homeID
            jsonDict["timezone"] = timezone
        case .getMotionDetectEventCovers(let homeID, let eventIDs):
            jsonDict["home_id"] = homeID
            jsonDict["event_ids"] = eventIDs
        case .getLastTriggeredTimeByCamId(let homeID, let camId):
            jsonDict["home_id"] = homeID
            jsonDict["ipc_id"] = camId
        }

        let encryptSecret = DinCore.appSecret ?? ""
        return DinHttpParams(with: ["gm": 1, "token": token],
                             dataParams: jsonDict,
                             encryptSecret: encryptSecret)
    }

    public var baseURL: URL {
        return DinApi.getURL()
    }

    public var path: String {
        var requestPath = "/ipc/"

        switch self {
        case .loginDevices:
            requestPath += "e2e-user-login/"
        case .logoutDevices:
            requestPath += "e2e-user-logout/"
        case .deleteDevice:
            requestPath += "del-ipc/"
        case .getDevices:
            requestPath += "list-ipc/"
        case .getDevicesByAddtime:
            requestPath += "list-ipc/"
        case .getDevicesEndid:
            requestPath += "list-ipc/"
        case .searchDevices:
            requestPath += "search-ipc/"
        case .renameDevice:
            requestPath += "rename-ipc/"
        case .getMotionDetectAlertMode, .getServiceSettings:
            requestPath += "get-ipc-service-settings/"
        case .setMotionDetectAlertMode, .updateServiceSettings:
            requestPath += "update-ipc-service-settings/"
        case .getVersions:
            requestPath += "get-ipc-version-datas/"
        case .listMotionRecords:
            requestPath += "md/list-motion-records/"
        case .deleteMotionRecords:
            requestPath += "md/delete-motion-records/"
        case .getIPCVideoURL:
            requestPath += "md/get-ipc-video-url/"
        case .listMotionDetectEvents:
            requestPath += "md/get-event-list/"
        case .getMotionDetectEventRecordCount:
            requestPath += "md/get-total-motion-records/"
        case .listMotionDetectEventRecords:
            requestPath += "md/list-event-motion-records/"
        case .deleteMotionDetectEvent:
            requestPath += "md/delete-event-motion-records/"
        case .getLatestTriggerMotionDetectTime:
            requestPath += "md/get-last-triggered-time/"
        case .getPeriodMotionDetectEvents:
            requestPath += "md/get-events/"
        case .getMotionDetectVideos:
            requestPath += "md/get-event-videos/"
        case .getMotionDetectEventDates:
            requestPath += "md/get-event-dates/"
        case .getMotionDetectEventCovers:
            requestPath += "md/get-event-covers/"
        case .getLastTriggeredTimeByCamId:
            requestPath += "md/get-last-triggered-time-by-ipc-id/"
        }

        return requestPath + (DinCore.appID ?? "")
    }

    public var method: Moya.Method {
        return .post
    }

    public var parameters: [String : Any]? {
        requestParam?.uploadDict
    }

    public var task: Moya.Task {
        if parameters != nil {
            return .requestParameters(parameters: parameters!, encoding: URLEncoding.default)
        } else {
            return .requestPlain
        }
    }

    public var validate: Bool {
        return true
    }

    public var sampleData: Data {
        return "Half measures are as bad as nothing at all.".data(using: .utf8)!
    }

    public var headers: [String: String]? {
        return ["Host": DinCoreDomain, "X-Online-Host": DinCoreDomain]
    }
}
