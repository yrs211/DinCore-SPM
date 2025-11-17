//
//  DinDelay.swift
//  DinCore
//
//  Created by Jin on 2021/5/13.
//

import Foundation

func delay(_ time: TimeInterval, task: @escaping ()->()) {
    let t = DispatchTime.now() + time
    DispatchQueue.main.asyncAfter(deadline: t, execute: task)
}
