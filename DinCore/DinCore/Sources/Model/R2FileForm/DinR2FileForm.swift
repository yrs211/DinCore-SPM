//
//  DinFileInfo.swift
//  DinCore
//
//  Created by Mia on 2025/7/16.
//

public enum DinR2UploadType: Int {
    case sign = 4
    case avatar = 5
}

public struct DinR2FileForm {
    let contentLength: Int
    let contentType: String
    let fileExtension: String
    let uploadtype: DinR2UploadType
    let homeID: String
    let fileName: String
    var type: Int {
        return uploadtype.rawValue
    }
}


