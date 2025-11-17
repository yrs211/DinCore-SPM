//
//  DinNovaPanelOperator.swift
//  DinCore
//
//  Created by Jin on 2021/5/13.
//

import UIKit
import HandyJSON
import RxRelay
import RxSwift

class DinNovaPanelOperator: NSObject, DinHomeDeviceProtocol {
    var id: String {
        panelControl.panel.id
    }

    var manageTypeID: String {
        DinNovaPanel.panelCategoryID
    }

    var category: String {
        DinNovaPanel.panelCategoryID
    }

    var subCategory: String {
        DinNovaPanel.panelCategoryID
    }

    var info: [String: Any] { panelControl.info }

    var fatherID: String? {
        nil
    }

    // MARK: - 设备（主动操作/第三方操作）数据通知
    var deviceCallback: Observable<[String : Any]> {
        return deviceOperationResult.asObservable()
    }
    private let deviceOperationResult = PublishRelay<[String: Any]>()
    /// 设备（主动操作/第三方操作）数据通知
    /// - Parameter result: 结果
    func accept(deviceOperationResult result: [String: Any]) {
        deviceOperationResult.accept(result)
    }

    deinit {
        panelControl.disconnect()
    }

    // MARK: - 设备在线状态通知
    var deviceStatusCallback: Observable<Bool> {
        return deviceOnlineState.asObservable()
    }
    private let deviceOnlineState = PublishRelay<Bool>()
    /// 设备在线状态通知
    /// - Parameter online: 状态
    func accept(deviceOnlineState online: Bool) {
        deviceOnlineState.accept(online)
    }

    var saveJsonString: String {
        jsonString()
    }

