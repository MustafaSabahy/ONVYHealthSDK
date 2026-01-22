//
//  ONVYHealthKitModule.swift
//  ONVYHealthKitModule
//
//  React Native bridge for ONVY Health SDK
//  Supports multiple data sources and aggregation
//

import Foundation
import React

@objc(ONVYHealthKitModule)
class ONVYHealthKitModule: RCTEventEmitter {
    
    // MARK: - Properties
    
    private let healthKitManager = HealthKitManager.shared
    private let apiClient = APIClient.shared
    private let aggregator = HealthDataAggregator.shared
    
    // Current data source selection
    private var currentSource: String = "aggregated"
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    override static func requiresMainQueueSetup() -> Bool {
        return false
    }
    
    // MARK: - Supported Events
    
    override func supportedEvents() -> [String]! {
        return [
            "healthDataUpdated",
            "heartRateUpdated",
            "authorizationStatusChanged",
            "sourceChanged",
            "liveUpdate"
        ]
    }
    
    // MARK: - Data Source Selection
    
    /// Switch between data sources
    @objc
    func setDataSource(_ source: String,
                      resolve: @escaping RCTPromiseResolveBlock,
                      rejecter reject: @escaping RCTPromiseRejectBlock) {
        currentSource = source
        
        // Notify React Native of source change
        sendEvent(withName: "sourceChanged", body: ["source": source])
        
        resolve(["success": true, "source": source])
    }
    
    /// Get available data sources
    @objc
    func getAvailableSources(_ resolve: @escaping RCTPromiseResolveBlock,
                            rejecter reject: @escaping RCTPromiseRejectBlock) {
        let sources = aggregator.getAvailableSources().map { source in
            [
                "id": source.sourceId,
                "name": source.displayName,
                "authorized": source.checkAuthorizationStatus() == .authorized
            ]
        }
        
        resolve(["sources": sources])
    }
    
    // MARK: - Authorization
    
    /// Request authorization for all sources
    @objc
    func requestAuthorization(_ resolve: @escaping RCTPromiseResolveBlock,
                             rejecter reject: @escaping RCTPromiseRejectBlock) {
        Task {
            do {
                // Request HealthKit authorization
                try await healthKitManager.requestAuthorization()
                
                // Request mock sources authorization
                let mockSources = aggregator.getAvailableSources().filter { $0.sourceId.contains("mock") }
                for source in mockSources {
                    try? await source.requestAuthorization()
                }
                
                let status = aggregator.getActiveSources().map { $0.displayName }
                
                await MainActor.run {
                    sendEvent(withName: "authorizationStatusChanged", body: ["sources": status])
                    resolve(["status": "authorized", "sources": status])
                }
            } catch let error as HealthKitError {
                await MainActor.run {
                    reject(error.code, error.localizedDescription, error)
                }
            } catch {
                await MainActor.run {
                    reject("UNKNOWN_ERROR", error.localizedDescription, error)
                }
            }
        }
    }
    
    /// Check current authorization status
    @objc
    func checkAuthorizationStatus(_ resolve: @escaping RCTPromiseResolveBlock,
                                 rejecter reject: @escaping RCTPromiseRejectBlock) {
        let sources = aggregator.getAvailableSources()
        var status: [String: String] = [:]
        
        for source in sources {
            let authStatus = source.checkAuthorizationStatus()
            status[source.sourceId] = authStatusToString(authStatus)
        }
        
        resolve(["status": status])
    }
    
    // MARK: - Steps
    
    /// Get steps for a specific date
    @objc
    func getSteps(_ date: NSNumber?,
                  resolve: @escaping RCTPromiseResolveBlock,
                  rejecter reject: @escaping RCTPromiseRejectBlock) {
        let targetDate = date != nil ? Date(timeIntervalSince1970: date!.doubleValue / 1000) : Date()
        
        Task {
            do {
                let steps: Double
                
                if currentSource == "aggregated" {
                    // Use aggregator for combined data
                    let aggregated = try await aggregator.aggregateHealthData(for: targetDate)
                    steps = aggregated.steps
                } else {
                    // Use specific source
                    steps = try await healthKitManager.getSteps(for: targetDate)
                }
                
                await MainActor.run {
                    resolve([
                        "steps": steps,
                        "date": targetDate.timeIntervalSince1970 * 1000,
                        "source": currentSource
                    ])
                }
            } catch let error as HealthKitError {
                await MainActor.run {
                    reject(error.code, error.localizedDescription, error)
                }
            } catch {
                await MainActor.run {
                    reject("STEPS_ERROR", error.localizedDescription, error)
                }
            }
        }
    }
    
