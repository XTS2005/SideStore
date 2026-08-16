//
//  OperationError.swift
//  AltStore
//
//  Created by Riley Testut on 6/7/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import Foundation
@preconcurrency import AltSign

extension OperationError
{
    enum Code: Int, ALTErrorCode, CaseIterable {
        typealias Error = OperationError
        
        // General
        case unknown = 1000
        case unknownResult = 1001
//        case cancelled = 1002
        case timedOut = 1003
        case notAuthenticated = 1004
        case appNotFound = 1005
        case unknownUDID = 1006
        case invalidApp = 1007
        case invalidParameters = 1008
        case maximumAppIDLimitReached = 1009
        case noSources = 1010
        case openAppFailed = 1011
        case missingAppGroup = 1012
        case forbidden = 1013
        case sourceNotAdded = 1014


        // Connection
        
        /* Connection */
        case serverNotFound = 1200
        case connectionFailed = 1201
        case connectionDropped = 1202
        
        /* Pledges */
        case pledgeRequired = 1401
        case pledgeInactive = 1402

        /* SideStore Only */
        case unableToConnectSideJIT
        case unableToRespondSideJITDevice
        case wrongSideJITIP
        case SideJITIssue // (error: String)
        case refreshsidejit
        case refreshAppFailed
        case tooNewError
        case anisetteV1Error//(message: String)
        case provisioningError//(result: String, message: String?)
        case anisetteV3Error//(message: String)
        case cacheClearError//(errors: [String])
        case noConnection
        case noVPN
        case noDevice
        case notReachable
        case invalidPairingFile
        case minimuxerNotStarted
        case pairingNotComplete

        case invalidOperationContext
        case sideStoreBundleIDMismatch
    }
    
    static var cancelled: CancellationError { CancellationError() }
    
    static let unknownResult: OperationError = .init(code: .unknownResult)
    static let timedOut: OperationError = .init(code: .timedOut)
    static let unableToConnectSideJIT: OperationError = .init(code: .unableToConnectSideJIT)
    static let unableToRespondSideJITDevice: OperationError = .init(code: .unableToRespondSideJITDevice)
    static let wrongSideJITIP: OperationError = .init(code: .wrongSideJITIP)
    static let notAuthenticated: OperationError = .init(code: .notAuthenticated)
    static let unknownUDID: OperationError = .init(code: .unknownUDID)
    static let invalidApp: OperationError = .init(code: .invalidApp)
    static let noSources: OperationError = .init(code: .noSources)
    static let missingAppGroup: OperationError = .init(code: .missingAppGroup)
    
    static func noConnection(reason: String? = nil) -> OperationError { OperationError(code: .noConnection, failureReason: reason) }
    static func noVPN(reason: String? = nil) -> OperationError { OperationError(code: .noVPN, failureReason: reason) }
    static func invalidVPN(reason: String? = nil) -> OperationError { OperationError(code: .noVPN, failureReason: reason) }
    static func noDevice(reason: String? = nil) -> OperationError { OperationError(code: .noDevice, failureReason: reason) }
    static func notReachable(reason: String) -> OperationError {
        OperationError(code: .notReachable, failureReason: reason)
    }
    static func invalidPairingFile(reason: String? = nil) -> OperationError { OperationError(code: .invalidPairingFile, failureReason: reason) }
    static func minimuxerNotStarted(reason: String? = nil) -> OperationError { OperationError(code: .minimuxerNotStarted, failureReason: reason) }
    static func pairingNotComplete(reason: String? = nil) -> OperationError { OperationError(code: .pairingNotComplete, failureReason: reason) }
    static let tooNewError: OperationError = .init(code: .tooNewError)
    static let provisioningError: OperationError = .init(code: .provisioningError)
    static let anisetteV1Error: OperationError = .init(code: .anisetteV1Error)
    static let anisetteV3Error: OperationError = .init(code: .anisetteV3Error)
    
    static let cacheClearError: OperationError = .init(code: .cacheClearError)

