//
//  Command.swift
//  DinCore
//
//  Created by Monsoir on 2022/12/14.
//

import Foundation

protocol Command {
    var rawValue: String { get }
}

protocol MSCTCommand: Command {}

protocol HTTPCommand: Command {}
