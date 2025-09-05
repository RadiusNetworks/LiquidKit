//
//  STRFTimeFormatter.swift
//
//  Copyright (c) 2014 emdentec (http://emdentec.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

class STRFTimeFormatter: NSObject, NSCopying {
    
    // MARK: - Private Properties
    private var _formatString: String = "%Y-%m-%dT%H:%M:%S%z"
    private var _useUniversalTimeLocale: Bool = false
    
    // Static cache for ASCII format string
    private static var formatStringHash: Int = 0
    private static var cachedFormatString: UnsafePointer<CChar>? = nil
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    // MARK: - Public Properties
    
    var formatString: String {
        get {
            return _formatString
        }
        set {
            _formatString = newValue
        }
    }
    
    var useUniversalTimeLocale: Bool {
        get {
            return _useUniversalTimeLocale
        }
        set {
            _useUniversalTimeLocale = newValue
        }
    }
    
    // MARK: - Conversion Methods
    
    func date(from string: String) -> Date? {
        var timeStruct = tm()
        
        guard let cString = string.cString(using: .ascii),
              let formatCString = asciiFormatString() else {
            return nil
        }
        
        // Use strptime to parse the string
        let result = strptime(cString, formatCString, &timeStruct)
        guard result != nil else {
            return nil
        }
        
        let timeInterval: time_t
        if useUniversalTimeLocale {
            timeInterval = timegm(&timeStruct)
        } else {
            timeInterval = mktime(&timeStruct)
        }
        
        return Date(timeIntervalSince1970: TimeInterval(timeInterval))
    }
    
    func string(from date: Date) -> String? {
        var timeInterval = time_t(date.timeIntervalSince1970)
        var timeStruct: tm
        
        if useUniversalTimeLocale {
            guard let gmtTime = gmtime(&timeInterval) else { return nil }
            timeStruct = gmtTime.pointee
        } else {
            guard let localTime = localtime(&timeInterval) else { return nil }
            timeStruct = localTime.pointee
        }
        
        guard let formatCString = asciiFormatString() else { return nil }
        
        // Create buffer for the formatted string
        var buffer = [CChar](repeating: 0, count: 80)
        let bytesWritten = strftime(&buffer, buffer.count, formatCString, &timeStruct)
        
        guard bytesWritten > 0 else { return nil }
        
        return String(cString: buffer, encoding: .ascii)
    }
    
    // MARK: - Private Methods
    
    private func asciiFormatString() -> UnsafePointer<CChar>? {
        let currentHash = formatString.hashValue
        
        // Check if we need to update the cached format string
        if STRFTimeFormatter.cachedFormatString == nil || STRFTimeFormatter.formatStringHash != currentHash {
            STRFTimeFormatter.formatStringHash = currentHash
            
            // Convert to C string - note: this creates a potential memory management issue
            // In a production app, you might want to use a different caching strategy
            if let cString = formatString.cString(using: .ascii) {
                let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: cString.count)
                buffer.initialize(from: cString, count: cString.count)
                STRFTimeFormatter.cachedFormatString = UnsafePointer(buffer)
            }
        }
        
        return STRFTimeFormatter.cachedFormatString
    }
    
    // MARK: - NSCopying
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = STRFTimeFormatter()
        copy.formatString = self._formatString
        copy.useUniversalTimeLocale = self._useUniversalTimeLocale
        return copy
    }
}

// MARK: - Convenience Extensions

extension STRFTimeFormatter {
    
    /// Convenience initializer with custom format string
    convenience init(formatString: String) {
        self.init()
        self.formatString = formatString
    }
    
    /// Convenience initializer with format string and locale option
    convenience init(formatString: String, useUniversalTimeLocale: Bool) {
        self.init()
        self.formatString = formatString
        self.useUniversalTimeLocale = useUniversalTimeLocale
    }
}

// MARK: - Usage Examples

/*
 // Basic usage
 let formatter = STRFTimeFormatter()
 let dateString = "2024-01-15T14:30:25+0000"
 if let date = formatter.date(from: dateString) {
 print("Parsed date: \(date)")
 if let formattedString = formatter.string(from: date) {
 print("Formatted back: \(formattedString)")
 }
 }
 
 // Custom format
 let customFormatter = STRFTimeFormatter(formatString: "%Y-%m-%d %H:%M:%S")
 let customDate = Date()
 if let customString = customFormatter.string(from: customDate) {
 print("Custom format: \(customString)")
 }
 
 // UTC/Universal time
 let utcFormatter = STRFTimeFormatter(formatString: "%Y-%m-%dT%H:%M:%SZ", useUniversalTimeLocale: true)
 */
