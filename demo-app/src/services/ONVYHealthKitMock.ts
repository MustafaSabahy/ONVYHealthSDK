//
//  ONVYHealthKitMock.ts
//  Mock implementation for iOS Simulator
//  HealthKit doesn't work on Simulator, so we use mock data
//

import { Platform } from 'react-native';

// Mock data types
export interface HealthDataSummary {
  date: number;
  steps: number;
  averageHeartRate: number | null;
  sleepHours: number | null;
  activeCalories: number | null;
  sources?: string[];
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

// Mock implementation for Simulator
class ONVYHealthKitMock {
  private currentSource = 'aggregated';
  private mockSteps = 8500;
  private mockHeartRate = 72;
  private mockSleep = 7.5;
  private updateInterval: NodeJS.Timeout | null = null;

  async setDataSource(source: string): Promise<{ success: boolean; source: string }> {
    this.currentSource = source;
    return { success: true, source };
  }

  async getAvailableSources(): Promise<DataSource[]> {
    return [
      { id: 'aggregated', name: 'Aggregated', authorized: true },
      { id: 'healthkit', name: 'HealthKit', authorized: false },
      { id: 'wearable', name: 'Mock Wearable', authorized: true },
      { id: 'nutrition', name: 'Mock Nutrition', authorized: true },
    ];
  }

  async requestAuthorization(): Promise<any> {
    // Simulate authorization
    await new Promise(resolve => setTimeout(resolve, 500));
    return {
      status: {
        steps: 'authorized',
        heartRate: 'authorized',
        sleep: 'authorized',
      },
    };
  }

  async checkAuthorizationStatus(): Promise<any> {
    return {
      status: {
        steps: 'authorized',
        heartRate: 'authorized',
        sleep: 'authorized',
      },
    };
  }

  async getSteps(date?: Date): Promise<{ steps: number; date: number }> {
    // Simulate some variation
    const steps = this.mockSteps + Math.floor(Math.random() * 200 - 100);
    return {
      steps: Math.max(0, steps),
      date: date ? date.getTime() : Date.now(),
    };
  }

  async getStepsForDays(days: number): Promise<{ data: any[] }> {
    const data = [];
    for (let i = 0; i < days; i++) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      data.push({
        date: date.getTime(),
        steps: Math.floor(Math.random() * 5000 + 5000),
        source: 'mock',
      });
    }
    return { data: data.reverse() };
  }

  async getLatestHeartRate(): Promise<any> {
    const hr = this.mockHeartRate + Math.floor(Math.random() * 10 - 5);
    return {
      heartRate: Math.max(60, Math.min(100, hr)),
      timestamp: Date.now(),
      source: 'mock',
    };
  }

  async getAverageHeartRate(date?: Date): Promise<any> {
    return {
      averageHeartRate: this.mockHeartRate,
      date: date ? date.getTime() : Date.now(),
    };
  }

  async getSleepData(date?: Date): Promise<any> {
    return {
      date: date ? date.getTime() : Date.now(),
      totalSleepHours: this.mockSleep,
      inBedHours: this.mockSleep + 0.5,
      asleepHours: this.mockSleep,
      awakeHours: 0.5,
      samples: [],
    };
  }

  async getHealthDataSummary(date?: Date): Promise<HealthDataSummary> {
    return {
      date: date ? date.getTime() : Date.now(),
      steps: this.mockSteps,
      averageHeartRate: this.mockHeartRate,
      sleepHours: this.mockSleep,
      activeCalories: 450,
      sources: ['Mock Wearable', 'Mock Nutrition'],
    };
  }

  async getWeeklyTrends(): Promise<{ data: WeeklyTrend[] }> {
    const data: WeeklyTrend[] = [];
    for (let i = 0; i < 7; i++) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      data.push({
        date: date.getTime(),
        steps: Math.floor(Math.random() * 3000 + 7000),
        averageHeartRate: Math.floor(Math.random() * 10 + 70),
        sleepHours: Math.random() * 2 + 7,
        activeCalories: Math.floor(Math.random() * 200 + 300),
        sources: ['Mock Wearable'],
      });
    }
    return { data: data.reverse() };
  }

  subscribeToSteps(callback: (data: any) => void): () => void {
    // Simulate updates every 3 seconds
    this.updateInterval = setInterval(() => {
      this.mockSteps += Math.floor(Math.random() * 50);
      callback({
        type: 'steps',
        value: this.mockSteps,
        timestamp: Date.now(),
      });
    }, 3000);

    return () => {
      if (this.updateInterval) {
        clearInterval(this.updateInterval);
      }
    };
  }

  subscribeToHeartRate(callback: (data: any) => void): () => void {
    const interval = setInterval(() => {
      this.mockHeartRate += Math.floor(Math.random() * 4 - 2);
      this.mockHeartRate = Math.max(60, Math.min(100, this.mockHeartRate));
      callback({
        heartRate: this.mockHeartRate,
        timestamp: Date.now(),
        source: 'mock',
      });
    }, 5000);

    return () => clearInterval(interval);
  }

  subscribeToLiveUpdates(callback: (data: any) => void): () => void {
    const interval = setInterval(() => {
      this.mockSteps += Math.floor(Math.random() * 20);
      this.mockHeartRate += Math.floor(Math.random() * 2 - 1);
      this.mockHeartRate = Math.max(60, Math.min(100, this.mockHeartRate));
      
      callback({
        steps: this.mockSteps,
        heartRate: this.mockHeartRate,
        timestamp: Date.now(),
        sources: ['Mock Wearable'],
      });
    }, 3000);

    return () => clearInterval(interval);
  }

  subscribeToAuthorizationStatus(callback: (status: any) => void): () => void {
    // No-op for mock
    return () => {};
  }

  subscribeToSourceChange(callback: (source: string) => void): () => void {
    // No-op for mock
    return () => {};
  }

  async sendHealthDataToBackend(date?: Date): Promise<{ success: boolean }> {
    console.log('📤 [MOCK] Sending health data to backend');
    const summary = await this.getHealthDataSummary(date);
    console.log('Payload:', JSON.stringify(summary, null, 2));
    console.log('✅ [MOCK] Health data sent successfully');
    return { success: true };
  }

  async clearCache(): Promise<{ success: boolean }> {
    return { success: true };
  }
}

export default new ONVYHealthKitMock();
