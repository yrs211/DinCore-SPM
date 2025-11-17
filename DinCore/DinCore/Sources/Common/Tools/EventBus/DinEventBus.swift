//
//  DinEventBus.swift
//  DinCore
//
//  Created by Jin on 2021/5/7.
//

import UIKit
import RxSwift
import RxRelay

/// 通过RXSwift 实现向上通知（Notification）
public class DinEventBus: NSObject {
    static let rxSerialQueue = DispatchQueue.init(label: DinQueueName.serialQueueForRX)
    // 基础信息的通知
    // 这里不能public，涉及到敏感信息，注意不要乱public出去
    let basic = DinEventBusBasic()
    // 摄像头通知
    let camera = DinEventBusCamera()

    let storageBattery  = DinEventBusStorageBattery()
}
