//
//  PipelineHandler.swift
//  SideStore
//
//  Created by Magesh K on 8/9/26.
//  Copyright © 2026 SideStore. All rights reserved.
//

import UIKit
import AltSign

class PipelineHandler: PipelineExecutionHandler, 
                         PreflightChecksHandler, 
                         EntitlementsReviewHandler, 
                         ExtensionRemovalHandler, 
                         UnsupportedVersionHandler, 
                         InstallAppHandler, 
                         UserCustomizationHandler 
{
    
    var preflightChecksHandler: PreflightChecksHandler { self }
    var entitlementsReviewHandler: EntitlementsReviewHandler { self }
    var extensionRemovalHandler: ExtensionRemovalHandler { self }
    var unsupportedVersionHandler: UnsupportedVersionHandler { self }
    var installAppHandler: InstallAppHandler { self }
    var userCustomizationHandler: UserCustomizationHandler { self }
    
    private weak var presentingViewController: UIViewController?
    
    init(presentingViewController: UIViewController?) {
        self.presentingViewController = presentingViewController
    }
    
    var isResignActive: Bool {
        return presentingViewController is ResignAltStoreViewController
    }
    
    @MainActor
    func resolveBundleIDMismatch(targetID: String, activeEffectiveID: String) async -> Bool {
        guard let presenter = self.presentingViewController else {
            return false
        }
        
        let title = NSLocalizedString("包名 ID 不匹配", comment: "")
        let message = String(format: NSLocalizedString("你正在安装的应用的 bundle ID（%@）与当前应用（%@）不匹配。是否继续？", comment: ""), targetID, activeEffectiveID)
        
        return await withCheckedContinuation { continuation in
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: UIAlertAction.cancel.title, style: UIAlertAction.cancel.style) { _ in
                continuation.resume(returning: false)
            })
            alertController.addAction(UIAlertAction(title: NSLocalizedString("继续", comment: ""), style: .default) { _ in
                continuation.resume(returning: true)
            })
            presenter.present(alertController, animated: true)
        }
    }
    
    @MainActor
    func reviewPermissions(_ permissions: [ALTEntitlement], for app: AppProtocol, mode: PermissionReviewMode) async throws {
        guard let presenter = self.presentingViewController else {
            throw OperationError.cancelled
        }
        let reviewPermissionsViewController = ReviewPermissionsViewController(app: app, permissions: permissions, mode: mode)
        let navigationController = UINavigationController(rootViewController: reviewPermissionsViewController)
        
        defer {
            navigationController.dismiss(animated: true)
        }
        
        try await withCheckedThrowingContinuation { continuation in
            reviewPermissionsViewController.completionHandler = { result in
                continuation.resume(with: result)
            }
            
            presenter.present(navigationController, animated: true)
        }
    }
    
    @MainActor
    func selectAppExtensionsToRemove(
        appBundle: ALTApplication,
        localAppExtensions: [ALTApplication],
        excessExtensions: Set<ALTApplication>
    ) async throws -> ExtensionRemovalDecision {
        guard let presenter = self.presentingViewController else {
            return .keepAll(useMainProfile: false)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let firstSentence: String
            if UserDefaults.standard.activeAppLimitIncludesExtensions {
                firstSentence = NSLocalizedString("非开发者 Apple ID 最多只能激活 3 个应用和应用扩展。", comment: "")
            } else {
                firstSentence = NSLocalizedString("非开发者 Apple ID 每周最多只能创建 10 个应用 ID。", comment: "")
            }
            
            let message = firstSentence + " " + NSLocalizedString("是否要移除此应用的应用扩展，使其不计入你的限制？共有 \(appBundle.appExtensions.count) 个扩展", comment: "")
            
            let alertController = UIAlertController(title: NSLocalizedString("应用包含扩展", comment: ""), message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: UIAlertAction.cancel.title, style: UIAlertAction.cancel.style, handler: { _ in
                continuation.resume(throwing: OperationError.cancelled)
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("保留应用扩展（使用主描述文件）", comment: ""), style: .default) { _ in
                continuation.resume(returning: .keepAll(useMainProfile: true))
            })
            alertController.addAction(UIAlertAction(title: NSLocalizedString("保留应用扩展（为每个扩展注册应用 ID）", comment: ""), style: .default) { _ in
                continuation.resume(returning: .keepAll(useMainProfile: false))
            })
            alertController.addAction(UIAlertAction(title: NSLocalizedString("移除应用扩展", comment: ""), style: .destructive) { _ in
                continuation.resume(returning: .removeAll)
            })
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("选择应用扩展", comment: ""), style: .default) { _ in
                let popoverContentController = AppExtensionViewHostingController(extensions: appBundle.appExtensions) { selection in
                    continuation.resume(returning: .removeSelected(Set(selection)))
                }
                
                let suiview = popoverContentController.view!
                suiview.translatesAutoresizingMaskIntoConstraints = false
                popoverContentController.modalPresentationStyle = .popover
                
                if let popoverPresentationController = popoverContentController.popoverPresentationController {
                    popoverPresentationController.sourceView = presenter.view
                    popoverPresentationController.sourceRect = CGRect(x: 50, y: 50, width: 4, height: 4)
                    popoverPresentationController.delegate = popoverContentController
                    presenter.present(popoverContentController, animated: true)
                } else {
                    continuation.resume(throwing: OperationError.invalidParameters("RemoveAppExtensionsOperation: popoverContentController.popoverPresentationController is nil"))
                }
            })
            
            presenter.present(alertController, animated: true) {
                if presenter.presentedViewController == nil && !alertController.isViewLoaded {
                    let errMsg = "RemoveAppExtensionsOperation: unable to present dialog, view context not available." +
                                 "\nDid you move to different screen or background after starting the operation?"
                    continuation.resume(throwing: OperationError.invalidOperationContext(errMsg))
                }
            }
        }
    }
    
    @MainActor
    func resolveUnsupportediOSVersion(errorDescription: String, appName: String, compatibleVersion: String) async throws -> Bool {
        guard let presenter = self.presentingViewController else {
            return false
        }
        
        let title = NSLocalizedString("不支持的 iOS 版本", comment: "")
        let message = errorDescription + "\n\n" + NSLocalizedString("是否改为下载与此设备兼容的最后一个版本？", comment: "")
        
        return await withCheckedContinuation { continuation in
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: UIAlertAction.cancel.title, style: UIAlertAction.cancel.style) { _ in
                continuation.resume(returning: false)
            })
            alertController.addAction(UIAlertAction(title: String(format: NSLocalizedString("下载 %@ %@", comment: ""), appName, compatibleVersion), style: .default) { _ in
                continuation.resume(returning: true)
            })
            presenter.present(alertController, animated: true)
        }
    }
    
    func requestBackgroundSuspension(completion: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(
                title: "完成刷新",
                message: """
                要完成刷新，SideStore 必须被移到后台。为此，你可以手动返回主屏幕，或轻点“继续”。完成后请重新打开 SideStore。
                """,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: NSLocalizedString("继续", comment: ""), style: .default, handler: { _ in
                completion()
            }))
            
            let presenter = self.presentingViewController
                            ?? UIApplication.shared.connectedScenes
                                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                                .first?.rootViewController
                                
            if var topVC = presenter {
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }
                topVC.present(alert, animated: true)
            } else {
                completion()
            }
        }
    }
    
    func suspendToHomeScreen(shouldTurnOffData: Bool) {
        DispatchQueue.main.async {
            if shouldTurnOffData {
                let shortcutURLonDelay = URL(string: "shortcuts://run-shortcut?name=TurnOnDataDelay")!
                UIApplication.shared.open(shortcutURLonDelay, options: [:])
            }
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
        }
    }
    
    var isAppInForeground: Bool {
        if Thread.isMainThread {
            return UIApplication.shared.applicationState == .active
        } else {
            return DispatchQueue.main.sync {
                UIApplication.shared.applicationState == .active
            }
        }
    }
    
    @MainActor
    func resolveBundleIDOverride(initialBundleID: String) async throws -> String? {
        guard let presenter = self.presentingViewController else {
            return initialBundleID
        }
        
        let titleText = NSLocalizedString("应用 ID 自定义", comment: "")
        let messageText = NSLocalizedString("如有需要，请自定义应用 ID，然后按“确认”继续。", comment: "")
        
        let alert = UIAlertController(
            title: titleText,
            message: messageText,
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.text = initialBundleID
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        
        return await withCheckedContinuation { continuation in
            let okAction = UIAlertAction(title: NSLocalizedString("确认", comment: ""), style: .default) { _ in
                continuation.resume(returning: alert.textFields?.first?.text ?? initialBundleID)
            }
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("取消", comment: ""), style: .cancel) { _ in
                continuation.resume(returning: nil)
            }
            alert.addAction(cancelAction)
            alert.addAction(okAction)
            presenter.present(alert, animated: true)
        }
    }

    @MainActor
    func resolveAppGroupMismatch(originalGroup: String, correctedGroup: String) async throws -> AppGroupResolution {
        guard let presenter = self.presentingViewController else {
            return .correctAndProceed(correctedGroup)
        }
        
        let title = NSLocalizedString("App Group 不一致", comment: "")
        let message = String(format: NSLocalizedString("App Group“%@”与应用 Bundle ID 的大小写不匹配。是否要将其更正为“%@”？", comment: ""), originalGroup, correctedGroup)
        
        return await withCheckedContinuation { continuation in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("更正并继续", comment: ""), style: .default) { _ in
                continuation.resume(returning: .correctAndProceed(correctedGroup))
            })
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("保留原始", comment: ""), style: .destructive) { _ in
                continuation.resume(returning: .keepOriginal(originalGroup))
            })
            
            alert.addAction(UIAlertAction(title: UIAlertAction.cancel.title, style: .cancel) { _ in
                continuation.resume(returning: .keepOriginal(originalGroup))
            })
            
            presenter.present(alert, animated: true)
        }
    }
}
