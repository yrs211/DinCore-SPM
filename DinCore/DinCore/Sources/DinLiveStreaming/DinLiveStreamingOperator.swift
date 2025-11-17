//
//  DinLiveStreamingOperator.swift
//  DinCore
//
//  Created by Monsoir on 2021/11/17.
//

import Foundation
import RxSwift
import RxRelay

class DinLiveStreamingOperator: NSObject, DinHomeDeviceProtocol {

    var id: String { liveStreamingControl.device.id }

    var manageTypeID: String { "" }

    var category: String { "" }

    var subCategory: String { "" }

    var info: [String : Any] { liveStreamingControl.info ?? [:] }

    var fatherID: String? { nil }

    // MARK: - 配件（主动操作/第三方操作）数据通知
    var deviceCallback: Observable<[String : Any]> { liveStreamingControl.deviceCallback }

    // MARK: - 配件在线状态通知
    var deviceStatusCallback: Observable<Bool> { liveStreamingControl.deviceStatusCallback }

    /// 暂时不用保存
    var saveJsonString: String { jsonString() }

    func submitData(_ data: [String : Any]) {
        guard let cmd = data["cmd"] as? String else {
            return
        }
        switch cmd {
        case DinLiveStreamingControl.CMD_CONNECT:
            liveStreamingControl.connectToCamera(discardCache: data["discardCache"] as? Bool ?? false)
        case DinLiveStreamingControl.CMD_DISCONNECT:
            liveStreamingControl.disconnect()
        case DinLiveStreamingControl.CMD_REQUESTLIVE:
            if (data["active"] as? Bool ?? false) {
                liveStreamingControl.requestLive(qualityHD: (data["quality"] as? String == "HD"))
            } else {
                liveStreamingControl.stopLive()
            }
        case DinLiveStreamingControl.CMD_REQUESTLIVE_AUDIO:
            if (data["active"] as? Bool ?? false) {
                liveStreamingControl.requestAudio()
            } else {
                liveStreamingControl.stopAudio()
            }
        case DinLiveStreamingControl.CMD_SEND_AUDIO:
            if (data["active"] as? Bool ?? false) {
                if let audioData = data["data"] as? Data {
                    liveStreamingControl.beginTalking(withVoiceData: audioData)
                }
            } else {
                liveStreamingControl.stopTalk()
            }
        case DinLiveStreamingControl.CMD_RECORDFILE:
            // 如果 fileName 和 type 的参数不对的话，liveStreamingControl.beginDownload()会报错，这里就不用做验证了
            liveStreamingControl.beginDownload(withFileName: data["fileName"] as? String ?? "",
                                               type: data["type"] as? String ?? "")
        case DinLiveStreamingControl.CMD_STOP_RECORDFILE:
            // 关闭获取TF卡文件的功能
            liveStreamingControl.stopDownload()
        case DinLiveStreamingControl.CMD_CLOSE_CMD:
            liveStreamingControl.stopCMDKcp()
        case DinLiveStreamingControl.CMD_GET_PARAMS,
            DinLiveStreamingControl.CMD_SET_MOTIONDETECT,
            DinLiveStreamingControl.CMD_SET_MOTIONDETECT_LEVEL,
            DinLiveStreamingControl.CMD_SET_MOTIONDETECT_ALARM,
            DinLiveStreamingControl.CMD_SET_PIR_LEVEL,
            DinLiveStreamingControl.CMD_SET_NAME,
            DinLiveStreamingControl.CMD_SET_MDTIME,
            DinLiveStreamingControl.CMD_GET_ALERTMODE,
            DinLiveStreamingControl.CMD_SET_ALERTMODE,
            DinLiveStreamingControl.CMD_RESTORE,
            DinLiveStreamingControl.CMD_RESET,
            DinLiveStreamingControl.CMD_REBOOT,
            DinLiveStreamingControl.CMD_FORMAT_TF,
            DinLiveStreamingControl.CMD_SET_GRAY,
            DinLiveStreamingControl.CMD_SET_VFLIP,
            DinLiveStreamingControl.CMD_SET_HFLIP,
            DinLiveStreamingControl.CMD_SET_TIMEZONE,
            DinLiveStreamingControl.CMD_UPGRADE,
            DinLiveStreamingControl.CMD_RECORDLIST,
            DinLiveStreamingControl.CMD_RECORDLIST_V2,
            DinLiveStreamingControl.CMD_DEL_RECORDFILE,
            DinLiveStreamingControl.CMD_UPDATE_SERVICE_SETTINGS,
            DinLiveStreamingControl.CMD_GET_SERVICE_SETTINGS,
            DinLiveStreamingControl.CMD_SET_FLOOD_LIGHT,
            DinLiveStreamingControl.CMD_SET_AUTO_FLOOD_LIGHT,
            DinLiveStreamingControl.CMD_SET_MOTION_DETECT_FOLLOW,
            DinLiveStreamingControl.CMD_SET_DAILY_MEMORIES,
            DinLiveStreamingControl.CMD_SET_RECORD_SCHEDULE:
            liveStreamingControl.submitData(data)
        default:
            break
        }
    }

    let disposeBag = DisposeBag()

    func destory() {
        //
    }

    let liveStreamingControl: DinLiveStreamingControl

    init(liveStreamingControl cameraControl: DinLiveStreamingControl) {
        self.liveStreamingControl = cameraControl
        super.init()
        // 如果主UDP断开，则这个也断开
        DinCore.eventBus.basic.udpSocketDisconnectObservable.subscribe(onNext: { [weak self] _ in
            self?.liveStreamingControl.disconnect()
        }).disposed(by: disposeBag)
    }

    /// 读取缓存下来的JsonString，转化成可操作摄像头对象
    /// 缓存读取后，摄像头默认离线
    /// - Parameters:
    ///   - panelInfo: 缓存下来的JsonString
    ///   - homeID: 主机所属的家庭id
    init?(deviceInfo: String, homeID: String) {
        guard let control = Self.liveStreamingControl(withJsonString: deviceInfo) else {
            return nil
        }
        control.networkState = .offline
        liveStreamingControl = DinLiveStreamingControl(withCommunicationDevice: control, belongsToHome: homeID)
        super.init()
        // 如果主UDP断开，则这个也断开
        DinCore.eventBus.basic.udpSocketDisconnectObservable.subscribe(onNext: { [weak self] _ in
            self?.liveStreamingControl.disconnect()
        }).disposed(by: disposeBag)
    }

    static func encryptString() -> String {
        DinCore.appSecret ?? ""
    }

    /// 序列化成Json字符串
    /// - Returns: 主机的Json字符串
    private func jsonString() -> String {
        DinCore.cryptor.rc4EncryptToHexString(with: liveStreamingControl.device.toJSONString() ?? "" , key: DinCameraOperator.encryptString()) ?? ""
    }

    class func liveStreamingControl(withJsonString jsonString: String) -> DinLiveStreaming? { nil }
}