    static func unknown(failureReason: String? = nil, file: String = #fileID, line: UInt = #line) -> OperationError {
        OperationError(code: .unknown, failureReason: failureReason, sourceFile: file, sourceLine: line)
    }

    static func appNotFound(name: String?) -> OperationError {
        OperationError(code: .appNotFound, appName: name)
    }

    static func openAppFailed(name: String?) -> OperationError {
        OperationError(code: .openAppFailed, appName: name)
    }
    static let domain = OperationError(code: .unknown)._domain
    
    static func SideJITIssue(error: String?) -> OperationError {
        var o = OperationError(code: .SideJITIssue)
        o.errorFailure = error
        return o
    }
    
    static func maximumAppIDLimitReached(appName: String, requiredAppIDs: Int, availableAppIDs: Int, expirationDate: Date) -> OperationError {
        OperationError(code: .maximumAppIDLimitReached, appName: appName, requiredAppIDs: requiredAppIDs, availableAppIDs: availableAppIDs, expirationDate: expirationDate)
    }

    static func provisioningError(result: String, message: String?) -> OperationError {
        var o = OperationError(code: .provisioningError, failureReason: result)
        o.errorTitle = message
        return o
    }

    static func certificateRevoked(appName: String) -> OperationError {
        OperationError(code: .provisioningError, failureReason: String(format: NSLocalizedString("用于安装“%@”的签名证书已在 Apple Developer 门户上被撤销。请重新签名或重新安装该应用。", comment: ""), appName))
    }

    static func customCertificateRevoked(appName: String, activeTeam: String) -> OperationError {
        var o = OperationError(code: .provisioningError, failureReason: String(format: NSLocalizedString("你当前使用的自定义/第三方签名证书（团队：%@）已在 Developer Portal 上被撤销。\n\n如果你并非有意使用自定义证书，请在“设置 -> 高级 -> 证书”中重置。", comment: ""), activeTeam))
        o.errorTitle = NSLocalizedString("自定义证书已被撤销", comment: "")
        return o
    }

    static func customCertificateExpired(appName: String, activeTeam: String) -> OperationError {
        var o = OperationError(code: .provisioningError, failureReason: String(format: NSLocalizedString("你当前使用的自定义/第三方签名证书（团队：%@）已过期。\n\n如果你并非有意使用自定义证书，请在“设置 -> 高级 -> 证书”中重置。", comment: ""), activeTeam))
        o.errorTitle = NSLocalizedString("自定义证书已过期", comment: "")
        return o
    }

    static func certificateExpired(appName: String) -> OperationError {
        OperationError(code: .provisioningError, failureReason: String(format: NSLocalizedString("用于安装“%@”的签名证书已过期。请重新签名或重新安装该应用。", comment: ""), appName))
    }

    static func certificateChanged(appName: String) -> OperationError {
        OperationError(code: .provisioningError, failureReason: String(format: NSLocalizedString("用于安装“%@”的签名证书与你当前使用的签名证书不同。请重新签名或重新安装该应用。", comment: ""), appName))
    }

    static func cacheClearError(errors: [String]) -> OperationError {
        OperationError(code: .cacheClearError, failureReason: errors.joined(separator: "\n"))
    }

    static func anisetteV1Error(message: String) -> OperationError {
        OperationError(code: .anisetteV1Error, failureReason: message)
    }

    static func anisetteV3Error(message: String) -> OperationError {
        OperationError(code: .anisetteV3Error, failureReason: message)
    }

    static func refreshAppFailed(message: String) -> OperationError {
        OperationError(code: .refreshAppFailed, failureReason: message)
    }

    static func invalidParameters(_ message: String? = nil) -> OperationError {
        OperationError(code: .invalidParameters, failureReason: message)
    }
    
    static func sideStoreBundleIDMismatch(targetBundleID: String, activeBundleID: String) -> OperationError {
        OperationError(code: .sideStoreBundleIDMismatch, failureReason: String(format: NSLocalizedString("目标 bundle ID“%@”与当前 SideStore 实例“%@”不匹配。\n\n此操作不允许执行，因为 SideStore 无法管理除自身以外的数据库容器。", comment: ""), targetBundleID, activeBundleID))
    }
    
