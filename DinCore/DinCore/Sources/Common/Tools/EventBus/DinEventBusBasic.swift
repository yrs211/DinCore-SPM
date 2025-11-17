//
//  DinEventBusBasic.swift
//  DinCore
//
//  Created by Jin on 2021/5/12.
//

import UIKit
import RxSwift
import RxRelay

class DinEventBusBasic: NSObject {
    /// DNS-iP检查通知
    /// 请求Http的时候，DNS模块检查ip之后，发出的通知
    /// 目前DinNovaPanel的websocket接收到通知会对比一下websocket的ip，如果不一样会重新连接
    var serverIPCheckedObservable: Observable<Any> {
        return serverIPChecked.asObservable()
    }
    private let serverIPChecked = PublishRelay<Any>()
    /// DNS-iP检查通知
    func accept(serverIPChecked info: Any) {
        serverIPChecked.accept(info)
    }

    /// DinCore的UDP对象被断开通知
    var udpSocketDisconnectObservable: Observable<Any> {
        return udpSocketDisconnect.asObservable()
    }
    private let udpSocketDisconnect = PublishRelay<Any>()

    /// DinCore的UDP对象被断开通知
    func accept(udpSocketDisconnect info: Any) {
        udpSocketDisconnect.accept(info)
    }


    /// 代理模式的Deliver改变了IP和Port
    var proxyDeliverChangedObservable: Observable<Any> {
        return proxyDeliverChanged.asObservable()
    }
    private let proxyDeliverChanged = PublishRelay<Any>()

    /// DinCore的UDP对象被断开通知
    func accept(proxyDeliverChanged info: Any) {
        proxyDeliverChanged.accept(info)
    }

}
