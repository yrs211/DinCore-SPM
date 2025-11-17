//
//  DinHomeDeviceProtocol.swift
//  DinCore
//
//  Created by Jin on 2021/5/12.
//

import UIKit
import RxSwift
import RxRelay

public protocol DinHomeDeviceProtocol: NSObjectProtocol {
    /// 设备ID
    var id: String { get }
    /// 供管理的统一类别ID
    var manageTypeID: String { get }
    /// 大类
    var category: String { get }
    /// 小类
    var subCategory: String { get }
    /// 设备信息字典 只显示需要UI的信息
    /// 在多线程读写的情况下，Info属性会有数据竞争的问题，全局新建一个线程来保证读写安全。
    var info: [String: Any] { get }
    /// 需要服从的设备id (例如主机包含配件，配件的fatherID就是主机ID)
    var fatherID: String? { get }
    /// 操作结果回调
    var deviceCallback: Observable<[String: Any]> { get }
    /// 状态回调
    var deviceStatusCallback: Observable<Bool> { get }
    /// 供存储对应的字符串（JsonString），用于模型转换
    var saveJsonString: String { get }

    /// 操作，更新数据, 操作的结果从deviceCallback回调
    /// - Parameter data: 需要的参数，实现者自己定义
    func submitData(_ data: [String: Any])

    /// 关闭
    func destory()
}

