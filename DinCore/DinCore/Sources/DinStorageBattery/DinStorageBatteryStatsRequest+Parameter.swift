//
//  DinStorageBatteryStatsRequest+Parameter.swift
//  DinCore
//
//  Created by williamhou on 2023/2/27.
//

import Foundation

extension DinStorageBatteryStatsRequest {
  
    struct GetStatsParameters {
        let homeID: String
        let deviceID: String
        let model: String
        // 时间偏移量单位，取值为 day/week/month/year/lifetime
        let interval: String
        // 天/周/月/12年 的偏移量（0 表示当天的数据，-n 表示前 n 天/周/月/12年 的数据）
        let offset: Int
    }
    
    // 若是 getStatsGrid 用这个
    struct GetStatsGridParameters {
        let homeID: String
        let deviceID: String
        let model: String
        // 时间偏移量单位，取值为 day/week/month/year/lifetime
        let interval: String
        // 天/周/月/12年 的偏移量（0 表示当天的数据，-n 表示前 n 天/周/月/12年 的数据）
        let offset: Int
        // 是否获取真实数据
        let get_real: Bool
        // day数据间隙，不传则默认1分钟
        let query_interval: Int
    }
    
    struct GetBSensorStatusParameters {
        let homeID: String
        let deviceID: String
        let model: String
    }
    
    struct GetChargingDischargingPlansParameters {
        let homeID: String
        let deviceID: String
        let model: String
        let offset: Int
    }
    
}
