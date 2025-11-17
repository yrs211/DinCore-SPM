//
//  DinNovaPanelEventHandler.swift
//  DinCore
//
//  Created by Jin on 2021/5/13.
//

import UIKit
import RxSwift
import RxRelay

public class DinNovaPanelEventHandler: NSObject {
    /// 事件
    private var operationEvents: [DinNovaPanelEvent] = []

    var eventCount: Int {
        operationEvents.count
    }

    let timeout: Int = 20
    static private let interval = 500

    // MARK: - 操作超时
    var operationTimeoutObservable: Observable<DinNovaPanelEvent> {
        return operationTimeout.asObservable()
    }
    private let operationTimeout = PublishRelay<DinNovaPanelEvent>()
    /// 操作超时
    /// - Parameter event: 操作信息模型
    func accept(operationTimeout event: DinNovaPanelEvent) {
        operationTimeout.accept(event)
    }

    /// 事件序列，每隔interval秒发送一次通知
    private let eventSequence = Observable<Int>.interval(.milliseconds(interval),
                                                         scheduler: SerialDispatchQueueScheduler(internalSerialQueueName: DinNovaPanelQueueName.novaPanelTimeoutChecker))
    func start() {
        // 每隔interval秒检查一次eventQueue
        _ = eventSequence.subscribe(onNext: { [weak self] (_) in
            DispatchQueue.main.async { [weak self] in
//                // 是否还有请求未发送，有则发送并将请求并移出队列
//                if requests.count > 0 {
//                    guard App.socket.isConnected else {
//                        return
//                    }
//                    let action = requests.first!
//                    action()
//                    _ = requests.remove(at: 0)
//                }

                guard let self = self else { return }

                // 是否还有事件未处理完，超过timeout值，当失败处理，将事件移出队列
                if self.operationEvents.count > 0 {
                    for i in 0 ..< self.operationEvents.count {
                        let event = self.operationEvents[i]
                        let now = Int(Date().timeIntervalSince1970)
                        let eventTime = Int(event.time.int64Value/1000000000)
                        if now - eventTime > self.timeout {
                            self.operationEvents.remove(at: i)
                            self.accept(operationTimeout: event)
                            break
                        }
                    }
                }
            }
        })
    }

    func enter(_ event: DinNovaPanelEvent) {
        operationEvents.append(event)
    }

    func removeEvent(id: String) {
        if operationEvents.count > 0 {
            for i in 0 ..< operationEvents.count {
                let event = operationEvents[i]
                if event.id == id {
                    operationEvents.remove(at: i)
                    break
                }
            }
        }
    }

    func removeAllEvent() {
        for event in operationEvents {
            event.retry = 3
        }
        operationEvents.removeAll()
    }

    func checkArmEvent(eventID: String?) -> Bool {
        var eventExist = false
        if operationEvents.count > 0 {
            for event in operationEvents {
                if event.cmd == DinNovaPanelCommand.arm.rawValue || event.cmd == DinNovaPanelCommand.disarm.rawValue || event.cmd == DinNovaPanelCommand.homeArm.rawValue {
                    if eventID != nil {
                        if event.id != eventID! {
                            eventExist = true
                            break
                        }
                    } else {
                        eventExist = true
                        break
                    }
                }
            }
        }
        return eventExist
    }
}
