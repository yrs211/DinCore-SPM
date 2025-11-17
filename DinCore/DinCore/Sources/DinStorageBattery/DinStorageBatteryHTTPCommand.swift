//
//  DinStorageBatteryHTTPCommand.swift
//  DinCore
//
//  Created by monsoir on 12/7/22.
//

import Foundation

enum DinStorageBatteryHTTPCommand: String, HTTPCommand {
    case getRegionList = "get_region_list"
    case updateRegion = "update_region"
    case getRegion = "get_region"
    case rename = "set_name"
    case getStatsLoadusage = "get_stats_loadusage"
    case getStatsLoadusageV2 = "get_stats_loadusage_v2"
    case getStatsBattery = "get_stats_battery"
    case getStatsBatteryV2 = "get_stats_battery_v2"
    case getStatsBatteryPowerlevel = "get_stats_battery_powerlevel"
    case getStatsGrid = "get_stats_grid"
    case getStatsMppt = "get_stats_mppt"
    case getStatsMpptV2 = "get_stats_mppt_v2"
    case getStatsRevenue = "get_stats_revenue"
    case getStatsRevenueV2 = "get_stats_revenue_v2"
    case getStatsEco = "get_stats_eco"
    case getStatsEcoV2 = "get_stats_eco_v2"
    case getElecPriceInfo = "get_elec_price_info"
    case getBSensorStatus = "get_bsensor_status"
    case bindInverter = "bind_inverter"
    case getFusePowerCaps = "get_fuse_power_caps"
    case getDualPowerOpen = "get_dualpower_open"
    case getFeature = "get_feature"
    case getChargingDischargingPlans = "get_charging_discharging_plans"
    case getChargingDischargingPlansV2 = "get_charging_discharging_plans_v2"
    case getChargingDischargingPlansV2Minute = "get_charging_discharging_plans_v2_minute"
    case getAIModeSettings = "get_aimode_settings"
    case getLocallySwitch = "get_locally_switch"
    case setLocallySwitch = "set_locally_switch"
    case getBmtLocation = "get_bmt_location"
    case setBmtInitPeakShaving = "set_bmt_init_peak_shaving"
}
