//
//  BLEValueDecoder.swift
//  CoreBluetoothExplorer
//
//  Created by Roberto Teixeira on 12/06/2026.
//

import Foundation

enum BLEValueDecoder {
    static func decodedValue(uuid: String, data: Data) -> String? {
        switch uuid.uppercased() {
        case "2A19":
            return decodeBatteryLevel(data)
        case "2A38":
            return decodeBodySensorLocation(data)
        default:
            return nil
        }
    }
    
    private static func decodeBatteryLevel(_ data: Data) -> String? {
        guard let firstByte = data.first else {
            return nil
        }
        
        return "\(firstByte)%"
    }
    
    private static func decodeBodySensorLocation(_ data: Data) -> String? {
        guard let firstByte = data.first else {
            return nil
        }
        
        switch firstByte {
        case 0:
            return "Other"
        case 1:
            return "Chest"
        case 2:
            return "Wrist"
        case 3:
            return "Finger"
        case 4:
            return "Hand"
        case 5:
            return "Ear Lobe"
        case 6:
            return "Foot"
        default:
            return "Reserved (\(firstByte)"
        }
    }
}
