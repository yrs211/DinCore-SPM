//
//  DinFixRequest+Parameter.swift
//  DinCore
//
//  Created by williamhou on 2024/4/26.
//

import Foundation

extension DinFixRequest {
  
    struct GenHomeQrcodeParameters {
        let homeID: String
    }
    
    struct OperatorTransferParameters {
        let bmtId: String
        let model: String
        let qrCode: String
        let ticketId: String
    }
}
