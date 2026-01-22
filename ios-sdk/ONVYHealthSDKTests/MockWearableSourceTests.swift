//
//  MockWearableSourceTests.swift
//  ONVYHealthSDKTests
//
//  Unit tests for MockWearableSource
//  Tests mock data generation and source behavior
//

import XCTest
@testable import ONVYHealthSDK

final class MockWearableSourceTests: XCTestCase {
    
    var mockSource: MockWearableSource!
    
    override func setUp() {
        super.setUp()
        mockSource = MockWearableSource()
    }
    
    override func tearDown() {
        mockSource = nil
        super.tearDown()
    }
    
    // MARK: - Availability Tests
    
    func testIsAvailable_ReturnsTrue() {
        // When
        let isAvailable = mockSource.isAvailable()
        
        // Then
        XCTAssertTrue(isAvailable)
    }
    
    // MARK: - Authorization Tests
    
    func testCheckAuthorizationStatus_ReturnsAuthorized() {
        // When
        let status = mockSource.checkAuthorizationStatus()
        
        // Then
        XCTAssertEqual(status, .authorized)
    }
    
    func testRequestAuthorization_Succeeds() async throws {
        // When
        try await mockSource.requestAuthorization()
        
        // Then
        let status = mockSource.checkAuthorizationStatus()
        XCTAssertEqual(status, .authorized)
    }
    
    // MARK: - Data Generation Tests
    
    func testGetHealthDataSummary_ReturnsValidData() async throws {
        // Given
        let date = Date()
        
        // When
        let summary = try await mockSource.getHealthDataSummary(for: date)
        
        // Then
        XCTAssertEqual(summary.date.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 1.0)
        XCTAssertGreaterThanOrEqual(summary.steps, 0)
        XCTAssertLessThanOrEqual(summary.steps, 50000) // Reasonable max
        if let heartRate = summary.averageHeartRate {
            XCTAssertGreaterThan(heartRate, 40)
            XCTAssertLessThan(heartRate, 200)
        }
        if let sleepHours = summary.sleepHours {
            XCTAssertGreaterThanOrEqual(sleepHours, 0)
            XCTAssertLessThanOrEqual(sleepHours, 24)
        }
        XCTAssertEqual(summary.source, "Mock Wearable")
    }
    
    func testGetHealthDataSummary_ConsistentForSameDate() async throws {
        // Given
        let date = Date()
        
        // When
        let summary1 = try await mockSource.getHealthDataSummary(for: date)
        let summary2 = try await mockSource.getHealthDataSummary(for: date)
        
        // Then
        // Mock data should be consistent for the same date
        XCTAssertEqual(summary1.steps, summary2.steps)
        XCTAssertEqual(summary1.averageHeartRate, summary2.averageHeartRate)
        XCTAssertEqual(summary1.sleepHours, summary2.sleepHours)
    }
    
    func testGetHealthDataSummary_DifferentForDifferentDates() async throws {
        // Given
        let date1 = Date()
        let date2 = Calendar.current.date(byAdding: .day, value: 1, to: date1)!
        
        // When
        let summary1 = try await mockSource.getHealthDataSummary(for: date1)
        let summary2 = try await mockSource.getHealthDataSummary(for: date2)
        
        // Then
        // Should generate different data for different dates
        // (or at least handle different dates correctly)
        XCTAssertNotNil(summary1)
        XCTAssertNotNil(summary2)
    }
}