    /// Get steps for multiple days (weekly trends)
    @objc
    func getStepsForDays(_ days: NSNumber,
                        resolve: @escaping RCTPromiseResolveBlock,
                        rejecter reject: @escaping RCTPromiseRejectBlock) {
        Task {
            do {
                if currentSource == "aggregated" {
                    // Get weekly trends from aggregator
                    let trends = try await aggregator.getWeeklyTrends()
                    let data = trends.map { trend in
                        [
                            "date": trend.date.timeIntervalSince1970 * 1000,
                            "steps": trend.steps,
                            "sources": trend.sources
                        ] as [String: Any]
                    }
                    
                    await MainActor.run {
                        resolve(["data": data, "source": "aggregated"])
                    }
                } else {
                    // Use HealthKit only
                    let dailySteps = try await healthKitManager.getStepsForDays(days.intValue)
                    let data = dailySteps.map { daily in
                        [
                            "date": daily.date.timeIntervalSince1970 * 1000,
                            "steps": daily.steps,
                            "source": daily.source ?? "healthkit"
                        ] as [String: Any]
                    }
                    
                    await MainActor.run {
                        resolve(["data": data, "source": "healthkit"])
                    }
                }
            } catch let error as HealthKitError {
                await MainActor.run {
                    reject(error.code, error.localizedDescription, error)
                }
            } catch {
                await MainActor.run {
                    reject("STEPS_WEEK_ERROR", error.localizedDescription, error)
                }
            }
        }
    }
    
    // MARK: - Heart Rate
    
    /// Get latest heart rate
    @objc
    func getLatestHeartRate(_ resolve: @escaping RCTPromiseResolveBlock,
                           rejecter reject: @escaping RCTPromiseRejectBlock) {
        Task {
            do {
                let heartRate: HeartRateData?
                
                if currentSource == "aggregated" {
                    let aggregated = try await aggregator.aggregateHealthData(for: Date())
                    if let hr = aggregated.averageHeartRate {
                        heartRate = HeartRateData(value: hr, timestamp: Date())
                    } else {
                        heartRate = nil
                    }
                } else {
                    heartRate = try await healthKitManager.getLatestHeartRate()
                }
                
                await MainActor.run {
                    if let hr = heartRate {
                        resolve([
                            "heartRate": hr.value,
                            "timestamp": hr.timestamp.timeIntervalSince1970 * 1000,
                            "source": hr.source ?? currentSource
                        ])
                    } else {
                        resolve([
                            "heartRate": NSNull(),
                            "timestamp": NSNull(),
                            "source": NSNull()
                        ])
                    }
                }
            } catch let error as HealthKitError {
                await MainActor.run {
                    reject(error.code, error.localizedDescription, error)
                }
            } catch {
                await MainActor.run {
                    reject("HEART_RATE_ERROR", error.localizedDescription, error)
                }
            }
        }
    }
    
    /// Get average heart rate for a date
    @objc
    func getAverageHeartRate(_ date: NSNumber?,
                            resolve: @escaping RCTPromiseResolveBlock,
                            rejecter reject: @escaping RCTPromiseRejectBlock) {
        let targetDate = date != nil ? Date(timeIntervalSince1970: date!.doubleValue / 1000) : Date()
        
        Task {
            do {
                let avgHeartRate: Double?
                
                if currentSource == "aggregated" {
                    let aggregated = try await aggregator.aggregateHealthData(for: targetDate)
                    avgHeartRate = aggregated.averageHeartRate
                } else {
                    avgHeartRate = try await healthKitManager.getAverageHeartRate(for: targetDate)
                }
                
                await MainActor.run {
                    resolve([
                        "averageHeartRate": avgHeartRate ?? NSNull(),
                        "date": targetDate.timeIntervalSince1970 * 1000
                    ])
                }
            } catch let error as HealthKitError {
                await MainActor.run {
                    reject(error.code, error.localizedDescription, error)
                }
            } catch {
                await MainActor.run {
                    reject("AVG_HEART_RATE_ERROR", error.localizedDescription, error)
                }
            }
        }
    }
    
    // MARK: - Sleep
    
