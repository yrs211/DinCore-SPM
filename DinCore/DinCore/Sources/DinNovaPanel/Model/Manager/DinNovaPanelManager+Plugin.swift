//
//  DinNovaPanelManager+Plugin.swift
//  DinCore
//
//  Created by Jin on 2021/5/27.
//

import Foundation
import DinSupport

// MARK: - 获取缓存
extension DinNovaPanelManager {
    func getCachedPlugin(withDeviceString deviceString: DinGetDeviceString, panelOperator: DinNovaPanelOperator) -> [DinNovaPluginOperator]? {
        getPluginCache(withDeviceString: deviceString, panelOperator: panelOperator, panelID: panelOperator.id)
    }
}

// MARK: - 门磁
extension DinNovaPanelManager {
    func getDoorWindowSensorList(WithPanelOperator panelOperator: DinNovaPanelOperator,
                                 complete: @escaping ([DinNovaPluginOperator]) -> Void) {
        let request = DinNovaPluginRequest.doorSensorList(id: panelOperator.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            guard let self = self else { return }
            self.handleDoorWindowSensorResult(result, panelOperator: panelOperator) { resultOperators in
                complete(resultOperators)
            }
        } fail: { [weak self] error in
            let doorWindowSensors = self?.getPluginCache(withDeviceString: .doorWindowSensor, panelOperator: panelOperator, panelID: panelOperator.id)
            complete(doorWindowSensors ?? [])
        }
    }
    private func handleDoorWindowSensorResult(_ data: [String: Any]?, panelOperator: DinNovaPanelOperator, complete: @escaping ([DinNovaPluginOperator])->()) {
        var devices: [DinNovaPluginOperator] = []
        if let oldSensors = data?["datas"] as? [[String: Any]] {
            for oldSensor in oldSensors {
                if let sensor = DinNovaDoorWindowSensor.deserialize(from: oldSensor) {
                    devices.append(DinNovaPluginOperator(withPluginControl: DinNovaDoorWindowSensorControl(withPlugin: sensor, panelOperator: panelOperator)))
                }
            }
        }
        if let newSensorsDict = data?["newaskdatas"] as? [String: Any] {
            let newSensorsArr = Array(newSensorsDict.values) as? [[[String: Any]]] ?? []
            for newSensors in newSensorsArr {
                for newSensor in newSensors {
                    if let sensor = DinNovaDoorWindowSensor.deserialize(from: newSensor) {
                        /// 如果ask配件，赋值askdata
                        if sensor.checkIsASKPlugin() {
                            sensor.askData = newSensor
                            // 写死ask plugin都是10
                            sensor.category = 10
                        }
                        devices.append(DinNovaPluginOperator(withPluginControl: DinNovaDoorWindowSensorControl(withPlugin: sensor, panelOperator: panelOperator)))
                    }
                }
            }
        }

        DinUser.homeDeviceInfoQueue.async(flags: .barrier) {
            // 如果主机离线，不要请求服务器了，直接读取缓存
            // 因为请求服务器是会有配件信息返回的，并且会把配件的状态设置成在线（和主机离线，所有配件必须为离线需求冲突）
            // 同时需要注意的是，不能用Operator和Control改，因为涉及到DinHomeDeviceProtocol里面的info信息的更新
            if !panelOperator.panelControl.panel.online {
                for device in devices {
                    device.pluginControl.forcePlugin(toOnline: false, complete: nil)
                }
            }
            DispatchQueue.main.async {
                complete(devices)
            }
        }
    }
    
    // 针对只返回ask配件的api
    func handleAskDoorWindowSensorResult(_ data: [String: Any]?,
                                         panelOperator: DinNovaPanelOperator,
                                         complete: @escaping ([DinNovaPluginOperator])->()) {
        var devices: [DinNovaPluginOperator] = []
        if let newSensorsDicts = data?["accessories"] as? [[String: Any]] {
            for newSensor in newSensorsDicts {
                if let sensor = DinNovaDoorWindowSensor.deserialize(from: newSensor) {
                    /// 如果ask配件，赋值askdata
                    if sensor.checkIsASKPlugin() {
                        sensor.askData = newSensor
                        // 写死ask plugin都是10
                        sensor.category = 10
                    }
                    devices.append(DinNovaPluginOperator(withPluginControl: DinNovaDoorWindowSensorControl(withPlugin: sensor, panelOperator: panelOperator)))
                }
            }
        }

        DinUser.homeDeviceInfoQueue.async(flags: .barrier) {
            // 如果主机离线，不要请求服务器了，直接读取缓存
            // 因为请求服务器是会有配件信息返回的，并且会把配件的状态设置成在线（和主机离线，所有配件必须为离线需求冲突）
            // 同时需要注意的是，不能用Operator和Control改，因为涉及到DinHomeDeviceProtocol里面的info信息的更新
            if !panelOperator.panelControl.panel.online {
                for device in devices {
                    device.pluginControl.forcePlugin(toOnline: false, complete: nil)
                }
            }
            DispatchQueue.main.async {
                complete(devices)
            }
        }
    }
}

