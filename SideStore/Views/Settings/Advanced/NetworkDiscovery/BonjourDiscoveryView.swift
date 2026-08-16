//
//  BonjourDiscoveryView.swift
//  SideStore
//
//  Created by Magesh K on 4/7/26.
//  Copyright © 2026 SideStore. All rights reserved.
//

import SwiftUI

// MARK: - Root View (Domains List)

/// Entry point: discovers and lists browsable Bonjour domains.
/// Tapping a domain navigates to its service types.
struct BonjourDiscoveryView: View {
    @StateObject private var manager = BonjourDiscoveryManager()
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if manager.isSearching && manager.domains.isEmpty {
                ProgressView("正在搜索域…")
            } else if manager.domains.isEmpty {
                emptyState
            } else {
                domainsList
            }
        }
        .navigationTitle("发现")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            manager.discoverDomains()
        }
        .onDisappear {
            manager.stopDomainSearch()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "network")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("未找到域")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("请确保你已连接到本地网络。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            SwiftUI.Button {
                manager.discoverDomains()
            } label: {
                Label("重试", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.medium))
            }
            .padding(.top, 4)
            
            VStack(spacing: 8) {
                Text("请确保已授予**本地网络访问**权限，否则此功能可能无法按预期工作，因为它基于本地网络访问…")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("**设置 -> 应用 -> SideStore -> 本地网络访问 = 开启**")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 12)
            .padding(.horizontal, 24)
        }
    }
    
    private var domainsList: some View {
        List {
            Section(header: Text("可浏览的域")) {
                ForEach(manager.domains, id: \.self) { domain in
                    NavigationLink(destination: ServiceTypesView(domain: domain)) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.accentColor)
                                .frame(width: 28)
                            Text(domain)
                                .font(.body)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}


// MARK: - Service Types View

/// Lists all service types discovered in a given domain.
/// Tapping a type navigates to its instances.
struct ServiceTypesView: View {
    let domain: String
    @StateObject private var manager = BonjourDiscoveryManager()
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if manager.isSearching && manager.serviceTypes.isEmpty {
                ProgressView("正在搜索服务类型…")
            } else if manager.serviceTypes.isEmpty {
                emptyState
            } else {
                serviceTypesList
            }
        }
        .navigationTitle(domain)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            manager.discoverServiceTypes(in: domain)
        }
        .onDisappear {
            manager.stopTypeSearch()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("未找到服务")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("此域中当前没有公告任何 Bonjour 服务。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            SwiftUI.Button {
                manager.discoverServiceTypes(in: domain)
            } label: {
                Label("重试", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.medium))
            }
            .padding(.top, 4)
            
            VStack(spacing: 8) {
                Text("请确保已授予**本地网络访问**权限，否则此功能可能无法按预期工作，因为它基于本地网络访问…")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("**设置 -> 应用 -> SideStore -> 本地网络访问 = 开启**")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 12)
            .padding(.horizontal, 24)
        }
    }
    
    private var serviceTypesList: some View {
        List {
            Section(
                header: Text("找到 \(manager.serviceTypes.count) 项服务"),
                footer: searchingFooter
            ) {
                ForEach(manager.serviceTypes) { typeInfo in
                    NavigationLink(destination: ServiceInstancesView(
                        serviceType: typeInfo.rawType,
                        domain: domain,
                        friendlyName: typeInfo.friendlyName
                    )) {
                        HStack(spacing: 12) {
                            Image(systemName: typeInfo.friendlyName != nil ? "checkmark.seal.fill" : "questionmark.circle")
                                .foregroundColor(typeInfo.friendlyName != nil ? .green : .orange)
                                .frame(width: 28)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                if let friendly = typeInfo.friendlyName {
                                    Text(friendly)
                                        .font(.body)
                                        .lineLimit(1)
                                    Text(typeInfo.rawType)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                } else {
                                    Text(typeInfo.rawType)
                                        .font(.body)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    @ViewBuilder
    private var searchingFooter: some View {
        if manager.isSearching {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("正在搜索…")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}


// MARK: - Service Instances View

/// Lists all discovered instances of a specific service type.
/// Tapping an instance navigates to its resolved details.
struct ServiceInstancesView: View {
    let serviceType: String
    let domain: String
    let friendlyName: String?
    
    @StateObject private var manager = BonjourDiscoveryManager()
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if manager.isSearching && manager.instances.isEmpty {
                ProgressView("正在搜索实例…")
            } else if manager.instances.isEmpty {
                emptyState
            } else {
                instancesList
            }
        }
        .navigationTitle(friendlyName ?? serviceType)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            manager.discoverInstances(ofType: serviceType, inDomain: domain)
        }
        .onDisappear {
            manager.stopInstanceSearch()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("未找到实例")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("当前没有设备公告此服务。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            SwiftUI.Button {
                manager.discoverInstances(ofType: serviceType, inDomain: domain)
            } label: {
                Label("重试", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.medium))
            }
            .padding(.top, 4)
            
            VStack(spacing: 8) {
                Text("请确保已授予**本地网络访问**权限，否则此功能可能无法按预期工作，因为它基于本地网络访问…")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("**设置 -> 应用 -> SideStore -> 本地网络访问 = 开启**")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 12)
            .padding(.horizontal, 24)
        }
    }
    
    private var instancesList: some View {
        List {
            Section(
                header: VStack(alignment: .leading, spacing: 4) {
                    Text(serviceType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(manager.instances.count) 个实例")
                },
                footer: searchingFooter
            ) {
                ForEach(manager.instances) { instance in
                    NavigationLink(destination: ServiceDetailView(service: instance)) {
                        HStack(spacing: 12) {
                            Image(systemName: "desktopcomputer")
                                .foregroundColor(.accentColor)
                                .frame(width: 28)
                            
                            Text(instance.name)
                                .font(.body)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    @ViewBuilder
    private var searchingFooter: some View {
        if manager.isSearching {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("正在搜索…")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}


// MARK: - Service Detail View

/// Shows full resolved details of a service: hostname, port, IP addresses, TXT records.
struct ServiceDetailView: View {
    let service: DiscoveredService
    @StateObject private var manager = BonjourDiscoveryManager()
    @State private var showCopyConfirmation = false
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if let resolved = manager.resolvedService {
                resolvedContent(resolved)
            } else if let error = manager.resolveError {
                errorState(error)
            } else {
                loadingState
            }
        }
        .navigationTitle("服务详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if manager.resolvedService != nil {
                    SwiftUI.Button("复制") {
                        copyAllInfo()
                    }
                }
            }
        }
        .onAppear {
            manager.resolveService(service)
        }
        .onDisappear {
            manager.stopResolving()
        }
    }
    
    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("正在解析服务…")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("解析失败")
                .font(.headline)
                .foregroundColor(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            SwiftUI.Button {
                manager.resolveService(service)
            } label: {
                Label("重试", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.medium))
            }
            .padding(.top, 4)
        }
    }
    
    private func resolvedContent(_ resolved: ResolvedServiceInfo) -> some View {
        List {
            // Service Name Header
            Section {
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "bonjour")
                        .font(.system(size: 36))
                        .foregroundColor(.accentColor)
                    Text(resolved.name)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            
            // Connection Info
            Section(header: Text("连接")) {
                DetailRow(label: "Hostname", value: resolved.hostname)
                DetailRow(label: "Port", value: "\(resolved.port)")
                DetailRow(label: "Type", value: resolved.type)
                DetailRow(label: "Domain", value: resolved.domain)
            }
            
            // IP Addresses
            if !resolved.addresses.isEmpty {
                Section(header: Text("地址")) {
                    ForEach(resolved.addresses, id: \.self) { address in
                        HStack {
                            Image(systemName: address.contains(":") ? "6.circle" : "4.circle")
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            Text(address)
                                .font(.system(.body, design: .monospaced))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .contextMenu {
                            SwiftUI.Button {
                                UIPasteboard.general.string = address
                            } label: {
                                Label("复制地址", systemImage: "doc.on.doc")
                            }
                        }
                    }
                }
            }
            
            // TXT Records
            if !resolved.txtRecords.isEmpty {
                Section(header: Text("TXT 记录")) {
                    ForEach(resolved.txtRecords, id: \.key) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.key)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                            Text(record.value)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                        .padding(.vertical, 2)
                        .contextMenu {
                            SwiftUI.Button {
                                UIPasteboard.general.string = "\(record.key) = \(record.value)"
                            } label: {
                                Label("复制", systemImage: "doc.on.doc")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay(alignment: .bottom) {
            if showCopyConfirmation {
                copiedBanner
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    private var copiedBanner: some View {
        Text("已复制到剪贴板")
            .font(.subheadline.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.accentColor)
            )
            .padding(.bottom, 16)
    }
    
    private func copyAllInfo() {
        guard let resolved = manager.resolvedService else { return }
        
        var lines: [String] = []
        lines.append("服务：\(resolved.name)")
        lines.append("类型：\(resolved.type)")
        lines.append("域：\(resolved.domain)")
        lines.append("主机名：\(resolved.hostname)")
        lines.append("端口：\(resolved.port)")
        lines.append("")
        
        if !resolved.addresses.isEmpty {
            lines.append("地址：")
            for addr in resolved.addresses {
                lines.append("  \(addr)")
            }
            lines.append("")
        }
        
        if !resolved.txtRecords.isEmpty {
            lines.append("TXT 记录：")
            for record in resolved.txtRecords {
                lines.append("  \(record.key) = \(record.value)")
            }
        }
        
        UIPasteboard.general.string = lines.joined(separator: "\n")
        
        withAnimation(.spring(response: 0.3)) {
            showCopyConfirmation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring(response: 0.3)) {
                showCopyConfirmation = false
            }
        }
    }
}


// MARK: - Detail Row

/// A simple key-value row with context menu for copying
private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .lineLimit(nil)
        }
        .padding(.vertical, 2)
        .contextMenu {
            SwiftUI.Button {
                UIPasteboard.general.string = value
            } label: {
                Label("复制 \(label)", systemImage: "doc.on.doc")
            }
        }
    }
}
