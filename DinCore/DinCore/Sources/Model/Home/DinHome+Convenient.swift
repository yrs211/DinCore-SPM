//
//  DinHome+Convenient.swift
//  DinCore
//
//  Created by Monsoir on 2021/6/23.
//
//  暂时提供便利的方法，主要是因为部分数据没有模型化，当数据模型化后，可以作修改或移除

import Foundation

extension DinHome {

#if ENABLE_DINCORE_PANEL
    /// 是否绑定了主机
    public var hasPanelBound: Bool {
        !(getDevices(withCategoryID: DinNovaPanel.panelCategoryID)?.isEmpty ?? true)
    }
#endif
}
