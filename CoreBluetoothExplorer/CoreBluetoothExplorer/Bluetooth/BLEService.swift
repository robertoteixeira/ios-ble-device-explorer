//
//  BLEService.swift
//  CoreBluetoothExplorer
//
//  Created by Roberto Teixeira on 06/06/2026.
//

import Foundation
import CoreBluetooth

struct BLEService: Identifiable, Equatable {
    let id: String
    let uuid: String
    var characteristics: [BLECharacteristic]
    
    init(
        uuid: String,
        characteristics: [BLECharacteristic] = []
    ) {
        self.id = uuid
        self.uuid = uuid
        self.characteristics = characteristics
    }
    
    init(service: CBService, characteristics: [BLECharacteristic] = []) {
        self.id = service.uuid.uuidString
        self.uuid = service.uuid.uuidString
        self.characteristics = characteristics
    }
}
