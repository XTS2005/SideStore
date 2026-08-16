//
//  WirelessPairManager.swift
//  SideStore
//
//  Created by Magesh K on 04/07/26.
//  Copyright © 2026 SideStore. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class WirelessPairManager: ObservableObject {
    static let shared = WirelessPairManager()
    
    @Published var statusText = "准备配对"
    @Published var subStatusText = "轻点“开始”即可在本地网络上广播此设备。"
    @Published var pinCode: String? = nil
    @Published var isAdvertising = false
    @Published var pairedDevice: MinimuxerPairedDevice? = nil
    @Published var errorMessage: String? = nil
    @Published var serviceID: String? = nil
    @Published var port: Int? = nil
    
    private let pairing = wirelessPairing
    private var startTask: Task<Void, Never>? = nil
    
    private init() {
        // Setup closures once
        pairing.onReadyToPair = { [weak self] (serviceID: String, port: Int) in
            Task { @MainActor in
                guard let self = self else { return }
                self.serviceID = serviceID
                self.port = port
                self.statusText = "正在广播服务器…"
                self.subStatusText = "请确保两台设备位于同一 Wi-Fi 网络。"
            }
        }
        
        pairing.onPinReceived = { [weak self] (pin: String) in
            Task { @MainActor in
                guard let self = self else { return }
                self.pinCode = pin
                self.statusText = "设备已连接"
                self.subStatusText = "请在另一台设备的设置界面中输入下方显示的配对码。"
            }
        }
    }
    
    func togglePairing() {
        if isAdvertising {
            stopPairing()
        } else {
            startPairing()
        }
    }
    
    func startPairing() {
        startTask?.cancel()
        
        isAdvertising = true
        pinCode = nil
        errorMessage = nil
        serviceID = nil
        port = nil
        
        // Debounce the "Waiting..." status text by 200ms
        let debounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
            guard !Task.isCancelled else { return }
            guard isAdvertising && serviceID == nil else { return }
            statusText = "正在等待连接…"
            subStatusText = "请在 Apple TV / Vision Pro / 主机设备上打开“远程配对”以发现此服务器。"
        }
        startTask = debounceTask
        
        let pairingFile = pairingFilePath()
        
        pairing.start(outPath: pairingFile) { [weak self] (result: Result<MinimuxerPairedDevice, Swift.Error>) in
            Task { @MainActor in
                guard let self = self else { return }
                debounceTask.cancel()
                guard self.isAdvertising else { return }
                self.isAdvertising = false
                self.pinCode = nil
                self.serviceID = nil
                self.port = nil
                
                switch result {
                case .success(let device):
                    self.pairedDevice = device
                    self.statusText = "成功！"
                    self.subStatusText = "已成功与 \(device.name)（\(device.model)）配对！\n配对文件已保存到文稿。"
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.statusText = "配对失败"
                    self.subStatusText = "配对过程中发生错误。"
                }
            }
        }
    }
    
    func stopPairing() {
        pairing.stop()
        startTask?.cancel()
        startTask = nil
        
        isAdvertising = false
        statusText = "准备配对"
        subStatusText = "轻点“开始”即可在本地网络上广播此设备。"
        pinCode = nil
        errorMessage = nil
        serviceID = nil
        port = nil
    }
    
    private func pairingFilePath() -> String {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("rp_pairing_file.plist").path
    }
}
