//
//  DinWebsocketControl.swift
//  DinNovaPanel
//
//  Created by Jin on 2021/5/10.
//

import UIKit
import AlicloudHttpDNS
import Starscream
import RxSwift
import RxRelay

protocol DinWebsocketControlDelegate: NSObjectProtocol {
    /// 请求重新向服务器获取panel数据，刷新token重连
    func control(requestPanelRefreshTokenToReconnect control: DinWebsocketControl, complete: @escaping ()->Void)
}

enum DinWebsocketControlConnectState: Int {
    case success = 1
    case fail = -1
    case failWithAccountToken = -3 //user token 错误
    case failWithDeviceToken = -5 //device token 错误
}
struct DinWebsocketControlConnectInfo {
    var isOnline: Bool
    var connectResult: DinWebsocketControlConnectState
}

enum DinNovaPanelWSStatus: Int {
    case disconnect = -1
    case connecting = 0
    case connected = 1
}

public class DinWebsocketControl: NSObject {
    
    private let socketConfigQueue = DispatchQueue(label: "com.dinsafer.socketConfigQueue")
    
    weak var delegate: DinWebsocketControlDelegate?

    private var socket: WebSocket?

    let disposeBag = DisposeBag()

    let panel: DinNovaPanel

    /// 与主机websocket连接状态
    var panelWSConnection: Observable<DinNovaPanelWSStatus> {
        return isWSConnected.asObservable()
    }
    var panelWSConnectionState: DinNovaPanelWSStatus {
        isWSConnected.value
    }
    private var isWSConnected = BehaviorRelay<DinNovaPanelWSStatus>(value: .disconnect)

    /// 记录是否app调用socket disconnect
    var appDisconnect = false
    /// 从websocket收到服务器错误test为 -2 的提示，panel token错误，重新获取panel token的次数
    var socketConnectRetry: Int = 0

    var disconnectSocketByUser = false

    /// 成功收取得到的messageid
    var successList: [String] = []

    // ping pong
    var pingSequence: Observable<Int>?
    var pingDisposeBag: DisposeBag?
    var pingValue: Int = 0
    var pongValue: Int = 0
    var pingRetry: Int = 0

    // MARK: - 设备（主动操作/第三方操作）数据通知
    var panelOperationResponseObservable: Observable<DinNovaPanelSocketResponse> {
        return panelOperationResponse.asObservable()
    }
    private let panelOperationResponse = PublishRelay<DinNovaPanelSocketResponse>()
    /// 设备（主动操作/第三方操作）数据通知
    /// - Parameter result: 结果
    func accept(panelOperationResponse response: DinNovaPanelSocketResponse) {
        panelOperationResponse.accept(response)
    }

    // MARK: - 设备的WS连接结果查询
    var panelConnectInfoObservable: Observable<DinWebsocketControlConnectInfo> {
        return panelConnectInfo.asObservable()
    }
    private let panelConnectInfo = PublishRelay<DinWebsocketControlConnectInfo>()
    /// 设备在线状态通知
    /// - Parameter connectInfo: 是否在线
    func accept(panelConnectInfo connectInfo: DinWebsocketControlConnectInfo) {
        panelConnectInfo.accept(connectInfo)
    }

    // MARK: - 主体
    init(withPanel panel: DinNovaPanel, delegate: DinWebsocketControlDelegate) {
        self.panel = panel
        self.delegate = delegate
        super.init()
        DinCore.eventBus.basic.serverIPCheckedObservable
            .observe(on: MainScheduler.asyncInstance)
            .subscribe { [weak self] (_) in
            // 这里其实就是为了当服务器的IP改变之后（域名没变），http接口会通过httpdns拿到的新域名去请求，这个时候ws的地址也要跟着修改
            // 发生的概率比较低
            // 测试服（DinConstants.useWSS = false）一般不使用这个规则
            guard DinConstants.useWSS else {
                return
            }
            // 这里由阿里的httpdns改为用DoH获取IP
            DinDoHManager().readValidIP(for: DinCoreDomain) { ip in
                if let ip = ip {
                    // 如果是主机离线了，则不用连接
                    if (self?.panel.token ?? "").count > 0,
                       !(self?.socket?.isConnected ?? false),
                       let host = self?.socket?.currentURL.host,
                       host != ip {
                        DinLogInfoFileTool.logToFile(withErrorMsg: "\(Date()) receive serverIPCheckedObservable diff - ip:\(ip), self?.socket?.currentURL.host:\(self?.socket?.currentURL.host)", requestPath: nil, requestParams: nil)
                        self?.configSocket {
                            self?.socket?.connect()
                        }
                    }
                } else {
                    DinLogInfoFileTool.logToFile(withErrorMsg: "\(Date()) receive serverIPCheckedObservable - ip: nil, self?.socket?.currentURL.host:\(self?.socket?.currentURL.host)", requestPath: nil, requestParams: nil)
                    
                }
            }
        }.disposed(by: disposeBag)
    }

