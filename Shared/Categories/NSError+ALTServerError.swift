//
//  NSError+ALTServerError.swift
//  AltStore
//
//  Created by Magesh K on 2026-06-28.
//

import Foundation

public let AltServerErrorDomain = "AltServer.ServerError"
public let AltServerInstallationErrorDomain = "Apple.InstallationError"
public let AltServerConnectionErrorDomain = "AltServer.ConnectionError"

public let ALTUnderlyingErrorDomainErrorKey = "underlyingErrorDomain"
public let ALTUnderlyingErrorCodeErrorKey = "underlyingErrorCode"
public let ALTProvisioningProfileBundleIDErrorKey = "bundleIdentifier"
public let ALTDeviceNameErrorKey = "deviceName"
public let ALTOperatingSystemNameErrorKey = "ALTOperatingSystemName"
public let ALTOperatingSystemVersionErrorKey = "ALTOperatingSystemVersion"

public let ALTNSCodingPathKey = "NSCodingPath"
public let ALTAppNameErrorKey = "appName"

@objc(ALTServerError)
public enum ALTServerErrorEnum: Int, Codable {
    case underlyingError = -1
    case unknown = 0
    case connectionFailed = 1
    case lostConnection = 2
    case deviceNotFound = 3
    case deviceWriteFailed = 4
    case invalidRequest = 5
    case invalidResponse = 6
    case invalidApp = 7
    case installationFailed = 8
    case maximumFreeAppLimitReached = 9
    case unsupportediOSVersion = 10
    case unknownRequest = 11
    case unknownResponse = 12
    case invalidAnisetteData = 13
    case pluginNotFound = 14
    case profileNotFound = 15
    case appDeletionFailed = 16
    case requestedAppNotRunning = 100
    case incompatibleDeveloperDisk = 101
}

public struct ALTServerError: Error, CustomNSError, Hashable, RawRepresentable, Codable {
    public typealias Code = ALTServerErrorEnum
    
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public var userInfo: [String: Any] = [:]
    
    public init(_ code: Code, userInfo: [String: Any]? = nil) {
        self.rawValue = code.rawValue
        self.userInfo = userInfo ?? [:]
    }
    
    public var code: Code {
        return Code(rawValue: rawValue) ?? .unknown
    }
    
    public static var errorDomain: String {
        return AltServerErrorDomain
    }
    
    public var errorCode: Int {
        return rawValue
    }
    
    public var errorUserInfo: [String: Any] {
        return userInfo
    }
    
    private enum CodingKeys: String, CodingKey {
        case rawValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.rawValue = try container.decode(Int.self, forKey: .rawValue)
        self.userInfo = [:]
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rawValue, forKey: .rawValue)
    }
}

extension ALTServerError {
    public static let underlyingError = Code.underlyingError
    public static let unknown = Code.unknown
    public static let connectionFailed = Code.connectionFailed
    public static let lostConnection = Code.lostConnection
    public static let deviceNotFound = Code.deviceNotFound
    public static let deviceWriteFailed = Code.deviceWriteFailed
    public static let invalidRequest = Code.invalidRequest
    public static let invalidResponse = Code.invalidResponse
    public static let invalidApp = Code.invalidApp
    public static let installationFailed = Code.installationFailed
    public static let maximumFreeAppLimitReached = Code.maximumFreeAppLimitReached
    public static let unsupportediOSVersion = Code.unsupportediOSVersion
    public static let unknownRequest = Code.unknownRequest
    public static let unknownResponse = Code.unknownResponse
    public static let invalidAnisetteData = Code.invalidAnisetteData
    public static let pluginNotFound = Code.pluginNotFound
    public static let profileNotFound = Code.profileNotFound
    public static let appDeletionFailed = Code.appDeletionFailed
    public static let requestedAppNotRunning = Code.requestedAppNotRunning
    public static let incompatibleDeveloperDisk = Code.incompatibleDeveloperDisk
}

