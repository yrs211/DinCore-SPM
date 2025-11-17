//
//  DinStorageBatteryPayloadParser.swift
//  DinCore
//
//  Created by monsoir on 12/1/22.
//

import Foundation

struct DinStorageBatteryPayloadParser {
    
    private let phase: Phase
    private let endian: Endian = .little
    
    init(phase: Phase) {
        self.phase = phase
    }
    
    func parse(getInverterInputInfoData data: Data) throws -> [String: Any] {
        guard data.count >= 24 else { throw CorruptedData() }
        
        let flags = endian.fix(data[0...1].copiedUInt16)
        
        func parse(
            isPlantInputOn: Bool,
            plantInputWatt: UInt16,
            isMPPTInputOn: Bool,
            mpptInputWatt: UInt16,
            isBatteryInputOn: Bool,
            batteryInputWatt: UInt16
        ) -> [String: Any] {
            return [
                "citySourceOn": isPlantInputOn,
                "citySource": plantInputWatt,
                "mpptOn": isMPPTInputOn,
                "mppt": mpptInputWatt,
                "batteryOn": isBatteryInputOn,
                "battery": batteryInputWatt,
            ]
        }
        
        let inputs: [String: Any] = {
            var result: [String: Any] = [
                "0": parse(
                    isPlantInputOn: flags & 0b0000_0000_0000_0001 > 0,
                    plantInputWatt: endian.fix(data[2...3].copiedUInt16),
                    isMPPTInputOn: flags & 0b0000_0000_0000_1000 > 0,
                    mpptInputWatt: endian.fix(data[8...9].copiedUInt16),
                    isBatteryInputOn: flags & 0b0000_0000_1000_0000 > 0,
                    batteryInputWatt: endian.fix(data[16...17].copiedUInt16)
                )
            ]
            
            switch phase {
            case .single: break
            case .three:
                result["1"] = parse(
                    isPlantInputOn: flags & 0b0000_0000_0000_0010 > 0,
                    plantInputWatt: endian.fix(data[4...5].copiedUInt16),
                    isMPPTInputOn: flags & 0b0000_0000_0001_0000 > 0,
                    mpptInputWatt: endian.fix(data[10...11].copiedUInt16),
                    isBatteryInputOn: flags & 0b0000_0001_0000_0000 > 0,
                    batteryInputWatt: endian.fix(data[18...19].copiedUInt16)
                )
                result["2"] = parse(
                    isPlantInputOn: flags & 0b0000_0000_0000_0100 > 0,
                    plantInputWatt: endian.fix(data[6...7].copiedUInt16),
                    isMPPTInputOn: flags & 0b0000_0000_0010_0000 > 0,
                    mpptInputWatt: endian.fix(data[12...13].copiedUInt16),
                    isBatteryInputOn: flags & 0b0000_0000_0000_0000 > 0,
                    batteryInputWatt: endian.fix(data[20...21].copiedUInt16)
                )
            }
            
            return result
        }()
        
        return [
            "evOn": flags & 0b0000_0000_0100_0000 > 0,
            "ev": endian.fix(data[14...15].copiedUInt16), // as W
            "BSensorInputOn": flags & 0b0000_0100_0000_0000 > 0,
            "BSensorInput": endian.fix(data[22...23].copiedUInt16), // as W
        ].merging(inputs, uniquingKeysWith: { (_, new) in new })
    }
    
    func parse(getInverterOutputInfoData data: Data) throws -> [String: Any] {
        guard data.count >= 24 else { throw CorruptedData() }
        
        let flags = endian.fix(data[0...1].copiedUInt16)
        
        func parse(
            inverterInIsOn: Bool,
            inverterInWatt: UInt16,
            otherOutIsOn: Bool,
            otherOutWatt: UInt16,
            batteryIsOn: Bool,
            batteryWatt: UInt16
        ) -> [String: Any] {
            return [
                // inverter -> plant
                "inverterInOn": inverterInIsOn,
                "inverterIn": inverterInWatt, // as W
                
                // inverter -> other
                "otherOutOn": otherOutIsOn,
                "otherOut": otherOutWatt, // as W
                
                // inverter -> battery
                "batteryOn": batteryIsOn,
                "battery": batteryWatt, // as W
            ]
        }
        
        let inverterOutputs: [String: Any] = {
            var result: [String: Any] = [
                "0": parse(
                    inverterInIsOn: flags & 0b0000_0000_0001_0000 > 0,
                    inverterInWatt: endian.fix(data[10...11].copiedUInt16),
                    otherOutIsOn: flags & 0b0000_0000_0000_0001 > 0,
                    otherOutWatt: endian.fix(data[2...3].copiedUInt16),
                    batteryIsOn: flags & 0b0000_0000_1000_0000 > 0,
                    batteryWatt: endian.fix(data[16...17].copiedUInt16)
                )
            ]
            
            switch phase {
            case .single: break
            case .three:
                result["1"] = parse(
                    inverterInIsOn: flags & 0b0000_0000_0010_0000 > 0,
                    inverterInWatt: endian.fix(data[12...13].copiedUInt16),
                    otherOutIsOn: flags & 0b0000_0000_0000_0010 > 0,
                    otherOutWatt: endian.fix(data[4...5].copiedUInt16),
                    batteryIsOn: flags & 0b0000_0001_0000_0000 > 0,
                    batteryWatt: endian.fix(data[18...19].copiedUInt16)
                )
                result["2"] = parse(
                    inverterInIsOn: flags & 0b0000_0000_0100_0000 > 0,
                    inverterInWatt: endian.fix(data[14...15].copiedUInt16),
                    otherOutIsOn: flags & 0b0000_0000_0000_0100 > 0,
                    otherOutWatt: endian.fix(data[6...7].copiedUInt16),
                    batteryIsOn: flags & 0b0000_0010_0000_0000 > 0,
                    batteryWatt: endian.fix(data[20...21].copiedUInt16)
                )
            }
            
            return result
        }()
        
        return [
            "evOn": flags & 0b0000_0000_0000_1000 > 0,
            "ev": endian.fix(data[8...9].uint16), // as W
            "BSensorOutputOn": flags & 0b0000_0100_0000_0000 > 0,
            "BSensorOutput": endian.fix(data[22...23].copiedInt16), // as W
        ].merging(inverterOutputs, uniquingKeysWith: { (_, new) in new })
    }
    
    func parse(resetInverter data: Data) throws -> [String: Any] {
        guard data.count >= 1 else { throw CorruptedData() }
        
        return [
            "delay": data[0].int,
        ]
    }
    
    fileprivate func extractedFunc(_ data: inout Data, _ modelLengthByteIndex: Int, _ modelLengthByte: UInt8, _ versionLengthByteIndex: Int, _ versionLengthByte: UInt8, _ indexByteIndex: Int, _ state: DinStorageBatteryInverterState, _ fanState: DinStorageBatteryInverterFanState) -> [String : Any] {
        return [
            "idInfo": asciiString(
                from: &data,
                startIndex: modelLengthByteIndex + 1,
                length: Int(bitPattern: UInt(modelLengthByte))
            ),
            "version": hexString(
                from: &data,
                startIndex: versionLengthByteIndex + 1,
                length: Int(bitPattern: UInt(versionLengthByte))
            ),
            "index": Int(bitPattern: UInt(data[indexByteIndex])),
            "state": state.rawValue,
            "vertBatteryExceptions": {
                return parse(exceptions: InverterBatteryException.self, from: endian.fix(data[1...2].copiedUInt16))
            }(),
            "vertExceptions": {
                return parse(exceptions: InverterException.self, from: endian.fix(data[3...4].copiedUInt16))
            }(),
            "vertGridExceptions": {
                return parse(exceptions: InverterGridException.self, from: endian.fix(data[5...6].copiedUInt16))
            }(),
            "vertSystemExceptions": {
                return parse(exceptions: InverterSystemException.self, from: endian.fix(data[7...8].copiedUInt16))
            }(),
            "vertmpptExceptions": {
                return parse(exceptions: InverterMPPTException.self, from: endian.fix(data[9...10].copiedUInt16))
            }(),
            "vertPresentExceptions": {
                return parse(exceptions: InverterPresentException.self, from: endian.fix(data[11...12].copiedUInt16))
            }(),
            "vertDCExceptions": {
                return parse(exceptions: InverterDCException.self, from: endian.fix(data[13...14].copiedUInt16))
            }(),
            "fanState": fanState.rawValue,
        ]
    }
    
    func parse(getInverterInfoData data: Data) throws -> [String: Any] {
        
        var data = data
        
        let modelLengthByteIndex = 15
        guard data.endIndex > modelLengthByteIndex else { throw CorruptedData() }
        let modelLengthByte = data[modelLengthByteIndex]
        
        let versionLengthByteIndex = modelLengthByteIndex + Int(bitPattern: UInt(modelLengthByte)) + 1
        guard data.endIndex > versionLengthByteIndex else { throw CorruptedData() }
        let versionLengthByte = data[versionLengthByteIndex]
        
        let fanStateByteIndex = versionLengthByteIndex + Int(bitPattern: UInt(versionLengthByte)) + 1
        guard data.endIndex > fanStateByteIndex else { throw CorruptedData() }
        guard let fanState = DinStorageBatteryInverterFanState.value(from: data[fanStateByteIndex]) else { throw CorruptedData() }
        
        let indexByteIndex = fanStateByteIndex + 1
        guard data.endIndex > indexByteIndex else { throw CorruptedData() }
        
        guard let state = DinStorageBatteryInverterState.value(from: data[0]) else { throw CorruptedData() }
        
        return extractedFunc(&data, modelLengthByteIndex, modelLengthByte, versionLengthByteIndex, versionLengthByte, indexByteIndex, state, fanState)
    }
    
