//
//  MockWearableSource.swift
//  ONVYHealthSDK
//
//  Mock wearable data source for demo purposes
//

import Foundation

/// Mock wearable data source
public class MockWearableSource: HealthDataSource {
    
    public let sourceId = "mock_wearable"
    public let displayName = "Mock Wearable Device"
    
    private var isAuthorized = false
    private var observationHandler: ((HealthDataSummary) -> Void)?
    private var observationTimer: Timer?
    
    // MARK: - HealthDataSource Protocol
    
    public func requestAuthorization() async throws {
        // Simulate authorization delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        isAuthorized = true
    }
    
    public func checkAuthorizationStatus() -> AuthorizationStatus {
        return isAuthorized ? .authorized : .notDetermined
    }
    
    public func getHealthDataSummary(for date: Date) async throws -> HealthDataSummary {
        guard isAuthorized else {
            throw HealthKitError.authorizationNotDetermined
        }
        
        // Generate mock data
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        
        let steps = isToday ? Double.random(in: 8000...12000) : Double.random(in: 5000...15000)
        let heartRate = Double.random(in: 65...85)
        let sleepHours = Double.random(in: 6.5...8.5)
        
        return HealthDataSummary(
            date: date,
            steps: steps,
            averageHeartRate: heartRate,
            sleepHours: sleepHours,
            activeCalories: Double.random(in: 200...400)
        )
    }
    
    public func startObserving(handler: @escaping (HealthDataSummary) -> Void) throws {
        guard isAuthorized else {
            throw HealthKitError.authorizationNotDetermined
        }
        
        observationHandler = handler
        
        // Simulate live updates every 5 seconds
        observationTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task {
                do {
                    let summary = try await self?.getHealthDataSummary(for: Date())
                    if let summary = summary {
                        await MainActor.run {
                            handler(summary)
                        }
                    }
                } catch {
                    print("Mock wearable update error: \(error)")
                }
            }
        }
    }
    
    public func isAvailable() -> Bool {
        // Mock source is always available for demo
        return true
    }
    
    deinit {
        observationTimer?.invalidate()
    }
}
