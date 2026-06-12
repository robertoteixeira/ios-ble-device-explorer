//
//  BLEServiceSectionView.swift
//  CoreBluetoothExplorer
//
//  Created by Roberto Teixeira on 06/06/2026.
//

import SwiftUI

struct BLEServiceSectionView: View {
    let service: BLEService
    let onReadCharacteristic: (BLECharacteristic) -> Void
    let onToggleNotify: (BLECharacteristic) -> Void
    
    var body: some View {
        Section {
            if service.characteristics.isEmpty {
                Text("No characteristics discovered")
            } else {
                ForEach(service.characteristics) { characteristic in
                    VStack(alignment: .leading, spacing: 6) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(KnownBLEUUID.displayName(for: characteristic.uuid))
                                .font(.headline)
                                .bold()
                            
                            if KnownBLEUUID.name(for: characteristic.uuid) != nil {
                                Text(characteristic.uuid)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if characteristic.properties.isEmpty {
                            Text("No properties")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(characteristic.properties.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let latestValue = characteristic.latestValue {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Value")
                                    .font(.caption)
                                    .bold()
                                
                                if let decodedValue = BLEValueDecoder.decodedValue(
                                    uuid: characteristic.uuid,
                                    data: latestValue
                                ) {
                                    Text(decodedValue)
                                        .font(.caption)
                                        .foregroundStyle(.primary)
                                        .textSelection(.enabled)
                                    
                                    Text("Raw: \(latestValue.hexDisplay)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                } else {
                                    Text(latestValue.readableDisplay)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                        
                        if characteristic.properties.contains("Read") {
                            Button("Read") {
                                onReadCharacteristic(characteristic)
                            }
                            .font(.caption)
                        }
                        
                        if characteristic.properties.contains("Notify") || characteristic.properties.contains("Indicate") {
                            Button("Notify") {
                                onToggleNotify(characteristic)
                            }
                            .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        } header: {
            Text("Service \(KnownBLEUUID.displayName(for: service.uuid))")
        }
    }
}
