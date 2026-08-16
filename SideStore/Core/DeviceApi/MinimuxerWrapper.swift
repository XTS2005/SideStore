//
//  MinimuxerWrapper.swift
//
//  Created by Magesh K on 22/02/26.
//  Copyright © 2026 SideStore. All rights reserved.
//

import Foundation
import Minimuxer
import Combine

public var minimuxerStatusPublisher: AnyPublisher<Result<Bool, Error>, Never> {
    Minimuxer.shared.statusPublisher
        .map { result in
            result.mapError { $0 as Error }
        }
        .eraseToAnyPublisher()
}

func bindConnectionConfig() async {
    defer { debugLog("[SideStore] bindTunnelConfig() completed") }

    debugLog("[SideStore] bindTunnelConfig() invoked")
    let config = ConnectionConfig.shared
    let configBinding = ConnectionConfigBinding(
        setTunnelIfaceIp: { value in Task { @MainActor in config.tunnelIfaceIp = value } },
        setTunnelPeerIp: { value in Task { @MainActor in config.tunnelPeerIp = value } },
        setTunnelPeerReachable: { value in Task { @MainActor in config.tunnelPeerReachable = value } },
        setTunnelIfaceSubnetMask: { value in Task { @MainActor in config.tunnelIfaceSubnetMask = value } },
        getRemoteServerIp: { config.remoteServerIp },
        setRemoteReachable: { value in Task { @MainActor in config.remoteReachable = value } },
        getOverrideTunnelPeerIp: { config.overrideTunnelPeerIp },
        setOverrideTunnelPeerReachable: { value in Task { @MainActor in config.overrideTunnelPeerReachable = value } },
        getConnectionMode: { config.useLocalVPN ? .localVPN : .remoteServer }
    )
    await Minimuxer.shared.bindConnectionConfig(configBinding)
}

func getDeviceConnectionMode() async -> DeviceConnectionMode {
    return await Minimuxer.shared.getConnectionMode()
}

enum MinimuxerStatus: Equatable {
    case ready
    case noDevice(String?)
    case noConnection(String?)
    case notReachable(String)
    case noVPN(String?)
    case invalidVPN(String?)
    case invalidPairing(String?)
    case notStarted(String?)
    case pairingNotLoaded(String?)
    case unknown
    
    init(from error: MinimuxerError) {
        switch error {
        case .noVPN(let reason):                    self = .noVPN(reason)
        case .invalidVPN(let reason):               self = .invalidVPN(reason)
        case .invalidPairing(_, let reason):        self = .invalidPairing(reason)
        case .noDevice(let reason):                 self = .noDevice(reason)
        case .noConnection(let reason):             self = .noConnection(reason)
        case .notReachable(let reason):             self = .notReachable(reason)
        case .notStarted(let reason):               self = .notStarted(reason)
        case .pairingNotLoaded(let reason):         self = .pairingNotLoaded(reason)
        default:                                    self = .unknown
        }
    }
    
    var operationError: OperationError? {
        switch self {
        case .unknown, .ready:                  return nil
        case .noDevice(let reason):             return .noDevice(reason: reason)
        case .noConnection(let reason):         return .noConnection(reason: reason)
        case .notReachable(let reason):         return .notReachable(reason: reason)
        case .noVPN(let reason):                return .noVPN(reason: reason)
        case .invalidVPN(let reason):           return .invalidVPN(reason: reason)
        case .invalidPairing(let reason):       return .invalidPairingFile(reason: reason)
        case .notStarted(let reason):           return .minimuxerNotStarted(reason: reason)
        case .pairingNotLoaded(let reason):     return .pairingNotComplete(reason: reason)
        }
    }

    static func from(_ result: Result<Bool, Error>) -> MinimuxerStatus {
        switch result {
        case .success:
            return .ready
        case .failure(let error):
            guard let error = error as? MinimuxerError else { return .unknown }
            return MinimuxerStatus(from: error)
        }
    }
}

