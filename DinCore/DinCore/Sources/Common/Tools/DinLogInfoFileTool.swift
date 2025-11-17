//
//  DinLogInfoFileTool.swift
//  NExT
//
//  Created by Jin on 2020/3/13.
//  Copyright © 2020 Dinsafer. All rights reserved.
//

import UIKit
import DinSupport

private let logDir = "logs"
private let logParentDirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
private let fileNameDateFormatter: DateFormatter = {
    let result = DateFormatter()
    result.dateFormat = "yyyy-MM-dd"
    result.locale = Locale(identifier: "en_US")
    return result
}()

private func getLogDirectoryURL() -> URL? {
    let result = logParentDirURL?.appendingPathComponent(logDir, isDirectory: true)
    return result
}

private func getTodayLogFileURL() -> URL? {
    let logFileName = "dslog_\(fileNameDateFormatter.string(from: Date()))"
    let result = getLogDirectoryURL()?
        .appendingPathComponent(logFileName)
        .appendingPathExtension("plist")
    return result
}

private func removeLogDirectory() {
    guard let url = logParentDirURL?.appendingPathComponent(logDir, isDirectory: true) else { return }
    if FileManager.default.fileExists(atPath: url.path) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            return
        }
    }
}

private func ensureTodayLogFile(_ completion: () -> Void) {
    guard let todayLogFileURL = getTodayLogFileURL() else { return }

    if !FileManager.default.fileExists(atPath: todayLogFileURL.path) {
        // 今天的日志文件不存在，说明现在「可能」存在的日志是旧的，删！
        removeLogDirectory()

        guard let logDirectoryURL = getLogDirectoryURL() else { return }
        do {
            try FileManager.default.createDirectory(
                at: logDirectoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
            FileManager.default.createFile(atPath: todayLogFileURL.path, contents: nil, attributes: nil)
        } catch {
            return
        }
        completion()
    } else {
        completion()
    }
}

public class DinLogInfoFileTool: NSObject {
    private static var plistLogger = PlistLogger(capacity: 200, fileURL: getTodayLogFileURL()!)

    public class func logToFile(withErrorMsg errMsg: String, requestPath: String?, requestParams: [String: Any]?) {
        ensureTodayLogFile {
            var infoDict = [String: Any]()
            infoDict["errorMessage"] = errMsg
            if let path = requestPath {
                infoDict["requestPath"] = path
            }
            if let params = requestParams, let paramString = DinDataConvertor.convertToString(params) {
                infoDict["requestParams"] = paramString
            }

            if let infoString = DinDataConvertor.convertToString(infoDict) {
                plistLogger.log(infoString)
            }
        }
    }

    class func uploadFile() {
        guard let todayLogFile = getTodayLogFileURL() else { return }

        if FileManager.default.fileExists(atPath: todayLogFile.path) {

            plistLogger.readLogsAsJSON { result in
                guard let content = result else { return }
                let request = DinRequest.uploadNetworkStateLog(errMessage: content)
//                deviceProvider.request(target) { (result) in
//                    if let response = API.check(result: result, path: target.path, parameters: target.parameters) {
//                        if response.status.isOK {
//                            // 如果上传成功，则删除本地log文件
//                            removeLogDirectory()
//                            plistLogger.clear()
//                        }
//                    }
//                }
                DinHttpProvider.request(request, withoutResultChecked: true) { result in
                    removeLogDirectory()
                    plistLogger.clear()
                } fail: { _ in
                }
            }
        }
    }
}
