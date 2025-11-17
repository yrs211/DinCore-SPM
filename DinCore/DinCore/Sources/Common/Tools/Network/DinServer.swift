//
//  DinServer.swift
//  DinCore
//
//  Created by Jin on 2021/4/21.
//

import UIKit
import Alamofire
import Moya

//open class MyServerTrustManager: ServerTrustManager {
//    open override func serverTrustEvaluator(forHost host: String) throws -> ServerTrustEvaluating? {
//        return DisabledTrustEvaluator()
//    }
//}

public class HostOverrideSessionDelegate: SessionDelegate {
    /// 拦截所有来自 ServerTrust 的挑战
    public override func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // 只处理服务器信任挑战
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust,
           let originalRequest = task.originalRequest,
           let originalHostWithPort = originalRequest.value(forHTTPHeaderField: "Host") {

           // 移除端口号（如果有）
           let originalHost = originalHostWithPort.components(separatedBy: ":").first ?? originalHostWithPort
            
            // 创建一个新的 SecPolicy，使用原始域名做校验
            let policy = SecPolicyCreateSSL(true, originalHost as CFString)
            SecTrustSetPolicies(serverTrust, policy)

            var result = SecTrustResultType.invalid
            SecTrustEvaluate(serverTrust, &result)
            let trusted = (result == .proceed || result == .unspecified)
            
            if trusted {
                // 验证通过
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                // 验证失败，走默认处理
                completionHandler(.performDefaultHandling, nil)
            }
        } else {
            // 对于其他类型挑战，保持默认
            completionHandler(.performDefaultHandling, nil)
        }
    }
}


class DinServer: NSObject {
    // 单例
    static let shared = DinServer()
    // 提供外部只读访问的网络 Session
    var session: Alamofire.Session {
        return defaultSession
    }
    // 网络模块
    private let defaultSession: Alamofire.Session
    // App模块
    var appProvider: MoyaProvider<DinRequest>
    // 授权模块
    var authProvider: MoyaProvider<DinAuthRequest>
    // 新用户模块
    var userProvider: MoyaProvider<DinUserRequest>
    // 家庭模块
    var homeProvider: MoyaProvider<DinHomeRequest>
    // 二维码模块
    var qrcodeProvider: MoyaProvider<DinQRCodeRequest>
    // 维修模块
    var fixProvider: MoyaProvider<DinFixRequest>

#if ENABLE_DINCORE_LIVESTREAMING
    // ipc 模块
    var cameraProvider: MoyaProvider<DinLiveStreamingRequest>
#endif

    // 第三方ipc模块
    var thirdPartyCameraProvider: MoyaProvider<DinThirdPartyCameraRequest>
    // upload模块
    var uploadProvider: MoyaProvider<DinUploadRequest>

#if ENABLE_DINCORE_PANEL
    // 主机请求模块
    var panelProvider: MoyaProvider<DinNovaPanelRequest>
    // 主机操作模块
    var panelOpProvider: MoyaProvider<DinNovaPanelOperationRequest>
    // 主机配件请求模块
    var pluginProvider: MoyaProvider<DinNovaPluginRequest>
    // 主机配件操作模块
    var pluginOpProvider: MoyaProvider<DinNovaPluginOperationRequest>
    // 主机小工具请求模块
    var widgetOpProvider: MoyaProvider<DinNovaWidgetRequest>
#endif

#if ENABLE_DINCORE_LIVESTREAMING
    // 自研IPC请求模块
    var dinCameraProvider: MoyaProvider<DinLiveStreamingRequest>

    /// 可视门铃请求模块
    var dinDoorbellProvider: MoyaProvider<DinLiveStreamingRequest>
#endif

#if ENABLE_DINCORE_STORAGE_BATTERY
    var storageBatteryProvider: MoyaProvider<DinStorageBatteryRequest>
    
    var storageBatteryStatsProvider: MoyaProvider<DinStorageBatteryStatsRequest>
#endif

    // Initialization
    private override init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
//        let trustManager = MyServerTrustManager(allHostsMustBeEvaluated: false, evaluators: [:])
        let sessionDelegate = HostOverrideSessionDelegate()
        defaultSession = Alamofire.Session(
            configuration: configuration,
//            serverTrustManager: trustManager,
            delegate: sessionDelegate
        )