// MARK: - 智能插座
extension DinNovaPanelManager {
    func getSmartPlugList(WithPanelOperator panelOperator: DinNovaPanelOperator,
                                 complete: @escaping ([DinNovaPluginOperator]) -> Void) {
        let request = DinNovaPluginRequest.getDeviceMainPlugins(deviceID: panelOperator.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            guard let self = self else { return }
            self.handleSmartPlugsResult(result, panelOperator: panelOperator) { resultOperators in
                complete(resultOperators)
            }
        } fail: { [weak self] error in
            let doorWindowSensors = self?.getPluginCache(withDeviceString: .smartPlugin, panelOperator: panelOperator, panelID: panelOperator.id)
            complete(doorWindowSensors ?? [])
        }
    }
    private func handleSmartPlugsResult(_ data: [String: Any]?, panelOperator: DinNovaPanelOperator, complete: @escaping ([DinNovaPluginOperator])->()) {
        var devices: [DinNovaPluginOperator] = []
        if let pluginData = data?["plugin_info"] as? [String: Any],
           let smartPlugDatas = pluginData["smart_plug"] as? [[String: Any]] {
            for smartPlugData in smartPlugDatas {
                if let sensor = DinNovaSmartPlug.deserialize(from: smartPlugData) {
                    /// 如果ask配件，赋值askdata
                    if sensor.checkIsASKPlugin() {
                        sensor.askData = smartPlugData
                        // 写死ask plugin都是10
                        sensor.category = 10
                    }
                    devices.append(DinNovaPluginOperator(withPluginControl: DinNovaSmartPlugControl(withPlugin: sensor, panelOperator: panelOperator)))
                }
            }
        }
        DinUser.homeDeviceInfoQueue.async(flags: .barrier) {
            // 如果主机离线，不要请求服务器了，直接读取缓存
            // 因为请求服务器是会有配件信息返回的，并且会把配件的状态设置成在线（和主机离线，所有配件必须为离线需求冲突）
            // 同时需要注意的是，不能用Operator和Control改，因为涉及到DinHomeDeviceProtocol里面的info信息的更新
            if !panelOperator.panelControl.panel.online {
                for device in devices {
                    device.pluginControl.forcePlugin(toOnline: false, complete: nil)
                }
            }
            DispatchQueue.main.async {
                complete(devices)
            }
        }
    }
    
    //针对只返回ask配件的api
    func handleAskSmartPlugsResult(_ data: [String: Any]?, panelOperator: DinNovaPanelOperator, complete: @escaping ([DinNovaPluginOperator])->()) {
        var devices: [DinNovaPluginOperator] = []
        if let smartPlugDatas = data?["accessories"] as? [[String: Any]] {
            for smartPlugData in smartPlugDatas {
                if let sensor = DinNovaSmartPlug.deserialize(from: smartPlugData) {
                    /// 如果ask配件，赋值askdata
                    if sensor.checkIsASKPlugin() {
                        sensor.askData = smartPlugData
                        // 写死ask plugin都是10
                        sensor.category = 10
                    }
                    devices.append(DinNovaPluginOperator(withPluginControl: DinNovaSmartPlugControl(withPlugin: sensor, panelOperator: panelOperator)))
                }
            }
        }
        DinUser.homeDeviceInfoQueue.async(flags: .barrier) {
            // 如果主机离线，不要请求服务器了，直接读取缓存
            // 因为请求服务器是会有配件信息返回的，并且会把配件的状态设置成在线（和主机离线，所有配件必须为离线需求冲突）
            // 同时需要注意的是，不能用Operator和Control改，因为涉及到DinHomeDeviceProtocol里面的info信息的更新
            if !panelOperator.panelControl.panel.online {
                for device in devices {
                    device.pluginControl.forcePlugin(toOnline: false, complete: nil)
                }
            }
            DispatchQueue.main.async {
                complete(devices)
            }
        }
    }
}