func getMinimuxerStatus() async -> MinimuxerStatus {
    // #if targetEnvironment(simulator)
    // debugLog("[SideStore] getMinimuxerStatus() = .ready on simulator")
    // return .ready
    // #endif
    let result = await Minimuxer.shared.isReady()
    return MinimuxerStatus.from(result.mapError { $0 as Error })
}

func reinitializePairingData(_ pairingFile: String) async throws {
    defer { debugLog("[SideStore] reinitializePairingData(pairingFile) completed") }
    #if targetEnvironment(simulator)
    debugLog("[SideStore] reinitializePairingData(pairingFile) is no-op on simulator")
    #else
    debugLog("[SideStore] reinitializePairingData(pairingFile) invoked")
    try await Minimuxer.shared.reinitializePairingData(pairingFile: pairingFile)
    #endif
}

func minimuxerStart(_ pairingFile: String, mountPath: String) async throws {
    defer { debugLog("[SideStore] minimuxerStart(pairingFile) completed") }
    #if targetEnvironment(simulator)
    debugLog("[SideStore] minimuxerStart(pairingFile) is no-op on simulator")
    await bindConnectionConfig()
    await Minimuxer.network.start()
    #else
    await bindConnectionConfig()
    debugLog("[SideStore] minimuxerStart(pairingFile) invoked")
    try await Minimuxer.shared.start(pairingFile: pairingFile, mountPath: mountPath)
    #endif
}


func reinitializePairingData(pairingFile: String) async throws {
    defer { debugLog("[SideStore] reinitializePairingData(pairingFile) completed") }
    #if targetEnvironment(simulator)
    debugLog("[SideStore] reinitializePairingData(pairingFile) is no-op on simulator")
    #else
    debugLog("[SideStore] reinitializePairingData(pairingFile) invoked")
    try await Minimuxer.shared.reinitializePairingData(pairingFile: pairingFile)
    #endif
}

func installProvisioningProfiles(_ profileData: Data) async throws {
    defer { debugLog("[SideStore] installProvisioningProfiles(profileData) completed") }
    #if targetEnvironment(simulator)
    debugLog("[SideStore] installProvisioningProfiles(profileData) is no-op on simulator")
    #else
    debugLog("[SideStore] installProvisioningProfiles(profileData) invoked")
    try await Minimuxer.shared.installProvisioningProfile(profile: profileData)
    #endif
}

func removeProvisioningProfile(_ id: String) async throws {
    defer { debugLog("[SideStore] removeProvisioningProfile(id) completed") }
    #if targetEnvironment(simulator)
    debugLog("[SideStore] removeProvisioningProfile(id) is no-op on simulator")
    #else
    debugLog("[SideStore] removeProvisioningProfile(id) invoked")
    try await Minimuxer.shared.removeProvisioningProfile(id: id)
    #endif
}

func removeApp(_ bundleId: String) async throws {
    defer { debugLog("[SideStore] removeApp(bundleId) completed") }
    #if targetEnvironment(simulator)
    debugLog("[SideStore] removeApp(bundleId) is no-op on simulator")
    #else
    debugLog("[SideStore] removeApp(bundleId) invoked")
    try await Minimuxer.shared.removeApp(bundleId: bundleId)
    #endif
}

func yeetAppAFC(_ bundleId: String, _ rawBytes: Data) async throws {
    defer { debugLog("[SideStore] yeetAppAFC(bundleId, rawBytes) completed") }
    #if targetEnvironment(simulator)
    debugLog("[SideStore] yeetAppAFC(bundleId, rawBytes) is no-op on simulator")
    #else
    debugLog("[SideStore] yeetAppAFC(bundleId, rawBytes) invoked")
    try await Minimuxer.shared.yeetAppAfc(bundleId: bundleId, ipaBytes: rawBytes)
    #endif
}

