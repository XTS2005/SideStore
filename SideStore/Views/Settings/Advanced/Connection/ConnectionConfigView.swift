//
//  ConnectionConfigView.swift
//  SideStore
//
//  Created by Magesh K on 02/03/26.
//  Copyright © 2026 SideStore. All rights reserved.
//

import SwiftUI
import Combine

private typealias SButton = SwiftUI.Button

enum ActiveState: String {
    case yes = "是"
    case no = "否"
}

struct AnimatedCheckmarkView: View {
    @State private var outerCircleTrim: CGFloat = 0.0
    @State private var checkmarkTrim: CGFloat = 0.0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.green.opacity(0.2), lineWidth: 4)
                .frame(width: 70, height: 70)
            
            Circle()
                .trim(from: 0.0, to: outerCircleTrim)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 70, height: 70)
                .rotationEffect(.degrees(-90))
            
            Path { path in
                path.move(to: CGPoint(x: 21, y: 35))
                path.addLine(to: CGPoint(x: 30, y: 44))
                path.addLine(to: CGPoint(x: 49, y: 25))
            }
            .trim(from: 0.0, to: checkmarkTrim)
            .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            .frame(width: 70, height: 70)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.4)) {
                outerCircleTrim = 1.0
            }
            withAnimation(.easeIn(duration: 0.3).delay(0.4)) {
                checkmarkTrim = 1.0
            }
        }
    }
}