    func submitData(_ data: [String : Any]) {
        // 检查有没有cmd
        guard let cmd = data["cmd"] as? String, cmd.count > 0 else {
            return
        }
        switch cmd {
        case DinNovaPanelControl.CMD_WS_CONN:
            wsConnection(data)
        case DinNovaPanelControl.CMD_ARM:
            armOperation(data)
        case DinNovaPanelControl.CMD_SOS:
            panelControl.sos()
        case DinNovaPanelControl.CMD_GET_PANEL_SIMINFO:
            panelControl.getSimInfo()
        case DinNovaPanelControl.CMD_RESTRICT_SMS_STRING:
            panelControl.getRestrictSMS(data)
        case DinNovaPanelControl.CMD_GET_EXITDELAY:
            panelControl.getExitDelay()
        case DinNovaPanelControl.CMD_SET_EXITDELAY:
            panelControl.setExitDelay(data)
        case DinNovaPanelControl.CMD_GET_ENTRYDELAY:
            panelControl.getEntryDelay()
        case DinNovaPanelControl.CMD_SET_ENTRYDELAY:
            panelControl.setEntryDelay(data)
        case DinNovaPanelControl.CMD_GET_SIRENTIME:
            panelControl.getSirenTime()
        case DinNovaPanelControl.CMD_SET_SIRENTIME:
            panelControl.setSirenTime(data)
        case DinNovaPanelControl.CMD_GET_HOMEARMINFO:
            panelControl.getHomeArmInfo()
        case DinNovaPanelControl.CMD_SET_HOMEARMINFO:
            panelControl.setHomeArmInfo(data)
        case DinNovaPanelControl.CMD_GET_DURESSINFO:
            panelControl.getDuressInfo()
        case DinNovaPanelControl.CMD_INIT_DURESSINFO:
            panelControl.initDuressInfo(data)
        case DinNovaPanelControl.CMD_ENABLE_DURESS:
            panelControl.enableDuressAlarm(data)
        case DinNovaPanelControl.CMD_SET_DURESSPWD:
            panelControl.setDuressPassword(data)
        case DinNovaPanelControl.CMD_SET_DURESSTEXT:
            panelControl.setDuressText(data)
        case DinNovaPanelControl.CMD_DELETE_PANEL:
            panelControl.delete()
        case DinNovaPanelControl.CMD_UNBIND_USER:
            panelControl.unbindUser(data)
        case DinNovaPanelControl.CMD_RENAME_PANEL:
            panelControl.renamePanel(data)
        case DinNovaPanelControl.CMD_PANEL_VERPWD:
            panelControl.verifyPanelPassword(data)
        case DinNovaPanelControl.CMD_PANEL_SPECIFYEVENTLIST:
            panelControl.getSpecifyEventList(data)
        case DinNovaPanelControl.CMD_PANEL_QRCODE:
            panelControl.getQRCode(data)
        case DinNovaPanelControl.CMD_PANEL_SOSINFO:
            panelControl.getSOSInfo()
        case DinNovaPanelControl.CMD_MODIFY_MEMBER:
            panelControl.modifyMember(data)
        case DinNovaPanelControl.CMD_PANEL_EMERCONTACTS:
            panelControl.getEmergencyContacts()
        case DinNovaPanelControl.CMD_MODIFY_EMERCONTACTS:
            panelControl.modifyEmergencyContacts(data)
        case DinNovaPanelControl.CMD_ADD_EMERCONTACTS:
            panelControl.addEmergencyContacts(data)
        case DinNovaPanelControl.CMD_REMOVE_EMERCONTACTS:
            panelControl.deleteEmergencyContacts(data)
        case DinNovaPanelControl.CMD_GET_MESSAGE:
            panelControl.getPanelMessage()
        case DinNovaPanelControl.CMD_GET_CIDDATA:
            panelControl.getPanelCIDData()
        case DinNovaPanelControl.CMD_SET_MESSAGELANG:
            panelControl.setMessageLang(data)
        case DinNovaPanelControl.CMD_SET_MESSAGETEMPLATE:
            panelControl.setMessageTemplate(data)
        case DinNovaPanelControl.CMD_GET_TIMEZONE:
            panelControl.getPanelTimezone()
        case DinNovaPanelControl.CMD_SET_TIMEZONE:
            panelControl.setTimezone(data)
        case DinNovaPanelControl.CMD_GET_RTASTATUS:
            panelControl.getReadyToArmStatus()
        case DinNovaPanelControl.CMD_SET_RTASTATUS:
            panelControl.setReadyToArm(data)
        case DinNovaPanelControl.CMD_GET_ADVANCED:
            panelControl.getAdvancedSetting()
        case DinNovaPanelControl.CMD_SET_ARMSOUND:
            panelControl.setArmSound(data)
        case DinNovaPanelControl.CMD_SET_RESTRICTMODE:
            panelControl.setRestrictMode(data)
        case DinNovaPanelControl.CMD_SET_PANELPWD:
            panelControl.resetPanelPassword(data)
        case DinNovaPanelControl.CMD_OPEN_BLE:
            panelControl.setPanelBluetooth(data)
        case DinNovaPanelControl.CMD_GET_4GINFO:
            panelControl.get4GInfo()
        case DinNovaPanelControl.CMD_SET_4GINFO:
            panelControl.set4GInfo(data)
        case DinNovaPanelControl.CMD_GET_CMSINFO:
            panelControl.getCMSInfo()
        case DinNovaPanelControl.CMD_SET_CMSINFO:
            panelControl.setCMSInfo(data)
        case DinNovaPanelControl.CMD_GET_CAREMODE:
            panelControl.getCareMode()
        case DinNovaPanelControl.CMD_SET_CAREMODE:
            panelControl.setCareMode(data)
        case DinNovaPanelControl.CMD_SET_CAREMODEPLUGS:
            panelControl.setCareModePlugs(data)
        case DinNovaPanelControl.CMD_GET_EVENTLIST_SETTING:
            panelControl.getEventListSetting()
        case DinNovaPanelControl.CMD_SET_EVENTLIST_SETTING:
            panelControl.setEventListSetting(data)
        case DinNovaPanelControl.CMD_CAREMODE_CANCELSOS:
            panelControl.cancelCareModeNoActionSOS()
        case DinNovaPanelControl.CMD_CAREMODE_NOACTION_SOS:
            panelControl.careModeSOSNoAction()
        case DinNovaPanelControl.CMD_RESET_PANEL:
            panelControl.resetDevice(data)
        case DinNovaPanelControl.CMD_GET_EXCETION_PLUGS:
            panelControl.getExceptionPlugs()
        case DinNovaPanelControl.CMD_GET_UNCLOSEPLUGS:
            panelControl.getUnclosePlugs(data)
        case DinNovaPanelControl.CMD_PLUGIN_LIST:
            panelControl.getPluginList(data)
        case DinNovaPanelControl.CMD_GET_PLUGSSTATUS:
            panelControl.getPlugsStatus(data)
        case DinNovaPanelControl.CMD_WIDGET_GET_ANTIINTERFERENCE_STATUS:
            panelControl.getAntiInterferenceStatus()
        case DinNovaPanelControl.CMD_WIDGET_MODIFY_CONF_COVER:
            panelControl.modifyAntiInterference(data)
        case DinNovaPanelControl.CMD_WIDGET_GET_TIMER_TASK_LIST:
            panelControl.getTimerTaskList()
        case DinNovaPanelControl.CMD_WIDGET_TOGGLE_TIMER_TASK_ABILITY:
            panelControl.toggleTimerTaskAbility(data)
        case DinNovaPanelControl.CMD_WIDGET_DELETE_TIMER_TASK:
            panelControl.deleteTimerTask(data)
        case DinNovaPanelControl.CMD_WIDGET_CREATE_TIMER_TASK:
            panelControl.createTimerTask(data)
        case DinNovaPanelControl.CMD_WIDGET_UPDATE_TIMER_TASK:
            panelControl.updateTimerTask(data)
        case DinNovaPanelControl.CMD_WIDGET_GET_RULED_PLUGINS:
            panelControl.getPluginsWithRuledTask(data)
        case DinNovaPanelControl.CMD_COUNT_PLUGIN:
            panelControl.countPlugins(data)
        case DinNovaPanelControl.CMD_LEARNMODE_ASKINFO:
            panelControl.getLearnModeAskInfo(data)
        case DinNovaPanelControl.CMD_LEARNMODE_ACTIVE:
            panelControl.activeLearnMode()
        case DinNovaPanelControl.CMD_LEARNMODE_DEACTIVE:
            panelControl.deactiveLearnMode()
        case DinNovaPanelControl.CMD_REQUEST_PANEL_UPGRADE:
            panelControl.requestPanelUpgrade(data)
        case DinNovaPanelControl.CMD_LEARNMODE_LISTEN:
            panelControl.learnModeStartListen(data)
        case DinNovaPanelControl.CMD_ZT_AUTH:
            panelControl.enableZTAuth(data)
        default:
            break
        }
    }

