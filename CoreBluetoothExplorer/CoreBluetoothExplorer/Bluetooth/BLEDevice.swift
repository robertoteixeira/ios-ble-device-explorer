//
//  BLEDevice.swift
//  CoreBluetoothExplorer
//
//  Created by Roberto Teixeira on 05/06/2026.
//

import Foundation

struct BLEDevice: Identifiable, Equatable {
    let id: UUID
    let name: String
    let rssi: Int
    let isConnectable: Bool?
    let advertisedServiceUUIDs: [String]
    let manufacturerData: Data?
    let txPowerLevel: Int?
    
    var displayName: String {
        name.isEmpty ? "Unknown Device" : name
    }
    
    init(
        id: UUID,
        name: String,
        rssi: Int,
        isConnectable: Bool?,
        advertisedServiceUUIDs: [String] = [],
        manufacturerData: Data? = nil,
        txPowerLevel: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.rssi = rssi
        self.isConnectable = isConnectable
        self.advertisedServiceUUIDs = advertisedServiceUUIDs
        self.manufacturerData = manufacturerData
        self.txPowerLevel = txPowerLevel
    }
}
