//
//  DinStorageBatteryControl+UpdateInfo.swift
//  DinCore
//
//  Created by Jin on 2023/1/5.
//

import Foundation

extension DinStorageBatteryControl {
    func updateInfoDict(complete: (()->())?) {
        DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.updateName(self.model.name, usingSync: true, complete: nil)
            self.updateNetworkState(self.model.networkState, usingSync: true, complete: nil)
            self.updateInverterBatteryExceptions(self.model.vertBatteryExceptions, usingSync: true, complete: nil)
            self.updateInverterExceptions(self.model.vertExceptions, usingSync: true, complete: nil)
            self.updateInverterGridExceptions(self.model.vertGridExceptions, usingSync: true, complete: nil)
            self.updateInverterSystemExceptions(self.model.vertSystemExceptions, usingSync: true, complete: nil)
            self.updateInverterMPPTExceptions(self.model.vertMPPTExceptions, usingSync: true, complete: nil)
            self.updateInverterPresentExceptions(self.model.vertPresentExceptions, usingSync: true, complete: nil)
            self.updateInverterDCExceptions(self.model.vertDCExceptions, usingSync: true, complete: nil)
            self.updateEVExceptions(self.model.evExceptions, usingSync: true, complete: nil)
            self.updateMPPTExceptions(self.model.mpptExceptions, usingSync: true, complete: nil)
            self.updateCabinetExceptions(self.model.cabinetExceptions, usingSync: true, complete: nil)
            self.updateBatteryExceptions(self.model.batteryExceptions, usingSync: true, complete: nil)
            self.updateSystemExceptions(self.model.systemExceptions, usingSync: true, complete: nil)
            self.updateCommunicationExceptions(self.model.communicationExceptions, usingSync: true, complete: nil)
            self.updateChipsStatus(self.model.chipsStatus, usingSync: true, complete: nil)
            self.updateThirdPartyPVOn(self.model.thirdpartyPVOn, usingSync: true, complete: nil)
            self.updateVertState(self.model.vertState, usingSync: true, complete: nil)
            self.updateIotVersion(self.model.iotVersion, iotRealVersion: self.model.iotRealVersion, usingSync: true, complete: nil)
            self.updateCountryCode(self.model.countryCode, usingSync: true, complete: nil)
            self.updateDeliveryArea(self.model.deliveryArea, usingSync: true, complete: nil)
            self.updateGridStatus(self.model.gridStatus, usingSync: true, complete: nil)
            self.updateIsDeleted(self.model.isDeleted, usingSync: true, complete: nil)
            self.updateRegulateFrequencyState(self.model.regulateFrequencyState, usingSync: true, complete: nil)
            self.updatePVSupplyCustomizationSupported(self.model.pvSupplyCustomizationSupported, self.model.isPeakShavingSupported, usingSync: true, complete: nil)

            DispatchQueue.global().async {
                complete?()
            }
        }
    }
}

