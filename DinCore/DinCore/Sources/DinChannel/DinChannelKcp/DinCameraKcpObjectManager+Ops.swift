//
//  DinChannelKcpObjectManager+Ops.swift
//  DinCore
//
//  Created by Jin on 2021/8/24.
//

import Foundation
import DinSupport

// MARK: - CMD的发消息通道
extension DinChannelKcpObjectManager {
    func sendCMD(data: Data) {
        DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
            guard let self = self else { return }
            if self.isPreparingKcp {
                return
            }
            if let cmdComm = self.cmdComm {
                cmdComm.kcpObject.send(data)
            } else {
                self.isPreparingKcp = true
                self.createCMDKcp()
                if self.type == .proxy {
                    self.delegate?.manager(self, requestEstabKcp: self.cmdComm?.sessionID ?? 0,
                                           channelID: self.cmdComm?.channelID ?? 0,
                                           complete: { [weak self] success in
                        if success {
                            self?.activeCMDKcp(complete: { [weak self] in
                                self?.cmdComm?.kcpObject.send(data)
                            })
                        } else {
                            self?.deactiveCMDKcp()
                        }
                    })
                } else {
                    // 如果是局域网、p2p不用建立kcp
                    self.activeCMDKcp(complete: { [weak self] in
                        self?.cmdComm?.kcpObject.send(data)
                    }, sync: true)
                }
            }
        }
    }
    func activeCMDKcp(complete: (()->())?, sync: Bool = false) {
        if sync {
            isPreparingKcp = false
            cmdComm?.kcpObject.startReceiving()
//            startLiveClock()
            complete?()
        } else {
            DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
                self?.isPreparingKcp = false
                self?.cmdComm?.kcpObject.startReceiving()
//                self?.startLiveClock()
                complete?()
            }
        }
    }
    func deactiveCMDKcp() {
        DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
            guard let self = self else { return }
//            self.stopLiveClock()
            if let comm = self.cmdComm {
                self.delegate?.manager(self, requestResignKcp: comm.sessionID)
                comm.kcpObject.stopReceiving()
                self.commObjects.removeValue(forKey: comm.convString)
                self.cmdComm = nil
            }
            self.isPreparingKcp = false
        }
    }
}

// MARK: - 视频通道
extension DinChannelKcpObjectManager {
    func requestLive(qualityHD: Bool, liveData: Data) {
        DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
            guard let self = self else { return }
            if qualityHD {
                self.createHDVideoKcp()
                if self.type == .proxy {
                    self.delegate?.manager(self, requestEstabKcp: self.hdComm?.sessionID ?? 0, channelID: self.hdComm?.channelID ?? 0, complete: { [weak self] success in
                        if success {
                            self?.activeHDLive(withData: liveData)
                        } else {
                            self?.deactiveHDLive()
                        }
                    })
                } else {
                    // 如果是局域网、p2p不用建立kcp
                    self.activeHDLive(withData: liveData, sync: true)
                }
                // 如果在播放标请，关闭
                self.deactiveSTDLive(sync: true)
            } else {
                self.createSTDVideoKcp()
                if self.type == .proxy {
                    self.delegate?.manager(self, requestEstabKcp: self.stdComm?.sessionID ?? 0, channelID: self.stdComm?.channelID ?? 0, complete: { [weak self] success in
                        if success {
                            self?.activeSTDLive(withData: liveData)
                        } else {
                            self?.deactiveSTDLive()
                        }
                    })
                } else {
                    // 如果是局域网、p2p不用建立kcp
                    self.activeSTDLive(withData: liveData, sync: true)
                }
                // 如果在播放高清，关闭
                self.deactiveHDLive(sync: true)
            }
        }
    }
    func deactiveLive(sync: Bool = false) {
        deactiveHDLive(sync: sync)
        deactiveSTDLive(sync: sync)
    }

    func activeHDLive(withData data: Data, sync: Bool = false) {
        if sync {
            activeLiveComm(hdComm, andSend: data)
        } else {
            DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
                self?.activeLiveComm(self?.hdComm, andSend: data)
            }
        }
    }
    private func deactiveHDLive(sync: Bool = false) {
        if sync {
            deactiveLiveComm(hdComm)
            hdComm = nil
        } else {
            DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
                if let self = self, let comm = self.hdComm {
                    self.deactiveLiveComm(comm)
                    self.hdComm = nil
                }
            }
        }
    }

    private func activeSTDLive(withData data: Data, sync: Bool = false) {
        if sync {
            activeLiveComm(stdComm, andSend: data)
        } else {
            DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
                self?.activeLiveComm(self?.stdComm, andSend: data)
            }
        }
    }
    private func deactiveSTDLive(sync: Bool = false) {
        if sync {
            deactiveLiveComm(stdComm)
            stdComm = nil
        } else {
            DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
                if let self = self, let comm = self.stdComm {
                    self.deactiveLiveComm(comm)
                    self.stdComm = nil
                }
            }
        }
    }

    private func activeLiveComm(_ comm: DinLiveStreamingKcpObject?, andSend data: Data) {
        comm?.kcpObject.startReceiving()
        comm?.kcpObject.send(data)
        lastRequestLiveData = data
        startLiveStreamWatch()
    }
    private func deactiveLiveComm(_ comm: DinLiveStreamingKcpObject?) {
        guard let deactiveLiveComm = comm else { return }
        delegate?.manager(self, requestResignKcp: deactiveLiveComm.sessionID)
        deactiveLiveComm.kcpObject.stopReceiving()
        self.commObjects.removeValue(forKey: deactiveLiveComm.convString)
        stopLiveSteamWatch()
    }
}

