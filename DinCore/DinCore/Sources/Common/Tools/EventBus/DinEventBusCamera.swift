//
//  DinEventBusCamera.swift
//  DinCore
//
//  Created by Jin on 2021/8/25.
//

import Foundation
import RxSwift
import RxRelay

public class DinEventBusCamera: NSObject {

    /// 更新完IPC的局域网模型之后，提交IPC的id通知上层更新
    var cameraLanIPReceivedObservable: Observable<String> {
        return cameraLanIPReceived.asObservable()
    }
    private let cameraLanIPReceived = PublishRelay<String>()
    /// 主机收到数据后，处理成字典模型返回
    /// - Parameter info: 结果
    func accept(cameraLanIPReceived deviceID: String) {
        cameraLanIPReceived.accept(deviceID)
    }
}
