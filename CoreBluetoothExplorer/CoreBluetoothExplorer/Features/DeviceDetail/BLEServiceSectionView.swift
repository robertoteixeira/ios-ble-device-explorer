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
    
    var body: some View {
        Section {
            if service.characteristics.isEmpty {
                Text("No characteristics discovered")
            } else {
                ForEach(service.characteristics) { characteristic in
                    BLECharacteristicRowView(
                        characteristic: characteristic,
                        onReadCharacteristic: onReadCharacteristic,
                        onToggleNotify: onToggleNotify,
                        onWriteCharacteristic: onWriteCharacteristic
                    )
                }
            }
        } header: {
            Text("Service \(KnownBLEUUID.displayName(for: service.uuid))")
        }
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
