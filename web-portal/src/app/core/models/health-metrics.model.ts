import { ChartInsight } from '../charts/models/chart.model';

export type HealthInsight = ChartInsight;

export interface BloodPressureReading {
  date: string;
  systolic: number;
  diastolic: number;
  pulse: number;
  insights?: HealthInsight;
}

export interface GlucoseReading {
  date: string;
  value: number;
  insights?: HealthInsight;
}

export interface BmiReading {
  date: string;
  value: number;
  insights?: HealthInsight;
}

export interface SleepRecord {
  date: string;
  score: number;
  hours: number;
  insights?: HealthInsight;
}

export interface CalorieRecord {
  date: string;
  value: number;
  insights?: HealthInsight;
}

export interface HealthMetricsPayload {
  bloodPressure: BloodPressureReading[];
  glucose: GlucoseReading[];
  bmi: BmiReading[];
  sleep: SleepRecord[];
  activeCalories: CalorieRecord[];
}

export type ChartId = 'blood-pressure' | 'glucose' | 'bmi' | 'sleep' | 'calories';

export type HealthTab = 'dashboard' | 'rag';
