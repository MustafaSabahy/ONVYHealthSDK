//
//  HealthKitError.swift
//  ONVYHealthSDK
//
//  Error types for HealthKit operations
//

import Foundation
import HealthKit

/// Error handling for HealthKit operations
public enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case authorizationDenied
    case authorizationNotDetermined
    case invalidType
    case queryFailed(String)
    case noDataAvailable
    case invalidDateRange
    case backgroundDeliveryNotEnabled
    
    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .authorizationDenied:
            return "HealthKit authorization was denied by the user"
        case .authorizationNotDetermined:
            return "HealthKit authorization has not been requested yet"
        case .invalidType:
            return "Invalid health data type identifier"
        case .queryFailed(let message):
            return "HealthKit query failed: \(message)"
        case .noDataAvailable:
            return "No health data available for the requested time period"
        case .invalidDateRange:
            return "Invalid date range provided for query"
        case .backgroundDeliveryNotEnabled:
            return "Background delivery is not enabled for this data type"
        }
    }
    
    /// Error code for React Native bridge compatibility
    public var code: String {
        switch self {
        case .notAvailable: return "NOT_AVAILABLE"
        case .authorizationDenied: return "AUTHORIZATION_DENIED"
        case .authorizationNotDetermined: return "AUTHORIZATION_NOT_DETERMINED"
        case .invalidType: return "INVALID_TYPE"
        case .queryFailed: return "QUERY_FAILED"
        case .noDataAvailable: return "NO_DATA_AVAILABLE"
        case .invalidDateRange: return "INVALID_DATE_RANGE"
        case .backgroundDeliveryNotEnabled: return "BACKGROUND_DELIVERY_NOT_ENABLED"
        }
    }
}
