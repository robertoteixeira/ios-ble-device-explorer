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
    
    init(viewModel: DeviceDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
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

struct DeviceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                DeviceDetailView(
                    viewModel: DeviceDetailViewModel(
                        device: PreviewFixtures.heartRateMonitor,
                        connectionState: .ready,
                        services: PreviewFixtures.services
                    )
                )
            }
            .previewDisplayName("Ready")
            
            NavigationStack {
                DeviceDetailView(
                    viewModel: DeviceDetailViewModel(
                        device: PreviewFixtures.thermometer,
                        connectionState: .discoveringCharacteristics,
                        services: [
                            BLEService(uuid: "1809")
                        ]
                    )
                )
            }
            .previewDisplayName("Discovering")
            
            NavigationStack {
                DeviceDetailView(
                    viewModel: DeviceDetailViewModel(
                        device: PreviewFixtures.unknownBeacon,
                        connectionState: .failed("Connection timed out"),
                        services: []
                    )
                )
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("No Services")
        }
    }
}