    func parse(inverterExceptionData data: Data) throws -> [String: Any] {
        guard data.count >= 3 else { throw CorruptedData() }
        
        return [
            "index": Int(bitPattern: UInt(data[0])),
            "vertBatteryExceptions": parse(exceptions: InverterBatteryException.self, from: endian.fix(data[1...2].copiedUInt16)),
            "vertExceptions": parse(exceptions: InverterException.self, from: endian.fix(data[3...4].copiedUInt16)),
            "vertGridExceptions": parse(exceptions: InverterGridException.self, from: endian.fix(data[5...6].copiedUInt16)),
            "vertSystemExceptions": parse(exceptions: InverterSystemException.self, from: endian.fix(data[7...8].copiedUInt16)),
            "vertmpptExceptions": parse(exceptions: InverterMPPTException.self, from: endian.fix(data[9...10].copiedUInt16)),
            "vertPresentExceptions": parse(exceptions: InverterPresentException.self, from: endian.fix(data[11...12].copiedUInt16)),
            "vertDCExceptions": parse(exceptions: InverterDCException.self, from: endian.fix(data[13...14].copiedUInt16)),
        ]
    }
    
    func parse(batchGetBatteryInfoData data: Data) throws -> [String: Any] {
        guard data.count >= 29 else { throw CorruptedData() }
        
        return [
            "count": Int(bitPattern: UInt(data[28])),
            "highVolt": endian.fix(data[0...1].copiedUInt16), // as mV
            "lowVolt": endian.fix(data[2...3].copiedUInt16), // as mV
            "totalVolt": endian.fix(data[4...5].copiedUInt16), // as mV
            "bmsLowTemp": Double(endian.fix(data[6...7].copiedUInt16)) / 10.0, // as K
            "bmsHighTemp": Double(endian.fix(data[8...9].copiedInt16)) / 10.0, // as K
            "electrodeLowTemp": Double(endian.fix(data[10...11].copiedInt16)) / 10.0, // as K
            "electrodeHighTemp": Double(endian.fix(data[12...13].copiedInt16)) / 10.0, // as K
            "soc": endian.fix(data[14...15].copiedUInt16), // as Percent
            "ampere": endian.fix(data[16...19].copiedInt32), // as mA
            "curPower": Double(endian.fix(data[20...21].copiedUInt16)), // as Ah
            "fullPower": Double(endian.fix(data[22...23].copiedUInt16)), // as Ah
            "remainTime": endian.fix(data[24...25].copiedUInt16), // as mins
            "chargeTime": endian.fix(data[26...27].copiedUInt16), // as mins
        ]
    }
    
    func parse(batteryAccessoryStateChangedNotifyData data: Data) throws -> [String: Any] {
        guard data.count >= 2 else { throw CorruptedData() }
        
        let heatingStatus = BatteryHeatingStatus(rawValue: data[1])
        return [
            "index": Int(bitPattern: UInt(data[0])),
            "heating": heatingStatus == .heating,
            "heatAvailable": heatingStatus != nil && heatingStatus! != .unavailable,
        ]
    }
    
    func parse(batteryAccessoryStateChangedCustomNotifyData data: Data) throws -> [String: Any] {
        guard data.count >= 4 else { throw CorruptedData() }
        
        let heatingStatus = BatteryHeatingStatus(rawValue: data[1])
        return [
            "index": Int(bitPattern: UInt(data[0])),
            "cabinetIndex": Int(bitPattern: UInt(data[2])),
            "cabinetPositionIndex": Int(bitPattern: UInt(data[3])),
            "heating": heatingStatus == .heating,
            "heatAvailable": heatingStatus != nil && heatingStatus! != .unavailable,
        ]
    }
    
    func parse(getBatteryInfoByIndexData data: Data) throws -> [String: Any] {
        
        var data = data
        
        let modelLengthByteIndex = 24
        guard data.endIndex > modelLengthByteIndex else { throw CorruptedData() }
        let bytesCountOfModel = data[modelLengthByteIndex]
        
        let versionLengthByteIndex = modelLengthByteIndex + Int(bitPattern: UInt(bytesCountOfModel)) + 1
        guard data.endIndex > versionLengthByteIndex else { throw CorruptedData() }
        let bytesCountOfVersion = data[versionLengthByteIndex]
        
        let barCodeLengthByteIndex = versionLengthByteIndex + Int(bitPattern: UInt(bytesCountOfVersion)) + 1
        guard data.endIndex > barCodeLengthByteIndex else { throw CorruptedData() }
        let bytesCountOfBarCode = data[barCodeLengthByteIndex]
        
        let cabinetSectionByteIndex = barCodeLengthByteIndex + Int(bitPattern: UInt(bytesCountOfBarCode)) + 1
        let cabinetRowByteIndex = cabinetSectionByteIndex + 1
        let indexByteIndex = cabinetRowByteIndex + 1
        let capacityIndexRange = (indexByteIndex + 1)...(indexByteIndex + 2)
        
        guard data.endIndex > capacityIndexRange.upperBound else { throw CorruptedData() }
        
        // 表示状态的 Uint16, 前两个 bit 表示DFETON和CFETON
        let dfetOn = data[0] & 0x01 == 1
        let cfetOn = data[0] >> 1 & 0x01 == 1
        
        return [
            "dischargeSwitchOn": dfetOn,
            "chargeSwitchOn": cfetOn,
            "exceptions": parse(exceptions: BatteryException.self, from: endian.fix(data[0...1].copiedUInt16) >> 2),
            "bmsTemp": Double(endian.fix(data[2...3].copiedUInt16)) / 10.0, // as K
            "electrodeATemp": Double(endian.fix(data[4...5].copiedUInt16)) / 10.0, // as K
            "electrodeBTemp": Double(endian.fix(data[6...7].copiedUInt16)) / 10.0, // as K
            "ampere": endian.fix(data[10...13].copiedInt32), // as mA
            "voltage": endian.fix(data[8...9].copiedUInt16), // as mV
            "soc": endian.fix(data[14...15].copiedUInt16), // as Percent
            "curPower": Double(endian.fix(data[16...17].copiedUInt16)) / 100, // as Ah
            "fullPower": Double(endian.fix(data[18...19].copiedUInt16)) / 100, // as Ah
            "releaseTimes": endian.fix(data[20...21].copiedUInt16),
            "healthy": endian.fix(data[22...23].copiedUInt16), // as Percent
            "idInfo": asciiString(from: &data, startIndex: modelLengthByteIndex + 1, length: Int(bitPattern: UInt(bytesCountOfModel))),
            "version": hexString(from: &data, startIndex: versionLengthByteIndex + 1, length: Int(bitPattern: UInt(bytesCountOfVersion))),
            "barcode": asciiString(from: &data, startIndex: barCodeLengthByteIndex + 1, length: Int(bitPattern: UInt(bytesCountOfBarCode))),
            "index": Int(bitPattern: UInt(data[indexByteIndex])),
            "cabinetIndex": Int(bitPattern: UInt(data[cabinetSectionByteIndex])),
            "cabinetPositionIndex": Int(bitPattern: UInt(data[cabinetRowByteIndex])),
            "capacity": endian.fix(data[capacityIndexRange].copiedUInt16),
        ]
    }
    
    func parse(batteryExceptionsNotifyData data: Data) throws -> [String: Any] {
        guard data.count >= 5 else { throw CorruptedData() }
        return [
            "index": Int(bitPattern: UInt(data[0])),
            "exceptions": parse(exceptions: BatteryException.self, from: endian.fix(data[1...2].copiedUInt16 >> 2)),
            "cabinetIndex": Int(bitPattern: UInt(data[3])),
            "cabinetPositionIndex": Int(bitPattern: UInt(data[4])),
        ]
    }
    
    func parse(getBatteryAccessoryStateData data: Data) throws -> [String: Any] {
        guard data.count >= 2 else { throw CorruptedData() }
        
        return [
            "heating": data[0] == 0x02,
            "heatAvailable": data[0] != 0x00,
            "index": Int(bitPattern: UInt(data[1])),
        ]
    }
    
    private func parse(evException value: UInt16) -> [Int] {
        let result: [Int] = EVException.allCases.reduce(into: []) { partialResult, exception in
            if value & exception.hitTestBits != 0 {
                partialResult.append(exception.rawValue)
            }
        }
        return result
    }
    
    func parse(getGlobalLoadStateData data: Data) throws -> [String: Any] {
        guard data.count >= 1 else { throw CorruptedData() }
        
        return [
            "on": data[0] & 0b0000_0010 > 0,
            "evOn": data[0] & 0b0000_0001 > 0,
            "otherOn": data[0] & 0b0000_0100 > 0,
        ]
    }
    
