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
    
    var displayName: String {
        name.isEmpty ? "Unknown Device" : name
    }
}
