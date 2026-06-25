//
//  BLEOperationStatus.swift
//  CoreBluetoothExplorer
//
//  Created by Roberto Teixeira on 24/06/2026.
//

enum BLEOperationStatus: Equatable {
    case idle
    case inProgress(String)
    case succeeded(String)
    case failed(String)
    
    var displayName: String? {
        switch self {
        case .idle:
            return nil
        case .inProgress(let message):
            return message
        case .succeeded(let message):
            return message
        case .failed(let message):
            return message
        }
    }
}
