//
//  DinChannelKcpOperation.swift
//  DinCore
//
//  Created by Jin on 2021/7/1.
//

import UIKit
import DinSupport

class DinChannelKcpOperation: NSObject {

    var timeoutTimer: DinGCDTimer?
    let timeoutSec: Int
    let timeoutBlock: ((String) -> Void)?
    let cmd: String

    init?(withCMD cmd: String, timeoutSec: Int = 10, timeoutBlock: ((String) -> Void)?) {
        guard cmd.count > 0 else {
            return nil
        }
        self.cmd = cmd
        self.timeoutSec = timeoutSec
        self.timeoutBlock = timeoutBlock
        super.init()
        startTimer()
    }

    func stop() {
        stopTimer()
    }

    private func startTimer() {
        let timer = DinGCDTimer(
            timerInterval: .seconds(Double(timeoutSec)),
            isRepeat: false,
            executeBlock: { [weak self] in
                self?.timeoutBlock?(self?.cmd ?? "")
                self?.stop()
            },
            queue: .main
        )
        timeoutTimer = timer
    }

    private func stopTimer() {
        timeoutTimer = nil
    }
}