    func configSocket(completion: (() -> Void)? = nil) {
        socketConfigQueue.async { [weak self] in
            guard let self = self else { return }

            if DinConstants.useWSS {
                DinDoHManager().readValidIP(for: DinCoreDomain) { [weak self] ip in
                    guard let self = self else { return }

                    let host = ip ?? DinCoreDomain
                    if ip != nil {
                        DinLogInfoFileTool.logToFile(
                            withErrorMsg: "\(Date()) wss configSocket - ip:\(host)",
                            requestPath: nil,
                            requestParams: nil
                        )
                    } else {
                        DinLogInfoFileTool.logToFile(
                            withErrorMsg: "\(Date()) wss configSocket - ip: nil, fallback to \(DinCoreDomain)",
                            requestPath: nil,
                            requestParams: nil
                        )
                    }

                    var request = URLRequest(url: URL(string: "wss://\(host)/device/ws/v2/" + (DinCore.appID ?? ""))!)
                    request.setValue(DinCoreDomain, forHTTPHeaderField: "Host")

                    self.socket = WebSocket(request: request)
                    self.socket?.disableSSLCertValidation = true
                    self.setupSocketCallbacks()

                    DispatchQueue.main.async {
                        completion?()
                    }
                }

            } else {
                let url = URL(string: "ws://\(DinCoreDomain)/device/ws/v2/" + (DinCore.appID ?? ""))!
                self.socket = WebSocket(url: url)
                self.setupSocketCallbacks()

                DispatchQueue.main.async {
                    completion?()
                }
            }
        }
    }
    
    private func setupSocketCallbacks() {
        socket?.onConnect = { [weak self] in
            DispatchQueue.main.async { [weak self] in
                if DinCore.hasUserToken() {
                    self?.sendTokenToServer(withUserToken: DinCore.user?.token ?? "")
                }
            }
        }

        socket?.onDisconnect = { [weak self] (error) in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.pingDisposeBag = nil
                self.pingSequence = nil

                if self.disconnectSocketByUser {
                    self.disconnectSocketByUser = false
                }

                if self.appDisconnect {
                    // 如果这次是app断开的，重置标志
                    self.appDisconnect = false
                } else {
                    // 如果不是App断开的，而是服务器断开的
                    self.accept(panelConnectInfo: DinWebsocketControlConnectInfo(isOnline: false, connectResult: .fail))
                    self.isWSConnected.accept(.disconnect)
                }
            }
        }

        socket?.onText = { [weak self] (text: String) in
            DispatchQueue.main.async { [weak self] in
                switch text {

                case "1": // 连接成功
                    self?.connectSuccess()

                case "-1":
                    self?.connectFailWithAccountToken()

                case "-2": // device token 错误
                    self?.connectFailWithDeviceToken()

                default:
                    self?.handleMessage(withReturnString: text)
                }
            }
        }

        socket?.onPong = { [weak self] (data: Data?) in
            DispatchQueue.main.async { [weak self] in
                self?.pongValue = self?.pingValue ?? 0
            }
        }
    }

    func connect() {
        // 配置socket相关信息
        configSocket { [weak self] in
            self?.socket?.connect()
        }
    }

    func disconnect(initiative: Bool = true) {
        pingDisposeBag = nil
        pingSequence = nil
        appDisconnect = true
        if socket?.isConnected ?? false {
            disconnectSocketByUser = initiative
            socket?.write(string: "")
        }
        socket?.disconnect()
        isWSConnected.accept(.disconnect)
        successList.removeAll()
    }
}