@objc(ALTServerConnectionError)
public enum ALTServerConnectionErrorEnum: Int, Codable {
    case unknown = 0
    case deviceLocked = 1
    case invalidRequest = 2
    case invalidResponse = 3
    case usbmuxd = 4
    case ssl = 5
    case timedOut = 6
}

public struct ALTServerConnectionError: Error, CustomNSError, Hashable, RawRepresentable, Codable {
    public typealias Code = ALTServerConnectionErrorEnum
    
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public var userInfo: [String: Any] = [:]
    
    public init(_ code: Code, userInfo: [String: Any]? = nil) {
        self.rawValue = code.rawValue
        self.userInfo = userInfo ?? [:]
    }
    
    public var code: Code {
        return Code(rawValue: rawValue) ?? .unknown
    }
    
    public static var errorDomain: String {
        return AltServerConnectionErrorDomain
    }
    
    public var errorCode: Int {
        return rawValue
    }
    
    public var errorUserInfo: [String: Any] {
        return userInfo
    }
    
    private enum CodingKeys: String, CodingKey {
        case rawValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.rawValue = try container.decode(Int.self, forKey: .rawValue)
        self.userInfo = [:]
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rawValue, forKey: .rawValue)
    }
}

extension ALTServerConnectionError {
    public static let unknown = Code.unknown
    public static let deviceLocked = Code.deviceLocked
    public static let invalidRequest = Code.invalidRequest
    public static let invalidResponse = Code.invalidResponse
    public static let usbmuxd = Code.usbmuxd
    public static let ssl = Code.ssl
    public static let timedOut = Code.timedOut
}

// MARK: - NSError Extension

extension NSError {
    @objc public var altserver_localizedDescription: String? {
        guard self.domain == AltServerErrorDomain else { return nil }
        let code = ALTServerError.Code(rawValue: self.code) ?? .unknown
        switch code {
        case .underlyingError:
            let underlyingError = self.userInfo[NSUnderlyingErrorKey] as? NSError
            return underlyingError?.localizedDescription
            
        case .invalidRequest, .invalidResponse:
            let underlyingError = self.userInfo[NSUnderlyingErrorKey] as? NSError
            if let underlyingError {
                return underlyingError.localizedDescription
            }
            return nil
            
        default:
            return nil
        }
    }
    
    @objc public var altserver_localizedFailure: String? {
        guard self.domain == AltServerErrorDomain else { return nil }
        let code = ALTServerError.Code(rawValue: self.code) ?? .unknown
        switch code {
        case .underlyingError:
            let underlyingError = self.userInfo[NSUnderlyingErrorKey] as? NSError
            return underlyingError?.localizedFailure
            
        case .connectionFailed:
            let underlyingError = self.userInfo[NSUnderlyingErrorKey] as? NSError
            if underlyingError?.localizedFailureReason != nil {
                #if os(macOS)
                return NSLocalizedString("连接设备时出错。", comment: "")
                #else
                return NSLocalizedString("AltServer 无法与 SideStore 建立连接。", comment: "")
                #endif
            }
            return nil
            
        default:
            return nil
        }
    }
    