struct ConnectionConfigView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var config = ConnectionConfig.shared
    @State private var draftUseLocalVPN: Bool = ConnectionConfig.shared.useLocalVPN
    @State private var draftOverrideTunnelPeerIp: String = ConnectionConfig.shared.overrideTunnelPeerIp
    @State private var draftRemoteServerIp: String = ConnectionConfig.shared.remoteServerIp
    @State private var draftWireGuardServerHost: String = ConnectionConfig.shared.wireguardServerHost
    @State private var draftWireGuardServerPort: String = String(ConnectionConfig.shared.wireguardServerPort)
    @State private var alwaysShowWireGuardConfig: Bool = UserDefaults.standard.alwaysShowWireGuardConfig
    @State private var showConfirmDialog = false
    @State private var validationError: String?
    @State private var showValidationErrorAlert = false

    var body: some View {
        ZStack {
            List {
                Section {
                    Toggle("使用本地 VPN", isOn: $draftUseLocalVPN)
                }

                if draftUseLocalVPN {
                    Section(header: Text("从网络自动发现")) {
                        Group {
                            networkConfigRow(label: "隧道 IP", text: $config.tunnelIfaceIp, editable: false)
                            networkConfigRow(label: "隧道掩码", text: $config.tunnelIfaceSubnetMask, editable: false)
                            networkConfigRow(label: "设备 IP", text: $config.tunnelPeerIp, editable: false)
                            if config.overrideTunnelPeerIp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                let hasDiscoveredPeer = config.tunnelPeerIp != nil && !config.tunnelPeerIp!.isEmpty
                                networkConfigRow(
                                    label: "可达",
                                    text: Binding<String?>(get: { hasDiscoveredPeer ? config.tunnelPeerActive.rawValue : "不适用" }, set: { _ in }),
                                    editable: false,
                                    textColor: hasDiscoveredPeer ? (config.tunnelPeerActive == .yes ? .green : .red) : .gray
                                )
                            }
                        }
                    }
                    
                    Section {
                        networkConfigRow(
                            label: "设备 IP",
                            text: Binding<String?>(get: { draftOverrideTunnelPeerIp }, set: { draftOverrideTunnelPeerIp = $0 ?? "" }),
                            editable: true
                        )
                        if !config.overrideTunnelPeerIp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            networkConfigRow(
                                label: "已启用",
                                text: Binding<String?>(get: { config.overrideTunnelPeerActive.rawValue }, set: { _ in }),
                                editable: false,
                                textColor: config.overrideTunnelPeerActive == .yes ? .green : .red
                            )
                        }
                    } header: {
                        Text("用户配置")
                    } footer: {
                        HStack(alignment: .top, spacing: 0) {
                            Text("注意：")
                            Text("'Device IP' is optional and if specified should match exactly as in the target VPN's config or Leave empty to prefer auto-discovery.")
                        }
                    }
                } else {
                    Section {
                        networkConfigRow(
                            label: "设备 IP / 端点",
                            text: Binding<String?>(get: { draftRemoteServerIp }, set: { draftRemoteServerIp = $0 ?? "" }),
                            editable: true
                        )
                        networkConfigRow(
                            label: "可达",
                            text: Binding<String?>(get: { config.remoteActive.rawValue }, set: { _ in }),
                            editable: false,
                            textColor: config.remoteActive == .yes ? .green : .red
                        )
                    } header: {
                        Text("远程端点")
                    } footer: {
                        HStack(alignment: .top, spacing: 0) {
                            Text("注意：")
                            Text("'设备 IP / 端点'为必填项，且应与远程服务器的地址匹配")
                        }
                    }
                }

                if UserDefaults.standard.enableEMPforWireguard || UserDefaults.standard.alwaysShowWireGuardConfig {
                    Section {
                        networkConfigRow(
                            label: "绑定主机 / IP",
                            text: Binding<String?>(get: { draftWireGuardServerHost }, set: { draftWireGuardServerHost = $0 ?? "" }),
                            editable: true
                        )
                        networkConfigRow(
                            label: "绑定端口",
                            text: Binding<String?>(get: { draftWireGuardServerPort }, set: { draftWireGuardServerPort = $0 ?? "" }),
                            editable: true,
                            isPort: true
                        )
                    } header: {
                        Text("WireGuard 服务器参数")
                    } footer: {
                        Text("配置 EMProxy 绑定的本地 UDP 回环主机和端口。")
                    }
                }
            }
            .navigationTitle("连接配置")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SButton("确认") {
                        Task { await commitChanges() }
                    }
                }
            }
            .disabled(showConfirmDialog)
            .onAppear {
                draftUseLocalVPN = config.useLocalVPN
                draftOverrideTunnelPeerIp = config.overrideTunnelPeerIp
                draftRemoteServerIp = config.remoteServerIp
                draftWireGuardServerHost = config.wireguardServerHost
                draftWireGuardServerPort = String(config.wireguardServerPort)
                alwaysShowWireGuardConfig = UserDefaults.standard.alwaysShowWireGuardConfig
            }
            .alert("配置无效", isPresented: $showValidationErrorAlert) {
                SwiftUI.Button("确定", role: .cancel) {}
            } message: {
                Text(validationError ?? "请检查你的配置设置。")
            }
            
            if showConfirmDialog {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showConfirmDialog = false
                    }
                
                VStack(spacing: 24) {
                    AnimatedCheckmarkView()
                        .padding(.top, 10)
                    
                    Text("更改已保存")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                    
                    SwiftUI.Button(action: {
                        showConfirmDialog = false
                    }) {
                        Text("确定")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(24)
                .frame(width: 320)
                .background(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: showConfirmDialog)
    }

    private func validateInputs() -> String? {
        if !draftUseLocalVPN {
            let remoteIp = draftRemoteServerIp.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !remoteIp.isEmpty else {
                return "远程端点模式下必须填写设备 IP / 端点。"
            }
        }
        if UserDefaults.standard.enableEMPforWireguard || UserDefaults.standard.alwaysShowWireGuardConfig {
            let host = draftWireGuardServerHost.trimmingCharacters(in: .whitespaces)
            guard !host.isEmpty else {
                return "绑定主机 / IP 不能为空。"
            }
            guard let port = UInt16(draftWireGuardServerPort), port > 0 else {
                return "绑定端口必须是 1 到 65535 之间的有效数字。"
            }
        }
        return nil
    }

    private func commitChanges() async {
        if let errorMsg = validateInputs() {
            self.validationError = errorMsg
            self.showValidationErrorAlert = true
            return
        }
        config.useLocalVPN = draftUseLocalVPN
        config.overrideTunnelPeerIp = draftOverrideTunnelPeerIp
        config.remoteServerIp = draftRemoteServerIp
        config.wireguardServerHost = draftWireGuardServerHost.trimmingCharacters(in: .whitespaces)
        config.wireguardServerPort = UInt16(draftWireGuardServerPort)!
        await bindConnectionConfig()
        showConfirmDialog = true
    }
    
    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }

    private func networkConfigRow(
        label: LocalizedStringKey,
        text: Binding<String?>,
        editable: Bool,
        textColor: Color? = nil,
        isPort: Bool = false
    ) -> some View {

        let proxy = Binding<String>(
            get: { text.wrappedValue ?? "不适用" },
            set: { text.wrappedValue = $0.isEmpty || $0 == "不适用" ? nil : $0 }
        )

        return HStack {
            Text(label)
                .foregroundColor(editable ? .primary : .gray)
            Spacer()
            TextField(label, text: proxy)
                .multilineTextAlignment(.trailing)
                .foregroundColor(textColor ?? (editable ? .secondary : .gray))
                .disabled(!editable)
                .keyboardType(isPort ? .numberPad : .numbersAndPunctuation)
                .onChange(of: proxy.wrappedValue) { newValue in
                    guard editable else { return }
                    if isPort {
                        let digits = newValue.filter { "0123456789".contains($0) }
                        if let val = UInt32(digits), val <= 65535 {
                            proxy.wrappedValue = digits
                        } else if digits.isEmpty {
                            proxy.wrappedValue = ""
                        } else {
                            proxy.wrappedValue = String(digits.prefix(5).filter { "0123456789".contains($0) })
                        }
                    } else {
                        proxy.wrappedValue = newValue.filter { "0123456789.".contains($0) }
                    }
                }
        }
    }
}
