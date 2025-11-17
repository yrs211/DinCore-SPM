//
//  DinNovaPluginOperator.swift
//  DinCore
//
//  Created by Jin on 2021/5/26.
//

import UIKit
import RxSwift
import RxRelay

class DinNovaPluginOperator: NSObject, DinHomeDeviceProtocol {

    var id: String {
        pluginControl.plugin.id
    }

    var manageTypeID: String {
        category + pluginControl.plugin.subCategory
    }

    var category: String {
        String(pluginControl.plugin.category)
    }

    var subCategory: String {
        pluginControl.plugin.subCategory
    }

    var info: [String : Any] {
        pluginControl.infoDict
    }

    var fatherID: String? {
        pluginControl.panelID
    }

    // MARK: - 配件（主动操作/第三方操作）数据通知
    var deviceCallback: Observable<[String : Any]> {
        return pluginControl.deviceCallback
    }

    // MARK: - 配件在线状态通知
    var deviceStatusCallback: Observable<Bool> {
        pluginControl.deviceStatusCallback
    }

    var saveJsonString: String {
        pluginControl.plugin.toJSONString() ?? ""
    }

    func submitData(_ data: [String : Any]) {
        pluginControl.operateData(data)
    }

    func destory() {
        //
    }

    /// nova系列配件控制器
    let pluginControl: DinNovaPluginControl
    /// 配件操作类
    /// - Parameter plugin: nova系列配件
    init(withPluginControl pluginControl: DinNovaPluginControl) {
        self.pluginControl = pluginControl
        super.init()
    }
}
