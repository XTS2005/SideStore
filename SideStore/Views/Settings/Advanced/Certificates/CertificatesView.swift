//
//  CertificatesView.swift
//  SideStore
//
//  Created by Magesh K on 2026-06-29.
//  Copyright © 2026 SideStore. All rights reserved.
//

import SwiftUI
@preconcurrency import AltSign
import UniformTypeIdentifiers

struct CertificatesView: View {
    weak var presentingViewController: UIViewController?
    
    @StateObject private var viewModel = CertificatesViewModel()
    
    private var allowedImportTypes: [UTType] {
        ["p12", "pfx", "pkcs12", "der", "cer", "crt", "pem"].compactMap { UTType(filenameExtension: $0) }
    }
    private var allowedKeyImportTypes: [UTType] {
        ["key", "pem", "der"].compactMap { UTType(filenameExtension: $0) }
    }
    
    @State private var showCreateDialog           = false
    @State private var showFileImporter           = false
    @State private var showRevokeConfirmation     = false
    @State private var showDeactivateConfirmation = false
    @State private var showDeleteConfirmation     = false
    @State private var showExportPasswordPrompt   = false
    @State private var showClearKeyConfirmation   = false
    @State private var hasInitialLoaded           = false
    @State private var hasCopiedActiveSerial      = false
    
    @State private var newMachineName        = ""
    @State private var exportPasswordInput   = ""
    @State private var fileImportMode: FileImportMode       = .certificate
    @State private var keyTextImportItem: KeyTextImportItem? = nil
    @State private var privateKeyTextInput   = ""
    
    @State private var deleteLocalOnRevoke: Bool = true
    
    @State private var certificateToRevoke:      ALTX509Certificate? = nil
    @State private var certificateToDelete:      ALTX509Certificate? = nil
    @State private var certificateToExport:      ALTX509Certificate? = nil
    @State private var certificateToAddKeyFor:   ALTX509Certificate? = nil
    @State private var certificateToClearKeyFor: ALTX509Certificate? = nil
    
