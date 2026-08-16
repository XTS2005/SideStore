//
//  ContentView.swift
//  SideBackup
//
//  Created by Magesh K on 2/7/26.
//  Copyright © 2026 SideStore. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var state = AppState()
    
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            VStack(spacing: 22) {
                if let error = state.bootCheckError {
                    // Hard boot failure — App Group not accessible
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.orange)
                    
                    Text(NSLocalizedString("SideBackup 无法启动", comment: ""))
                        .font(.title2.bold())
                        .foregroundColor(Color("Text"))
                        .multilineTextAlignment(.center)
                    
                    Text(error.localizedDescription)
                        .font(.callout)
                        .foregroundColor(Color("Text").opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    
                } else if let operation = state.currentOperation {
                    Text(operation == .backup ? "正在备份应用数据…" : "正在恢复应用数据…")
                        .font(.title2)
                        .foregroundColor(Color("Text"))
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 10) {
                        ProgressView(value: state.progressFraction)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color("Text")))
                            .frame(height: 8)
                            .clipShape(Capsule())
                        
                        if !state.progressText.isEmpty {
                            Text(state.progressText)
                                .font(.callout.monospacedDigit())
                                .foregroundColor(Color("Text").opacity(0.85))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 16)
                } else {
                    Text(String(format: NSLocalizedString("%@ 当前处于非活跃状态。", comment: ""),
                                Bundle.main.appName ?? NSLocalizedString("应用", comment: "")))
                        .font(.title2)
                        .foregroundColor(Color("Text"))
                        .multilineTextAlignment(.center)
                    
                    Text(String(format: NSLocalizedString("在 SideStore 中刷新 %@ 以继续使用它。", comment: ""),
                                Bundle.main.appName ?? NSLocalizedString("此应用", comment: "")))
                        .font(.body)
                        .foregroundColor(Color("Text"))
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}