    func destory() {
        //
    }

    let panelControl: DinNovaPanelControl

    let disposeBag = DisposeBag()

    /// 读取缓存下来的JsonString，转化成可操作主机对象
    /// 缓存读取后，主机默认离线
    /// - Parameters:
    ///   - panelInfo: 缓存下来的JsonString
    ///   - homeID: 主机所属的家庭id
    init?(withPanelString panelInfo: String, homeID: String) {
        guard let cachePanel = DinNovaPanelOperator.panel(withJsonString: panelInfo) else {
            return nil
        }
        // 从缓存拿出来的主机默认离线，并且处在等待加载状态
        cachePanel.online = false
        cachePanel.isLoading = true
        panelControl = DinNovaPanelControl(withPanel: cachePanel, homeID: homeID)
        super.init()
        self.config()
    }

    init(withPanelControl panelControl: DinNovaPanelControl) {
        self.panelControl = panelControl
        super.init()
        self.config()
    }

    /// 主机实例化之后，需要首先做的配置
    func config() {
        // 主机比较特殊，在线或者离线的定义是服务器给的，也就是服务器返回数据就等于在线，如果服务器返回错误 -24，或者连接不上服务器，都判断为离线
        // 当然从缓存里面读取的，全部都判定为离线
        self.panelControl.updatePanelInfo(complete: nil)

        // 主机操作，信息更变回调
        panelControl.panelOperationResultObservable.subscribe(onNext: { [weak self] result in
            self?.handlePanelControl(returnData: result)
        }).disposed(by: disposeBag)
    }
}

extension DinNovaPanelOperator {
    private static func encryptString() -> String {
        DinCore.appSecret ?? ""
    }

    /// 序列化成Json字符串
    /// - Returns: 主机的Json字符串
    private func jsonString() -> String {
        DinCore.cryptor.rc4EncryptToHexString(with: panelControl.panel.toJSONString() ?? "" , key: DinNovaPanelOperator.encryptString()) ?? ""
    }

    private static func panel(withJsonString jsonString: String) -> DinNovaPanel? {
        guard jsonString.count > 0 else {
            return nil
        }
        guard let decodeString = DinCore.cryptor.rc4DecryptHexString(jsonString, key: DinNovaPanelOperator.encryptString()) else {
            return nil
        }
        return DinNovaPanel.deserialize(from: decodeString)
    }
}
