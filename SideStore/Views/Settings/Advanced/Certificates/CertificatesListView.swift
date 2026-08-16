//
//  CertificatesListView.swift
//  SideStore
//
//  Created by Magesh K on 2026-07-03.
//  Copyright © 2026 SideStore. All rights reserved.
//

import SwiftUI
@preconcurrency import AltSign

struct CertificatesListView: View {
    @ObservedObject var viewModel: CertificatesViewModel
    
    var onRowTap:     (ALTX509Certificate) -> Void
    var onRevoke:     (ALTX509Certificate) -> Void
    var onExportP12:  (ALTX509Certificate) -> Void
    var onClearKey:   (ALTX509Certificate) -> Void
    var onAddKeyBin:  (ALTX509Certificate) -> Void
    var onAddKeyText: (ALTX509Certificate) -> Void
    var onDelete:     (ALTX509Certificate) -> Void
    
    var body: some View {
        if viewModel.certificates.isEmpty {
            Section(header: Text("全部证书")) {
                if viewModel.isLoading {
                    Text("正在获取证书…").foregroundColor(.secondary)
                } else {
                    Text("未找到本地证书。").foregroundColor(.secondary)
                }
            }
        } else {
            ForEach(viewModel.groupedCertificatesList) { group in
                Section {
                    ForEach(group.certificates, id: \.serialNumber) { cert in
                        CertificateRowView(
                            cert:        cert,
                            viewModel:   viewModel,
                            onRevoke:    { onRevoke(cert) },
                            onExportP12: { onExportP12(cert) },
                            onClearKey:  { onClearKey(cert) },
                            onAddKeyBin: { onAddKeyBin(cert) },
                            onAddKeyText:{ onAddKeyText(cert) },
                            onDelete:    { onDelete(cert) }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { onRowTap(cert) }
                    }
                } header: {
                    CertGroupHeaderView(group: group, viewModel: viewModel)
                } footer: {
                    if group.id == viewModel.groupedCertificatesList.last?.id {
                        Text("后缀 (R) 表示该证书已在 Apple 的开发者门户上远程注册。")
                    }
                }
            }
        }
    }
}

private struct CertGroupHeaderView: View {
    let group: GroupedCertificates
    @ObservedObject var viewModel: CertificatesViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Text(group.name)
            Spacer()
            Menu {
                ForEach(SortOption.allCases) { option in
                    SwiftUI.Button {
                        if viewModel.currentSort == option { viewModel.isAscending.toggle() }
                        else { viewModel.currentSort = option; viewModel.isAscending = (option == .name) }
                    } label: {
                        if viewModel.currentSort == option {
                            Label("\(option.rawValue) \(viewModel.isAscending ? "↑" : "↓")", systemImage: "checkmark")
                        } else {
                            Text(option.rawValue)
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down").font(.system(size: 13)).foregroundColor(.accentColor)
            }
            Menu {
                Picker("分组依据", selection: $viewModel.currentGroup) {
                    ForEach(GroupOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            } label: {
                Image(systemName: "rectangle.3.group").font(.system(size: 13)).foregroundColor(.accentColor)
            }
            SwiftUI.Button {
                viewModel.isSectionHideActive.toggle()
            } label: {
                Image(systemName: viewModel.isSectionHideActive ? "eye.slash" : "eye")
                    .font(.subheadline)
                    .foregroundColor(viewModel.isGlobalHideActive ? .gray : .accentColor)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isGlobalHideActive)
        }
    }
}
