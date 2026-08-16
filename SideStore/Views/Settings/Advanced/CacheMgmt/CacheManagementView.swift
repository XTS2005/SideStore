//
//  CacheManagementView.swift
//  SideStore
//
//  Created by Magesh K on 2026-06-29.
//  Copyright © 2026 SideStore. All rights reserved.
//

import SwiftUI

struct CacheManagementView: View {
    @StateObject private var viewModel = CacheViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.internalApps.isEmpty && viewModel.resignedApps.isEmpty {
                ProgressView("正在加载缓存…")
                    .scaleEffect(1.1)
            } else {
                List {
                    Section(header: Text("内部应用缓存"), footer: Text("存储在 SideStore 私有容器中的已解压应用包缓存。这些缓存用于自动后台刷新和重新签名。")) {
                        if viewModel.internalApps.isEmpty {
                            Text("没有缓存内部应用。")
                                .foregroundColor(.secondary)
                                .italic()
                                .padding(.vertical, 4)
                        } else {
                            ForEach(viewModel.internalApps) { item in
                                CacheItemRow(item: item, onExport: {
                                    viewModel.activeExportURL = item.url
                                }, onDelete: {
                                    viewModel.itemToDelete = item
                                })
                            }
                            .onDelete { indexSet in
                                if let index = indexSet.first {
                                    viewModel.itemToDelete = viewModel.internalApps[index]
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("已导出的重新签名应用"), footer: Text("导出到你的“文稿”文件夹中的已签名应用包副本。可通过“文件”应用共享或取回。")) {
                        if viewModel.resignedApps.isEmpty {
                            Text("没有已导出的重新签名应用。")
                                .foregroundColor(.secondary)
                                .italic()
                                .padding(.vertical, 4)
                        } else {
                            ForEach(viewModel.resignedApps) { item in
                                CacheItemRow(item: item, onExport: {
                                    viewModel.activeExportURL = item.url
                                }, onDelete: {
                                    viewModel.deleteItem(item)
                                })
                            }
                            .onDelete { indexSet in
                                if let index = indexSet.first {
                                    viewModel.deleteItem(viewModel.resignedApps[index])
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            
            if viewModel.isLoading && !(viewModel.internalApps.isEmpty && viewModel.resignedApps.isEmpty) {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                
                ProgressView()
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
                    .shadow(radius: 10)
            }
        }
        .navigationTitle("缓存管理")
        .onAppear {
            viewModel.loadCacheItems()
        }
        .alert(isPresented: $viewModel.showErrorAlert) {
            Alert(
                title: Text("错误"),
                message: Text(viewModel.errorMessage ?? "发生未知错误。"),
                dismissButton: .default(Text("确定"))
            )
        }
        .alert(isPresented: $viewModel.showDeleteAlert) {
            let appName = viewModel.itemToDelete?.name ?? "此应用"
            return Alert(
                title: Text("删除缓存的应用？"),
                message: Text("如果删除，SideStore 在重新安装、备份、重新签名或刷新过程中将需要原始 IPA 文件。你确定要删除“\(appName)”的缓存应用包吗？"),
                primaryButton: .destructive(Text("删除")) {
                    if let item = viewModel.itemToDelete {
                        viewModel.deleteItem(item)
                    }
                },
                secondaryButton: .cancel {
                    viewModel.itemToDelete = nil
                }
            )
        }
        .sheet(isPresented: Binding<Bool>(
            get: { viewModel.activeExportURL != nil },
            set: { if !$0 { viewModel.activeExportURL = nil } }
        )) {
            if let url = viewModel.activeExportURL {
                ActivityViewController(activityItems: [url])
            }
        }
    }
}

struct CacheItemRow: View {
    let item: CacheItem
    let onExport: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            if let image = item.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)
            } else {
                Image(systemName: "square.dashed")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(.secondary)
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                if let bundleID = item.bundleIdentifier {
                    Text(bundleID)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(item.sizeString)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .contextMenu {
            SwiftUI.Button(action: onExport) {
                Label("导出 / 分享", systemImage: "square.and.arrow.up")
            }
            SwiftUI.Button(role: .destructive, action: onDelete) {
                Label("删除缓存", systemImage: "trash")
            }
        }
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
