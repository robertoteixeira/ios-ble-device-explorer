//
//  BLECharacteristicRowView.swift
//  CoreBluetoothExplorer
//
//  Created by Roberto Teixeira on 25/06/2026.
//

import SwiftUI

struct BLECharacteristicRowView: View {
    let characteristic: BLECharacteristic
    let onReadCharacteristic: (BLECharacteristic) -> Void
    let onToggleNotify: (BLECharacteristic) -> Void
    let onWriteCharacteristic: (BLECharacteristic, String) -> Void
    
    @State private var writeHexValue = ""
    
    var body: some View {
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
                    .background(.gray.opacity(0.1))
            } else {
                Text(characteristic.properties.joined(separator: " | "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(4)
                    .background(.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            if let latestValue = characteristic.latestValue {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Value:")
                        .font(.caption)
                        .bold()
                    
                    Text("Raw: \(latestValue.hexDisplay)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    
                    if let decodedValue = BLEValueDecoder.decodedValue(
                        uuid: characteristic.uuid,
                        data: latestValue
                    ) {
                        Text(decodedValue)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .textSelection(.enabled)
                    } else if let utf8Display = latestValue.utf8Display {
                        Text(utf8Display)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 16) {
                    if characteristic.properties.contains("Read") {
                        Button("Read") {
                            onReadCharacteristic(characteristic)
                        }
                        .font(.caption)
                    }
                    
                    if characteristic.properties.contains("Notify") || characteristic.properties.contains("Indicate") {
                        Text(characteristic.isNotifying ? "Notifications enabled" : "Notifications disabled")
                            .font(.caption2)
                            .foregroundStyle(characteristic.isNotifying ? .green : .secondary)
                        
                        Button(characteristic.isNotifying ? "Stop Notify" : "Notify") {
                            onToggleNotify(characteristic)
                        }
                        .font(.caption)
                    }
                }
                
                if characteristic.properties.contains("Write") || characteristic.properties.contains("Write Without Response") {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            TextField("Hex bytes", text: $writeHexValue)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                            
                            Button("Write") {
                                onWriteCharacteristic(characteristic, writeHexValue)
                            }
                            .font(.caption)
                            .disabled(!isValidHexValue)
                        }
                        
                        if shouldShowInvalidHexHint {
                            Text("Enter an even number of hex digits")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var isValidHexValue: Bool {
        HexDataParser.data(from: writeHexValue) != nil
    }
    
    private var shouldShowInvalidHexHint: Bool {
        guard writeHexValue.isEmpty == false else {
            return false
        }
        
        return HexDataParser.data(from: writeHexValue) == nil
    }
}

struct BLECharacteristicRowView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            BLECharacteristicRowView(
                characteristic: PreviewFixtures.services[1].characteristics[0],
                onReadCharacteristic: { _ in },
                onToggleNotify: { _ in },
                onWriteCharacteristic: { _, _ in }
            )
        }
    }
}
