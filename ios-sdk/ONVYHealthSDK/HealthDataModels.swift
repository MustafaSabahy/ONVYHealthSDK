//
//  HealthDataModels.swift
//  ONVYHealthSDK
//
//  Data models for health data
//

import Foundation
import HealthKit

// MARK: - Health Data Models

/// Represents daily steps data
public struct DailySteps: Codable {
    public let date: Date
    public let steps: Double
    public let source: String?
    
    public init(date: Date, steps: Double, source: String? = nil) {
        self.date = date
        self.steps = steps
        self.source = source
    }
}

/// Represents heart rate data point
public struct HeartRateData: Codable {
    public let value: Double
    public let timestamp: Date
    public let source: String?
    
    public init(value: Double, timestamp: Date, source: String? = nil) {
        self.value = value
        self.timestamp = timestamp
        self.source = source
    }
}

/// Represents sleep analysis data
public struct SleepAnalysis: Codable {
    public let startDate: Date
    public let endDate: Date
    public let value: Int // HKCategoryValueSleepAnalysis rawValue
    public let source: String?
    
    public init(startDate: Date, endDate: Date, value: Int, source: String? = nil) {
        self.startDate = startDate
        self.endDate = endDate
        self.value = value
        self.source = source
    }
}

/// Sleep summary for a specific date
public struct SleepSummary: Codable {
    public let date: Date
    public let totalSleepHours: Double
    public let inBedHours: Double
    public let asleepHours: Double
    public let awakeHours: Double
    public let samples: [SleepAnalysis]
    
    public init(date: Date, totalSleepHours: Double, inBedHours: Double, asleepHours: Double, awakeHours: Double, samples: [SleepAnalysis]) {
        self.date = date
        self.totalSleepHours = totalSleepHours
        self.inBedHours = inBedHours
        self.asleepHours = asleepHours
        self.awakeHours = awakeHours
        self.samples = samples
    }
}

/// Health data summary for dashboard
public struct HealthDataSummary: Codable {
    public let date: Date
    public let steps: Double
    public let averageHeartRate: Double?
    public let sleepHours: Double?
    public let activeCalories: Double?
    
    public init(date: Date, steps: Double, averageHeartRate: Double? = nil, sleepHours: Double? = nil, activeCalories: Double? = nil) {
        self.date = date
        self.steps = steps
        self.averageHeartRate = averageHeartRate
        self.sleepHours = sleepHours
        self.activeCalories = activeCalories
    }
}

// MARK: - Backend API Models

/// Payload for sending health data to backend/BI
public struct HealthDataPayload: Codable {
    public let userId: String?
    public let timestamp: Date
    public let data: HealthDataSummary
    public let metadata: PayloadMetadata
    
    public init(userId: String? = nil, timestamp: Date = Date(), data: HealthDataSummary, metadata: PayloadMetadata) {
        self.userId = userId
        self.timestamp = timestamp
        self.data = data
        self.metadata = metadata
    }
}

public struct PayloadMetadata: Codable {
    public let sdkVersion: String
    public let platform: String
    public let deviceModel: String?
    public let timezone: String
    
    public init(sdkVersion: String = "1.0.0", platform: String = "iOS", deviceModel: String? = nil, timezone: String = TimeZone.current.identifier) {
        self.sdkVersion = sdkVersion
        self.platform = platform
        self.deviceModel = deviceModel
        self.timezone = timezone
    }
}