func installIPA(_ bundleId: String) async throws {
    defer { debugLog("[SideStore] installIPA(bundleId) completed") }
    #if targetEnvironment(simulator)
    debugLog("[SideStore] installIPA(bundleId) is no-op on simulator")
    #else
    debugLog("[SideStore] installIPA(bundleId) invoked")
    try await Minimuxer.shared.installIpa(bundleId: bundleId)
    #endif
}

@discardableResult
func fetchUDID(useStatic: Bool = false) async throws -> String? {
    defer { debugLog("[SideStore] fetchUDID() completed") }
    #if targetEnvironment(simulator)
    debugLog("[SideStore] fetchUDID() is no-op on simulator")
    return "XXXXX-XXXX-XXXXX-XXXX"
    #else
    debugLog("[SideStore] fetchUDID() invoked")
    if let udid = try? await Minimuxer.shared.fetchUDID(), !udid.isEmpty, udid != "XXXXX-XXXX-XXXXX-XXXX" {
        return udid
    }
    if useStatic {
        return PairingFileManager.shared.pairingUDID
    }
    return nil
    #endif
}

func debugApp(_ appId: String) async throws {
    defer { debugLog("[SideStore] debugApp(appId) completed") }
    #if targetEnvironment(simulator)
    debugLog("[SideStore] debugApp(appId) is no-op on simulator")
    #else
    debugLog("[SideStore] debugApp(appId) invoked")
    try await Minimuxer.shared.debugApp(appId: appId)
    #endif
}

func attachDebugger(_ pid: UInt32) async throws {
    defer { debugLog("[SideStore] attachDebugger(pid) completed") }
    #if targetEnvironment(simulator)
    debugLog("[SideStore] attachDebugger(pid) is no-op on simulator")
    #else
    debugLog("[SideStore] attachDebugger(pid) invoked")
    try await Minimuxer.shared.attachDebugger(pid: pid)
    #endif
}


func dumpProfiles(_ docsPath: String) async throws -> String {
    defer { debugLog("[SideStore] dumpProfiles(docsPath) completed") }
    #if targetEnvironment(simulator)
    debugLog("[SideStore] dumpProfiles(docsPath) is no-op on simulator")
    return ""
    #else
    debugLog("[SideStore] dumpProfiles(docsPath) invoked")
    return try await Minimuxer.shared.dumpProfiles(docsPath: docsPath)
    #endif
}

func minimuxerSetLogging(_ enabled: Bool) {
    defer { debugLog("[SideStore] minimuxerSetLogging(enabled) completed") }
    debugLog("[SideStore] minimuxerSetLogging(enabled) invoked")
    #if !targetEnvironment(simulator)
    Minimuxer.shared.setLogging(enabled)
    #endif
}

