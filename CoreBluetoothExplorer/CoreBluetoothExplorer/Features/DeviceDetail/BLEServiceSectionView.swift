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
    let onWriteCharacteristic: (BLECharacteristic, String) -> Void
    
    @State private var writeHexValues: [String: String] = [:]
    
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
                                HStack(alignment: .top, spacing: 4) {
                                    Text("Value:")
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
                                    } else if let utf8Display = latestValue.utf8Display {
                                        Text(utf8Display)
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                            .textSelection(.enabled)
                                    }
                                }
                                HStack(alignment: .top, spacing: 4) {
                                    Text("Raw:")
                                        .font(.caption)
                                        .bold()
                                    Text("\(latestValue.hexDisplay)")
                                        .font(.caption)
                                        .foregroundStyle(.primary)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                        
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
                            
                            if characteristic.properties.contains("Write") || characteristic.properties.contains("Write Without Response") {
                                HStack(spacing: 8) {
                                    TextField(
                                        "Hex Bytes",
                                        text: Binding(
                                            get: {
                                                writeHexValues[characteristic.id] ?? ""
                                            },
                                            set: { newValue in
                                                writeHexValues[characteristic.id] = newValue
                                            }
                                        )
                                    )
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled()
                                    .textFieldStyle(.roundedBorder)
                                    .font(.caption)
                                    
                                    Button("Write") {
                                        onWriteCharacteristic(
                                            characteristic,
                                            writeHexValues[characteristic.id] ?? ""
                                        )
                                    }
                                    .font(.caption)
                                    .disabled(!isValidHexValue(for: characteristic))
                                    
                                    if shouldShowInvalidHexHint(for: characteristic) {
                                        Text("Enter an even number of hex digits")
                                            .font(.caption2)
                                            .foregroundStyle(.red)
                                    }
                                    
                                }
                            }
                        }
                        .padding(.top, 16)
                    }
                    .padding(.vertical, 4)
                }
            }
        } header: {
            Text("Service \(KnownBLEUUID.displayName(for: service.uuid))")
        }
    }
    
    private func isValidHexValue(for characteristic: BLECharacteristic) -> Bool {
        guard let hexValue = writeHexValues[characteristic.id] else {
            return false
        }
        
        return HexDataParser.data(from: hexValue) != nil
    }
    
    private func shouldShowInvalidHexHint(for characteristic: BLECharacteristic) -> Bool {
        guard let hexValue = writeHexValues[characteristic.id] else {
            return false
        }
        
        guard hexValue.isEmpty == false else {
            return false
        }
        
        return HexDataParser.data(from: hexValue) == nil
    }
}

struct BLEServiceSectionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                List {
                    ForEach(PreviewFixtures.services) { service in
                        BLEServiceSectionView(
                            service: service,
                            onReadCharacteristic: { _ in },
                            onToggleNotify: { _ in },
                            onWriteCharacteristic: { _, _ in }
                        )
                    }
                }
                .navigationTitle("Services")
            }
            .previewDisplayName("Services")
            
            NavigationStack {
                List {
                    BLEServiceSectionView(
                        service: BLEService(uuid: "1234"),
                        onReadCharacteristic: { _ in },
                        onToggleNotify: { _ in },
                        onWriteCharacteristic: { _, _ in }
                    )
                }
            }
            .previewDisplayName("Empty Service")
        }
    }
}
