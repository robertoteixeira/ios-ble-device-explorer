//
//  KnownBLEUUID.swift
//  CoreBluetoothExplorer
//
//  Created by Roberto Teixeira on 12/06/2026.
//

import Foundation

enum KnownBLEUUID {
    static func name(for uuid: String) -> String? {
        knownNames[uuid.uppercased()]
    }
    
    static func displayName(for uuid: String) -> String {
        guard let name = name(for: uuid) else {
            return uuid
        }
        
        return "\(uuid) - \(name)"
    }
    
    private static let knownNames: [String: String] = [
        // MARK: - Services
        
        "180A": "Device Information",
        "180F": "Battery Service",
        "180D": "Heart Rate",
        "1805": "Current Time",
        "1800": "Generic Access",
        "1801": "Generic Attribute",
        "1812": "Human Interface Device",
        
        // MARK: - Device Information Characteristics
        
        "2A23": "System ID",
        "2A24": "Model Number String",
        "2A25": "Serial Number String",
        "2A26": "Firmware Revision String",
        "2A27": "Hardware Revision String",
        "2A28": "Software Revision String",
        "2A29": "Manufacturer Name String",
        "2A2A": "IEEE Regulatory Certification Data List",
        "2A50": "PnP ID",
        
        // MARK: - Battery Characteristics
        
        "2A19": "Battery Level",
        
        // MARK: - Heart Rate Characteristics
        
        "2A37": "Heart Rate Measurement",
        "2A38": "Body Sensor Location",
        "2A39": "Heart Rate Control Point"
    ]
}
