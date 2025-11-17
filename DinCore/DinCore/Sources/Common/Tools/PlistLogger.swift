//
//  PlistLogger.swift
//  Logger
//
//  Created by Monsoir on 2021/3/1.
//

import Foundation

class PlistLogger {

    private lazy var queue = DispatchQueue(label: "plist.logger")
    typealias Logs = [String]
    private lazy var logs: Logs = {
        let result = _readLogs()
        return result
    }()

    private let capacity: Int
    private let fileURL: URL

    private lazy var encoder = PropertyListEncoder()
    private let recordLength = 8000

    init(capacity: Int, fileURL: URL) {
        self.capacity = capacity
        self.fileURL = fileURL
    }

    func log(_ content: @escaping @autoclosure () -> Any) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self._log(content())
        }
    }

    private func _log(_ content: @autoclosure () -> Any) {
        ensureSize {
            let record: String = {
                var result = "\(content())"
                if result.count > recordLength {
                    result = String(result.prefix(recordLength))
                }
                return result
            }()
            logs.append(record)
            flush()
        }
    }

    private func ensureSize(_ completion: () -> Void) {
        let delta = logs.count - capacity
        guard delta > 0 else {
            completion()
            return
        }

        for _ in 0..<delta {
            logs.removeFirst()
        }

        completion()
    }

    private func flush() {
        guard let data = try? encoder.encode(logs) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func readLogs(_ completion: @escaping (Logs) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let result = self._readLogs()
            completion(result)
        }
    }

    func clear() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.logs.removeAll(keepingCapacity: true)
        }
    }

    func readLogsAsJSON(_ completion: @escaping (String?) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let logs = self._readLogs()
            guard !logs.isEmpty else {
                completion(nil)
                return
            }
            if let data = try? JSONEncoder().encode(logs) {
                let result = String(data: data, encoding: .utf8)
                completion(result)
                return
            }
            completion(nil)
        }
    }

    private func _readLogs() -> Logs {
        guard
            let data = try? Data(contentsOf: fileURL)
        else {
            var result = Logs()
            result.reserveCapacity(capacity)
            return result
        }

        let decoder = PropertyListDecoder()
        let result = (try? decoder.decode(Logs.self, from: data)) ?? {
            var result = Logs()
            result.reserveCapacity(capacity)
            return result
        }()
        return result
    }
}