    /// Get sleep data for a date
    @objc
    func getSleepData(_ date: NSNumber?,
                     resolve: @escaping RCTPromiseResolveBlock,
                     rejecter reject: @escaping RCTPromiseRejectBlock) {
        let targetDate = date != nil ? Date(timeIntervalSince1970: date!.doubleValue / 1000) : Date()
        
        Task {
            do {
                let sleepSummary: SleepSummary
                
                if currentSource == "aggregated" {
                    let aggregated = try await aggregator.aggregateHealthData(for: targetDate)
                    // Create mock sleep summary from aggregated data
                    sleepSummary = SleepSummary(
                        date: targetDate,
                        totalSleepHours: aggregated.sleepHours ?? 0,
                        inBedHours: aggregated.sleepHours ?? 0,
                        asleepHours: aggregated.sleepHours ?? 0,
                        awakeHours: 0,
                        samples: []
                    )
                } else {
                    sleepSummary = try await healthKitManager.getSleepData(for: targetDate)
                }
                
                let samples = sleepSummary.samples.map { sample in
                    [
                        "startDate": sample.startDate.timeIntervalSince1970 * 1000,
                        "endDate": sample.endDate.timeIntervalSince1970 * 1000,
                        "value": sample.value,
                        "source": sample.source ?? NSNull()
                    ] as [String: Any]
                }
                
                await MainActor.run {
                    resolve([
                        "date": targetDate.timeIntervalSince1970 * 1000,
                        "totalSleepHours": sleepSummary.totalSleepHours,
                        "inBedHours": sleepSummary.inBedHours,
                        "asleepHours": sleepSummary.asleepHours,
                        "awakeHours": sleepSummary.awakeHours,
                        "samples": samples
                    ])
                }
            } catch let error as HealthKitError {
                await MainActor.run {
                    reject(error.code, error.localizedDescription, error)
                }
            } catch {
                await MainActor.run {
                    reject("SLEEP_ERROR", error.localizedDescription, error)
                }
            }
        }
    }
    
    // MARK: - Health Data Summary
    
    /// Get complete health data summary for dashboard
    @objc
    func getHealthDataSummary(_ date: NSNumber?,
                             resolve: @escaping RCTPromiseResolveBlock,
                             rejecter reject: @escaping RCTPromiseRejectBlock) {
        let targetDate = date != nil ? Date(timeIntervalSince1970: date!.doubleValue / 1000) : Date()
        
        Task {
            do {
                let summary: HealthDataSummary
                let sources: [String]
                
                if currentSource == "aggregated" {
                    let aggregated = try await aggregator.aggregateHealthData(for: targetDate)
                    summary = HealthDataSummary(
                        date: aggregated.date,
                        steps: aggregated.steps,
                        averageHeartRate: aggregated.averageHeartRate,
                        sleepHours: aggregated.sleepHours,
                        activeCalories: aggregated.activeCalories
                    )
                    sources = aggregated.sources
                } else {
                    summary = try await healthKitManager.getHealthDataSummary(for: targetDate)
                    sources = [currentSource]
                }
                
                await MainActor.run {
                    resolve([
                        "date": summary.date.timeIntervalSince1970 * 1000,
                        "steps": summary.steps,
                        "averageHeartRate": summary.averageHeartRate ?? NSNull(),
                        "sleepHours": summary.sleepHours ?? NSNull(),
                        "activeCalories": summary.activeCalories ?? NSNull(),
                        "sources": sources
                    ])
                }
            } catch let error as HealthKitError {
                await MainActor.run {
                    reject(error.code, error.localizedDescription, error)
                }
            } catch {
                await MainActor.run {
                    reject("SUMMARY_ERROR", error.localizedDescription, error)
                }
            }
        }
    }
    
    /// Get weekly trends
    @objc
    func getWeeklyTrends(_ resolve: @escaping RCTPromiseResolveBlock,
                        rejecter reject: @escaping RCTPromiseRejectBlock) {
        Task {
            do {
                let trends = try await aggregator.getWeeklyTrends()
                let data = trends.map { trend in
                    [
                        "date": trend.date.timeIntervalSince1970 * 1000,
                        "steps": trend.steps,
                        "averageHeartRate": trend.averageHeartRate ?? NSNull(),
                        "sleepHours": trend.sleepHours ?? NSNull(),
                        "activeCalories": trend.activeCalories ?? NSNull(),
                        "sources": trend.sources
                    ] as [String: Any]
                }
                
                await MainActor.run {
                    resolve(["data": data])
                }
            } catch let error as HealthKitError {
                await MainActor.run {
                    reject(error.code, error.localizedDescription, error)
                }
            } catch {
                await MainActor.run {
                    reject("TRENDS_ERROR", error.localizedDescription, error)
                }
            }
        }
    }
    
