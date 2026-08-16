//
//  SourceError.swift
//  AltStore
//
//  Created by Riley Testut on 5/3/23.
//  Copyright © 2023 Riley Testut. All rights reserved.
//

extension SourceError
{
    enum Code: Int, ALTErrorCode
    {
        typealias Error = SourceError
        
        case unsupported
        case duplicateBundleID
        case duplicateVersion
        
        case blocked
        case changedID
        case duplicate
        
        case missingPermissionUsageDescription
        case missingScreenshotSize
        
        case marketplaceNotSupported = 101
        case marketplaceRequired
    }
    
    static func unsupported(_ source: Source) -> SourceError { SourceError(code: .unsupported, source: source) }
    static func duplicateBundleID(_ bundleID: String, source: Source) -> SourceError { SourceError(code: .duplicateBundleID, source: source, bundleID: bundleID) }
    static func duplicateVersion(_ version: String, for app: StoreApp, source: Source) -> SourceError { SourceError(code: .duplicateVersion, source: source, app: app, version: version) }
    
    static func blocked(_ source: Source, bundleIDs: [String]?, existingSource: Source?) -> SourceError { SourceError(code: .blocked, source: source, existingSource: existingSource, bundleIDs: bundleIDs) }
    static func changedID(_ identifier: String, previousID: String, source: Source) -> SourceError { SourceError(code: .changedID, source: source, sourceID: identifier, previousSourceID: previousID) }
    static func duplicate(_ source: Source, existingSource: Source?) -> SourceError { SourceError(code: .duplicate, source: source, existingSource: existingSource) }
    
    static func missingPermissionUsageDescription(for permission: any ALTAppPermission, app: StoreApp, source: Source) -> SourceError {
        SourceError(code: .missingPermissionUsageDescription, source: source, app: app, permission: permission)
    }
    
    static func missingScreenshotSize(for screenshot: AppScreenshot, source: Source) -> SourceError {
        SourceError(code: .missingScreenshotSize, source: source, app: screenshot.app, screenshotURL: screenshot.imageURL)
    }
    
    static func marketplaceNotSupported(source: Source) -> SourceError {
        return SourceError(code: .marketplaceNotSupported, source: source)
    }
    
    static func marketplaceRequired(source: Source) -> SourceError {
        return SourceError(code: .marketplaceRequired, source: source)
    }
}

struct SourceError: ALTLocalizedError
{
    let code: Code
    var errorTitle: String?
    var errorFailure: String?
    
    @Managed var source: Source
    
    @Managed var app: StoreApp?
    @Managed var existingSource: Source?
    var version: String?
    var bundleID: String?
    var bundleIDs: [String]?
        
    // Store in userInfo so they can be viewed from Error Log.
    @UserInfoValue var sourceID: String?
    @UserInfoValue var previousSourceID: String?
    
    @UserInfoValue
    var permission: (any ALTAppPermission)?
    
    @UserInfoValue
    var screenshotURL: URL?
    
