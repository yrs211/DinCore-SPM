//
//  DinNovaPanelControl.swift
//  DinNovaPanel
//
//  Created by Jin on 2021/5/10.
//

import UIKit
import RxSwift
import RxRelay
import DinSupport

public class DinNovaPanelControl: NSObject {
    /// 主机
    let panel: DinNovaPanel
    /// 家庭ID
    let homeID: String
    /// 操作超时检查
    var operationTimeoutChecker = DinNovaPanelEventHandler()
    /// 用于缓存主机操作需要的信息
    var operationInfoHolder = DinNovaPanelOperationInfoHolder()
    /// 用于缓存主机操作需要的信息
    var lanCommunicator: DinNovaPanelLANUtil?
    /// 用于触发配对的通讯器
    var learnModeCommunicator: DinLearnModeWebSocketControl?
    /// 用于接收主机信息返回的websocket控制器
    private var websocketControl: DinWebsocketControl?

    /// Control info sync queue
    /// 在多线程读写的情况下，Info属性会有数据竞争的问题
    var unsafeInfo: [String: Any] = [:]
    var info: [String: Any] {
        var tempInfo: [String: Any] = [:]
        DinUser.homeDeviceInfoQueue.sync { [weak self] in
            if let self = self {
                tempInfo = self.unsafeInfo
            }
        }
        return tempInfo
    }

    /// 主机收到数据后，处理成字典模型返回
    var panelOperationResultObservable: Observable<[String: Any]> {
        return panelOperationResult.asObservable()
    }
    private let panelOperationResult = PublishRelay<[String: Any]>()
    /// 主机收到数据后，处理成字典模型返回
    /// - Parameter info: 结果
    func accept(panelOperationResult info: [String: Any]) {
        panelOperationResult.accept(info)
    }

    let disposeBag = DisposeBag()

    /// 与主机websocket连接状态Observable
    var panelWSConnection: Observable<DinNovaPanelWSStatus>? {
        websocketControl?.panelWSConnection
    }
    /// 设备的WS连接结果查询
    var panelWSConnectResult: Observable<DinWebsocketControlConnectInfo>? {
        websocketControl?.panelConnectInfoObservable
    }
    /// 与主机websocket连接状态
    var panelWSConnectionState: DinNovaPanelWSStatus {
        websocketControl?.panelWSConnectionState ?? .disconnect
    }
    /// 设备（主动操作/第三方操作）websocket 数据通知
    var panelWSResultObservable: Observable<DinNovaPanelSocketResponse>? {
        return websocketControl?.panelOperationResponseObservable
    }
    /// 触发配对结果
    var learnModeResultObservable: Observable<[String: Any]>? {
        return learnModeCommunicator?.learnModeResultObservable
    }

    public init(withPanel novaPanel: DinNovaPanel, homeID: String) {
        self.panel = novaPanel
        self.homeID = homeID
        super.init()
        self.websocketControl = DinWebsocketControl(withPanel: self.panel, delegate: self)
        self.learnModeCommunicator = DinLearnModeWebSocketControl()
        self.lanCommunicator = DinNovaPanelLANUtil(withPanelControl: self)
        self.lanCommunicator?.checkAvailable(withLanIP: panel.lanIP)
        /// 运行检查器
        operationTimeoutChecker.start()

        registerResponseObservers()
    }

    public func connect() {
        websocketControl?.connect()
    }

    public func disconnect() {
        websocketControl?.disconnect()
    }

    func accept(coapResponse response: DinNovaPanelSocketResponse) {
        // 扔进去websocket走对应流程
        // 同一地方处理结果
        websocketControl?.accept(panelOperationResponse: response)
    }

    func setOffline(usingSync sync: Bool, complete: (()->())?) {
        let returnDict = makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_OFFLINE,
                                               owner: false,
                                               result: ["online": false])
        if sync {
            updateIsOnline(false, usingSync: true, complete: nil)
            DispatchQueue.global().async { [weak self] in
                self?.accept(panelOperationResult: returnDict)
            }
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.updateIsOnline(false, usingSync: true, complete: nil)
                DispatchQueue.global().async { [weak self] in
                    complete?()
                    self?.accept(panelOperationResult: returnDict)
                }
            }
        }
    }
}

extension DinNovaPanelControl: DinWebsocketControlDelegate { 
    func control(requestPanelRefreshTokenToReconnect control: DinWebsocketControl, complete: @escaping () -> Void) {
        DinNovaPanelManager.getDevice(withIDs: [panel.id], homeID: homeID) { [weak self] (result) in
            if var newPanel = result {
                DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                    guard let self = self else { return }
                    self.panel.refresh(withPanel: newPanel)
                    self.panel.online = true
                    self.updatePanelInfo {
                        DispatchQueue.main.async { [weak self] in
                            self?.notifyPanelRenewed()
                            complete()
                        }
                    }
                }
            } else {
                complete()
            }
        }
    }
}

