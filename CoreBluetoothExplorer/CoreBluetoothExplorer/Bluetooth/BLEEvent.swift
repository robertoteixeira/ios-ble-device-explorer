//
//  BLEEvent.swift
//  CoreBluetoothExplorer
//
//  Created by Codex on 30/06/2026.
//

import Foundation

struct BLEEvent: Identifiable, Equatable {
    enum Level: Equatable {
        case info
        case success
        case warning
        case failure
    }
    
    let id: UUID
    let date: Date
    let level: Level
    let title: String
    let message: String?
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        level: Level,
        title: String,
        message: String? = nil
    ) {
        self.id = id
        self.date = date
        self.level = level
        self.title = title
        self.message = message
    }
}
