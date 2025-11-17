//
//  DinNovaPluginControl.swift
//  DinCore
//
//  Created by Jin on 2021/5/26.
//

import UIKit
import RxSwift
import RxRelay

/// 配件控制类，必须依靠DinNovaPanelOperator的操作类里面的WebsocketControl才能通讯，监听
/// 所以再新建此类的时候，请赋值给 panelOperator 属性
class DinNovaPluginControl: NSObject {

    /// 赋值给 panelOperator 属性之后会自动填充
    let panelID: String
    /// 赋值给 panelOperator 属性之后会自动填充
    let homeID: String
    /// 需要依赖Panel的操作类做websock转换
    let panelOperator: DinNovaPanelOperator
    /// nova系列配件
    let plugin: DinNovaPlugin

    /// 供用户查询的Dict
    /// Control info sync queue
    /// 在多线程读写的情况下，Info属性会有数据竞争的问题
    var unsafeInfo: [String: Any] = [:]
    var infoDict: [String: Any] {
        var tempInfo: [String: Any] = [:]
        DinUser.homeDeviceInfoQueue.sync { [weak self] in
            if let self = self {
                tempInfo = self.unsafeInfo
            }
        }
        return tempInfo
    }

    /// 用于缓存配件操作需要的信息
    var operationInfoHolder = DinNovaPluginOperationInfoHolder()
    /// 操作超时检查
    var operationTimeoutChecker = DinNovaPanelEventHandler()

    // MARK: - 配件（主动操作/第三方操作）数据通知
    var deviceCallback: Observable<[String : Any]> {
        return deviceOperationResult.asObservable()
    }
    private let deviceOperationResult = PublishRelay<[String: Any]>()
    /// 设备（主动操作/第三方操作）数据通知
    /// - Parameter result: 结果
    func accept(deviceOperationResult result: [String: Any]) {
        deviceOperationResult.accept(result)
    }

    // MARK: - 配件在线状态通知
    var deviceStatusCallback: Observable<Bool> {
        return deviceOnlineState.asObservable()
    }
    private let deviceOnlineState = PublishRelay<Bool>()
    /// 设备在线状态通知
    /// - Parameter online: 状态
    func accept(deviceOnlineState online: Bool) {
        deviceOnlineState.accept(online)
    }

    let disposeBag = DisposeBag()

    /// 配件操作类
    /// - Parameter plugin: nova系列配件
    init(withPlugin plugin: DinNovaPlugin, panelOperator: DinNovaPanelOperator) {
        self.plugin = plugin
        self.panelOperator = panelOperator
        self.panelID = panelOperator.panelControl.panel.id
        self.homeID = panelOperator.panelControl.homeID
        super.init()

        // ws 返回结果
        self.panelOperator.panelControl.panelWSResultObservable?.subscribe(onNext: { [weak self] result in
            self?.handle(result: result)
        }).disposed(by: disposeBag)
        // ws 超时
        operationTimeoutChecker.operationTimeoutObservable.subscribe(onNext: { [weak self] event in
            self?.handleTimeout(event)
        }).disposed(by: disposeBag)

        /// 运行检查器
        operationTimeoutChecker.start()

    }

    func operateData(_ data: [String: Any]) {
        guard let cmd = data["cmd"] as? String else {
            return
        }

        switch cmd {
        case DinNovaPluginControl.CMD_SET_NAME:
            setName(data)
        case DinNovaPluginControl.CMD_ADD:
            addPlugin(data)
        case DinNovaPluginControl.CMD_DELETE:
            deletePlugin(data)
        default:
            break
        }
    }

    func handle(result: DinNovaPanelSocketResponse) {
        // 只处理Result结果
        guard result.action == DinNovaPanelResponseAction.result.rawValue else {
            return
        }
        switch result.cmd {
        case DinNovaPluginCommand.setASKPlugin.rawValue:
            handleSetASKPlugNameResult(result, failEvent: nil)
        case DinNovaPluginCommand.modifyPlugin.rawValue:
            handleSetOldPlugNameResult(result, failEvent: nil)
//        case DinNovaPluginCommand.deleteASKPLugin.rawValue:
//            handleDeleteASKPlugResult(result, failEvent: nil)
//        case DinNovaPluginCommand.deletePlugin.rawValue:
//            handleDeleteOldPlugResult(result, failEvent: nil)
        default:
            break
        }
    }

    func handleTimeout(_ event: DinNovaPanelEvent) {
        switch event.cmd {
        case DinNovaPluginCommand.setASKPlugin.rawValue:
            handleSetASKPlugNameResult(nil, failEvent: event)
        case DinNovaPluginCommand.modifyPlugin.rawValue:
            handleSetOldPlugNameResult(nil, failEvent: event)
//        case DinNovaPluginCommand.deleteASKPLugin.rawValue:
//            handleDeleteASKPlugResult(nil, failEvent: event)
//        case DinNovaPluginCommand.deletePlugin.rawValue:
//            handleDeleteOldPlugResult(nil, failEvent: event)
        default:
            break
        }
    }

    /// 有某些奇怪的逻辑，需要强制让配件置于在线或者离线
    /// - Parameter online: 是否在线
    func forcePlugin(toOnline online: Bool, complete: (()->())?) {
        if let complete = complete {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                // 配件属性 - info 更改
                self.updateIsOnline(online, usingSync: true, complete: nil)

                // 配件属性 - askData 更改
                if self.plugin.askData?["keeplive"] is Bool {
                    self.plugin.askData?["keeplive"] = online
                    self.updateASKData(self.plugin.askData ?? [:], usingSync: true, complete: nil)
                }
                DispatchQueue.global().async {
                    complete()
                }
            }
        } else {
            // 配件属性 - info 更改
            self.updateIsOnline(online, usingSync: true, complete: nil)

            // 配件属性 - askData 更改
            if self.plugin.askData?["keeplive"] is Bool {
                self.plugin.askData?["keeplive"] = online
                self.updateASKData(self.plugin.askData ?? [:], usingSync: true, complete: nil)
            }
        }
    }
    func setIsDeleted(_ isDeleted: Bool, usingSync sync: Bool, complete: (() -> ())?){
        updateIsDeleted(isDeleted, usingSync: sync, complete: complete)
    }
    
}

// MARK: - Basic
extension DinNovaPluginControl {
    func makeResultSuccessInfo(withCMD cmd: String, owner: Bool, result: [String: Any]) -> [String: Any] {
        return ["cmd": cmd, "resultType": 1, "owner": owner, "status": 1, "errorMessage": "", "result": result]
    }
    func makeResultFailureInfo(withCMD cmd: String, owner: Bool, errorMessage: String, result: [String: Any]) -> [String: Any] {
        return ["cmd": cmd, "resultType": 1, "owner": owner, "status": 0, "errorMessage": errorMessage, "result": result]
    }
    func makeHTTPSuccessInfo(withCMD cmd: String, result: [String: Any]) -> [String: Any] {
        return ["cmd": cmd, "status": 1, "owner": true, "errorMessage": "", "result": result]
    }
    func makeHTTPFailureInfo(withCMD cmd: String, errorMessage: String, result: [String: Any]) -> [String: Any] {
        return ["cmd": cmd, "status": 0, "owner": true, "errorMessage": errorMessage, "result": result]
    }
}