    func parse(getGlobalExceptionsData data: Data) throws -> [String: Any] {
        guard data.count >= 26 else { throw CorruptedData() }
        
        return [
            "vertBatteryExceptions": parse(exceptions: InverterBatteryException.self, from: endian.fix(data[0...1].copiedUInt16)),
            "vertExceptions": parse(exceptions: InverterException.self, from: endian.fix(data[2...3].copiedUInt16)),
            "vertGridExceptions": parse(exceptions: InverterGridException.self, from: endian.fix(data[4...5].copiedUInt16)),
            "vertSystemExceptions": parse(exceptions: InverterSystemException.self, from: endian.fix(data[6...7].copiedUInt16)),
            "vertmpptExceptions": parse(exceptions: InverterMPPTException.self, from: endian.fix(data[8...9].copiedUInt16)),
            "vertPresentExceptions": parse(exceptions: InverterPresentException.self, from: endian.fix(data[10...11].copiedUInt16)),
            "vertDCExceptions": parse(exceptions: InverterDCException.self, from: endian.fix(data[12...13].copiedUInt16)),
            "ev": parse(exceptions: EVException.self, from: endian.fix(data[14...15].copiedUInt16)),
            "mppt": parse(exceptions: MPPTException.self, from: endian.fix(data[16...17].copiedUInt16)),
            "cabinet": parse(exceptions: CabinetException.self, from: endian.fix(data[18...19].copiedUInt16)),
            "battery": parse(exceptions: BatteryException.self, from: endian.fix(data[20...21].copiedUInt16 >> 2)),
            "system": parse(exceptions: SystemException.self, from: endian.fix(data[22...23].copiedUInt16)),
            "communication": parse(exceptions: CommunicationException.self, from: endian.fix(data[24...25].copiedUInt16)),
        ]
    }
    
    func parse(systemExceptionsNotifyData data: Data) throws -> [String: Any] {
        guard data.count >= 2 else { throw CorruptedData() }
        
        return [
            "exceptions": parse(exceptions: SystemException.self, from: endian.fix(data[0...1].copiedUInt16)),
        ]
    }
    
    func parse(communicationExceptionsNotifyData data: Data) throws -> [String: Any] {
        guard data.count >= 2 else { throw CorruptedData() }
        
        return [
            "exceptions": parse(exceptions: CommunicationException.self, from: endian.fix(data[0...1].copiedUInt16)),
        ]
    }
    
    func parse(getMCUInfoData data: Data) throws -> [String: Any] {
        var data = data
        
        let modelLengthByteIndex = 0
        guard data.endIndex > modelLengthByteIndex else { throw CorruptedData() }
        let bytesCountOfModel = data[modelLengthByteIndex]
        
        let versionLengthByteIndex = modelLengthByteIndex + Int(bitPattern: UInt(bytesCountOfModel)) + 1
        guard data.endIndex > versionLengthByteIndex else { throw CorruptedData() }
        let bytesCountOfVersion = data[versionLengthByteIndex]
        
        let barCodeLengthByteIndex = versionLengthByteIndex + Int(bitPattern: UInt(bytesCountOfVersion)) + 1
        guard data.endIndex > barCodeLengthByteIndex else { throw CorruptedData() }
        let bytesCountOfBarCode = data[barCodeLengthByteIndex]
        
        guard data.count >= 3 + Int(bitPattern: UInt(bytesCountOfModel + bytesCountOfVersion + bytesCountOfBarCode)) else { throw CorruptedData() }
        
        return [
            "idInfo": asciiString(from: &data, startIndex: modelLengthByteIndex + 1, length: bytesCountOfModel.int),
            "version": hexString(from: &data, startIndex: versionLengthByteIndex + 1, length: bytesCountOfVersion.int),
            "barcode": asciiString(from: &data, startIndex: barCodeLengthByteIndex + 1, length: bytesCountOfBarCode.int),
        ]
    }
    
    func parse(getCabinetStateData data: Data) throws -> [String: Any] {
        var data = data
        let versionLenghtByteIndex = 4
        guard data.endIndex > versionLenghtByteIndex else { throw CorruptedData() }
        let bytesCountOfVersion = data[versionLenghtByteIndex]
        guard
            let waterState = DinStorageBatteryCabinetWaterState.value(from: data[0]),
            let smokeState = CabinetSmokeState.value(from: data[1]),
            let fanState = DinStorageBatteryCabinetFanState.value(from: data[2])
        else { throw CorruptedData() }
        let indexIndex = versionLenghtByteIndex + Int(bitPattern: UInt(bytesCountOfVersion)) + 1
        /// This is the "one-past-the-end" position, and will always be equal to the `count`.
        guard data.endIndex > indexIndex else { throw CorruptedData() }
        return [
            "waterState": waterState.rawValue,
            "smokeState": smokeState.rawValue,
            "fanState": fanState.rawValue,
            "exceptions": data[3] & 0b0000_0001 > 0 ? [CabinetException.communicationException.rawValue] : [],
            "version": hexString(from: &data, startIndex: versionLenghtByteIndex + 1, length: bytesCountOfVersion.int),
            "index": data[indexIndex].int,
        ]
    }
    
    func parse(cabinetStateChangedNotifyData data: Data) throws -> [String: Any] {
        guard
            data.count >= 4,
            let waterState = DinStorageBatteryCabinetWaterState.value(from: data[1]),
            let smokeState = CabinetSmokeState.value(from: data[2]),
            let fanState = DinStorageBatteryCabinetFanState.value(from: data[3])
        else { throw CorruptedData() }
        
        return [
            "waterState": waterState.rawValue,
            "smokeState": smokeState.rawValue,
            "fanState": fanState.rawValue,
            "index": data[0].int,
        ]
    }
    
    func parse(cabinetExceptionChangedNotifyData data: Data) throws -> [String: Any] {
        guard data.count >= 3 else { throw CorruptedData() }
        
        return [
            "exceptions": parse(exceptions: CabinetException.self, from: endian.fix(data[1...2].copiedUInt16)),
            "index": data[0].int,
        ]
    }
    
    func parse(getMPPTStateData data: Data) throws -> [String: Any] {
        guard data.count >= 7 else { throw CorruptedData() }
        
        var result: [String: Any] = [
            "0On": data[0] & 0b0000_0001 > 0,
            "0": parse(exceptions: MPPTException.self, from: endian.fix(data[1...2].copiedUInt16)),
        ]
        
        switch phase {
        case .single: break
        case .three:
            result["1On"] = data[0] & 0b0000_0010 > 0
            result["1"] = parse(exceptions: MPPTException.self, from: endian.fix(data[3...4].copiedUInt16))
            
            result["2On"] = data[0] & 0b0000_0100 > 0
            result["2"] = parse(exceptions: MPPTException.self, from: endian.fix(data[5...6].copiedUInt16))
        }
        
        return result
    }
    
    func parse(mpptExceptionsNotifyData data: Data) throws -> [String: Any] {
        guard data.count >= 2 else { throw CorruptedData() }
        
        return [
            "index": data[0].int,
            "exceptions": parse(exceptions: MPPTException.self, from: endian.fix(data[1...2].copiedUInt16)),
        ]
    }
    
    func parse(getEVStateData data: Data) throws -> [String: Any] {
        guard
            data.count >= 4,
            let state = DinStorageBatteryEVState.value(from: data[0]),
            let lightState = DinStorageBatteryEVLightState.value(from: data[1])
        else { throw CorruptedData() }
        
        return [
            "state": state.rawValue,
            "lightState": lightState.rawValue,
            "exceptions": parse(exceptions: EVException.self, from: endian.fix(data[2...3].copiedUInt16)),
        ]
    }
    
    func parse(evExceptionsNotifyData data: Data) throws -> [String: Any] {
        guard data.count >= 3,
              let detailState = DinStorageBatteryEVDetailState.value(from: data[2])
        else { throw CorruptedData() }
        return ["exceptions": parse(exceptions: EVException.self, from: endian.fix(data[0...1].copiedUInt16)),
                "detailState": detailState.rawValue,
        ]
    }
    
    func parse(batteryIndexChangedNotifyData data: Data) throws -> [String: Any] {
        guard data.count >= 4 else { throw CorruptedData() }
        
        return [
            "index": data[1].int,
            "isAdd": data[0] == 0x01,
            "cabinetIndex": data[2].int,
            "cabinetPositionIndex": data[3].int,
        ]
    }
    
    func parse(batteryStatusInfoNotifyData data: Data) throws -> [String: Any] {
        guard data.count >= 1,
              let state = DinStorageBatterySOCState.value(from: data[0])
        else { throw CorruptedData() }
        return ["socState": state.rawValue]
    }
    
    func parse(cabinetIndexChangedNotifyData data: Data) throws -> [String: Any] {
        guard data.count >= 2 else { throw CorruptedData() }
        
        return [
            "isAdd": data[0] == 0x01,
            "index": data[1].int,
        ]
    }
    
    func parse(getCabinetInfoData data: Data) throws -> [String: Any] {
        guard data.count >= 1 else { throw CorruptedData() }
        
        return [
            "count": data[0].int,
        ]
    }
    
    func parse(getEmergencyChargeSettingsData data: Data) throws -> [String: Any] {
        guard data.count >= 9 else { throw CorruptedData() }
        
        return [
            "startTime": TimeInterval(endian.fix(data[1...4].copiedUInt32)),
            "endTime": TimeInterval(endian.fix(data[5...8].copiedUInt32)),
            "on": data[0] == 0x01,
        ]
    }
    
    func parse(getGridChargeMarginData data: Data) throws -> [String: Any] {
        guard data.count >= 4 else { throw CorruptedData() }

        return [
            "gridMargin": Int(endian.fix(data[0...3].copiedUInt32))
        ]
    }
    
