//
//  DinLearnModeWebSocketControl.swift
//  DinCore
//
//  Created by Jin on 2021/6/23.
//

import UIKit
import Starscream
import RxSwift
import RxRelay

class DinLearnModeWebSocketControl: NSObject {

    private var socket: WebSocket?

    var connectIP = "" {
        didSet {
            if connectIP.count > 0 {
                socket = WebSocket(url: URL(string: "ws://\(connectIP):1949/ws")!)
                configSocket()
            } else {
                disconnnect()
            }
        }
    }

    /// 触发配对数据通知
    var learnModeResultObservable: Observable<[String: Any]> {
        return learnModeResult.asObservable()
    }
    private let learnModeResult = PublishRelay<[String: Any]>()
    /// 触发配对数据通知
    /// - Parameter result: 结果
    func accept(learnModeResult result: [String: Any]) {
        learnModeResult.accept(result)
    }

    private func configSocket() {
        socket?.onConnect = { [weak self] in
            self?.accept(learnModeResult: ["cmd": "start_learnmode", "status": 1])
        }

        socket?.onDisconnect = { [weak self] (error) in
            self?.accept(learnModeResult: ["cmd": "start_learnmode", "status": 0])
        }

        socket?.onText = { [weak self] (text: String) in
            if text == "-1" {
                self?.accept(learnModeResult: ["cmd": DinNovaPanelControl.CMD_LEARNMODE_LISTEN, "status": -1])
            } else if text == "-50" {
                self?.accept(learnModeResult: ["cmd": DinNovaPanelControl.CMD_LEARNMODE_LISTEN, "status": -50])
            } else if text == "-3" {
                self?.accept(learnModeResult: ["cmd": DinNovaPanelControl.CMD_LEARNMODE_LISTEN, "status": -3])
            } else {
                self?.accept(learnModeResult: ["cmd": DinNovaPanelControl.CMD_LEARNMODE_LISTEN, "status": 1, "result": text])
            }
        }
        socket?.connect()
    }

    func connect(toIp ip: String) {
        connectIP = ip
    }

    func disconnnect() {
        if socket?.isConnected ?? false {
            socket?.disconnect()
        }
        socket = nil
        accept(learnModeResult: ["cmd": "stop_learnmode", "status": 1])
    }

    func startListen(toOfficial official: Bool) {
        if socket?.isConnected ?? false {
            socket?.write(string: "{\"cmd\":\"CMD_TRIGGERPAIR\", \"isofficial\":\(official)}")
        }
    }

}