// MARK: - 智能按钮
extension DinNovaPanelManager {
    func getSmartButtonList(WithPanelOperator panelOperator: DinNovaPanelOperator,
                                 complete: @escaping ([DinNovaPluginOperator]) -> Void) {
        let request = DinNovaPluginRequest.getSmartBtnList(deviceID: panelOperator.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            guard let self = self else { return }
            self.handleSmartButtonsResult(result, panelOperator: panelOperator) { resultOperators in
                complete(resultOperators)
            }
        } fail: { _ in
            complete([])
        }
    }
    private func handleSmartButtonsResult(_ data: [String: Any]?, panelOperator: DinNovaPanelOperator, complete: @escaping ([DinNovaPluginOperator])->()) {
        var devices: [DinNovaPluginOperator] = []
        if let pluginData = data?["datas"] as? [String: Any],
           let smartPlugDatas = pluginData["3B"] as? [[String: Any]] {
            for smartPlugData in smartPlugDatas {
                if let sensor = DinNovaSmartButton.deserialize(from: smartPlugData) {
                    /// 如果ask配件，赋值askdata
                    if sensor.checkIsASKPlugin() {
                        sensor.askData = smartPlugData
                    }
                    devices.append(DinNovaPluginOperator(withPluginControl: DinNovaSmartButtonControl(withPlugin: sensor, panelOperator: panelOperator)))
                }
            }
        }
        DinUser.homeDeviceInfoQueue.async(flags: .barrier) {
            // 如果主机离线，不要请求服务器了，直接读取缓存
            // 因为请求服务器是会有配件信息返回的，并且会把配件的状态设置成在线（和主机离线，所有配件必须为离线需求冲突）
            // 同时需要注意的是，不能用Operator和Control改，因为涉及到DinHomeDeviceProtocol里面的info信息的更新
            if !panelOperator.panelControl.panel.online {
                for device in devices {
                    device.pluginControl.forcePlugin(toOnline: false, complete: nil)
                }
            }
            DispatchQueue.main.async {
                complete(devices)
            }
        }
    }
}