    var errorFailureReason: String {
        switch self.code
        {
        case .unsupported: return String(format: NSLocalizedString("此版本的 SideStore 不支持源“%@”。", comment: ""), self.$source.name)
        case .duplicateBundleID:
            let bundleIDFragment = self.bundleID.map { String(format: NSLocalizedString("bundle 标识符 %@", comment: ""), $0) } ?? NSLocalizedString("相同的 bundle 标识符", comment: "")
            let failureReason = String(format: NSLocalizedString("源“%@”包含多个具有 %@ 的应用。", comment: ""), self.$source.name, bundleIDFragment)
            return failureReason
            
        case .duplicateVersion:
            var versionFragment = NSLocalizedString("重复的版本", comment: "")
            if let version
            {
                versionFragment += " (\(version))"
            }
            
            let appFragment: String
            if let name = self.$app.name, let bundleID = self.$app.bundleIdentifier
            {
                appFragment = name + " (\(bundleID))"
            }
            else
            {
                appFragment = NSLocalizedString("一个或多个应用", comment: "")
            }
            
            let failureReason = String(format: NSLocalizedString("源“%@”包含 %@（针对 %@）。", comment: ""), self.$source.name, versionFragment, appFragment)
            return failureReason
            
        case .blocked:
            let failureReason = String(format: NSLocalizedString("出于安全原因，SideStore 已屏蔽源“%@”。", comment: ""), self.$source.name)
            return failureReason
            
        case .changedID:
            let failureReason = String(format: NSLocalizedString("源“%@”的标识符已更改。", comment: ""), self.$source.name)
            return failureReason
            
        case .duplicate:
            let baseMessage = String(format: NSLocalizedString("标识符为“%@”的源已存在", comment: ""), self.$source.identifier)
            guard let existingSourceName = self.$existingSource.name else { return baseMessage + "." }
            
            let failureReason = baseMessage + " (“\(existingSourceName)”)."
            return failureReason
            
        case .missingPermissionUsageDescription:
            let appName = self.$app.name ?? String(format: NSLocalizedString("源“%@”中的某个应用", comment: ""), self.$source.name)
            guard let permission else {
                return String(format: NSLocalizedString("%@的某项权限缺少用途说明。", comment: ""), appName)
            }
            
            let permissionType = permission.type.localizedName ?? NSLocalizedString("权限", comment: "")
            let failureReason = String(format: NSLocalizedString("%@“%@”（用于 %@）缺少用途说明。", comment: ""), permissionType.lowercased(), permission.rawValue, appName)
            return failureReason
            
        case .missingScreenshotSize:
            let appName = self.$app.name ?? String(format: NSLocalizedString("源“%@”中的某个应用", comment: ""), self.$source.name)
            let baseMessage = String(format: NSLocalizedString("%@的 iPad 截图未指定尺寸", comment: ""), appName)
            guard let screenshotURL else { return baseMessage + "." }
            
            let failureReason = baseMessage + ": \(screenshotURL.absoluteString)"
            return failureReason
            
        case .marketplaceNotSupported:
            let failureReason = String(format: NSLocalizedString("源“%@”包含已公证（notarized）的应用，而此版本的 SideStore 不支持它们。", comment: ""), self.$source.name)
            return failureReason
            
        case .marketplaceRequired:
            let failureReason = String(format: NSLocalizedString("源“%@”中的一个或多个应用缺少 marketplaceID。这很可能意味着它们未经公证（notarized），而此版本的 SideStore 不支持这种情况。", comment: ""), self.$source.name)
            return failureReason
        }
    }
    
    var recoverySuggestion: String? {
        switch self.code
        {
        case .blocked:
            if self.existingSource != nil
            {
                // Source already added, so tell them to remove it + any installed apps.
                let baseMessage = NSLocalizedString("为了你的安全，请移除该源并卸载", comment: "")
                
                if let blockedAppNames = self.blockedAppNames
                {
                    let recoverySuggestion = baseMessage + " " + NSLocalizedString("以下应用：", comment: "") + "\n\n" + blockedAppNames.joined(separator: "\n")
                    return recoverySuggestion
                }
                else
                {
                    let recoverySuggestion = baseMessage + " " + NSLocalizedString("所有从此源下载的应用。", comment: "")
                    return recoverySuggestion
                }
            }
            else
            {
                // Source is not already added, so no need to tell users to remove it.
                // Instead, we just list all affected apps (if provided).
                guard let blockedAppNames else { return nil }
                
                let recoverySuggestion = NSLocalizedString("以下应用已被标记：", comment: "") + "\n\n" + blockedAppNames.joined(separator: "\n")
                return recoverySuggestion
            }
            
        case .changedID: return NSLocalizedString("源一旦添加便无法更改其标识符。此源无法再更新。", comment: "")
        case .duplicate:
            let recoverySuggestion = NSLocalizedString("请移除现有源，以便添加此源。", comment: "")
            return recoverySuggestion
            
        case .marketplaceRequired:
            let failureReason = String(format: NSLocalizedString("SideStore 只能安装已由 Apple 公证（notarized）的 marketplace 应用。", comment: ""), self.$source.name)
            return failureReason
            
        default: return nil
        }
    }
}

private extension SourceError
{
    var blockedAppNames: [String]? {
        let blockedAppNames: [String]?
        
        if let existingSource
        {
            // Blocked apps = all installed apps from this source.
            blockedAppNames = self.$existingSource.perform { _ in
                let storeApps = existingSource.apps.lazy.filter { $0.installedApp != nil }
                guard !storeApps.isEmpty else { return nil }
                
                let appNames = storeApps.map { "\($0.name) (\($0.bundleIdentifier))" }
                return Array(appNames)
            }
        }
        else if let bundleIDs
        {
            // Blocked apps = explicitly listed bundleIDs in blocked source JSON entry.
            blockedAppNames = self.$source.perform { source in
                bundleIDs.compactMap { (bundleID) in
                    guard let storeApp = source._apps.lazy.compactMap({ $0 as? StoreApp }).first(where: { $0.bundleIdentifier == bundleID }) else { return nil }
                    return "\(storeApp.name) (\(storeApp.bundleIdentifier))"
                }
            }
        }
        else
        {
            blockedAppNames = nil
        }

        let sortedNames = blockedAppNames?.sorted { $0.localizedCompare($1) == .orderedAscending }
        return sortedNames
    }
}
