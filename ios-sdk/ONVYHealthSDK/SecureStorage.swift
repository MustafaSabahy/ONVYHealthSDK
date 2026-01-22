//
//  SecureStorage.swift
//  ONVYHealthSDK
//
//  Secure storage for sensitive health data
//  Implements encryption and secure keychain storage
//

import Foundation
import Security
import CryptoKit

/// Secure storage manager for sensitive health data
/// Uses iOS Keychain with AES-256 encryption
public class SecureStorage {
    
    public static let shared = SecureStorage()
    
    private let keychainService = "com.onvy.healthsdk"
    private let encryptionKeyTag = "com.onvy.healthsdk.encryption.key"
    
    private init() {
        // Ensure encryption key exists
        ensureEncryptionKey()
    }
    
    // MARK: - Encryption Key Management
    
    /// Ensures encryption key exists in Keychain
    private func ensureEncryptionKey() {
        if getEncryptionKey() == nil {
            generateAndStoreEncryptionKey()
        }
    }
    
    /// Generates and stores a new encryption key
    private func generateAndStoreEncryptionKey() {
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: encryptionKeyTag,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing key if present
        SecItemDelete(query as CFDictionary)
        
        // Add new key
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            print("Failed to store encryption key: \(status)")
            return
        }
    }
    
    /// Retrieves encryption key from Keychain
    private func getEncryptionKey() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: encryptionKeyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            return nil
        }
        
        return SymmetricKey(data: keyData)
    }
    
    // MARK: - Secure Storage
    
    /// Stores encrypted data securely
    /// - Parameters:
    ///   - data: Data to encrypt and store
    ///   - key: Key for storage
    public func store(_ data: Data, forKey key: String) throws {
        guard let encryptionKey = getEncryptionKey() else {
            throw SecureStorageError.encryptionKeyNotFound
        }
        
        // Encrypt data
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        guard let encryptedData = sealedBox.combined else {
            throw SecureStorageError.encryptionFailed
        }
        
        // Store in Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: encryptedData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecureStorageError.storageFailed(status)
        }
    }
    
    /// Retrieves and decrypts stored data
    /// - Parameter key: Key for retrieval
    /// - Returns: Decrypted data
    public func retrieve(forKey key: String) throws -> Data? {
        guard let encryptionKey = getEncryptionKey() else {
            throw SecureStorageError.encryptionKeyNotFound
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let encryptedData = result as? Data else {
            return nil
        }
        
        // Decrypt data
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey)
        
        return decryptedData
    }
    
    /// Removes stored data
    /// - Parameter key: Key to remove
    public func remove(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    /// Clears all stored data
    public func clearAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Secure Storage Errors

public enum SecureStorageError: Error, LocalizedError {
    case encryptionKeyNotFound
    case encryptionFailed
    case storageFailed(OSStatus)
    case decryptionFailed
    
    public var errorDescription: String? {
        switch self {
        case .encryptionKeyNotFound:
            return "Encryption key not found in Keychain"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .storageFailed(let status):
            return "Failed to store data in Keychain: \(status)"
        case .decryptionFailed:
            return "Failed to decrypt data"
        }
    }
}