// MARK: - 警笛
extension DinNovaPanelManager {
    func getSirenList(WithPanelOperator panelOperator: DinNovaPanelOperator,
                                 complete: @escaping ([DinNovaPluginOperator]) -> Void) {
        let request = DinNovaPanelRequest.getAccessoryByType(id: panelOperator.id, type: DinAccessoryType.siren.rawValue, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            guard let self = self else { return }
            self.handleSirenResult(result, panelOperator: panelOperator) { resultOperators in
                complete(resultOperators)
            }
        } fail: { _ in
            complete([])
        }
    }
    private func handleSirenResult(_ data: [String: Any]?, panelOperator: DinNovaPanelOperator, complete: @escaping ([DinNovaPluginOperator])->()) {
        var devices: [DinNovaPluginOperator] = []
        if let oldSirens = data?["datas"] as? [[String: Any]] {
            let pluginInfo = data?["plugininfo"] as? [String: Any] ?? [:]
            let category = pluginInfo["category"] as? Int ?? 4
            for oldSiren in oldSirens {
                if let sensor = DinNovaSiren.deserialize(from: oldSiren) {
                    sensor.category = category
                    devices.append(DinNovaPluginOperator(withPluginControl: DinNovaSirenControl(withPlugin: sensor, panelOperator: panelOperator)))
                }
            }
        }

        if let pluginData = data?["newaskdatas"] as? [String: Any] {
            if let G004s = pluginData["21"] as? [[String: Any]] {
                for G004 in G004s {
                    if let sensor = DinNovaSiren.deserialize(from: G004) {
                        /// 如果ask配件，赋值askdata
                        if sensor.checkIsASKPlugin() {
                            sensor.askData = G004
                        }
                        devices.append(DinNovaPluginOperator(withPluginControl: DinNovaSirenControl(withPlugin: sensor, panelOperator: panelOperator)))
                    }
                }
            }
            if let G005s = pluginData["22"] as? [[String: Any]] {
                    for G005 in G005s {
                        if let sensor = DinNovaSiren.deserialize(from: G005) {
                            /// 如果ask配件，赋值askdata
                            if sensor.checkIsASKPlugin() {
                                sensor.askData = G005
                            }
                            devices.append(DinNovaPluginOperator(withPluginControl: DinNovaSirenControl(withPlugin: sensor, panelOperator: panelOperator)))
                        }
                    }
            }
            if let outdoorSiren35Array = pluginData["35"] as? [[String: Any]] {
                for outdoorSiren35 in outdoorSiren35Array {
                    if let sensor = DinNovaSiren.deserialize(from: outdoorSiren35) {
                        /// 如果ask配件，赋值askdata
                        if sensor.checkIsASKPlugin() {
                            sensor.askData = outdoorSiren35
                        }
                        devices.append(DinNovaPluginOperator(withPluginControl: DinNovaSirenControl(withPlugin: sensor, panelOperator: panelOperator)))
                    }
                }
            }
            if let indooprSiren34Array = pluginData["34"] as? [[String: Any]] {
                for indooprSiren34 in indooprSiren34Array {
                    if let sensor = DinNovaSiren.deserialize(from: indooprSiren34) {
                        /// 如果ask配件，赋值askdata
                        if sensor.checkIsASKPlugin() {
                            sensor.askData = indooprSiren34
                        }
                        devices.append(DinNovaPluginOperator(withPluginControl: DinNovaSirenControl(withPlugin: sensor, panelOperator: panelOperator)))
                    }
                }
            }
        }
        DinUser.homeDeviceInfoQueue.async(flags: .barrier) {
            // 如果主机离线，不要请求服务器了，直接读取缓存
            // 因为请求服务器是会有配件信息返回的，并且会把配件的状态设置成在线（和主机离线，所有配件必须为离线需求冲突）
            // 同时需要注意的是，不能用Operator和Control改，因为涉及到DinHomeDeviceProtocol里面的info信息的更新
            if !panelOperator.panelControl.panel.online {
                for device in devices {
                    device.pluginControl.forcePlugin(toOnline: false, complete: nil)
                }
            }
            DispatchQueue.main.async {
                complete(devices)
            }
        }
    }
}

// MARK: - 遥控
extension DinNovaPanelManager {
    func getRemoteControlList(WithPanelOperator panelOperator: DinNovaPanelOperator,
                                 complete: @escaping ([DinNovaPluginOperator]) -> Void) {
        let request = DinNovaPanelRequest.getAccessoryByType(id: panelOperator.id,
                                                             type: DinAccessoryType.remoteControll.rawValue, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            guard let self = self else { return }
            self.handleRemoteControlResult(result, panelOperator: panelOperator) { resultOperators in
                complete(resultOperators)
            }
        } fail: { _ in
            complete([])
        }
    }
    private func handleRemoteControlResult(_ data: [String: Any]?, panelOperator: DinNovaPanelOperator, complete: @escaping ([DinNovaPluginOperator])->()) {
        var devices: [DinNovaPluginOperator] = []
        if let oldRemoteControls = data?["datas"] as? [[String: Any]] {
            let pluginInfo = data?["plugininfo"] as? [String: Any] ?? [:]
            let category = pluginInfo["category"] as? Int ?? 4
            for oldRemoteControl in oldRemoteControls {
                if let sensor = DinNovaRemoteControl.deserialize(from: oldRemoteControl) {
                    sensor.category = category
                    devices.append(DinNovaPluginOperator(withPluginControl: DinNovaRemoteControlControl(withPlugin: sensor, panelOperator: panelOperator)))
                }
            }
        }
        if let newRemoteControlsDict = data?["newaskdatas"] as? [String: Any] {
            var newRemoteControls = [[String: Any]]()
            // 没有心跳5键遥控
            if let newRemoteControl1Es = newRemoteControlsDict["1E"] as? [[String: Any]] {
                newRemoteControls.append(contentsOf: newRemoteControl1Es)
            }
            // 没有心跳5键遥控
            if let newRemoteControl3As = newRemoteControlsDict["3A"] as? [[String: Any]] {
                newRemoteControls.append(contentsOf: newRemoteControl3As)
            }
            for newRemoteControl in newRemoteControls {
                if let sensor = DinNovaRemoteControl.deserialize(from: newRemoteControl) {
                    /// 如果ask配件，赋值askdata
                    if sensor.checkIsASKPlugin() {
                        sensor.askData = newRemoteControl
                    }
                    devices.append(DinNovaPluginOperator(withPluginControl: DinNovaRemoteControlControl(withPlugin: sensor, panelOperator: panelOperator)))
                }
            }
        }
        DinUser.homeDeviceInfoQueue.async(flags: .barrier) {
            // 如果主机离线，不要请求服务器了，直接读取缓存
            // 因为请求服务器是会有配件信息返回的，并且会把配件的状态设置成在线（和主机离线，所有配件必须为离线需求冲突）
            // 同时需要注意的是，不能用Operator和Control改，因为涉及到DinHomeDeviceProtocol里面的info信息的更新
            if !panelOperator.panelControl.panel.online {
                for device in devices {
                    device.pluginControl.forcePlugin(toOnline: false, complete: nil)
                }
            }
            DispatchQueue.main.async {
                complete(devices)
            }
        }
    }
}

