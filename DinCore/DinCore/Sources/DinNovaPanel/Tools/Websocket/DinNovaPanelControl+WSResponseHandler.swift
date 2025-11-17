//
//  DinNovaPanelControl+WSResponseHandler.swift
//  DinCore
//
//  Created by Jin on 2021/5/16.
//

import UIKit
import DinSupport

extension DinNovaPanelControl {
    func registerResponseObservers() {
        observePanelWSState()
        observeArmResult()
        observeSOSResult()
        observeSettingResult()
        observeOtherWSResult()
        observePanelWSConnectionResult()
    }
}

// MARK: - ws state
extension DinNovaPanelControl {
    func observePanelWSConnectionResult() {
        // 主机ws连接状态回调
        panelWSConnectResult?.subscribe(onNext: { [weak self] result in
            guard let self = self else { return }
            switch result.connectResult {
            case .failWithDeviceToken:
                // 如果是多次重试之后依然收到服务器返回devicetoken失败，判定主机离线
                self.setOffline(usingSync: false, complete: nil)
            default:
                break
            }
            let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_WS_CONN,
                                                         owner: true,
                                                         result: ["connection": result.connectResult.rawValue])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    func observePanelWSState() {
        // 主机ws连接状态回调
        panelWSConnection?.subscribe(onNext: { [weak self] state in
            guard let self = self else { return }
            self.updateWSConnection(usingSync: false) { [weak self] in
                guard let self = self else { return }
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_WS_STATE_CHANGED,
                                                             owner: true,
                                                             result: ["wsState": state.rawValue])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }

    func notifyPanelRenewed() {
        let returnDict = makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_RENEW,
                                               owner: true,
                                               result: [:])
        self.accept(panelOperationResult: returnDict)
    }
}

// MARK: - ws alert arm op result
extension DinNovaPanelControl {
    func observeArmResult() {
        observeArmOperationAck()
        observeArmOperationResult()
        obverveArmOperationTimeout()
    }

    func observeArmOperationAck() {
        panelWSResultObservable?.filter {
           $0.action == DinNovaPanelResponseAction.ack.rawValue && $0.cmd == DinNovaPanelCommand.arm.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            self?.operationTimeoutChecker.removeEvent(id: response.messageID)
            guard let self = self else { return }
            if self.panel.exitDelay > 0 {
                let isSelf = response.messageID == self.operationInfoHolder.armActionEventID
                let data = self.makeACKSuccessInfo(withCMD: DinNovaPanelControl.CMD_ARM,
                                           owner: isSelf,
                                           result: ["armStatus": self.panel.armStatus,
                                                    "exitDelay": self.panel.exitDelay])
                self.accept(panelOperationResult: data)
            }
       }).disposed(by: disposeBag)

        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.ack.rawValue && ($0.cmd == DinNovaPanelCommand.disarm.rawValue || $0.cmd == DinNovaPanelCommand.homeArm.rawValue)
        }.subscribe(onNext: { [weak self] (response) in
            self?.operationTimeoutChecker.removeEvent(id: response.messageID)
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.armActionEventID
            let data = self.makeACKSuccessInfo(withCMD: DinNovaPanelControl.CMD_ARM,
                                               owner: isSelf,
                                               result: ["armStatus": self.panel.armStatus])
            self.accept(panelOperationResult: data)
        }).disposed(by: disposeBag)
    }

    private func observeArmOperationResult() {
        // 布撤防结果，socket通知
        panelWSResultObservable?.filter {
            $0.cmd == DinNovaPanelCommand.arm.rawValue || $0.cmd == DinNovaPanelCommand.disarm.rawValue || $0.cmd == DinNovaPanelCommand.homeArm.rawValue
        }.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            self?.operationTimeoutChecker.removeEvent(id: response.messageID)
            guard let self = self else { return }

            // 制作提交的Dict
            var resultDict: [String: Any] = [:]
            resultDict["operationCMD"] = response.cmd
            let isSelf = response.messageID == self.operationInfoHolder.armActionEventID
            // 如果成功，改变主机状态
            if response.status == 1 {
                DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                    guard let self = self else { return }
                    //是否需要用户确认布防（ready to arm）
                    // 状态时间大于当前状态的时间才处理该结果
                    let armReturn = DinNovaPanelArmOperationResult.deserialize(from: response.result)
                    // if detect some plugin has not in ready before arm, alert user to know or decide if still arm
                    if let armResult = armReturn, armResult.plugs.count > 0 {
                        resultDict["unclosePlugins"] = armResult.plugs
                        resultDict["pluginName"] = armResult.plugName
                        resultDict["subCategory"] = armResult.subcategory
                        resultDict["category"] = armResult.category
                        resultDict["plugID"] = armResult.plugId
                        resultDict["panelName"] = self.panel.name
                        //非用户触发
                        if armResult.category == "1" || ((armResult.category == "10") && ((armResult.subcategory == "1E") || (armResult.subcategory == "3A") || (armResult.subcategory == "2F") || (armResult.subcategory == "3B")))  {
                            /// 遥控器等配件操作，已经强制执行操作
                            resultDict["force"] = false
                            // show block notice when armed
                            let blockedPlugins = armResult.blockPlugs
                            if response.cmd == DinNovaPanelCommand.arm.rawValue || response.cmd == DinNovaPanelCommand.homeArm.rawValue {
                                self.updateDeviceArmStatus(commandString: response.cmd,
                                                           time: armResult.armTime,
                                                           usingSync: true,
                                                           complete: nil)
                                resultDict["blockPlugins"] = blockedPlugins
                            } else {
                                self.updateDeviceArmStatus(commandString: response.cmd,
                                                           time: armResult.armTime,
                                                           usingSync: true,
                                                           complete: nil)
                            }
                        } else {
                            //用户触发
                            //自己
                            if response.messageID == self.operationInfoHolder.armActionEventID {
                                /// 判断是否已经强制执行操作了
                                resultDict["force"] = armResult.force
                            }
                        }
                    } else {
                        let blockedPlugins = armReturn?.blockPlugs ?? []
                        if response.cmd == DinNovaPanelCommand.arm.rawValue || response.cmd == DinNovaPanelCommand.homeArm.rawValue {
                            self.updateDeviceArmStatus(commandString: response.cmd,
                                                       time: armReturn?.armTime ?? 0,
                                                       usingSync: true,
                                                       complete: nil)
                            resultDict["blockPlugins"] = blockedPlugins
                        } else {
                            self.updateDeviceArmStatus(commandString: response.cmd,
                                                       time: armReturn?.armTime ?? 0,
                                                       usingSync: true,
                                                       complete: nil)
                        }
                    }

                    // disarm reset all sos
                    if response.cmd == DinNovaPanelCommand.disarm.rawValue {
                        if self.operationInfoHolder.disarmMessageID == response.messageID {
                            resultDict["disarmHit"] = true
                            self.operationInfoHolder.disarmMessageID = nil
                        }
                    }
                    resultDict["armStatus"] = self.panel.armStatus
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_ARM,
                                                                owner: isSelf,
                                                                result: resultDict)
                    DispatchQueue.global().async { [weak self] in
                        self?.accept(panelOperationResult: returnDict)
                    }
                    
                    self.operationInfoHolder.armActionEventID = nil
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_ARM,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
                
                self.operationInfoHolder.armActionEventID = nil
            }

        }).disposed(by: disposeBag)
    }

    func obverveArmOperationTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.arm.rawValue || $0.cmd == DinNovaPanelCommand.disarm.rawValue || $0.cmd == DinNovaPanelCommand.homeArm.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.armActionEventID
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_ARM,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
            self.lanCommunicator?.isCOAPAvailable = false
        }).disposed(by: disposeBag)
    }
}

