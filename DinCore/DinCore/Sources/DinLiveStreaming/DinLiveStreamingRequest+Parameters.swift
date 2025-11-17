//
//  DinLiveStreamingRequest+Parameters.swift
//  DinCore
//
//  Created by Monsoir on 2022/3/8.
//

import Foundation

extension DinLiveStreamingRequest {

    struct GetServiceSettingParameters {
        let homeID: String
        let provider: String
        let deviceID: String
    }

    struct UpdateServiceSettingParameters {
        let homeID: String
        let provider: String
        let deviceID: String
        let alertMode: String
        let isCloudStorageEnabled: Bool
        let arm: Bool
        let disarm: Bool
        let homeArm: Bool
        let sos: Bool
    }
}
