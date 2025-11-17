//
//  DinDataManager+DoH.swift
//  DinCore
//
//  Created by 黄先生 on 2025/5/30.
//

import Foundation

public extension DinDataManager {
    
    func setAnswer(_ answer: Answer?, domain: String) {
        guard let answer = answer else {
            removeValueAsync(withKey: domain)
            return
        }
        guard let data = try? JSONEncoder().encode(answer) else {
            return
        }
        saveValueAsync(withKey: domain, value: data)
    }

    func getAnswer(_ domain: String) -> Answer? {
        guard let data = hasValue(withKey: domain) as? Data, let answer = try? JSONDecoder().decode(Answer.self, from: data) else {
            return nil
        }
        return answer
    }
}