// MARK: - ws alert arm op result
extension DinNovaPanelControl {
    func observeSOSResult() {
        observeSOSOperationResult()
        obverveSOSOperationTimeout()
    }

    private func observeSOSOperationResult()  {
        // SOS socket通知
        panelWSResultObservable?.filter {
            ($0.cmd == DinNovaPanelCommand.sos.rawValue || $0.cmd == DinNovaPanelCommand.fcSOS.rawValue || $0.cmd == DinNovaPanelCommand.careModeNoActionSOS.rawValue || $0.cmd == DinNovaPanelCommand.panelFCSOS.rawValue) && $0.action == DinNovaPanelResponseAction.result.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.sosActionEventID
            self.operationTimeoutChecker.removeEvent(id: response.messageID)
            if response.status == 1 {
                if var resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    self.updateSOS(true, usingSync: false) { [weak self] in
                        guard let self = self else { return }
                        // 检查是否有sosType
                        if !(resultDict["sostype"] is String) {
                            resultDict["sostype"] = response.cmd
                        }
                        let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SOS,
                                                                    owner: isSelf,
                                                                    result: resultDict)
                        self.accept(panelOperationResult: returnDict)
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SOS,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SOS,
                                                            owner: isSelf,
                                                            errorMessage:response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)

        // 胁迫报警
        panelWSResultObservable?.filter {
            $0.cmd == DinNovaPanelCommand.duressAlarm.rawValue && $0.action == DinNovaPanelResponseAction.result.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            if response.status == 1 {
                if var resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                        guard let self = self else { return }
                        let sosResponse = DinNovaPanelSOSOperationResult.deserialize(from: response.result)
                        self.updateDeviceArmStatus(commandString: DinNovaPanelCommand.disarm.rawValue,
                                                   time: sosResponse?.time ?? 0,
                                                   usingSync: true,
                                                   complete: nil)
                        self.updateSOS(true, usingSync: true, complete: nil)
                        // 检查是否有sosType
                        if !(resultDict["sostype"] is String) {
                            resultDict["sostype"] = response.cmd
                        }
                        let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SOS,
                                                                    owner: false,
                                                                    result: resultDict)
                        DispatchQueue.global().async { [weak self] in
                            self?.accept(panelOperationResult: returnDict)
                        }
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SOS,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            }
        }).disposed(by: disposeBag)

