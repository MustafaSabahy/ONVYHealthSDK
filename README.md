# ONVY Health SDK

iOS SDK and React Native bridge for integrating Apple HealthKit into React Native applications.

## What is this?

A production-ready SDK that lets you read health data (steps, heart rate, sleep) from Apple HealthKit in your React Native apps. Works with Expo.

## Features

- ✅ Read steps, heart rate, and sleep data from HealthKit
- ✅ Multiple data sources support (HealthKit, mock wearables, nutrition)
- ✅ Real-time updates with live data streaming
- ✅ Weekly trends and historical data
- ✅ React Native bridge with TypeScript support
- ✅ Works with Expo (development builds)
- ✅ Privacy-first: minimal data storage, GDPR compliant

## Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/your-org/ONVYHealthSDK.git
cd ONVYHealthSDK
```

### iOS SDK Setup

1. Add the SDK to your Xcode project
2. Add HealthKit capability in Xcode
3. Add to `Info.plist`:
```xml
<key>NSHealthShareUsageDescription</key>
<string>We need access to your health data to provide personalized insights.</string>
```

### React Native Integration

```typescript
import ONVYHealthKit from '@onvy/healthkit';

// Request authorization
await ONVYHealthKit.requestAuthorization();

// Get today's health data
const summary = await ONVYHealthKit.getHealthDataSummary();
console.log('Steps:', summary.steps);
console.log('Heart Rate:', summary.averageHeartRate);
console.log('Sleep:', summary.sleepHours);

// Subscribe to real-time updates
const unsubscribe = ONVYHealthKit.subscribeToSteps((data) => {
  console.log('New steps:', data.value);
});
```

## Project Structure

```
ONVYHealthSDK/
├── ios-sdk/              # Native iOS SDK (Swift)
│   └── ONVYHealthSDK/
├── react-native-bridge/   # React Native bridge
│   ├── ios/              # iOS bridge (Swift + Objective-C)
│   └── src/              # TypeScript service layer
├── demo-app/             # Example React Native app
└── docs/                  # Documentation
```

## Requirements

- iOS 14.0+
- Xcode 13.0+
- React Native 0.70+
- Expo SDK 54+ (if using Expo)

## API Reference

### Authorization

```typescript
// Check current status
const status = await ONVYHealthKit.checkAuthorizationStatus();

// Request authorization
await ONVYHealthKit.requestAuthorization();
```

### Reading Data

```typescript
// Get today's summary
const summary = await ONVYHealthKit.getHealthDataSummary();

// Get steps for specific date
const steps = await ONVYHealthKit.getSteps(new Date('2024-01-15'));

// Get weekly trends
const trends = await ONVYHealthKit.getWeeklyTrends();
```

### Real-time Updates

```typescript
// Subscribe to steps updates
const unsubscribe = ONVYHealthKit.subscribeToSteps((data) => {
  console.log('Steps updated:', data.value);
});

// Don't forget to unsubscribe
unsubscribe();
```

## Demo App

Run the demo app to see the SDK in action:

```bash
cd demo-app
npm install
npx expo start
```

Then press `i` to open iOS Simulator (uses mock data) or run on a physical device for real HealthKit data.

## Architecture

The SDK consists of three main layers:

1. **iOS SDK** (Swift): Core HealthKit integration
2. **React Native Bridge**: Connects Swift code to JavaScript
3. **TypeScript Service**: Type-safe API for React Native apps

Data flows: HealthKit → Swift SDK → Bridge → TypeScript → Your App

## Multiple Data Sources

The SDK supports multiple health data sources:

- **HealthKit**: Native iOS health data
- **Mock Wearable**: Simulated wearable device (for testing)
- **Mock Nutrition**: Simulated nutrition data (for testing)
- **Aggregated**: Combined data from all sources

Switch between sources:

```typescript
await ONVYHealthKit.setDataSource('healthkit');
// or
await ONVYHealthKit.setDataSource('aggregated');
```

## Privacy & Security

- All cached data is encrypted
- Only aggregated data is stored (never raw samples)
- User controls all data access
- GDPR and HIPAA compliant
- Secure API communication with certificate pinning

## Error Handling

```typescript
try {
  const data = await ONVYHealthKit.getHealthDataSummary();
} catch (error) {
  if (error.code === 'AUTHORIZATION_DENIED') {
    // User denied access
  } else if (error.code === 'NOT_AVAILABLE') {
    // HealthKit not available (simulator)
  }
}
```

## Common Issues

### HealthKit not working on Simulator

HealthKit requires a physical device. The SDK automatically uses mock data on simulators.

### Authorization denied

Guide users to Settings > Privacy & Security > Health to enable access.

## Contributing

Contributions are welcome! Please read our contributing guidelines first.

## License

[Your License Here]

## Support

For issues and questions:
- Open an issue on GitHub
- Check the [documentation](./docs/)
- See [troubleshooting guide](./docs/TROUBLESHOOTING.md)

---

Made with ❤️ for health and wellness apps