    static func invalidOperationContext(_ message: String? = nil) -> OperationError {
        OperationError(code: .invalidOperationContext, failureReason: message)
    }
    
    static func forbidden(failureReason: String? = nil, file: String = #fileID, line: UInt = #line) -> OperationError {
        OperationError(code: .forbidden, failureReason: failureReason, sourceFile: file, sourceLine: line)
    }
    
    static func sourceNotAdded(@Managed _ source: Source, file: String = #fileID, line: UInt = #line) -> OperationError {
        OperationError(code: .sourceNotAdded, sourceName: $source.name, sourceFile: file, sourceLine: line)
    }
    
    static func pledgeRequired(appName: String, file: String = #fileID, line: UInt = #line) -> OperationError {
        OperationError(code: .pledgeRequired, appName: appName, sourceFile: file, sourceLine: line)
    }
    
    static func pledgeInactive(appName: String, file: String = #fileID, line: UInt = #line) -> OperationError {
        OperationError(code: .pledgeInactive, appName: appName, sourceFile: file, sourceLine: line)
    }
}


struct OperationError: ALTLocalizedError {

    let code: Code

    var errorTitle: String?
    var errorFailure: String?
    
    @UserInfoValue
    var appName: String?
    
    @UserInfoValue
    var sourceName: String?
    
    var requiredAppIDs: Int?
    var availableAppIDs: Int?
    var expirationDate: Date?

    var sourceFile: String?
    var sourceLine: UInt?

    private var _failureReason: String?

    private init(code: Code, failureReason: String? = nil,
                 appName: String? = nil, sourceName: String? = nil, requiredAppIDs: Int? = nil,
                 availableAppIDs: Int? = nil, expirationDate: Date? = nil, sourceFile: String? = nil, sourceLine: UInt? = nil){
        self.code = code
        self._failureReason = failureReason

        self.appName = appName
        self.sourceName = sourceName
        self.requiredAppIDs = requiredAppIDs
        self.availableAppIDs = availableAppIDs
        self.expirationDate = expirationDate
        self.sourceFile = sourceFile
        self.sourceLine = sourceLine
    }

