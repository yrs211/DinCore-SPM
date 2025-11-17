//
//  DinDoHManager.swift
//  DinCore
//
//  Created by 黄先生 on 2025/5/30.
//

import Foundation
import RxSwift
import RxRelay

/// DoH管理器
public class DinDoHManager {
    
    /// 通过域名异步获取IP
    public func readValidIP(for domain: String, completion: @escaping (_ ip: String?) -> Void) {
        resolveIP(for: domain, completion: completion)
    }
}

extension DinDoHManager {
    
    /// 从本地数据库读取指定域名的 IP，如果缓存不存在或已过期，则通过 DoH 方式查询 IP
    private func resolveIP(for domain: String, completion: @escaping (_ ip: String?) -> Void) {
        if let resolvedIP = DinCore.dataBase.getAnswer(domain), !resolvedIP.isExpired {
            completion(resolvedIP.ip)
        } else {
            fetchAndCacheAnswer(for: domain, completion: completion)
        }
    }
    
    /// 查询 IP 并缓存查询结果
    private func fetchAndCacheAnswer(for domain: String, completion: @escaping (_ ip: String?) -> Void) {
        resolveFastestAnswer(for: domain) { [weak self] answer in
            guard let self = self, let answer = answer else {
                completion(nil)
                return
            }
            DinCore.dataBase.setAnswer(answer, domain: domain)
            completion(answer.ip)
        }
    }
    
    /// 竞速发起DoH获取IP ，超时的话就用系统的 DNS
    private func resolveFastestAnswer(for domain: String, completion: @escaping (Answer?) -> Void) {
        let cfAnswerDriver = PublishRelay<Answer>()
        let emaldoAnswerDriver = PublishRelay<Answer>()

        var disposable: Disposable? = nil

        disposable = Observable.merge(
            cfAnswerDriver.asObservable(),
            emaldoAnswerDriver.asObservable()
        )
        .timeout(.seconds(1), scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
        .take(1)
        .observe(on: MainScheduler.instance)
        .subscribe(
            onNext: { answer in
                // print("✅ 合并流收到: \(answer)")
                completion(answer)
                disposable?.dispose()
                disposable = nil
            },
            onError: { [weak self] error in
                // print("⚠️ 合并流超时或失败，尝试系统 DNS: \(error.localizedDescription)")
                self?.resolveUsingSystemDNS(domain: domain, completion: completion)
                disposable?.dispose()
                disposable = nil
            }
        )

        fetchDoHAnswer(for: domain, using: .cloudflare) { answer in
            if let answer = answer { cfAnswerDriver.accept(answer) }
        }

        fetchDoHAnswer(for: domain, using: .emaldo) { answer in
            if let answer = answer { emaldoAnswerDriver.accept(answer) }
        }
    }
    
    /// 发起 DoH 服务发送请求，获取域名的 IP 信息
    private func fetchDoHAnswer(for domain: String, using provider: DoHProvider, completion: @escaping (Answer?) -> Void) {
        let urlString = provider.url(for: domain)
        guard let url = URL(string: urlString) else {
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 3
        request.addValue("application/dns-json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
                guard
                    let data = data,
                    error == nil,
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let answers = json["Answer"] as? [[String: Any]]
                else {
                    return
                }

                if let aRecord = answers.first(where: { ($0["type"] as? Int) == 1 }),
                   let jsonData = try? JSONSerialization.data(withJSONObject: aRecord),
                   var answer = try? JSONDecoder().decode(Answer.self, from: jsonData) {
                    answer.timestamp = Date().timeIntervalSince1970
                    switch provider {
                    case .cloudflare:
                        answer.sourceType = .cloudflare
                    case .emaldo:
                        answer.sourceType = .emaldo
                    default:
                        break
                    }
                    completion(answer)
                }
            }.resume()
    }
    
    /// 发起系统的 DNS，获取域名的 IP 信息
    private func resolveUsingSystemDNS(domain: String, completion: @escaping (Answer?) -> Void) {
        let (host, port) = separateHostAndPort(from: domain)
        DispatchQueue.global(qos: .userInitiated).async {
            var hints = addrinfo(
                        ai_flags: AI_DEFAULT,
                        ai_family: AF_INET,
                        ai_socktype: SOCK_STREAM,
                        ai_protocol: IPPROTO_TCP,
                        ai_addrlen: 0,
                        ai_canonname: nil,
                        ai_addr: nil,
                        ai_next: nil
                    )

                    var result: UnsafeMutablePointer<addrinfo>?
                    let status = getaddrinfo(host, nil, &hints, &result)

                    defer { if result != nil { freeaddrinfo(result) } }

                    if status == 0, let addr = result?.pointee.ai_addr {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        let success = getnameinfo(
                            addr,
                            socklen_t(result!.pointee.ai_addrlen),
                            &hostname,
                            socklen_t(hostname.count),
                            nil,
                            0,
                            NI_NUMERICHOST
                        )
                        if success == 0, let ipString = String(validatingUTF8: hostname) {
                            var ipWithPort = ipString
                            if let port = port {
                                ipWithPort += ":\(port)"
                            }
                            
                            var answer = Answer(type: 1, domain: domain, ip: ipWithPort, ttl: 600)
                            answer.timestamp = Date().timeIntervalSince1970
                            answer.sourceType = .dns
                            DispatchQueue.main.async { completion(answer) }
                            return
                        }
                    }

                    DispatchQueue.main.async { completion(nil) }
        }
    }
    
    
    /// 剥离域名与端口号（假如有端口号的话）
    private func separateHostAndPort(from domain: String) -> (host: String, port: String?) {
        let nsDomain = domain as NSString
        let range = nsDomain.range(of: ":")
        if range.location != NSNotFound {
            let host = nsDomain.substring(to: range.location)
            let port = nsDomain.substring(from: range.location + 1)
            return (host, port)
        } else {
            return (domain, nil)
        }
    }
}

extension DinDoHManager {
    
    enum DoHProvider {
        case cloudflare
        case emaldo
        case google
        
        func url(for domain: String) -> String {
            switch self {
            case .cloudflare:
                return "https://cloudflare-dns.com/dns-query?name=\(domain)&type=A"
            case .emaldo:
                return "https://doh.emaldo.com/dns-query?name=\(domain)&type=A"
            case .google:
                return "https://dns.google/resolve?name=\(domain)&type=A"
            }
        }
    }
}

public struct Answer: Codable {
    
    enum SourceType: String, Codable {
        case cloudflare   // Cloudflare DoH
        case emaldo       // Emaldo DoH
        case dns       // 系统 DNS
    }
    
    let type: Int         // 记录类型，例如 1 代表 A 记录
    let domain: String      // 域名
    var ip: String      // 返回的 IP
    let ttl: Int          // 生存时间（秒）
    var timestamp: TimeInterval?   // 本次 DOH 请求完成的时间（单位：秒）
    var sourceType: SourceType?    // 来源类型
    
    enum CodingKeys: String, CodingKey {
        case type, domain = "name", ip = "data", ttl = "TTL", timestamp, sourceType
    }
    
    /// 判断缓存是否已过期
    var isExpired: Bool {
        guard let timestamp = timestamp else {
            return true
        }
        let now = Date().timeIntervalSince1970
        return now - timestamp > TimeInterval(ttl)
    }
}

