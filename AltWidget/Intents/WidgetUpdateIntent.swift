//
//  WidgetUpdateIntent.swift
//  AltStore
//
//  Created by Magesh K on 10/01/25.
//  Copyright © 2025 SideStore. All rights reserved.
//

import AppIntents

@available(iOS 17, *)
final class WidgetUpdateIntent: WidgetConfigurationIntent, @unchecked Sendable {
    public static let COMMON_WIDGET_ID = 1
    
    static var title: LocalizedStringResource { "小组件 ID 更新意图" }
    static var isDiscoverable: Bool { false }
    
    @Parameter(title: "ID", description: "提供一个数字 ID 以标识小组件", default: 1)
    var ID: Int?
}
