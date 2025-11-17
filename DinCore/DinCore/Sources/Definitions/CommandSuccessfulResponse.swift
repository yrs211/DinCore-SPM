//
//  CommandSuccessfulResponse.swift
//  DinCore
//
//  Created by Monsoir on 2022/12/14.
//

import Foundation

struct HTTPCommandSuccessfulResponse {
    let command: HTTPCommand
    let payload: [String: Any]

    var result: [String: Any] {
        [
            "cmd": command.rawValue,
            "owned": true, // http command is sure of being sent by owner
            "status": 1,
            "result": payload,
        ]
    }
}