    var errorFailureReason: String {
        switch self.code {
        case .unknown:
            var failureReason = self._failureReason ?? NSLocalizedString("发生未知错误。", comment: "")
            guard let sourceFile, let sourceLine else { return failureReason }
            failureReason += " (\(sourceFile) line \(sourceLine)"
            return failureReason
        case .unknownResult: return NSLocalizedString("操作返回了未知结果。", comment: "")
        case .timedOut: return NSLocalizedString("操作超时。", comment: "")
        case .notAuthenticated: return NSLocalizedString("你尚未登录。", comment: "")
        case .unknownUDID: return NSLocalizedString("SideStore 无法确定此设备的 UDID。请使用 iloader 重新配对。", comment: "")
        case .invalidApp: return NSLocalizedString("应用格式无效。", comment: "")
        case .maximumAppIDLimitReached: return NSLocalizedString("7 天内最多只能注册 10 个应用 ID。", comment: "")
        case .noSources: return NSLocalizedString("没有可用的 SideStore 源。", comment: "")
        case .missingAppGroup: return NSLocalizedString("无法访问 SideStore 的共享应用组。", comment: "")
        case .forbidden:
            guard let failureReason = self._failureReason else { return NSLocalizedString("此操作被禁止。", comment: "") }
            return failureReason
            
        case .sourceNotAdded:
            let sourceName = self.sourceName.map { String(format: NSLocalizedString("源“%@”", comment: ""), $0) } ?? NSLocalizedString("该源", comment: "")
            return String(format: NSLocalizedString("%@尚未添加到 SideStore。", comment: ""), sourceName)

        case .appNotFound:
            let appName = self.appName ?? NSLocalizedString("该应用", comment: "")
            return String(format: NSLocalizedString("找不到%@。", comment: ""), appName)
        case .openAppFailed:
            let appName = self.appName ?? NSLocalizedString("该应用", comment: "")
            return String(format: NSLocalizedString("SideStore 被拒绝授予启动 %@ 的权限。", comment: ""), appName)
        case .noConnection:
            if let reason = self._failureReason, !reason.isEmpty {
                return String(format: NSLocalizedString("网络连接错误：\n%@\n\n请先连接到 Wi-Fi，然后再尝试后续操作。", comment: ""), reason)
            }
            return NSLocalizedString("你似乎没有连接到 Wi-Fi！\n\n请先连接到 Wi-Fi，然后再尝试后续操作", comment: "")
        case .noVPN:
            if let reason = self._failureReason, !reason.isEmpty {
                return String(format: NSLocalizedString("VPN 连接错误：\n%@\n\n请确保 LocalDevVPN 已连接并正常运行。", comment: ""), reason)
            }
            return NSLocalizedString("你似乎没有连接到 VPN。\n\n请确保 LocalDevVPN 已连接并正在运行！如果问题仍然存在，请使用 iloader 重新配对，或尝试重启设备。", comment: "")
        case .noDevice:
            if let reason = self._failureReason, !reason.isEmpty {
                return String(format: NSLocalizedString("SideStore 无法访问设备端点：\n%@\n\n请检查“设置”中的连接配置。", comment: ""), reason)
            }
            return NSLocalizedString("SideStore 无法访问设备端点。\n\n请检查“设置”中的连接配置，确保 IP 和端点正确。", comment: "")
        case .notReachable: return self._failureReason ?? NSLocalizedString("无法在指定的 IP/端点找到设备。", comment: "")
        case .invalidPairingFile: return NSLocalizedString("当前的配对文件无效或缺失。\n\n请确保输入了有效的配对文件！如果问题仍然存在，请使用 iloader 重新配对。", comment: "")
        case .minimuxerNotStarted: return NSLocalizedString("Minimuxer 尚未启动。\n\n请先完成配对或启动 minimuxer，然后再执行操作。", comment: "")
        case .pairingNotComplete: return NSLocalizedString("需要配对：\n如果没有有效的配对文件，SideStore 操作将无法连接到你的设备。请配对设备或导入有效的配对文件。", comment: "")
        case .tooNewError: return NSLocalizedString("iOS 17.0-17.3.1 改变了启用 JIT 的方式，因此在这些版本上 SideStore 无法在没有 SideJITServer 的情况下启用 JIT，给你带来不便，敬请谅解。", comment: "")
        case .unableToConnectSideJIT: return NSLocalizedString("无法连接到 SideJITServer。请检查你是否与服务器处于同一 Wi-Fi，以及服务器上的防火墙是否已正确配置。", comment: "")
        case .unableToRespondSideJITDevice: return NSLocalizedString("SideJITServer 无法连接到你的 iDevice。请确保你已通过运行“SideJITServer -y”配对 iDevice，或尝试在“设置”中刷新 SideJITServer。", comment: "")
        case .wrongSideJITIP: return NSLocalizedString("SideJITServer 的 IP 不正确。请确保你与 SideJITServer 处于同一 Wi-Fi", comment: "")
        case .refreshsidejit: return NSLocalizedString("找不到应用；请尝试在“设置”中刷新 SideJITServer。", comment: "")
        case .anisetteV1Error:
            let message = self._failureReason ?? ""
            return String(format: NSLocalizedString("从 V1 服务器获取 anisette 数据时出错：%@。请尝试使用其它 anisette 服务器。", comment: ""), message)
        case .provisioningError:
            let result = self._failureReason ?? ""
            let message = self.errorTitle ?? ""
            let combined = message.isEmpty ? result : "\(result) \(message)"
            let trimmed = combined.trimmingCharacters(in: CharacterSet(charactersIn: " ."))
            return String(format: NSLocalizedString("配置描述文件时出错：%@。请重试。如果问题仍然存在，请在 GitHub Issues 上报告！", comment: ""), trimmed)
        case .anisetteV3Error:
            let message = self._failureReason ?? ""
            return String(format: NSLocalizedString("从 V3 服务器获取 anisette 数据时出错：%@。请重试。如果问题仍然存在，请在 GitHub Issues 上报告！", comment: ""), message)
        case .cacheClearError:
            let message = self._failureReason ?? ""
            return String(format: NSLocalizedString("清除缓存时出错：%@", comment: ""), message)
        case .SideJITIssue:
            let message = self.errorFailure ?? ""
            return String(format: NSLocalizedString("使用 SideJIT 时出错：%@", comment: ""), message)
            
        case .refreshAppFailed:
            let message = self._failureReason ?? ""
            return String(format: NSLocalizedString("无法刷新应用\n%@", comment: ""), message)

        case .invalidParameters:
            let message = self._failureReason.map { ": \n\($0)" } ?? "."
            return String(format: NSLocalizedString("无效的参数%@", comment: ""), message)
        case .invalidOperationContext:
            let message = self._failureReason.map { ": \n\($0)" } ?? "."
            return String(format: NSLocalizedString("无效的操作上下文%@", comment: ""), message)
        case .sideStoreBundleIDMismatch:
            let message = self._failureReason ?? ""
            return String(format: NSLocalizedString("包名 ID 不匹配：%@", comment: ""), message)
        case .serverNotFound: return NSLocalizedString("找不到 AltServer。", comment: "")
        case .connectionFailed: return NSLocalizedString("无法与 AltServer 建立连接。", comment: "")
        case .connectionDropped: return NSLocalizedString("与 AltServer 的连接已断开。", comment: "")
            
        case .pledgeRequired:
            let appName = self.appName ?? NSLocalizedString("此应用", comment: "")
            return String(format: NSLocalizedString("%@需要有效的赞助（pledge）才能安装。", comment: ""), appName)
            
        case .pledgeInactive:
            let appName = self.appName ?? NSLocalizedString("此应用", comment: "")
            return String(format: NSLocalizedString("你的赞助（pledge）已不再有效。请续费，以便继续正常使用 %@。", comment: ""), appName)
        }
        
    }
    
