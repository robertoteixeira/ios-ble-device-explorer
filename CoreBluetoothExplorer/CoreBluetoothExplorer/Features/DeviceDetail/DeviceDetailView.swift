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
                
                if let operationStatusMessage = viewModel.operationStatus.displayName {
                    LabeledContent("Last Action") {
                        Text(operationStatusMessage)
                            .foregroundStyle(operationStatusForegroundStyle)
                    }
                }
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
                        },
                        onWriteCharacteristic: { characteristic, hexString in
                            viewModel.writeCharacteristic(
                                characteristic,
                                hexString: hexString
                            )
                        }
                    )
                }
            }
        }
        .navigationTitle("Device Details")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if showsDisconnectButton {
                    Button("Disconnect") {
                        viewModel.disconnect()
                    }
                }
            }
        }
    }
    
    private var operationStatusForegroundStyle: Color {
        switch viewModel.operationStatus {
        case .idle:
            return .secondary
        case .inProgress:
            return .orange
        case .succeeded:
            return .green
        case .failed:
            return .red
        }
    }
    
    private var showsDisconnectButton: Bool {
        switch viewModel.connectionState {
        case .connecting, .connected, .discoveringServices, .discoveringCharacteristics, .ready:
            return true
        case .disconnected, .scanning, .failed:
            return false
        }
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
                        operationStatus: .succeeded("Value updated"),
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
