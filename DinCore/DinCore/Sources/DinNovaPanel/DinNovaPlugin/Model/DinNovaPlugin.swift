//
//  DinNovaPlugin.swift
//  DinCore
//
//  Created by Jin on 2021/5/26.
//

import UIKit
import HandyJSON
import RxSwift
import RxRelay
import DinSupport

/// 配件基础类
class DinNovaPlugin: DinModel {
    /// 配件ID
    var id: String = ""
    /// 配件名字
    var name: String = ""
    /// 配件大类
    var category: Int = 0
    /// 配件小类
    var subCategory: String = ""
    /// decodeID, 用来解码的id
    var decodeID: String = ""
    /// 新配件的data信息
    var askData: [String: Any]?
    // 是否在线
    var isOnline: Bool = true
    // 是否删除
    var isDeleted: Bool = false
    // 添加时间
    var addtime: Int64 = 0
    var canDetectOnline: Bool {
        self.askData != nil
    }

    override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)

        mapper <<< self.subCategory <-- ["subcategory", "stype", "sub_category", "plugin_item_sub_category"]
        mapper <<< self.decodeID <-- "decodeid"
        mapper <<< self.category <-- "dtype"
        mapper <<< self.isOnline <-- ["keeplive", "online"]
        mapper <<< self.addtime <-- ["add_time", "time"]
    }

    override func didFinishMapping() {
        super.didFinishMapping()
        // 如果服务器没有返回小类，试着解码
        if subCategory.count < 1 {
            if decodeID.count == 11 || decodeID.count == 15 {
                // 检查小Type
                let sTypeID = decodeID[1...2]
                if DinAccessory.checkStype(sTypeID) {
                    subCategory = sTypeID
                }
            }
        }
    }

    /// 判断是否是NewAsk配件
    func checkIsASKPlugin() -> Bool {
        DinAccessory.pluginID(isASKPlugin: id, decodeID: decodeID)
    }
}
