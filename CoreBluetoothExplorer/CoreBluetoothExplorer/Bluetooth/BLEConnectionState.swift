//
//  BLEConnectionState.swift
//  CoreBluetoothExplorer
//
//  Created by Roberto Teixeira on 05/06/2026.
//

enum BLEConnectionState: Equatable {
    case disconnected
    case scanning
    case connecting
    case connected
    case discoveringServices
    case discoveringCharacteristics
    case ready
    case failed(String)
    
    var displayName: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .scanning: return "Scanning"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        case .discoveringServices: return "Discovering Services"
        case .discoveringCharacteristics: return "Discovering Characteristics"
        case .ready: return "Ready"
        case .failed(let message): return "Failed: \(message)"
        }
    }
}
