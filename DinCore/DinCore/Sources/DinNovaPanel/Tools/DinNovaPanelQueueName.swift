//
//  DinNovaPanelQueueName.swift
//  DinCore
//
//  Created by Jin on 2021/5/14.
//

import Foundation

struct DinNovaPanelQueueName {
    /// nova系列主机操作超时检查线程
    static let novaPanelTimeoutChecker = "com.dinsafer.queue.novapanel.operation.timeout"
    /// nova系列主机websocket pingpong 线程
    static let wsPingQueue = "com.dinsafer.queue.novapanel.wsPingQueue"
}
