//
//  types.ts
//  Shared types for the demo app
//

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
