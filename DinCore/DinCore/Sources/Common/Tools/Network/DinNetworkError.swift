//
//  DinNetworkError.swift
//  DinCore
//
//  Created by Jin on 2021/4/21.
//

import Foundation

public protocol DinNetworkErrorProtocol: Error {
    /// for present error description
    var errorDescription: String? { get }

    /// The domain of the error.
    static var errorDomain: String { get }

    /// The error code within the given domain.
    var errorCode: Int { get }

    /// The user-info dictionary.
    var errorUserInfo: [String : Any] { get }
}

public struct DinNetwork {
    public enum Error {
        case unknown
        case lackParams(String)
        case apiFail(String, Int)
        case noDataReturn(String)
        case dictionaryConvertFail(String)
        case dataStatusNotFound(String)
        case statusFail(String, Int, String)
        case modelConvertFail(String)
    }
}

extension DinNetwork.Error: DinNetworkErrorProtocol {
    static func descriptionString(with desc: String) -> String {
        "\(errorDomain): \(desc)"
    }

    public var errorDescription: String? {
        switch self {
        case .lackParams(let api):
            return "\(DinNetwork.Error.descriptionString(with: "\(api) -> invoke api without parameters"))"
        case .apiFail(let api, _):
            return "\(DinNetwork.Error.descriptionString(with: "\(api) -> api fail to response"))"
        case .noDataReturn(let api):
            return "\(DinNetwork.Error.descriptionString(with: "\(api) -> api return none data"))"
        case .dictionaryConvertFail(let api):
            return "\(DinNetwork.Error.descriptionString(with: "\(api) -> api result convert failure"))"
        case .dataStatusNotFound(let api):
            return "\(DinNetwork.Error.descriptionString(with: "\(api) -> api status not provide"))"
        case .statusFail(let api, let status, _):
            return "\(DinNetwork.Error.descriptionString(with: "\(api) -> api return failure with status: \(status)"))"
        case .modelConvertFail(let modelName):
            return "\(DinNetwork.Error.descriptionString(with: "\(modelName) -> convert failure"))"
        default:
            return "\(DinNetwork.Error.descriptionString(with: "unknown failure"))"
        }
    }

    public var serverErrorMsg: String? {
        switch self {
        case .statusFail(_, _, let result):
            return result
        default:
            return nil
        }
    }

    public static var errorDomain: String {
        "DinNetwork.Error"
    }

    public var errorCode: Int {
        switch self {
        case .lackParams:
            return -991
        case .apiFail(_, let state):
            return state
        case .noDataReturn:
            return -993
        case .dictionaryConvertFail:
            return -994
        case .dataStatusNotFound:
            return -995
        case .statusFail(_, let status, _):
            return status
        case .modelConvertFail:
            return -996
        default:
            return -990
        }
    }

    public var errorUserInfo: [String : Any] {
        return [:]
    }
}
