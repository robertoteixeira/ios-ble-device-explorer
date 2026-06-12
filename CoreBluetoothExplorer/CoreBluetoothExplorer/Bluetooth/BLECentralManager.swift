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
    private var connectingPeripheral: CBPeripheral?
    private var connectedPeripheral: CBPeripheral?
    private var discoveredCharacteristics: [String: CBCharacteristic] = [:]
    
    init(startsCentralManager: Bool = true) {
        super.init()
        
        if startsCentralManager {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }
    
    func startScanning() {
        guard bluetoothState == .poweredOn else { return }
        
        discoveredDevices.removeAll()
        discoveredPeripherals.removeAll()
        services.removeAll()
        connectedPeripheral = nil
        discoveredCharacteristics.removeAll()
        
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
        connectingPeripheral = peripheral
        connectionState = .connecting
        centralManager?.connect(peripheral)
    }
    
    func disconnect() {
        if let connectingPeripheral {
            centralManager?.cancelPeripheralConnection(connectingPeripheral)
            self.connectingPeripheral = nil
        }
        
        if let connectedPeripheral {
            centralManager?.cancelPeripheralConnection(connectedPeripheral)
        } else {
            connectionState = .disconnected
            services.removeAll()
            discoveredCharacteristics.removeAll()
        }
    }
    
    func readCharacteristic(_ characteristic: BLECharacteristic) {
        guard let connectedPeripheral else {
            connectionState = .failed("No connected peripheral")
            return
        }
        
        guard let cbCharacteristic = discoveredCharacteristics[characteristic.uuid] else {
            connectionState = .failed("Characteristic not found")
            return
        }
        
        guard cbCharacteristic.properties.contains(.read) else {
            connectionState = .failed("Characteristic does not support read")
            return
        }
        
        connectedPeripheral.readValue(for: cbCharacteristic)
    }
    
    func toggleNotify(for characteristic: BLECharacteristic) {
        guard let connectedPeripheral else {
            connectionState = .failed("No connected peripheral")
            return
        }
        
        guard let cbCharacteristic = discoveredCharacteristics[characteristic.uuid] else {
            connectionState = .failed("Characteristic not found")
            return
        }
        
        let supportsNotify = cbCharacteristic.properties.contains(CBCharacteristicProperties.notify)
        let supportsIndicate = cbCharacteristic.properties.contains(CBCharacteristicProperties.indicate)
        
        guard supportsNotify || supportsIndicate else {
            connectionState = .failed("Characteristic does not support nofity/indicate")
            return
        }
        
        connectedPeripheral.setNotifyValue(
            !cbCharacteristic.isNotifying,
            for: cbCharacteristic
        )
    }
    
    func writeCharacteristic(_ characteristic: BLECharacteristic, hexString: String) {
        guard let value = HexDataParser.data(from: hexString) else {
            connectionState = .failed("Invalid hex value")
            return
        }
        
        guard let connectedPeripheral else {
            connectionState = .failed("No connected peripheral")
            return
        }
        
        guard let cbCharacteristic = discoveredCharacteristics[characteristic.uuid] else {
            connectionState = .failed("Characteristic not found")
            return
        }
        
        let supportsWrite = cbCharacteristic.properties.contains(.write)
        let supportsWriteWithoutResponse = cbCharacteristic.properties.contains(.writeWithoutResponse)
        
        guard supportsWrite || supportsWriteWithoutResponse else {
            connectionState = .failed("Characterist does not support write")
            return
        }
        
        let writeType: CBCharacteristicWriteType = supportsWrite ? .withResponse : .withoutResponse
        
        connectedPeripheral.writeValue(
            value,
            for: cbCharacteristic,
            type: writeType
        )
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
        connectingPeripheral = nil
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
        connectingPeripheral = nil
        connectionState = .failed(error?.localizedDescription ?? "Failed to connect")
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        connectingPeripheral = nil
        connectedPeripheral = nil
        services.removeAll()
        discoveredCharacteristics.removeAll()
        
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
        
        for characteristic in characteristics {
            discoveredCharacteristics[characteristic.uuid.uuidString] = characteristic
        }
        
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
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error {
            connectionState = .failed(error.localizedDescription)
            return
        }
        
        let updatedCharacteristic = BLECharacteristic(characteristic: characteristic)
        
        services = services.map { service in
            var updatedService = service
            
            updatedService.characteristics = service.characteristics.map { existingCharacteristic in
                if existingCharacteristic.uuid == updatedCharacteristic.uuid {
                    return updatedCharacteristic
                }
                
                return existingCharacteristic
            }
            
            return updatedService
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error {
            connectionState = .failed(error.localizedDescription)
            return
        }
        
        let updatedCharacteristic = BLECharacteristic(characteristic: characteristic)
        
        services = services.map { service in
            var updatedService = service
            
            updatedService.characteristics = service.characteristics.map { existingCharacteristic in
                if existingCharacteristic.uuid == updatedCharacteristic.uuid {
                    return updatedCharacteristic
                }
                
                return existingCharacteristic
            }
            return updatedService
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error {
            connectionState = .failed(error.localizedDescription)
            return
        }
        
        connectionState = .ready
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
