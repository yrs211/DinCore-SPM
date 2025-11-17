//
//  DinChannelKcpObjectFileFetcher.swift
//  DinCore
//
//  Created by Jin on 2021/11/30.
//

import UIKit
import DinSupport

enum DinChannelKcpObjectFileFetchStatus: Int {
    case success = 1
    case interrupt = 0
    case paramsError = -1
    case saveFileFailure = -2
    case dataFormatFailure = -3
    case kcpReset = -4
    case timeout = -5
}

protocol DinChannelKcpObjectFileFetcherDelegate: NSObjectProtocol {
    /// 接收到下载通道数据
    func fetcher(_ fetcher: DinChannelKcpObjectFileFetcher, receivedFileAt filePath: String, fileName: String, fileType: String, status: DinChannelKcpObjectFileFetchStatus)
    /// 通知kcp通道reset
    func fetcher(sendReset fetcher: DinChannelKcpObjectFileFetcher)
    /// 操作已登记，可以开始传输数据
    func fetcher(_ fetcher: DinChannelKcpObjectFileFetcher, requestSend data: Data)
}

class DinChannelKcpObjectFileFetcher: NSObject {
    weak var delegate: DinChannelKcpObjectFileFetcherDelegate?

    /// 是否开始传输数据了
    var fetching = false
    /// 当前正在下载包的总大小
    var curDownloadSize: Int = 0
    /// 当前缓存的data
    var curDownloadData: Data = Data()
    /// 当前下载的文件名
    var curDownloadFileName: String = ""
    /// 下载只能串行
    static let kcpDownloadQueue = DispatchQueue.init(label: DinQueueName.cameraDowload)

    /// 每个文件允许的下载时间是60s
    var fetchTimer: DinGCDTimer?

    /// 待下载的文件名队列
    var waitingFileNames: [String] = []

    /// 每个文件的第一个包都是json，需要转换成json获取接下来的数据总量
    /// 当后来收到的包加起来等于上面json中表明的总量，则文件传输完毕，这时候把downloadReset变成true，用于下一个数据需要转成新的json逻辑
    var waitForFileInfo: Bool {
        curDownloadSize == 0 && curDownloadData.count == 0
    }
    /// 文件接收完毕
    var fileReceived: Bool {
        curDownloadSize > 0 && curDownloadData.count == curDownloadSize
    }

    /// 保存的目录唯一名字
    let fileSaveID: String

    deinit {
        stopFetch()
    }
    /// 初始化实例
    /// - Parameters:
    ///   - fileSaveID: 文件保存的唯一路径文件夹名
    ///   - delegate: 代理
    init(withSaveID fileSaveID: String = "", delegate: DinChannelKcpObjectFileFetcherDelegate) {
        if fileSaveID.count > 0 {
            self.fileSaveID = fileSaveID
        } else {
            self.fileSaveID = "common"
        }
        self.delegate = delegate
        super.init()
    }

    // MARK: - download method
    func handleFileFetch(data: Data) {
        // json的data在结束后面有4位的"\r\n\r\n"，需要去除
        DinChannelKcpObjectFileFetcher.kcpDownloadQueue.async { [weak self] in
            guard let self = self else { return }
            if self.waitForFileInfo {
                // 第一个包是json
                if data.count > 4 {
                    let jsonData = data[0...(data.count-4)]
                    if let jsonDict = DinDataConvertor.convertToDictionary(jsonData),
                        self.curDownloadFileName == jsonDict["filename"] as? String ?? "" {
                        self.curDownloadSize = jsonDict["filesize"] as? Int ?? 0
                        if self.curDownloadSize > 0 {
                            self.curDownloadData.removeAll()
                            return
                        }
                    }
                }
                self.resetDownLoad(withFetchStatus: .saveFileFailure, filePath: "")
            } else {
                self.curDownloadData.append(data)
            }

            // 最后检查数据是否接收完毕
            if self.fileReceived {
                let savePath = self.saveToCache(fullFileName: self.curDownloadFileName, data: data)
                if savePath.count > 0 {
                    self.resetDownLoad(withFetchStatus: .success, filePath: savePath)
                } else {
                    self.resetDownLoad(withFetchStatus: .saveFileFailure, filePath: "")
                }
            }
        }
    }

