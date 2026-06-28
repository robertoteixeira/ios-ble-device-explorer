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
    @Published private(set) var operationStatus: BLEOperationStatus = .idle
    @Published private(set) var discoveredDevices: [BLEDevice] = []
    @Published private(set) var services: [BLEService] = []
    
    private var centralManager: CBCentralManager?
    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    private var connectingPeripheral: CBPeripheral?
    private var connectedPeripheral: CBPeripheral?
    private var irrigationPeripheral: CBPeripheral?
    private var discoveredCharacteristics: [String: CBCharacteristic] = [:]
    private var scanMode: BLEScanMode = .explorer
    
    private static let irrigationServiceUUID = CBUUID(
        string: "7b6a0001-4f7a-4f2e-9f1b-91b0f3c7d001"
    )

    private static let firmwareCharacteristicUUID = CBUUID(
        string: "7b6a0002-4f7a-4f2e-9f1b-91b0f3c7d001"
    )
    
    init(startsCentralManager: Bool = true) {
        super.init()
        
        if startsCentralManager {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }
    
    func startScanning() {
        startScanning(mode: .explorer)
    }
    
    func startScanning(mode: BLEScanMode) {
        guard bluetoothState == .poweredOn else { return }
        
        scanMode = mode
        
        discoveredDevices.removeAll()
        discoveredPeripherals.removeAll()
        services.removeAll()
        connectedPeripheral = nil
        irrigationPeripheral = nil
        discoveredCharacteristics.removeAll()
        operationStatus = .idle
        connectionState = .scanning
        
        switch mode {
        case .explorer:
            centralManager?.scanForPeripherals(
                withServices: nil,
                options: [
                    CBCentralManagerScanOptionAllowDuplicatesKey: false
                ]
            )
        case .irrigation:
            centralManager?.scanForPeripherals(
                withServices: [Self.irrigationServiceUUID],
                options: nil
            )
        }
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
        
        if scanMode == .irrigation {
            irrigationPeripheral = peripheral
            irrigationPeripheral?.delegate = self
        }
        
        connectionState = .connecting
        centralManager?.connect(peripheral)
    }
    
    func disconnect() {
        operationStatus = .idle
        
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
            irrigationPeripheral = nil
        }
    }
    
    func readCharacteristic(_ characteristic: BLECharacteristic) {
        guard let connectedPeripheral else {
            operationStatus = .failed("No connected peripheral")
            return
        }
        
        guard let cbCharacteristic = discoveredCharacteristics[characteristic.uuid] else {
            operationStatus = .failed("Characteristic not found")
            return
        }
        
        guard cbCharacteristic.properties.contains(.read) else {
            operationStatus = .failed("Characteristic does not support read")
            return
        }
        
        operationStatus = .inProgress("Reading value")
        connectedPeripheral.readValue(for: cbCharacteristic)
    }
    
    func toggleNotify(for characteristic: BLECharacteristic) {
        guard let connectedPeripheral else {
            operationStatus = .failed("No connected peripheral")
            return
        }
        
        guard let cbCharacteristic = discoveredCharacteristics[characteristic.uuid] else {
            operationStatus = .failed("Characteristic not found")
            return
        }
        
        let supportsNotify = cbCharacteristic.properties.contains(CBCharacteristicProperties.notify)
        let supportsIndicate = cbCharacteristic.properties.contains(CBCharacteristicProperties.indicate)
        
        guard supportsNotify || supportsIndicate else {
            operationStatus = .failed("Characteristic does not support nofity/indicate")
            return
        }
        
        operationStatus = cbCharacteristic.isNotifying
            ? .inProgress("Disabling notifications")
            : .inProgress("Enabling notifications")
        
        connectedPeripheral.setNotifyValue(
            !cbCharacteristic.isNotifying,
            for: cbCharacteristic
        )
    }
    
    func writeCharacteristic(_ characteristic: BLECharacteristic, hexString: String) {
        guard let value = HexDataParser.data(from: hexString) else {
            operationStatus = .failed("Invalid hex value")
            return
        }
        
        guard let connectedPeripheral else {
            operationStatus = .failed("No connected peripheral")
            return
        }
        
        guard let cbCharacteristic = discoveredCharacteristics[characteristic.uuid] else {
            operationStatus = .failed("Characteristic not found")
            return
        }
        
        let supportsWrite = cbCharacteristic.properties.contains(.write)
        let supportsWriteWithoutResponse = cbCharacteristic.properties.contains(.writeWithoutResponse)
        
        guard supportsWrite || supportsWriteWithoutResponse else {
            operationStatus = .failed("Characterist does not support write")
            return
        }
        
        let writeType: CBCharacteristicWriteType = supportsWrite ? .withResponse : .withoutResponse
        
        operationStatus = .inProgress("Writing value")
        
        connectedPeripheral.writeValue(
            value,
            for: cbCharacteristic,
            type: writeType
        )
        
        if writeType == .withoutResponse {
            operationStatus = .succeeded("Write send without response")
        }
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
        
        let advertisedServiceUUIDs = (
            advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
        )?
            .map { $0.uuidString }
            .sorted() ?? []
        
        let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        
        let txPowerLevel = (
            advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber
        )?.intValue
        
        let device = BLEDevice(
            id: peripheral.identifier,
            name: name,
            rssi: RSSI.intValue,
            isConnectable: isConnectable,
            advertisedServiceUUIDs: advertisedServiceUUIDs,
            manufacturerData: manufacturerData,
            txPowerLevel: txPowerLevel
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
        print("BLE didConnect peripheral=\(peripheral.identifier) mode=\(scanMode)")
        
        connectingPeripheral = nil
        connectedPeripheral = peripheral
        
        if scanMode == .irrigation {
            irrigationPeripheral = peripheral
            irrigationPeripheral?.delegate = self
        } else {
            peripheral.delegate = self
        }
        
        connectionState = .discoveringServices
        services.removeAll()
        discoveredCharacteristics.removeAll()
        
        switch scanMode {
        case .explorer:
            peripheral.discoverServices(nil)
        case .irrigation:
            operationStatus = .inProgress("Discovering irrigation service")
            peripheral.discoverServices([Self.irrigationServiceUUID])
        }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        print(
            "BLE didFailToConnect peripheral=\(peripheral.identifier) error=\(error?.localizedDescription ?? "nil")"
        )
        
        connectingPeripheral = nil
        connectionState = .failed(error?.localizedDescription ?? "Failed to connect")
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        print(
            "BLE didDisconnectPeripheral peripheral=\(peripheral.identifier) error=\(error?.localizedDescription ?? "nil")"
        )
        
        connectingPeripheral = nil
        connectedPeripheral = nil
        irrigationPeripheral = nil
        services.removeAll()
        discoveredCharacteristics.removeAll()
        operationStatus = .idle
        
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
        print(
            "BLE didDiscoverServices peripheral=\(peripheral.identifier) mode=\(scanMode) services=\(peripheral.services?.map { $0.uuid.uuidString } ?? []) error=\(error?.localizedDescription ?? "nil")"
        )
        
        if let error {
            connectionState = .failed(error.localizedDescription)
            return
        }
        
        var seenServiceUUIDs = Set<String>()
        let discoveredServices = (peripheral.services ?? []).filter { service in
            seenServiceUUIDs.insert(service.uuid.uuidString).inserted
        }
        
        switch scanMode {
        case .explorer:
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
            
        case .irrigation:
            guard let irrigationService = discoveredServices.first(where: {
                $0.uuid == Self.irrigationServiceUUID
            }) else {
                connectionState = .failed("Irrigation service not found")
                return
            }
            
            services = [
                BLEService(service: irrigationService)
            ]
            
            connectionState = .discoveringCharacteristics
            operationStatus = .inProgress("Discovering firmware characteristic")
            
            peripheral.discoverCharacteristics(
                [Self.firmwareCharacteristicUUID],
                for: irrigationService
            )
        }
        

    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        print(
            "BLE didDiscoverCharacteristicsFor service=\(service.uuid.uuidString) mode=\(scanMode) characteristics=\(service.characteristics?.map { $0.uuid.uuidString } ?? []) error=\(error?.localizedDescription ?? "nil")"
        )
        
        if let error {
            connectionState = .failed(error.localizedDescription)
            return
        }
        
        switch scanMode {
        case .explorer:
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
        case .irrigation:
            guard service.uuid == Self.irrigationServiceUUID else {
                return
            }
            
            guard let firmwareCharacteristic = service.characteristics?.first(where: {
                $0.uuid == Self.firmwareCharacteristicUUID
            }) else {
                connectionState = .failed("Firmware characteristc not found")
                return
            }
            
            discoveredCharacteristics = [
                firmwareCharacteristic.uuid.uuidString: firmwareCharacteristic
            ]
            
            let mappedCharacteristic = BLECharacteristic(characteristic: firmwareCharacteristic)
            
            if let index = services.firstIndex(where: { $0.uuid == service.uuid.uuidString }) {
                services[index].characteristics = [mappedCharacteristic]
            }
            
            connectionState = .ready
            operationStatus = .inProgress("Reading firmware version")
            
            peripheral.readValue(for: firmwareCharacteristic)
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error {
            print(
                "BLE didUpdateValueFor characteristic=\(characteristic.uuid.uuidString) mode=\(scanMode) error=\(error.localizedDescription)"
            )
            operationStatus = .failed(error.localizedDescription)
            return
        }
        
        print(
            "BLE didUpdateValueFor characteristic=\(characteristic.uuid.uuidString) mode=\(scanMode) value=\(characteristic.value?.hexDisplay ?? "nil") error=nil"
        )
        
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
        
        switch scanMode {
        case .explorer:
            operationStatus = .succeeded("Value updated")
        case .irrigation:
            guard characteristic.uuid == Self.firmwareCharacteristicUUID else {
                return
            }
            
            if let data = characteristic.value,
               let firmwareVersion = String(data: data, encoding: .utf8) {
                operationStatus = .succeeded("Firmware: \(firmwareVersion)")
                print("Firmware:", firmwareVersion)
            } else {
                operationStatus = .failed("Unable to decode firmware version")
            }
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error {
            operationStatus = .failed(error.localizedDescription)
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
        
        operationStatus = updatedCharacteristic.isNotifying
        ? .succeeded("Notifications enabled")
        : .succeeded("Notifications disabled")
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error {
            operationStatus = .failed(error.localizedDescription)
            return
        }
        
        operationStatus = .succeeded("Write succeeded")
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
