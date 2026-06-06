//
//  DeviceDetailViewModel.swift.swift
//  CoreBluetoothExplorer
//
//  Created by Roberto Teixeira on 06/06/2026.
//

import Foundation

@MainActor
final class DeviceDetailViewModel: ObservableObject {
    @Published private(set) var connectionState: BLEConnectionState = .disconnected
    @Published private(set) var services: [BLEService] = []
    
    let device: BLEDevice
    
    private let bleCentralManager: BLECentralManager
    
    init(
        device: BLEDevice,
        bleCentralManager: BLECentralManager
    ) {
        self.device = device
        self.bleCentralManager = bleCentralManager
        
        bleCentralManager.$connectionState
            .receive(on: DispatchQueue.main)
            .assign(to: &$connectionState)
        
        bleCentralManager.$services
            .receive(on: DispatchQueue.main)
            .assign(to: &$services)
    }
}
