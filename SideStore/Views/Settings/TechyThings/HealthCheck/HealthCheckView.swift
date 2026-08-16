//
//  HealthCheckView.swift
//  SideStore
//
//  Created by Magesh K on 11/07/26.
//  Copyright © 2026 SideStore. All rights reserved.
//

import SwiftUI
import Minimuxer

struct HealthCheckView: View {
    @StateObject private var viewModel = HealthCheckViewModel()
    
    var body: some View {
        List {
            // Section 1: Connection Status Header
            Section {
                VStack(spacing: 12) {
                    if let result = viewModel.minimuxerReadyResult {
                        switch result {
                        case .success:
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.green)
                            Text("SideStore 已就绪")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(viewModel.connectionMode == .localVPN
                                 ? "所有要求均已满足。本地设备配对和 VPN 隧道已激活。"
                                 : "所有要求均已满足。本地设备配对和远程服务器连接已激活。"
                            )
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        case .failure(let err):
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.orange)
                            Text("需要操作")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(err.localizedDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        ProgressView("正在执行诊断检查…")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            
            // Section 2: Core Dependencies
            Section(header: Text("核心要求")) {
                DependencyRow(
                    title: "网络连接",
                    subtitle: viewModel.networkSatisfied == nil ? "未知" : (viewModel.isWifiSatisfied ? "Wi-Fi 已连接" : "无连接"),
                    isSatisfied: viewModel.networkSatisfied
                )
                
                if viewModel.connectionMode == .localVPN {
                    DependencyRow(
                        title: "VPN 隧道 (utun)",
                        subtitle: viewModel.vpnSatisfied == nil ? "未知" : (viewModel.isUTunAvailable ? "已连接" : "未连接"),
                        isSatisfied: viewModel.vpnSatisfied
                    )
                    
                    if !viewModel.isRPPairing {
                        if #available(iOS 26.4, *) {
                            DependencyRow(
                                title: "IPSec/IKEv2 隧道",
                                subtitle: viewModel.ipsecSatisfied == nil ? "未知" : (viewModel.isIKEv2IPSecAvailable ? "已连接" : "未连接"),
                                isSatisfied: viewModel.ipsecSatisfied
                            )
                        }
                    }
                }
                
                DependencyRow(
                    title: "设备可达性（Ping）",
                    subtitle: viewModel.pingSatisfied == nil ? "未知" : (viewModel.isPingSuccessful ? "可达" : "不可达"),
                    isSatisfied: viewModel.pingSatisfied
                )
                
                DependencyRow(
                    title: "配对文件",
                    subtitle: viewModel.isPairingFileVerified ? "已验证" : (viewModel.isPairingFileLoaded ? "已加载（连接中断）" : "未验证 / 缺失"),
                    isSatisfied: viewModel.pairingSatisfied
                )
            }
            
            // Section 3: JIT Dependencies
            Section(header: Text("JIT 要求")) {
                DependencyRow(
                    title: "开发者磁盘映像（DDI）",
                    subtitle: viewModel.isDDIMounted ? "已挂载" : "未挂载（JIT 不可用）",
                    isSatisfied: viewModel.ddiSatisfied,
                    isOptional: true
                )
            }
            
            // Section 4: Connection Configuration
            Section(header: Text("连接配置")) {
                HStack {
                    Text("连接模式")
                    Spacer()
                    Text(viewModel.connectionMode == .localVPN ? "本地 VPN" : "远程服务器")
                        .foregroundColor(.secondary)
                }
                
                if viewModel.connectionMode == .localVPN {
                    ConfigRow(label: "隧道接口 IP", value: viewModel.tunnelIfaceIp)
                    ConfigRow(label: "隧道子网掩码", value: viewModel.tunnelIfaceSubnetMask)
                    ConfigRow(label: "隧道对端 IP", value: viewModel.tunnelPeerIp)
                    ConfigRow(label: "覆盖对端 IP", value: viewModel.overrideTunnelPeerIp.isEmpty ? nil : viewModel.overrideTunnelPeerIp)
                    HStack {
                        Text("覆盖状态")
                        Spacer()
                        Text(viewModel.overrideTunnelPeerEffective ? "已启用" : "未启用")
                            .foregroundColor(viewModel.overrideTunnelPeerEffective ? .green : .secondary)
                    }
                    HStack {
                        Text("活动协议")
                        Spacer()
                        Text(viewModel.activeProtocol)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ConfigRow(label: "远程端点 IP", value: viewModel.remoteServerIp.isEmpty ? nil : viewModel.remoteServerIp)
                    HStack {
                        Text("活动协议")
                        Spacer()
                        Text(viewModel.activeProtocol)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Section 4: All Active Interfaces
            Section(header: Text("活动网络接口")) {
                if viewModel.availableInterfaces.isEmpty {
                    Text("未扫描到活动接口。")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    let vpnInterfaces = viewModel.availableInterfaces.filter { $0.type.isVPN }
                    let localInterfaces = viewModel.availableInterfaces.filter { !$0.type.isVPN }
                    
                    if !vpnInterfaces.isEmpty {
                        ForEach(vpnInterfaces) { iface in
                            InterfaceRow(iface: iface)
                        }
                    }
                    
                    if !localInterfaces.isEmpty {
                        ForEach(localInterfaces) { iface in
                            InterfaceRow(iface: iface)
                        }
                    }
                }
            }
        }
        .navigationTitle("健康检查")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.observeMetrics()
        }
    }
}

struct DependencyRow: View {
    let title: String
    let subtitle: String
    let isSatisfied: Bool?
    var isOptional: Bool = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if let satisfied = isSatisfied {
                if satisfied {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                } else if isOptional {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
            } else {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.title3)
            }
        }
    }
}

struct ConfigRow: View {
    let label: String
    let value: String?
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value ?? "不适用")
                .foregroundColor(.secondary)
        }
    }
}

struct InterfaceRow: View {
    let iface: LocalInterfaceInfo
    
    private var hasIPv4: Bool {
        !iface.subnet.isEmpty && !iface.ip.contains(":")
    }
    
    private var ipv4Host: String {
        hasIPv4 ? iface.ip : "不适用"
    }
    
    private var ipv4Mask: String {
        !iface.subnet.isEmpty ? iface.subnet : "不适用"
    }
    
    private var ipv6Address: String {
        if let v6 = iface.ipv6, !v6.isEmpty {
            return v6
        }
        if iface.ip.contains(":") {
            return iface.ip
        }
        return "不适用"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("接口：")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 36, alignment: .leading)
                
                Text(iface.name)
                    .fontWeight(.semibold)
                
                Text(iface.type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(iface.type.isVPN ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15))
                    .foregroundColor(iface.type.isVPN ? .blue : .primary)
                    .cornerRadius(4)
                
                Spacer()
            }
            .padding(.bottom, 2)
            
            HStack(alignment: .top, spacing: 8) {
                Text("IPv4：")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 36, alignment: .leading)
                
                Text(ipv4Host)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(hasIPv4 ? .primary : .secondary)
                
                if hasIPv4 {
                    Text("(\(ipv4Mask))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(alignment: .top, spacing: 8) {
                Text("IPv6:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 36, alignment: .leading)
                
                Text(ipv6Address)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(ipv6Address != "不适用" ? .primary : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}