    func stopFetch(withFetchStatus status: DinChannelKcpObjectFileFetchStatus = .interrupt, cleanWaitingFiles: Bool = true) {
        // 清除所有等待下载的文件
        stopFetchTimeCount()
        if cleanWaitingFiles {
            self.waitingFileNames.removeAll()
        }
        self.resetDownLoad(withFetchStatus: status, filePath: "", withoutCheck: cleanWaitingFiles)
    }

    func beginFetch(_ fileName: String, fileType type: String) {
        // 检查参数
        let curDownloadFileName = self.checkFileName(fileName, fileType: type)
        guard curDownloadFileName.count > 0 else {
            delegate?.fetcher(self, receivedFileAt: "", fileName: "", fileType:"", status: .paramsError)
            return
        }

        DinChannelKcpObjectFileFetcher.kcpDownloadQueue.async { [weak self] in
            guard let self = self else { return }
            // 如果是在下载同时是第一个的时候，也就是匹配中正在下载的时候，不进行刷新
            if self.fetching && curDownloadFileName == self.waitingFileNames.first {
                return
            }
            // 筛选本来就有的, 删除
            for (index, waitFileName) in self.waitingFileNames.enumerated() {
                if waitFileName == curDownloadFileName {
                    self.waitingFileNames.remove(at: index)
                    break
                }
            }

            if !self.fetching {
                if self.waitingFileNames.count < 1 {
                    // 当前没有下载任务，可直接下载
                    self.waitingFileNames.append(curDownloadFileName)
                    self.checkWaitFiles()
                } else {
                    // 插队
                    self.waitingFileNames.insert(curDownloadFileName, at: 0)
                }
            } else if self.waitingFileNames.count > 0 {
                // 保证队列有1个数据，防止insert有问题
                // 当前有下载任务，优先插入栈
                self.waitingFileNames.insert(curDownloadFileName, at: 1)
            }
        }
    }
    /// 注意：请在DinChannelKcpObjectFileFetcher.kcpDownloadQueue里面使用
    func resetDownLoad(withFetchStatus status: DinChannelKcpObjectFileFetchStatus, filePath: String, withoutCheck: Bool = false) {
        // 关闭计时
        stopFetchTimeCount()

        let fileNameArr = curDownloadFileName.components(separatedBy: ".")
        if fileNameArr.count == 2, getFileType(withFileExtension: fileNameArr.last ?? "").count > 0 {
            self.delegate?.fetcher(self,
                                   receivedFileAt: filePath,
                                   fileName: fileNameArr.first ?? "",
                                   fileType: getFileType(withFileExtension: fileNameArr.last ?? ""),
                                   status: status)
        } else {
            self.delegate?.fetcher(self, receivedFileAt: filePath, fileName: fileNameArr.first ?? "", fileType:"", status: .dataFormatFailure)
        }
        // 如果是本地超时了，通知ipc reset，方便之后重新建立kcp通讯
        // 因为是本地判断超时，所以有可能ipc还在传输过来，所以要告诉ipc reset
        if status == .timeout {
            self.delegate?.fetcher(sendReset: self)
        }
        // 完成下载之后，队列移除文件名
        // 防止有问题，加个控制
        if waitingFileNames.count > 0 {
            waitingFileNames.removeFirst()
        }
        curDownloadSize = 0
        curDownloadData.removeAll()
        curDownloadFileName = ""
        fetching = false
        if !withoutCheck {
            checkWaitFiles()
        }
    }
    func checkWaitFiles() {
        DinChannelKcpObjectFileFetcher.kcpDownloadQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.fetching && self.waitingFileNames.count > 0 {
                self.fetching = true
                let fileName = self.waitingFileNames.first ?? ""
                if fileName.count > 0 {
                    self.curDownloadFileName = fileName
                    let cachePath = self.hasCache(fullFileName: fileName)
                    if cachePath.count > 0 {
                        self.resetDownLoad(withFetchStatus: .success, filePath: cachePath)
                    } else {
                        let dataDict: [String: Any] = ["filename": fileName]
                        self.delegate?.fetcher(self, requestSend: DinDataConvertor.convertToData(dataDict) ?? Data())
                        self.startFetchTimeCount()
                    }
                } else {
                    self.resetDownLoad(withFetchStatus: .dataFormatFailure, filePath: "")
                }
            }
        }
    }
}