// MARK: - 继电器
extension DinNovaPanelManager {
    func getRelayList(WithPanelOperator panelOperator: DinNovaPanelOperator,
                                 complete: @escaping ([DinNovaPluginOperator]) -> Void) {
        let request = DinNovaPanelRequest.relayAccessoryList(id: panelOperator.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            guard let self = self else { return }
            self.handleRelayResult(result, panelOperator: panelOperator) { resultOperators in
                complete(resultOperators)
            }
        } fail: { _ in
            complete([])
        }
    }
    private func handleRelayResult(_ data: [String: Any]?, panelOperator: DinNovaPanelOperator, complete: @escaping ([DinNovaPluginOperator])->()) {
        var devices: [DinNovaPluginOperator] = []
        if let relayArr = data?["datas"] as? [[String: Any]] {
            for relayDict in relayArr {
                if let sensor = DinNovaRelay.deserialize(from: relayDict) {
                    /// 如果ask配件，赋值askdata
                    if sensor.checkIsASKPlugin() {
                        sensor.askData = relayDict
                    }
                    devices.append(DinNovaPluginOperator(withPluginControl: DinNovaRelayControl(withPlugin: sensor, panelOperator: panelOperator)))
                }
            }
        }
        DinUser.homeDeviceInfoQueue.async(flags: .barrier) {
            // 如果主机离线，不要请求服务器了，直接读取缓存
            // 因为请求服务器是会有配件信息返回的，并且会把配件的状态设置成在线（和主机离线，所有配件必须为离线需求冲突）
            // 同时需要注意的是，不能用Operator和Control改，因为涉及到DinHomeDeviceProtocol里面的info信息的更新
            if !panelOperator.panelControl.panel.online {
                for device in devices {
                    device.pluginControl.forcePlugin(toOnline: false, complete: nil)
                }
            }
            DispatchQueue.main.async {
                complete(devices)
            }
        }
    }
}