    func parse(getChargingStrategiesData data: Data) throws -> [String: Any] {
        guard
            data.count >= 9,
            let strategy = DinStorageBatteryCharingStrategy.value(from: data[0])
        else { throw CorruptedData() }
        
        return [
            "strategyType": strategy.rawValue,
            "smartReserve": data[1].int, // as Percent
            "goodPricePercentage": (data[3] == 0x01) ? Int(endian.fix(data[4...5].copiedUInt16)) : -1,
            "emergencyReserve": data[2].int,
            "acceptablePricePercentage": (data[6] == 0x01) ? Int(endian.fix(data[7...8].copiedUInt16)) : -1,
        ]
    }
    
    func parse(getVirtualPowerPlantData data: Data) throws -> [String: Any] {
        guard data.count >= 1 else { throw CorruptedData() }
        
        return ["on": data[0] == 0x01]
    }
    
    func parse(getSellingProtectionData data: Data) throws -> [String: Any] {
        guard data.count >= 2 else { throw CorruptedData() }
        return ["firstUse": data[0].bool, "on": data[1].bool, "threshold": endian.fix(data[2...5].copiedUInt32)]
    }

    func parse(getSignalsData data: Data) throws -> [String: Any] {
        guard data.count >= 4 else { throw CorruptedData() }
        // 如果没有以太网信号数据，默认没有连接以太网
        let ethernetSignal = data.count >= 5 ? data[4].int + 1 : 1
        // 0x00 没信号；0x01 弱；0x02 良好；0x03 强；
        return [
            "wifi": data[0].int + 1,
            "cellular": data[1].int + 1,
            "wifiRSSI": -data[2].int,
            "cellularRSSI": -data[3].int,
            "ethernet": ethernetSignal
        ]
    }
    
    func parse(getAdvanceInfoData data: Data) throws -> [String: Any] {
        var data = data
        
        let wifiNameLengthByteIndex = 0
        guard data.endIndex > wifiNameLengthByteIndex else { throw CorruptedData() }
        let bytesCountOfWifiName = data[wifiNameLengthByteIndex]
        
        let ipLengthByteIndex = wifiNameLengthByteIndex + Int(bitPattern: UInt(bytesCountOfWifiName)) + 1
        guard data.endIndex > ipLengthByteIndex else { throw CorruptedData() }
        let bytesCountOfIP = data[ipLengthByteIndex]
        
        let macLengthByteIndex = ipLengthByteIndex + Int(bitPattern: UInt(bytesCountOfIP)) + 1
        guard data.endIndex > macLengthByteIndex else { throw CorruptedData() }
        let bytesCountOfMAC = data[macLengthByteIndex]
        
        let versionLengthByteIndex = macLengthByteIndex + Int(bitPattern: UInt(bytesCountOfMAC)) + 1
        guard data.endIndex > versionLengthByteIndex else { throw CorruptedData() }
        let bytesCountOfVersion = data[versionLengthByteIndex]
        
        // 计算旧版本的最大数据长度
        let oldVersionLength = 4 + Int(bitPattern: UInt(bytesCountOfWifiName + bytesCountOfIP + bytesCountOfMAC + bytesCountOfVersion))
        
        // 初版
        guard data.count > oldVersionLength else {
            // 旧版本解析
            return [
                "wifiName": asciiString(from: &data, startIndex: wifiNameLengthByteIndex + 1, length: bytesCountOfWifiName.int),
                "ip": asciiString(from: &data, startIndex: ipLengthByteIndex + 1, length: bytesCountOfIP.int),
                "mac": asciiString(from: &data, startIndex: macLengthByteIndex + 1, length: bytesCountOfMAC.int),
                "version": asciiString(from: &data, startIndex: versionLengthByteIndex + 1, length: bytesCountOfVersion.int),
                "hardware_version": "",
                "ethernet_ip": "",
                "ethernet_mac": "",
                "realVersion": "v0.0.0",
            ]
        }
        
        // v2
        let hardwareVersionLengthByteIndex = versionLengthByteIndex + Int(bitPattern: UInt(bytesCountOfVersion)) + 1
        guard data.endIndex > hardwareVersionLengthByteIndex else { throw CorruptedData() }
        let bytesCountOfHardwareVersion = data[hardwareVersionLengthByteIndex]
        
        let ethernetIpLengthByteIndex = hardwareVersionLengthByteIndex + Int(bitPattern: UInt(bytesCountOfHardwareVersion)) + 1
        guard data.endIndex > ethernetIpLengthByteIndex else { throw CorruptedData() }
        let bytesCountOfEthernetIp = data[ethernetIpLengthByteIndex]
        
        let ethernetMacLengthByteIndex = ethernetIpLengthByteIndex + Int(bitPattern: UInt(bytesCountOfEthernetIp)) + 1
        guard data.endIndex > ethernetMacLengthByteIndex else { throw CorruptedData() }
        let bytesCountOfEthernetMac = data[ethernetMacLengthByteIndex]
        
        let v2VersionLength = 7 + Int(bitPattern: UInt(bytesCountOfWifiName + bytesCountOfIP + bytesCountOfMAC + bytesCountOfVersion + bytesCountOfHardwareVersion + bytesCountOfEthernetIp + bytesCountOfEthernetMac))
        
        guard data.count > v2VersionLength else {
            return [
                "wifiName": asciiString(from: &data, startIndex: wifiNameLengthByteIndex + 1, length: bytesCountOfWifiName.int),
                "ip": asciiString(from: &data, startIndex: ipLengthByteIndex + 1, length: bytesCountOfIP.int),
                "mac": asciiString(from: &data, startIndex: macLengthByteIndex + 1, length: bytesCountOfMAC.int),
                "version": asciiString(from: &data, startIndex: versionLengthByteIndex + 1, length: bytesCountOfVersion.int),
                "hardware_version": asciiString(from: &data, startIndex: hardwareVersionLengthByteIndex + 1, length: bytesCountOfHardwareVersion.int),
                "ethernet_ip": asciiString(from: &data, startIndex: ethernetIpLengthByteIndex + 1, length: bytesCountOfEthernetIp.int),
                "ethernet_mac": asciiString(from: &data, startIndex: ethernetMacLengthByteIndex + 1, length: bytesCountOfEthernetMac.int),
                "realVersion": "v0.0.0",
            ]
        }
        
        // v3
        let realVersionLengthByteIndex = ethernetMacLengthByteIndex + Int(bitPattern: UInt(bytesCountOfEthernetMac)) + 1
        guard data.endIndex > realVersionLengthByteIndex else { throw CorruptedData() }
        let bytesCountOfRealVersion = data[realVersionLengthByteIndex]
        
        return [
            "wifiName": asciiString(from: &data, startIndex: wifiNameLengthByteIndex + 1, length: bytesCountOfWifiName.int),
            "ip": asciiString(from: &data, startIndex: ipLengthByteIndex + 1, length: bytesCountOfIP.int),
            "mac": asciiString(from: &data, startIndex: macLengthByteIndex + 1, length: bytesCountOfMAC.int),
            "version": asciiString(from: &data, startIndex: versionLengthByteIndex + 1, length: bytesCountOfVersion.int),
            "hardware_version": asciiString(from: &data, startIndex: hardwareVersionLengthByteIndex + 1, length: bytesCountOfHardwareVersion.int),
            "ethernet_ip": asciiString(from: &data, startIndex: ethernetIpLengthByteIndex + 1, length: bytesCountOfEthernetIp.int),
            "ethernet_mac": asciiString(from: &data, startIndex: ethernetMacLengthByteIndex + 1, length: bytesCountOfEthernetMac.int),
            "realVersion": asciiString(from: &data, startIndex: realVersionLengthByteIndex + 1, length: bytesCountOfRealVersion.int)
        ]
    }
    
    func parse(getModeData data: Data) throws -> [String: Any] {
        guard data.count >= 4 else { throw CorruptedData() }
        // 0x01 模式1；0x02 模式2；0x03 模式3（default）；0x04 模式4；
        switch data[3] {
        case 0x01:
            return ["mode": 1]
        case 0x02:
            return ["mode": 2]
        case 0x03:
            return ["mode": 3]
        case 0x04:
            return ["mode": 4]
        default:
            return ["mode": 0]
        }
    }
    
    func parse(getModeV2Data data: Data) throws -> [String: Any] {
        guard data.count >= 3 else { throw CorruptedData() }
        // 0x01 模式1；0x02 模式2；0x03 模式3（default）；0x04 模式4；
        switch data[0] {
        case 0x01:
            return ["mode": 1]
        case 0x02:
            return ["mode": 2]
        case 0x03:
            return ["mode": 3]
        case 0x04:
            return ["mode": 4]
        default:
            return ["mode": 0]
        }
    }
    
    func parse(getChipsStatus data: Data) throws -> [String: Any] {
        guard data.count >= 1 else { throw CorruptedData() }
        let status = data[0] <= 0x03 ? data[0].int : 0
        return ["status": status]
    }
    
    func parse(getChipsUpdateProgress data: Data) throws -> [String: Any] {
        guard data.count >= 2 else { throw CorruptedData() }
        let status = data[1] <= 0x03 ? data[1].int : 0
        
        var error: [Int] = []
        if data.count >= 4 {
            error = parse(exceptions: ChipsProgressError.self, from: endian.fix(data[2...3].copiedUInt16))
        }
        
        return [
            "progress": data[0].int,
            "failed": data[0].int == 255,
            "status": status,
            "error": error,
        ]
    }
    
