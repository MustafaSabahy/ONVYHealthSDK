//
//  HealthDataSource.swift
//  ONVYHealthSDK
//
//  Protocol-based design for health data sources
//

import Foundation

/// Protocol for all health data sources
public protocol HealthDataSource {
    /// Unique identifier for the data source
    var sourceId: String { get }
    
    /// Display name for the data source
    var displayName: String { get }
    
    /// Request authorization for this data source
    func requestAuthorization() async throws
    
    /// Check authorization status
    func checkAuthorizationStatus() -> AuthorizationStatus
    
    /// Get health data summary
    func getHealthDataSummary(for date: Date) async throws -> HealthDataSummary
    
    /// Start observing data changes
    func startObserving(handler: @escaping (HealthDataSummary) -> Void) throws
    
    /// Check if source is available
    func isAvailable() -> Bool
}

/// Authorization status for data sources
public enum AuthorizationStatus {
    case notDetermined
    case denied
    case authorized
}
