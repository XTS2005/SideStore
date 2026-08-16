//
//  CertificateDetailView.swift
//  SideStore
//
//  Created by Magesh K on 2026-06-29.
//  Copyright © 2026 SideStore. All rights reserved.
//

import SwiftUI
@preconcurrency import AltSign

struct DeveloperPortalMetadata {
    var identifier: String?
    var machineName: String?
    var machineIdentifier: String?
    var requesterEmail: String?
}

struct CertificateDetailView: View {
    let certificate: ALTX509Certificate
    let portalMetadata: DeveloperPortalMetadata?
    @ObservedObject var viewModel: CertificatesViewModel
    
    private var signableCert: ALTCertificate? {
        viewModel.getSignableCertificate(for: certificate.serialNumber)
    }
    
    init(certificate: ALTX509Certificate, portalMetadata: DeveloperPortalMetadata? = nil, viewModel: CertificatesViewModel) {
        self.certificate = certificate
        self.portalMetadata = portalMetadata
        self.viewModel = viewModel
    }
    
    @State private var isRedacted = true
    
    @State private var showPrivateKey = false
    @State private var copiedPrivateKey = false
    @State private var copiedPEM = false
    @State private var copiedSerialNumber = false
    @State private var copiedIdentifier = false
    @State private var copiedFingerprintSHA1 = false
    @State private var copiedFingerprintSHA256 = false
    
    var body: some View {
        Form {
            Section {
                Section {
                    if let identifier = portalMetadata?.identifier {
                        detailRowWithCopy(title: "证书 ID", value: identifier, isCopied: $copiedIdentifier)
                    }
                    if let machineID = portalMetadata?.machineIdentifier {
                        detailRow(title: "机器 ID", value: machineID)
                    }
                    if let email = portalMetadata?.requesterEmail {
                        detailRow(title: "请求者电子邮件", value: redactableValue(email))
                    }
                } header: {
                    Text("Developer Portal 信息")
                }
            }
            
            if let certData = certificate.data {
                let details = parseCertificate(derData: certData)
                Section {
                    detailRow(title: "版本", value: details.version)
                    detailRow(title: "主题", value: redactableValue(details.subject))
                    detailRow(title: "签发者", value: details.issuer)
                    detailRow(title: "序列号（十六进制）", value: details.serialHex)
                    detailRow(title: "序列号（十进制）", value: details.serialDec)
                } header: {
                    Text("X.509 字段")
                }
                
                if let from = details.validFrom, let until = details.validUntil {
                    let stats = computeValidityStats(from: from, until: until)
                    Section {
                        detailRow(title: "生效日期", value: formatDate(from))
                        detailRow(title: "失效日期", value: formatDate(until))
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("有效期进度")
                                Spacer()
                                Text(String(format: "%.0f%%", stats.progress * 100))
                                    .foregroundColor(.secondary)
                            }
                            ProgressView(value: stats.progress)
                                .tint(.accentColor)
                        }
                        
                        detailRow(title: "有效期天数", value: "总计：\(stats.totalDays)，已过：\(stats.elapsedDays)，剩余：\(stats.remainingDays)")
                    } header: {
                        Text("有效期")
                    }
                }
                
                Section {
                    detailRow(title: "公钥", value: details.publicKeyType)
                    detailRow(title: "签名算法", value: details.signatureAlgorithm)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("SHA-1 指纹")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            
                            SwiftUI.Button {
                                UIPasteboard.general.string = details.fingerprintSHA1
                                copiedFingerprintSHA1 = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copiedFingerprintSHA1 = false
                                }
                            } label: {
                                Image(systemName: copiedFingerprintSHA1 ? "checkmark" : "doc.on.doc")
                                    .font(.footnote)
                                    .foregroundColor(copiedFingerprintSHA1 ? .green : .accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                        Text(details.fingerprintSHA1)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("SHA-256 指纹")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            
                            SwiftUI.Button {
                                UIPasteboard.general.string = details.fingerprintSHA256
                                copiedFingerprintSHA256 = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copiedFingerprintSHA256 = false
                                }
                            } label: {
                                Image(systemName: copiedFingerprintSHA256 ? "checkmark" : "doc.on.doc")
                                    .font(.footnote)
                                    .foregroundColor(copiedFingerprintSHA256 ? .green : .accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                        Text(details.fingerprintSHA256)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("签名与公钥详情")
                }
            }
            
            Section {
                detailRow(title: "有私钥", value: signableCert != nil ? "是" : "否")
                
                if let privateKey = signableCert?.privateKey {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("私钥数据")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            
                            SwiftUI.Button {
                                showPrivateKey.toggle()
                            } label: {
                                Image(systemName: showPrivateKey ? "eye.slash" : "eye")
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                            
                            SwiftUI.Button {
                                UIPasteboard.general.string = privateKey.base64EncodedString()
                                copiedPrivateKey = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copiedPrivateKey = false
                                }
                            } label: {
                                Image(systemName: copiedPrivateKey ? "checkmark" : "doc.on.doc")
                                    .foregroundColor(copiedPrivateKey ? .green : .accentColor)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 12)
                        }
                        
                        if showPrivateKey {
                            Text(privateKey.base64EncodedString())
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                                .lineLimit(nil)
                                .multilineTextAlignment(.leading)
                        } else {
                            Text("••••••••••••••••••••••••••••")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                if let certData = certificate.data {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("证书 PEM 数据")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            
                            SwiftUI.Button {
                                let pem = String(data: certData, encoding: .utf8) ?? certData.base64EncodedString()
                                UIPasteboard.general.string = pem
                                copiedPEM = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copiedPEM = false
                                }
                            } label: {
                                Image(systemName: copiedPEM ? "checkmark" : "doc.on.doc")
                                    .foregroundColor(copiedPEM ? .green : .accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: true) {
                            Text(String(data: certData, encoding: .utf8) ?? certData.base64EncodedString())
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("加密密钥")
            }
        }
        .navigationTitle("证书详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                SwiftUI.Button {
                    isRedacted.toggle()
                } label: {
                    Image(systemName: isRedacted ? "eye.slash" : "eye")
                }
            }
        }
    }
    
    private func redactableValue(_ value: String, sensitive: Bool = true) -> String {
        if sensitive && isRedacted {
            return "••••••••"
        }
        return value
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }
    
    private func detailRowWithCopy(title: String, value: String, isCopied: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
            
            if value != "N/A" && !value.isEmpty && value != "••••••••" {
                SwiftUI.Button {
                    UIPasteboard.general.string = value
                    isCopied.wrappedValue = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isCopied.wrappedValue = false
                    }
                } label: {
                    Image(systemName: isCopied.wrappedValue ? "checkmark" : "doc.on.doc")
                        .font(.footnote)
                        .foregroundColor(isCopied.wrappedValue ? .green : .accentColor)
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            }
        }
    }
}
