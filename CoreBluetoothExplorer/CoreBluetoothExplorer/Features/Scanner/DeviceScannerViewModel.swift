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
    @Published var showsOnlyConnectableDevices = false
    
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
        showsUnknownDevices: Bool = true,
        showsOnlyConnectableDevices: Bool = false
    ) {
        self.bluetoothState = bluetoothState
        self.connectionState = connectionState
        self.devices = devices
        self.showsUnknownDevices = showsUnknownDevices
        self.showsOnlyConnectableDevices = showsOnlyConnectableDevices
        self.bleCentralManager = BLECentralManager(startsCentralManager: false)
    }
    
    var visibleDevices: [BLEDevice] {
        var filteredDevices = devices
        
        if showsUnknownDevices == false {
            filteredDevices = filteredDevices.filter { device in
                device.name.isEmpty == false
            }
        }
        
        if showsOnlyConnectableDevices {
            filteredDevices = filteredDevices.filter { device in
                device.isConnectable == true
            }
        }
        
        return filteredDevices
    }
    
    func startScanning() {
        bleCentralManager.startScanning()
    }
    
    func startIrrigationScanning() {
        bleCentralManager.startScanning(mode: .irrigation)
    }
    
    func stopScanning() {
        bleCentralManager.stopScanning()
    }
    
    func connect(to device: BLEDevice) {
        bleCentralManager.connect(to: device)
    }
}