extension Result {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

extension MinimuxerError {
    public var failureReason: String? {
        switch self {
        case .noDevice:
            return NSLocalizedString("无法从 muxer 获取设备", comment: "")
        case .noConnection:
            return NSLocalizedString("你似乎没有连接到 Wi-Fi 或有线网络！请连接到 Wi-Fi 或有线连接。", comment: "")
        case .notReachable(let reason):
            return NSLocalizedString(reason, comment: "")
        case .connectionModeNotConfigured(let reason):
            return NSLocalizedString(reason, comment: "")
        case .noVPN(let reason):
            return String(format: NSLocalizedString("无法通过 %@ VPN 连接到设备。请确保 LocalDevVPN 已启用并正在运行！原因：%@", comment: ""), "LocalDev", reason)
        case .invalidPairing(let proto, let reason):
            return String(format: NSLocalizedString("配对文件无效（%@ 协议）：%@。请使用 iloader 替换它。", comment: ""), proto.description, reason)
        case .createDebug:
            return createService(name: "debug")
        case .lookupApps:
            return getFromDevice(name: "installed apps")
        case .findApp:
            return getFromDevice(name: "path to the app")
        case .bundlePath:
            return getFromDevice(name: "bundle path")
        case .maxPacket:
            return setArgument(name: "max packet")
        case .workingDirectory:
            return setArgument(name: "working directory")
        case .argv:
            return setArgument(name: "argv")
        case .launchSuccess:
            return getFromDevice(name: "launch success")
        case .detach:
            return NSLocalizedString("无法从应用的进程中分离", comment: "")
        case .attach:
            return NSLocalizedString("无法附加到应用的进程", comment: "")
        case .createInstproxy:
            return createService(name: "instproxy")
        case .createAfc:
            return createService(name: "AFC")
        case .rwAfc:
            return NSLocalizedString("AFC 无法管理设备上的文件。", comment: "")
        case .installApp(let message):
            return NSLocalizedString("无法安装应用：\(message)", comment: "")
        case .uninstallApp:
            return NSLocalizedString("无法卸载应用", comment: "")
        case .createMisagent:
            return createService(name: "misagent")
        case .profileInstall:
            return NSLocalizedString("无法管理设备上的描述文件", comment: "")
        case .profileRemove:
            return NSLocalizedString("无法管理设备上的描述文件", comment: "")
        case .createLockdown:
            return NSLocalizedString("无法连接到 lockdown", comment: "")
        case .createCoreDevice:
            return NSLocalizedString("无法连接到核心设备代理", comment: "")
        case .createSoftwareTunnel:
            return NSLocalizedString("无法创建软件隧道", comment: "")
        case .createRemoteServer:
            return NSLocalizedString("无法连接到远程服务器", comment: "")
        case .createProcessControl:
            return NSLocalizedString("无法连接到进程控制", comment: "")
        case .getLockdownValue:
            return NSLocalizedString("无法从 lockdown 获取值", comment: "")
        case .connect:
            return NSLocalizedString("无法连接到 TCP 端口", comment: "")
        case .close:
            return NSLocalizedString("无法关闭 TCP 端口", comment: "")
        case .xpcHandshake:
            return NSLocalizedString("无法从 XPC 获取服务", comment: "")
        case .noService:
            return NSLocalizedString("设备中不包含该服务", comment: "")
        case .invalidProductVersion:
            return NSLocalizedString("服务版本的格式不符合预期", comment: "")
        case .createFolder:
            return NSLocalizedString("无法创建 DDI 文件夹", comment: "")
        case .downloadImage:
            return NSLocalizedString("无法下载 DDI", comment: "")
        case .imageLookup:
            return NSLocalizedString("无法查找 DDI 映像", comment: "")
        case .imageRead:
            return NSLocalizedString("无法将映像读取到内存", comment: "")
        case .mount(let proto, let reason):
            return String(format: NSLocalizedString("挂载失败（%@ 协议）：%@", comment: ""), proto.description, reason)
        case .restartAlreadyInProgressError:
            return NSLocalizedString("重启已在进行中", comment: "")
        case .invalidVPN:
            return NSLocalizedString("无效的 VPN 配置", comment: "")
        case .muxerNotListening:
            return NSLocalizedString("Usbmuxd 服务器未在设备上监听", comment: "")
        case .notStarted(let reason):
            return String(format: NSLocalizedString("Minimuxer 尚未启动：%@", comment: ""), reason)
        case .pairingNotLoaded(let reason):
            return String(format: NSLocalizedString("未加载配对文件：%@", comment: ""), reason)
        }
    }

    fileprivate func createService(name: String) -> String {
        String(format: NSLocalizedString("无法在设备上启动 %@ 服务器。", comment: ""), name)
    }

    fileprivate func getFromDevice(name: String) -> String {
        String(format: NSLocalizedString("无法从设备获取 %@。", comment: ""), name)
    }

    fileprivate func setArgument(name: String) -> String {
        String(format: NSLocalizedString("无法在设备上设置 %@。", comment: ""), name)
    }
}

public enum MinimuxerWrapperError: Error, LocalizedError {
    case profileInstall
    case restartAlreadyInProgress
    case pairingFile
    
