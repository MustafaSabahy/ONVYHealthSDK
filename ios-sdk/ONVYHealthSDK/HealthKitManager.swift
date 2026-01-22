//
//  HealthKitManager.swift
//  ONVYHealthSDK
//
//  Core HealthKit manager
//  Handles all HealthKit operations with proper error handling and timezone awareness
//

import Foundation
import HealthKit

/// Main manager for HealthKit operations
/// Uses singleton pattern to ensure single HKHealthStore instance
public class HealthKitManager {
    
    // MARK: - Singleton
    
    public static let shared = HealthKitManager()
    
    // MARK: - Properties
    
    private let healthStore: HKHealthStore
    
    /// In-memory cache to reduce HealthKit queries
    /// Only caches aggregated data, never raw samples
    private var cache: [String: (data: Any, timestamp: Date)] = [:]
    private let cacheTTL: TimeInterval = 300 // 5 minutes
    
    // MARK: - Initialization
    
    private init() {
        self.healthStore = HKHealthStore()
    }
    
    // MARK: - Authorization
    
    /// Request authorization for health data types
    public func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        // Define types to read
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        try await healthStore.requestAuthorization(toShare: nil, read: typesToRead)
    }
    
    /// Check authorization status for a specific type
    public func checkAuthorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        return healthStore.authorizationStatus(for: type)
    }
    
    /// Get overall authorization status
    public func getAuthorizationStatus() -> [String: String] {
        var status: [String: String] = [:]
        
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let stepStatus = healthStore.authorizationStatus(for: stepType)
            status["steps"] = authorizationStatusToString(stepStatus)
        }
        
        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            let hrStatus = healthStore.authorizationStatus(for: heartRateType)
            status["heartRate"] = authorizationStatusToString(hrStatus)
        }
        
        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            let sleepStatus = healthStore.authorizationStatus(for: sleepType)
            status["sleep"] = authorizationStatusToString(sleepStatus)
        }
        
        return status
    }
    
    // MARK: - Steps
    
    /// Get steps for a specific date
    /// Uses HKStatisticsQuery for better performance
    public func getSteps(for date: Date) async throws -> Double {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.invalidType
        }
        
        // Check authorization
        let status = healthStore.authorizationStatus(for: stepType)
        guard status == .sharingAuthorized else {
            if status == .notDetermined {
                throw HealthKitError.authorizationNotDetermined
            } else {
                throw HealthKitError.authorizationDenied
            }
        }
        
        // Check cache first
        let cacheKey = "steps_\(date.timeIntervalSince1970)"
        if let cached = getCachedData(key: cacheKey) as? Double {
            return cached
        }
        
        // Calculate date range using calendar for timezone handling
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw HealthKitError.invalidDateRange
        }
        
        // Edge case: Don't query future dates
        guard endOfDay <= Date() else {
            throw HealthKitError.invalidDateRange
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { [weak self] _, result, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
                    return
                }
                
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                
                // Cache the result
                self?.setCachedData(key: cacheKey, data: steps)
                
                continuation.resume(returning: steps)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Get steps for multiple days (e.g., last 7 days)
    public func getStepsForDays(_ days: Int, from date: Date = Date()) async throws -> [DailySteps] {
        var results: [DailySteps] = []
        
        for dayOffset in 0..<days {
            guard let targetDate = Calendar.current.date(byAdding: .day, value: -dayOffset, to: date) else {
                continue
            }
            
            do {
                let steps = try await getSteps(for: targetDate)
                results.append(DailySteps(date: targetDate, steps: steps))
            } catch {
                // Continue with other days even if one fails
                print("Failed to get steps for \(targetDate): \(error)")
            }
        }
        
        return results.reversed() // Return in chronological order
    }
    
    // MARK: - Heart Rate
    
    /// Get latest heart rate reading
    public func getLatestHeartRate() async throws -> HeartRateData? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.invalidType
        }
        
        let status = healthStore.authorizationStatus(for: heartRateType)
        guard status == .sharingAuthorized else {
            if status == .notDetermined {
                throw HealthKitError.authorizationNotDetermined
            } else {
                throw HealthKitError.authorizationDenied
            }
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                let source = sample.sourceRevision.source.name
                
                let data = HeartRateData(
                    value: heartRate,
                    timestamp: sample.endDate,
                    source: source
                )
                
                continuation.resume(returning: data)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Get average heart rate for a date
    public func getAverageHeartRate(for date: Date) async throws -> Double? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.invalidType
        }
        
        let status = healthStore.authorizationStatus(for: heartRateType)
        guard status == .sharingAuthorized else {
            if status == .notDetermined {
                throw HealthKitError.authorizationNotDetermined
            } else {
                throw HealthKitError.authorizationDenied
            }
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw HealthKitError.invalidDateRange
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
                    return
                }
                
                let avgHeartRate = result?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: avgHeartRate)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Sleep Analysis
    
    /// Get sleep data for a specific date
    public func getSleepData(for date: Date) async throws -> SleepSummary {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.invalidType
        }
        
        let status = healthStore.authorizationStatus(for: sleepType)
        guard status == .sharingAuthorized else {
            if status == .notDetermined {
                throw HealthKitError.authorizationNotDetermined
            } else {
                throw HealthKitError.authorizationDenied
            }
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw HealthKitError.invalidDateRange
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
                    return
                }
                
                let sleepSamples = (samples as? [HKCategorySample])?.map { sample in
                    SleepAnalysis(
                        startDate: sample.startDate,
                        endDate: sample.endDate,
                        value: sample.value,
                        source: sample.sourceRevision.source.name
                    )
                } ?? []
                
                let summary = self.calculateSleepSummary(from: sleepSamples)
                continuation.resume(returning: summary)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Observer Queries (Real-time Updates)
    
    /// Start observing steps changes for real-time updates
    public func startObservingSteps(handler: @escaping (Double) -> Void) throws {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.invalidType
        }
        
        let status = healthStore.authorizationStatus(for: stepType)
        guard status == .sharingAuthorized else {
            throw HealthKitError.authorizationDenied
        }
        
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                print("Observer query error: \(error)")
                completionHandler()
                return
            }
            
            Task {
                do {
                    let steps = try await self?.getSteps(for: Date()) ?? 0
                    await MainActor.run {
                        handler(steps)
                    }
                } catch {
                    print("Error getting steps in observer: \(error)")
                }
                completionHandler()
            }
        }
        
        healthStore.execute(query)
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { success, error in
            if !success {
                print("Failed to enable background delivery: \(error?.localizedDescription ?? "unknown")")
            }
        }
    }
    
    /// Start observing heart rate changes
    public func startObservingHeartRate(handler: @escaping (HeartRateData?) -> Void) throws {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.invalidType
        }
        
        let status = healthStore.authorizationStatus(for: heartRateType)
        guard status == .sharingAuthorized else {
            throw HealthKitError.authorizationDenied
        }
        
        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                print("Observer query error: \(error)")
                completionHandler()
                return
            }
            
            Task {
                do {
                    let heartRate = try await self?.getLatestHeartRate()
                    await MainActor.run {
                        handler(heartRate)
                    }
                } catch {
                    print("Error getting heart rate in observer: \(error)")
                }
                completionHandler()
            }
        }
        
        healthStore.execute(query)
        
        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { success, error in
            if !success {
                print("Failed to enable background delivery: \(error?.localizedDescription ?? "unknown")")
            }
        }
    }
    
    // MARK: - Health Data Summary
    
    /// Get complete health data summary for dashboard
    public func getHealthDataSummary(for date: Date = Date()) async throws -> HealthDataSummary {
        async let stepsTask = getSteps(for: date)
        async let avgHeartRateTask = getAverageHeartRate(for: date)
        async let sleepTask = getSleepData(for: date)
        
        let steps = try await stepsTask
        let avgHeartRate = try? await avgHeartRateTask
        let sleep = try? await sleepTask
        
        return HealthDataSummary(
            date: date,
            steps: steps,
            averageHeartRate: avgHeartRate,
            sleepHours: sleep?.totalSleepHours,
            activeCalories: nil // Can be added later
        )
    }
    
    // MARK: - Cache Management
    
    private func getCachedData(key: String) -> Any? {
        guard let cached = cache[key],
              Date().timeIntervalSince(cached.timestamp) < cacheTTL else {
            cache.removeValue(forKey: key)
            return nil
        }
        return cached.data
    }
    
    private func setCachedData(key: String, data: Any) {
        cache[key] = (data: data, timestamp: Date())
    }
    
    /// Clear cache (useful for testing or when data is updated)
    public func clearCache() {
        cache.removeAll()
    }
    
    // MARK: - Helpers
    
    private func authorizationStatusToString(_ status: HKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "notDetermined"
        case .sharingDenied:
            return "denied"
        case .sharingAuthorized:
            return "authorized"
        @unknown default:
            return "unknown"
        }
    }
    
    private func calculateSleepSummary(from samples: [SleepAnalysis]) -> SleepSummary {
        let date = samples.first?.startDate ?? Date()
        
        var inBedDuration: TimeInterval = 0
        var asleepDuration: TimeInterval = 0
        var awakeDuration: TimeInterval = 0
        
        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            
            // Map HKCategoryValueSleepAnalysis values
            // 0 = inBed, 1 = asleep, 2 = awake
            switch sample.value {
            case 0: // inBed
                inBedDuration += duration
            case 1: // asleep
                asleepDuration += duration
            case 2: // awake
                awakeDuration += duration
            default:
                break
            }
        }
        
        let totalSleep = asleepDuration / 3600 // Convert to hours
        let inBedHours = inBedDuration / 3600
        let asleepHours = asleepDuration / 3600
        let awakeHours = awakeDuration / 3600
        
        return SleepSummary(
            date: date,
            totalSleepHours: totalSleep,
            inBedHours: inBedHours,
            asleepHours: asleepHours,
            awakeHours: awakeHours,
            samples: samples
        )
    }
}
