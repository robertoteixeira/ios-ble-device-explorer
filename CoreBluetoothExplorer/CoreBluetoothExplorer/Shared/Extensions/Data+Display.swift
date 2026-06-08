//
//  Data+Display.swift
//  CoreBluetoothExplorer
//
//  Created by Roberto Teixeira on 08/06/2026.
//

import Foundation

extension Data {
    var hexDisplay: String {
        guard !isEmpty else {
            return "Empty"
        }
        
        return map {
            String(format: "%02X", $0)
        }
        .joined(separator: " ")
    }
    
    var utf8Display: String? {
        guard !isEmpty else {
            return nil
        }
        
        return String(data: self, encoding: .utf8)
    }
    
    var readableDisplay: String {
        if let utf8Display, !utf8Display.isEmpty {
            return "\(hexDisplay) (\(utf8Display)"
        }
        
        return hexDisplay
    }
}