        // 防干扰报警
        panelWSResultObservable?.filter {
            $0.cmd == DinNovaPanelCommand.antiInterferenceAlarm.rawValue && $0.action == DinNovaPanelResponseAction.result.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            if response.status == 1 {
                if var resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    // 检查是否有sosType
                    if !(resultDict["sostype"] is String) {
                        resultDict["sostype"] = response.cmd
                    }
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SOS,
                                                                owner: false,
                                                                result: resultDict)
                    self.updateSOS(true, usingSync: false) { [weak self] in
                        self?.accept(panelOperationResult: returnDict)
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SOS,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            }
        }).disposed(by: disposeBag)
    }

    func obverveSOSOperationTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.sos.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.sosActionEventID
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SOS,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
            self.lanCommunicator?.isCOAPAvailable = false
        }).disposed(by: disposeBag)
    }
}


// MARK: - ws notify setting result
extension DinNovaPanelControl {
    func observeSettingResult() {
        // 延时布防
        observeSetExitDelayResult()
        obverveSetExitDelayTimeout()
        // 延时报警
        observeSetEntryDelayResult()
        obverveSetEntryDelayTimeout()
        // 警笛鸣响时长
        observeSetSirenTimeResult()
        obverveSetSirenTimeTimeout()
        // HomeArm信息配置
        observeSetHomeArmInfoResult()
        obverveSetHomeArmInfoTimeout()
        // 胁迫报警信息配置
        observeInitDuressResult()
        observeEnableDuressResult()
        observeSetDuressPWDResult()
        observeSetDuressTextResult()
        obverveInitDuressTimeout()
        obverveEnableDuressTimeout()
        obverveSetDuressPWDTimeout()
        obverveSetDuressTextTimeout()
        // 设置通知的短信，push内容
        observeSetMessageLanguageResult()
        obverveSetMessageLanguageTimeout()
        observeSetMessageTemplateResult()
        obverveSetMessageTemplateTimeout()
        // 设置时区
        observeSetTimeZoneResult()
        obverveSetTimeZoneTimeout()
        // 设置ReadyToArm
        observeSetRTAResult()
        obverveSetRTATimeout()
        // 设置布撤防声音
        observeSetArmSoundResult()
        obverveSetArmSoundTimeout()
        // 设置限制模式开关
        observeSetRestrictModeResult()
        obverveSetRestrictModeTimeout()
        // 设置主机密码
        observeSetPanelPasswordResult()
        obverveSetPanelPasswordTimeout()
        // 设置主机蓝牙开关
        observeSetPanelBluetoothResult()
        obverveSetPanelBluetoothTimeout()
        // 设置主机4G
        observeSet4GResult()
        obverveSet4GTimeout()
        // 设置主机CMS
        observeSetCMSResult()
        obverveSetCMSTimeout()
        // 设置守护模式配置
        observeSetCareModeResult()
        obverveSetCareModeTimeout()
        // 设置守护模式配件配置
        observeSetCareModePlugsResult()
        obverveSetCareModePlugsTimeout()
        // 取消caremode报警
        observeCancelCareModeNoActionSOSResult()
        observeCancelCareModeNoActionSOSTimeout()
        // 看护模式 报警
        observeCareModeNoActionSOSResult()
        observeCareModeNoActionSOSTimeout()
        // 设置eventlist的配置
        observeSetEventListSettingResult()
        obverveSetEventListSettingTimeout()
        // 重置主机
        observeResetDeviceResult()
        observeResetDeviceTimeout()
        // 获取异常配件列表(低电及打开的)
        observeExceptionPlugsResult()
        observeExceptionPlugsTimeout()
        // 获取未闭合的门磁列表（ready to arm）
        observeUnclosePlugsResult()
        observeUnclosePlugsTimeout()
        // 添加配件
        observeAddAskPlugsResult()
        observeAddAskPlugsTimeout()
        observeAddOldPlugsResult()
        observeAddOldPlugsTimeout()
        // 删除配件
        observeRemoveAskPlugsResult()
        observeRemoveAskPlugsTimeout()
        observeRemoveOldPlugsResult()
        observeRemoveOldPlugsTimeout()
        // 获取配件列表中配件状态
        observePlugsStatusResult()
        observePlugsStatusTimeout()
        // 触发配对
        observeActiveLearnModeResult()
        observeActiveLearnModeTimeout()
        observeEnableZTAuthResult()
        observeEnableZTAuthTimeout()
        
    }

