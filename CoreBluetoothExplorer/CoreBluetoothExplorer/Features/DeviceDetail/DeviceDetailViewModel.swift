//
//  DeviceDetailViewModel.swift
//  CoreBluetoothExplorer
//
//  Created by Roberto Teixeira on 06/06/2026.
//

import Foundation
import Combine

@MainActor
final class DeviceDetailViewModel: ObservableObject {
    @Published private(set) var connectionState: BLEConnectionState = .disconnected
    @Published private(set) var services: [BLEService] = []
    
    let device: BLEDevice
    
    private let bleCentralManager: BLECentralManager?
    
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
    
    init(
        device: BLEDevice,
        connectionState: BLEConnectionState,
        services: [BLEService]
    ) {
        self.device = device
        self.connectionState = connectionState
        self.services = services
        self.bleCentralManager = nil
    }
    
    func readCharacteristic(_ characteristic: BLECharacteristic) {
        bleCentralManager?.readCharacteristic(characteristic)
    }
    
    func toggleNotify(for characteristic: BLECharacteristic) {
        bleCentralManager?.toggleNotify(for: characteristic)
    }
    
    func writeCharacteristic(_ characteristic: BLECharacteristic, hexString: String) {
        bleCentralManager?.writeCharacteristic(characteristic, hexString: hexString)
    }
    
    func disconnect() {
        bleCentralManager?.disconnect()
    }
}