// MARK: - 对主机配件数量做更新缓存
extension DinNovaPanelControl {
    /// 对主机配件数量做更新缓存（格外注意！！！这个方法调用需要在 DinUser.homeDeviceInfoQueue 下运行）
    /// - Parameters:
    ///   - subCategory: 配件类别
    ///   - num: 数量
    func updateASKPluginCount(withSubCategoryUsingSync subCategory: String, num: Int) {
        guard subCategory.count > 0 else {
            return
        }
        if subCategory == "21" || subCategory == "22" || subCategory == "34" || subCategory == "35" {
            self.updatePanelSirenCount(self.panel.sirenCount + num, usingSync: true, complete: nil)
        }
        else if subCategory == "11" || subCategory == "1C" || subCategory == "25" || subCategory == "16" || subCategory == "19" || subCategory == "38" || subCategory == "2C" || subCategory == "3D" {
            self.updatePanelDoorSensorCount(self.panel.doorSensorCount + num, usingSync: true, complete: nil)
        }
        else if subCategory == "12" {
            self.updatePanelRelayAccessoryCount(self.panel.relayAccessoryCount + num, usingSync: true, complete: nil)
        }
        else if subCategory == "1E" || subCategory == "3A" {
            self.updatePanelRemoteControlCount(self.panel.remoteControlCount + num, usingSync: true, complete: nil)
        }
        else if subCategory == "2F" {
            self.updatePanelKeypadAccessoryCount(self.panel.keypadAccessoryCount + num, usingSync: true, complete: nil)
        }
        else if subCategory == "3E" {
            self.updatePanelSmartPlugCount(self.panel.smartPlugCount + num, usingSync: true, complete: nil)
        }
        else if subCategory == "4E" {
            self.updatePanelSignalRepeaterPlugCount(self.panel.signalRepeaterPlugCount + num, usingSync: true, complete: nil)
        }
        else if subCategory == "3B" {
            self.updatePanelSmartButtonCount(self.panel.smartButtonCount + num, usingSync: true, complete: nil)
        }
        else {
            self.updatePanelSecurityAccessoryCount(self.panel.securityAccessoryCount + num, usingSync: true, complete: nil)
        }
    }

    /// 对主机配件数量做更新缓存（格外注意！！！这个方法调用需要在 DinUser.homeDeviceInfoQueue 下运行）
    /// - Parameters:
    ///   - category: 配件类别
    ///   - num: 配件数量
    ///   - pluginID: 配件id
    ///   - decodeID: 配件解码后id
    func updateOldPluginCount(withCategoryUsingSync category: Int, num: Int, pluginID: String, decodeID: String) {
        guard pluginID.count > 0, decodeID.count > 0 else {
            return
        }
        switch category {
            case 0, 5, 6, 8, 9:
                if pluginID.count > 0 {
                    // 检查小Type
                    var dinID = DinAccessoryUtil.str64(toHexStr: pluginID)
                    if decodeID.count > 0 {
                        dinID = decodeID
                    }
                    let sTypeID = dinID[1...2]
                    if sTypeID == "0B" || sTypeID == "06" {
                        self.updatePanelDoorSensorCount(self.panel.doorSensorCount + num, usingSync: true, complete: nil)
                    }
                    else {
                        self.updatePanelSecurityAccessoryCount(self.panel.securityAccessoryCount + num, usingSync: true, complete: nil)
                    }
                }
                else {
                    self.updatePanelSecurityAccessoryCount(self.panel.securityAccessoryCount + num, usingSync: true, complete: nil)
                }
            case 1, 7:
                if DinAccessory.isKeypad(pluginID: pluginID, decodeID: decodeID) {
                    self.updatePanelKeypadAccessoryCount(self.panel.keypadAccessoryCount + num, usingSync: true, complete: nil)
                } else {
                    self.updatePanelRemoteControlCount(self.panel.remoteControlCount + num, usingSync: true, complete: nil)
                }
            case 3:
            self.updatePanelSmartPlugCount(self.panel.smartPlugCount + num, usingSync: true, complete: nil)
            case 4:
            self.updatePanelSirenCount(self.panel.sirenCount + num, usingSync: true, complete: nil)
            case 12:
            self.updatePanelRelayAccessoryCount(self.panel.relayAccessoryCount + num, usingSync: true, complete: nil)
            default:
                break
        }
    }
}
