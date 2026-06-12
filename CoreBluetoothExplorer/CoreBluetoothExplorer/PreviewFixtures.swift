//
//  PreviewFixtures.swift
//  CoreBluetoothExplorer
//
//  Created by Codex on 12/06/2026.
//

import Foundation

enum PreviewFixtures {
    static let heartRateMonitor = BLEDevice(
        id: UUID(uuidString: "A4E6F3B0-B5F6-4DB7-AF8D-1C18C8F5D101")!,
        name: "Polar H10",
        rssi: -42,
        isConnectable: true
    )
    
    static let thermometer = BLEDevice(
        id: UUID(uuidString: "3C17A5A0-9569-4E52-8E3A-F41BB31C7092")!,
        name: "Kitchen Thermometer",
        rssi: -67,
        isConnectable: true
    )
    
    static let unknownBeacon = BLEDevice(
        id: UUID(uuidString: "F8C1A6B5-7921-4F0C-B581-058541EF4C2E")!,
        name: "",
        rssi: -81,
        isConnectable: false
    )
    
    static let devices = [
        heartRateMonitor,
        thermometer,
        unknownBeacon
    ]
    
    static let services = [
        BLEService(
            uuid: "180D",
            characteristics: [
                BLECharacteristic(
                    uuid: "2A37",
                    properties: ["Notify"],
                    latestValue: Data([0x00, 0x48])
                ),
                BLECharacteristic(
                    uuid: "2A38",
                    properties: ["Read"],
                    latestValue: Data([0x02])
                )
            ]
        ),
        BLEService(
            uuid: "180F",
            characteristics: [
                BLECharacteristic(
                    uuid: "2A19",
                    properties: ["Read", "Notify"],
                    latestValue: Data([88])
                )
            ]
        ),
        BLEService(
            uuid: "180A",
            characteristics: [
                BLECharacteristic(
                    uuid: "2A29",
                    properties: ["Read"],
                    latestValue: Data("Nordic Semiconductor".utf8)
                ),
                BLECharacteristic(
                    uuid: "2A26",
                    properties: ["Read"],
                    latestValue: Data("1.4.2".utf8)
                )
            ]
        )
    ]
}