    func parse(updateChips data: Data) throws -> [String: Any] {
        guard data.count >= 2 else { throw CorruptedData() }
        let status = data[1] <= 0x03 ? data[1].int : 0
        return [
            "error": data[0].int,
            "status": status
        ]
    }
    
    func parse(reserveMode data: Data) throws -> [String: Any] {
        guard
            data.count >= 2,
            let reserveMode = DinStorageBatteryReserveMode.value(from: data[0])
        else { throw CorruptedData() }
        
        return [
            "reserveMode": reserveMode.rawValue,
            "isPriceTrackingSupported": data[1] == 0x01
        ]
    }
    
    func parse(priceTrackReserveMode data: Data) throws -> [String: Any] {
        guard data.count >= 11 else { throw CorruptedData() }
        
        return [
            "smart": data[0].int,
            "emergency": data[1].int,
            "lowpowerWarn": data[2].int,
            "lowpowerProtect": data[3].int,
            "c1": data[4].signedInt,
            "c2": data[5].signedInt,
            "c3": data[6].signedInt,
            "s1": data[7].signedInt,
            "s2": data[8].signedInt,
            "fullyReserve": data[9].int,
            "plentyReserve": data[10].int
        ]
    }
    
    func parse(scheduleReserveMode data: Data) throws -> [String: Any] {
        guard
            data.count >= 56
        else { throw CorruptedData() }
        var weekdays: [Int] = []
        for index in 4..<28 {
            weekdays.append(data[index].signedInt)
        }
        var weekend: [Int] = []
        for index in 28..<52 {
            weekend.append(data[index].signedInt)
        }
        return [
            "smart": data[0].int,
            "emergency": data[1].int,
            "lowpowerAlert": data[2].int,
            "batteryProtect": data[3].int,
            "weekdays": weekdays,
            "weekend": weekend,
            "sync": data[52] == 0x01,
            "fullCharge": Int(endian.fix(data[53...56].copiedUInt32))
        ]
    }
    
    func parse(customScheduleMode data: Data) throws -> [String: Any] {
        guard
            data.count >= 58
        else { throw CorruptedData() }
        var weekdays: [Int] = []
        
        let byte: Int8 = -128
        
        for index in 4..<28 {
            weekdays.append(data[index].signedInt)
        }
        var weekend: [Int] = []
        for index in 28..<52 {
            weekend.append(data[index].signedInt)
        }
        return [
            "smart": data[0].int,
            "emergency": data[1].int,
            "lowpowerAlert": data[2].int,
            "batteryProtect": data[3].int,
            "weekdays": weekdays,
            "weekend": weekend,
            "sync": data[52] == 0x01,
            "fullCharge": Int(endian.fix(data[53...56].copiedUInt32)),
            "type": data[57].int
        ]
    }
    
    func parse(customScheduleModeAI data: Data) throws -> [String: Any] {
        guard
            data.count >= 9
        else { throw CorruptedData() }
        
        let chargeDischargeDataLength = data[8].int
        guard data.count >= 9 + chargeDischargeDataLength else { throw CorruptedData() }
        
        var chargeDischargeData: [Int] = []
        for index in 9..<9+chargeDischargeDataLength {
            chargeDischargeData.append(data[index].signedInt)
        }
        return [
            "smart": data[0].int,
            "emergency": data[1].int,
            "type": data[2].int,
            "fullCharge": Int(endian.fix(data[3...6].copiedUInt32)),
            "timeGranularity": data[7].int,
            "chargeDischargeData": chargeDischargeData
        ]
    }
    
    func parse(currentEVChargingMode data: Data) throws -> [String: Any] {
        guard
            data.count >= 5,
            let mode = DinStorageBatteryEVChargingMode.value(from: data[0])
        else { throw CorruptedData() }
        return [
            "evChargingMode": mode.rawValue,
            "fixed": Int(endian.fix(data[1...2].copiedInt16)),
            "fixedFull": Int(endian.fix(data[3...4].copiedInt16)),
            "pricePercent": data[5].signedInt,
        ]
    }
    
    func parse(setEvchargingModeInstantcharge data: Data) throws -> [String: Any] {
        guard
            data.count >= 1,
            let mode = DinStorageBatteryEVChargingMode.value(from: data[0])
        else { throw CorruptedData() }
        return [
            "evChargingMode": mode.rawValue,
        ]
    }
    
    func parse(evChargingModeSchedule data: Data) throws -> [String: Any] {
        guard
            data.count >= 7
        else { throw CorruptedData() }
        var weekdays: [Int] = []
        for index in 0...2 {
            weekdays.append(contentsOf: splitUInt8IntoBits(data[index]))
        }
        var weekend: [Int] = []
        for index in 3...5 {
            weekend.append(contentsOf: splitUInt8IntoBits(data[index]))
        }
        return [
            "weekdays": weekdays,
            "weekend": weekend,
            "sync": data[6] == 0x01,
        ]
    }
    
    func parse(currentEVAdvanceStatus data: Data) throws -> [String: Any] {
        guard
            data.count >= 1,
            let mode = DinStorageBatteryEVAdvanceStatus.value(from: data[0])
        else { throw CorruptedData() }
        return [
            "advanceStatus": mode.rawValue,
        ]
    }
    
    func parse(evAdvancestatuschanged data: Data) throws -> [String: Any] {
        guard
            data.count >= 1,
            let mode = DinStorageBatteryEVAdvanceStatus.value(from: data[0])
        else { throw CorruptedData() }
        return [
            "advanceStatus": mode.rawValue,
        ]
    }
    
    func parse(evchargingInfo data: Data) throws -> [String: Any] {
        guard
            data.count >= 4
        else { throw CorruptedData() }
        
        return [
            "batteryCharged": Int(endian.fix(data[0...1].copiedUInt16)),
            "chargeTime": Int(endian.fix(data[2...3].copiedUInt16)),
        ]
    }
    
    func parse(getSmartEvStatus data: Data) throws -> [String: Any] {
        guard
            data.count >= 2,
            let toggleStatus = DinStorageBatterySmartEVToggleStatus(rawValue: data[0].signedInt)
        else { throw CorruptedData() }
        
        return [
            "toggleStatus": toggleStatus.rawValue,
            "shouldRestart": data[1] == 0x01
        ]
    }
    
    func parse(getGlobalCurrentFlowInfoData data: Data) throws -> [String: Any] {
        var data = data
        
        guard data.count >= 16
        else { throw CorruptedData() }
        
        var gridValid = true
        var bsensorValid = true
        
        if data.count >= 18 {
            gridValid = data[16] == 0x01
            bsensorValid = data[17] == 0x01
        }
        
        // 长度校验，在缺失的位置自动补0（0x00）
        // 以后如果有新增的数据位，也同样补0，0将当作 Unknown 来识别
        let expectedDataLength = 22
        if data.count < expectedDataLength {
            data.append(contentsOf: repeatElement(UInt8(0), count: expectedDataLength - data.count))
        }
        
        return [
            "batteryWat": Int(endian.fix(data[0...1].copiedInt16)),
            "solarWat": Int(endian.fix(data[2...3].copiedInt16)),
            "gridWat": Int(endian.fix(data[4...5].copiedInt16)),
            "additionLoadWat": Int(endian.fix(data[6...7].copiedInt16)),
            "otherLoadWat": Int(endian.fix(data[8...9].copiedInt16)),
            "vechiWat": Int(endian.fix(data[10...11].copiedInt16)),
            "ip2Wat": Int(endian.fix(data[12...13].copiedUInt16)),
            "op2Wat": Int(endian.fix(data[14...15].copiedUInt16)),
            "gridValid": gridValid,
            "bsensorValid": bsensorValid,
            "solarEfficiency": data[18].int,
            "thirdpartyPVOn": data[19] == 0x01,
            "dualPowerWat": Int(endian.fix(data[20...21].copiedInt16))
        ]
    }
    
