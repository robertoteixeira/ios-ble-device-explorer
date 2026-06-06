//
//  BLECharacteristic.swift
//  CoreBluetoothExplorer
//
//  Created by Roberto Teixeira on 06/06/2026.
//

import Foundation
import CoreBluetooth

struct BLECharacteristic: Identifiable, Equatable {
    let id: String
    let uuid: String
    let properties: [String]
    let latestValue: Data?
    
    init(characteristic: CBCharacteristic) {
        self.id = characteristic.uuid.uuidString
        self.uuid = characteristic.uuid.uuidString
        self.properties = characteristic.properties.displayNames
        self.latestValue = characteristic.value
    }
}

private extension CBCharacteristicProperties {
    var displayNames: [String] {
        var names: [String] = []
        
        if contains(.read) {
            names.append("Read")
        }
        
        if contains(.write) {
            names.append("Write")
        }
        
        if contains(.writeWithoutResponse) {
            names.append("Write Without Response")
        }
        
        if contains(.notify) {
            names.append("Notify")
        }
        
        if contains(.indicate) {
            names.append("Indicate")
        }
        
        if contains(.broadcast) {
            names.append("Broadcast")
        }
        
        if contains(.authenticatedSignedWrites) {
            names.append("Signed Write")
        }
        
        if contains(.extendedProperties) {
            names.append("Extended")
        }
        
        if contains(.notifyEncryptionRequired) {
            names.append("Read")
        }
        
        if contains(.indicateEncryptionRequired) {
            names.append("Indicate Encryption Required")
        }
        
        return names
    }
}
