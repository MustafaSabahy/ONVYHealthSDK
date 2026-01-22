//
//  MockNutritionSource.swift
//  ONVYHealthSDK
//
//  Mock nutrition data source for demo purposes
//

import Foundation

/// Mock nutrition data source
public class MockNutritionSource: HealthDataSource {
    
    public let sourceId = "mock_nutrition"
    public let displayName = "Mock Nutrition Tracker"
    
    private var isAuthorized = false
    
    // MARK: - HealthDataSource Protocol
    
    public func requestAuthorization() async throws {
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        isAuthorized = true
    }
    
    public func checkAuthorizationStatus() -> AuthorizationStatus {
        return isAuthorized ? .authorized : .notDetermined
    }
    
    public func getHealthDataSummary(for date: Date) async throws -> HealthDataSummary {
        guard isAuthorized else {
            throw HealthKitError.authorizationNotDetermined
        }
        
        // Mock nutrition data - returns calories only
        return HealthDataSummary(
            date: date,
            steps: 0,
            averageHeartRate: nil,
            sleepHours: nil,
            activeCalories: Double.random(in: 1800...2500) // Mock calories
        )
    }
    
    public func startObserving(handler: @escaping (HealthDataSummary) -> Void) throws {
        // Nutrition updates less frequently
    }
    
    public func isAvailable() -> Bool {
        return true
    }
}