// MARK: - 语音、对讲通道
extension DinChannelKcpObjectManager {
    func requestAudio(withData audioData: Data) {
        createAudioKcp()
        if self.type == .proxy {
            self.delegate?.manager(self, requestEstabKcp: self.audioComm?.sessionID ?? 0, channelID: self.audioComm?.channelID ?? 0, complete: { [weak self] success in
                if success {
                    self?.activeAudio(withData: audioData)
                } else {
                    self?.deactiveAudio()
                }
            })
        } else {
            // 如果是局域网、p2p不用建立kcp
            self.activeAudio(withData: audioData, sync: true)
        }
    }
    private func activeAudio(withData data: Data, sync: Bool = false) {
        if sync {
            audioComm?.kcpObject.startReceiving()
            audioComm?.kcpObject.send(data)
        } else {
            DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
                self?.audioComm?.kcpObject.startReceiving()
                self?.audioComm?.kcpObject.send(data)
            }
        }
    }
    func deactiveAudio() {
        DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
            if let self = self, let comm = self.audioComm {
                self.delegate?.manager(self, requestResignKcp: comm.sessionID)
                comm.kcpObject.stopReceiving()
                self.commObjects.removeValue(forKey: comm.convString)
                self.audioComm = nil
            }
        }
    }

    func beginTalking(withVoiceData data: Data) {
        DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
            guard let self = self else { return }
            if self.isTalking {
                self.talkComm?.kcpObject.send(data)
            } else {
                if self.isPreparingTalk {
                    return
                }
                self.createTalkKcp()
                self.isPreparingTalk = true
                if self.type == .proxy {
                    self.delegate?.manager(self, requestEstabKcp: self.talkComm?.sessionID ?? 0, channelID: self.talkComm?.channelID ?? 0, complete: { [weak self] success in
                        if success {
                            self?.acitveTalk(withData: data)
                        } else {
                            self?.deactiveTalk()
                        }
                    })
                } else {
                    // 如果是局域网、p2p不用建立kcp
                    self.acitveTalk(withData: data, sync: true)
                }
            }
        }
    }
    private func acitveTalk(withData data: Data, sync: Bool = false) {
        if sync {
            isPreparingTalk = false
            isTalking = true
            talkComm?.kcpObject.startReceiving()
            talkComm?.kcpObject.send(data)
        } else {
            DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
                self?.isPreparingTalk = false
                self?.isTalking = true
                self?.talkComm?.kcpObject.startReceiving()
                self?.talkComm?.kcpObject.send(data)
            }
        }
    }
    func deactiveTalk() {
        DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
            if let self = self, let comm = self.talkComm {
                comm.kcpObject.sendReset()
                self.delegate?.manager(self, requestResignKcp: comm.sessionID)
                comm.kcpObject.stopReceiving()
                self.commObjects.removeValue(forKey: comm.convString)
                self.talkComm = nil
            }
            self?.isPreparingTalk = false
            self?.isTalking = false
        }
    }
}

// MARK: - 下载SD卡里面的视频文件
extension DinChannelKcpObjectManager {
    func beginFetchFile(withFileName fileName: String, fileType type: String) {
        self.fileFetcher?.beginFetch(fileName, fileType: type)
    }

    func stopFetch(withFetchStatus status: DinChannelKcpObjectFileFetchStatus = .interrupt, cleanWaitingFiles: Bool = true) {
        self.fileFetcher?.stopFetch(withFetchStatus: status, cleanWaitingFiles: cleanWaitingFiles)
    }

    func cmdKeepLive() {
        DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
            guard let self = self else { return }
            self.keepliveBlock()
        }
    }
    func downloadKeepLive() {
        DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
            guard let self = self else { return }
            if let keepliveData = "{}".data(using: .utf8) {
                self.downloadComm?.kcpObject.send(keepliveData)
            }
        }
    }

    /// 发送下载指令到IPC，请求传输文件。
    /// 此方法是通过DinChannelKcpObjectFileFetcher类回调专用，请不要乱调用
    /// - Parameter data: 发送的下载指令
    func download(withData data: Data) {
        DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
            guard let self = self else { return }
            if self.isPreparingDownload {
                return
            }
            if self.downloadComm != nil {
                self.acitveDownload(withData: data, sync: true)
            } else {
                self.isPreparingDownload = true
                self.createDownloadKcp()
                if self.type == .proxy {
                    self.delegate?.manager(self, requestEstabKcp: self.downloadComm?.sessionID ?? 0, channelID: self.downloadComm?.channelID ?? 0, complete: { [weak self] success in
                        if success {
                            self?.acitveDownload(withData: data)
                        } else {
                            self?.deactiveDownload()
                        }
                    })
                } else {
                    // 如果是局域网、p2p不用建立kcp
                    self.acitveDownload(withData: data, sync: true)
                }
            }
        }
    }
    private func acitveDownload(withData data: Data, sync: Bool = false) {
        if sync {
            isPreparingDownload = false
            downloadComm?.kcpObject.startReceiving()
            downloadComm?.kcpObject.send(data)
        } else {
            DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
                self?.isPreparingDownload = false
                self?.downloadComm?.kcpObject.startReceiving()
                self?.downloadComm?.kcpObject.send(data)
            }
        }
    }
    func deactiveDownload() {
        DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
            if let self = self, let comm = self.downloadComm {
                comm.kcpObject.sendReset()
                self.delegate?.manager(self, requestResignKcp: comm.sessionID)
                comm.kcpObject.stopReceiving()
                self.commObjects.removeValue(forKey: comm.convString)
                self.downloadComm = nil
            }
            self?.isPreparingDownload = false
        }
    }
}
