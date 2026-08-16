//
//  SetCertificateAlertViewController.swift
//  SideStore
//
//  Created by Magesh K on 1/8/26.
//  Copyright © 2026 SideStore. All rights reserved.
//

@preconcurrency import UIKit
import Foundation
@preconcurrency import AltSign

final class SetCertificateAlertViewController: UIViewController {
    let installedApp: InstalledApp
    let targetCertificate: ALTX509Certificate
    let viewModel: CertificatesViewModel
    
    init(installedApp: InstalledApp, certificate: ALTX509Certificate, viewModel: CertificatesViewModel = CertificatesViewModel()) {
        self.installedApp = installedApp
        self.targetCertificate = certificate
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appCertSerial = installedApp.certificateSerialNumber
        var currentCertObj = viewModel.getSigningCertificate(at: installedApp.fileURL)
        
        if currentCertObj == nil, let serial = appCertSerial {
            currentCertObj = viewModel.getLocalX509Certificate(serialNumber: serial)
        }
        
        let currentName = currentCertObj?.name ?? "不适用"
        let currentMachine = currentCertObj?.machineName ?? "不适用"
        let currentSerial = currentCertObj?.serialNumber ?? appCertSerial ?? "无"
        let currentEmail = currentCertObj?.requesterEmail ?? "不适用"
        let currentBrief = getBriefInfo(for: currentCertObj?.data)
        let currentType = currentBrief?.type ?? "不适用"
        let currentValidity = currentBrief != nil ? "\(currentBrief!.validFrom) - \(currentBrief!.validUntil)" : "不适用"
        
        let targetName = targetCertificate.name
        let targetMachine = targetCertificate.machineName ?? "不适用"
        let targetSerial = targetCertificate.serialNumber
        let targetEmail = targetCertificate.requesterEmail ?? "不适用"
        let targetBrief = getBriefInfo(for: targetCertificate.data)
        let targetType = targetBrief?.type ?? "不适用"
        let targetValidity = targetBrief != nil ? "\(targetBrief!.validFrom) - \(targetBrief!.validUntil)" : "不适用"
        
        debugLog("[SetCertAlert] appName: '\(installedApp.name)', appCertSerial: '\(appCertSerial ?? "nil")'")
        debugLog("[SetCertAlert] currentCertObj found: \(currentCertObj != nil), serial: '\(currentSerial)', name: '\(currentName)', machine: '\(currentMachine)', email: '\(currentEmail)'")
        debugLog("[SetCertAlert] targetCert serial: '\(targetSerial)', name: '\(targetName)', machine: '\(targetMachine)', email: '\(targetEmail)'")
        
        let details = """
          • 应用：\(installedApp.name)
          • 包名 ID：\(installedApp.resignedBundleIdentifier)

        [当前应用证书]
          • 名称：\(currentName)
          • 机器：\(currentMachine)
          • 序列号：\(currentSerial)
          • 类型：\(currentType)
          • 有效期：\(currentValidity)
          • 电子邮件：\(currentEmail)

        [目标证书]
          • 名称：\(targetName)
          • 机器：\(targetMachine)
          • 序列号：\(targetSerial)
          • 类型：\(targetType)
          • 有效期：\(targetValidity)
          • 电子邮件：\(targetEmail)
        """
        
        let detailsLabel = UILabel()
        detailsLabel.text = details
        detailsLabel.font = .systemFont(ofSize: 11, weight: .regular)
        detailsLabel.textColor = .secondaryLabel
        detailsLabel.numberOfLines = 0
        detailsLabel.textAlignment = .left
        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(detailsLabel)
        
        NSLayoutConstraint.activate([
            detailsLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            detailsLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4),
            detailsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            detailsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
        
        self.preferredContentSize = CGSize(width: 290, height: 290)
    }
}
