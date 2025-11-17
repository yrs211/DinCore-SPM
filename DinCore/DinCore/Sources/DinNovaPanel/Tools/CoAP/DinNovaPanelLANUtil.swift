//
//  DinNovaPanelLANUtil.swift
//  DinCore
//
//  Created by Jin on 2021/5/13.
//

import UIKit
import DinCore.ICoAPExchange
import DinSupport

public class DinNovaPanelLANUtil: NSObject {
    weak var panelControl: DinNovaPanelControl?

    private let iExchange: ICoAPExchange = ICoAPExchange()
    private let Payload_CMD_CheckAvailable: String = "CheckAvailable"

    public var isCOAPAvailable: Bool = false

    private var checkAvailableMessageID: String = ""
    private var opMessageIDs: [String] = []

    init(withPanelControl panelControl: DinNovaPanelControl) {
        self.panelControl = panelControl
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(checkForReachability(notification:)), name: Notification.Name.reachabilityChanged, object: nil)
        iExchange.delegate = self
    }


    @objc private func checkForReachability(notification: NSNotification) {
        isCOAPAvailable = false
        checkAvailable(withLanIP: panelControl?.panel.lanIP ?? "")
    }

    //MARK: - 处理COAP的Payload内容
    private func makeCOAPPayload(withCMD cmd: String, messageID: String, force: Bool) -> String {
        var jsonDict = [String: Any]()
        jsonDict["devtoken"] = panelControl?.panel.token ?? ""
        jsonDict["userid"] = DinCore.user?.name ?? ""
        jsonDict["messageid"] = messageID
        jsonDict["cmd"] = cmd
        jsonDict["gmtime"] = Int64(Date().timeIntervalSince1970*1000000000)
        jsonDict["force"] = force

        return encryptData(withDictionary: jsonDict)
    }
    private func encryptData(withDictionary dict: Dictionary<String, Any>) -> String {
        if dict.count < 1 {
            return ""
        }
        if let sendData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
            if let sendString = String(data: sendData, encoding: .utf8) {
                return DinCore.cryptor.rc4EncryptToHexString(with: sendString, key: DinCore.appSecret ?? "") ?? ""
            }
        }
        return ""
    }
    private func decryptData(withDataString dataString: String) -> Dictionary<String, Any> {
        if dataString.count < 1 {
            return [:]
        }
        let decryptString = DinCore.cryptor.rc4EncryptToHexString(with: dataString, key: DinCore.appSecret ?? "")
        if let resultData = decryptString?.data(using: .utf8) {
            if let resultDict = ((try? JSONSerialization.jsonObject(with: resultData, options: .mutableLeaves) as? Dictionary<String, Any>) as Dictionary<String, Any>??) {
                return resultDict ?? [:]
            }
        }
        return [:]
    }

    //MARK: - 公用方法
    public func checkAvailable(withLanIP lanIP: String?) {
        guard lanIP?.count ?? 0 > 0 else {
            isCOAPAvailable = false
            return
        }

        checkAvailableMessageID = String.UUID()
        var jsonDict = [String: String]()
        jsonDict["messageid"] = checkAvailableMessageID
        let encryptString = encryptData(withDictionary: jsonDict)
        let coapMsg = ICoAPMessage(asRequestConfirmable: true, requestMethod: IC_GET.rawValue, sendToken: true, payload: encryptString)
        guard coapMsg != nil else {
            isCOAPAvailable = false
            return
        }
        coapMsg!.addOption(IC_URI_PATH.rawValue, withValue: "action")
        iExchange.sendRequest(with: coapMsg, toHost: lanIP!, port: 5683)
    }

    public func sendOperationSuccess(withCMD cmd: String, messageID: String, force: Bool) -> Bool {
        guard panelControl?.panel.lanIP.count ?? 0 > 0 else {
            return false
        }

        let encryptString = makeCOAPPayload(withCMD: cmd, messageID: messageID, force: force)
        let coapMsg = ICoAPMessage(asRequestConfirmable: true, requestMethod: IC_GET.rawValue, sendToken: true, payload: encryptString)

        guard coapMsg != nil else {
            return false
        }

        coapMsg!.addOption(IC_URI_PATH.rawValue, withValue: "action")
        iExchange.sendRequest(with: coapMsg, toHost: panelControl?.panel.lanIP ?? "", port: 5683)
        opMessageIDs.append(messageID)
        return true
    }

    public func sendSetSmartPlugEnableOperationSuccess(withMessageID messageID: String, pluginID: String, enable: Bool, sendID: String? = nil, stype: String? = nil) -> Bool {
        guard panelControl?.panel.lanIP.count ?? 0 > 0 else {
            return false
        }

        var jsonDict = [String: Any]()
        jsonDict["devtoken"] = panelControl?.panel.token ?? ""
        jsonDict["userid"] = DinCore.user?.name ?? ""
        jsonDict["gmtime"] = Int64(Date().timeIntervalSince1970*1000000000)
        jsonDict["messageid"] = messageID
        let cmd = stype?.count ?? 0 > 0 ? DinNovaPluginCommand.setNewSmartPlugEnable.rawValue : DinNovaPluginCommand.setSmartPlugEnable.rawValue
        jsonDict["cmd"] = cmd
        jsonDict["pluginid"] = pluginID
        jsonDict["plugin_item_smart_plug_enable"] = enable.toInt()
        if stype?.count ?? 0 > 0 {
            jsonDict["dtype"] = 10
            jsonDict["sendid"] = sendID
            jsonDict["stype"] = stype
        }
        let coapMsg = ICoAPMessage(asRequestConfirmable: true, requestMethod: IC_GET.rawValue, sendToken: true, payload: encryptData(withDictionary: jsonDict))

        guard coapMsg != nil else {
            return false
        }

        coapMsg!.addOption(IC_URI_PATH.rawValue, withValue: "action")
        iExchange.sendRequest(with: coapMsg, toHost: panelControl?.panel.lanIP ?? "", port: 5683)
        opMessageIDs.append(messageID)
        return true
    }

    public func sendSetRelayOperationSuccess(withMessageID messageID: String, action: String, sendid: String) -> Bool {
        guard panelControl?.panel.lanIP.count ?? 0 > 0 else {
            return false
        }

        var jsonDict = [String: Any]()
        jsonDict["devtoken"] = panelControl?.panel.token ?? ""
        jsonDict["userid"] = DinCore.user?.name ?? ""
        jsonDict["gmtime"] = Int64(Date().timeIntervalSince1970*1000000000)
        jsonDict["messageid"] = messageID
        jsonDict["cmd"] = DinNovaPluginCommand.setRelayAction.rawValue
        jsonDict["action"] = action
        jsonDict["sendid"] = sendid

        let coapMsg = ICoAPMessage(asRequestConfirmable: true, requestMethod: IC_GET.rawValue, sendToken: true, payload: encryptData(withDictionary: jsonDict))

        guard coapMsg != nil else {
            return false
        }

        coapMsg!.addOption(IC_URI_PATH.rawValue, withValue: "action")
        iExchange.sendRequest(with: coapMsg, toHost: panelControl?.panel.lanIP ?? "", port: 5683)
        opMessageIDs.append(messageID)
        return true
    }
}


extension DinNovaPanelLANUtil: ICoAPExchangeDelegate {
    public func iCoAPExchange(_ exchange: ICoAPExchange!, didFailWithError error: Error!) {
        //
    }

    public func iCoAPExchange(_ exchange: ICoAPExchange!, didReceive coapMessage: ICoAPMessage!) {
        isCOAPAvailable = true
        if let playload = coapMessage.payload {
            let resultDict = decryptData(withDataString: playload)
            if resultDict.count > 0 {
                if let messageID = resultDict["messageid"] as? String, let cmd = resultDict["cmd"] as? String {
                    if cmd == DinNovaPanelCommand.arm.rawValue {
                        let response = DinNovaPanelSocketResponse()
                        response.status = 1
                        response.action = "/device/cmdack"
                        response.cmd = cmd
                        response.messageID = messageID
                        panelControl?.accept(coapResponse: response)
                    }
                }
            }
        }
    }

    public func iCoAPExchange(_ exchange: ICoAPExchange!, didRetransmitCoAPMessage coapMessage: ICoAPMessage!, number: uint, finalRetransmission final: Bool) {
        //
    }
}
