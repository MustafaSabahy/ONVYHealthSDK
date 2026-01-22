//
//  HealthDataAggregator.swift
//  ONVYHealthSDK
//
//  Unified aggregator for multiple health data sources
//

import Foundation

/// Aggregates health data from multiple sources
public class HealthDataAggregator {
    
    public static let shared = HealthDataAggregator()
    
    private var sources: [HealthDataSource] = []
    
    private init() {
        // Initialize with available sources
        sources = [
            HealthKitSource(),      // Real HealthKit
            MockWearableSource(),   // Mock wearable for demo
            MockNutritionSource()   // Mock nutrition for demo
        ]
    }
    
    /// Register a new health data source
    public func registerSource(_ source: HealthDataSource) {
        sources.append(source)
    }
    
    /// Get available sources
    public func getAvailableSources() -> [HealthDataSource] {
        return sources.filter { $0.isAvailable() }
    }
    
    /// Get active (authorized) sources
    public func getActiveSources() -> [HealthDataSource] {
        return sources.filter { source in
            source.isAvailable() && source.checkAuthorizationStatus() == .authorized
        }
    }
    
    /// Aggregate health data from all active sources
    public func aggregateHealthData(for date: Date) async throws -> AggregatedHealthData {
        let activeSources = getActiveSources()
        
        guard !activeSources.isEmpty else {
            throw HealthKitError.authorizationNotDetermined
        }
        
        var summaries: [HealthDataSummary] = []
        
        // Fetch data from all active sources
        for source in activeSources {
            do {
                let summary = try await source.getHealthDataSummary(for: date)
                summaries.append(summary)
            } catch {
                // Continue with other sources if one fails
                print("Failed to get data from \(source.displayName): \(error)")
            }
        }
        
        guard !summaries.isEmpty else {
            throw HealthKitError.noDataAvailable
        }
        
        // Aggregate data from all sources
        let aggregatedSteps = aggregateSteps(from: summaries)
        let aggregatedHeartRate = aggregateHeartRate(from: summaries)
        let aggregatedSleep = aggregateSleep(from: summaries)
        let aggregatedCalories = aggregateCalories(from: summaries)
        
        return AggregatedHealthData(
            date: date,
            steps: aggregatedSteps,
            averageHeartRate: aggregatedHeartRate,
            sleepHours: aggregatedSleep,
            activeCalories: aggregatedCalories,
            sources: activeSources.map { $0.displayName }
        )
    }
    
    /// Get weekly trends from all sources
    public func getWeeklyTrends() async throws -> [AggregatedHealthData] {
        var trends: [AggregatedHealthData] = []
        
        for dayOffset in 0..<7 {
            guard let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) else {
                continue
            }
            
            do {
                let data = try await aggregateHealthData(for: date)
                trends.append(data)
            } catch {
                // Continue with other days
                print("Failed to get data for day \(dayOffset): \(error)")
            }
        }
        
        return trends.reversed() // Chronological order
    }
    
    // MARK: - Aggregation Logic
    
    private func aggregateSteps(from summaries: [HealthDataSummary]) -> Double {
        // Use highest value (most complete data)
        return summaries.map { $0.steps }.max() ?? 0
    }
    
    private func aggregateHeartRate(from summaries: [HealthDataSummary]) -> Double? {
        // Average all available heart rate readings
        let heartRates = summaries.compactMap { $0.averageHeartRate }
        guard !heartRates.isEmpty else { return nil }
        return heartRates.reduce(0, +) / Double(heartRates.count)
    }
    
    private func aggregateSleep(from summaries: [HealthDataSummary]) -> Double? {
        // Use highest value (most complete sleep data)
        return summaries.compactMap { $0.sleepHours }.max()
    }
    
    private func aggregateCalories(from summaries: [HealthDataSummary]) -> Double? {
        // Sum calories from all sources
        let calories = summaries.compactMap { $0.activeCalories }
        guard !calories.isEmpty else { return nil }
        return calories.reduce(0, +)
    }
}

/// Aggregated health data from multiple sources
public struct AggregatedHealthData: Codable {
    public let date: Date
    public let steps: Double
    public let averageHeartRate: Double?
    public let sleepHours: Double?
    public let activeCalories: Double?
    public let sources: [String] // List of source names
    
    public init(date: Date, steps: Double, averageHeartRate: Double?, sleepHours: Double?, activeCalories: Double?, sources: [String]) {
        self.date = date
        self.steps = steps
        self.averageHeartRate = averageHeartRate
        self.sleepHours = sleepHours
        self.activeCalories = activeCalories
        self.sources = sources
    }
}

/// HealthKit as a HealthDataSource
/// Wraps HealthKitManager to conform to protocol
class HealthKitSource: HealthDataSource {
    let sourceId = "healthkit"
    let displayName = "Apple HealthKit"
    
    func requestAuthorization() async throws {
        try await HealthKitManager.shared.requestAuthorization()
    }
    
    func checkAuthorizationStatus() -> AuthorizationStatus {
        let status = HealthKitManager.shared.getAuthorizationStatus()
        // Check if at least one type is authorized
        let isAuthorized = status.values.contains { $0 == "authorized" }
        return isAuthorized ? .authorized : .notDetermined
    }
    
    func getHealthDataSummary(for date: Date) async throws -> HealthDataSummary {
        return try await HealthKitManager.shared.getHealthDataSummary(for: date)
    }
    
    func startObserving(handler: @escaping (HealthDataSummary) -> Void) throws {
        try HealthKitManager.shared.startObservingSteps { steps in
            Task {
                do {
                    let summary = try await HealthKitManager.shared.getHealthDataSummary(for: Date())
                    handler(summary)
                } catch {
                    print("HealthKit observation error: \(error)")
                }
            }
        }
    }
    
    func isAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
}
