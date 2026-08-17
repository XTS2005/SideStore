//
//  ScheduleExpirationWarningNotificationOperation.swift
//  SideStore
//
//  Created by Magesh K on 30/07/26.
//  Copyright © 2026 AltStore. All rights reserved.
//

import UserNotifications
import Foundation

final class ScheduleExpirationWarningNotificationOperation: BaseStandaloneOperation<StandaloneOperationContext, Bool>, @unchecked Sendable {
    let installedApp: InstalledApp

    init(installedApp: InstalledApp, context: StandaloneOperationContext) throws {
        self.installedApp = installedApp
        try super.init(context: context)
    }

    override func execute(parentProgress: Progress?) async throws -> Bool {
        debugLog("[ScheduleExpirationWarningNotificationOperation] execute() started")
        defer { debugLog("[ScheduleExpirationWarningNotificationOperation] execute() completed") }
        try await super.executePreconditionCheck(parentProgress: parentProgress)
        self.setProgress(10)

        let center = UNUserNotificationCenter.current()
        let now = Date()
        var expirationDate = Date()
        self.setProgress(30)
        installedApp.managedObjectContext?.performAndWait {
            expirationDate = installedApp.expirationDate
        }

        let milestones: [(id: String, timeBeforeExp: TimeInterval, title: String, body: String)] = [
            ("24h", 24 * 60 * 60, "SideStore 即将过期", "SideStore 将在 24 小时后过期。打开应用并刷新，以防止过期。"),
            ("6h",   6 * 60 * 60, "SideStore 即将很快过期", "SideStore 将在 6 小时后过期！立即刷新以防过期。"),
            ("0h",   0,           "SideStore 已过期", "SideStore 已过期。请刷新或重新安装应用。")
        ]

        let allIdentifiers = milestones.map { "\(AppManager.expirationWarningNotificationID).\($0.id)" }
        self.setProgress(50)
        center.removePendingNotificationRequests(withIdentifiers: allIdentifiers)

        let startProgress = self.progress.completedUnitCount
        let endProgress: Int64 = 95
        let range = endProgress - startProgress
        let count = milestones.count
        
        for (index, milestone) in milestones.enumerated() {
            if range > 0 {
                let percent = startProgress + Int64(Double(index + 1) / Double(count) * Double(range))
                self.setProgress(percent)
            }
            
            let identifier = "\(AppManager.expirationWarningNotificationID).\(milestone.id)"
            let targetDate = expirationDate.addingTimeInterval(-milestone.timeBeforeExp)
            let triggerInterval = targetDate.timeIntervalSince(now)

            // Skip milestones that are already in the past
            guard triggerInterval > 0 else { continue }

            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString(milestone.title, comment: "")
            content.body = NSLocalizedString(milestone.body, comment: "")
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerInterval, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            try await center.add(request)
        }
        self.setProgress(100)
        return true
    }
}
