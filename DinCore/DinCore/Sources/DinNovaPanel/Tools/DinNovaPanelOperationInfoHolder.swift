//
//  DinNovaPanelOperationInfoHolder.swift
//  DinCore
//
//  Created by Jin on 2021/5/13.
//

import UIKit
import RxSwift
import RxRelay

/// 用于缓存主机操作需要的信息
class DinNovaPanelOperationInfoHolder: NSObject {
    /// 在家布防或者布防，强制执行
    /// 用于ReadyToArm操作
    var isArmForce: Bool = false
    /// 布防、撤防、在家布防使用的message id
    var armActionEventID: String?
    /// 手动触发报警使用的message id
    var sosActionEventID: String?
    /// 延时布防message id
    var delayEventID: String?
    /// 提示用户是否需要重启的Disarm messageid
    var disarmMessageID: String?

    /// 设置延迟布防ID
    var setExitDelayMID: String?
    /// 设置延迟报警ID
    var setEntryDelayMID: String?
    /// 设置警笛鸣响时间
    var setSirenTimeMID: String?
    /// 设置HomeArm信息
    var setHomeArmInfoMID: String?
    /// 初始化Duress信息
    var initDuressInfoMID: String?
    /// 开关Duress
    var enableDuressMID: String?
    /// 设置Duress密码
    var setDuressPasswordMID: String?
    /// 设置Duress信息
    var setDuressTextMID: String?
    /// 设置通知的短信，push内容
    var setMessageLanguageMID: String?
    /// 设置消息模板
    var setMessageTemplateMID: String?
    /// 设置时区
    var setTimezoneMID: String?
    /// 设置ReadyToArm配置
    var setReadyToArmMID: String?
    /// 设置ReadyToArm配置
    var setArmSoundMID: String?
    /// 设置ReadyToArm配置
    var setRestrictModeMID: String?
    /// 设置ReadyToArm配置
    var setPanelPasswordMID: String?
    /// 设置ReadyToArm配置
    var setPanelBluetoothMID: String?
    /// 设置4gInfo
    var set4GInfoMID: String?
    /// 设置CMS信息
    var setCMSInfoMID: String?
    /// 设置守护模式配置
    var setCareModeMID: String?
    /// 设置守护模式配件配置
    var setCareModePlugsMID: String?
    /// 关闭看护模式报警倒计时
    var cancelCareModeNoActionSOSMID: String?
    /// 看护模式 报警
    var careModeSOSNoActionMID: String?
    /// 设置eventlist的配置
    var setEventListSettingMID: String?
    /// 重置主机
    var resetDeviceMID: String?
    /// 获取异常配件列表(低电及打开的)
    var getExceptionPlugsMID: String?
    /// 获取未闭合的门磁列表（ready to arm）
    var getUnclosePlugsMID: String?
    /// 添加配件
    var addPlugsMID: String?
    /// 获取配件列表中配件状态
    var getPlugsStatusMID: String?
    /// 删除配件
    var deletePlugsMID: String?

    /// [触发配对]激活主机接收配件信号功能
    var activeLearnModeMID: String?
    /// [触发配对]关闭主机接收配件信号功能
    var deactiveLearnModeMID: String?
    /// [触发配对]开始监听配件信号
    var learnModeStartListenMID: String?
    /// 主机启用 zt
    var enableZTAuthMID: String?
}
