//  AnisetteDataView.swift
//  SideStore
//
//  Created by Magesh K on 31/7/26.
//  Copyright © 2026 SideStore. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

@MainActor
class AnisetteDataViewModel: ObservableObject {
    @Published var clientInfo: String = ""
    @Published var userAgent: String = ""
    @Published var customDeviceID: String = ""
    @Published var customLocalUserID: String = ""
    @Published var customLocale: String = ""
    @Published var customTimeZone: String = ""
    
    @Published var isOfflineMode: Bool = false
    @Published var isLoading: Bool = false
    
    @Published var viewMode: Int = 0 // 0 = Interactive, 1 = Raw JSON
    @Published var rawEditableJSON: String = ""
    @Published var serverReturnedHeadersJSON: String = "{}"
    
    init() {
        Task {
            await loadData()
        }
    }
    
    func loadData() async {
        isOfflineMode = AnisetteConfigManager.shared.isOfflineMode
        let config = await AnisetteConfigManager.shared.loadConfig()
        clientInfo = config.clientInfo
        userAgent = config.userAgent
        customDeviceID = config.customDeviceID ?? ""
        customLocalUserID = config.customLocalUserID ?? ""
        customLocale = config.customLocale ?? ""
        customTimeZone = config.customTimeZone ?? ""
        
        updateRawEditableJSON()
        
        let serverHeaders = await AnisetteConfigManager.shared.loadServerHeaders()
        if let data = try? JSONSerialization.data(withJSONObject: serverHeaders, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]),
           let str = String(data: data, encoding: .utf8) {
            serverReturnedHeadersJSON = str
        }
    }
    
    func updateRawEditableJSON() {
        var dict: [String: String] = [
            "clientInfo": clientInfo,
            "userAgent": userAgent
        ]
        if !customDeviceID.isEmpty { dict["customDeviceID"] = customDeviceID }
        if !customLocalUserID.isEmpty { dict["customLocalUserID"] = customLocalUserID }
        if !customLocale.isEmpty { dict["customLocale"] = customLocale }
        if !customTimeZone.isEmpty { dict["customTimeZone"] = customTimeZone }
        
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]),
           let str = String(data: data, encoding: .utf8) {
            rawEditableJSON = str
        }
    }
    
    func save() async {
        AnisetteConfigManager.shared.isOfflineMode = isOfflineMode
        let config = AnisetteConfig(
            clientInfo: clientInfo,
            userAgent: userAgent,
            customDeviceID: customDeviceID.isEmpty ? nil : customDeviceID,
            customLocalUserID: customLocalUserID.isEmpty ? nil : customLocalUserID,
            customLocale: customLocale.isEmpty ? nil : customLocale,
            customTimeZone: customTimeZone.isEmpty ? nil : customTimeZone
        )
        await AnisetteConfigManager.shared.saveConfig(config)
        updateRawEditableJSON()
        showToast(text: "配置保存成功。")
    }
    
    func saveRawJSON() async {
        guard let data = rawEditableJSON.data(using: .utf8) else {
            showToast(text: "编码失败", detailText: "无法将 JSON 编码为 UTF-8。")
            return
        }
        
        do {
            let config = try Foundation.JSONDecoder().decode(AnisetteConfig.self, from: data)
            
            clientInfo = config.clientInfo
            userAgent = config.userAgent
            customDeviceID = config.customDeviceID ?? ""
            customLocalUserID = config.customLocalUserID ?? ""
            customLocale = config.customLocale ?? ""
            customTimeZone = config.customTimeZone ?? ""
            
            await AnisetteConfigManager.shared.saveConfig(config)
            showToast(text: "JSON 配置保存成功！")
        } catch {
            showToast(text: "JSON 结构无效", error: error)
        }
    }
    
    func reset() async {
        let config = await AnisetteConfigManager.shared.resetToDefaults()
        clientInfo = config.clientInfo
        userAgent = config.userAgent
        customDeviceID = ""
        customLocalUserID = ""
        customLocale = ""
        customTimeZone = ""
        updateRawEditableJSON()
        await save()
        showToast(text: "已重置为默认配置。")
    }
    
    func importJSON(url: URL) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let gotAccess = url.startAccessingSecurityScopedResource()
            defer {
                if gotAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            let config = try await AnisetteConfigManager.shared.importFromFile(url: url)
            clientInfo = config.clientInfo
            userAgent = config.userAgent
            customDeviceID = config.customDeviceID ?? ""
            customLocalUserID = config.customLocalUserID ?? ""
            customLocale = config.customLocale ?? ""
            customTimeZone = config.customTimeZone ?? ""
            updateRawEditableJSON()
            showToast(text: "导入成功", detailText: url.lastPathComponent)
        } catch {
            showToast(text: "导入失败", error: error)
        }
    }
    
    func exportJSON() async -> URL? {
        guard let data = await AnisetteConfigManager.shared.exportConfigData() else { return nil }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("anisette-config.json")
        do {
            try data.write(to: tempURL, options: .atomic)
            return tempURL
        } catch {
            showToast(text: "导出失败", error: error)
            return nil
        }
    }
    
    func fetchFreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let activeServer = UserDefaults.standard.menuAnisetteURL
            guard !activeServer.isEmpty, let url = URL(string: activeServer) else {
                throw NSError(domain: "AnisetteDataViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "未配置有效的 anisette 服务器 URL。"])
            }
            
            let clientInfoURL = url.appendingPathComponent("v3").appendingPathComponent("client_info")
            var request = URLRequest(url: clientInfoURL)
            request.timeoutInterval = 10
            
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: String] else {
                throw NSError(domain: "AnisetteDataViewModel", code: -2, userInfo: [NSLocalizedDescriptionKey: "服务器响应不是有效的 JSON。"])
            }
            
            // Save the server returned headers
            await AnisetteConfigManager.shared.saveServerHeaders(json)
            
            // Refresh the server headers display
            let serverHeaders = await AnisetteConfigManager.shared.loadServerHeaders()
            if let data = try? JSONSerialization.data(withJSONObject: serverHeaders, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]),
               let str = String(data: data, encoding: .utf8) {
                serverReturnedHeadersJSON = str
            }
            
            showToast(text: "已获取服务器配置！", detailText: url.host)
        } catch {
            showToast(text: "获取失败", error: error)
        }
    }
    
    func loadServerHeadersIntoOverrides() async {
        let serverHeaders = await AnisetteConfigManager.shared.loadServerHeaders()
        guard !serverHeaders.isEmpty else {
            showToast(text: "未找到获取的标头", detailText: "请先从服务器获取。")
            return
        }
        
        // Casing helper to lookup keys flexibly in both camelCase and snake_case
        func getValue(forKeys keys: [String]) -> String? {
            for key in keys {
                if let val = serverHeaders[key] {
                    return val
                }
            }
            return nil
        }
        
        if let val = getValue(forKeys: ["client_info", "clientInfo", "X-Mme-Client-Info"]) {
            clientInfo = val
        }
        if let val = getValue(forKeys: ["user_agent", "userAgent", "User-Agent"]) {
            userAgent = val
        }
        if let val = getValue(forKeys: ["custom_device_id", "customDeviceID", "X-Mme-Device-Id", "deviceUniqueIdentifier"]) {
            customDeviceID = val
        }
        if let val = getValue(forKeys: ["custom_local_user_id", "customLocalUserID", "X-Apple-I-MD-LU", "localUserID"]) {
            customLocalUserID = val
        }
        if let val = getValue(forKeys: ["custom_locale", "customLocale", "X-Apple-Locale", "locale"]) {
            customLocale = val
        }
        if let val = getValue(forKeys: ["custom_time_zone", "customTimeZone", "X-Apple-I-TimeZone", "timeZone"]) {
            customTimeZone = val
        }
        
        // Save and update
        await save()
        showToast(text: "已将获取的数据加载到覆盖项中！")
    }
    
    func showToast(text: String, detailText: String? = nil, error: Error? = nil) {
        let toast: ToastView
        if let error = error {
            toast = ToastView(error: error, opensLog: true)
        } else {
            toast = ToastView(text: text, detailText: detailText)
        }
        
        let keyWindow = UIApplication.shared.alt_keyWindow
        if let rootVC = keyWindow?.rootViewController {
            let presentingVC = rootVC.presentedViewController ?? rootVC
            toast.show(in: presentingVC)
        }
    }
}

