# ONVY Health SDK

**Native iOS SDK and React Native Bridge for Apple HealthKit**

A modular iOS SDK written in Swift that exposes Apple HealthKit data to React Native applications through a clean, type-safe bridge.

This project focuses on correctness, extensibility, and privacy, and is intended to demonstrate how a HealthKit-based SDK can be built for real-world HealthTech products.

---

## 🎯 Project Overview

This SDK showcases:

- Native iOS development with Apple HealthKit
- Swift-based SDK design with clear separation of concerns
- A React Native bridge (Swift + Objective-C) with a TypeScript API
- Compatibility with Expo development builds
- Architecture designed to scale to multiple health data sources

The goal of this project is not to be a full product, but a realistic, production-style SDK foundation that could be extended in a HealthTech environment.

---

## 🏗️ Architecture

### High-Level Design

```
┌─────────────────────────────────────┐
│   React Native / Expo App           │
│   (TypeScript API Layer)            │
└──────────────┬──────────────────────┘
               │
               │ React Native Bridge
               │
┌──────────────▼──────────────────────┐
│   Native iOS Bridge                  │
│   (Swift + Objective-C)              │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   iOS SDK (Swift)                    │
│   - HealthKitManager                 │
│   - HealthDataAggregator             │
│   - HealthDataSource Protocol        │
└──────────────────────────────────────┘
```

The SDK is split into three layers to keep responsibilities clear and make future changes easier.

---

## 🧩 Core Components

### 1. iOS SDK (`ios-sdk/ONVYHealthSDK/`)

- **HealthKitManager**
  - Handles HealthKit authorization, queries, and observer-based updates.
- **HealthDataAggregator**
  - Combines data from one or more sources into a unified summary.
- **HealthDataSource**
  - A protocol that allows new data sources to be added without changing the bridge or API.
- Shared utilities for caching, logging, and error handling.

### 2. React Native Bridge (`react-native-bridge/`)

- Swift module exposed via Objective-C
- Promise-based API for async operations
- Event emitters for real-time updates
- TypeScript wrapper providing a clean, typed interface

### 3. Demo App (`demo-app/`)

- Small React Native app demonstrating SDK usage
- Displays daily summaries and live updates
- Uses mock data automatically on simulators

---

## 🚀 Features

### HealthKit Integration

- Reads steps, heart rate, and sleep analysis
- Handles authorization states explicitly
- Supports live updates using HKObserverQuery
- Date-based queries and weekly trends
- Graceful handling of missing or partial data

### React Native Integration

- Type-safe TypeScript API
- Async/await friendly
- Real-time subscriptions via event emitters
- Works with Expo development builds

### Extensibility

- Protocol-based design for adding new data sources
- Aggregation layer independent from HealthKit
- Mock sources included for testing and demos

### Production Considerations

- Structured logging
- Clear error propagation across the bridge
- Minimal, privacy-aware data handling
- CI-ready project structure

---

## 📦 Installation

### Requirements

- iOS 14+
- Xcode 13+
- React Native 0.70+
- Expo SDK 54+ (optional)

### iOS Setup

1. Add the SDK to your Xcode project
2. Enable the HealthKit capability
3. Add the required usage description to `Info.plist`:

```xml
<key>NSHealthShareUsageDescription</key>
<string>This app reads health data to provide health insights.</string>
```

---

## 💻 Usage Example

```typescript
import ONVYHealthKit from '@onvy/healthkit';

await ONVYHealthKit.requestAuthorization();

const summary = await ONVYHealthKit.getHealthDataSummary();
console.log(summary.steps, summary.averageHeartRate);

const unsubscribe = ONVYHealthKit.subscribeToSteps(data => {
  console.log('Steps updated:', data.value);
});
```

---

## 🔌 Multiple Data Sources

The SDK is designed so that HealthKit is just one possible source.

```typescript
await ONVYHealthKit.setDataSource('aggregated');
const data = await ONVYHealthKit.getHealthDataSummary();
```

New sources can be added by implementing `HealthDataSource` in Swift and registering it with the aggregator.

---

## 🔐 Privacy & Security

- User-controlled HealthKit permissions
- No raw HealthKit samples exposed to JavaScript
- Aggregated data only
- Encrypted storage for sensitive values
- Architecture aligned with GDPR-style data minimization

---

## 🧪 Testing

- Unit tests for core SDK components
- Mock data sources for predictable test runs
- Simulator-safe fallback when HealthKit is unavailable

---

## 📁 Project Structure

```
ONVYHealthSDK/
├── ios-sdk/                      # Native iOS SDK (Swift)
│   ├── ONVYHealthSDK/           # Core SDK implementation
│   │   ├── HealthKitManager.swift
│   │   ├── HealthDataAggregator.swift
│   │   ├── HealthDataSource.swift
│   │   └── ...
│   └── ONVYHealthSDKTests/       # Unit tests
│
├── react-native-bridge/          # React Native integration
│   ├── ios/                      # Native bridge (Swift + Objective-C)
│   │   ├── ONVYHealthKitModule.swift
│   │   └── ONVYHealthKitModule.m
│   └── src/                      # TypeScript service layer
│       └── ONVYHealthKit.ts
│
├── demo-app/                     # Example React Native app
│   ├── src/
│   │   ├── components/           # Dashboard components
│   │   └── services/             # Mock service for simulator
│   └── ...
│
├── expo-plugin-onvy-healthkit/   # Expo plugin
├── docs/                         # Documentation
└── .github/workflows/            # CI/CD pipelines
```

---

## 📝 License

MIT — for demonstration and evaluation purposes.
