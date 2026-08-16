//
//  DeveloperOptionsView.swift
//  SideStore
//
//  Created by Magesh K on 8/2/26.
//  Copyright © 2026 SideStore. All rights reserved.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers
import WidgetKit
@preconcurrency import AltSign

private extension Color {
    static let settingsRowBackground = Color.white.opacity(0.15)
    static let settingsDivider = Color.white.opacity(0.15)
}

struct DeveloperOptionsView: View {
    @State private var responseCachingDisabled: Bool = UserDefaults.standard.responseCachingDisabled
    @State private var isVerboseOperationsLoggingEnabled: Bool = UserDefaults.standard.isVerboseOperationsLoggingEnabled
    @State private var isSideStoreVerboseLoggingEnabled: Bool = UserDefaults.standard.isSideStoreVerboseLoggingEnabled
    @State private var isAltWidgetVerboseLoggingEnabled: Bool = UserDefaults.standard.isAltWidgetVerboseLoggingEnabled
    @State private var isAltSignVerboseLoggingEnabled: Bool = UserDefaults.standard.isAltSignVerboseLoggingEnabled
    @State private var isMinimuxerVerboseLoggingEnabled: Bool = UserDefaults.standard.isMinimuxerVerboseLoggingEnabled
    @State private var isRotateLogsOnStartupEnabled: Bool = UserDefaults.standard.isRotateLogsOnStartupEnabled
    @State private var recreateDatabaseOnNextStart: Bool = UserDefaults.standard.recreateDatabaseOnNextStart
    @State private var alwaysShowWireGuardConfig: Bool = UserDefaults.standard.alwaysShowWireGuardConfig
    