    func parse(gridConnectionConfigData data: Data) throws -> [String: Any] {
        guard data.count >= 40
        else { throw CorruptedData() }
        
        return [
            "gridOvervoltage1ProtectTime": int16ToFloat(endian.fix(data[0...1].copiedInt16), decimalPlaces: 1),
            "gridOvervoltage2ProtectTime": int16ToFloat(endian.fix(data[2...3].copiedInt16), decimalPlaces: 1),
            "gridUndervoltage1ProtectTime": int16ToFloat(endian.fix(data[4...5].copiedInt16), decimalPlaces: 1),
            "gridUndervoltage2ProtectTime": int16ToFloat(endian.fix(data[6...7].copiedInt16), decimalPlaces: 1),
            
            "activeSoftStartRate": int16ToFloat(endian.fix(data[8...9].copiedInt16), decimalPlaces: 2),
            "appFastPowerDown": endian.fix(data[10...11].copiedInt16) == 1,
            "overfrequencyLoadShedding": int16ToFloat(endian.fix(data[12...13].copiedInt16), decimalPlaces: 2),
            "overfrequencyLoadSheddingSlope": int16ToFloat(endian.fix(data[14...15].copiedInt16), decimalPlaces: 2),
            "underfrequencyLoadShedding": int16ToFloat(endian.fix(data[16...17].copiedInt16), decimalPlaces: 2),
            
            "quMode": endian.fix(data[18...19].copiedInt16) == 1,
            "cosMode": endian.fix(data[20...21].copiedInt16) == 1,
            "antiislandingMode": endian.fix(data[22...23].copiedInt16) == 1,
            "highlowMode": endian.fix(data[24...25].copiedInt16) == 1,
            
            "powerFactor": int16ToFloat(endian.fix(data[26...27].copiedInt16), decimalPlaces: 2),
            "reconnectTime": int16ToFloat(endian.fix(data[28...29].copiedInt16), decimalPlaces: 1),
            "reconnectSlope": int16ToFloat(endian.fix(data[30...31].copiedInt16), decimalPlaces: 2),
            
            "gridOvervoltage1": int16ToFloat(endian.fix(data[32...33].copiedInt16), decimalPlaces: 1),
            "gridOvervoltage2": int16ToFloat(endian.fix(data[34...35].copiedInt16), decimalPlaces: 1),
            
            "gridUndervoltage1": int16ToFloat(endian.fix(data[36...37].copiedInt16), decimalPlaces: 1),
            "gridUndervoltage2": int16ToFloat(endian.fix(data[38...39].copiedInt16), decimalPlaces: 1),
            
            "gridOverfrequency1": int16ToFloat(endian.fix(data[40...41].copiedInt16), decimalPlaces: 2),
            "gridOverfrequency2": int16ToFloat(endian.fix(data[42...43].copiedInt16), decimalPlaces: 2),
            
            "gridUnderfrequency1": int16ToFloat(endian.fix(data[44...45].copiedInt16), decimalPlaces: 2),
            "gridUnderfrequency2": int16ToFloat(endian.fix(data[46...47].copiedInt16), decimalPlaces: 2),
            
            "powerPercent": int16ToFloat(endian.fix(data[48...49].copiedInt16), decimalPlaces: 2),
            "gridOverfrequencyProtectTime": Int(endian.fix(data[50...51].copiedInt16)),
            "gridUnderfrequencyProtectTime": Int(endian.fix(data[52...53].copiedInt16)),
            "underfrequencyLoadSheddingSlope": int16ToFloat(endian.fix(data[54...55].copiedInt16), decimalPlaces: 3),
            
            "rebootGridOvervoltage": int16ToFloat(endian.fix(data[56...57].copiedInt16), decimalPlaces: 2),
            "rebootGridUndervoltage": int16ToFloat(endian.fix(data[58...59].copiedInt16), decimalPlaces: 2),
            "rebootGridOverfrequency": int16ToFloat(endian.fix(data[60...61].copiedInt16), decimalPlaces: 1),
            "rebootGridUnderfrequency": int16ToFloat(endian.fix(data[62...63].copiedInt16), decimalPlaces: 1),
        ]
        
    }
    
    func parse(firmwaresData data: Data) throws -> [String: Any] {
        var data = data
        
        guard data.count >= 2 else {
            throw CorruptedData()
        }
        
        let versionInfoLength = data[1].int
        
        guard data.count >= 2 + versionInfoLength else {
            throw CorruptedData()
        }
        
        return [
            "type": data[0].int,
            "version": asciiString(from: &data, startIndex: 2, length: versionInfoLength)
        ]
    }
    
    func parse(fuseSpecsData data: Data) throws -> [String: Any] {
        var data = data
        
        guard data.count >= 3 else {
            throw CorruptedData()
        }
        
        let specLength = data[0].int
        
        guard data.count >= 3 + specLength else {
            throw CorruptedData()
        }
        
        return [
            "spec": asciiString(from: &data, startIndex: 1, length: specLength),
            "power_cap": Int(endian.fix(data[(specLength+1)...(specLength+2)].copiedUInt16))
        ]
    }
    
    func parse(getThirdPartyPVInfoData data: Data) throws -> [String: Any] {
        guard data.count >= 1 else { throw CorruptedData() }
        
        return ["on": data[0] == 0x01]
    }
    
    func parse(setThirdPartyPVOnData data: Data) throws -> [String: Any] {
        guard data.count >= 3 else { throw CorruptedData() }
        
        let errorValue = endian.fix(data[1...2].copiedUInt16)
        let errors: [Int] = ThirdPartyPVActiveError.allCases.reduce(into: []) { partialResult, error in
            if errorValue & error.hitTestBits != 0 {
                partialResult.append(error.rawValue)
            }
        }
        
        return [
            "error": errors,
            "on": data[0] == 0x01,
        ]
    }
    
    func parse(getBrightnessSettingsData data: Data) throws -> [String: Any] {
        guard data.count >= 3 else { throw CorruptedData() }

        let brightness = data[0...1].copiedUInt16
        let supported = data[2] == 0x01

        return [
            "brightness": Int(brightness),
            "supported": supported
        ]
    }
    
    func parse(getSoundSettingsData data: Data) throws -> [String: Any] {
        guard data.count >= 2 else { throw CorruptedData() }

        return [
            "systemTones": data[0] == 0x01,
            "reminderAlerts": data[1] == 0x01
        ]
    }
    
    func parse(getRegulateFrequencyState data: Data) throws -> [String: Any] {
        guard
            data.count >= 1,
            let mode = DinRegulateFrequencyState.value(from: data[0])
        else { throw CorruptedData() }
        return [
            "state": mode.rawValue,
        ]
    }
    
    func parse(pvDistData data: Data) throws -> [String: Any] {
        guard
            data.count >= 2,
            let ai = DinStorageBatteryPVPreference.value(from: data[0]),
            let scheduled = DinStorageBatteryPVPreference.value(from: data[1])
        else { throw CorruptedData() }
        
        return [
            "ai": ai.rawValue,
            "scheduled": scheduled.rawValue,
        ]
    }
    
    func parse(AllSupportFeatures data: Data) throws -> [String: Any] {
        guard data.count >= 2 else { throw CorruptedData() }
        
        return [
            "pvSupplyCustomizationSupported": data[0] == 0x01,
            "peakShavingSupported": data[1] == 0x01,
        ]
    }
    
    func parse(togglPeakShaving data: Data) throws -> [String: Any] {
        guard data.count >= 2 else { throw CorruptedData() }
        
        return [
            "error": Int(endian.fix(data[0...1].copiedUInt16)),
        ]
    }
    
    func parse(getPeakShavingConfig data: Data) throws -> [String: Any] {
        guard data.count >= 7 else { throw CorruptedData() }
        
        return [
            "isOn": data[0] == 0x01,
            "redundancy": Int(endian.fix(data[1...4].copiedUInt32)),
            "point1": data[5].int,
            "point2": data[6].int,
            "fullCharge": Int(endian.fix(data[7...10].copiedUInt32)),
            "frequencyCapacity": Int(endian.fix(data[11...14].copiedUInt32)),
            "emergency": data[15].int,
            "plenty": data[16].int,
            "smart": data[17].int,
            "lowpowerAlert": data[18].int,
            "isSupported": data[19] == 0x01
        ]
    }
    
    func parse(getPeakShavingSchedule data: Data) throws -> [String: Any] {
        guard data.count >= 2 else { throw CorruptedData() }
        let totalLength = Int(endian.fix(data[0...1].copiedUInt16))
        let singleLength = 26
        guard totalLength % singleLength == 0 else { throw CorruptedData() }
        let count = totalLength / singleLength
        let expectedLength = 2 + totalLength
        guard data.count >= expectedLength else { throw CorruptedData() }
        
        var schedules: [[String: Any]] = []
        
        for i in 0..<count {
            let startIndex = 2 + i * singleLength
            let endIndex = startIndex + singleLength
            let subdata = data.subdata(in: startIndex..<endIndex)
            
            let isAllDay = subdata[0] != 0
            let startSeconds = Int(endian.fix(subdata[1...4].copiedInt32))
            let endSeconds = Int(endian.fix(subdata[5...8].copiedInt32))
            let weekdaysBitmask = subdata[9].littleEndianData.weekdaysFromBitmask()
            let powerLimit = Int(endian.fix(subdata[10...13].copiedInt32))
            let createdAt = Int64(endian.fix(subdata[14...21].copiedInt64))
            let scheduleId = Int(endian.fix(subdata[22...25].copiedInt32))
            
            let schedule: [String: Any] = [
                "allDay": isAllDay,
                "start": startSeconds,
                "end": endSeconds,
                "weekdays": weekdaysBitmask,
                "limit": powerLimit,
                "createdAt":createdAt,
                "scheduleId":scheduleId
            ]
            
            schedules.append(schedule)
        }
        
        return [
            "schedules": schedules
        ]
    }
    
    // Helpers below
    private func asciiString(from data: inout Data, startIndex: Data.Index, length: Int) -> String {
        guard length > 0 else { return "" }
        let endIndex = data.index(startIndex, offsetBy: length)
        return data[startIndex..<endIndex].stringFromACSIIScalar
    }
    
    private func hexString(from data: inout Data, startIndex: Data.Index, length: Int) -> String {
        guard length > 0 else { return "" }
        let endIndex = data.index(startIndex, offsetBy: length)
        return data[startIndex..<endIndex].hexadecimalString()
    }
    
    private func parse<T: ExceptionRawIntValueConvertable>(exceptions: T.Type, from rawValue: T.TestValueType) -> [Int] {
        let result = T.allCases.compactMap { exception in
            (rawValue & exception.hitTestBits) > 0 ? exception.rawValue : nil
        }
        return result
    }
    
