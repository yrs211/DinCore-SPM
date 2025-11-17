//
//  DinDeviceScanner.swift
//  DinCore
//
//  Created by Jin on 2021/6/1.
//

import UIKit
import DinSupport

public enum QRCodeType: String {
    case familyInvitationCode = "familyInvitationCode"
    case newPluginCode = "newPluginCode"
    case oldPluginCode = "oldPluginCode"
    case cameraCode = "cameraCode"
    case dinCameraCode = "dinCameraCode"
    case dinCameraV006Code = "dinCameraCodeV006"
    case dinCameraV015Code = "dinCameraCodeV015"
    case dinStorageBattery5000Code = "dinStorageBattery5000"
    case dinStorageBatteryPowerCore20OR30Code = "dinStorageBatteryPowerCore20OR30Code"
    case dinStorageBatteryPowerStoreCode = "dinStorageBatteryPowerStoreCode"
    case dinStorageBatteryPowerStore20Code = "dinStorageBatteryPowerStore20Code"
    case dinStorageBatteryPowerPulseCode = "dinStorageBatteryPowerPulseCode"
    case panelCode = "panelCode"
    case videoDoorbellCode = "dsdoorbellCode"
}

public class DinDeviceScanner: NSObject {

    /// 对扫码的结果进行解析
    /// - Parameters:
    ///   - content: 扫码的结果
    ///   - complete: Any: 任何结果，Int: 状态码 1: 成功， 其他失败
    public func decodeQR(content: String, homeID: String, complete: ((Any?, Int) -> Void)?) {
        if content.starts(with: "Home_") {
            verifyHomeInvitationCode(code: content, complete: complete)
            return
        }

        if content.starts(with: "dscam_") {
            foundDinCameraCode(complete: complete)
            return
        }

        if content.starts(with: "dscamv006_") {
            foundDinCameraV006Code(complete: complete)
            return
        }
        
        if content.starts(with: "dscamv015_") {
            foundDinCameraV015Code(complete: complete)
            return
        }

        if content == "bmt_hp5000" {
            foundDinStorageBattery5000Code(complete: complete)
            return
        }
        
        if content == "PC1-BAK15-HS10" {
            foundDinStorageBatteryPowerCore20OR30Code(complete: complete)
            return
        }
        
        if content == "PS1-BAK10-HS10" {
            foundDinStorageBatteryPowerStoreCode(complete: complete)
            return
        }
        
        if content == "PS2-BAK10-HS10" {
            foundDinStorageBatteryPowerStore20Code(complete: complete)
            return
        }
        
        if content == "VB1-BAK5-HS10" {
            foundDinStorageBatteryPowerPulseCode(complete: complete)
            return
        }

        if content == "PSE1" {
            foundDinStorageBatteryPowerStoreCode(complete: complete)
            return
        }

        if content.count == 16 {
            foundPanelCode(complete: complete)
            return
        }

        if content[0...1] == "!I" {
            foundThirdPartyCameraCode(content: content, homeID: homeID, complete: complete)
            return
        }

        if content[0...0] == "!" {
            decodeNewQR(content: content, complete: complete)
            return
        }

        if content.starts(with: "dsdoorbell_") {
            foundDinDoorbellCode(complete: complete)
            return
        }

        decodeOldQR(content: content, scanID: nil, complete: complete)
    }
    
    // !I 开头为心籁IPC二维码
    private func foundThirdPartyCameraCode(content: String, homeID: String, complete: ((Any?, Int) -> Void)?) {
        let request = DinQRCodeRequest.getCameraDataWithCode(codeStr: content, homeID: homeID)
        DinHttpProvider.request(request, withoutResultChecked: true) { result in
            if let data = result?["resultData"] as? Data,
               let encryptData = (String(data: data, encoding: .utf8) ?? "").dataFromHexadecimalString(),
               let decryptData = DinCore.cryptor.rc4Decrypt(encryptData, key: DinCore.ipcSecret ?? "") {
                complete?(["codeType": QRCodeType.cameraCode.rawValue, "data": decryptData], 1)
            } else {
                complete?(nil, -1)
            }
        } fail: { error in
            complete?(nil, (error as? DinNetwork.Error)?.errorCode ?? -1)
        }

    }
    
    
    // 16位的为主机二维码
    private func foundPanelCode(complete: (([String: Any]?, Int) -> Void)?) {
        complete?(["codeType": QRCodeType.panelCode.rawValue], 1)
    }
    // dscam_开头的二维码
    private func foundDinCameraCode(complete: (([String: Any]?, Int) -> Void)?) {
        complete?(["codeType": QRCodeType.dinCameraCode.rawValue], 1)
    }

    private func foundDinCameraV006Code(complete: (([String: Any]?, Int) -> Void)?) {
        complete?(["codeType": QRCodeType.dinCameraV006Code.rawValue], 1)
    }
    // dscam_开头的二维码
    private func foundDinCameraV015Code(complete: (([String: Any]?, Int) -> Void)?) {
        complete?(["codeType": QRCodeType.dinCameraV015Code.rawValue], 1)
    }