// MARK: - 安防配件
extension DinNovaPanelManager {
    func getSecurityAccessoryList(WithPanelOperator panelOperator: DinNovaPanelOperator,
                                 complete: @escaping ([DinNovaPluginOperator]) -> Void) {
        let request = DinNovaPluginRequest.getSecurityPluginList(deviceID: panelOperator.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            guard let self = self else { return }
            self.handleSecurityAccessoryResult(result, panelOperator: panelOperator) { resultOperators in
                complete(resultOperators)
            }
        } fail: { _ in
            complete([])
        }
    }
    private func handleSecurityAccessoryResult(_ data: [String: Any]?, panelOperator: DinNovaPanelOperator, complete: @escaping ([DinNovaPluginOperator])->()) {
        var devices: [DinNovaPluginOperator] = []
        if let oldSensors = data?["datas"] as? [[String: Any]] {
            let pluginInfo = data?["plugininfo"] as? [String: Any] ?? [:]
            let category = pluginInfo["category"] as? Int ?? 4
            for oldSensor in oldSensors {
                if let sensor = DinNovaSecurityAccessory.deserialize(from: oldSensor) {
                    sensor.category = category
                    devices.append(DinNovaPluginOperator(withPluginControl: DinNovaSecurityAccessoryControl(withPlugin: sensor, panelOperator: panelOperator)))
                }
            }
        }
        if let newSensorsDict = data?["newaskdatas"] as? [String: Any] {
            var newSecurityAccessorys = [[String: Any]]()
            // 心跳红外
            if let new17Sensors = newSensorsDict["17"] as? [[String: Any]] {
                newSecurityAccessorys.append(contentsOf: new17Sensors)
            }
            // 心跳门磁
            if let new16Sensors = newSensorsDict["16"] as? [[String: Any]] {
                newSecurityAccessorys.append(contentsOf: new16Sensors)
            }
            // 红外
            if let pir24Sensors = newSensorsDict["24"] as? [[String: Any]] {
                newSecurityAccessorys.append(contentsOf: pir24Sensors)
            }
            // 红外
            if let pir36Sensors = newSensorsDict["36"] as? [[String: Any]] {
                newSecurityAccessorys.append(contentsOf: pir36Sensors)
            }
            // 可调灵敏度红外
            if let pir4ASensor = newSensorsDict["4A"] as? [[String: Any]] {
                newSecurityAccessorys.append(contentsOf: pir4ASensor)
            }
            // 心跳水感
            if let water28Sensors = newSensorsDict["18"] as? [[String: Any]] {
                newSecurityAccessorys.append(contentsOf: water28Sensors)
            }
            // 水感
            if let water2ESensors = newSensorsDict["2E"] as? [[String: Any]] {
                newSecurityAccessorys.append(contentsOf: water2ESensors)
            }
            // 水感
            if let water39Sensors = newSensorsDict["39"] as? [[String: Any]] {
                newSecurityAccessorys.append(contentsOf: water39Sensors)
            }
            // 心跳震动
            if let door19Sensors = newSensorsDict["19"] as? [[String: Any]] {
                newSecurityAccessorys.append(contentsOf: door19Sensors)
            }
            // 震动
            if let door2CSensors = newSensorsDict["2C"] as? [[String: Any]] {
                newSecurityAccessorys.append(contentsOf: door2CSensors)
            }
            // 烟感
            if let smoke2DSensors = newSensorsDict["2D"] as? [[String: Any]] {
                newSecurityAccessorys.append(contentsOf: smoke2DSensors)
            }
            // 烟感
            if let smoke3CSensors = newSensorsDict["3C"] as? [[String: Any]] {
                newSecurityAccessorys.append(contentsOf: smoke3CSensors)
            }
            // 紧急按钮
            if let emergency23Sensors = newSensorsDict["23"] as? [[String: Any]] {
                newSecurityAccessorys.append(contentsOf: emergency23Sensors)
            }
            // 紧急按钮
            if let emergency3BSensors = newSensorsDict["3B"] as? [[String: Any]] {
                newSecurityAccessorys.append(contentsOf: emergency3BSensors)
            }
            // 有线桥接器
            if let wiredBridges = newSensorsDict["3F"] as? [[String: Any]] {
                newSecurityAccessorys.append(contentsOf: wiredBridges)
            }
            for newSecurityAccessory in newSecurityAccessorys {
                if let sensor = DinNovaSecurityAccessory.deserialize(from: newSecurityAccessory) {
                    /// 如果ask配件，赋值askdata
                    if sensor.checkIsASKPlugin() {
                        sensor.askData = newSecurityAccessory
                    }
                    devices.append(DinNovaPluginOperator(withPluginControl: DinNovaSecurityAccessoryControl(withPlugin: sensor, panelOperator: panelOperator)))
                }
            }
        }
        DinUser.homeDeviceInfoQueue.async(flags: .barrier) {
            // 如果主机离线，不要请求服务器了，直接读取缓存
            // 因为请求服务器是会有配件信息返回的，并且会把配件的状态设置成在线（和主机离线，所有配件必须为离线需求冲突）
            // 同时需要注意的是，不能用Operator和Control改，因为涉及到DinHomeDeviceProtocol里面的info信息的更新
            if !panelOperator.panelControl.panel.online {
                for device in devices {
                    device.pluginControl.forcePlugin(toOnline: false, complete: nil)
                }
            }
            DispatchQueue.main.async {
                complete(devices)
            }
        }
    }
}

