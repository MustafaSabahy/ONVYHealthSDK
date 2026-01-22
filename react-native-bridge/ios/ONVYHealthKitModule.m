//
//  ONVYHealthKitModule.m
//  ONVYHealthKitModule
//
//  Objective-C bridge for React Native
//

#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(ONVYHealthKitModule, RCTEventEmitter)

// Data Source Selection
RCT_EXTERN_METHOD(setDataSource:(NSString *)source
                  resolve:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getAvailableSources:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Authorization
RCT_EXTERN_METHOD(requestAuthorization:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(checkAuthorizationStatus:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Steps
RCT_EXTERN_METHOD(getSteps:(NSNumber *)date
                  resolve:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getStepsForDays:(NSNumber *)days
                  resolve:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Heart Rate
RCT_EXTERN_METHOD(getLatestHeartRate:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getAverageHeartRate:(NSNumber *)date
                  resolve:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Sleep
RCT_EXTERN_METHOD(getSleepData:(NSNumber *)date
                  resolve:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Summary
RCT_EXTERN_METHOD(getHealthDataSummary:(NSNumber *)date
                  resolve:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Weekly Trends
RCT_EXTERN_METHOD(getWeeklyTrends:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Observers
RCT_EXTERN_METHOD(startObservingSteps)

RCT_EXTERN_METHOD(startObservingHeartRate)

// Simulated Live Updates
RCT_EXTERN_METHOD(startSimulatedLiveUpdates)

// Backend
RCT_EXTERN_METHOD(sendHealthDataToBackend:(NSNumber *)date
                  resolve:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Cache
RCT_EXTERN_METHOD(clearCache:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

@end
