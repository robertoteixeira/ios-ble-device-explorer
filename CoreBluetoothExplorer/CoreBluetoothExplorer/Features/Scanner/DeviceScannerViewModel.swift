//
//  DeviceScannerViewModel.swift
//  CoreBluetoothExplorer
//
//  Created by Roberto Teixeira on 05/06/2026.
//

import Foundation
import Combine

@MainActor
final class DeviceScannerViewModel: ObservableObject {
    @Published private(set) var bluetoothState: BluetoothState = .unknown
    @Published private(set) var connectionState: BLEConnectionState = .disconnected
    @Published private(set) var devices: [BLEDevice] = []
    
    private let bleCentralManager: BLECentralManager
    private var cancellables: Set<AnyCancellable> = []
    
    init(bleCentralManager: BLECentralManager) {
        self.bleCentralManager = bleCentralManager
        
        bleCentralManager.$bluetoothState
            .receive(on: DispatchQueue.main)
            .assign(to: &$bluetoothState)
        
        bleCentralManager.$connectionState
            .receive(on: DispatchQueue.main)
            .assign(to: &$connectionState)
        
        bleCentralManager.$discoveredDevices
            .receive(on: DispatchQueue.main)
            .assign(to: &$devices)
    }
    
    func startScanning() {
        bleCentralManager.startScanning()
    }
    
    func stopScanning() {
        bleCentralManager.stopScanning()
    }
    
    func connect(to device: BLEDevice) {
        bleCentralManager.connect(to: device)
    }
}
