//
//  DinEventBusStorageBattery.swift
//  DinCore
//
//  Created by monsoir on 11/29/22.
//

import Foundation
import RxSwift
import RxRelay

final
public class DinEventBusStorageBattery {

    /// 更新完IPC的局域网模型之后，提交IPC的id通知上层更新
    var lanIPReceivedObservable: Observable<String> { lanIPReceived.asObservable() }

    private let lanIPReceived = PublishRelay<String>()

    /// 主机收到数据后，处理成字典模型返回
    /// - Parameter info: 结果
    func accept(lanIPReceived deviceID: String) {
        lanIPReceived.accept(deviceID)
    }
}
