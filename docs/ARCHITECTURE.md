# ONVY Health SDK - Architecture Documentation

Comprehensive architecture documentation for the ONVY Health SDK.

## Table of Contents

1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Component Design](#component-design)
4. [Data Flow](#data-flow)
5. [Security Architecture](#security-architecture)
6. [Extension Points](#extension-points)

---

## Overview

The ONVY Health SDK is designed with a modular, extensible architecture that supports:

- **Multiple Data Sources**: HealthKit, Wearables, Nutrition, and more
- **Data Aggregation**: Unified view of health data from multiple sources
- **React Native Integration**: Seamless bridge between native iOS and React Native
- **Privacy-First**: GDPR/HIPAA compliant with minimal data storage
- **Production-Ready**: Comprehensive error handling, logging, and security

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    React Native App                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         TypeScript Service Layer                     │   │
│  │  (ONVYHealthKit.ts - Type-safe API)                 │   │
│  └──────────────────┬──────────────────────────────────┘   │
│                     │                                        │
└─────────────────────┼────────────────────────────────────────┘
                      │
                      │ React Native Bridge
                      │
┌─────────────────────▼────────────────────────────────────────┐
│              Native iOS Bridge Layer                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │    ONVYHealthKitModule (Swift + Objective-C)        │   │
│  │    - Method exposure                                  │   │
│  │    - Event emitters                                   │   │
│  │    - Promise handling                                 │   │
│  └──────────────────┬───────────────────────────────────┘   │
└─────────────────────┼────────────────────────────────────────┘
                      │
                      │ Native Calls
                      │
┌─────────────────────▼────────────────────────────────────────┐
│                  iOS SDK Core                                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         HealthDataAggregator                          │   │
│  │    - Source management                                │   │
│  │    - Data aggregation                                 │   │
│  │    - Conflict resolution                              │   │
│  └──────┬──────────────┬──────────────┬──────────────────┘   │
│         │              │              │                       │
│  ┌──────▼──────┐ ┌────▼──────┐ ┌────▼──────┐               │
│  │ HealthKit   │ │  Wearable │ │ Nutrition  │               │
│  │  Source     │ │  Source   │ │  Source    │               │
│  └──────┬──────┘ └───────────┘ └────────────┘               │
│         │                                                      │
│  ┌──────▼──────────────────────────────────────┐            │
│  │         HealthKitManager                     │            │
│  │    - Authorization                           │            │
│  │    - Data queries                            │            │
│  │    - Observer queries                        │            │
│  │    - Caching                                 │            │
│  └──────────────────────────────────────────────┘            │
└──────────────────────────────────────────────────────────────┘
```

---

## Component Design

### 1. HealthKitManager

**Responsibility**: Core HealthKit operations

**Design Patterns**:
- Singleton pattern for single HKHealthStore instance
- Async/await for modern concurrency
- Cache pattern for performance optimization

**Key Features**:
- Authorization management
- Data queries (steps, heart rate, sleep)
- Observer queries for real-time updates
- In-memory caching with TTL

**Privacy**: Only caches aggregated data, never raw samples

---

### 2. HealthDataAggregator

**Responsibility**: Aggregate data from multiple sources

**Design Patterns**:
- Aggregator pattern
- Strategy pattern for source selection
- Protocol-based design for extensibility

**Key Features**:
- Dynamic source registration
- Priority-based data selection
- Conflict resolution
- Source tracking

**Extensibility**: Easy to add new sources via `HealthDataSource` protocol

---

### 3. HealthDataSource Protocol

**Responsibility**: Define interface for health data sources

```swift
public protocol HealthDataSource {
    var displayName: String { get }
    func isAvailable() -> Bool
    func checkAuthorizationStatus() -> AuthorizationStatus
    func requestAuthorization() async throws
    func getHealthDataSummary(for date: Date) async throws -> HealthDataSummary
}
```

**Benefits**:
- Type-safe source interface
- Easy to add new sources
- Consistent API across sources
- Testable via protocol conformance

---

### 4. React Native Bridge

**Responsibility**: Bridge between React Native and iOS SDK

**Components**:
- `ONVYHealthKitModule.swift` - Swift implementation
- `ONVYHealthKitModule.m` - Objective-C bridge
- `ONVYHealthKit.ts` - TypeScript service layer

**Features**:
- Promise-based API
- Event emitters for real-time updates
- Type-safe TypeScript interface
- Error handling and translation

---

## Data Flow

### 1. Authorization Flow

```
React Native App
    │
    ├─> requestAuthorization()
    │
    ▼
React Native Bridge
    │
    ├─> ONVYHealthKitModule.requestAuthorization()
    │
    ▼
HealthKitManager
    │
    ├─> HKHealthStore.requestAuthorization()
    │
    ▼
HealthKit Framework
    │
    ├─> User Authorization Dialog
    │
    ▼
Authorization Result
    │
    └─> Promise Resolution
```

### 2. Data Reading Flow

```
React Native App
    │
    ├─> getHealthDataSummary()
    │
    ▼
React Native Bridge
    │
    ├─> ONVYHealthKitModule.getHealthDataSummary()
    │
    ▼
HealthDataAggregator
    │
    ├─> Get active sources
    │
    ├─> Fetch from each source
    │   ├─> HealthKit Source
    │   ├─> Wearable Source
    │   └─> Nutrition Source
    │
    ├─> Aggregate data
    │
    └─> Return aggregated result
```

### 3. Real-time Updates Flow

```
HealthKit Framework
    │
    ├─> Observer Query detects change
    │
    ▼
HealthKitManager
    │
    ├─> Process update
    │
    ├─> Update cache
    │
    └─> Emit event
        │
        ▼
React Native Bridge
    │
    ├─> SendEvent() to React Native
    │
    ▼
React Native App
    │
    └─> Event listener receives update
```

---

## Security Architecture

### 1. Data Encryption

- **Cached Data**: Encrypted using AES-256-GCM
- **Key Storage**: Stored in iOS Keychain
- **Key Management**: Automatic key generation and rotation

### 2. Secure Communication

- **Certificate Pinning**: SSL certificate pinning for API calls
- **HTTPS Only**: All API communication over HTTPS
- **Token Management**: Secure token storage in Keychain

### 3. Privacy Protection

- **Minimal Storage**: Only aggregated data cached
- **No Raw Samples**: Never cache raw HealthKit samples
- **User Control**: All data access requires explicit authorization
- **GDPR Compliant**: User can revoke access at any time

---

## Extension Points

### Adding a New Data Source

1. **Create Source Class**:
```swift
class MyCustomSource: HealthDataSource {
    var displayName: String { "My Custom Source" }
    
    func isAvailable() -> Bool {
        // Check availability
        return true
    }
    
    func checkAuthorizationStatus() -> AuthorizationStatus {
        // Check authorization
        return .authorized
    }
    
    func requestAuthorization() async throws {
        // Request authorization
    }
    
    func getHealthDataSummary(for date: Date) async throws -> HealthDataSummary {
        // Fetch and return data
    }
}
```

2. **Register Source**:
```swift
let customSource = MyCustomSource()
HealthDataAggregator.shared.registerSource(customSource)
```

3. **Use in React Native**:
```typescript
await ONVYHealthKit.setDataSource('my-custom-source');
```

### Adding a New Health Data Type

1. **Extend HealthKitManager**:
```swift
public func getNewDataType(for date: Date) async throws -> Double {
    // Implement query logic
}
```

2. **Update HealthDataSummary**:
```swift
public struct HealthDataSummary: Codable {
    // ... existing fields
    public let newDataType: Double?
}
```

3. **Update React Native Bridge**:
```swift
@objc func getNewDataType(_ resolve: @escaping RCTPromiseResolveBlock,
                          reject: @escaping RCTPromiseRejectBlock) {
    // Bridge implementation
}
```

---

## Design Decisions

### 1. Singleton Pattern

**Decision**: Use singleton for HealthKitManager and Aggregator

**Rationale**:
- Single HKHealthStore instance (required by HealthKit)
- Easy access throughout SDK
- Thread-safe with proper implementation

**Trade-offs**:
- Harder to test (mitigated with dependency injection in tests)
- Global state (acceptable for SDK-level managers)

### 2. Protocol-Based Sources

**Decision**: Use protocol for data sources

**Rationale**:
- Easy to add new sources
- Consistent interface
- Testable via mocks
- Supports 500+ sources

**Trade-offs**:
- Slight overhead (minimal)
- Requires protocol conformance

### 3. Async/Await

**Decision**: Use async/await for all async operations

**Rationale**:
- Modern Swift concurrency
- Cleaner code
- Better error handling
- Type-safe

**Trade-offs**:
- Requires iOS 13+ (acceptable)
- Learning curve (minimal)

---

## Performance Considerations

### 1. Caching Strategy

- **In-Memory Cache**: Fast access to frequently used data
- **TTL**: 5-minute cache expiration
- **Invalidation**: Automatic on new data

### 2. Query Optimization

- **Statistics Queries**: Use HKStatisticsQuery for aggregated data
- **Batch Queries**: Combine multiple queries where possible
- **Pagination**: For large date ranges

### 3. Bridge Optimization

- **Minimize Calls**: Batch data transfers
- **Event Throttling**: Throttle real-time updates
- **Memory Management**: Proper cleanup of observers

---

For implementation details, see the [Implementation Guide](./IMPLEMENTATION_GUIDE.md).
