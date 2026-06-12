//
//  HexDataParser.swift
//  CoreBluetoothExplorer
//
//  Created by Roberto Teixeira on 12/06/2026.
//

import Foundation

enum HexDataParser {
    static func data(from input: String) -> Data? {
        let normalizedInput = input
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\t", with: "")
        
        guard normalizedInput.isEmpty == false else {
            return nil
        }
        
        guard normalizedInput.count.isMultiple(of: 2) else {
            return nil
        }
        
        var bytes: [UInt8] = []
        var currentIndex = normalizedInput.startIndex
        
        while currentIndex < normalizedInput.endIndex {
            let nextIndex = normalizedInput.index(currentIndex, offsetBy: 2)
            let byteString = normalizedInput[currentIndex..<nextIndex]
            
            guard let byte = UInt8(byteString, radix: 16) else {
                return nil
            }
            
            bytes.append(byte)
            currentIndex = nextIndex
        }
        
        return Data(bytes)
    }
}
