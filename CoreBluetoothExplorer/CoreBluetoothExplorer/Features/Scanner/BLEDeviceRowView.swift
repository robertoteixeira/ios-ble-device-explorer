//
//  BLEDeviceRowView.swift
//  CoreBluetoothExplorer
//
//  Created by Roberto Teixeira on 05/06/2026.
//

import SwiftUI

struct BLEDeviceRowView: View {
    let device: BLEDevice
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(device.displayName)
                .font(.headline)
            
            Text(device.id.uuidString)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            
            HStack {
                Text("RSSI: \(device.rssi)")
                
                Spacer()
                
                if let isConnectable = device.isConnectable {
                    Text(isConnectable ? "Connectable" : "Not connectable")
                        .foregroundStyle(isConnectable ? .green : .secondary)
                }
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

struct BLEDeviceRowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            List {
                BLEDeviceRowView(device: PreviewFixtures.heartRateMonitor)
            }
            .previewDisplayName("Connectable")
            
            List {
                BLEDeviceRowView(device: PreviewFixtures.unknownBeacon)
            }
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewDisplayName("Unknown Device")
        }
    }
}