    @objc public var altserver_localizedFailureReason: String? {
        guard self.domain == AltServerErrorDomain else { return nil }
        let code = ALTServerError.Code(rawValue: self.code) ?? .unknown
        switch code {
        case .underlyingError:
            let underlyingError = self.userInfo[NSUnderlyingErrorKey] as? NSError
            if let reason = underlyingError?.localizedFailureReason {
                return reason
            }
            if let underlyingErrorCode = self.userInfo[ALTUnderlyingErrorCodeErrorKey] as? String {
                return String(format: NSLocalizedString("错误代码：%@", comment: ""), underlyingErrorCode)
            }
            return nil
            
        case .unknown:
            return NSLocalizedString("发生未知错误。", comment: "")
            
        case .connectionFailed:
            let underlyingError = self.userInfo[NSUnderlyingErrorKey] as? NSError
            if let reason = underlyingError?.localizedFailureReason {
                return reason
            }
            #if os(macOS)
            return NSLocalizedString("连接设备时出错。", comment: "")
            #else
            return NSLocalizedString("无法连接到 SideStore。", comment: "")
            #endif
            
        case .lostConnection:
            return NSLocalizedString("与 SideStore 的连接已断开。", comment: "")
            
        case .deviceNotFound:
            return NSLocalizedString("SideStore 找不到此设备。", comment: "")
            
        case .deviceWriteFailed:
            return NSLocalizedString("SideStore 无法向此设备写入数据。", comment: "")
            
        case .invalidRequest:
            let underlyingError = self.userInfo[NSUnderlyingErrorKey] as? NSError
            return underlyingError?.localizedFailureReason ?? NSLocalizedString("SideStore 收到了无效的请求。", comment: "")
            
        case .invalidResponse:
            let underlyingError = self.userInfo[NSUnderlyingErrorKey] as? NSError
            return underlyingError?.localizedFailureReason ?? NSLocalizedString("SideStore 发送了无效的响应。", comment: "")
            
        case .invalidApp:
            return NSLocalizedString("应用格式无效。", comment: "")
            
        case .installationFailed:
            let underlyingError = self.userInfo[NSUnderlyingErrorKey] as? NSError
            if let underlyingError {
                return underlyingError.localizedFailureReason ?? underlyingError.localizedDescription
            }
            return NSLocalizedString("安装应用时出错。", comment: "")
            
        case .maximumFreeAppLimitReached:
            return NSLocalizedString("使用非开发者 Apple ID 最多只能激活 3 个应用。", comment: "")
            
        case .unsupportediOSVersion:
            let appName = self.userInfo[ALTAppNameErrorKey] as? String
            let osVersion = self.altserver_osVersion
            if appName == nil || osVersion == nil {
                return NSLocalizedString("你的设备必须运行 iOS 15.0 或更高版本才能安装 SideStore。", comment: "")
            }
            return String(format: NSLocalizedString("%@需要 %@ 或更高版本。", comment: ""), appName!, osVersion!)
            
        case .unknownRequest:
            return NSLocalizedString("SideStore 不支持此请求。", comment: "")
            
        case .unknownResponse:
            return NSLocalizedString("SideStore 从 SideStore 收到了未知响应。", comment: "")
            
        case .invalidAnisetteData:
            return NSLocalizedString("提供的 anisette 数据无效。", comment: "")
            
        case .pluginNotFound:
            return NSLocalizedString("AltServer 无法连接到 Mail 插件。", comment: "")
            
        case .profileNotFound:
            return self.profileErrorLocalizedDescription(baseDescription: NSLocalizedString("找不到描述文件", comment: ""))
            
        case .appDeletionFailed:
            return NSLocalizedString("移除应用时出错。", comment: "")
            
        case .requestedAppNotRunning:
            let appName = (self.userInfo[ALTAppNameErrorKey] as? String) ?? NSLocalizedString("所请求的应用", comment: "")
            let deviceName = (self.userInfo[ALTDeviceNameErrorKey] as? String) ?? NSLocalizedString("该设备", comment: "")
            return String(format: NSLocalizedString("%@当前未在 %@ 上运行。", comment: ""), appName, deviceName)
            
        case .incompatibleDeveloperDisk:
            let osVersion = self.altserver_osVersion ?? NSLocalizedString("此设备的系统版本", comment: "")
            return String(format: NSLocalizedString("磁盘与 %@ 不兼容。", comment: ""), osVersion)
        }
    }
    
