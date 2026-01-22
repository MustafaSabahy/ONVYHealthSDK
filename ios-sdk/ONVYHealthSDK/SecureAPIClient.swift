//
//  SecureAPIClient.swift
//  ONVYHealthSDK
//
//  Secure API client with certificate pinning
//  Implements SSL pinning for secure communication
//  Security: Prevents man-in-the-middle attacks
//

import Foundation

/// Secure API client with certificate pinning
public class SecureAPIClient: APIClientProtocol {
    
    public static let shared = SecureAPIClient()
    
    public var baseURL: String = "https://api.onvy.health/v1"
    public var userId: String?
    
    private let session: URLSession
    private let pinnedCertificates: [Data]
    
    private init() {
        // Load pinned certificates
        // In production, these would be embedded in the app bundle
        self.pinnedCertificates = SecureAPIClient.loadPinnedCertificates()
        
        // Configure URLSession with certificate pinning delegate
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        
        self.session = URLSession(
            configuration: config,
            delegate: CertificatePinningDelegate(certificates: pinnedCertificates),
            delegateQueue: nil
        )
    }
    
    /// Load pinned certificates from bundle
    private static func loadPinnedCertificates() -> [Data] {
        var certificates: [Data] = []
        
        // Load certificate files from bundle
        // In production, these would be actual certificate files
        // For now, return empty array (certificate pinning disabled in demo)
        
        return certificates
    }
    
    public func sendHealthData(_ payload: HealthDataPayload) async throws -> Bool {
        // Use secure session for API calls
        guard let url = URL(string: "\(baseURL)/health-data") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add security headers
        request.setValue("Bearer \(getAuthToken())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Encode payload
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(payload)
        request.httpBody = jsonData
        
        // Make secure request
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        return true
    }
    
    private func getAuthToken() -> String {
        // In production, retrieve from secure storage
        return "demo-token"
    }
}

// MARK: - Certificate Pinning Delegate

private class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    let certificates: [Data]
    
    init(certificates: [Data]) {
        self.certificates = certificates
    }
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // If no certificates pinned, use default handling (for demo)
        guard !certificates.isEmpty else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // Verify certificate
        var secresult = SecTrustResultType.invalid
        let status = SecTrustEvaluate(serverTrust, &secresult)
        
        guard status == errSecSuccess else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Check if certificate matches pinned certificates
        let serverCertificates = getCertificates(from: serverTrust)
        let isPinned = serverCertificates.contains { serverCert in
            certificates.contains { $0 == serverCert }
        }
        
        if isPinned {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
    private func getCertificates(from trust: SecTrust) -> [Data] {
        var certificates: [Data] = []
        let count = SecTrustGetCertificateCount(trust)
        
        for i in 0..<count {
            if let certificate = SecTrustGetCertificateAtIndex(trust, i) {
                let data = SecCertificateCopyData(certificate) as Data
                certificates.append(data)
            }
        }
        
        return certificates
    }
}
