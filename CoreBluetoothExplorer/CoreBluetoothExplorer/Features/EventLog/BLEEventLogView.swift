//
//  BLEEventLogView.swift
//  CoreBluetoothExplorer
//
//  Created by Codex on 30/06/2026.
//

import SwiftUI

struct BLEEventLogView: View {
    let events: [BLEEvent]
    
    var body: some View {
        Group {
            if events.isEmpty {
                Text("No events yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(events) { event in
                    BLEEventRowView(event: event)
                }
            }
        }
    }
}

private struct BLEEventRowView: View {
    let event: BLEEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImageName)
                .foregroundStyle(iconColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(event.date, format: .dateTime.hour().minute().second())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                if let message = event.message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private var systemImageName: String {
        switch event.level {
        case .info:
            return "info.circle"
        case .success:
            return "checkmark.circle"
        case .warning:
            return "exclamationmark.triangle"
        case .failure:
            return "xmark.octagon"
        }
    }
    
    private var iconColor: Color {
        switch event.level {
        case .info:
            return .blue
        case .success:
            return .green
        case .warning:
            return .orange
        case .failure:
            return .red
        }
    }
}
