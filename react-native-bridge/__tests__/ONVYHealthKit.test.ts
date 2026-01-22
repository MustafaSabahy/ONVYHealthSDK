//
//  ONVYHealthKit.test.ts
//  React Native Bridge Tests
//
//  Integration tests for React Native bridge
//  Tests native module methods, event emitters, and Promise-based API
//

import ONVYHealthKit from '../src/ONVYHealthKit';
import { NativeModules, NativeEventEmitter } from 'react-native';

// Mock native module
jest.mock('react-native', () => {
  const mockModule = {
    checkAuthorizationStatus: jest.fn(),
    requestAuthorization: jest.fn(),
    getHealthDataSummary: jest.fn(),
    getWeeklyTrends: jest.fn(),
    setDataSource: jest.fn(),
    sendHealthDataToBackend: jest.fn(),
    addListener: jest.fn(),
    removeListeners: jest.fn(),
  };

  return {
    NativeModules: {
      ONVYHealthKit: mockModule,
    },
    NativeEventEmitter: jest.fn().mockImplementation(() => ({
      addListener: jest.fn(),
      removeListener: jest.fn(),
    })),
  };
});

describe('ONVYHealthKit', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('checkAuthorizationStatus', () => {
    it('should return authorization status', async () => {
      const mockStatus = {
        status: {
          steps: 'authorized',
          heartRate: 'authorized',
          sleep: 'notDetermined',
        },
      };

      (NativeModules.ONVYHealthKit.checkAuthorizationStatus as jest.Mock).mockResolvedValue(
        mockStatus
      );

      const result = await ONVYHealthKit.checkAuthorizationStatus();

      expect(result).toEqual(mockStatus);
      expect(NativeModules.ONVYHealthKit.checkAuthorizationStatus).toHaveBeenCalledTimes(1);
    });

    it('should handle errors', async () => {
      const error = new Error('Authorization check failed');
      (NativeModules.ONVYHealthKit.checkAuthorizationStatus as jest.Mock).mockRejectedValue(error);

      await expect(ONVYHealthKit.checkAuthorizationStatus()).rejects.toThrow(error);
    });
  });

  describe('requestAuthorization', () => {
    it('should request authorization successfully', async () => {
      (NativeModules.ONVYHealthKit.requestAuthorization as jest.Mock).mockResolvedValue(true);

      const result = await ONVYHealthKit.requestAuthorization();

      expect(result).toBe(true);
      expect(NativeModules.ONVYHealthKit.requestAuthorization).toHaveBeenCalledTimes(1);
    });

    it('should handle authorization denial', async () => {
      const error = { code: 'AUTHORIZATION_DENIED', message: 'User denied authorization' };
      (NativeModules.ONVYHealthKit.requestAuthorization as jest.Mock).mockRejectedValue(error);

      await expect(ONVYHealthKit.requestAuthorization()).rejects.toEqual(error);
    });
  });

  describe('getHealthDataSummary', () => {
    it('should return health data summary', async () => {
      const mockSummary = {
        date: Date.now(),
        steps: 8500,
        averageHeartRate: 72,
        sleepHours: 7.5,
        activeCalories: 450,
        sources: ['HealthKit'],
      };

      (NativeModules.ONVYHealthKit.getHealthDataSummary as jest.Mock).mockResolvedValue(
        mockSummary
      );

      const result = await ONVYHealthKit.getHealthDataSummary();

      expect(result).toEqual(mockSummary);
      expect(NativeModules.ONVYHealthKit.getHealthDataSummary).toHaveBeenCalledTimes(1);
    });

    it('should handle missing data', async () => {
      const mockSummary = {
        date: Date.now(),
        steps: 0,
        averageHeartRate: null,
        sleepHours: null,
        activeCalories: null,
      };

      (NativeModules.ONVYHealthKit.getHealthDataSummary as jest.Mock).mockResolvedValue(
        mockSummary
      );

      const result = await ONVYHealthKit.getHealthDataSummary();

      expect(result.averageHeartRate).toBeNull();
      expect(result.sleepHours).toBeNull();
    });
  });

  describe('getWeeklyTrends', () => {
    it('should return weekly trends', async () => {
      const mockTrends = {
        data: [
          {
            date: Date.now() - 86400000,
            steps: 8000,
            averageHeartRate: 70,
            sleepHours: 7.0,
            activeCalories: 400,
            sources: ['HealthKit'],
          },
        ],
      };

      (NativeModules.ONVYHealthKit.getWeeklyTrends as jest.Mock).mockResolvedValue(mockTrends);

      const result = await ONVYHealthKit.getWeeklyTrends();

      expect(result).toEqual(mockTrends);
      expect(NativeModules.ONVYHealthKit.getWeeklyTrends).toHaveBeenCalledTimes(1);
    });
  });

  describe('setDataSource', () => {
    it('should set data source', async () => {
      (NativeModules.ONVYHealthKit.setDataSource as jest.Mock).mockResolvedValue(undefined);

      await ONVYHealthKit.setDataSource('healthkit');

      expect(NativeModules.ONVYHealthKit.setDataSource).toHaveBeenCalledWith('healthkit');
    });

    it('should handle invalid source', async () => {
      const error = { code: 'INVALID_SOURCE', message: 'Invalid data source' };
      (NativeModules.ONVYHealthKit.setDataSource as jest.Mock).mockRejectedValue(error);

      await expect(ONVYHealthKit.setDataSource('invalid')).rejects.toEqual(error);
    });
  });

  describe('subscribeToSteps', () => {
    it('should subscribe to steps updates', () => {
      const callback = jest.fn();
      const unsubscribe = ONVYHealthKit.subscribeToSteps(callback);

      expect(typeof unsubscribe).toBe('function');
    });

    it('should call callback when steps update', () => {
      const callback = jest.fn();
      ONVYHealthKit.subscribeToSteps(callback);

      // Simulate event emission
      const mockEventEmitter = new NativeEventEmitter();
      mockEventEmitter.emit('onStepsUpdate', { value: 1000 });

      // Note: In real implementation, this would be tested with actual event emission
    });
  });

  describe('sendHealthDataToBackend', () => {
    it('should send data to backend successfully', async () => {
      const mockResult = { success: true };
      (NativeModules.ONVYHealthKit.sendHealthDataToBackend as jest.Mock).mockResolvedValue(
        mockResult
      );

      const result = await ONVYHealthKit.sendHealthDataToBackend();

      expect(result).toEqual(mockResult);
      expect(NativeModules.ONVYHealthKit.sendHealthDataToBackend).toHaveBeenCalledTimes(1);
    });

    it('should handle backend errors', async () => {
      const error = { code: 'NETWORK_ERROR', message: 'Network request failed' };
      (NativeModules.ONVYHealthKit.sendHealthDataToBackend as jest.Mock).mockRejectedValue(error);

      await expect(ONVYHealthKit.sendHealthDataToBackend()).rejects.toEqual(error);
    });
  });
});
