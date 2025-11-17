//
//  CommandRequestFailure.swift
//  DinCore
//
//  Created by Monsoir on 2022/12/14.
//

import Foundation

protocol CommandExecutionFailure: Swift.Error {
    var command: Command { get }
    var result: [String: Any] { get }
}

/// 客户端 MSCT 命令请求参数错误
struct MSCTCommandBadRequestFailure: CommandExecutionFailure {

    let command: Command

    init(command: MSCTCommand) {
        self.command = command
    }

    var result: [String: Any] {
        [
            "cmd": command.rawValue,
            "owned": true,
            "status": 0,
            "errorMsg": "bad request"
        ]
    }
}

/// 客户端 MSCT 连接不可用错误 - 设备离线或正在连接中
struct MSCTConnectionUnavailableFailure: CommandExecutionFailure {

    let command: Command

    init(command: MSCTCommand) {
        self.command = command
    }

    var result: [String: Any] {
        [
            "cmd": command.rawValue,
            "owned": true,
            "status": 0,
            "errorMsg": "connection unavailable due to device being offline or in connection process"
        ]
    }
}

/// 客户端 HTTP 命令请求参数错误
struct HTTPCommandBadRequestFailure: CommandExecutionFailure {

    let command: Command

    init(command: HTTPCommand) {
        self.command = command
    }

    var result: [String: Any] {
        [
            "cmd": command.rawValue,
            "owned": true,
            "status": 0,
            "errorMsg": "bad request",
        ]
    }
}

/// 服务端 HTTP 命令执行错误
struct HTTPCommandInternalFailure: CommandExecutionFailure {

    let command: Command
    let error: Swift.Error
    let status: Int

    init(command: HTTPCommand, error: Swift.Error) {
        self.command = command
        self.error = error
        self.status = (error as? DinNetwork.Error)?.errorCode ?? 0
    }

    var result: [String: Any] {
        [
            "cmd": command.rawValue,
            "owned": true,
            "status": status,
            "errorMsg": error.localizedDescription,
        ]
    }
}
