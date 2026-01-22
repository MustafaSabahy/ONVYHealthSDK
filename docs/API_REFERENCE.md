# ONVY Health SDK - API Reference

Complete API reference for the ONVY Health SDK, including iOS SDK and React Native bridge.

## Table of Contents

1. [iOS SDK](#ios-sdk)
2. [React Native Bridge](#react-native-bridge)
3. [TypeScript Service](#typescript-service)
4. [Error Handling](#error-handling)
5. [Data Models](#data-models)

---

## iOS SDK

### HealthKitManager

Main manager for HealthKit operations.

#### Methods

##### `requestAuthorization() async throws`

Requests authorization for health data types.

```swift
do {
    try await HealthKitManager.shared.requestAuthorization()
    print("Authorization granted")
} catch {
    print("Authorization failed: \(error)")
}
```

**Throws:**
- `HealthKitError.notAvailable` - HealthKit not available on device
- `HealthKitError.authorizationDenied` - User denied authorization

---

##### `checkAuthorizationStatus(for: HKObjectType) -> HKAuthorizationStatus`

Checks authorization status for a specific health data type.

```swift
let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
let status = HealthKitManager.shared.checkAuthorizationStatus(for: stepType)

switch status {
case .sharingAuthorized:
    print("Authorized")
case .sharingDenied:
    print("Denied")
case .notDetermined:
    print("Not determined")
@unknown default:
    break
}
```

**Returns:** `HKAuthorizationStatus` - Current authorization status

---

##### `getSteps(for: Date) async throws -> Double`

Gets total steps for a specific date.

```swift
let today = Date()
do {
    let steps = try await HealthKitManager.shared.getSteps(for: today)
    print("Steps today: \(steps)")
} catch {
    print("Failed to get steps: \(error)")
}
```

**Parameters:**
- `date: Date` - Date to query steps for

**Returns:** `Double` - Total steps for the date

**Throws:**
- `HealthKitError.authorizationDenied` - Not authorized
- `HealthKitError.noDataAvailable` - No data available
- `HealthKitError.queryFailed` - Query execution failed

---

##### `getAverageHeartRate(for: Date) async throws -> Double?`

Gets average heart rate for a specific date.

```swift
let today = Date()
do {
    if let heartRate = try await HealthKitManager.shared.getAverageHeartRate(for: today) {
        print("Average heart rate: \(heartRate) bpm")
    }
} catch {
    print("Failed to get heart rate: \(error)")
}
```

**Parameters:**
- `date: Date` - Date to query heart rate for

**Returns:** `Double?` - Average heart rate in bpm, or `nil` if no data

**Throws:**
- `HealthKitError.authorizationDenied` - Not authorized
- `HealthKitError.queryFailed` - Query execution failed

---

##### `getSleepHours(for: Date) async throws -> Double?`

Gets total sleep hours for a specific date.

```swift
let today = Date()
do {
    if let sleepHours = try await HealthKitManager.shared.getSleepHours(for: today) {
        print("Sleep hours: \(sleepHours)")
    }
} catch {
    print("Failed to get sleep: \(error)")
}
```

**Parameters:**
- `date: Date` - Date to query sleep for

**Returns:** `Double?` - Total sleep hours, or `nil` if no data

**Throws:**
- `HealthKitError.authorizationDenied` - Not authorized
- `HealthKitError.queryFailed` - Query execution failed

---

### HealthDataAggregator

Aggregates health data from multiple sources.

#### Methods

##### `registerSource(_ source: HealthDataSource)`

Registers a new health data source.

```swift
let customSource = MyCustomHealthSource()
HealthDataAggregator.shared.registerSource(customSource)
```

**Parameters:**
- `source: HealthDataSource` - Source to register

---

##### `getAvailableSources() -> [HealthDataSource]`

Gets all available health data sources.

```swift
let sources = HealthDataAggregator.shared.getAvailableSources()
for source in sources {
    print("Source: \(source.displayName)")
}
```

**Returns:** Array of available sources

---

##### `aggregateHealthData(for: Date) async throws -> AggregatedHealthData`

Aggregates health data from all active sources.

```swift
let today = Date()
do {
    let aggregated = try await HealthDataAggregator.shared.aggregateHealthData(for: today)
    print("Aggregated steps: \(aggregated.steps)")
    print("Sources: \(aggregated.sources)")
} catch {
    print("Failed to aggregate: \(error)")
}
```

**Parameters:**
- `date: Date` - Date to aggregate data for

**Returns:** `AggregatedHealthData` - Aggregated health data

**Throws:**
- `HealthKitError.authorizationNotDetermined` - No authorized sources
- `HealthKitError.noDataAvailable` - No data available from any source

---

## React Native Bridge

### ONVYHealthKit Module

React Native bridge for accessing HealthKit functionality.

#### Methods

##### `checkAuthorizationStatus(): Promise<AuthorizationStatus>`

Checks current authorization status.

```typescript
import ONVYHealthKit from '@onvy/healthkit';

const status = await ONVYHealthKit.checkAuthorizationStatus();
console.log('Steps:', status.status.steps);
console.log('Heart Rate:', status.status.heartRate);
```

**Returns:** Promise resolving to authorization status object

---

##### `requestAuthorization(): Promise<boolean>`

Requests HealthKit authorization.

```typescript
try {
    const granted = await ONVYHealthKit.requestAuthorization();
    if (granted) {
        console.log('Authorization granted');
    }
} catch (error) {
    console.error('Authorization failed:', error);
}
```

**Returns:** Promise resolving to `true` if authorized

**Throws:** Error if authorization fails

---

##### `getHealthDataSummary(): Promise<HealthDataSummary>`

Gets health data summary for today.

```typescript
try {
    const summary = await ONVYHealthKit.getHealthDataSummary();
    console.log('Steps:', summary.steps);
    console.log('Heart Rate:', summary.averageHeartRate);
    console.log('Sleep:', summary.sleepHours);
} catch (error) {
    console.error('Failed to get data:', error);
}
```

**Returns:** Promise resolving to health data summary

**Throws:** Error if data retrieval fails

---

##### `getWeeklyTrends(): Promise<WeeklyTrends>`

Gets weekly health trends.

```typescript
try {
    const trends = await ONVYHealthKit.getWeeklyTrends();
    console.log('Trends:', trends.data);
} catch (error) {
    console.error('Failed to get trends:', error);
}
```

**Returns:** Promise resolving to weekly trends

---

##### `setDataSource(source: string): Promise<void>`

Sets the active data source.

```typescript
await ONVYHealthKit.setDataSource('healthkit');
// or
await ONVYHealthKit.setDataSource('aggregated');
```

**Parameters:**
- `source: string` - Source identifier ('healthkit', 'wearable', 'nutrition', 'aggregated')

---

##### `subscribeToSteps(callback: (data: StepsData) => void): () => void`

Subscribes to real-time steps updates.

```typescript
const unsubscribe = ONVYHealthKit.subscribeToSteps((data) => {
    console.log('New steps:', data.value);
});

// Later, unsubscribe
unsubscribe();
```

**Parameters:**
- `callback: Function` - Callback function receiving steps data

**Returns:** Unsubscribe function

---

##### `subscribeToHeartRate(callback: (data: HeartRateData) => void): () => void`

Subscribes to real-time heart rate updates.

```typescript
const unsubscribe = ONVYHealthKit.subscribeToHeartRate((data) => {
    console.log('New heart rate:', data.heartRate);
});

unsubscribe();
```

---

##### `sendHealthDataToBackend(): Promise<{ success: boolean }>`

Sends health data to backend/BI.

```typescript
try {
    const result = await ONVYHealthKit.sendHealthDataToBackend();
    if (result.success) {
        console.log('Data sent successfully');
    }
} catch (error) {
    console.error('Failed to send data:', error);
}
```

**Returns:** Promise resolving to success status

---

## Error Handling

### HealthKitError

Swift error enum for HealthKit operations.

```swift
public enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case authorizationDenied
    case authorizationNotDetermined
    case invalidType
    case queryFailed(String)
    case noDataAvailable
    case invalidDateRange
    case backgroundDeliveryNotEnabled
}
```

### Error Codes

All errors have a `code` property for React Native compatibility:

- `NOT_AVAILABLE` - HealthKit not available
- `AUTHORIZATION_DENIED` - Authorization denied
- `AUTHORIZATION_NOT_DETERMINED` - Authorization not requested
- `INVALID_TYPE` - Invalid health data type
- `QUERY_FAILED` - Query execution failed
- `NO_DATA_AVAILABLE` - No data available
- `INVALID_DATE_RANGE` - Invalid date range
- `BACKGROUND_DELIVERY_NOT_ENABLED` - Background delivery disabled

---

## Data Models

### HealthDataSummary

```swift
public struct HealthDataSummary: Codable {
    public let date: Date
    public let steps: Double
    public let averageHeartRate: Double?
    public let sleepHours: Double?
    public let activeCalories: Double?
    public let source: String
}
```

### AggregatedHealthData

```swift
public struct AggregatedHealthData: Codable {
    public let date: Date
    public let steps: Double
    public let averageHeartRate: Double?
    public let sleepHours: Double?
    public let activeCalories: Double?
    public let sources: [String]
}
```

---

## TypeScript Types

### HealthDataSummary

```typescript
interface HealthDataSummary {
    date: number;
    steps: number;
    averageHeartRate: number | null;
    sleepHours: number | null;
    activeCalories: number | null;
    sources?: string[];
}
```

### WeeklyTrend

```typescript
interface WeeklyTrend {
    date: number;
    steps: number;
    averageHeartRate: number | null;
    sleepHours: number | null;
    activeCalories: number | null;
    sources: string[];
}
```

---

For more examples and usage patterns, see the [Usage Guide](./USAGE_GUIDE.md).