    private func foundDinStorageBattery5000Code(complete: (([String: Any]?, Int) -> Void)?) {
        complete?(["codeType": QRCodeType.dinStorageBattery5000Code.rawValue], 1)
    }
    
    private func foundDinStorageBatteryPowerCore20OR30Code(complete: (([String: Any]?, Int) -> Void)?) {
        complete?(["codeType": QRCodeType.dinStorageBatteryPowerCore20OR30Code.rawValue], 1)
    }
    
    private func foundDinStorageBatteryPowerStoreCode(complete: (([String: Any]?, Int) -> Void)?) {
        complete?(["codeType": QRCodeType.dinStorageBatteryPowerStoreCode.rawValue], 1)
    }
    
    private func foundDinStorageBatteryPowerStore20Code(complete: (([String: Any]?, Int) -> Void)?) {
        complete?(["codeType": QRCodeType.dinStorageBatteryPowerStore20Code.rawValue], 1)
    }
    
    private func foundDinStorageBatteryPowerPulseCode(complete: (([String: Any]?, Int) -> Void)?) {
        complete?(["codeType": QRCodeType.dinStorageBatteryPowerPulseCode.rawValue], 1)
    }

    private func foundDinDoorbellCode(complete: (([String: Any]?, Int) -> Void)?) {
        complete?(["codeType": QRCodeType.videoDoorbellCode.rawValue], 1)
    }

    /// 解码旧二维码
    ///
    /// - Parameters:
    ///   - content: 用作解码的字段
    ///   - scanID: 用作显示的字段，（usst这边由于工厂打码的问题，scanID扫出来的并不是真实用于解码的id，但是需要显示）
    private func decodeOldQR(content: String, scanID: String?, complete: (([String: Any]?, Int) -> Void)?) {
        var accessoryID: String?
        var ipcData: String?

        if let object = DinDataConvertor.convertToDictionary(content) {
            accessoryID = object["id"] as? String ?? ""
            ipcData = content
        } else {
            accessoryID = content
        }

        guard accessoryID != nil else {
            complete?(nil, -1)
            return
        }

        let dinID = DinAccessoryUtil.str64(toHexStr: accessoryID ?? "")
        if !(dinID.count == 11 || dinID.count == 15) {
            complete?(nil, -1)
            return
        }

        // 检查大type
        guard DinAccessory.checkDType(dinID[0...0]) == true else {
            complete?(nil, -1)
            return
        }

        // 检查小Type
        let sTypeID = dinID[1...2]
        guard DinAccessory.checkStype(sTypeID) else {
            complete?(nil, -1)
            return
        }

        var oldPlugInfo: [String: Any] = [:]
        oldPlugInfo["category"] = Int(dinID[0...0]) ?? 0
        oldPlugInfo["subCategory"] = dinID[1...2]
        if scanID?.count ?? 0 > 0 {
            oldPlugInfo["pluginID"] = scanID ?? ""
        } else {
            oldPlugInfo["pluginID"] = accessoryID ?? ""
        }
        oldPlugInfo["ipcData"] = ipcData ?? ""
        oldPlugInfo["decodeID"] = accessoryID ?? ""

        complete?(["codeType": QRCodeType.oldPluginCode.rawValue, "data": oldPlugInfo], 1)

//        if DinAccessory.oldDoorWindowsStypes.contains(sTypeID) || DinAccessory.oldSmartPlugStypes.contains(sTypeID) {
//            complete?(["codeType": QRCodeType.oldPluginCode.rawValue, "data": oldPlugInfo], 1)
//            return
//        }
//        complete?(nil, -1)
    }

    private func decodeNewQR(content: String, complete: ((Any?, Int) -> Void)?) {
        let request = DinRequest.getPluginInfo(content: content)
        DinHttpProvider.request(request, withoutResultChecked: true) { [weak self] result in
            if let data = result?["resultData"] as? Data {
                complete?(["codeType": QRCodeType.cameraCode.rawValue, "data": data], 1)
            } else {
                let type = result?["dtype"] as? Int ?? -99
                if type == 11 { // 可视门铃
                    complete?(nil, -1)
                    return
                } else if type == -1 {
                    if let oldcode = result?["oldcode"] as? String {
                        self?.decodeOldQR(content: oldcode, scanID: content, complete: complete)
                        return
                    } else {
                        complete?(nil, -1)
                        return
                    }
                }
                else {
                    // 其他新ask配件
                    complete?(["codeType": QRCodeType.newPluginCode.rawValue, "data": result ?? [:]], 1)
                }
            }
        } fail: { error in
            complete?(nil, (error as? DinNetwork.Error)?.errorCode ?? -1)
        }
    }
    
    private func verifyHomeInvitationCode(code: String, complete: (([String: Any]?, Int) -> Void)?) {
        DinCore.verifyHomeInvitationCode(code: code) { home in
            complete?(["codeType": QRCodeType.familyInvitationCode.rawValue, "home": home], 1)
        } fail: { error in
            complete?(nil, (error as? DinNetwork.Error)?.errorCode ?? -1)
        }
    }
}