extension DinStorageBatteryControl {
    func updateLocal(dict: [String: Any], usingSync sync: Bool, complete: (()->())?) {
        if sync {
            if let name = dict["name"] as? String {
                self.model.name = name
                self.updateName(name, usingSync: true, complete: nil)
            }
            if let endID = dict["end_id"] as? String {
                self.model.uniqueID = endID
            }
            if let groupID = dict["group_id"] as? String {
                self.model.groupID = groupID
            }
            if let addtime = dict["addtime"] as? Int64 {
                self.model.addtime = addtime
                self.updateAddtime(addtime, usingSync: true, complete: nil)
            }
            if let countryCode = dict["country_code"] as? String {
                self.model.countryCode = countryCode
                self.updateCountryCode(countryCode, usingSync: true, complete: nil)
            }
            if let deliveryArea = dict["delivery_area"] as? String {
                self.model.deliveryArea = deliveryArea
                self.updateDeliveryArea(deliveryArea, usingSync: true, complete: nil)
            }
            // id和model不需要处理
            // let id = dict["id"] as? String,
            // let model = dict["model"] as? String,
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }

                if let name = dict["name"] as? String {
                    self.model.name = name
                    self.updateName(name, usingSync: true, complete: nil)
                }
                if let endID = dict["end_id"] as? String {
                    self.model.uniqueID = endID
                }
                if let groupID = dict["group_id"] as? String {
                    self.model.groupID = groupID
                }
                if let addtime = dict["addtime"] as? Int64 {
                    self.model.addtime = addtime
                    self.updateAddtime(addtime, usingSync: true, complete: nil)
                }
                if let countryCode = dict["country_code"] as? String {
                    self.model.countryCode = countryCode
                    self.updateCountryCode(countryCode, usingSync: true, complete: nil)
                }
                if let deliveryArea = dict["delivery_area"] as? String {
                    self.model.deliveryArea = deliveryArea
                    self.updateDeliveryArea(deliveryArea, usingSync: true, complete: nil)
                }
                // id和model不需要处理
                // let id = dict["id"] as? String,
                // let model = dict["model"] as? String,

                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func setIsDeleted(_ isDeleted: Bool, usingSync sync: Bool, complete: (() -> ())?) {
        updateIsDeleted(isDeleted, usingSync: sync, complete: complete)
    }
}

extension DinStorageBatteryControl {
    func updateNetworkState(_ state: DinStorageBattery.NetworkState, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.networkState = state
            unsafeInfo["networkState"] = state.rawValue
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.networkState = state
                self.unsafeInfo["networkState"] = state.rawValue
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateName(_ name: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.name = name
            unsafeInfo["name"] = name
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.name = name
                self.unsafeInfo["name"] = name
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateInverterAllExceptions(dict: [String: Any], usingSync sync: Bool, complete: (()->())?) {
        let vertBatteryExceptions = dict["vertBatteryExceptions"] as? [Int] ?? []
        let vertExceptions = dict["vertExceptions"] as? [Int] ?? []
        let vertGridExceptions = dict["vertGridExceptions"] as? [Int] ?? []
        
        let vertSystemExceptions = dict["vertSystemExceptions"] as? [Int] ?? []
        let vertmpptExceptions = dict["vertmpptExceptions"] as? [Int] ?? []
        let vertPresentExceptions = dict["vertPresentExceptions"] as? [Int] ?? []
        let vertDCExceptions = dict["vertDCExceptions"] as? [Int] ?? []
        if sync {
            model.vertBatteryExceptions = vertBatteryExceptions
            unsafeInfo["vertBatteryExceptions"] = vertBatteryExceptions
            model.vertExceptions = vertExceptions
            unsafeInfo["vertExceptions"] = vertExceptions
            model.vertGridExceptions = vertGridExceptions
            unsafeInfo["vertGridExceptions"] = vertGridExceptions
            model.vertSystemExceptions = vertSystemExceptions
            unsafeInfo["vertSystemExceptions"] = vertSystemExceptions
            model.vertMPPTExceptions = vertmpptExceptions
            unsafeInfo["vertmpptExceptions"] = vertmpptExceptions
            model.vertPresentExceptions = vertPresentExceptions
            unsafeInfo["vertPresentExceptions"] = vertPresentExceptions
            model.vertDCExceptions = vertDCExceptions
            unsafeInfo["vertDCExceptions"] = vertDCExceptions
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.vertBatteryExceptions = vertBatteryExceptions
                self.unsafeInfo["vertBatteryExceptions"] = vertBatteryExceptions
                self.model.vertExceptions = vertExceptions
                self.unsafeInfo["vertExceptions"] = vertExceptions
                self.model.vertGridExceptions = vertGridExceptions
                self.unsafeInfo["vertGridExceptions"] = vertGridExceptions
                self.model.vertSystemExceptions = vertSystemExceptions
                self.unsafeInfo["vertSystemExceptions"] = vertSystemExceptions
                self.model.vertMPPTExceptions = vertmpptExceptions
                self.unsafeInfo["vertmpptExceptions"] = vertmpptExceptions
                self.model.vertPresentExceptions = vertPresentExceptions
                self.unsafeInfo["vertPresentExceptions"] = vertPresentExceptions
                self.model.vertDCExceptions = vertDCExceptions
                self.unsafeInfo["vertDCExceptions"] = vertDCExceptions
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateInverterBatteryExceptions(_ exceptions: [Int], usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.vertBatteryExceptions = exceptions
            unsafeInfo["vertBatteryExceptions"] = exceptions
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.vertBatteryExceptions = exceptions
                self.unsafeInfo["vertBatteryExceptions"] = exceptions
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateInverterExceptions(_ exceptions: [Int], usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.vertExceptions = exceptions
            unsafeInfo["vertExceptions"] = exceptions
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.vertExceptions = exceptions
                self.unsafeInfo["vertExceptions"] = exceptions
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateInverterGridExceptions(_ exceptions: [Int], usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.vertGridExceptions = exceptions
            unsafeInfo["vertGridExceptions"] = exceptions
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.vertGridExceptions = exceptions
                self.unsafeInfo["vertGridExceptions"] = exceptions
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateInverterSystemExceptions(_ exceptions: [Int], usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.vertSystemExceptions = exceptions
            unsafeInfo["vertSystemExceptions"] = exceptions
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.vertSystemExceptions = exceptions
                self.unsafeInfo["vertSystemExceptions"] = exceptions
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateInverterMPPTExceptions(_ exceptions: [Int], usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.vertMPPTExceptions = exceptions
            unsafeInfo["vertmpptExceptions"] = exceptions
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.vertMPPTExceptions = exceptions
                self.unsafeInfo["vertmpptExceptions"] = exceptions
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateInverterPresentExceptions(_ exceptions: [Int], usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.vertPresentExceptions = exceptions
            unsafeInfo["vertPresentExceptions"] = exceptions
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.vertPresentExceptions = exceptions
                self.unsafeInfo["vertPresentExceptions"] = exceptions
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateInverterDCExceptions(_ exceptions: [Int], usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.vertDCExceptions = exceptions
            unsafeInfo["vertDCExceptions"] = exceptions
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.vertDCExceptions = exceptions
                self.unsafeInfo["vertDCExceptions"] = exceptions
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateEVExceptions(_ evExceptions: [Int], usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.evExceptions = evExceptions
            unsafeInfo["evExceptions"] = evExceptions
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.evExceptions = evExceptions
                self.unsafeInfo["evExceptions"] = evExceptions
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateMPPTExceptions(_ mpptExceptions: [Int], usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.mpptExceptions = mpptExceptions
            unsafeInfo["mpptExceptions"] = mpptExceptions
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.mpptExceptions = mpptExceptions
                self.unsafeInfo["mpptExceptions"] = mpptExceptions
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateCabinetExceptions(_ cabinetExceptions: [Int], usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.cabinetExceptions = cabinetExceptions
            unsafeInfo["cabinetExceptions"] = cabinetExceptions
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.cabinetExceptions = cabinetExceptions
                self.unsafeInfo["cabinetExceptions"] = cabinetExceptions
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateBatteryExceptions(_ batteryExceptions: [Int], usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.batteryExceptions = batteryExceptions
            unsafeInfo["batteryExceptions"] = batteryExceptions
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.batteryExceptions = batteryExceptions
                self.unsafeInfo["batteryExceptions"] = batteryExceptions
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateSystemExceptions(_ systemExceptions: [Int], usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.systemExceptions = systemExceptions
            unsafeInfo["systemExceptions"] = systemExceptions
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.systemExceptions = systemExceptions
                self.unsafeInfo["systemExceptions"] = systemExceptions
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }

    func updateCommunicationExceptions(_ communicationExceptions: [Int], usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.communicationExceptions = communicationExceptions
            unsafeInfo["communicationExceptions"] = communicationExceptions
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.communicationExceptions = communicationExceptions
                self.unsafeInfo["communicationExceptions"] = communicationExceptions
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateAddtime(_ addtime: Int64, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.addtime = addtime
            unsafeInfo["addtime"] = addtime
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.addtime = addtime
                self.unsafeInfo["addtime"] = addtime
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateIsDeleted(_ isDeleted: Bool, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.isDeleted = isDeleted
            unsafeInfo["isDeleted"] = isDeleted
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.isDeleted = isDeleted
                self.unsafeInfo["isDeleted"] = isDeleted
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateChipsStatus(_ chipsStatus: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.chipsStatus = chipsStatus
            unsafeInfo["chipsStatus"] = chipsStatus
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.chipsStatus = chipsStatus
                self.unsafeInfo["chipsStatus"] = chipsStatus
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateThirdPartyPVOn(_ isOn: Bool, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.thirdpartyPVOn = isOn
            unsafeInfo["thirdpartyPVOn"] = isOn
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.thirdpartyPVOn = isOn
                self.unsafeInfo["thirdpartyPVOn"] = isOn
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateVertState(_ vertState: [Int], usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.vertState = vertState
            unsafeInfo["vertState"] = vertState
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.vertState = vertState
                self.unsafeInfo["vertState"] = vertState
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateVertState(_ indexState: Int, at index: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            guard index >= 0 && index < model.vertState.count else { return }
            model.vertState[index] = indexState
            unsafeInfo["vertState"] = model.vertState
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                guard index >= 0 && index < model.vertState.count else { return }
                self.model.vertState[index] = indexState
                self.unsafeInfo["vertState"] = model.vertState
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateIotVersion(_ iotVersion: String, iotRealVersion: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.iotVersion = iotVersion
            unsafeInfo["iotVersion"] = iotVersion
            unsafeInfo["iotRealVersion"] = iotRealVersion
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.iotVersion = iotVersion
                self.unsafeInfo["iotVersion"] = iotVersion
                self.unsafeInfo["iotRealVersion"] = iotRealVersion
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateCountryCode(_ countryCode: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.countryCode = countryCode
            unsafeInfo["countryCode"] = countryCode
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.countryCode = countryCode
                self.unsafeInfo["countryCode"] = countryCode
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateDeliveryArea(_ deliveryArea: String, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.deliveryArea = deliveryArea
            unsafeInfo["deliveryArea"] = deliveryArea
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.deliveryArea = deliveryArea
                self.unsafeInfo["deliveryArea"] = deliveryArea
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateGridStatus(_ gridStatus: DinStorageBattery.GridStatus, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.gridStatus = gridStatus
            unsafeInfo["gridStatus"] = gridStatus.rawValue
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.gridStatus = gridStatus
                self.unsafeInfo["gridStatus"] = gridStatus.rawValue
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateRegulateFrequencyState(_ regulateFrequencyState: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.regulateFrequencyState = regulateFrequencyState
            unsafeInfo["regulateFrequencyState"] = regulateFrequencyState
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.regulateFrequencyState = regulateFrequencyState
                self.unsafeInfo["regulateFrequencyState"] = regulateFrequencyState
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updateAIModeSettings(_ aiSmart: Int, _ aiEmergency: Int, usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.aiSmart = aiSmart
            model.aiEmergency = aiEmergency
            unsafeInfo["aiSmart"] = aiSmart
            unsafeInfo["aiEmergency"] = aiEmergency
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.aiSmart = aiSmart
                self.model.aiEmergency = aiEmergency
                self.unsafeInfo["aiSmart"] = aiSmart
                self.unsafeInfo["aiEmergency"] = aiEmergency
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
    
    func updatePVSupplyCustomizationSupported(_ isPVSupported: Bool, _ isPKSupported: Bool,usingSync sync: Bool, complete: (()->())?) {
        if sync {
            model.pvSupplyCustomizationSupported = isPVSupported
            model.isPeakShavingSupported = isPKSupported
            unsafeInfo["pvSupplyCustomizationSupported"] = isPVSupported
            unsafeInfo["peakShavingSupported"] = isPKSupported
        } else {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.model.pvSupplyCustomizationSupported = isPVSupported
                self.model.isPeakShavingSupported = isPKSupported
                self.unsafeInfo["pvSupplyCustomizationSupported"] = isPVSupported
                self.unsafeInfo["peakShavingSupported"] = isPKSupported
                DispatchQueue.global().async {
                    complete?()
                }
            }
        }
    }
}