        appProvider = MoyaProvider<DinRequest>(session: defaultSession)
        authProvider = MoyaProvider<DinAuthRequest>(session: defaultSession)
        userProvider = MoyaProvider<DinUserRequest>(session: defaultSession)
        homeProvider = MoyaProvider<DinHomeRequest>(session: defaultSession)
        qrcodeProvider = MoyaProvider<DinQRCodeRequest>(session: defaultSession)
        fixProvider = MoyaProvider<DinFixRequest>(session: defaultSession)
#if ENABLE_DINCORE_LIVESTREAMING
        cameraProvider = MoyaProvider<DinLiveStreamingRequest>(session: defaultSession)
#endif
        thirdPartyCameraProvider = MoyaProvider<DinThirdPartyCameraRequest>(session: defaultSession)
        uploadProvider = MoyaProvider<DinUploadRequest>(session: defaultSession)
#if ENABLE_DINCORE_PANEL
        panelProvider = MoyaProvider<DinNovaPanelRequest>(session: defaultSession)
        panelOpProvider = MoyaProvider<DinNovaPanelOperationRequest>(session: defaultSession)
        pluginProvider = MoyaProvider<DinNovaPluginRequest>(session: defaultSession)
        pluginOpProvider = MoyaProvider<DinNovaPluginOperationRequest>(session: defaultSession)
        widgetOpProvider = MoyaProvider<DinNovaWidgetRequest>(session: defaultSession)
#endif
#if ENABLE_DINCORE_LIVESTREAMING
        dinCameraProvider = MoyaProvider<DinLiveStreamingRequest>(session: defaultSession)
        dinDoorbellProvider = MoyaProvider<DinLiveStreamingRequest>(session: defaultSession)
#endif
#if ENABLE_DINCORE_STORAGE_BATTERY
        storageBatteryProvider = MoyaProvider<DinStorageBatteryRequest>(session: defaultSession)
        storageBatteryStatsProvider = MoyaProvider<DinStorageBatteryStatsRequest>(session: defaultSession)
#endif
    }
}

extension DinServer {
    func requestServer(with httpParams: DinHttpRequest,
                       complete: ((Data?, AFDataResponse<Data?>?, Error?) -> Void)?) {
        guard httpParams.requestParam != nil else {
            complete?(nil, nil, DinNetwork.Error.lackParams(httpParams.path))
            return
        }


        if let appRequest = httpParams as? DinRequest {
            appProvider.requestWithDoHUsingCoreSession(appRequest) { [weak self] (result) in
                self?.receiveAppResult(httpParams, result: result, completeBlock: complete)
            }
            return
        }

        if let authRequest = httpParams as? DinAuthRequest {
            authProvider.requestWithDoHUsingCoreSession(authRequest) { [weak self] (result) in
                self?.receiveResult(httpParams, result: result, completeBlock: complete)
            }
            return
        }

        if let userRequest = httpParams as? DinUserRequest {
            userProvider.requestWithDoHUsingCoreSession(userRequest) { [weak self] (result) in
                self?.receiveResult(httpParams, result: result, completeBlock: complete)
            }
            return
        }

        if let homeRequest = httpParams as? DinHomeRequest {
            homeProvider.requestWithDoHUsingCoreSession(homeRequest) { [weak self] (result) in
                self?.receiveResult(httpParams, result: result, completeBlock: complete)
            }
            return
        }

        if let qrcodeRequest = httpParams as? DinQRCodeRequest {
            qrcodeProvider.requestWithDoHUsingCoreSession(qrcodeRequest) { [weak self] (result) in
                self?.receiveResult(httpParams, result: result, completeBlock: complete)
            }
            return
        }
        
        if let fixRequest = httpParams as? DinFixRequest {
            fixProvider.requestWithDoHUsingCoreSession(fixRequest) { [weak self] (result) in
                self?.receiveResult(httpParams, result: result, completeBlock: complete)
            }
            return
        }

#if ENABLE_DINCORE_LIVESTREAMING
        if let cameraRequest = httpParams as? DinLiveStreamingRequest {
            cameraProvider.requestWithDoHUsingCoreSession(cameraRequest) { [weak self] (result) in
                self?.receiveResult(httpParams, result: result, completeBlock: complete)
            }
            return
        }
#endif

        if let thirdPartyCameraRequest = httpParams as? DinThirdPartyCameraRequest {
            thirdPartyCameraProvider.requestWithDoHUsingCoreSession(thirdPartyCameraRequest) { [weak self] (result) in
                self?.receiveResult(httpParams, result: result, completeBlock: complete)
            }
            return
        }

        if let uploadRequest = httpParams as? DinUploadRequest {
            uploadProvider.requestWithDoHUsingCoreSession(uploadRequest) { [weak self] (result) in
                self?.receiveResult(httpParams, result: result, completeBlock: complete)
            }
            return
        }

#if ENABLE_DINCORE_PANEL
        if let panelRequest = httpParams as? DinNovaPanelRequest {
            panelProvider.requestWithDoHUsingCoreSession(panelRequest) { [weak self] (result) in
                self?.receiveResult(httpParams, result: result, completeBlock: complete)
            }
            return
        }

        if let panelOpRequest = httpParams as? DinNovaPanelOperationRequest {
            panelOpProvider.requestWithDoHUsingCoreSession(panelOpRequest) { [weak self] (result) in
                self?.receiveResultByfilterSuccessfulStatusOnly(httpParams, result: result, completeBlock: complete)
            }
            return
        }

        if let pluginRequest = httpParams as? DinNovaPluginRequest {
            pluginProvider.requestWithDoHUsingCoreSession(pluginRequest) { [weak self] (result) in
                self?.receiveResultByfilterSuccessfulStatusOnly(httpParams, result: result, completeBlock: complete)
            }
            return
        }

        if let pluginOpRequest = httpParams as? DinNovaPluginOperationRequest {
            pluginOpProvider.requestWithDoHUsingCoreSession(pluginOpRequest) { [weak self] (result) in
                self?.receiveResultByfilterSuccessfulStatusOnly(httpParams, result: result, completeBlock: complete)
            }
            return
        }

        if let widgetRequest = httpParams as? DinNovaWidgetRequest {
            widgetOpProvider.requestWithDoHUsingCoreSession(widgetRequest) { [weak self] result in
                self?.receiveResultByfilterSuccessfulStatusOnly(httpParams, result: result, completeBlock: complete)
            }
            return
        }
#endif

#if ENABLE_DINCORE_LIVESTREAMING
        if let dinCameraRequest = httpParams as? DinLiveStreamingRequest {
            dinCameraProvider.requestWithDoHUsingCoreSession(dinCameraRequest) { [weak self] (result) in
                self?.receiveResultByfilterSuccessfulStatusOnly(httpParams, result: result, completeBlock: complete)
            }
            return
        }
#endif

#if ENABLE_DINCORE_STORAGE_BATTERY
        if let request = httpParams as? DinStorageBatteryRequest {
            storageBatteryProvider.requestWithDoHUsingCoreSession(request) { [weak self] result in
                self?.receiveResultByfilterSuccessfulStatusOnly(httpParams, result: result, completeBlock: complete)
            }
            return
        }

        if let request = httpParams as? DinStorageBatteryStatsRequest {
            storageBatteryStatsProvider.requestWithDoHUsingCoreSession(request) { [weak self] result in
                self?.receiveResultByfilterSuccessfulStatusOnly(httpParams, result: result, completeBlock: complete)
            }
            return
        }
#endif
    }

