//
//  DinNovaWidgetRequest+Parameters.swift
//  DinCore
//
//  Created by monsoir on 6/17/21.
//

import Foundation

extension DinNovaWidgetRequest {
    enum Parameter {}
}

extension DinNovaWidgetRequest.Parameter {
    struct GetAntiInterferenceStatus {
        let deviceID: String
        let addOnType: String
    }

    struct ModifyConfCover {
        let deviceID: String
        let addOnType: String
        let enable: Bool
        let message: String

        var confString: String? {
            let dict = ["enable": enable, "message": message] as [String : Any]
            if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []) {
                return String(data: jsonData, encoding: .utf8)
            }
            return nil
        }
    }

    struct ListTimerConf {
        let deviceID: String
    }

    struct ModifyConf {
        let deviceID: String
        let addOnType: String
        let addOnID: String?
        let type: String?
        let conf: String
    }

    struct DeleteConf {
        let deviceID: String
        let addOnType: String
        let addOnID: String
    }

    struct ListAddOnConf {
        let deviceID: String
        let addOnType: String
    }
}
