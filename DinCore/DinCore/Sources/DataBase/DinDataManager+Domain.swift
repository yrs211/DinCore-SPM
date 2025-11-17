//
//  DinDataManager+Domain.swift
//  DinCore
//
//  Created by Jin on 2021/4/22.
//

import Foundation

public extension DinDataManager {
    /// 存储用户信息
    static let domainKey = "dincore_domain"
    /// 存储统计域名
    static let statisticsDomainKey = "dincore_statistics_domain"
    
    func setDomain(_ domain: String?) {
        guard let saveDomain = domain else {
            removeValueAsync(withKey: DinDataManager.domainKey)
            return
        }
        saveValueAsync(withKey: DinDataManager.domainKey, value: saveDomain)
    }

    func getDomain() -> String? {
        hasValue(withKey: DinDataManager.domainKey) as? String
    }

    func setStatisticsDomain(_ domain: String?) {
        guard let saveStatisticsDomain = domain else {
            removeValueAsync(withKey: DinDataManager.statisticsDomainKey)
            return
        }
        saveValueAsync(withKey: DinDataManager.statisticsDomainKey, value: saveStatisticsDomain)
    }

    func getStatisticsDomain() -> String? {
        hasValue(withKey: DinDataManager.statisticsDomainKey) as? String
    }
}
