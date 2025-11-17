//
//  DinFileUploadManager.swift
//  DinCore
//
//  Created by Mia on 2025/7/16.
//

import Alamofire

public class DinFileUploadManager: NSObject {
    
    // MARK: - 公共方法
    
    
    /// 通过Data获取文件信息并打印
    /// - Parameters:
    ///   - data: 文件数据
    ///   - mimeType: 文件MIME类型，如不提供则默认为application/octet-stream
    /// - Returns: 包含文件大小和MIME类型的元组
    public static func getAndPrintFileInfo(data: Data, mimeType: String? = nil) -> (size: Int, mimeType: String) {
        let fileSize = data.count
        let actualMimeType = mimeType ?? "image/png"
        
        print("📁 文件信息:")
        print("📏 文件大小: \(fileSize) 字节")
        print("🏷️ 文件类型: \(actualMimeType)")
        
        return (fileSize, actualMimeType)
    }
    
    /// 使用预签名URL上传文件数据
    /// - Parameters:
    ///   - data: 要上传的文件数据
    ///   - preSignedURL: 预签名的上传URL
    ///   - mimeType: 文件MIME类型，如不提供则默认为image/jpeg
    ///   - progressHandler: 进度回调，返回0-1之间的上传进度
    ///   - completion: 完成回调，成功返回true，失败返回错误信息
    public static func uploadData(_ data: Data,
                                     fileName: String,
                                     preSignedURL: String,
                                     mimeType: String = "image/png",
                                     progressHandler: ((Double) -> Void)? = nil,
                                     completion: @escaping (Result<Void, Error>) -> Void) {
        
        // 获取文件信息并打印
        let fileInfo = getAndPrintFileInfo(data: data, mimeType: mimeType)
        
        print("🚀 开始上传文件...")
        print("📤 上传URL: \(preSignedURL)")
        
        // 创建URLRequest
        var request = URLRequest(url: URL(string: preSignedURL)!)
        request.httpMethod = "PUT"
        request.setValue(fileInfo.mimeType, forHTTPHeaderField: "Content-Type")
        request.setValue("\(fileInfo.size)", forHTTPHeaderField: "Content-Length")
        
        // 使用Alamofire上传
        AF.upload(data, with: request)
            .uploadProgress { progress in
                let progressValue = progress.fractionCompleted
                print("📊 上传进度: \(Int(progressValue * 100))%")
                progressHandler?(progressValue)
            }
            .response { response in
                if let error = response.error {
                    print("❌ 上传失败: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                // 检查状态码
                if let statusCode = response.response?.statusCode {
                    let isSuccess = (200...299).contains(statusCode)
                    print(isSuccess ? "✅ 上传成功 (状态码: \(statusCode))" : "❌ 上传失败 (状态码: \(statusCode))")
                    if isSuccess {
                        completion(.success(()))
                    } else {
                        completion(.failure(NSError(domain: "UploadError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "上传失败，服务器返回状态码 \(statusCode)"])))
                    }
                } else {
                    print("❌ 上传失败: 无响应状态码")
                    completion(.failure(NSError(domain: "UploadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "上传失败，无响应状态码"])))
                }
            }
    }
}
