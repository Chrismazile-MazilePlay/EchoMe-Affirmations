//
//  Logger.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/3/25.
//

import Foundation

enum Logger {
    enum Level: String {
        case debug = "🔍"
        case info = "ℹ️"
        case warning = "⚠️"
        case error = "❌"
        case success = "✅"
    }
    
    static func log(
        _ message: String,
        level: Level = .debug,
        file: String = #file,
        line: Int = #line
    ) {
        #if DEBUG
        let filename = file.split(separator: "/").last ?? ""
        print("\(level.rawValue) [\(filename):\(line)] \(message)")
        #endif
    }
}

// MARK: - Convenience Methods
extension Logger {
    static func debug(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .debug, file: file, line: line)
    }
    
    static func info(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .info, file: file, line: line)
    }
    
    static func warning(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .warning, file: file, line: line)
    }
    
    static func error(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .error, file: file, line: line)
    }
    
    static func success(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .success, file: file, line: line)
    }
}
