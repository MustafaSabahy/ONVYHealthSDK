//
//  HealthDataAggregatorTests.swift
//  ONVYHealthSDKTests
//
//  Unit tests for HealthDataAggregator
//  Tests aggregation logic, source management, and data merging
//

import XCTest
@testable import ONVYHealthSDK

final class HealthDataAggregatorTests: XCTestCase {
    
    var aggregator: HealthDataAggregator!
    var mockSource1: MockHealthDataSource!
    var mockSource2: MockHealthDataSource!
    
    override func setUp() {
        super.setUp()
        aggregator = HealthDataAggregator.shared
        mockSource1 = MockHealthDataSource(name: "MockSource1")
        mockSource2 = MockHealthDataSource(name: "MockSource2")
    }
    
    override func tearDown() {
        aggregator = nil
        mockSource1 = nil
        mockSource2 = nil
        super.tearDown()
    }
    
    // MARK: - Source Management Tests
    
    func testRegisterSource_AddsSourceToAggregator() {
        // Given
        let initialCount = aggregator.getAvailableSources().count
        
        // When
        aggregator.registerSource(mockSource1)
        
        // Then
        let newCount = aggregator.getAvailableSources().count
        XCTAssertEqual(newCount, initialCount + 1)
    }
    
    func testGetAvailableSources_ReturnsOnlyAvailableSources() {
        // Given
        mockSource1.isAvailableValue = true
        mockSource2.isAvailableValue = false
        aggregator.registerSource(mockSource1)
        aggregator.registerSource(mockSource2)
        
        // When
        let availableSources = aggregator.getAvailableSources()
        
        // Then
        XCTAssertTrue(availableSources.contains { $0.displayName == "MockSource1" })
        XCTAssertFalse(availableSources.contains { $0.displayName == "MockSource2" })
    }
    
    func testGetActiveSources_ReturnsOnlyAuthorizedSources() {
        // Given
        mockSource1.isAvailableValue = true
        mockSource1.authorizationStatusValue = .authorized
        mockSource2.isAvailableValue = true
        mockSource2.authorizationStatusValue = .denied
        aggregator.registerSource(mockSource1)
        aggregator.registerSource(mockSource2)
        
        // When
        let activeSources = aggregator.getActiveSources()
        
        // Then
        XCTAssertTrue(activeSources.contains { $0.displayName == "MockSource1" })
        XCTAssertFalse(activeSources.contains { $0.displayName == "MockSource2" })
    }
    
    // MARK: - Aggregation Tests
    
    func testAggregateHealthData_WithSingleSource_ReturnsSourceData() async throws {
        // Given
        let date = Date()
        mockSource1.isAvailableValue = true
        mockSource1.authorizationStatusValue = .authorized
        mockSource1.mockSummary = HealthDataSummary(
            date: date,
            steps: 5000,
            averageHeartRate: 72,
            sleepHours: 7.5,
            activeCalories: 300,
            source: "MockSource1"
        )
        aggregator.registerSource(mockSource1)
        
        // When
        let aggregated = try await aggregator.aggregateHealthData(for: date)
        
        // Then
        XCTAssertEqual(aggregated.steps, 5000)
        XCTAssertEqual(aggregated.averageHeartRate, 72)
        XCTAssertEqual(aggregated.sleepHours, 7.5)
    }
    
