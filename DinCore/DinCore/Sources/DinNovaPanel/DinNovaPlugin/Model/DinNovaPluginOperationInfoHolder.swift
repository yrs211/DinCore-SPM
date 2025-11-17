//
//  DinNovaPluginOperationInfoHolder.swift
//  DinCore
//
//  Created by Jin on 2021/5/29.
//

import UIKit

/// 用于缓存主机配件操作需要的信息
class DinNovaPluginOperationInfoHolder: NSObject {
    /// 设置新配件的message id
    var setNameMID: String?
    /// 设置新配件的绕开规则
    var configBlockMID: String?
    /// 设置门磁推送状态
    var setDoorWindowPushStatusMID: String?
    /// 设置新配件的绕开规则
    var deletPluginMID: String?
    /// 设置智能插座开关
    var enablePluginMID: String?
    /// 获取配件详细信息
    var getPluginDetailMID: String?
    /// 删除配件绑定信息
    var deletePlugBindConfigMID: String?
    /// 设置配件绑定信息
    var updatePlugBindConfigMID: String?
    /// 测试警笛
    var testSirenMID: String?
    /// 设置警笛
    var setSirenMID: String?
    /// 设置ASK警笛
    var setASKSirenMID: String?
    /// 删除遥控绑定详细信息
    var deleteRemoteControlConfigMID: String?
    /// 设置遥控绑定详细信息
    var updateRemoteControlConfigMID: String?
    /// 操作继电器
    var relayActionMID: String?
    /// 临时屏蔽红外触发
    var byPassPlugin5MinMID: String?
    /// 设置红外灵敏度设置模式
    var setSensitivityMID: String?
    /// 退出红外设置模式
    var exitPIRSettingModeMID: String?
}
