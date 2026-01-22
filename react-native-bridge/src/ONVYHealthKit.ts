//
//  ONVYHealthKit.ts
//  React Native TypeScript interface for ONVY Health SDK
//

import { NativeModules, NativeEventEmitter, Platform } from 'react-native';

const { ONVYHealthKitModule } = NativeModules;

// Event emitter for real-time updates
const healthKitEmitter = new NativeEventEmitter(ONVYHealthKitModule);

// MARK: - Types

export interface AuthorizationStatus {
  status: {
    [key: string]: 'notDetermined' | 'denied' | 'authorized';
  };
}

export interface StepsData {
  steps: number;
  date: number;
  source?: string;
}

export interface DailySteps {
  date: number;
  steps: number;
  source?: string | null;
  sources?: string[]; // For aggregated data
}

export interface HeartRateData {
  heartRate: number | null;
  timestamp: number | null;
  source?: string | null;
}

export interface SleepData {
  date: number;
  totalSleepHours: number;
  inBedHours: number;
  asleepHours: number;
  awakeHours: number;
  samples: SleepSample[];
}

export interface SleepSample {
  startDate: number;
  endDate: number;
  value: number;
  source?: string | null;
}

export interface HealthDataSummary {
  date: number;
  steps: number;
  averageHeartRate: number | null;
  sleepHours: number | null;
  activeCalories: number | null;
  sources?: string[]; // List of data sources
}

export interface HealthDataUpdate {
  type: 'steps' | 'heartRate';
  value: number;
  timestamp: number;
  source?: string;
}

export interface LiveUpdate {
  steps: number;
  heartRate: number;
  timestamp: number;
  sources: string[];
}

export interface WeeklyTrend {
  date: number;
  steps: number;
  averageHeartRate: number | null;
  sleepHours: number | null;
  activeCalories: number | null;
  sources: string[];
}

export interface DataSource {
  id: string;
  name: string;
  authorized: boolean;
}

// MARK: - ONVY HealthKit Service

class ONVYHealthKit {
  /**
   * Set current data source
   * Options: "healthkit", "wearable", "nutrition", "aggregated"
   */
  async setDataSource(source: string): Promise<{ success: boolean; source: string }> {
    if (Platform.OS !== 'ios') {
      throw new Error('HealthKit is only available on iOS');
    }

    try {
      const result = await ONVYHealthKitModule.setDataSource(source);
      return result;
    } catch (error: any) {
      throw new Error(`Failed to set data source: ${error.message}`);
    }
  }

  /**
   * Get available data sources
   */
  async getAvailableSources(): Promise<DataSource[]> {
    if (Platform.OS !== 'ios') {
      throw new Error('HealthKit is only available on iOS');
    }

    try {
      const result = await ONVYHealthKitModule.getAvailableSources();
      return result.sources;
    } catch (error: any) {
      throw new Error(`Failed to get sources: ${error.message}`);
    }
  }

  /**
   * Request HealthKit authorization for all sources
   */
  async requestAuthorization(): Promise<AuthorizationStatus> {
    if (Platform.OS !== 'ios') {
      throw new Error('HealthKit is only available on iOS');
    }

    if (!ONVYHealthKitModule) {
      throw new Error('ONVYHealthKitModule is not available');
    }

    try {
      const result = await ONVYHealthKitModule.requestAuthorization();
      return result;
    } catch (error: any) {
      throw new Error(`Authorization failed: ${error.message}`);
    }
  }

  /**
   * Check current authorization status
   */
  async checkAuthorizationStatus(): Promise<AuthorizationStatus> {
    if (Platform.OS !== 'ios') {
      throw new Error('HealthKit is only available on iOS');
    }

    try {
      const result = await ONVYHealthKitModule.checkAuthorizationStatus();
      return result;
    } catch (error: any) {
      throw new Error(`Failed to check authorization: ${error.message}`);
    }
  }

  /**
   * Get steps for a specific date
   * @param date Optional date (defaults to today)
   */
  async getSteps(date?: Date): Promise<StepsData> {
    try {
      const timestamp = date ? date.getTime() : undefined;
      const result = await ONVYHealthKitModule.getSteps(timestamp);
      return result;
    } catch (error: any) {
      throw new Error(`Failed to get steps: ${error.message}`);
    }
  }

  /**
   * Get steps for multiple days
   * @param days Number of days to retrieve
   */
  async getStepsForDays(days: number): Promise<DailySteps[]> {
    try {
      const result = await ONVYHealthKitModule.getStepsForDays(days);
      return result.data;
    } catch (error: any) {
      throw new Error(`Failed to get steps for days: ${error.message}`);
    }
  }

