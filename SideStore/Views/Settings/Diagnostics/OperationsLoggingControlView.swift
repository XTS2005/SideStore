//
//  OperationsLoggingControlView.swift
//  SideStore
//
//  Created by Magesh K on 14/01/25.
//  Copyright © 2025 SideStore. All rights reserved.
//

import SwiftUI

private extension Color {
    static let settingsRowBackground = Color.white.opacity(0.15)
    static let settingsDivider = Color.white.opacity(0.15)
}

private let pipelineStepToggles: [(name: String, step: PipelineStep)] = [
    ("备份应用数据",                         .backupAppData),
    ("缓存应用",                               .cacheApp),
    ("更换应用图标",                         .changeAppIcon),
    ("清理暂存应用",                        .cleanStagedApp),
    ("停用应用",                          .deactivateApp),
    ("下载应用",                            .downloadApp),
    ("启用 JIT",                              .enableJIT),
    ("导出重新签名的应用",                     .exportResignedApp),
    ("获取描述文件（安装）",   .fetchProvisioningProfilesInstall),
    ("获取描述文件（刷新）",   .fetchProvisioningProfilesRefresh),
    ("安装应用",                             .installApp),
    ("预检检查",                        .preflightChecks),
    ("准备应用扩展包名 ID",        .prepareAppExtensionBundleIDs),
    ("刷新应用",                             .refreshApp),
    ("移除应用",                              .removeApp),
    ("移除应用扩展",                   .removeAppExtensions),
    ("移除备份数据",                      .removeBackupData),
    ("重新签名应用",                              .resignApp),
    ("恢复应用数据",                        .restoreAppData),
    ("发送应用",                                .sendApp),
    ("暂存应用",                               .stageApp),
    ("暂存备份应用",                        .stageBackupApp),
    ("更新应用证书",                  .updateAppCertificate),
    ("用户自定义",                      .userCustomization),
    ("验证应用",                              .verifyApp),
    ("验证证书",                      .verifyCertificate),
]

private let standaloneStepToggles: [(name: String, step: StandaloneStep)] = [
    ("身份验证",                          .authentication),
    ("后台刷新应用",                 .backgroundRefreshApps),
    ("清除应用缓存",                         .clearAppCache),
    ("获取 Anisette 数据",                     .fetchAnisetteData),
    ("获取应用 ID",                           .fetchAppIDs),
    ("获取源",                            .fetchSource),
    ("安排过期提醒",             .scheduleExpirationWarningNotification),
]

struct OperationsLoggingControlView: View {
    @ObservedObject private var viewModel = OperationsLoggingViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Standalone Steps
                VStack(alignment: .leading, spacing: 8) {
                    Text("独立步骤")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(.horizontal, 16)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(standaloneStepToggles.enumerated()), id: \.element.name) { index, entry in
                            if index > 0 {
                                divider
                            }
                            stepToggle(entry.name, step: entry.step)
                        }
                    }
                    .background(Color.settingsRowBackground)
                    .cornerRadius(14)
                }
                
                // Pipeline Steps
                VStack(alignment: .leading, spacing: 8) {
                    Text("流水线步骤")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(.horizontal, 16)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(pipelineStepToggles.enumerated()), id: \.element.name) { index, entry in
                            if index > 0 {
                                divider
                            }
                            stepToggle(entry.name, step: entry.step)
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
        .navigationTitle("操作日志")
        .navigationBarTitleDisplayMode(.large)
    }

    private func stepToggle(_ title: String, step: some OperationStep) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Toggle("", isOn: Binding(
                get: { OperationsLoggingControl.isStepLoggingEnabled(for: step) },
                set: { value in
                    OperationsLoggingControl.setStepLoggingEnabled(for: step, value: value)
                    viewModel.refresh()
                }
            ))
            .labelsHidden()
            .tint(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 50)
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Color.settingsDivider)
            .frame(height: 0.5)
            .padding(.horizontal, 16)
    }
}

private final class OperationsLoggingViewModel: ObservableObject {
    func refresh() {
        objectWillChange.send()
    }
}
