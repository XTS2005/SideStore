//
//  PrivateKeyTextInputView.swift
//  SideStore
//
//  Created by Magesh K on 2026-07-03.
//  Copyright © 2026 SideStore. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers
@preconcurrency import AltSign

struct PrivateKeyTextInputView: View {
    @Binding var text: String
    let cert: ALTX509Certificate
    let viewModel: CertificatesViewModel
    let allowedKeyImportTypes: [UTType]
    var onCancel: () -> Void
    
    @State private var showFilePicker = false
    @State private var errorMessage: String? = nil
    @State private var isEditing = false
    @State private var showSuccessAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                Text("在下方粘贴 PEM 格式的私钥，或从文本文件导入。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top)
                
                PrivateKeyTextEditor(text: $text, isEditing: $isEditing)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(4)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                HStack(spacing: 12) {
                    SwiftUI.Button {
                        showFilePicker = true
                    } label: {
                        Label("从文件导入", systemImage: "doc.badge.plus")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    
                    SwiftUI.Button {
                        if let keyData = text.data(using: .utf8) {
                            do {
                                let formattedKey = try viewModel.validateAndFormatPrivateKey(data: keyData)
                                let signableCert = ALTCertificate(x509: cert, privateKey: formattedKey)
                                viewModel.saveLocalCertificate(signableCert)
                                viewModel.loadCertificates(presentingViewController: nil)
                                showSuccessAlert = true
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        Text("添加 PEM 密钥")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("添加私钥")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if isEditing {
                        SwiftUI.Button("完成") {
                            isEditing = false
                        }
                    } else {
                        SwiftUI.Button {
                            onCancel()
                        } label: {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: allowedKeyImportTypes,
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        _ = url.startAccessingSecurityScopedResource()
                        defer { url.stopAccessingSecurityScopedResource() }
                        do {
                            let content = try String(contentsOf: url, encoding: .utf8)
                            text = content
                            isEditing = false
                            errorMessage = nil
                        } catch {
                            errorMessage = "无法将文件读取为文本：" + error.localizedDescription
                        }
                    }
                case .failure(let error):
                    errorMessage = "选择文件失败：" + error.localizedDescription
                }
            }
            .alert("密钥已添加", isPresented: $showSuccessAlert) {
                SwiftUI.Button("确定") {
                    onCancel()
                }
            } message: {
                Text("密钥已添加到证书 \(cert.name)（SN：\(cert.serialNumber)）。")
            }
        }
    }
}
