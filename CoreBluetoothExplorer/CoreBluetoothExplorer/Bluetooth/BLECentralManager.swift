//
//  BLECentralManager.swift
//  CoreBluetoothExplorer
//
//  Created by Roberto Teixeira on 05/06/2026.
//

import Foundation
import CoreBluetooth

final class BLECentralManager: NSObject, ObservableObject {
    @Published private(set) var bluetoothState: BluetoothState = .unknown
    @Published private(set) var connectionState: BLEConnectionState = .disconnected
    @Published private(set) var discoveredDevices: [BLEDevice] = []
    @Published private(set) var services: [BLEService] = []
    
    private var centralManager: CBCentralManager?
    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    private var connectedPeripheral: CBPeripheral?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        guard bluetoothState == .poweredOn else { return }
        
        discoveredDevices.removeAll()
        discoveredPeripherals.removeAll()
        services.removeAll()
        connectedPeripheral = nil
        
        connectionState = .scanning
        
        centralManager?.scanForPeripherals(
            withServices: nil,
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false
            ]
        )
    }
    
    func stopScanning() {
        centralManager?.stopScan()
        
        if connectionState == .scanning {
            connectionState = .disconnected
        }
    }
    
    func connect(to device: BLEDevice) {
        guard let peripheral = discoveredPeripherals[device.id] else {
            connectionState = .failed("Peripheral not found")
            return
        }
        
        stopScanning()
        connectionState = .connecting
        centralManager?.connect(peripheral)
    }
}

// MARK: - CBCentralManagerDelegate
extension BLECentralManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = BluetoothState(central.state)
        
        if bluetoothState != .poweredOn {
            connectionState = .disconnected
            discoveredDevices.removeAll()
            discoveredPeripherals.removeAll()
        }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        discoveredPeripherals[peripheral.identifier] = peripheral
        
        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = localName ?? peripheral.name ?? ""
        
        let isConnectable = advertisementData[CBAdvertisementDataIsConnectable] as? Bool
        
        let device = BLEDevice(
            id: peripheral.identifier,
            name: name,
            rssi: RSSI.intValue,
            isConnectable: isConnectable
        )
        
        if let index = discoveredDevices.firstIndex(where: { $0.id == device.id }) {
            discoveredDevices[index] = device
        } else {
            discoveredDevices.append(device)
        }
        
        discoveredDevices.sort { $0.rssi > $1.rssi }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        connectedPeripheral = peripheral
        peripheral.delegate = self
        
        connectionState = .discoveringServices
        services.removeAll()
        
        peripheral.discoverServices(nil)
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        connectionState = .failed(error?.localizedDescription ?? "Failed to connect")
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        connectedPeripheral = nil
        
        if let error {
            connectionState = .failed(error.localizedDescription)
        } else {
            connectionState = .disconnected
        }
    }
}

// MARK: - CBPeripheralDelegate
extension BLECentralManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            connectionState = .failed(error.localizedDescription)
            return
        }
        
        let discoveredServices = peripheral.services ?? []
        
        services = discoveredServices.map {
            BLEService(service: $0)
        }
        
        guard !discoveredServices.isEmpty else {
            connectionState = .ready
            return
        }
        
        connectionState = .discoveringCharacteristics
        
        for service in discoveredServices {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        if let error {
            connectionState = .failed(error.localizedDescription)
            return
        }
        
        let characteristics = service.characteristics ?? []
        let mappedCharacteristics = characteristics.map {
            BLECharacteristic(characteristic: $0)
        }
        
        if let index = services.firstIndex(where: { $0.uuid == service.uuid.uuidString }) {
            services[index].characteristics = mappedCharacteristics
        }
        
        let allServicesHaveCharacteristics = peripheral.services?.allSatisfy { service in
            service.characteristics != nil
        } ?? true
        
        if allServicesHaveCharacteristics {
            connectionState = .ready
        }
    }
}


// MARK: - Mapping
private extension BluetoothState {
    init(_ state: CBManagerState) {
        switch state {
        case .unknown:
            self = .unknown
        case .resetting:
            self = .resetting
        case .unsupported:
            self = .unsupported
        case .unauthorized:
            self = .unauthorized
        case .poweredOff:
            self = .poweredOff
        case .poweredOn:
            self = .poweredOn
        @unknown default:
            self = .unknown
        }
    }
}
