//
//  DinDataManager.swift
//  DinCore
//
//  Created by Jin on 2021/4/20.
//

import UIKit
import Objective_LevelDB

public class DinDataManager: NSObject {

    var levelDataBase: LevelDB?
    /// background线程保存数据，并行的
    let saveQueue: DispatchQueue = DispatchQueue(label: DinQueueName.appDataSave, attributes: .concurrent)

    /// 命名（保证唯一性，请尽量用项目相关的名字命名，例如bundleid）
    /// - Parameter dbName: 数据库名
    public init(withDataBaseName dbName: String) {
        super.init()
        levelDataBase = LevelDB.databaseInLibrary(withName: dbName) as? LevelDB
    }

    public func hasValue(withKey key: Any) -> Any? {
        var value: Any?
        saveQueue.sync { [weak self] in
            value = self?.levelDataBase?.object(forKey: key)
        }
        return value
    }
    
    public func saveValueAsync(withKey key: Any, value: Any) {
        saveQueue.async(flags: .barrier) { [weak self] in
            self?.levelDataBase?[key] = value
        }
    }

    public func removeValueAsync(withKey key: Any) {
        saveQueue.async(flags: .barrier) { [weak self] in
            self?.levelDataBase?.removeObject(forKey: key)
        }
    }

}