    public var errorDescription: String? {
        switch self {
        case .profileInstall:
            return NSLocalizedString("无法管理设备上的描述文件", comment: "")
        case .restartAlreadyInProgress:
            return NSLocalizedString("重启已在进行中", comment: "")
        case .pairingFile:
            return NSLocalizedString("配对文件无效。你的配对文件要么没有 UDID，要么不是有效的 plist。请使用 iloader 替换它。", comment: "")
        }
    }

    public var failureReason: String? {
        return errorDescription
    }
}

extension Error {
    public var isMinimuxerNoConnection: Bool {
        if let minimuxerErr = self as? MinimuxerError,
           case .noConnection = minimuxerErr { return true }
        return false
    }
    public var isMinimuxerNotReachable: Bool {
        if let minimuxerErr = self as? MinimuxerError,
           case .notReachable = minimuxerErr { return true }
        return false
    }
    public var isMinimuxerNoVPN: Bool {
        if let minimuxerErr = self as? MinimuxerError,
           case .noVPN = minimuxerErr { return true }
        return false
    }
    public var isMinimuxerProfileInstall: Bool {
        if let minimuxerErr = self as? MinimuxerError,
           case .profileInstall = minimuxerErr { return true }
        return (self as? MinimuxerWrapperError) == .profileInstall
    }
    public var isMinimuxerPairingFile: Bool {
        if let minimuxerErr = self as? MinimuxerError,
           case .invalidPairing = minimuxerErr { return true }
        return (self as? MinimuxerWrapperError) == .pairingFile
    }
    public var isMinimuxerRestartInProgress: Bool {
        if let minimuxerErr = self as? MinimuxerError,
           case .restartAlreadyInProgressError = minimuxerErr { return true }
        return (self as? MinimuxerWrapperError) == .restartAlreadyInProgress
    }
    public var isMinimuxerNotStarted: Bool {
        if let minimuxerErr = self as? MinimuxerError,
           case .notStarted = minimuxerErr { return true }
        return false
    }
}

func minimuxerRestart() async throws {
    #if !targetEnvironment(simulator)
    try await Minimuxer.shared.restart()
    #endif
}

public struct MinimuxerPairedDevice: Codable, Sendable {
    public let name: String
    public let model: String
    public let udid: String
    public let pairingFilePath: String
    
    public init(name: String, model: String, udid: String, pairingFilePath: String) {
        self.name = name
        self.model = model
        self.udid = udid
        self.pairingFilePath = pairingFilePath
    }
}

@MainActor
public final class WirelessPairWrapper {
    public static let shared = WirelessPairWrapper()
    
    private init() {}
    
    public var onPinReceived: ((String) -> Void)? {
        get {
            #if !targetEnvironment(simulator)
            return Minimuxer.wirelessPair.onPinReceived
            #else
            return nil
            #endif
        }
        set {
            #if !targetEnvironment(simulator)
            Minimuxer.wirelessPair.onPinReceived = newValue
            #endif
        }
    }
    
    public var onReadyToPair: ((String, Int) -> Void)? {
        get {
            #if !targetEnvironment(simulator)
            return Minimuxer.wirelessPair.onReadyToPair
            #else
            return nil
            #endif
        }
        set {
            #if !targetEnvironment(simulator)
            Minimuxer.wirelessPair.onReadyToPair = newValue
            #endif
        }
    }
    
    public func start(
        outPath: String,
        completion: @escaping (Result<MinimuxerPairedDevice, Error>) -> Void
    ) {
        #if !targetEnvironment(simulator)
        Minimuxer.wirelessPair.start(outPath: outPath) { result in
            switch result {
            case .success(let device):
                completion(.success(MinimuxerPairedDevice(
                    name: device.name,
                    model: device.model,
                    udid: device.udid,
                    pairingFilePath: device.pairingFilePath
                )))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        #else
        completion(.failure(MinimuxerWrapperError.pairingFile))
        #endif
    }
    
    public func stop() {
        #if !targetEnvironment(simulator)
        Minimuxer.wirelessPair.stop()
        #endif
    }
}

@MainActor
let wirelessPairing = WirelessPairWrapper.shared
