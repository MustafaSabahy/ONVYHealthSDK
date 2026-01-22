//
//  Logger.swift
//  ONVYHealthSDK
//
//  Structured logging system using OSLog
//

import Foundation
import OSLog

/// Structured logging system for ONVY Health SDK
/// Uses OSLog for efficient logging
/// Never logs sensitive health data
public class Logger {
    
    // MARK: - Log Categories
    
    public enum Category: String {
        case healthKit = "HealthKit"
        case aggregation = "Aggregation"
        case authorization = "Authorization"
        case cache = "Cache"
        case api = "API"
        case bridge = "Bridge"
        case general = "General"
    }
    
    // MARK: - Log Levels
    
    public enum Level {
        case debug
        case info
        case warning
        case error
        case fault
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .fault: return .fault
            }
        }
    }
    
    // MARK: - Properties
    
    private static let subsystem = "com.onvy.healthsdk"
    private static var loggers: [Category: Logger] = [:]
    
    private let osLogger: os.Logger
    
    // MARK: - Initialization
    
    private init(category: Category) {
        self.osLogger = os.Logger(subsystem: Logger.subsystem, category: category.rawValue)
    }
    
    /// Get logger for a specific category
    public static func logger(for category: Category) -> Logger {
        if let existing = loggers[category] {
            return existing
        }
        let logger = Logger(category: category)
        loggers[category] = logger
        return logger
    }
    
    // MARK: - Logging Methods
    
    /// Log debug message
    /// - Parameters:
    ///   - message: Log message
    ///   - metadata: Additional metadata (never includes sensitive data)
    public func debug(_ message: String, metadata: [String: Any]? = nil) {
        log(level: .debug, message: message, metadata: metadata)
    }
    
    /// Log info message
    /// - Parameters:
    ///   - message: Log message
    ///   - metadata: Additional metadata
    public func info(_ message: String, metadata: [String: Any]? = nil) {
        log(level: .info, message: message, metadata: metadata)
    }
    
    /// Log warning message
    /// - Parameters:
    ///   - message: Log message
    ///   - metadata: Additional metadata
    public func warning(_ message: String, metadata: [String: Any]? = nil) {
        log(level: .warning, message: message, metadata: metadata)
    }
    
    /// Log error message
    /// - Parameters:
    ///   - message: Log message
    ///   - error: Error object
    ///   - metadata: Additional metadata
    public func error(_ message: String, error: Error? = nil, metadata: [String: Any]? = nil) {
        var fullMetadata = metadata ?? [:]
        if let error = error {
            fullMetadata["error"] = error.localizedDescription
            fullMetadata["errorCode"] = (error as? HealthKitError)?.code ?? "UNKNOWN"
        }
        log(level: .error, message: message, metadata: fullMetadata)
    }
    
    /// Log fault (critical error)
    /// - Parameters:
    ///   - message: Log message
    ///   - metadata: Additional metadata
    public func fault(_ message: String, metadata: [String: Any]? = nil) {
        log(level: .fault, message: message, metadata: metadata)
    }
    
    // MARK: - Private Methods
    
    private func log(level: Level, message: String, metadata: [String: Any]?) {
        var logMessage = message
        
        // Append metadata if present
        if let metadata = metadata, !metadata.isEmpty {
            let metadataString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            logMessage += " | \(metadataString)"
        }
        
        // Log using OSLog
        osLogger.log(level: level.osLogType, "\(logMessage)")
    }
}

// MARK: - Convenience Extensions

extension Logger {
    /// Log HealthKit operation
    public static func healthKit(_ message: String, level: Level = .info, metadata: [String: Any]? = nil) {
        logger(for: .healthKit).log(level: level, message: message, metadata: metadata)
    }
    
    /// Log aggregation operation
    public static func aggregation(_ message: String, level: Level = .info, metadata: [String: Any]? = nil) {
        logger(for: .aggregation).log(level: level, message: message, metadata: metadata)
    }
    
    /// Log authorization operation
    public static func authorization(_ message: String, level: Level = .info, metadata: [String: Any]? = nil) {
        logger(for: .authorization).log(level: level, message: message, metadata: metadata)
    }
    
    /// Log API operation
    public static func api(_ message: String, level: Level = .info, metadata: [String: Any]? = nil) {
        logger(for: .api).log(level: level, message: message, metadata: metadata)
    }
}
