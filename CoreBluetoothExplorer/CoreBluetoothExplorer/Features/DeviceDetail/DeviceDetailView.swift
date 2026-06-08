//
//  DeviceDetailView.swift
//  CoreBluetoothExplorer
//
//  Created by Roberto Teixeira on 06/06/2026.
//
import SwiftUI

struct DeviceDetailView: View {
    @StateObject private var viewModel: DeviceDetailViewModel
    
    init(
        device: BLEDevice,
        bleCentralManager: BLECentralManager
    ) {
        _viewModel = StateObject(
            wrappedValue: DeviceDetailViewModel(
                device: device,
                bleCentralManager: bleCentralManager
            )
        )
    }
    
    var body: some View {
        List {
            Section {
                LabeledContent("Name", value: viewModel.device.displayName)
                LabeledContent("Identifier", value: viewModel.device.id.uuidString)
                LabeledContent("RSSI", value: "\(viewModel.device.rssi)")
                LabeledContent("Connection", value: viewModel.connectionState.displayName)
            } header: {
                Text("Device")
            }
            
            if viewModel.services.isEmpty {
                Section {
                    Text("No services discovered yet")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(viewModel.services) { service in
                    BLEServiceSectionView(
                        service: service,
                        onReadCharacteristic: { characteristic in
                            viewModel.readCharacteristic(characteristic)
                        },
                        onToggleNotify: { characteristic in
                            viewModel.toggleNotify(for: characteristic)
                        }
                    )
                }
            }
        }
        .navigationTitle("Device Details")
    }
}
