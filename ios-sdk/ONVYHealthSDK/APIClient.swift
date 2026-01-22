//
//  APIClient.swift
//  ONVYHealthSDK
//
//  Mock API client for backend/BI integration
//

import Foundation

/// API client for sending health data to backend/BI
public protocol APIClientProtocol {
    func sendHealthData(_ payload: HealthDataPayload) async throws -> Bool
}

public class APIClient: APIClientProtocol {
    
    // MARK: - Properties
    
    public static let shared = APIClient()
    
    /// Base URL for API
    public var baseURL: String = "https://api.onvy.health/v1"
    
    /// User ID for API calls
    public var userId: String?
    
    private let session: URLSession
    
    // MARK: - Initialization
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - API Methods
    
    /// Send health data to backend
    public func sendHealthData(_ payload: HealthDataPayload) async throws -> Bool {
        // Create payload with user ID if available
        var finalPayload = payload
        if let userId = userId {
            finalPayload = HealthDataPayload(
                userId: userId,
                timestamp: payload.timestamp,
                data: payload.data,
                metadata: payload.metadata
            )
        }
        
        guard let url = URL(string: "\(baseURL)/health-data") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode payload
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let jsonData = try encoder.encode(finalPayload)
            request.httpBody = jsonData
            
            // Log request for demo purposes
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 Sending health data to backend:")
                print(jsonString)
            }
            
        } catch {
            throw APIError.encodingFailed(error.localizedDescription)
        }
        
        // Perform request
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // For demo: Accept 200-299 as success
            // In production, handle different status codes appropriately
            if (200...299).contains(httpResponse.statusCode) {
                print("✅ Health data sent successfully")
                return true
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw APIError.serverError(httpResponse.statusCode, errorMessage)
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
    }
    
    /// Mock method for demo purposes
    /// Simulates successful API call without actual network request
    public func sendHealthDataMock(_ payload: HealthDataPayload) async -> Bool {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Log mock payload
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        if let jsonData = try? encoder.encode(payload),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 [MOCK] Sending health data to backend:")
            print(jsonString)
        }
        
        print("✅ [MOCK] Health data sent successfully")
        return true
    }
}

// MARK: - API Errors

public enum APIError: Error, LocalizedError {
    case invalidURL
    case encodingFailed(String)
    case networkError(String)
    case invalidResponse
    case serverError(Int, String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .encodingFailed(let message):
            return "Failed to encode payload: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code, let message):
            return "Server error \(code): \(message)"
        }
    }
}