    @objc public var altserver_localizedRecoverySuggestion: String? {
        guard self.domain == AltServerErrorDomain else { return nil }
        let code = ALTServerError.Code(rawValue: self.code) ?? .unknown
        switch code {
        case .underlyingError:
            let underlyingError = self.userInfo[NSUnderlyingErrorKey] as? NSError
            return underlyingError?.localizedRecoverySuggestion
            
        case .connectionFailed:
            let underlyingError = self.userInfo[NSUnderlyingErrorKey] as? NSError
            if let suggestion = underlyingError?.localizedRecoverySuggestion {
                return suggestion
            }
            fallthrough
            
        case .deviceNotFound:
            return NSLocalizedString("请确保你已在电脑上信任此设备，并且已启用 Wi-Fi 同步。", comment: "")
            
        case .pluginNotFound:
            return NSLocalizedString("Mail 已自动打开，请稍等片刻后重试。否则，请确保已在 Mail 的偏好设置中启用插件。", comment: "")
            
        case .maximumFreeAppLimitReached:
            #if os(macOS)
            return NSLocalizedString("请使用 SideStore 停用一个侧载应用，以便安装另一个应用。\n\n如果你运行的是 iOS 13.5 或更高版本，请确保已在“设置 > iTunes 与 App Store”中关闭“卸载未使用的应用”，然后安装或删除所有已卸载的应用，以免它们被错误地计入此限制。", comment: "")
            #else
            return NSLocalizedString("请停用一个侧载应用，以便安装另一个应用。\n\n如果你运行的是 iOS 13.5 或更高版本，请确保已在“设置 > iTunes 与 App Store”中关闭“卸载未使用的应用”，然后安装或删除所有已卸载的应用。", comment: "")
            #endif
            
        case .requestedAppNotRunning:
            let deviceName = (self.userInfo[ALTDeviceNameErrorKey] as? String) ?? NSLocalizedString("你的设备", comment: "")
            return String(format: NSLocalizedString("请确保应用在 %@ 上前台运行，然后重试。", comment: ""), deviceName)
            
        default:
            return nil
        }
    }
    
    @objc public var altserver_localizedDebugDescription: String? {
        guard self.domain == AltServerErrorDomain else { return nil }
        let code = ALTServerError.Code(rawValue: self.code) ?? .unknown
        switch code {
        case .underlyingError, .invalidRequest, .invalidResponse:
            let underlyingError = self.userInfo[NSUnderlyingErrorKey] as? NSError
            return underlyingError?.localizedDebugDescription
            
        case .incompatibleDeveloperDisk:
            guard let path = self.userInfo[NSFilePathErrorKey] as? String else { return nil }
            let osVersion = self.altserver_osVersion ?? NSLocalizedString("此设备的系统版本", comment: "")
            return String(format: NSLocalizedString("位于 %@ 的 Developer disk 与 %@ 不兼容。", comment: ""), path, osVersion)
            
        default:
            return nil
        }
    }
    
    private func profileErrorLocalizedDescription(baseDescription: String) -> String {
        if let bundleID = self.userInfo[ALTProvisioningProfileBundleIDErrorKey] as? String {
            return String(format: "%@ “%@”", baseDescription, bundleID)
        } else {
            return String(format: "%@.", baseDescription)
        }
    }
    
    @objc public var altserver_osVersion: String? {
        guard let osName = self.userInfo[ALTOperatingSystemNameErrorKey] as? String,
              let versionString = self.userInfo[ALTOperatingSystemVersionErrorKey] as? String else { return nil }
        return "\(osName) \(versionString)"
    }
    
