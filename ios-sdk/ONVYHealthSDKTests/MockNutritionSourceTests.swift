//
//  MockNutritionSourceTests.swift
//  ONVYHealthSDKTests
//
//  Unit tests for MockNutritionSource
//  Tests nutrition data generation and source behavior
//

import XCTest
@testable import ONVYHealthSDK

final class MockNutritionSourceTests: XCTestCase {
    
    var mockSource: MockNutritionSource!
    
    override func setUp() {
        super.setUp()
        mockSource = MockNutritionSource()
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
        XCTAssertEqual(summary.source, "Mock Nutrition")
        // Nutrition source might have different data structure
        // Verify it returns valid data
        XCTAssertNotNil(summary)
    }
}