// MARK: - 键盘/RFID卡
extension DinNovaPanelManager {
    func getKeypadList(WithPanelOperator panelOperator: DinNovaPanelOperator,
                                 complete: @escaping ([DinNovaPluginOperator]) -> Void) {
        let request = DinNovaPanelRequest.getAccessoryByType(id: panelOperator.id,
                                                             type: DinAccessoryType.remoteControll.rawValue, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            guard let self = self else { return }
            self.handleKeypadResult(result, panelOperator: panelOperator) { resultOperators in
                complete(resultOperators)
            }
        } fail: { _ in
            complete([])
        }
    }
    private func handleKeypadResult(_ data: [String: Any]?, panelOperator: DinNovaPanelOperator, complete: @escaping ([DinNovaPluginOperator])->()) {
        var devices: [DinNovaPluginOperator] = []
        if let oldSensors = data?["datas"] as? [[String: Any]] {
            let pluginInfo = data?["plugininfo"] as? [String: Any] ?? [:]
            let category = pluginInfo["category"] as? Int ?? 4
            for oldSensor in oldSensors {
                let id = oldSensor["id"] as? String ?? ""
                let decodeID = oldSensor["decodeid"] as? String ?? ""
                if DinAccessory.isKeypad(pluginID: id, decodeID: decodeID),
                   let sensor = DinNovaKeypad.deserialize(from: oldSensor) {
                    sensor.category = category
                    devices.append(DinNovaPluginOperator(withPluginControl: DinNovaKeypadControl(withPlugin: sensor, panelOperator: panelOperator)))
                }
            }
        }
        if let newKeypadsDict = data?["newaskdatas"] as? [String: Any] {
            var newKeypads = [[String: Any]]()
            // 新型键盘
            if let kepad2Fs = newKeypadsDict["2F"] as? [[String: Any]] {
                newKeypads.append(contentsOf: kepad2Fs)
            }
            for newKeypad in newKeypads {
                if let sensor = DinNovaKeypad.deserialize(from: newKeypad) {
                    /// 如果ask配件，赋值askdata
                    if sensor.checkIsASKPlugin() {
                        sensor.askData = newKeypad
                    }
                    devices.append(DinNovaPluginOperator(withPluginControl: DinNovaKeypadControl(withPlugin: sensor, panelOperator: panelOperator)))
                }
            }
        }
        DinUser.homeDeviceInfoQueue.async(flags: .barrier) {
            // 如果主机离线，不要请求服务器了，直接读取缓存
            // 因为请求服务器是会有配件信息返回的，并且会把配件的状态设置成在线（和主机离线，所有配件必须为离线需求冲突）
            // 同时需要注意的是，不能用Operator和Control改，因为涉及到DinHomeDeviceProtocol里面的info信息的更新
            if !panelOperator.panelControl.panel.online {
                for device in devices {
                    device.pluginControl.forcePlugin(toOnline: false, complete: nil)
                }
            }
            DispatchQueue.main.async {
                complete(devices)
            }
        }
    }
}

// MARK: - 信号中继插座
extension DinNovaPanelManager {
    func getSignalRepeaterPlugList(WithPanelOperator panelOperator: DinNovaPanelOperator,
                                 complete: @escaping ([DinNovaPluginOperator]) -> Void) {
        let request = DinNovaPluginRequest.getDeviceMainPlugins(deviceID: panelOperator.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            guard let self = self else { return }
            self.handleSignalRepeaterPlugsResult(result, panelOperator: panelOperator) { resultOperators in
                complete(resultOperators)
            }
        } fail: { [weak self] error in
            let doorWindowSensors = self?.getPluginCache(withDeviceString: .signalRepeaterPlug, panelOperator: panelOperator, panelID: panelOperator.id)
            complete(doorWindowSensors ?? [])
        }
    }
    private func handleSignalRepeaterPlugsResult(_ data: [String: Any]?, panelOperator: DinNovaPanelOperator, complete: @escaping ([DinNovaPluginOperator])->()) {
        var devices: [DinNovaPluginOperator] = []
        if let pluginData = data?["plugin_info"] as? [String: Any],
           let smartPlugDatas = pluginData["signal_repeater_plug"] as? [[String: Any]] {
            for smartPlugData in smartPlugDatas {
                if let sensor = DinNovaSmartPlug.deserialize(from: smartPlugData) {
                    /// 如果ask配件，赋值askdata
                    if sensor.checkIsASKPlugin() {
                        sensor.askData = smartPlugData
                        // 写死ask plugin都是10
                        sensor.category = 10
                    }
                    devices.append(DinNovaPluginOperator(withPluginControl: DinNovaSmartPlugControl(withPlugin: sensor, panelOperator: panelOperator)))
                }
            }
        }
        DinUser.homeDeviceInfoQueue.async(flags: .barrier) {
            // 如果主机离线，不要请求服务器了，直接读取缓存
            // 因为请求服务器是会有配件信息返回的，并且会把配件的状态设置成在线（和主机离线，所有配件必须为离线需求冲突）
            // 同时需要注意的是，不能用Operator和Control改，因为涉及到DinHomeDeviceProtocol里面的info信息的更新
            if !panelOperator.panelControl.panel.online {
                for device in devices {
                    device.pluginControl.forcePlugin(toOnline: false, complete: nil)
                }
            }
            DispatchQueue.main.async {
                complete(devices)
            }
        }
    }
}