    var body: some View {
        ZStack {
            List {
                ActiveCertSectionView(
                    viewModel: viewModel,
                    hasCopiedActiveSerial: $hasCopiedActiveSerial,
                    onDeactivate: { showDeactivateConfirmation = true }
                )
                CertificatesListView(
                    viewModel: viewModel,
                    onRowTap:     { pushDetailView(for: $0) },
                    onRevoke:     { presentRevokeAlert(for: $0) },
                    onExportP12:  { cert in
                        certificateToExport = cert
                        exportPasswordInput = ""
                        showExportPasswordPrompt = true
                    },
                    onClearKey:   { cert in
                        certificateToClearKeyFor = cert
                        showClearKeyConfirmation = true
                    },
                    onAddKeyBin:  { cert in
                        certificateToAddKeyFor = cert
                        fileImportMode = .privateKey
                        showFileImporter = true
                    },
                    onAddKeyText: { cert in
                        keyTextImportItem = KeyTextImportItem(id: cert.serialNumber, cert: cert)
                    },
                    onDelete: { certificateToDelete = $0; showDeleteConfirmation = true }
                )
            }
            .refreshable {
                await withCheckedContinuation { continuation in
                    viewModel.loadCertificates(presentingViewController: presentingViewController, isPullToRefresh: true) {
                        continuation.resume()
                    }
                }
            }
            .navigationTitle("证书")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    SwiftUI.Button {
                        viewModel.isGlobalHideActive.toggle()
                    } label: {
                        Image(systemName: viewModel.isGlobalHideActive ? "eye.slash" : "eye")
                    }
                    .accessibilityLabel("切换隐藏敏感信息")
                    
                    SwiftUI.Button {
                        newMachineName = "SideStore - \(UIDevice.current.name)"
                        showCreateDialog = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("创建证书")
                    .disabled(viewModel.team == nil)
                    
                    SwiftUI.Button {
                        fileImportMode = .certificate
                        showFileImporter = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .accessibilityLabel("导入证书")
                }
            }
            .onAppear {
                guard !hasInitialLoaded else { return }
                hasInitialLoaded = true
                viewModel.loadCertificates(presentingViewController: nil)
            }
            
            if viewModel.isLoading { LoadingOverlay() }
        }
        .alert("错误", isPresented: $viewModel.showErrorAlert) {
            SwiftUI.Button("确定", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "发生未知错误。")
        }
        .alert("新证书", isPresented: $showCreateDialog) {
            TextField("机器名称", text: $newMachineName)
            SwiftUI.Button("创建") {
                viewModel.createCertificate(machineName: newMachineName, presentingViewController: presentingViewController)
            }
            SwiftUI.Button("取消", role: .cancel) {}
        } message: {
            Text("为新证书输入名称。这将在 Apple 的服务器上创建新证书，并将私钥存储在本地。")
        }
        .alert("停用证书", isPresented: $showDeactivateConfirmation) {
            SwiftUI.Button("停用", role: .destructive) { viewModel.deactivateActiveCertificate() }
            SwiftUI.Button("取消", role: .cancel) {}
        } message: {
            Text("你确定要在本地停用当前的签名证书吗？")
        }
        .alert("删除证书", isPresented: $showDeleteConfirmation) {
            SwiftUI.Button("删除", role: .destructive) {
                if let cert = certificateToDelete { viewModel.deleteCertificate(cert) }
            }
            SwiftUI.Button("取消", role: .cancel) {}
        } message: {
            Text("你确定要在本地删除此证书吗？这将把它从本地缓存存储中移除。")
        }
        .alert("导入证书密码", isPresented: $viewModel.showPasswordPromptForImport) {
            SecureField("密码", text: $viewModel.importPasswordInput)
            SwiftUI.Button("导入") { viewModel.submitImportPassword() }
            SwiftUI.Button("取消", role: .cancel) { viewModel.cancelImport() }
        } message: {
            Text("输入密码以解密导入的证书文件。\n\n文件：\(viewModel.currentImportFilename)")
        }
        .alert("成功", isPresented: $viewModel.showAlert) {
            SwiftUI.Button("确定", role: .cancel) { viewModel.alertMessage = nil }
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
        .alert("导入摘要", isPresented: $viewModel.showImportSummary) {
            if viewModel.importFailedCount > 0 {
                SwiftUI.Button("显示失败项") {
                    DispatchQueue.main.async {
                        viewModel.showFailuresAlert = true
                    }
                }
                SwiftUI.Button("确定", role: .cancel) {}
            } else {
                SwiftUI.Button("确定", role: .cancel) {}
            }
        } message: {
            Text(viewModel.importSummaryMessage)
        }
        .sheet(isPresented: $viewModel.showFailuresAlert) {
            NavigationView {
                List {
                    ForEach(viewModel.failedImportsList, id: \.self) { failure in
                        Text(failure)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.red)
                    }
                }
                .navigationTitle("导入失败")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        SwiftUI.Button("完成") {
                            viewModel.showFailuresAlert = false
                        }
                    }
                }
            }
        }
        .alert("导出证书密码", isPresented: $showExportPasswordPrompt) {
            SecureField("密码", text: $exportPasswordInput)
            SwiftUI.Button("导出") {
                if let cert = certificateToExport, let signable = viewModel.getSignableCertificate(for: cert.serialNumber) {
                    CertificateExporter.shareP12(signable, password: exportPasswordInput) { viewModel.errorMessage = $0 }
                }
            }
            SwiftUI.Button("取消", role: .cancel) {}
        } message: {
            Text("设置一个密码以加密导出的 .p12 证书文件。")
        }
        .alert("清除私钥", isPresented: $showClearKeyConfirmation) {
            if let cert = certificateToClearKeyFor {
                SwiftUI.Button("清除密钥", role: .destructive) {
                    viewModel.clearPrivateKey(for: cert)
                    certificateToClearKeyFor = nil
                }
            }
            SwiftUI.Button("取消", role: .cancel) { certificateToClearKeyFor = nil }
        } message: {
            if let cert = certificateToClearKeyFor {
                Text("这将清除此证书在本地存储的私钥。\n\n名称：\(cert.name)\nS/N：\(cert.serialNumber)")
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: fileImportMode == .certificate ? allowedImportTypes : allowedKeyImportTypes,
            allowsMultipleSelection: fileImportMode == .certificate
        ) { result in
            switch result {
            case .success(let urls):
                switch fileImportMode {
                case .certificate:
                    viewModel.startBulkImport(urls: urls)
                case .privateKey:
                    if let url = urls.first, let cert = certificateToAddKeyFor {
                        _ = url.startAccessingSecurityScopedResource()
                        defer { url.stopAccessingSecurityScopedResource() }
                        do {
                            viewModel.importPrivateKey(data: try Data(contentsOf: url), for: cert)
                        } catch {
                            viewModel.errorMessage = "读取私钥失败：" + error.localizedDescription
                        }
                    }
                }
            case .failure(let error):
                let type = fileImportMode == .certificate ? "文件" : "私钥"
                viewModel.errorMessage = "选择\(type)失败：" + error.localizedDescription
            }
        }
        .sheet(item: $keyTextImportItem) { item in
            PrivateKeyTextInputView(
                text: $privateKeyTextInput,
                cert: item.cert,
                viewModel: viewModel,
                allowedKeyImportTypes: allowedKeyImportTypes,
                onCancel: {
                    keyTextImportItem = nil
                    privateKeyTextInput = ""
                }
            )
        }
    }
    
    private func pushDetailView(for cert: ALTX509Certificate) {
        let metadata = DeveloperPortalMetadata(
            identifier: cert.identifier,
            machineName: cert.machineName,
            machineIdentifier: cert.machineIdentifier,
            requesterEmail: cert.requesterEmail
        )
        let detailVC = UIHostingController(rootView: CertificateDetailView(certificate: cert, portalMetadata: metadata, viewModel: viewModel))
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        detailVC.navigationItem.scrollEdgeAppearance = appearance
        detailVC.navigationItem.standardAppearance   = appearance
        presentingViewController?.navigationController?.pushViewController(detailVC, animated: true)
    }
    
    private func presentRevokeAlert(for cert: ALTX509Certificate) {
        let contentVC = RevokeAlertViewController()
        
        let alertController = UIAlertController(
            title: NSLocalizedString("撤销证书", comment: ""),
            message: NSLocalizedString("你确定要撤销此证书吗？这将永久删除 Apple 服务器上的证书。", comment: ""),
            preferredStyle: .alert
        )
        
        alertController.setValue(contentVC, forKey: "contentViewController")
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("取消", comment: ""), style: .cancel, handler: nil)
        let revokeAction = UIAlertAction(title: NSLocalizedString("撤销", comment: ""), style: .destructive) { _ in
            let keepLocal = contentVC.isKeepLocalChecked
            viewModel.revokeCertificate(cert, keepLocal: keepLocal, presentingViewController: presentingViewController)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(revokeAction)
        
        presentingViewController?.present(alertController, animated: true)
    }
}

private struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.2).ignoresSafeArea()
            ProgressView()
                .padding(20)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
        }
    }
}
