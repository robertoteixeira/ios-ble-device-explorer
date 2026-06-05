//
//  CoreBluetoothExplorerApp.swift
//  CoreBluetoothExplorer
//
//  Created by Roberto Teixeira on 05/06/2026.
//

import SwiftUI

@main
struct CoreBluetoothExplorerApp: App {
    @StateObject private var bleCentralManager = BLECentralManager()
    
    var body: some Scene {
        WindowGroup {
            DeviceScannerView(bleCentralManager: bleCentralManager)
        }
    }
}
