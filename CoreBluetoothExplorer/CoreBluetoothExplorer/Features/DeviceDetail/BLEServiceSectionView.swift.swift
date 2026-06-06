//
//  BLEServiceSectionView.swift.swift
//  CoreBluetoothExplorer
//
//  Created by Roberto Teixeira on 06/06/2026.
//

import SwiftUI

struct BLEServiceSectionView: View {
    let service: BLEService
    
    var body: some View {
        Section {
            if service.characteristics.isEmpty {
                Text("No characteristics discovered")
            } else {
                ForEach(service.characteristics) { characteristic in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(characteristic.uuid)
                            .font(.subheadline)
                            .bold()
                        
                        if characteristic.properties.isEmpty {
                            Text("No properties")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(characteristic.properties.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        } header: {
            Text("Service \(service.uuid)")
        }
    }
}
