//
//  DinChannelKcpObjectManager+ResultHandler.swift
//  DinCore
//
//  Created by Jin on 2021/8/24.
//

import Foundation
import DinSupport
import DinSupportObjC

extension DinChannelKcpObjectManager: KCPObjectDelegate {
    public func kcp(_ kcp: KCPObject, didReceivedData data: Data) {
        if kcp == hdComm?.kcpObject {
            self.delegate?.manager(self, receivedHDLiveData: data, isReset: false)
            DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
                self?.liveDataArriveTime = Date().timeIntervalSince1970
            }
        } else if kcp == stdComm?.kcpObject {
            self.delegate?.manager(self, receivedSTDLiveData: data, isReset: false)
            DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
                self?.liveDataArriveTime = Date().timeIntervalSince1970
            }
        } else if kcp == audioComm?.kcpObject {
            self.delegate?.manager(self, receivedAudioData: data, isReset: false)
        } else if kcp == talkComm?.kcpObject {
            self.delegate?.manager(self, receivedTalkData: data, isReset: false)
        } else if kcp == cmdComm?.kcpObject {
            self.delegate?.manager(self, receivedCMDData: data, isReset: false)
        } else if kcp == downloadComm?.kcpObject {
            self.fileFetcher?.handleFileFetch(data: data)
        }
    }

    public func kcpDidReceivedResetRequest(_ kcp: KCPObject) {
        if kcp == hdComm?.kcpObject {
            self.delegate?.manager(self, receivedHDLiveData: nil, isReset: true)
            DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
                self?.resetLiveComm(withQualityHD: true, needSendRST: false)
            }
        } else if kcp == stdComm?.kcpObject {
            self.delegate?.manager(self, receivedSTDLiveData: nil, isReset: true)
            DinChannelKcpObjectManager.kcpCreateQueue.async { [weak self] in
                self?.resetLiveComm(withQualityHD: false, needSendRST: false)
            }
        } else if kcp == audioComm?.kcpObject {
            self.delegate?.manager(self, receivedAudioData: nil, isReset: true)
            deactiveAudio()
        } else if kcp == talkComm?.kcpObject {
            self.delegate?.manager(self, receivedTalkData: nil, isReset: true)
            deactiveTalk()
        } else if kcp == cmdComm?.kcpObject {
            self.delegate?.manager(self, receivedCMDData: nil, isReset: true)
            deactiveCMDKcp()
        } else if kcp == downloadComm?.kcpObject {
            stopFetch(withFetchStatus: .kcpReset, cleanWaitingFiles: false)
            deactiveDownload()
        }
    }
}

extension DinChannelKcpObjectManager: DinChannelKcpObjectFileFetcherDelegate {
    func fetcher(_ fetcher: DinChannelKcpObjectFileFetcher, receivedFileAt filePath: String, fileName: String, fileType: String, status: DinChannelKcpObjectFileFetchStatus) {
        self.delegate?.manager(self, receivedFileAt: filePath, fileName: fileName, fileType: fileType, status: status)
    }

    func fetcher(sendReset fetcher: DinChannelKcpObjectFileFetcher) {
        deactiveDownload()
    }

    func fetcher(_ fetcher: DinChannelKcpObjectFileFetcher, requestSend data: Data) {
        download(withData: data)
    }
}