    func bitsToBytes(bits: [Int]) -> [UInt8] {
        var bytes: [UInt8] = []
        for (index, bit) in bits.enumerated() where bit == 1 {
            bytes[index/8] = bytes[index/8] + (1 << (7 - index % 8))
        }
        return bytes
    }
    
    func splitUInt8IntoBits(_ value: UInt8) -> [Int] {
        var bits = [Int]()
        for i in (0..<8) {
            let bit = (value >> i) & 1
            bits.append(Int(bit))
        }
        return bits
    }
    
    func combineBitsIntoUInt8(_ bits: [Int]) -> UInt8? {
        if bits.count != 8 {
            return nil
        }
        
        var value: UInt8 = 0
        for (i, bit) in bits.enumerated() {
            if bit == 1 {
                value |= (1 << i)
            } else if bit != 0 {
                return nil
            }
        }
        return value
    }
    
    // This function converts a float to an int16, keeping a specified number of decimal places.
    // Eg. floatToInt16(25.23123, decimalPlaces: 2) returns 2523
    func floatToInt16(_ value: Float, decimalPlaces: Int) -> Int16 {
        let multiplier = pow(10.0, Float(decimalPlaces))
        return Int16(value * multiplier)
    }
    
    // This function converts an int16 back to a float, based on a specified number of decimal places.
    // Eg. int16ToFloat(2523, decimalPlaces: 2) returns 25.23
    func int16ToFloat(_ value: Int16, decimalPlaces: Int) -> Float {
        let divisor = pow(10.0, Float(decimalPlaces))
        return Float(value) / divisor
    }
    
}

fileprivate protocol ExceptionRawIntValueConvertable: CaseIterable {
    associatedtype TestValueType: FixedWidthInteger
    var rawValue: Int { get }
    var hitTestBits: TestValueType { get }
}

extension DinStorageBatteryPayloadParser {
    
    enum Phase {
        case single
        case three
    }
    
    enum Endian {
        case big
        case little
        
        fileprivate func fix<T: FixedWidthInteger>(_ value: T) -> T {
            switch self {
            case .big:
                return value.bigEndian
            case .little:
                return value.littleEndian
            }
        }
    }
    
    struct CorruptedData: Swift.Error {}
}

fileprivate enum InverterException: Int, CaseIterable, ExceptionRawIntValueConvertable {
    
    typealias TestValueType = UInt16
    case outOverVoltage = 1                 // Bit0：逆变输出过压（锁死）
    case inOverVoltage                   // BIT1：逆变输出欠压（锁死）
    case unknown                           // BIT2：预留
    case DCPartOverCurrent              // BIT3：逆变电流直流分量高（锁死）
    case overCurrent                     // BIT4：逆变电流过流（锁死）
    case hardwareOverCurrent              // BIT5：逆变电流硬件过流（锁死）
    case outShortCircuit                  // BIT6：逆变输出短路（锁死）
    case overload105                      // BIT7：负载过载-105%（锁死）
    case overload120                      // BIT8：负载过载-120%（锁死）
    case overload200                      // BIT9：负载过载-200%（锁死）
    case coolerOverTemperature            // BIT10：逆变散热器过温（保护之后，关闭输出，恢复之后，正常输出）
    case coolerError                      // BIT11：逆变散热器故障（保护之后，关闭输出，恢复之后，正常输出）
    
    var hitTestBits: UInt16 { 1 << (rawValue - 1) }
}

fileprivate enum InverterBatteryException: Int, CaseIterable, ExceptionRawIntValueConvertable {
    
    typealias TestValueType = UInt16
    case overVoltage = 1                 // Bit0：电池过压（保护之后，关闭输出，恢复之后，正常输出）
    case lackOfVoltage                 // Bit1：电池欠压（保护之后，关闭输出，恢复之后，正常输出）
    case overTemperature              // Bit2：电池过温（保护之后，关闭输出，恢复之后，正常输出）
    case overCurrent                   // Bit3：电池过流（锁死）
    case hardwareOverCurrent          // Bit4: 电池硬件过流（锁死）
    case boostCooler1OverTemperature   // Bit5: 升压散热器1过温（保护之后，关闭输出，恢复之后，正常输出）
    case boostCooler2OverTemperature   // Bit6：升压散热器2过温（保护之后，关闭输出，恢复之后，正常输出）
    case boostCooler3OverTemperature   // Bit7：升压散热器3过温（保护之后，关闭输出，恢复之后，正常输出）
    case boostCooler1Error           // Bit8：升压散热器1故障（保护之后，关闭输出，恢复之后，正常输出）
    case boostCooler2Error             // Bit9：升压散热器2故障（保护之后，关闭输出，恢复之后，正常输出）
    case boostCooler3Error             // Bit10：升压散热器3故障（保护之后，关闭输出，恢复之后，正常输出）
    var hitTestBits: UInt16 { 1 << (rawValue - 1) }
}

fileprivate enum InverterGridException: Int, CaseIterable, ExceptionRawIntValueConvertable {
    
    typealias TestValueType = UInt16
    case secOverVoltage = 1              // Bit0：电网瞬时值过压（告警类，故障之后，维持输出）
    case effectL1OverVoltage         // Bit1：电网有效值1级过压（告警类，故障之后，维持输出）
    case effectL2OverVoltage         // Bit2：电网有效值2级过压（告警类，故障之后，维持输出）
    case effectL1LackOfVoltage       // Bit3：电网有效值1级欠压（告警类，故障之后，维持输出）
    case effectL2LackOfVoltage       // Bit4：电网有效值2级欠压（告警类，故障之后，维持输出）
    case secLackOfVoltage            // Bit5：电网瞬时值欠压（告警类，故障之后，维持输出）
    case l1OverFrequency             // Bit6：频率1级过频（告警类，故障之后，维持输出）
    case l2OverFrequency             // Bit7：频率2级过频（告警类，故障之后，维持输出）
    case l1LackOfFrequency           // Bit8：频率1级欠频（告警类，故障之后，维持输出）
    case l2LackOfFrequency           // Bit9：频率2级欠频（告警类，故障之后，维持输出）
    case envelopeError              // Bit10：电网包络异常（告警类，故障之后，维持输出）
    case shutdownError               // Bit11：电网锁相异常（告警类，故障之后，维持输出）
    case cacheRelayError             // Bit12：缓冲继电器粘死检测（锁死）
    case mainRelayError              // Bit13：主继电器粘死检测（锁死）
    var hitTestBits: UInt16 { 1 << (rawValue - 1) }
}

fileprivate enum InverterSystemException: Int, CaseIterable, ExceptionRawIntValueConvertable {
    
    typealias TestValueType = UInt16
    case insulationCheckError = 1              // Bit0：绝缘检测异常（锁死）
    case leakageCheckError              // Bit1：漏电检测异常（锁死）
    case unknown              // Bit2：预留
    case mainLine1OverVoltage              // Bit3：母线1级过压（锁死）
    case mainLine2OverVoltage              // Bit4：母线2级过压（锁死）
    case mainLine1LackOfVoltage              // Bit5：母线1级欠压（锁死）
    case mainLine2LackOfVoltage              // Bit6：母线2级欠压（锁死）
    case mainLineError              // Bit7：母线故障（锁死）
    case powerDown              // Bit8：PowerDown（锁死）
    case overTemperature              // Bit9：变压器过温（保护之后，关闭输出，恢复之后，正常输出）
    case error              // Bit10：变压器故障（保护之后，关闭输出，恢复之后，正常输出）
    case communication              // Bit11：通信故障（保护之后，关闭输出，恢复之后，正常输出）
    case fan              // Bit12：风机故障（告警类，故障之后，维持输出）
    var hitTestBits: UInt16 { 1 << (rawValue - 1) }
}

fileprivate enum InverterMPPTException: Int, CaseIterable, ExceptionRawIntValueConvertable {
    
    typealias TestValueType = UInt16
    case overVoltage = 1              // Bit0：光伏过压（保护之后，关闭输出，恢复之后，正常输出）
    case lackOfVoltage              // Bit1：光伏欠压（保护之后，关闭输出，恢复之后，正常输出）
    case overCurrent              // Bit2：光伏过流（锁死）
    case coolerOverTemperature              // Bit3：光伏散热器1过温（保护之后，关闭输出，恢复之后，正常输出）
    case coolerError              // Bit4：光伏散热器1故障（保护之后，关闭输出，恢复之后，正常输出）
    var hitTestBits: UInt16 { 1 << (rawValue - 1) }
}

fileprivate enum InverterPresentException: Int, CaseIterable, ExceptionRawIntValueConvertable {
    
    typealias TestValueType = UInt16
    case batteryOverVoltage = 1              // Bit0：电池过压
    case batteryLackOfVoltage              // Bit1：电池欠压
    case overTemperature             // Bit2：逆变器过温
    case gridVoltage              // Bit3：电网电压异常
    case gridFrequency              // Bit4：电网频率异常
    case outVoltage              // Bit5：输出电压异常
    case outShortCircuit              // Bit6：输出短路
    case outOverload              // Bit7：输出过载
    case error              // Bit8：逆变器故障
    case mpptOverVoltage              // Bit9：光伏过压
    case mpptError              // Bit10：光伏故障
    var hitTestBits: UInt16 { 1 << (rawValue - 1) }
}

