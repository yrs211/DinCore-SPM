//
//  DinChannelKcpObjectManager.swift
//  DinCore
//
//  Created by Jin on 2021/8/24.
//

import UIKit
import DinSupport

protocol DinChannelKcpObjectManagerDelegate: NSObjectProtocol {
    /// 请求发送Data
    func manager(_ manager: DinChannelKcpObjectManager, requestSendData rawData: Data, withDeliverType type: DinDeviceUDPDeliverType)
    /// 请求注册通道
    func manager(_ manager: DinChannelKcpObjectManager, requestEstabKcp sessionID: UInt16, channelID: UInt16, complete: ((Bool) -> Void)?)
    /// 请求注销通道
    func manager(_ manager: DinChannelKcpObjectManager, requestResignKcp sessionID: UInt16)

    /// 接收到CMD通道数据
    func manager(_ manager: DinChannelKcpObjectManager, receivedCMDData data: Data?, isReset: Bool)
    /// 接收到高清通道数据
    func manager(_ manager: DinChannelKcpObjectManager, receivedHDLiveData data: Data?, isReset: Bool)
    /// 接收到标清通道数据
    func manager(_ manager: DinChannelKcpObjectManager, receivedSTDLiveData data: Data?, isReset: Bool)
    /// 接收到音频通道数据
    func manager(_ manager: DinChannelKcpObjectManager, receivedAudioData data: Data?, isReset: Bool)
    /// 接收到讲话通道数据
    func manager(_ manager: DinChannelKcpObjectManager, receivedTalkData data: Data?, isReset: Bool)
    /// 接收到下载通道数据
    func manager(_ manager: DinChannelKcpObjectManager, receivedFileAt filePath: String, fileName: String, fileType: String, status: DinChannelKcpObjectFileFetchStatus)
}

class DinChannelKcpObjectManager: NSObject {
    weak var delegate: DinChannelKcpObjectManagerDelegate?

    /// kcp所属的通道类型
    let type: DinDeviceUDPDeliverType
    /// kcp的CMD通道需要保活
    let keepliveBlock: (()->())

    var commObjects: [String: DinLiveStreamingKcpObject] = [:]

    var cmdComm: DinLiveStreamingKcpObject?
    var hdComm: DinLiveStreamingKcpObject?
    var stdComm: DinLiveStreamingKcpObject?
    var audioComm: DinLiveStreamingKcpObject?
    var talkComm: DinLiveStreamingKcpObject?
    var downloadComm: DinLiveStreamingKcpObject?

    /// 用于cmd的kcp通道保活
    var cmdKcpTimer: DinGCDTimer?
    /// 建立Kcp使用的线程
    static let kcpCreateQueue = DispatchQueue.init(label: DinQueueName.cameraKcpCreation)

    /// 是否在讲话
    var isTalking = false
    /// 是否在初始化讲话通道
    var isPreparingTalk = false

    /// 是否在初始化下载通道
    var isPreparingDownload = false
    var fileFetcher: DinChannelKcpObjectFileFetcher?

    /// 是否在初始化CMD通道
    var isPreparingKcp = false

    /// 监听Live通道的数据通行情况，如果10s收不到视频数据，重新请求视频数据
    var liveStreamWatchDog: DinGCDTimer?
    /// 观看直播期间，视频流数据最新的到达时间，用于判断断流多久
    var liveDataArriveTime: TimeInterval = 0
    /// 当前的直播申请data，用于重连重新申请
    var lastRequestLiveData: Data? = nil


    deinit {
        stopLiveClock()
        stopLiveSteamWatch()
        NotificationCenter.default.removeObserver(self)
    }

    /// 实例化
    /// - Parameters:
    ///   - type: 管理器类型
    ///   - fileSaveID: 文件传输保存路径使用（唯一文件夹名）
    ///   - keepliveBlock: 心跳回调
    init(withDeliverType type: DinDeviceUDPDeliverType, fileSaveID: String, keepliveBlock: @escaping (()->())) {
        self.type = type
        self.keepliveBlock = keepliveBlock
        super.init()
        // 系统的UDP代理模式通道收到的kcp包
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(receivedServerData(_:)),
                                               name: .dinProxyDeliverKcpDataReceived,
                                               object: nil)
        startLiveClock()
        self.fileFetcher = DinChannelKcpObjectFileFetcher(withSaveID: fileSaveID, delegate: self)
    }

    func startLiveClock() {
        stopLiveClock()
        cmdKcpTimer = DinGCDTimer.init(timerInterval: .seconds(5), isRepeat: true, executeBlock: { [weak self] in
            self?.cmdKeepLive()
            self?.downloadKeepLive()
        })
    }
    func stopLiveClock() {
        cmdKcpTimer = nil
    }

    // 系统的UDP代理模式通道收到的MSCT包
    @objc private func receivedServerData(_ notif: Notification) {
        guard let data = notif.userInfo?[DinSupportNotificationKey.dinKCPDataKey] as? Data else {
            return
        }
        // 检查是否是属于本设备的消息
        let convString = notif.userInfo?[DinSupportNotificationKey.dinKCPIDKey] as? String ?? ""

        DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
            guard let commObject = self?.commObjects[convString] else {
                return
            }
            // 处理消息
            DispatchQueue.global().async {
                commObject.kcpObject.inputData(data)
            }
        }
    }

    func reset() {
        DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
            guard let self = self else { return }
            for commObject in self.commObjects.values {
                commObject.kcpObject.stopReceiving()
            }
            self.cmdComm = nil
            self.hdComm = nil
            self.stdComm = nil
            self.audioComm = nil
            self.talkComm = nil
            self.downloadComm = nil
            self.commObjects.removeAll()
        }
    }
}

