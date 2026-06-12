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
    @Published var showsUnknownDevices = true
    
    let bleCentralManager: BLECentralManager
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
    
    init(
        bluetoothState: BluetoothState,
        connectionState: BLEConnectionState,
        devices: [BLEDevice],
        showsUnknownDevices: Bool = true
    ) {
        self.bluetoothState = bluetoothState
        self.connectionState = connectionState
        self.devices = devices
        self.showsUnknownDevices = showsUnknownDevices
        self.bleCentralManager = BLECentralManager(startsCentralManager: false)
    }
    
    var visibleDevices: [BLEDevice] {
        guard showsUnknownDevices == false else {
            return devices
        }
        
        return devices.filter { device in
            device.name.isEmpty == false
        }
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