fileprivate enum InverterDCException: Int, CaseIterable, ExceptionRawIntValueConvertable {
    
    typealias TestValueType = UInt16
    case error = 1                   // Bit0：逆变器使能硬件故障（锁死）DC判断到逆变使能没开但是可以通信时认为故障
    case communication             // Bit1：DC同逆变器通信故障。（锁死）
    var hitTestBits: UInt16 { 1 << (rawValue - 1) }
}

fileprivate enum BatteryException: Int, CaseIterable, ExceptionRawIntValueConvertable {
    
    typealias TestValueType = UInt16
    
    case hardwareError = 1
    case dischargeHighTemperatureAlert
    case lowVoltageAlert
    case dischargeOverAmpereAlert
    case fetTemperatureProtection
    case chargeHighTemperatureProtection
    case chargeLowTemperatureProtection
    case dischargeHighTemperatureProtection
    case dischargeLowTemperatureProtection
    case dischargeShortCircuitProtection
    case chargeOverAmpereProtection
    case lowVoltageProtection
    case highVoltageProtection
    case communicationError
    
    var hitTestBits: UInt16 { 1 << (rawValue - 1) }
}

fileprivate enum BatteryHeatingStatus: UInt8 {
    case unavailable = 0x00
    case notHeating = 0x01
    case heating = 0x02
}

fileprivate enum MPPTException: Int, CaseIterable, ExceptionRawIntValueConvertable {
    
    typealias TestValueType = UInt16
    
    case InputVoltageTooHigh = 1
    case PVLowVoltage = 2
    case PVOverVoltage = 3
    case PVOverCurrent = 4
    case UseLess = 5
    case CoolerTempHigh1 = 6
    case CoolerError1 = 7
    case CoolerTempHigh2 = 8
    case CoolerError2 = 9
    case Communication = 10
    
    var hitTestBits: UInt16 { 1 << (rawValue - 1) }
}

fileprivate enum EVException: Int, CaseIterable, ExceptionRawIntValueConvertable {
    
    typealias TestValueType = UInt16
    
    case currentLeakage = 1
    case overVoltage = 2
    case voltageLackage = 3
    case overAmpere = 4
    case overTemperature = 5
    case currentLeakageCheckingError = 6
    case groundWireError = 7
    case cpLevelError = 8
    case relayError = 9
    case assistantCPUError = 10
    case system5VError = 11
    case communication = 12
    
    var hitTestBits: UInt16 { 1 << (rawValue - 1) }
}

fileprivate enum CabinetException: Int, CaseIterable, ExceptionRawIntValueConvertable {
    
    typealias TestValueType = UInt16
    
    case waterSensorException = 1
    case smokeSensorException
    case fanException
    case communicationException
    
    var hitTestBits: UInt16 { 1 << (rawValue - 1) }
}

fileprivate enum SystemException: Int, CaseIterable, ExceptionRawIntValueConvertable {
    typealias TestValueType = UInt16
    case offlineOverLoadProtect = 1            // BIT0:离线过载保护。（超过4000W关闭输出）
    case socTooLow                     // BIT1：pack的soc过低（基础模式低于ALARM+2%关闭输出，其它模式按照SOC OFF的设定值关闭输出）
    case mainLineVoltageTooLow            // BIT2:总线电压过低。（告警不关闭输出）
    case testOverTemperature            // BIT3:系统测试的温度过高（MCU测试采样的温度高于80度关闭输出）
    case testLowTemperature            // BIT4:系统测试的温度过低（MCU测试采样的温度低于-30度关闭输出）
    case dataError            // BIT5:机柜指示数量与实际读取的数量不匹配（容错处理，会告警不关闭输出）
    case batteryEffect            // BIT6:电池的性能恶化告警（检测电池的健康度指标告警处理不关闭）
    case loutConnectError            // BIT7:逆变L-OUT接线错误。（即LOUT未开的情况下接入LIN市电电压，检测到异常之后，关闭逆变使能关闭输出。外部异常清除后，自动输出）
    case sensorConnectError         // BIT8:电表接线错误.（即电表的输入霍尔传感器的接线一致性有问题，3路输入的功率应该是同向的，检测到不同向时告警处理，不关输出）
    case cabinetUnExist             // BIT9：gb_box_unexist_for_hard 9 //硬件指示机柜不存在
    case batteryMaintenance         // BIT10：电池维护状态（当前电池禁止放电）
    
    var hitTestBits: UInt16 { 1 << (rawValue - 1) }
}

fileprivate enum CommunicationException: Int, CaseIterable, ExceptionRawIntValueConvertable {
    typealias TestValueType = UInt16
    
    case iotOrMCUError = 1
    case threePhraseMeterError
    
    var hitTestBits: UInt16 { 1 << (rawValue - 1) }
}

fileprivate enum ChipsProgressError: Int, CaseIterable, ExceptionRawIntValueConvertable {
    typealias TestValueType = UInt16
    
    case BatteryLevelLow = 1
    case Other = 16
    
    var hitTestBits: UInt16 { 1 << (rawValue - 1) }
}

fileprivate enum ThirdPartyPVActiveError: Int, CaseIterable, ExceptionRawIntValueConvertable {
    typealias TestValueType = UInt16
    
    case Other = 1
    case BSensorNotDetect
    case GridUnavailable
    case MCUNotSupport
    
    var hitTestBits: UInt16 { 1 << (rawValue - 1) }
}

extension DinStorageBatteryCharingStrategy {
    fileprivate static func value(from byte: UInt8) -> Self? {
        switch byte {
        case 0x00: return .priceInsensitive
        case 0x01: return .smartCharge
        case 0x02: return .extremlySaving
        default: return nil
        }
    }
}

extension DinStorageBatteryEVState {
    fileprivate static func value(from byte: UInt8) -> Self? {
        switch byte {
        case 0x00: return .evClose
        case 0x01: return .evFree
        case 0x02: return .evOutput
        case 0x03: return .evInput
        default: return nil
        }
    }
}

extension DinStorageBatteryEVLightState {
    fileprivate static func value(from byte: UInt8) -> Self? {
        switch byte {
        case 0x00: return .stop
        case 0x01: return .green
        case 0x02: return .red
        default: return nil
        }
    }
}

extension DinStorageBatteryInverterState {
    fileprivate static func value(from byte: UInt8) -> Self? {
        switch byte {
        case 0x00: return .shutdown
        case 0x01: return .running
        case 0x02: return .downToError
        default: return nil
        }
    }
    
}

extension DinStorageBatteryInverterFanState {
    fileprivate static func value(from byte: UInt8) -> Self? {
        switch byte {
        case 0x00: return .stop
        case 0x01: return .running
        default: return nil
        }
    }
}

fileprivate typealias CabinetSmokeState = DinStorageBatteryCabinetWaterState

extension DinStorageBatteryCabinetWaterState {
    fileprivate static func value(from byte: UInt8) -> Self? {
        switch byte {
        case 0x00: return .valid
        case 0x01: return .exception
        default: return nil
        }
    }
}

extension DinStorageBatteryCabinetFanState {
    fileprivate static func value(from byte: UInt8) -> Self? {
        switch byte {
        case 0x00: return .stopped
        case 0x01: return .running
        case 0x02: return .exception
        default: return nil
        }
    }
    
}

extension DinStorageBatterySOCState {
    fileprivate static func value(from byte: UInt8) -> Self? {
        switch byte {
        case 0x00: return .full
        case 0x01: return .lowSOCAlert
        case 0x02: return .lowSOCWarning
        case 0x03: return .lowSOCProtect
        default: return nil
        }
    }
    
}

extension DinStorageBatteryReserveMode {
    fileprivate static func value(from byte: UInt8) -> Self? {
        switch byte {
        case 0x01: return .scheduled
        case 0x00, 0x02: return .aiAdapter
        default: return nil
        }
    }
}

extension DinStorageBatteryEVDetailState {
    fileprivate static func value(from byte: UInt8) -> Self? {
        switch byte {
        case 0x00: return .close
        case 0x01: return .free
        case 0x02: return .charging
        case 0x03: return .carUnvalid
        case 0x04: return .unvalid
        case 0x05: return .complete
        case 0x06: return .error
        default: return nil
        }
    }
}

extension DinStorageBatteryEVChargingMode {
    fileprivate static func value(from byte: UInt8) -> Self? {
        switch byte {
        case 0x00: return .lowerUtilityRate
        case 0x01: return .solarOnly
        case 0x02: return .scheduled
        case 0x03: return .instantChargeFull
        case 0x04: return .instantChargeFixed
        default: return nil
        }
    }
}

extension DinStorageBatteryEVAdvanceStatus {
    fileprivate static func value(from byte: UInt8) -> Self? {
        switch byte {
        case 0x00: return .off
        case 0x01: return .wait
        case 0x02: return .charging
        case 0x03: return .error
        default: return nil
        }
    }
}

extension DinRegulateFrequencyState {
    fileprivate static func value(from byte: UInt8) -> Self? {
        switch byte {
        case 0x00: return .idle
        case 0x01: return .onHold
        case 0x02: return .fcrN
        case 0x03: return .fcrDUp
        case 0x04: return .fcrDDown
        case 0x05: return .fcrDUpDown
        default: return nil
        }
    }
}

extension DinStorageBatteryPVPreference {
    fileprivate static func value(from byte: UInt8) -> Self? {
        switch byte {
        case 0x00: return .ignore
        case 0x01: return .followEmaldoAI
        case 0x02: return .load
        case 0x03: return .batteryCharge
        default: return nil
        }
    }
}
