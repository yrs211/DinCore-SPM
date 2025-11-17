//
//  DinCore.swift
//  DinCore
//
//  Created by Jin on 2021/4/20.
//

import Foundation
import DinSupport
import AlicloudHttpDNS

public struct DinCore {

    public static var userDelegate: DinCoreUserDelegate?

    public static var homeDelegate: DinCoreHomeDelegate?

    public static var cameraDelegate: DinCoreCameraDelegate?

    public static var storageBatteryDelegate: DinCoreStorageBatteryDelegate?

    static var appID: String?
    static var appKey: String?
    static var appSecret: String?
    static var ipcSecret: String?
    /// API 地址
    static var apiDomain: String?
    /// 暂时是Emaldo用到的数据图表服务器地址
    static var statisticsDomain: String?

    /// UDP-KCP网络通讯模块 - 地址 端口
    /// 默认先置空，等待请求服务器获取最新的UDP地址。
    /// 这样做是为了防止在获取目标地址之前，接入默认的地址，而默认地址能提供对应的接口功能，从而IPC等相关设备注册好了对应的KCP和UDP沟通渠道，这个时候再切换到目标地址，就会有设备离线，请求无应答状况，涉及到kcp通讯使用的EndID，secret等等数据
    static var kUdpURL = ""
    static var kUdpPort = UInt16(0)

    /// 打洞功能的前提，获取客户端的公网ip和端口，下面是服务器的Host和端口
    static var getPublicIPHost = ""
    static var getPublicIPPort = UInt16(0)

    /// 加解密工具类
    public static let cryptor = DinsaferRC4Cryptor()

    /// 数据库
    public static let dataBase = DinDataManager(withDataBaseName: "com.dinsafer.dscore.leveldb")

    /// 网络可用性检查
    private(set) static var reachability: DinReachability?

    /// 用户
    public enum UserState {

        /// 已经登录
        case didLogin

        /// 将要退出登录
        /// - 此时还可以访问用户信息
        case willLogout

        /// 已经退出登录
        /// - 此时已不可以访问用户信息
        case didLogout

        /// 用户 token 失效
        case tokenExpired
    }

    public static var user: DinUser? = dataBase.getUser() {
        willSet {
            if newValue == nil {
                DinCore.userDelegate?.dinCoreUserStateDidChange(state: .willLogout)
            }
        }
        didSet {
            if user == nil {
                DinCore.userDelegate?.dinCoreUserStateDidChange(state: .didLogout)
            } else {
                if oldValue == nil {
                    DinCore.userDelegate?.dinCoreUserStateDidChange(state: .didLogin)
                }
            }
            dataBase.saveUser(user)
        }
    }

    /// DoH管理器
    public static let dohManager = DinDoHManager()
    
//    public static var httpDNS: HttpDnsService {
//        HttpDnsService.sharedInstance()
//    }

    // 持有收发功能的通道管理者
    static var proxyDeliver: DinProxyDeliver?

    /// 消息发送器
    public static let eventBus = DinEventBus()

    public static func config(_ config: Config, specifyDomain sDomain: String? = nil) {
        self.appID = config.appID
        self.appKey = config.appKey
        self.appSecret = config.appSecret
        self.ipcSecret = config.ipcSecret
        self.apiDomain = config.apiDomain
        self.statisticsDomain = config.statisticsDomain
        if let specifyDomain = sDomain, !specifyDomain.isEmpty {
            apiDomain = specifyDomain
        }
        DinSupport.config(
            DinSupport.Config(
                appID: config.appID,
                appKey: config.appKey,
                appSecret: config.appSecret,
                udpURL: DinCore.kUdpURL,
                udpPort: DinCore.kUdpPort,
                getPublicIPHost: DinCore.getPublicIPHost,
                getPublicIPPort: DinCore.getPublicIPPort
            )
        )
        // dns
//        let httpdns = HttpDnsService(accountID: 160011, secretKey: DinConstants.httpdnsSecret)
//        httpdns?.setCachedIPEnabled(true)
//        httpdns?.setPreResolveHosts([DinCoreDomain])
        
        // 检测手机网络
        configReachability()
        // 默认不启用
//        DinLogInfoFileTool.uploadFile()
    }

    public struct Config {
        let appID: String
        let appKey: String
        let appSecret: String
        let ipcSecret: String
        // http api domain
        let apiDomain: String
        // emaldo statistics graph domain
        let statisticsDomain:String

        public init(
            appID: String,
            appKey: String,
            appSecret: String,
            ipcSecret: String,
            apiDomain: String,
            statisticsDomain: String
        ) {
            self.appID = appID
            self.appKey = appKey
            self.appSecret = appSecret
            self.ipcSecret = ipcSecret
            self.apiDomain = apiDomain
            self.statisticsDomain = statisticsDomain
        }
    }

    static func updateUDPAddress(withDomain domain: String, port: UInt16, getPublicIPHost: String, getPublicIPPort: UInt16) {
        kUdpURL = domain
        kUdpPort = port
        DinSupport.modifyUDP(url: kUdpURL,
                             port: kUdpPort,
                             getPublicIPHost: getPublicIPHost,
                             getPublicIPPort: getPublicIPPort)
        DinCore.proxyDeliver?.connectToServer()
        DinCore.eventBus.basic.accept(proxyDeliverChanged: true)
    }
}

extension DinCore {
    /// check if user has token
    public static func hasUserToken() -> Bool {
        return DinCore.user?.token.count ?? 0 > 0
    }
    /// check if user has uniqueID
    public static func hasUserUniqueID() -> Bool {
        return DinCore.user?.uniqueID.count ?? 0 > 0
    }
}

extension DinCore {
    public static func startUDPSocket() {
        let serverEncrypter = DinServerEncryptor()
        DinCore.proxyDeliver = DinProxyDeliver(with: DispatchQueue(label: DinQueueName.systemProxyDeliver,
                                                                   attributes: .concurrent),
                                               dataEncryptor: serverEncrypter,
                                               belongsTo: nil,
                                               from: DinGroupCommunicator(withUniqueID: "SERVER", groupID: "SERVER", commSecret: "SERVER"))
        DinCore.proxyDeliver?.connectToServer()
    }

    public static func stopUDPSocket() {
        DinCore.proxyDeliver?.disconnect()
        DinCore.proxyDeliver = nil
        DinCore.eventBus.basic.accept(udpSocketDisconnect: "")
    }
}

extension DinCore {
    /// 检查手机的网络情况
    static func configReachability() {
        // 改成百度降低网络错误报错的几率
        reachability = try? DinReachability(hostname: "baidu.com")
        try? reachability?.startNotifier()
    }
}
