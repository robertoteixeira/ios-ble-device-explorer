//
//  DeviceScannerView.swift
//  CoreBluetoothExplorer
//
//  Created by Roberto Teixeira on 05/06/2026.
//

import SwiftUI

struct DeviceScannerView: View {
    @StateObject private var viewModel: DeviceScannerViewModel
    
    init(bleCentralManager: BLECentralManager) {
        _viewModel = StateObject(
            wrappedValue: DeviceScannerViewModel(
                bleCentralManager: bleCentralManager
            )
        )
    }
    
    init(viewModel: DeviceScannerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statusHeader
                
                List(viewModel.visibleDevices) { device in
                    NavigationLink {
                        DeviceDetailView(
                            device: device,
                            bleCentralManager: viewModel.bleCentralManager
                        )
                        .onAppear {
                            viewModel.connect(to: device)
                        }
                    } label: {
                        BLEDeviceRowView(device: device)
                    }
                }
            }
            .navigationTitle("BLE Explorer")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Toggle("Show Unknown Devices", isOn: $viewModel.showsUnknownDevices)
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    scanButton
                }
            }
        }
    }
    
    private var statusHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Bluetooth")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(viewModel.bluetoothState.displayName)
                    .font(.caption)
                    .bold()
            }
            
            HStack {
                Text("State")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(viewModel.connectionState.displayName)
                    .font(.caption)
                    .bold()
            }
        }
        .padding()
        .background(.thinMaterial)
    }
    
    private var scanButton: some View {
        Button {
            if viewModel.connectionState == .scanning {
                viewModel.stopScanning()
            } else {
                viewModel.startScanning()
            }
        } label: {
            Text(viewModel.connectionState == .scanning ? "Stop" : "Scan")
        }
        .disabled(viewModel.bluetoothState != .poweredOn)
    }
}

struct DeviceScannerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DeviceScannerView(
                viewModel: DeviceScannerViewModel(
                    bluetoothState: .poweredOn,
                    connectionState: .scanning,
                    devices: PreviewFixtures.devices
                )
            )
            .previewDisplayName("Scanning")
            
            DeviceScannerView(
                viewModel: DeviceScannerViewModel(
                    bluetoothState: .poweredOn,
                    connectionState: .disconnected,
                    devices: PreviewFixtures.devices,
                    showsUnknownDevices: false
                )
            )
            .previewDisplayName("Filtered")
            
            DeviceScannerView(
                viewModel: DeviceScannerViewModel(
                    bluetoothState: .poweredOff,
                    connectionState: .disconnected,
                    devices: []
                )
            )
            .previewDisplayName("Bluetooth Off")
        }
    }
}