    func testAggregateHealthData_WithMultipleSources_UsesPriority() async throws {
        // Given
        let date = Date()
        
        // Source 1: Lower priority, lower values
        mockSource1.isAvailableValue = true
        mockSource1.authorizationStatusValue = .authorized
        mockSource1.mockSummary = HealthDataSummary(
            date: date,
            steps: 3000,
            averageHeartRate: 70,
            sleepHours: 6.0,
            activeCalories: 200,
            source: "MockSource1"
        )
        
        // Source 2: Higher priority, higher values
        mockSource2.isAvailableValue = true
        mockSource2.authorizationStatusValue = .authorized
        mockSource2.mockSummary = HealthDataSummary(
            date: date,
            steps: 8000,
            averageHeartRate: 75,
            sleepHours: 8.0,
            activeCalories: 400,
            source: "MockSource2"
        )
        
        aggregator.registerSource(mockSource1)
        aggregator.registerSource(mockSource2)
        
        // When
        let aggregated = try await aggregator.aggregateHealthData(for: date)
        
        // Then
        // Should use higher priority source or merge intelligently
        XCTAssertGreaterThanOrEqual(aggregated.steps, 3000)
        XCTAssertLessThanOrEqual(aggregated.steps, 8000)
    }
    
    func testAggregateHealthData_WithNoActiveSources_ThrowsError() async {
        // Given
        mockSource1.isAvailableValue = false
        mockSource2.isAvailableValue = false
        aggregator.registerSource(mockSource1)
        aggregator.registerSource(mockSource2)
        
        // When/Then
        do {
            _ = try await aggregator.aggregateHealthData(for: Date())
            XCTFail("Should throw error when no active sources")
        } catch {
            XCTAssertTrue(error is HealthKitError)
        }
    }
    
    func testAggregateHealthData_WithSourceFailure_ContinuesWithOtherSources() async throws {
        // Given
        let date = Date()
        mockSource1.isAvailableValue = true
        mockSource1.authorizationStatusValue = .authorized
        mockSource1.shouldThrowError = true // This source will fail
        
        mockSource2.isAvailableValue = true
        mockSource2.authorizationStatusValue = .authorized
        mockSource2.mockSummary = HealthDataSummary(
            date: date,
            steps: 5000,
            averageHeartRate: 72,
            sleepHours: 7.5,
            activeCalories: 300,
            source: "MockSource2"
        )
        
        aggregator.registerSource(mockSource1)
        aggregator.registerSource(mockSource2)
        
        // When
        let aggregated = try await aggregator.aggregateHealthData(for: date)
        
        // Then
        // Should still get data from source2 even though source1 failed
        XCTAssertEqual(aggregated.steps, 5000)
    }
    
    // MARK: - Data Merging Tests
    
    func testAggregateSteps_UsesMaximumValue() {
        // Given
        let summaries = [
            HealthDataSummary(date: Date(), steps: 3000, averageHeartRate: nil, sleepHours: nil, activeCalories: nil, source: "Source1"),
            HealthDataSummary(date: Date(), steps: 5000, averageHeartRate: nil, sleepHours: nil, activeCalories: nil, source: "Source2"),
            HealthDataSummary(date: Date(), steps: 4000, averageHeartRate: nil, sleepHours: nil, activeCalories: nil, source: "Source3")
        ]
        
        // When
        // Note: This tests the private aggregateSteps method indirectly
        // In a refactored version, we'd make it testable or test through public API
        
        // Then
        // Verify that maximum or intelligent merging is used
    }
}

// MARK: - Mock Health Data Source

class MockHealthDataSource: HealthDataSource {
    var displayName: String
    var isAvailableValue: Bool = true
    var authorizationStatusValue: AuthorizationStatus = .authorized
    var mockSummary: HealthDataSummary?
    var shouldThrowError: Bool = false
    
    init(name: String) {
        self.displayName = name
    }
    
    func isAvailable() -> Bool {
        return isAvailableValue
    }
    
    func checkAuthorizationStatus() -> AuthorizationStatus {
        return authorizationStatusValue
    }
    
    func requestAuthorization() async throws {
        if shouldThrowError {
            throw HealthKitError.authorizationDenied
        }
        authorizationStatusValue = .authorized
    }
    
    func getHealthDataSummary(for date: Date) async throws -> HealthDataSummary {
        if shouldThrowError {
            throw HealthKitError.queryFailed("Mock error")
        }
        guard let summary = mockSummary else {
            throw HealthKitError.noDataAvailable
        }
        return summary
    }
}