    private func observeSetExitDelayResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.setExitDelay.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.setExitDelayMID
            self.operationTimeoutChecker.removeEvent(id: response.messageID)
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.setExitDelayMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let exitDelay = resultDict["time"] as? Int ?? 0
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SET_EXITDELAY,
                                                                owner: isSelf,
                                                                result: resultDict)
                    self.updateExitDelay(exitDelay, usingSync: false) { [weak self] in
                        self?.accept(panelOperationResult: returnDict)
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_EXITDELAY,
                                                                owner: isSelf,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_EXITDELAY,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func obverveSetExitDelayTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.setExitDelay.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.setExitDelayMID
            if isSelf {
                self.operationInfoHolder.setExitDelayMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_EXITDELAY,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeSetEntryDelayResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.setEntryDelay.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.setEntryDelayMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.setEntryDelayMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let entryDelay = resultDict["time"] as? Int ?? 0
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SET_ENTRYDELAY,
                                                                owner: isSelf,
                                                                result: resultDict)
                    self.updateEntryDelay(entryDelay, usingSync: false) { [weak self] in
                        self?.accept(panelOperationResult: returnDict)
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_ENTRYDELAY,
                                                                owner: isSelf,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_ENTRYDELAY,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func obverveSetEntryDelayTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.setEntryDelay.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.setEntryDelayMID
            if isSelf {
                self.operationInfoHolder.setEntryDelayMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_ENTRYDELAY,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeSetSirenTimeResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.setSirenTime.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.setSirenTimeMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.setSirenTimeMID = nil
            }
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SET_SIRENTIME,
                                                            owner: isSelf,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_SIRENTIME,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func obverveSetSirenTimeTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.setSirenTime.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.setSirenTimeMID
            if isSelf {
                self.operationInfoHolder.setSirenTimeMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_SIRENTIME,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeSetHomeArmInfoResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.setHomeArm.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.setHomeArmInfoMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.setHomeArmInfoMID = nil
            }
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SET_HOMEARMINFO,
                                                            owner: isSelf,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_HOMEARMINFO,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func obverveSetHomeArmInfoTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.setHomeArm.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.setHomeArmInfoMID
            if isSelf {
                self.operationInfoHolder.setHomeArmInfoMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_HOMEARMINFO,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeInitDuressResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.initDuressAlarm.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.initDuressInfoMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.initDuressInfoMID = nil
            }
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_INIT_DURESSINFO,
                                                            owner: isSelf,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_INIT_DURESSINFO,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func obverveInitDuressTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.initDuressAlarm.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.initDuressInfoMID
            if isSelf {
                self.operationInfoHolder.initDuressInfoMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_INIT_DURESSINFO,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeEnableDuressResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.setDuressAlarmEnable.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.enableDuressMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.enableDuressMID = nil
            }
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_ENABLE_DURESS,
                                                            owner: isSelf,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_ENABLE_DURESS,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func obverveEnableDuressTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.setDuressAlarmEnable.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.enableDuressMID
            if isSelf {
                self.operationInfoHolder.enableDuressMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_ENABLE_DURESS,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeSetDuressPWDResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.setDuressAlarmPassword.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.setDuressPasswordMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.setDuressPasswordMID = nil
            }
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SET_DURESSPWD,
                                                            owner: isSelf,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_DURESSPWD,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func obverveSetDuressPWDTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.setDuressAlarmPassword.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.setDuressPasswordMID
            if isSelf {
                self.operationInfoHolder.setDuressPasswordMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_DURESSPWD,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeSetDuressTextResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.setDuressAlarmText.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.setDuressTextMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.setDuressTextMID = nil
            }
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SET_DURESSTEXT,
                                                            owner: isSelf,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_DURESSTEXT,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func obverveSetDuressTextTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.setDuressAlarmText.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.setDuressTextMID
            if isSelf {
                self.operationInfoHolder.setDuressTextMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_DURESSTEXT,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeSetMessageLanguageResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.setPushLang.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.setMessageLanguageMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.setMessageLanguageMID = nil
            }
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SET_MESSAGELANG,
                                                            owner: isSelf,
                                                            result: [:])
                self.updateMessageSet(true, usingSync: false) { [weak self] in
                    self?.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_MESSAGELANG,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func obverveSetMessageLanguageTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.setPushLang.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.setMessageLanguageMID
            if isSelf {
                self.operationInfoHolder.setMessageLanguageMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_MESSAGELANG,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeSetMessageTemplateResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.setMessage.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.setMessageTemplateMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.setMessageTemplateMID = nil
            }
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SET_MESSAGETEMPLATE,
                                                            owner: isSelf,
                                                            result: [:])
                self.updateMessageSet(true, usingSync: false) { [weak self] in
                    self?.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_MESSAGETEMPLATE,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func obverveSetMessageTemplateTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.setMessage.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.setMessageTemplateMID
            if isSelf {
                self.operationInfoHolder.setMessageTemplateMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_MESSAGETEMPLATE,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeSetTimeZoneResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.setTimezone.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.setTimezoneMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.setTimezoneMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let timezone = resultDict["timezone"] as? String ?? ""
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SET_TIMEZONE,
                                                                owner: isSelf,
                                                                result: resultDict)
                    self.updateTimezone(timezone, usingSync: false) { [weak self] in
                        self?.accept(panelOperationResult: returnDict)
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_TIMEZONE,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_TIMEZONE,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func obverveSetTimeZoneTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.setTimezone.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.setTimezoneMID
            if isSelf {
                self.operationInfoHolder.setTimezoneMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_TIMEZONE,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeSetRTAResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.setReadyToArm.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.setReadyToArmMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.setReadyToArmMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SET_RTASTATUS,
                                                                owner: isSelf,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_RTASTATUS,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_RTASTATUS,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func obverveSetRTATimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.setReadyToArm.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.setReadyToArmMID
            if isSelf {
                self.operationInfoHolder.setReadyToArmMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_RTASTATUS,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeSetArmSoundResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.setPlaySoundSetting.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.setArmSoundMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.setArmSoundMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SET_ARMSOUND,
                                                                owner: isSelf,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_ARMSOUND,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_ARMSOUND,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func obverveSetArmSoundTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.setPlaySoundSetting.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.setArmSoundMID
            if isSelf {
                self.operationInfoHolder.setArmSoundMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_ARMSOUND,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeSetRestrictModeResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.setRestrictMode.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.setRestrictModeMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.setRestrictModeMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SET_RESTRICTMODE,
                                                                owner: isSelf,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_RESTRICTMODE,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_RESTRICTMODE,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func obverveSetRestrictModeTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.setRestrictMode.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.setRestrictModeMID
            if isSelf {
                self.operationInfoHolder.setRestrictModeMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_RESTRICTMODE,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeSetPanelPasswordResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.resetDevicePassword.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.setPanelPasswordMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.setPanelPasswordMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SET_PANELPWD,
                                                                owner: isSelf,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_PANELPWD,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_PANELPWD, status: response.status,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func obverveSetPanelPasswordTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.resetDevicePassword.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.setPanelPasswordMID
            if isSelf {
                self.operationInfoHolder.setPanelPasswordMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_PANELPWD,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeSetPanelBluetoothResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.openDeviceBluetooth.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.setPanelBluetoothMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.setPanelBluetoothMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_OPEN_BLE,
                                                                owner: isSelf,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_OPEN_BLE,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_OPEN_BLE,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func obverveSetPanelBluetoothTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.openDeviceBluetooth.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.setPanelBluetoothMID
            if isSelf {
                self.operationInfoHolder.setPanelBluetoothMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_OPEN_BLE,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeSet4GResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.set4GConfiguration.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.set4GInfoMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.set4GInfoMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SET_4GINFO,
                                                                owner: isSelf,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_4GINFO,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_4GINFO,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func obverveSet4GTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.set4GConfiguration.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.set4GInfoMID
            if isSelf {
                self.operationInfoHolder.set4GInfoMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_4GINFO,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeSetCMSResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.setCMSInfo.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.setCMSInfoMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.setCMSInfoMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SET_CMSINFO,
                                                                owner: isSelf,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_CMSINFO,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_CMSINFO,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func obverveSetCMSTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.setCMSInfo.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.setCMSInfoMID
            if isSelf {
                self.operationInfoHolder.setCMSInfoMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_CMSINFO,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeSetCareModeResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.setCareModeData.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.setCareModeMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.setCareModeMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SET_CAREMODE,
                                                                owner: isSelf,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_CAREMODE,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_CAREMODE,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func obverveSetCareModeTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.setCareModeData.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.setCareModeMID
            if isSelf {
                self.operationInfoHolder.setCareModeMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_CAREMODE,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeSetCareModePlugsResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.setCareModePlugin.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.setCareModePlugsMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.setCareModePlugsMID = nil
            }
            if response.status == 1 {
                // result没有的，直接正确返回
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SET_CAREMODEPLUGS,
                                                            owner: isSelf,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_CAREMODEPLUGS,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func obverveSetCareModePlugsTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.setCareModePlugin.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.setCareModePlugsMID
            if isSelf {
                self.operationInfoHolder.setCareModePlugsMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_CAREMODEPLUGS,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeSetEventListSettingResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.updateEventListSetting.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.setEventListSettingMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.setEventListSettingMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_SET_EVENTLIST_SETTING,
                                                                owner: isSelf,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_EVENTLIST_SETTING,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_EVENTLIST_SETTING,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func obverveSetEventListSettingTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.updateEventListSetting.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.setEventListSettingMID
            if isSelf {
                self.operationInfoHolder.setEventListSettingMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_SET_EVENTLIST_SETTING,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeCancelCareModeNoActionSOSResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.cancelCareModeNoActionSOS.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.cancelCareModeNoActionSOSMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.cancelCareModeNoActionSOSMID = nil
            }
            if response.status == 1 {
                let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_CAREMODE_CANCELSOS,
                                                            owner: isSelf,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_CAREMODE_CANCELSOS,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func observeCancelCareModeNoActionSOSTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.cancelCareModeNoActionSOS.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.cancelCareModeNoActionSOSMID
            if isSelf {
                self.operationInfoHolder.cancelCareModeNoActionSOSMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_CAREMODE_CANCELSOS,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeCareModeNoActionSOSResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.careModeNoActionSOS.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.careModeSOSNoActionMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.careModeSOSNoActionMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_CAREMODE_NOACTION_SOS,
                                                                owner: isSelf,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_CAREMODE_NOACTION_SOS,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_CAREMODE_NOACTION_SOS,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func observeCareModeNoActionSOSTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.careModeNoActionSOS.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.careModeSOSNoActionMID
            if isSelf {
                self.operationInfoHolder.careModeSOSNoActionMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_CAREMODE_NOACTION_SOS,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeResetDeviceResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.resetDevice.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.resetDeviceMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.resetDeviceMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_RESET_PANEL,
                                                                owner: isSelf,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_RESET_PANEL,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_RESET_PANEL,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func observeResetDeviceTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.resetDevice.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.resetDeviceMID
            if isSelf {
                self.operationInfoHolder.resetDeviceMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_RESET_PANEL,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeExceptionPlugsResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.taskPluginException.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.getExceptionPlugsMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.getExceptionPlugsMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_GET_EXCETION_PLUGS,
                                                                owner: isSelf,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_EXCETION_PLUGS,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_EXCETION_PLUGS,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func observeExceptionPlugsTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.taskPluginException.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.getExceptionPlugsMID
            if isSelf {
                self.operationInfoHolder.getExceptionPlugsMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_EXCETION_PLUGS,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeUnclosePlugsResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.getUnClosedSensor.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.getUnclosePlugsMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.getUnclosePlugsMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_GET_UNCLOSEPLUGS,
                                                                owner: isSelf,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_UNCLOSEPLUGS,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_UNCLOSEPLUGS,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func observeUnclosePlugsTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.getUnClosedSensor.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.getUnclosePlugsMID
            if isSelf {
                self.operationInfoHolder.getUnclosePlugsMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_UNCLOSEPLUGS,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeAddAskPlugsResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.addASKPlugin.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.addPlugsMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.addPlugsMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                        guard let self = self else { return }
                        let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_ADD,
                                                                    owner: isSelf,
                                                                    result: resultDict)
                        if let stype = resultDict["stype"] as? String {
                            self.updateASKPluginCount(withSubCategoryUsingSync: stype, num: 1)
                        }
                        DispatchQueue.global().async { [weak self] in
                            self?.accept(panelOperationResult: returnDict)
                        }
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_ADD,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let errorString = (response.status == -50) ? "plugin_exist" : response.error
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_ADD,
                                                            owner: isSelf,
                                                            errorMessage: errorString,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func observeAddAskPlugsTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.addASKPlugin.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.addPlugsMID
            if isSelf {
                self.operationInfoHolder.addPlugsMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_ADD,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeAddOldPlugsResult()  {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.addPlugin.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.addPlugsMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.addPlugsMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                        guard let self = self else { return }
                        let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_ADD,
                                                                    owner: isSelf,
                                                                    result: resultDict)
                        if let category = resultDict["category"] as? Int, let pluginID = resultDict["pluginid"] as? String, let decodeID = resultDict["decodeid"] as? String {
                            self.updateOldPluginCount(withCategoryUsingSync: category, num: 1, pluginID: pluginID, decodeID: decodeID)
                        }
                        DispatchQueue.global().async { [weak self] in
                            self?.accept(panelOperationResult: returnDict)
                        }
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_ADD,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let errorString = (response.status == -50) ? "plugin_exist" : response.error
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_ADD,
                                                            owner: isSelf,
                                                            errorMessage: errorString,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func observeAddOldPlugsTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.addPlugin.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.addPlugsMID
            if isSelf {
                self.operationInfoHolder.addPlugsMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_ADD,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    /// 主机旧配件删除通知
    private func observeRemoveOldPlugsResult() {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.deletePlugin.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.deletePlugsMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.deletePlugsMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result),
                    let category = resultDict["category"] as? Int,
                   let pluginID = resultDict["pluginid"] as? String,
                   let decodeID = resultDict["decodeid"] as? String {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_DELETE,
                                                                owner: isSelf,
                                                                result: resultDict)
                    DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                        guard let self = self else { return }
                        self.updateOldPluginCount(withCategoryUsingSync: category,
                                                  num: -1,
                                                  pluginID: pluginID,
                                                  decodeID: decodeID)
                        DispatchQueue.global().async { [weak self] in
                            self?.accept(panelOperationResult: returnDict)
                        }
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_DELETE,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_DELETE,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    private func observeRemoveOldPlugsTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.deletePlugin.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.deletePlugsMID
            if isSelf {
                self.operationInfoHolder.deletePlugsMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_DELETE,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    /// 主机ASK配件删除通知
    private func observeRemoveAskPlugsResult() {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.deleteASKPLugin.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.deletePlugsMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.deletePlugsMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result),
                    let subCategory = resultDict["stype"] as? String {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_DELETE,
                                                                owner: isSelf,
                                                                result: resultDict)
                    DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                        guard let self = self else { return }
                        self.updateASKPluginCount(withSubCategoryUsingSync: subCategory, num: -1)
                        DispatchQueue.global().async { [weak self] in
                            self?.accept(panelOperationResult: returnDict)
                        }
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_DELETE,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_DELETE,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func observeRemoveAskPlugsTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.deleteASKPLugin.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.deletePlugsMID
            if isSelf {
                self.operationInfoHolder.deletePlugsMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_PLUGIN_DELETE,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }


    private func observePlugsStatusResult() {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.pluginPowerValueChanged.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.getPlugsStatusMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.getPlugsStatusMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_GET_PLUGSSTATUS,
                                                                owner: isSelf,
                                                                result: resultDict)
                    self.accept(panelOperationResult: returnDict)
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_PLUGSSTATUS,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_PLUGSSTATUS,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    func observePlugsStatusTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.pluginPowerValueChanged.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.getPlugsStatusMID
            if isSelf {
                self.operationInfoHolder.getPlugsStatusMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_GET_PLUGSSTATUS,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }

    private func observeActiveLearnModeResult()  {
        learnModeResultObservable?.subscribe(onNext: { [weak self] result in
            guard let self = self else { return }

            let cmd = result["cmd"] as? String
            if cmd == DinNovaPanelControl.CMD_LEARNMODE_ACTIVE {
                if let messageID = self.operationInfoHolder.activeLearnModeMID {
                    self.operationTimeoutChecker.removeEvent(id: messageID)
                    self.operationInfoHolder.activeLearnModeMID = nil
                }
            } else if cmd == DinNovaPanelControl.CMD_LEARNMODE_DEACTIVE {
                if let messageID = self.operationInfoHolder.deactiveLearnModeMID {
                    self.operationTimeoutChecker.removeEvent(id: messageID)
                    self.operationInfoHolder.deactiveLearnModeMID = nil
                }
            } else if cmd == DinNovaPanelControl.CMD_LEARNMODE_LISTEN {
                if let messageID = self.operationInfoHolder.learnModeStartListenMID {
                    self.operationTimeoutChecker.removeEvent(id: messageID)
                    self.operationInfoHolder.learnModeStartListenMID = nil
                }
            }
            self.accept(panelOperationResult: result)
        }).disposed(by: disposeBag)
    }
    func observeActiveLearnModeTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.subscribe(onNext: { [weak self] failEvent in
            guard let self = self else { return }
            if failEvent.id == self.operationInfoHolder.activeLearnModeMID {
                if let messageID = self.operationInfoHolder.activeLearnModeMID {
                    self.operationTimeoutChecker.removeEvent(id: messageID)
                    self.operationInfoHolder.activeLearnModeMID = nil
                    self.accept(panelOperationResult: ["cmd": "start_learnmode", "status": 0])
                }
            } else if failEvent.id == self.operationInfoHolder.deactiveLearnModeMID {
                if let messageID = self.operationInfoHolder.deactiveLearnModeMID {
                    self.operationTimeoutChecker.removeEvent(id: messageID)
                    self.operationInfoHolder.deactiveLearnModeMID = nil
                    self.accept(panelOperationResult: ["cmd": "stop_learnmode", "status": 0])
                }
            } else if failEvent.id == self.operationInfoHolder.learnModeStartListenMID {
                if let messageID = self.operationInfoHolder.learnModeStartListenMID {
                    self.operationTimeoutChecker.removeEvent(id: messageID)
                    self.operationInfoHolder.learnModeStartListenMID = nil
                    self.accept(panelOperationResult: ["cmd": DinNovaPanelControl.CMD_LEARNMODE_LISTEN, "status": -9, "errorMessage": "timeout"])
                }
            }
        }).disposed(by: disposeBag)
    }
    
    /// 临时屏蔽红外触发通知
    private func observeEnableZTAuthResult() {
        panelWSResultObservable?.filter {
            $0.action == DinNovaPanelResponseAction.result.rawValue && $0.cmd == DinNovaPanelCommand.enableZTAuth.rawValue
        }.subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            let isSelf = response.messageID == self.operationInfoHolder.enableZTAuthMID
            if isSelf {
                self.operationTimeoutChecker.removeEvent(id: response.messageID)
                self.operationInfoHolder.enableZTAuthMID = nil
            }
            if response.status == 1 {
                if let resultDict = DinDataConvertor.convertToDictionary(response.result) {
                    let returnDict = self.makeResultSuccessInfo(withCMD: DinNovaPanelControl.CMD_ZT_AUTH,
                                                                owner: isSelf,
                                                                result: resultDict)
                    DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                        guard let self = self else { return }
                        DispatchQueue.global().async { [weak self] in
                            self?.accept(panelOperationResult: returnDict)
                        }
                    }
                } else {
                    let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_ZT_AUTH,
                                                                owner: false,
                                                                errorMessage: "can not convert data",
                                                                result: [:])
                    self.accept(panelOperationResult: returnDict)
                }
            } else {
                let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_ZT_AUTH,
                                                            owner: isSelf,
                                                            errorMessage: response.error,
                                                            result: [:])
                self.accept(panelOperationResult: returnDict)
            }
        }).disposed(by: disposeBag)
    }
    
    private func observeEnableZTAuthTimeout() {
        operationTimeoutChecker.operationTimeoutObservable.filter {
            $0.cmd == DinNovaPanelCommand.enableZTAuth.rawValue
        }.subscribe(onNext: { [weak self] (failEvent) in
            guard let self = self else { return }
            let isSelf = failEvent.id == self.operationInfoHolder.enableZTAuthMID
            if isSelf {
                self.operationInfoHolder.enableZTAuthMID = nil
            }
            let returnDict = self.makeResultFailureInfo(withCMD: DinNovaPanelControl.CMD_ZT_AUTH,
                                                        owner: isSelf,
                                                        errorMessage: "timout",
                                                        result: [:])
            self.accept(panelOperationResult: returnDict)
        }).disposed(by: disposeBag)
    }
}

// MARK: - Basic
extension DinNovaPanelControl {
    func makeACKSuccessInfo(withCMD cmd: String, owner: Bool, result: [String: Any]) -> [String: Any] {
        return ["cmd": cmd, "resultType": 0, "owner": owner, "status": 1, "errorMessage": "", "result": result]
    }
    func makeResultSuccessInfo(withCMD cmd: String, owner: Bool, result: [String: Any]) -> [String: Any] {
        return ["cmd": cmd, "resultType": 1, "owner": owner, "status": 1, "errorMessage": "", "result": result]
    }
    private func makeACKFailureInfo(withCMD cmd: String, owner: Bool, errorMessage: String, result: [String: Any]) -> [String: Any] {
        return ["cmd": cmd, "resultType": 0, "owner": owner, "status": 0, "errorMessage": errorMessage, "result": result]
    }
    func makeResultFailureInfo(withCMD cmd: String, status: Int = 0, owner: Bool, errorMessage: String, result: [String: Any]) -> [String: Any] {
        return ["cmd": cmd, "resultType": 1, "owner": owner, "status": status, "errorMessage": errorMessage, "result": result]
    }

    private func updateDeviceArmStatus(commandString: String,
                                       time: NSNumber,
                                       usingSync sync: Bool,
                                       complete: (()->())?) {
        var armStatus = panel.armStatus
        switch commandString {
        case DinNovaPanelCommand.arm.rawValue:
            armStatus = DinNovaPanelArmStatus.arm.rawValue
        case DinNovaPanelCommand.disarm.rawValue:
            armStatus = DinNovaPanelArmStatus.disarm.rawValue
        case DinNovaPanelCommand.homeArm.rawValue:
            armStatus = DinNovaPanelArmStatus.homeArm.rawValue
        default:
            break
        }

        if sync {
            panel.updateArmStatus(armStatus, time: time)
            self.updateArmStatus(armStatus, usingSync: true, complete: nil)
            self.updateSOS(panel.sos, usingSync: true, complete: nil)
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.panel.updateArmStatus(armStatus, time: time)
                self.updateArmStatus(armStatus, usingSync: true, complete: nil)
                self.updateSOS(self.panel.sos, usingSync: true, complete: nil)
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
}

