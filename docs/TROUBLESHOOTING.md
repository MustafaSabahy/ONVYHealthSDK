# ONVY Health SDK - Troubleshooting Guide

Common issues and solutions for the ONVY Health SDK.

## Table of Contents

1. [Authorization Issues](#authorization-issues)
2. [Data Not Available](#data-not-available)
3. [Performance Issues](#performance-issues)
4. [React Native Bridge Issues](#react-native-bridge-issues)
5. [Build Issues](#build-issues)

---

## Authorization Issues

### Issue: Authorization Always Returns "notDetermined"

**Symptoms:**
- `checkAuthorizationStatus()` always returns `notDetermined`
- User never sees authorization dialog

**Solutions:**

1. **Check Info.plist**:
   ```xml
   <key>NSHealthShareUsageDescription</key>
   <string>We need access to your health data to provide personalized health insights.</string>
   <key>NSHealthUpdateUsageDescription</key>
   <string>We need permission to update your health data.</string>
   ```

2. **Verify HealthKit Availability**:
   ```swift
   guard HKHealthStore.isHealthDataAvailable() else {
       // HealthKit not available on this device
       return
   }
   ```

3. **Check Request Timing**:
   - Request authorization on main thread
   - Don't request immediately on app launch
   - Wait for user interaction

---

### Issue: Authorization Denied

**Symptoms:**
- User denied authorization
- `checkAuthorizationStatus()` returns `denied`

**Solutions:**

1. **Guide User to Settings**:
   ```swift
   if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
       UIApplication.shared.open(settingsURL)
   }
   ```

2. **Provide Clear Instructions**:
   - Explain why authorization is needed
   - Show benefits of granting access
   - Provide step-by-step instructions

3. **Respect User Choice**:
   - Don't repeatedly request authorization
   - Provide alternative features without health data

---

## Data Not Available

### Issue: No Steps Data

**Symptoms:**
- `getSteps()` returns 0 or throws error
- Steps data not appearing in app

**Solutions:**

1. **Check Data Source**:
   - Verify iPhone is tracking steps
   - Check Health app for step data
   - Ensure Apple Watch is synced (if applicable)

2. **Verify Date Range**:
   ```swift
   // Use today's date
   let today = Date()
   let steps = try await manager.getSteps(for: today)
   ```

3. **Check Authorization**:
   ```swift
   let status = manager.checkAuthorizationStatus(for: stepType)
   guard status == .sharingAuthorized else {
       // Request authorization
   }
   ```

---

### Issue: Heart Rate Data Missing

**Symptoms:**
- `getAverageHeartRate()` returns `nil`
- No heart rate data available

**Solutions:**

1. **Check Device**:
   - Heart rate requires Apple Watch or compatible device
   - Verify device is paired and synced

2. **Check Date**:
   - Heart rate data may not be available for all dates
   - Try recent dates first

3. **Verify Data in Health App**:
   - Open Health app
   - Check if heart rate data exists
   - Verify data source

---

## Performance Issues

### Issue: Slow Data Queries

**Symptoms:**
- Queries take > 1 second
- App feels sluggish

**Solutions:**

1. **Use Batch Queries**:
   ```swift
   let batch = try await manager.batchQuery(
       for: date,
       types: [.steps, .heartRate, .sleep]
   )
   ```

2. **Enable Caching**:
   - Cache is enabled by default
   - Check cache TTL (default: 5 minutes)
   - Use `smartInvalidateCache()` for stale data

3. **Optimize Date Ranges**:
   - Query specific dates, not large ranges
   - Use pagination for historical data

---

### Issue: High Memory Usage

**Symptoms:**
- App memory usage increases over time
- App crashes due to memory pressure

**Solutions:**

1. **Clear Cache Periodically**:
   ```swift
   manager.invalidateAllCache()
   ```

2. **Use Pagination**:
   ```swift
   let pages = try await manager.paginatedQuery(
       from: startDate,
       to: endDate,
       pageSize: 7,
       type: .steps
   )
   ```

3. **Release Observers**:
   ```swift
   // Always unsubscribe from observers
   let unsubscribe = manager.subscribeToSteps { _ in }
   // Later...
   unsubscribe()
   ```

---

## React Native Bridge Issues

### Issue: Native Module Not Found

**Symptoms:**
- `NativeModules.ONVYHealthKit is undefined`
- Methods not available

**Solutions:**

1. **Check Linking**:
   ```bash
   cd ios
   pod install
   ```

2. **Verify Native Module**:
   - Check `ONVYHealthKitModule.m` exists
   - Verify `RCT_EXPORT_MODULE()` is present

3. **Rebuild App**:
   ```bash
   npx react-native run-ios
   ```

---

### Issue: Events Not Firing

**Symptoms:**
- Subscribed to events but not receiving updates
- Real-time updates not working

**Solutions:**

1. **Check Event Names**:
   ```typescript
   // Verify event names match
   ONVYHealthKit.subscribeToSteps((data) => {
       console.log('Steps update:', data);
   });
   ```

2. **Verify Native Implementation**:
   - Check `sendEvent()` calls in Swift
   - Verify event names match

3. **Check Authorization**:
   - Events require authorization
   - Verify observer queries are set up

---

## Build Issues

### Issue: Swift Compilation Errors

**Symptoms:**
- Xcode build fails
- Swift syntax errors

**Solutions:**

1. **Check Swift Version**:
   - Requires Swift 5.5+
   - Requires iOS 14.0+

2. **Verify Imports**:
   ```swift
   import Foundation
   import HealthKit
   ```

3. **Check Xcode Version**:
   - Requires Xcode 13.0+
   - Update to latest Xcode

---

### Issue: React Native Build Fails

**Symptoms:**
- `pod install` fails
- Native dependencies missing

**Solutions:**

1. **Clean Build**:
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   ```

2. **Check Node Version**:
   - Requires Node.js 16+
   - Use `nvm` to manage versions

3. **Clear Cache**:
   ```bash
   npx react-native start --reset-cache
   ```

---

## Common Error Codes

### `NOT_AVAILABLE`
- **Cause**: HealthKit not available on device
- **Solution**: Check device compatibility (iPhone/iPad with iOS 8+)

### `AUTHORIZATION_DENIED`
- **Cause**: User denied authorization
- **Solution**: Guide user to Settings app

### `NO_DATA_AVAILABLE`
- **Cause**: No health data for requested date
- **Solution**: Check Health app for data, try different date

### `QUERY_FAILED`
- **Cause**: HealthKit query execution failed
- **Solution**: Check error message, verify data types

---

## Getting Help

If you're still experiencing issues:

1. **Check Logs**:
   - Enable debug logging
   - Check Xcode console
   - Review React Native logs

2. **File an Issue**:
   - Include error messages
   - Provide code snippets
   - Include device/OS information

3. **Review Documentation**:
   - API Reference
   - Architecture docs
   - Code examples

---

For more help, see the [API Reference](./API_REFERENCE.md) or [Architecture Documentation](./ARCHITECTURE.md).
