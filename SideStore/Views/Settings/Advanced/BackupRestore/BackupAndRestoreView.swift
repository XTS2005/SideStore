import SwiftUI
import UniformTypeIdentifiers

private extension Color {
    static let settingsRowBackground = Color.white.opacity(0.15)
    static let settingsDivider = Color.white.opacity(0.15)
}

struct BackupAndRestoreView: View {
    @State private var showingImportFilePicker = false
    @State private var importedData: Data? = nil
    @State private var showingImportPasswordAlert = false
    @State private var importFilePassword = ""
    
    @State private var importedAccount: ImportedAccount? = nil
    @State private var showingApplePasswordAlert = false
    @State private var applePasswordInput = ""
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingMessageAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Section 1: Account, Certificate, & Pairing Data
                VStack(alignment: .leading, spacing: 8) {
                    Text("账户、证书和配对数据")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(.horizontal, 16)
                    
                    VStack(spacing: 0) {
                        SwiftUI.Button(action: {
                            showingImportFilePicker = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("导入账户")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                        }
                        
                        divider
                        
                        SwiftUI.Button(action: {
                            presentExportAlert()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("导出账户")
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
                
                // Section 2: Sources Data
                VStack(alignment: .leading, spacing: 8) {
                    Text("源数据")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(.horizontal, 16)
                    
                    VStack(spacing: 0) {
                        SwiftUI.Button(action: {
                            print("[BackupAndRestoreView] Import Sources tapped")
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("导入源")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                        }
                        
                        divider
                        
                        SwiftUI.Button(action: {
                            print("[BackupAndRestoreView] Export Sources tapped")
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("导出源")
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
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color(uiColor: .settingsBackground).ignoresSafeArea())
        .navigationTitle("备份与恢复")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingImportFilePicker) {
            DocumentPickerView(contentTypes: [UTType(filenameExtension: "sideconf") ?? .data]) { url in
                guard let url = url else { return }
                do {
                    _ = url.startAccessingSecurityScopedResource()
                    defer { url.stopAccessingSecurityScopedResource() }
                    let data = try Data(contentsOf: url)
                    self.importedData = data
                    self.importFilePassword = ""
                    self.showingImportPasswordAlert = true
                } catch {
                    showAlert(title: "导入错误", message: error.localizedDescription)
                }
            }
        }
        .alert("解密备份", isPresented: $showingImportPasswordAlert) {
            SecureField("文件密码", text: $importFilePassword)
            SwiftUI.Button("解密") {
                performImportDecrypt()
            }
            SwiftUI.Button("取消", role: .cancel) {}
        } message: {
            Text("输入用于加密此备份文件的密码。")
        }
        .alert("Apple ID 密码", isPresented: $showingApplePasswordAlert) {
            SecureField("密码", text: $applePasswordInput)
            SwiftUI.Button("登录") {
                performAppleSignIn()
            }
            SwiftUI.Button("取消", role: .cancel) {}
        } message: {
            if let email = importedAccount?.email {
                Text("请输入 \(email) 的 Apple ID 密码以完成登录。")
            } else {
                Text("请输入你的 Apple ID 密码以完成登录。")
            }
        }
        .alert(alertTitle, isPresented: $showingMessageAlert) {
            SwiftUI.Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Color.settingsDivider)
            .frame(height: 0.5)
            .padding(.horizontal, 16)
    }

    private func presentExportAlert() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              var top = window.rootViewController else { return }
        while let presented = top.presentedViewController {
            top = presented
        }
        
        let alert = UIAlertController(title: NSLocalizedString("导出账户", comment: ""), message: nil, preferredStyle: .alert)
        let alertVC = ExportAccountAlertViewController()
        alert.setValue(alertVC, forKey: "contentViewController")
        
        let exportAction = UIAlertAction(title: NSLocalizedString("导出", comment: ""), style: .default) { _ in
            let filePassword = alertVC.passwordTextField.text ?? ""
            let includeApplePassword = alertVC.isIncludePasswordChecked
            
            guard !filePassword.isEmpty else {
                showAlert(title: "导出错误", message: "文件密码不能为空。")
                return
            }
            
            do {
                let encryptedData = try ImportExport.exportAccount(password: filePassword, includeApplePassword: includeApplePassword)
                guard AuthManager.shared.currentAppleID != nil else { return }
                
                let tempDir = FileManager.default.temporaryDirectory
                let fileURL = tempDir.appendingPathComponent(AppConstants.accountConfigurationFileName)
                try encryptedData.write(to: fileURL)
                
                let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                top.present(activityVC, animated: true)
            } catch {
                showAlert(title: "导出错误", message: error.localizedDescription)
            }
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("取消", comment: ""), style: .cancel)
        
        alert.addAction(exportAction)
        alert.addAction(cancelAction)
        
        top.present(alert, animated: true)
    }
    
    private func performImportDecrypt() {
        guard let data = importedData, !importFilePassword.isEmpty else { return }
        do {
            let account = try ImportExport.importAccount(data, filePassword: importFilePassword)
            self.importedAccount = account
            
            if let pass = account.password, !pass.isEmpty {
                showAlert(title: "账户已导入", message: "账户 \(account.email) 导入成功！")
            } else {
                self.applePasswordInput = ""
                self.showingApplePasswordAlert = true
            }
        } catch {
            showAlert(title: "导入错误", message: error.localizedDescription)
        }
    }
    
    private func performAppleSignIn() {
        guard let account = importedAccount, !applePasswordInput.isEmpty else { return }
        AuthManager.shared.password = applePasswordInput
        showAlert(title: "账户已导入", message: "账户 \(account.email) 导入成功！")
    }

    private func showAlert(title: String, message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showingMessageAlert = true
    }
}

struct DocumentPickerView: UIViewControllerRepresentable {
    let contentTypes: [UTType]
    let onPick: (URL?) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: false)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL?) -> Void
        init(onPick: @escaping (URL?) -> Void) {
            self.onPick = onPick
        }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls.first)
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onPick(nil)
        }
    }
}
