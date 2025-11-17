//
//  DinNovaKeypadControl+WSResponseHandler.swift
//  DinCore
//
//  Created by Jin on 2021/6/23.
//

import Foundation
import DinSupport

extension DinNovaKeypadControl {
    func handlePowerValueChange(_ result: [String: Any]) {
        guard let plugins = result["plugins"] as? [[String: Any]] else {
            return
        }

        for plugin in plugins {
            if plugin["id"] as? String == self.plugin.id {
                if self.plugin.checkIsASKPlugin() {
                    DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                        guard let self = self else { return }
                        if let batteryLevel = plugin["battery_level"] {
                            self.plugin.askData?["battery_level"] = batteryLevel
                        }
                        if let charging = plugin["charging"] {
                            self.plugin.askData?["charging"] = charging
                        }
                        if let tamper = plugin["tamper"] {
                            self.plugin.askData?["tamper"] = tamper
                        }
                        if let rssi = plugin["rssi"] {
                            self.plugin.askData?["rssi"] = rssi
                        }
                        self.updateASKData(self.plugin.askData ?? [:], usingSync: true, complete: nil)
                        DispatchQueue.global().async { [weak self] in
                            guard let self = self else { return }
                            self.accept(deviceOperationResult: self.makeResultSuccessInfo(withCMD: "plugin_state_change", owner: false, result: [:]))
                        }
                    }
                }
                break
            }
        }
    }

    func handleOnline(_ result: [String: Any], online: Bool) {
        guard let sendid = result["sendid"] as? String else {
            return
        }
        if sendid == (self.plugin as? DinNovaKeypad)?.sendid ?? "" {
            DinUser.homeDeviceInfoQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.plugin.askData?["keeplive"] = online
                self.updateIsOnline(online, usingSync: true, complete: nil)
                self.updateASKData(self.plugin.askData ?? [:], usingSync: true, complete: nil)
                DispatchQueue.global().async { [weak self] in
                    self?.accept(deviceOnlineState: online)
                }
            }
        }
    }
}