  /**
   * Get latest heart rate reading
   */
  async getLatestHeartRate(): Promise<HeartRateData> {
    try {
      const result = await ONVYHealthKitModule.getLatestHeartRate();
      return result;
    } catch (error: any) {
      throw new Error(`Failed to get heart rate: ${error.message}`);
    }
  }

  /**
   * Get average heart rate for a date
   * @param date Optional date (defaults to today)
   */
  async getAverageHeartRate(date?: Date): Promise<{ averageHeartRate: number | null; date: number }> {
    try {
      const timestamp = date ? date.getTime() : undefined;
      const result = await ONVYHealthKitModule.getAverageHeartRate(timestamp);
      return result;
    } catch (error: any) {
      throw new Error(`Failed to get average heart rate: ${error.message}`);
    }
  }

  /**
   * Get sleep data for a date
   * @param date Optional date (defaults to today)
   */
  async getSleepData(date?: Date): Promise<SleepData> {
    try {
      const timestamp = date ? date.getTime() : undefined;
      const result = await ONVYHealthKitModule.getSleepData(timestamp);
      return result;
    } catch (error: any) {
      throw new Error(`Failed to get sleep data: ${error.message}`);
    }
  }

  /**
   * Get complete health data summary for dashboard
   * @param date Optional date (defaults to today)
   */
  async getHealthDataSummary(date?: Date): Promise<HealthDataSummary> {
    try {
      const timestamp = date ? date.getTime() : undefined;
      const result = await ONVYHealthKitModule.getHealthDataSummary(timestamp);
      return result;
    } catch (error: any) {
      throw new Error(`Failed to get health data summary: ${error.message}`);
    }
  }

  /**
   * Get weekly trends
   */
  async getWeeklyTrends(): Promise<WeeklyTrend[]> {
    try {
      const result = await ONVYHealthKitModule.getWeeklyTrends();
      return result.data;
    } catch (error: any) {
      throw new Error(`Failed to get weekly trends: ${error.message}`);
    }
  }

  /**
   * Start observing steps changes
   * Returns unsubscribe function
   */
  subscribeToSteps(callback: (data: HealthDataUpdate) => void): () => void {
    const subscription = healthKitEmitter.addListener('healthDataUpdated', (data: HealthDataUpdate) => {
      if (data.type === 'steps') {
        callback(data);
      }
    });

    ONVYHealthKitModule.startObservingSteps();

    return () => {
      subscription.remove();
    };
  }

  /**
   * Start observing heart rate changes
   * Returns unsubscribe function
   */
  subscribeToHeartRate(callback: (data: HeartRateData) => void): () => void {
    const subscription = healthKitEmitter.addListener('heartRateUpdated', (data: HeartRateData) => {
      callback(data);
    });

    ONVYHealthKitModule.startObservingHeartRate();

    return () => {
      subscription.remove();
    };
  }

  /**
   * Subscribe to authorization status changes
   */
  subscribeToAuthorizationStatus(callback: (status: AuthorizationStatus) => void): () => void {
    const subscription = healthKitEmitter.addListener('authorizationStatusChanged', (status: AuthorizationStatus) => {
      callback(status);
    });

    return () => {
      subscription.remove();
    };
  }

  /**
   * Subscribe to source changes
   */
  subscribeToSourceChange(callback: (source: string) => void): () => void {
    const subscription = healthKitEmitter.addListener('sourceChanged', (data: { source: string }) => {
      callback(data.source);
    });

    return () => {
      subscription.remove();
    };
  }

  /**
   * Subscribe to simulated live updates for demo
   */
  subscribeToLiveUpdates(callback: (data: LiveUpdate) => void): () => void {
    const subscription = healthKitEmitter.addListener('liveUpdate', (data: LiveUpdate) => {
      callback(data);
    });

    // Start simulated updates
    ONVYHealthKitModule.startSimulatedLiveUpdates();

    return () => {
      subscription.remove();
    };
  }

  /**
   * Send health data to backend/BI
   * @param date Optional date (defaults to today)
   */
  async sendHealthDataToBackend(date?: Date): Promise<{ success: boolean }> {
    try {
      const timestamp = date ? date.getTime() : undefined;
      const result = await ONVYHealthKitModule.sendHealthDataToBackend(timestamp);
      return result;
    } catch (error: any) {
      throw new Error(`Failed to send health data: ${error.message}`);
    }
  }

  /**
   * Clear SDK cache
   */
  async clearCache(): Promise<{ success: boolean }> {
    try {
      const result = await ONVYHealthKitModule.clearCache();
      return result;
    } catch (error: any) {
      throw new Error(`Failed to clear cache: ${error.message}`);
    }
  }
}

// Export singleton instance
export default new ONVYHealthKit();