    var recoverySuggestion: String? {
        switch self.code
        {
        case .noConnection: return NSLocalizedString("请连接到 Wi-Fi 网络、Bridge 或有线网络连接！", comment: "")
        case .noVPN: return NSLocalizedString("请确保 LocalDevVPN 已连接并正在运行！", comment: "")
        case .invalidPairingFile: return NSLocalizedString("请导入有效的 mobiledevicepairing 文件。", comment: "")
        case .serverNotFound: return NSLocalizedString("请确保你与运行 AltServer 的电脑处于同一 Wi-Fi 网络，或尝试通过 USB 将此设备连接到电脑。", comment: "")
        case .maximumAppIDLimitReached:
            let baseMessage = NSLocalizedString("删除侧载的应用以释放应用 ID 名额。", comment: "")
            guard let appName, let requiredAppIDs, let availableAppIDs, let expirationDate else { return baseMessage }
            var message: String

            if requiredAppIDs > 1
            {
                let availableText: String
                
                switch availableAppIDs
                {
                case 0: availableText = NSLocalizedString("一个都不剩", comment: "")
                case 1: availableText = NSLocalizedString("只剩 1 个", comment: "")
                default: availableText = String(format: NSLocalizedString("只剩 %@ 个", comment: ""), NSNumber(value: availableAppIDs))
                }
                
                let prefixMessage = String(format: NSLocalizedString("%@需要 %@ 个应用 ID，但%@。", comment: ""), appName, NSNumber(value: requiredAppIDs), availableText)
                message = prefixMessage + " " + baseMessage + "\n\n"
            }
            else
            {
                message = baseMessage + " "
            }

            let dateComponents = Calendar.current.dateComponents([.day, .hour, .minute], from: Date(), to: expirationDate)
            let dateFormatter = DateComponentsFormatter()
            dateFormatter.maximumUnitCount = 1
            dateFormatter.unitsStyle = .full

            let remainingTime = dateFormatter.string(from: dateComponents)!

            message += String(format: NSLocalizedString("你可以在 %@ 后注册另一个应用 ID。", comment: ""), remainingTime)

            return message
            
        default: return nil
        }
    }
}
