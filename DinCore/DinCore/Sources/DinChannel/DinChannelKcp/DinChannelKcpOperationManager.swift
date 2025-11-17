//
//  DinKcpChannelOperationManager.swift
//  DinCore
//
//  Created by Jin on 2021/7/1.
//

import UIKit

protocol DinChannelKcpOperationManagerDelegate: NSObjectProtocol {
    func operation(result: [String: Any])
    func operation(timeoutCMD: String)
}

class DinKcpChannelOperationManager: NSObject {
    weak var delegate: DinChannelKcpOperationManagerDelegate?
    /// 数据的读写队列
    private let queue = DispatchQueue(label: DinQueueName.cameraSubmitCMDData, attributes: .concurrent)

    /// operations数组【不能直接使用，需要搭配queue来读写以达到线程安全
    private var unsafeOperations: [String: DinChannelKcpOperation]? = [String: DinChannelKcpOperation]()
    var operations: [String: DinChannelKcpOperation]? {
        var copyOps: [String: DinChannelKcpOperation]?
        queue.sync { [weak self] in
            if let self = self {
                copyOps = self.unsafeOperations
            }
        }
        return copyOps
    }

    func startOperation(withCmd cmd: String, timeoutSec: Int = 10) {
        let operation = DinChannelKcpOperation(withCMD: cmd) { [weak self] cmd in
            self?.queue.async(flags: .barrier) { [weak self] in
                self?.unsafeOperations?.removeValue(forKey: cmd)
                self?.delegate?.operation(timeoutCMD: cmd)
            }
        }
        if let operation = operation {
            queue.async(flags: .barrier) { [weak self] in
                self?.unsafeOperations?[operation.cmd] = operation
            }
        }
    }

    func receiveOperationResult(_ result: [String: Any]) {
        guard let cmd = result["cmd"] as? String else {
            return
        }
        if let operation = operations?[cmd] {
            operation.stop()
            queue.async(flags: .barrier) { [weak self] in
                self?.unsafeOperations?.removeValue(forKey: cmd)
            }
        }
        // 不是自己的也可以收到
        delegate?.operation(result: result)
    }
}