    private func receiveAppResult(_ httpParams: DinHttpRequest,
                               result: Result<Moya.Response, MoyaError>,
                               completeBlock: ((Data?, AFDataResponse<Data?>?, Error?) -> Void)?) {
        switch result {
        case let .success(moyaResponse):
            do {
                _ = try moyaResponse.filterSuccessfulStatusAndRedirectCodes()
            } catch {
                let statusCode = moyaResponse.response?.statusCode ?? -992
                completeBlock?(nil, nil, DinNetwork.Error.apiFail(httpParams.path, statusCode))
                return
            }
            completeBlock?(moyaResponse.data, nil, nil)
        case let .failure(error):
            completeBlock?(nil, nil, error)
        }
    }

    private func receiveResult(_ httpParams: DinHttpRequest,
                               result: Result<Moya.Response, MoyaError>,
                               completeBlock: ((Data?, AFDataResponse<Data?>?, Error?) -> Void)?) {
        switch result {
        case let .success(moyaResponse):
            do {
                _ = try moyaResponse.filterSuccessfulStatusAndRedirectCodes()
            } catch {
                let statusCode = moyaResponse.response?.statusCode ?? -992
                completeBlock?(nil, nil, DinNetwork.Error.apiFail(httpParams.path, statusCode))
                return
            }
            completeBlock?(moyaResponse.data, nil, nil)
        case let .failure(error):
            completeBlock?(nil, nil, error)
        }
    }

    private func receiveResultByfilterSuccessfulStatusOnly(_ httpParams: DinHttpRequest,
                                                           result: Result<Moya.Response, MoyaError>,
                                                           completeBlock: ((Data?, AFDataResponse<Data?>?, Error?) -> Void)?) {
        switch result {
        case let .success(moyaResponse):
            do {
                _ = try moyaResponse.filterSuccessfulStatusCodes()
            } catch {
                let statusCode = moyaResponse.response?.statusCode ?? -992
                completeBlock?(nil, nil, DinNetwork.Error.apiFail(httpParams.path, statusCode))
                return
            }
            completeBlock?(moyaResponse.data, nil, nil)
        case let .failure(error):
            completeBlock?(nil, nil, error)
        }
    }
}