    @State private var isExportingDB: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showClearRefreshAttemptsConfirmation: Bool = false
    @State private var showClearKeychainConfirmation: Bool = false
    @State private var showExportPasswordPrompt: Bool = false
    @State private var exportCertPassword: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Section 1: Logging & Diagnostics
                VStack(alignment: .leading, spacing: 8) {
                    Text("日志与诊断")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(.horizontal, 16)
                    
                    VStack(spacing: 0) {
                        toggleRow(title: "禁用 URL 响应缓存", isOn: Binding(
                            get: { responseCachingDisabled },
                            set: { newValue in
                                responseCachingDisabled = newValue
                                UserDefaults.standard.responseCachingDisabled = newValue
                            }
                        ))
                        
                        divider
                        
                        toggleRow(title: "启动时轮转日志", isOn: Binding(
                            get: { isRotateLogsOnStartupEnabled },
                            set: { newValue in
                                isRotateLogsOnStartupEnabled = newValue
                                UserDefaults.standard.isRotateLogsOnStartupEnabled = newValue
                                let suffixFormat: SuffixFormat = newValue ? .timestamp : .none
                                if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                                    appDelegate.consoleLog.updateConfiguration(baseName: "console", suffixFormat: suffixFormat, policy: .immediate)
                                }
                            }
                        ))
                        
                        divider
                        
                        toggleRow(title: "SideStore 详细日志", isOn: Binding(
                            get: { isSideStoreVerboseLoggingEnabled },
                            set: { newValue in
                                isSideStoreVerboseLoggingEnabled = newValue
                                UserDefaults.standard.isSideStoreVerboseLoggingEnabled = newValue
                                SideStoreLogging.setLogging(newValue)
                            }
                        ))
                        
                        divider
                        
                        toggleRow(title: "小组件详细日志", isOn: Binding(
                            get: { isAltWidgetVerboseLoggingEnabled },
                            set: { newValue in
                                isAltWidgetVerboseLoggingEnabled = newValue
                                UserDefaults.standard.isAltWidgetVerboseLoggingEnabled = newValue
                            }
                        ))
                        
                        divider
                        
                        toggleRow(title: "AltSign 详细日志", isOn: Binding(
                            get: { isAltSignVerboseLoggingEnabled },
                            set: { newValue in
                                isAltSignVerboseLoggingEnabled = newValue
                                UserDefaults.standard.isAltSignVerboseLoggingEnabled = newValue
                                AltSign.setLogging(newValue)
                            }
                        ))
                        
                        divider
                        
                        toggleRow(title: "Minimuxer 详细日志", isOn: Binding(
                            get: { isMinimuxerVerboseLoggingEnabled },
                            set: { newValue in
                                isMinimuxerVerboseLoggingEnabled = newValue
                                UserDefaults.standard.isMinimuxerVerboseLoggingEnabled = newValue
                                minimuxerSetLogging(newValue)
                            }
                        ))
                        
                        divider
                        
                        toggleRow(title: "操作详细日志", isOn: Binding(
                            get: { isVerboseOperationsLoggingEnabled },
                            set: { newValue in
                                isVerboseOperationsLoggingEnabled = newValue
                                UserDefaults.standard.isVerboseOperationsLoggingEnabled = newValue
                            }
                        ))
                        
                        divider
                        
                        NavigationLink(destination: OperationsLoggingControlView()) {
                            HStack {
                                Text("操作日志控制")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.white.opacity(0.4))
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                        }
                        
                        divider
                        
                        NavigationLink(destination: BonjourDiscoveryViewV2()) {
                            HStack {
                                Text("网络发现")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.white.opacity(0.4))
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                        }
                    }
                    .background(Color.settingsRowBackground)
                    .cornerRadius(14)
                }
                
                // Section: Widget Options
                VStack(alignment: .leading, spacing: 8) {
                    Text("小组件选项")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(.horizontal, 16)
                    
                    VStack(spacing: 0) {
                        SwiftUI.Button(action: { triggerReloadAllWidgets() }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("重新加载所有小组件")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                        }
                        
                        divider
                        
                        SwiftUI.Button(action: { triggerRotateWidgetLog() }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("轮转小组件日志")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                        }
                    }
                    .background(Color.settingsRowBackground)
                    .cornerRadius(14)
                }
                
                // Section 2: Database Options
                VStack(alignment: .leading, spacing: 8) {
                    Text("数据库选项")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(.horizontal, 16)
                    
                    VStack(spacing: 0) {
                        SwiftUI.Button(action: { exportDatabase() }) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("导出数据库")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                                if isExportingDB {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                        }
                        .disabled(isExportingDB)
                        
                        divider
                        
                        SwiftUI.Button(action: { showClearRefreshAttemptsConfirmation = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 1.0, green: 0.27, blue: 0.27))
                                Text("清除刷新尝试记录")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(Color(red: 1.0, green: 0.27, blue: 0.27))
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                        }
                        
                        divider
                        
                        SwiftUI.Button(action: { showDeleteConfirmation = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "trash")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 1.0, green: 0.27, blue: 0.27))
                                Text("删除数据库")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(Color(red: 1.0, green: 0.27, blue: 0.27))
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                        }
                        
                        divider
                        
                        SwiftUI.Button(action: { showClearKeychainConfirmation = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "key")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 1.0, green: 0.27, blue: 0.27))
                                Text("清除钥匙串项目")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(Color(red: 1.0, green: 0.27, blue: 0.27))
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                        }
                        
                        divider
                        
                        toggleRow(title: "下次启动时清空数据库", isOn: Binding(
                            get: { recreateDatabaseOnNextStart },
                            set: { newValue in
                                recreateDatabaseOnNextStart = newValue
                                UserDefaults.standard.recreateDatabaseOnNextStart = newValue
                            }
                        ))
                    }
                    .background(Color.settingsRowBackground)
                    .cornerRadius(14)
                }
                
                // Section 3: WireGuard Configuration
                VStack(alignment: .leading, spacing: 8) {
                    Text("WireGuard 配置")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(.horizontal, 16)
                    
                    VStack(spacing: 0) {
                        SwiftUI.Button(action: { exportWireGuardConfig() }) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("导出 WireGuard 配置")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                        }
                        
                        divider
                        
                        SwiftUI.Button(action: { triggerStartEMProxy() }) {
                            HStack(spacing: 12) {
                                Image(systemName: "play.circle")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("启动 EMProxy")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                        }
                        
                        divider
                        
                        SwiftUI.Button(action: { triggerStopEMProxy() }) {
                            HStack(spacing: 12) {
                                Image(systemName: "stop.circle")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("停止 EMProxy")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                        }
                        
                        divider
                        
                        toggleRow(title: "显示 WireGuard 设置", isOn: Binding(
                            get: { alwaysShowWireGuardConfig },
                            set: { newValue in
                                alwaysShowWireGuardConfig = newValue
                                UserDefaults.standard.alwaysShowWireGuardConfig = newValue
                            }
                        ))
                    }
                    .background(Color.settingsRowBackground)
                    .cornerRadius(14)
                }
                
                #if DEBUG
                // Section 3: Account Management
                VStack(alignment: .leading, spacing: 8) {
                    Text("账户管理")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(.horizontal, 16)
                    
                    VStack(spacing: 0) {
                        SwiftUI.Button(action: { showImportAccountPicker() }) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("导入账户 JSON")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                        }
                        
                        divider
                        
                        SwiftUI.Button(action: {
                            if AuthManager.shared.currentAppleID == nil ||
                               AuthManager.shared.password == nil ||
                               CertificateManager.shared.activeCertificate == nil {
                                if let top = topViewController() {
                                    let toastView = ToastView(text: NSLocalizedString("导出账户失败！", comment: ""), detailText: "未找到账户或缺少凭据。")
                                    toastView.show(in: top)
                                }
                            } else {
                                exportCertPassword = ""
                                showExportPasswordPrompt = true
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("导出账户 JSON")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                        }
                    }
                    .background(Color.settingsRowBackground)
                    .cornerRadius(14)
                }
                #endif
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color(uiColor: .settingsBackground).ignoresSafeArea())
        .navigationTitle("开发者选项")
        .navigationBarTitleDisplayMode(.large)
        .alert("删除数据库", isPresented: $showDeleteConfirmation) {
            SwiftUI.Button("删除并退出", role: .destructive) {
                _ = DatabaseManager.deleteDatabase()
                exit(0)
            }
            SwiftUI.Button("取消", role: .cancel) {}
        } message: {
            Text("删除数据库将移除 SideStore 中的所有应用条目和源。")
        }
        .alert("清除刷新尝试记录", isPresented: $showClearRefreshAttemptsConfirmation) {
            SwiftUI.Button("清除", role: .destructive) {
                clearRefreshAttempts()
            }
            SwiftUI.Button("取消", role: .cancel) {}
        } message: {
            Text("你确定要清除所有现有的刷新尝试记录吗？")
        }
        #if DEBUG
        .alert("导出账户", isPresented: $showExportPasswordPrompt) {
            SecureField("证书密码", text: $exportCertPassword)
            SwiftUI.Button("导出") {
                exportAccountJSON(password: exportCertPassword)
            }
            SwiftUI.Button("取消", role: .cancel) {}
        } message: {
            Text("请输入证书密码。")
        }
        #endif
        .alert("清除钥匙串项目", isPresented: $showClearKeychainConfirmation) {
            SwiftUI.Button("全部清除", role: .destructive) {
                Keychain.shared.clearAll()
            }
            SwiftUI.Button("取消", role: .cancel) {}
        } message: {
            Text("是否要清除与此 SideStore 实例相关的所有钥匙串项目？")
        }
    }
    
    private func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }),
              var top = window.rootViewController else {
            return nil
        }
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
    
    #if DEBUG
    private func showImportAccountPicker() {
        guard let top = topViewController() else { return }
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType(filenameExtension: "sideconf")!, .json], asCopy: false)
        ImportExport.documentPickerHandler = DocumentPickerHandler { selectedURL in
            guard let url = selectedURL else { return }
            do {
                try ImportExport.importAccountJSON(from: url)
                let email = AuthManager.shared.currentAppleID ?? ""
                let toastView = ToastView(text: NSLocalizedString("成功导入“\(email)”！", comment: ""), detailText: "SideStore 应该已完全可用！")
                toastView.show(in: top)
            } catch {
                let toastView = ToastView(text: NSLocalizedString("导入账户 JSON 失败！", comment: ""), detailText: error.localizedDescription)
                toastView.show(in: top)
            }
        }
        picker.delegate = ImportExport.documentPickerHandler
        top.present(picker, animated: true)
    }
    
    private func exportAccountJSON(password: String) {
        guard let top = topViewController() else { return }
        guard let account = ImportExport.exportAccountJSON(password: password) else {
            let toastView = ToastView(text: NSLocalizedString("导出账户失败！", comment: ""), detailText: "未找到账户或缺少凭据。")
            toastView.show(in: top)
            return
        }
        
        guard let accountData = try? Foundation.JSONEncoder().encode(account) else {
            let toastView = ToastView(text: NSLocalizedString("导出账户数据失败！", comment: ""), detailText: "账户数据格式错误。")
            toastView.show(in: top)
            return
        }
        
        let tmpPath = FileManager.default.temporaryDirectory.appendingPathComponent("\(account.email).sideconf")
        do {
            try accountData.write(to: tmpPath)
            let exportVC = UIDocumentPickerViewController(forExporting: [tmpPath], asCopy: false)
            top.present(exportVC, animated: true)
        } catch {
            let toastView = ToastView(text: NSLocalizedString("导出账户失败！", comment: ""), detailText: error.localizedDescription)
            toastView.show(in: top)
        }
    }
    #endif
    
    private func clearRefreshAttempts() {
        let context = DatabaseManager.shared.persistentContainer.newBackgroundContext()
        context.perform {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = RefreshAttempt.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            _ = try? context.execute(deleteRequest)
            try? context.save()
        }
    }
    
    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 50)
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Color.settingsDivider)
            .frame(height: 0.5)
            .padding(.horizontal, 16)
    }
    
    private func exportDatabase() {
        guard !isExportingDB else { return }
        isExportingDB = true
        
        Task {
            do {
                let exportedURL = try await CoreDataHelper.exportCoreDataStore()
                debugLog("[DeveloperOptionsView] ExportedURL: \(exportedURL)")
                await MainActor.run {
                    isExportingDB = false
                }
            } catch {
                debugLog("[DeveloperOptionsView] Export error: \(error)")
                await MainActor.run {
                    isExportingDB = false
                }
            }
        }
    }
    
    private func exportWireGuardConfig() {
        guard let top = topViewController() else { return }
        guard let url = Bundle.main.url(forResource: "SideStore", withExtension: "conf") else {
            let toastView = ToastView(text: NSLocalizedString("SideStore.conf 缺失！", comment: ""), detailText: "无法在 bundle 资源中找到 SideStore.conf。")
            toastView.show(in: top)
            return
        }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        top.present(activityVC, animated: true)
    }
    
    private func triggerStartEMProxy() {
        guard let top = topViewController() else { return }
        Task {
            do {
                try await startEMProxy()
                await MainActor.run {
                    let toastView = ToastView(text: NSLocalizedString("EMProxy 已启动", comment: ""), detailText: "EMProxy 回环服务器正在运行。")
                    toastView.show(in: top)
                }
            } catch {
                await MainActor.run {
                    let toastView = ToastView(text: NSLocalizedString("启动 EMProxy 失败！", comment: ""), detailText: error.localizedDescription)
                    toastView.show(in: top)
                }
            }
        }
    }
    
    private func triggerStopEMProxy() {
        guard let top = topViewController() else { return }
        Task {
            do {
                try await stopEMProxy()
                await MainActor.run {
                    let toastView = ToastView(text: NSLocalizedString("EMProxy 已停止", comment: ""), detailText: "EMProxy 回环服务器已停止。")
                    toastView.show(in: top)
                }
            } catch {
                await MainActor.run {
                    let toastView = ToastView(text: NSLocalizedString("停止 EMProxy 失败！", comment: ""), detailText: error.localizedDescription)
                    toastView.show(in: top)
                }
            }
        }
    }
    
    private func triggerReloadAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        if let top = topViewController() {
            let toastView = ToastView(text: NSLocalizedString("已重新加载所有小组件", comment: ""), detailText: "已触发所有小组件的时间线刷新。")
            toastView.show(in: top)
        }
    }
    
    private func triggerRotateWidgetLog() {
        guard let top = topViewController() else { return }
        do {
            if let rotatedURL = try WidgetLogManager.rotateLog() {
                let toastView = ToastView(text: NSLocalizedString("小组件日志已轮转", comment: ""), detailText: "已保存到 WidgetLogs/\(rotatedURL.lastPathComponent)")
                toastView.show(in: top)
            } else {
                let toastView = ToastView(text: NSLocalizedString("小组件日志为空", comment: ""), detailText: "没有可轮转的内容。")
                toastView.show(in: top)
            }
        } catch {
            let toastView = ToastView(text: NSLocalizedString("轮转日志失败", comment: ""), detailText: error.localizedDescription)
            toastView.show(in: top)
        }
    }
}