struct AnisetteDataView: View {
    @StateObject private var viewModel = AnisetteDataViewModel()
    @State private var showingResetAlert = false
    @State private var showingFileImporter = false
    @State private var showingShareSheet = false
    @State private var exportFileURL: URL? = nil
    @State private var isCopiedServer = false
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("视图模式", selection: $viewModel.viewMode) {
                Text("交互式").tag(0)
                Text("原始 JSON").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color(.systemGroupedBackground))
            
            List {
                // Section 1: Operational Mode
                Section {
                    Toggle(isOn: $viewModel.isOfflineMode) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("使用离线配置文件")
                                .font(.body)
                            Text("跳过从服务器获取客户端信息")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: viewModel.isOfflineMode) { _ in
                        Task {
                            await viewModel.save()
                        }
                    }
                } header: {
                    Text("运行模式")
                } footer: {
                    Text("启用后，SideStore 将使用本地保存的 JSON 配置参数生成所有身份验证标头，而不会向服务器发起 client_info 请求。")
                }
                
                if viewModel.viewMode == 0 {
                    // SECTION 2: INTERACTIVE CUSTOMIZATION
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("客户端信息（X-Mme-Client-Info）")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $viewModel.clientInfo)
                                .font(.system(.caption, design: .monospaced))
                                .frame(minHeight: 80)
                                .padding(4)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(6)
                        }
                        .padding(.vertical, 4)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("用户代理")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $viewModel.userAgent)
                                .font(.system(.caption, design: .monospaced))
                                .frame(minHeight: 80)
                                .padding(4)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(6)
                        }
                        .padding(.vertical, 4)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("设备 ID 覆盖（可选）")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                            
                            TextField("系统生成", text: $viewModel.customDeviceID)
                                .font(.system(.caption, design: .monospaced))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(8)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(6)
                        }
                        .padding(.vertical, 4)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("本地用户 ID 覆盖（可选）")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                            
                            TextField("系统生成", text: $viewModel.customLocalUserID)
                                .font(.system(.caption, design: .monospaced))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(8)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(6)
                        }
                        .padding(.vertical, 4)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("区域设置覆盖（可选）")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                            
                            TextField("例如 en_US", text: $viewModel.customLocale)
                                .font(.system(.caption, design: .monospaced))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(8)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(6)
                        }
                        .padding(.vertical, 4)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("时区覆盖（可选）")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                            
                            TextField("例如 UTC、GMT", text: $viewModel.customTimeZone)
                                .font(.system(.caption, design: .monospaced))
                                .autocapitalization(.allCharacters)
                                .disableAutocorrection(true)
                                .padding(8)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(6)
                        }
                        .padding(.vertical, 4)
                        
                        SwiftUI.Button {
                            Task {
                                await viewModel.save()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text("保存覆盖项")
                                    .font(.headline)
                                Spacer()
                            }
                        }
                        .disabled(viewModel.clientInfo.isEmpty || viewModel.userAgent.isEmpty)
                    } header: {
                        Text("自定义参数")
                    }
                } else {
                    // SECTION 3: RAW JSON VIEW
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("配置 JSON（可编辑）")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $viewModel.rawEditableJSON)
                                .font(.system(.caption, design: .monospaced))
                                .frame(minHeight: 300)
                                .padding(4)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(6)
                        }
                        .padding(.vertical, 4)
                        
                        SwiftUI.Button {
                            Task {
                                await viewModel.saveRawJSON()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text("保存原始 JSON")
                                    .font(.headline)
                                Spacer()
                            }
                        }
                        .disabled(viewModel.rawEditableJSON.isEmpty)
                    } header: {
                        Text("原始配置 JSON")
                    }
                }
                
                // SECTION 4: SERVER RETURNED HEADERS (READ-ONLY)
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("上次服务器响应 JSON")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            SwiftUI.Button {
                                UIPasteboard.general.string = viewModel.serverReturnedHeadersJSON
                                withAnimation {
                                    isCopiedServer = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        isCopiedServer = false
                                    }
                                }
                            } label: {
                                Image(systemName: isCopiedServer ? "checkmark" : "doc.on.doc")
                                    .font(.footnote)
                                    .foregroundColor(isCopiedServer ? .green : .accentColor)
                            }
                        }
                        
                        ScrollView(.horizontal, showsIndicators: true) {
                            Text(viewModel.serverReturnedHeadersJSON)
                                .font(.system(size: 11, design: .monospaced))
                                .padding(8)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(6)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    SwiftUI.Button {
                        Task {
                            await viewModel.loadServerHeadersIntoOverrides()
                        }
                    } label: {
                        Label("将获取的数据加载到覆盖项", systemImage: "square.and.arrow.down.on.square")
                    }
                    .disabled(viewModel.serverReturnedHeadersJSON == "{}" || viewModel.serverReturnedHeadersJSON.isEmpty)
                } header: {
                    Text("服务器返回的标头（只读）")
                } footer: {
                    Text("显示从成功的 anisette 服务器握手缓存的原始标头。用于复制客户端/服务器发送的精确参数。")
                }
                
                // SECTION 5: ACTIONS
                Section {
                    SwiftUI.Button {
                        Task {
                            await viewModel.fetchFreshFromServer()
                        }
                    } label: {
                        Label("从活跃服务器获取新数据", systemImage: "arrow.clockwise")
                    }
                    
                    SwiftUI.Button {
                        showingFileImporter = true
                    } label: {
                        Label("导入配置 JSON", systemImage: "square.and.arrow.down")
                    }
                    
                    SwiftUI.Button {
                        Task {
                            if let url = await viewModel.exportJSON() {
                                exportFileURL = url
                                showingShareSheet = true
                            }
                        }
                    } label: {
                        Label("导出配置 JSON", systemImage: "square.and.arrow.up")
                    }
                    
                    SwiftUI.Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        Label("重置为默认值", systemImage: "arrow.circlepath")
                            .foregroundColor(.red)
                    }
                    .alert("重置为默认值？", isPresented: $showingResetAlert) {
                        SwiftUI.Button("重置", role: .destructive) {
                            Task {
                                await viewModel.reset()
                            }
                        }
                        SwiftUI.Button("取消", role: .cancel) {}
                    } message: {
                        Text("这将把客户端标头恢复为推荐的默认 macOS 值。")
                    }
                } header: {
                    Text("操作")
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("客户端配置")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
                        .shadow(radius: 10)
                }
            }
        )
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task {
                        await viewModel.importJSON(url: url)
                    }
                }
            case .failure(let error):
                viewModel.showToast(text: "文件选择失败", error: error)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let fileURL = exportFileURL {
                ActivityViewController(activityItems: [fileURL])
            }
        }
    }
}