// MARK: - 建立KCP
extension DinChannelKcpObjectManager {
    private func createKcpComm(withType type: DinKcpType) -> DinLiveStreamingKcpObject? {
        let commObj = DinLiveStreamingKcpObject(withKcpType: type) { [weak self] outpuData in
            guard let self = self else { return  -1 }
            self.delegate?.manager(self, requestSendData: outpuData, withDeliverType: self.type)
            return 0
        }
        commObj?.kcpObject.delegate = self
        return commObj
    }

    func createHDVideoKcp() {
        guard hdComm == nil else {
            return
        }
        // 高清视频流
        hdComm = createKcpComm(withType: .hd)
        if let kcpComm = hdComm {
            commObjects[kcpComm.convString] = kcpComm
        }
    }

    func createSTDVideoKcp() {
        guard stdComm == nil else {
            return
        }
        // 标清视频流
        stdComm = createKcpComm(withType: .std)
        if let kcpComm = stdComm {
            commObjects[kcpComm.convString] = kcpComm
        }
    }

    func startLiveStreamWatch() {
        stopLiveSteamWatch()
        // 防止 liveDataArriveTime 太久 超过10s，这里重新赋值开始计时
        liveDataArriveTime = Date().timeIntervalSince1970
        liveStreamWatchDog = DinGCDTimer(timerInterval: .seconds(1), isRepeat: true, executeBlock: { [weak self] in
            guard let self = self else { return }
            let nowTime = Int(Date().timeIntervalSince1970)
            let arriveTime = Int(self.liveDataArriveTime)
            if nowTime - arriveTime > 10 {
                var isHD = true
                if self.stdComm != nil {
                    isHD = false
                }
                self.resetLiveComm(withQualityHD: isHD, needSendRST: true)
            }
        }, queue: DinChannelKcpObjectManager.kcpCreateQueue)
    }
    func stopLiveSteamWatch() {
        liveStreamWatchDog = nil
    }
    /// 重置直播通讯通道
    /// - Parameter needSendRST: 是否需要向kcp通道发送rst指令再释放
    func resetLiveComm(withQualityHD isHD: Bool, needSendRST: Bool = false) {
        guard let requestData = self.lastRequestLiveData else {
            return
        }
        if needSendRST {
            // 告诉服务器这个kcp废弃
            self.stdComm?.kcpObject.sendReset()
            self.hdComm?.kcpObject.sendReset()
        }
        // 释放旧kcp
        self.deactiveLive(sync: true)
        // 重新请求直播数据
        self.requestLive(qualityHD: isHD, liveData: requestData)
    }

    func createAudioKcp() {
        guard audioComm == nil else {
            return
        }
        // 收听音频流
        audioComm = createKcpComm(withType: .audio)
        if let kcpComm = audioComm {
            commObjects[kcpComm.convString] = kcpComm
        }
    }

    func createTalkKcp() {
        guard talkComm == nil else {
            return
        }
        // 讲话音频流
        talkComm = createKcpComm(withType: .talk)
        if let kcpComm = talkComm {
            commObjects[kcpComm.convString] = kcpComm
        }
    }

    func createDownloadKcp() {
        guard downloadComm == nil else {
            return
        }
        // 下载sd卡文件
        downloadComm = createKcpComm(withType: .downloadRecord)
        if let kcpComm = downloadComm {
            commObjects[kcpComm.convString] = kcpComm
        }
    }

    func createCMDKcp() {
        guard cmdComm == nil else {
            return
        }
        // 指令
        cmdComm = createKcpComm(withType: .jsonCmd)
        if let kcpComm = cmdComm {
            commObjects[kcpComm.convString] = kcpComm
        }
    }
}