    // MARK: - Observers (Real-time Updates)
    
    /// Start observing steps changes
    @objc
    func startObservingSteps() {
        do {
            if currentSource == "aggregated" {
                // Observe from all active sources
                let activeSources = aggregator.getActiveSources()
                for source in activeSources {
                    try? source.startObserving { [weak self] summary in
                        self?.sendEvent(withName: "healthDataUpdated", body: [
                            "type": "steps",
                            "value": summary.steps,
                            "timestamp": Date().timeIntervalSince1970 * 1000,
                            "source": source.displayName
                        ])
                    }
                }
            } else {
                try healthKitManager.startObservingSteps { [weak self] steps in
                    self?.sendEvent(withName: "healthDataUpdated", body: [
                        "type": "steps",
                        "value": steps,
                        "timestamp": Date().timeIntervalSince1970 * 1000,
                        "source": "healthkit"
                    ])
                }
            }
        } catch {
            print("Failed to start observing steps: \(error)")
        }
    }
    
    /// Start observing heart rate changes
    @objc
    func startObservingHeartRate() {
        do {
            try healthKitManager.startObservingHeartRate { [weak self] heartRate in
                if let hr = heartRate {
                    self?.sendEvent(withName: "heartRateUpdated", body: [
                        "value": hr.value,
                        "timestamp": hr.timestamp.timeIntervalSince1970 * 1000,
                        "source": hr.source ?? "healthkit"
                    ])
                }
            }
        } catch {
            print("Failed to start observing heart rate: \(error)")
        }
    }
    
    /// Start simulated live updates for demo
    @objc
    func startSimulatedLiveUpdates() {
        // Simulate updates every 3 seconds
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] timer in
            Task {
                do {
                    let aggregated = try await self?.aggregator.aggregateHealthData(for: Date())
                    if let data = aggregated {
                        self?.sendEvent(withName: "liveUpdate", body: [
                            "steps": data.steps + Double.random(in: -50...50),
                            "heartRate": data.averageHeartRate ?? 0 + Double.random(in: -2...2),
                            "timestamp": Date().timeIntervalSince1970 * 1000,
                            "sources": data.sources
                        ])
                    }
                } catch {
                    // Ignore errors in simulation
                }
            }
        }
    }
    
    // MARK: - Backend Integration
    
    /// Send health data to backend/BI
    @objc
    func sendHealthDataToBackend(_ date: NSNumber?,
                                resolve: @escaping RCTPromiseResolveBlock,
                                rejecter reject: @escaping RCTPromiseRejectBlock) {
        let targetDate = date != nil ? Date(timeIntervalSince1970: date!.doubleValue / 1000) : Date()
        
        Task {
            do {
                let summary: HealthDataSummary
                
                if currentSource == "aggregated" {
                    let aggregated = try await aggregator.aggregateHealthData(for: targetDate)
                    summary = HealthDataSummary(
                        date: aggregated.date,
                        steps: aggregated.steps,
                        averageHeartRate: aggregated.averageHeartRate,
                        sleepHours: aggregated.sleepHours,
                        activeCalories: aggregated.activeCalories
                    )
                } else {
                    summary = try await healthKitManager.getHealthDataSummary(for: targetDate)
                }
                
                let metadata = PayloadMetadata(
                    sdkVersion: "1.0.0",
                    platform: "iOS",
                    deviceModel: UIDevice.current.model,
                    timezone: TimeZone.current.identifier
                )
                
                let payload = HealthDataPayload(
                    userId: apiClient.userId,
                    timestamp: Date(),
                    data: summary,
                    metadata: metadata
                )
                
                // Use mock for demo
                let success = await apiClient.sendHealthDataMock(payload)
                
                await MainActor.run {
                    resolve(["success": success])
                }
            } catch let error as HealthKitError {
                await MainActor.run {
                    reject(error.code, error.localizedDescription, error)
                }
            } catch {
                await MainActor.run {
                    reject("BACKEND_ERROR", error.localizedDescription, error)
                }
            }
        }
    }
    
    // MARK: - Cache Management
    
    @objc
    func clearCache(_ resolve: @escaping RCTPromiseResolveBlock,
                   rejecter reject: @escaping RCTPromiseRejectBlock) {
        healthKitManager.clearCache()
        resolve(["success": true])
    }
    
    // MARK: - Helpers
    
    private func authorizationStatusToString(_ status: AuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "notDetermined"
        case .denied:
            return "denied"
        case .authorized:
            return "authorized"
        }
    }
}