// MARK: - 智能插座和中继插座
extension DinNovaPanelManager {
    func getSmartPlugAndSignalRepeaterPlugList(WithPanelOperator panelOperator: DinNovaPanelOperator,
                                 complete: @escaping ([DinNovaPluginOperator]) -> Void) {
        let request = DinNovaPluginRequest.getDeviceMainPlugins(deviceID: panelOperator.id, homeID: homeID)
        DinHttpProvider.request(request) { [weak self] result in
            guard let self = self else { return }
            self.handleSmartPlugsAndSignalRepeaterPlugsResult(result, panelOperator: panelOperator) { resultOperators in
                complete(resultOperators)
            }
        } fail: { [weak self] error in
            let doorWindowSensors = self?.getPluginCache(withDeviceString: .smartPlugin, panelOperator: panelOperator, panelID: panelOperator.id)
            complete(doorWindowSensors ?? [])
        }
    }
    
    private func handleSmartPlugsAndSignalRepeaterPlugsResult(_ data: [String: Any]?, panelOperator: DinNovaPanelOperator, complete: @escaping ([DinNovaPluginOperator])->()) {
        var devices: [DinNovaPluginOperator] = []
        if let pluginData = data?["plugin_info"] as? [String: Any],
           let smartPlugDatas = pluginData["smart_plug"] as? [[String: Any]] {
            for smartPlugData in smartPlugDatas {
                if let sensor = DinNovaSmartPlug.deserialize(from: smartPlugData) {
                    /// 如果ask配件，赋值askdata
                    if sensor.checkIsASKPlugin() {
                        sensor.askData = smartPlugData
                        // 写死ask plugin都是10
                        sensor.category = 10
                    }
                    devices.append(DinNovaPluginOperator(withPluginControl: DinNovaSmartPlugControl(withPlugin: sensor, panelOperator: panelOperator)))
                }
            }
        }
        if let pluginData = data?["plugin_info"] as? [String: Any],
           let smartPlugDatas = pluginData["signal_repeater_plug"] as? [[String: Any]] {
            for smartPlugData in smartPlugDatas {
                if let sensor = DinNovaSmartPlug.deserialize(from: smartPlugData) {
                    /// 如果ask配件，赋值askdata
                    if sensor.checkIsASKPlugin() {
                        sensor.askData = smartPlugData
                        // 写死ask plugin都是10
                        sensor.category = 10
                    }
                    devices.append(DinNovaPluginOperator(withPluginControl: DinNovaSmartPlugControl(withPlugin: sensor, panelOperator: panelOperator)))
                }
            }
        }
        DinUser.homeDeviceInfoQueue.async(flags: .barrier) {
            // 如果主机离线，不要请求服务器了，直接读取缓存
            // 因为请求服务器是会有配件信息返回的，并且会把配件的状态设置成在线（和主机离线，所有配件必须为离线需求冲突）
            // 同时需要注意的是，不能用Operator和Control改，因为涉及到DinHomeDeviceProtocol里面的info信息的更新
            if !panelOperator.panelControl.panel.online {
                for device in devices {
                    device.pluginControl.forcePlugin(toOnline: false, complete: nil)
                }
            }
            DispatchQueue.main.async {
                complete(devices)
            }
        }
    }
}