    // Connection Error Providers
    @objc public var altserver_connection_localizedFailureReason: String? {
        guard self.domain == AltServerConnectionErrorDomain else { return nil }
        let code = ALTServerConnectionError.Code(rawValue: self.code) ?? .unknown
        switch code {
        case .unknown:
            let underlyingErrorDomain = self.userInfo[ALTUnderlyingErrorDomainErrorKey] as? String
            let underlyingErrorCode = self.userInfo[ALTUnderlyingErrorCodeErrorKey] as? String
            if let underlyingErrorDomain, let underlyingErrorCode {
                return String(format: NSLocalizedString("%@ 错误 %@。", comment: ""), underlyingErrorDomain, underlyingErrorCode)
            } else if let underlyingErrorCode {
                return String(format: NSLocalizedString("连接错误代码：%@", comment: ""), underlyingErrorCode)
            }
            return nil
            
        case .deviceLocked:
            let deviceName = (self.userInfo[ALTDeviceNameErrorKey] as? String) ?? NSLocalizedString("该设备", comment: "")
            return String(format: NSLocalizedString("%@当前处于锁定状态。", comment: ""), deviceName)
            
        case .invalidRequest:
            let deviceName = (self.userInfo[ALTDeviceNameErrorKey] as? String) ?? NSLocalizedString("该设备", comment: "")
            return String(format: NSLocalizedString("%@收到了来自 SideStore 的无效请求。", comment: ""), deviceName)
            
        case .invalidResponse:
            let deviceName = (self.userInfo[ALTDeviceNameErrorKey] as? String) ?? NSLocalizedString("该设备", comment: "")
            return String(format: NSLocalizedString("SideStore 收到了来自 %@ 的无效响应。", comment: ""), deviceName)
            
        case .usbmuxd:
            return NSLocalizedString("与 usbmuxd 守护进程通信时出现问题。", comment: "")
            
        case .ssl:
            let deviceName = (self.userInfo[ALTDeviceNameErrorKey] as? String) ?? NSLocalizedString("该设备", comment: "")
            return String(format: NSLocalizedString("SideStore 无法与 %@ 建立安全连接。", comment: ""), deviceName)
            
        case .timedOut:
            let deviceName = (self.userInfo[ALTDeviceNameErrorKey] as? String) ?? NSLocalizedString("该设备", comment: "")
            return String(format: NSLocalizedString("SideStore 与 %@ 的连接已超时。", comment: ""), deviceName)
        }
    }
    
    @objc public var altserver_connection_localizedRecoverySuggestion: String? {
        guard self.domain == AltServerConnectionErrorDomain else { return nil }
        let code = ALTServerConnectionError.Code(rawValue: self.code) ?? .unknown
        switch code {
        case .deviceLocked:
            return NSLocalizedString("请使用密码解锁设备，然后重试。", comment: "")
        default:
            return nil
        }
    }
}

// MARK: - Registration of UserInfo Providers

private let _installALTServerErrorProviders: Void = {
    NSError.setUserInfoValueProvider(forDomain: AltServerErrorDomain) { error, key in
        let nsError = error as NSError
        switch key {
        case NSLocalizedDescriptionKey:
            return nsError.altserver_localizedDescription
        case NSLocalizedFailureErrorKey:
            return nsError.altserver_localizedFailure
        case NSLocalizedFailureReasonErrorKey:
            return nsError.altserver_localizedFailureReason
        case NSLocalizedRecoverySuggestionErrorKey:
            return nsError.altserver_localizedRecoverySuggestion
        case NSDebugDescriptionErrorKey:
            return nsError.altserver_localizedDebugDescription
        default:
            return nil
        }
    }
    
    NSError.setUserInfoValueProvider(forDomain: AltServerConnectionErrorDomain) { error, key in
        let nsError = error as NSError
        switch key {
        case NSLocalizedFailureReasonErrorKey:
            return nsError.altserver_connection_localizedFailureReason
        case NSLocalizedRecoverySuggestionErrorKey:
            return nsError.altserver_connection_localizedRecoverySuggestion
        default:
            return nil
        }
    }
}()

private let __installServerErrorHelper: Void = { _ = _installALTServerErrorProviders }()

public func ~= (lhs: ALTServerError.Code, rhs: Error) -> Bool {
    let error = rhs as NSError
    guard error.domain == AltServerErrorDomain else { return false }
    return error.code == lhs.rawValue
}

public func ~= (lhs: ALTServerError, rhs: Error) -> Bool {
    let error = rhs as NSError
    guard error.domain == AltServerErrorDomain else { return false }
    return error.code == lhs.rawValue
}

public func ~= (lhs: ALTServerConnectionError.Code, rhs: Error) -> Bool {
    let error = rhs as NSError
    guard error.domain == AltServerConnectionErrorDomain else { return false }
    return error.code == lhs.rawValue
}