// MARK: - timeout counter
extension DinChannelKcpObjectFileFetcher {
    private func startFetchTimeCount() {
        stopFetchTimeCount()
        // 代理大概是50m 40s的速度，局域网在公司大概是要130多s，所以先跟安卓一样120s超时
        fetchTimer = DinGCDTimer(timerInterval: .seconds(120), isRepeat: false, executeBlock: { [weak self] in
            self?.stopFetch(withFetchStatus: .timeout, cleanWaitingFiles: false)
        }, queue: DinChannelKcpObjectFileFetcher.kcpDownloadQueue)
    }
    private func stopFetchTimeCount() {
        fetchTimer = nil
    }
}

// MARK: - for cache
extension DinChannelKcpObjectFileFetcher {
    /// 检查文件名和文件类型是否符合规则
    /// 目前只支持类型为 "photo"和"video"的文件传输
    /// - Parameters:
    ///   - fileName: 文件名
    ///   - type: 文件类型
    /// - Returns: 下载文件名。若为空字符串，则验证失败
    private func checkFileName(_ fileName: String, fileType type: String) -> String {
        guard fileName.count > 0 else { return "" }
        let fileExtension = getFileExtension(withType: type)
        guard fileExtension.count > 0 else { return "" }
        return "\(fileName).\(fileExtension)"
    }
    private func getFileExtension(withType type: String) -> String {
        switch type {
        case "photo":
            return "jpg"
        case "video":
            return "mp4"
        default:
            return ""
        }
    }
    private func getFileType(withFileExtension fileExtension: String) -> String {
        switch fileExtension {
        case "jpg":
            return "photo"
        case "mp4":
            return "video"
        default:
            return ""
        }
    }

    private func getSaveDomainUrl() -> URL? {
        // 保存 data
        guard let libraryCachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last else {
            return nil
        }
        return URL(fileURLWithPath: libraryCachePath, isDirectory: true).appendingPathComponent("com.dinsafer.dincore.streamingdevice", isDirectory: true).appendingPathComponent(self.fileSaveID)
    }

    private func saveToCache(fullFileName: String, data: Data) -> String {
        // 保存 data
        guard let libraryCacheUrl = getSaveDomainUrl() else {
            return ""
        }
        var savePath = ""
        let savePathUrl = libraryCacheUrl.appendingPathComponent(fullFileName, isDirectory: false)
        let saveDomainUrl = savePathUrl.deletingLastPathComponent()
        do {
            if !FileManager.default.fileExists(atPath: saveDomainUrl.path) {
                try FileManager.default.createDirectory(at: saveDomainUrl, withIntermediateDirectories: true, attributes: nil)
            }
            try self.curDownloadData.write(to: savePathUrl)
            savePath = savePathUrl.absoluteString
        } catch {}

        return savePath
    }

    func removeCache(fullFileName: String) {
        // 保存 data
        guard let libraryCacheUrl = getSaveDomainUrl() else {
            return
        }
        let savePathUrl = libraryCacheUrl.appendingPathComponent(fullFileName, isDirectory: false)
        let saveDomainUrl = savePathUrl.deletingLastPathComponent()
        do {
            if FileManager.default.fileExists(atPath: saveDomainUrl.path) {
                try FileManager.default.removeItem(atPath: saveDomainUrl.path)
            }
        } catch {
        }
        return
    }

    private func hasCache(fullFileName: String) -> String {
        // 保存 data
        guard let libraryCachePath = getSaveDomainUrl() else {
            return ""
        }
        var savePath = ""
        let savePathUrl = libraryCachePath.appendingPathComponent(fullFileName, isDirectory: false)
        if FileManager.default.fileExists(atPath: savePathUrl.path) {
            savePath = savePathUrl.absoluteString
        }
        return savePath
    }
}