// MARK: - handling message
extension DinWebsocketControl {
    func sendTokenToServer(withUserToken userToken: String) {
        isWSConnected.accept(.connecting)
        let userIDString = "\(userToken)&\(panel.token)_\(Int64(Date().timeIntervalSince1970*1000000000))"
        if let encryptString = DinCore.cryptor.rc4EncryptToHexString(with: userIDString, key: DinCore.appSecret ?? "") {
            socket?.write(string: encryptString)
        }
    }

    /// 通过代理请求外面重新刷新主机数据，然后通知自身重连
    func requestForReconnect() {
        // 断开ws，只是为了重连，这里不能设置成主动断开，否则重连三次的设定会无效
        disconnect(initiative: false)
        // 等待重连
        delegate?.control(requestPanelRefreshTokenToReconnect: self, complete: { [weak self] in
            self?.connect()
        })
    }

    func connectSuccess() {
        socketConnectRetry = 0
        accept(panelConnectInfo: DinWebsocketControlConnectInfo(isOnline: true, connectResult: .success))
        isWSConnected.accept(.connected)
        startSocketPing()
    }

    func connectFailWithAccountToken() {
        accept(panelConnectInfo: DinWebsocketControlConnectInfo(isOnline: false, connectResult: .failWithAccountToken))
        disconnect(initiative: false)
        isWSConnected.accept(.disconnect)
    }

    func connectFailWithDeviceToken() {
        if socketConnectRetry == 3 {
            accept(panelConnectInfo: DinWebsocketControlConnectInfo(isOnline: false, connectResult: .failWithDeviceToken))
            isWSConnected.accept(.disconnect)
            socketConnectRetry = 0
            disconnect(initiative: false)
            return
        }
        socketConnectRetry += 1
        isWSConnected.accept(.connecting)
        requestForReconnect()
    }

    func handleMessage(withReturnString result: String) {
        if isWSConnected.value != .connected {
            isWSConnected.accept(.connected)
        }
        guard result.count > 0, let response = DinNovaPanelSocketResponse.deserialize(from: result) else {
            return
        }

        if response.cmd != DinNovaPanelCommand.setSmartBot.rawValue {
            // 忽略重复的成功结果
            if response.action == DinNovaPanelResponseAction.result.rawValue,
               successList.contains(response.messageID) {
                return
            }
        }

        // result有内容
        if response.result != "" {
            // 解密
            if let encryptData = response.result.dataFromHexadecimalString(),
               let decryptData = DinCore.cryptor.rc4Decrypt(encryptData, key: DinCore.appSecret ?? "") {
                if let uncompressedData = (decryptData as NSData).snappy_decompressed() {
                    response.result = String(data: uncompressedData, encoding: .utf8) ?? ""
                    if response.status == 1 && response.action == DinNovaPanelResponseAction.result.rawValue {
                        successList.append(response.messageID)
                    }
                    accept(panelOperationResponse: response)
                }
            }
        } else {
            // result没内容，直接发送事件
            if response.status == 1 && response.action == DinNovaPanelResponseAction.result.rawValue {
                successList.append(response.messageID)
            }
            accept(panelOperationResponse: response)
        }
    }
}

// MARK: - ping/pong
extension DinWebsocketControl {
    func startSocketPing() {
        pingValue = 0
        pongValue = 0
        pingDisposeBag = DisposeBag()
        pingSequence = Observable<Int>.interval(.seconds(30),
                                                scheduler: SerialDispatchQueueScheduler(internalSerialQueueName: DinNovaPanelQueueName.wsPingQueue))
        socketPingData()
        if let disposeBag = pingDisposeBag {
            pingSequence?.subscribe(onNext: { [weak self] (_) in
                self?.socketPingData()
            }).disposed(by: disposeBag)
        }
    }

    func socketPingData() {
        DispatchQueue.main.async { [weak self] in
            self?.pingValue = self?.pingValue ?? 0 + 1
            self?.socket?.write(ping: Data())
            delay(2) {
                if self?.pingValue != self?.pongValue {
                    if self?.pingRetry == 3 {
                        self?.disconnect()
                        delay(1) {
                            self?.pingRetry = 0
                            self?.connect()
                        }
                    } else {
                        self?.pingRetry = self?.pingRetry ?? 0 + 1
                        self?.socketPingData()
                    }
                }
            }
        }
    }
}
