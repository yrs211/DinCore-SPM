//
//  DinStorageBatteryMSCTCommand.swift
//  DinCore
//
//  Created by monsoir on 12/5/22.
//

import Foundation

enum DinStorageBatteryMSCTCommand: String, MSCTCommand {

    // connect
    case connect = "connect"
    case disconnect = "disconnect"
    case connectStatusChangedNotify = "connect_status_changed"

    // inverter
    case getInverterInputInfo = "get_inverter_input_info"
    case getInverterOutputInfo = "get_inverter_output_info"
    case getInverterInfoByIndex = "get_inverter_info"
    case inverterExceptionsNotify = "inverter_exception"
    case resetInverter = "reset_inverter"

    // battery
    case getBatteryAccessoryStateByIndex = "get_battery_accessorystate"
    case getBatteryInfoByIndex = "get_battery_info"
    case batteryExceptionsNotify = "battery_exception"
    case batchGetBatteryInfo = "get_battery_allinfo"
    case batchTurnOffBattery = "set_battery_alloff"
    case batteryAccessoryStateChangedNotify = "battery_accessorystate_changed"
    case batteryAccessoryStateChangedCustomNotify = "battery_accessorystate_changed_custom"
    case batteryIndexChangedNotify = "battery_index_changed"
    case batteryStatusInfoNotify = "battery_statusinfo_notify"

    // EV
    case getEVState = "get_ev_state"
    case evExceptionsNotify = "ev_exception"

    // MPPT
    case getMPPTState = "get_mppt_state"
    case mpptExceptionsNotify = "mppt_exception"

    // MCU
    case getMCUInfo = "get_mcu_info"

    // Cabinet
    case getCabinetInfo = "get_cabinet_allinfo"
    case getCabinetStateByIndex = "get_cabinet_state"
    case cabinetStateChangedNotify = "cabinet_state_changed"
    case cabinetIndexChangedNotify = "cabinet_index_changed"
    case cabinetExceptionChangedNotify = "cabinet_exception"

    // Global
    case getGlobalLoadState = "get_global_loadstate"
    case getGlobalExceptions = "get_global_exceptions"
    case systemExceptionsNotify = "system_exception"
    case communicationExceptionsNotify = "communication_exception"
    case getGlobalCurrentFlowInfo = "get_global_currentflow_info"
    case getGlobalDisplayExceptions = "get_view_exceptions"

    // Strategy
    case getEmergencyChargingSettings = "get_emergency_charge"
    case setEmergencyCharging = "set_emergency_charge"
    case getGridChargeMargin = "get_grid_charge_margin"
    case setChargingStrategies = "set_charge_strategies"
    case getChargingStrategies = "get_charge_strategies"
    case setVirtualPowerPlant = "set_virtualpowerplant"
    case getVirtualPowerPlant = "get_virtualpowerplant"
    case getSignals = "get_communicate_signal"
    case setSellingProtection = "set_sellingprotection"
    case getSellingProtection = "get_sellingprotection"

    // setting
    case reset = "reset"
    case reboot = "reset_devicedata"
    case getAdvanceInfo = "get_advance_info"
    case setGlobalLoaderOpen = "set_global_loader_open"
    case getMode = "get_mode"
    case getModeV2 = "get_mode_v2"

    // upgrade
    case getChipsStatus = "get_chips_status"
    case getChipsUpdateProgress = "get_chips_update_progress"
    case updateChips = "update_chips"

    // Charge, Discharge
    case getCurrentReserveMode = "get_current_reservemode"
    case getPriceTrackReserveMode = "get_pricetrack_reservemode"
    case getScheduleReserveMode = "get_schedule_reservemode"
    case getCustomScheduleMode = "get_custom_schedulemode"
    case setReserveMode = "set_reservemode"
    case getCurrentEVChargingMode = "get_current_evchargingmode"
    case getEVChargingModeSchedule = "get_evchargingmode_schedule"
    case setEVChargingMode = "set_evchargingmode"
    case setEVChargingModeInstant = "set_evchargingmode_instant"
    case setEvchargingModeInstantcharge = "set_evchargingmode_instantcharge"
    case getSmartEvStatus = "get_smart_ev_status"
    case setSmartEvStatus = "set_smart_ev_status"
    case getCurrentEVAdvanceStatus = "get_current_evadvancestatus"
    case evAdvanceStatusChangedNotify = "ev_advancestatus_changed"
    case getEVChargingInfo = "get_evcharging_info"
    case getCustomScheduleModeAI = "get_custom_schedulemode_ai"
    case setReserveModeAI = "set_reservemode_ai"

    case setRegion = "set_region"

    case setExceptionIgnore = "set_exception_ignore"
    case getGridConnectionConfig = "get_gridconnection_config"
    case updateGridConnectionConfig = "update_gridconnection_config"
    case resumeGridConnectionConfig = "resume_gridconnection_config"
    
    case getFirmwares = "get_firmwares"
    
    // Fuse Specs
    case setFuseSpecs = "set_fuse_specs"
    case getFuseSpecs = "get_fuse_specs"
    
    // Third Party PV
    case getThirdPartyPVInfo = "get_thirdpartypv_info"
    case setThirdPartyPVOn = "set_thirdpartypv_on"
    
    case getRegulateFrequencyState = "get_regulatefrequency_state"
    
    case getPVDist = "get_pv_dist"
    case setPVDist = "set_pv_dist"
    case getAllSupportFeatures = "get_all_support_features"
    
    // Brightness&Sound
    case getBrightnessSettings = "get_screen_settings"
    case setBrightnessSettings = "set_screen_settings"
    case getSoundSettings = "get_sound_settings"
    case setSoundSettings = "set_sound_settings"
    // Peak Shaving
    case togglPeakShaving = "toggle_peak_shaving"
    case setPeakShavingPoints = "set_peak_shaving_points"
    case setPeakShavingRedundancy = "set_peak_shaving_redundancy"
    case getPeakShavingConfig = "get_peak_shaving_config"
    case getPeakShavingSchedule = "get_peak_shaving_schedule"
    case addPeakShavingSchedule = "add_peak_shaving_schedule"
    case delPeakShavingSchedule = "del_peak_shaving_schedule"
}
