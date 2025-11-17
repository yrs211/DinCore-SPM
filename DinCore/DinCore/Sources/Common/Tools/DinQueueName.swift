//
//  DinQueueName.swift
//  DinCore
//
//  Created by Jin on 2021/4/20.
//

import Foundation

struct DinQueueName {
    /// App的一些本地化数据库异步保存线程
    static let appDataSave = "com.dinsafer.dincore.queue.appDataSave"
    /// User里面的CurHome获取
    static let getHome = "com.dinsafer.dincore.queue.getuserhome"
    static let getHomeInfo = "com.dinsafer.dincore.queue.getuserhomeinfo"
    /// 家庭设备同步数据独占线程
    /// 在多线程读写的情况下，家庭设备的某些属性会有数据竞争的问题，全局新建一个线程来保证读写安全。
    static let homeDeviceDataSync = "com.dinsafer.dincore.queue.device.dataSync"
    /// 家庭设备数组独占线程
    /// 在多线程读写的情况下，家庭设备数组会有数据竞争的问题，全局新建一个线程来保证读写安全。
    static let homeDevicesSync = "com.dinsafer.dincore.queue.devicesSync"
    /// App的UDP代理模式通信用到的并行收发线程【代理模式】
    static let systemProxyDeliver = "com.dinsafer.dincore.queue.systemProxyDeliver"
    /// 家庭里面的设备列表显示管理
    static let homeDevicesManage = "com.dinsafer.dincore.queue.homeDevicesManage"
    /// 家庭里面的设备列表缓存
    static let homeDevicesCache = "com.dinsafer.dincore.queue.homeDevicesCache"
    /// 设备数据提交线程
    static let deviceAcceptData = "com.dinsafer.dincore.queue.device.dataAccepct"
    /// 自研IPC发送语音线程
    static let cameraSendVoiceData = "com.dinsafer.dincore.queue.camera.sendvoicedata"
    /// 自研IPC建立KcpObject线程
    static let cameraKcpCreation = "com.dinsafer.dincore.queue.camera.kcpcreation"
    /// 自研IPC下载文件独占线程
    static let cameraDowload = "com.dinsafer.dincore.queue.camera.kcpdownload"
    /* ⚠️ Synchronization anomaly was detected.
     > Debugging: To debug this issue you can set a breakpoint in /Users/jin/Documents/HelioPro/Pods/RxSwift/RxSwift/Rx.swift:112 and observe the call stack.
     > Problem: This behavior is breaking the observable sequence grammar. `next (error | completed)?`
       This behavior breaks the grammar because there is overlapping between sequence events.
       Observable sequence is trying to send an event before sending of previous event has finished.
     > Interpretation: Two different unsynchronized threads are trying to send some event simultaneously.
       This is undefined behavior because the ordering of the effects caused by these events is nondeterministic and depends on the
       operating system thread scheduler. This will result in a random behavior of your program.
     > Remedy: If this is the expected behavior this message can be suppressed by adding `.observe(on:MainScheduler.asyncInstance)`
       or by synchronizing sequence events in some other way. */
    /// 在多线程下，并发提交RX会有问题的，这个queue是串行的全局子线程，可用于规范RX的并发提交问题
    static let serialQueueForRX = "com.dinsafer.dincore.queue.rx.accept"
    /// 自研IPC发送语音线程
    static let cameraSubmitCMDData = "com.dinsafer.dincore.queue.camera.submitCMDData"
}
