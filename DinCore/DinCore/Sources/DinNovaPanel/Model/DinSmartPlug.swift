//
//  DinSmartPlug.swift
//  DinCore
//
//  Created by Jin on 2021/5/7.
//

import UIKit
import HandyJSON
import DinSupport

public class DinSmartPlug: DinModel, DinHomeDeviceSelection, NSCopying {
    public var id = ""
    // 马甲配件，真的id
    public var decodeid: String = ""
    public var name = ""
    public var time: NSNumber = 0
    public var isEnabled = false
    public var isLoading = false
    public var decodeID = ""

    // 新型插座的数据
    public var askData: [String: Any]?
    public var category: Int?
    public var sendID = ""
    public var stype = ""

    // default selected to show
    public var isSelected: Bool = true
    public var isEditing: Bool = false

    public var tapable: Bool = true

    // default to online
    public var isOnline: Bool = true
    public var canDetectOnline: Bool {
        return DinAccessory.keepliveSmartPlugStypes.contains(stype)
    }

    // 是否是新型插座
    public var isNewAskPlug: Bool {
        return stype.count > 0
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let plug = DinSmartPlug()
        plug.id = self.id
        plug.decodeid = self.decodeid
        plug.name = self.name
        plug.time = self.time
        plug.isEnabled = self.isEnabled
        plug.isLoading = self.isLoading
        plug.askData = self.askData
        plug.category = self.category
        plug.sendID = self.sendID
        plug.stype = self.stype
        plug.isSelected = self.isSelected
        plug.isEditing = self.isEditing
        plug.isOnline = self.isOnline
        plug.tapable = self.tapable
        return plug
    }

    public override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)
        mapper <<<
            self.decodeID <-- "decodeid"
        mapper <<<
            self.isEnabled <-- ["enable","plugin_item_smart_plug_enable"]
        mapper <<<
            self.sendID <-- "sendid"
        mapper <<<
            self.isOnline <-- "keeplive"

// TODO: 这里是需要文案的，看看怎么处理
//        if (name.count == 0) && (stype.count > 0) {
//            name = "\(Accessory.getName(withTypeID: stype))_\(id)"
//        } else if name.count == 0 {
//            name = Accessory.getDefaultName(withID: id, orDecodeID: decodeID)
//        }
    }
}
