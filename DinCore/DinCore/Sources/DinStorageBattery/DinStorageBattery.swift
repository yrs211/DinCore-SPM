//
//  DinStorageBattery.swift
//  DinCore
//
//  Created by monsoir on 11/28/22.
//

import Foundation
import DinSupport
import HandyJSON

class DinStorageBattery: DinModel, DinCommunicationDevice {

      ///分类id
    ///静态方法给子类集成区分不同设备类型
    class var categoryID: String { "" }

    ///提供者
    class var provider: String { "" }

    var deviceID: String { id }

    var id: String = ""

    var name: String = ""

    var model: String = ""

    var uniqueID: String = ""

    var groupID: String = ""

    var token: String = ""

    var area: String = ""

    var lanAddress: String = ""

    var lanPort: UInt16 = 0

    var addtime: Int64 = 0
    
    var isDeleted: Bool = false

    var networkState: NetworkState = .offline
    
    var chipsStatus: Int = 0
    
    var thirdpartyPVOn: Bool = false
    
    // ⚠️ 每次创建时 vertState 字段都将被重置为 [2, 2, 2]。具体实现请参考 mapping 函数的代码
    var vertState: [Int] = [2, 2, 2]
    
    var iotVersion: String = ""
    
    var iotRealVersion: String = ""
    
    var countryCode: String = ""
    
    var deliveryArea: String = ""
    
    var vertBatteryExceptions: [Int] = []

    var vertExceptions: [Int] = []
    
    var vertGridExceptions: [Int] = []
    
    var vertSystemExceptions: [Int] = []
    
    var vertMPPTExceptions: [Int] = []
    
    var vertPresentExceptions: [Int] = []
    
    var vertDCExceptions: [Int] = []

    var evExceptions: [Int] = []

    var mpptExceptions: [Int] = []

    var cabinetExceptions: [Int] = []

    var batteryExceptions: [Int] = []

    var systemExceptions: [Int] = []

    var communicationExceptions: [Int] = []
    
    var gridStatus: GridStatus = .unknown
    
    var regulateFrequencyState: Int = 0
    
    var aiSmart: Int = 0
    
    var aiEmergency: Int = 0
    
    var pvSupplyCustomizationSupported: Bool = false
    
    var isPeakShavingSupported: Bool = false

    init?(homeID: String, rawString: String) {
        super.init()
    }

    public required override init() {}

    override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)

        mapper <<< self.groupID <-- "group_id"
        mapper <<< self.uniqueID <-- "end_id"
        mapper <<< self.lanAddress <-- "addr"
        mapper <<< self.countryCode <-- "country_code"
        mapper <<< self.deliveryArea <-- "delivery_area"
        // 缓存的时候排除的属性
        mapper >>> self.gridStatus
        mapper >>> self.vertState
    }
}

extension DinStorageBattery {
    enum NetworkState: Int {
        case offline = -1
        case connecting = 0
        case online = 1
    }
    
    enum GridStatus: Int {
        case unknown = 0
        case offGrid = 1   // 离网
        case onGrid = 2    // 并网
    }
}
