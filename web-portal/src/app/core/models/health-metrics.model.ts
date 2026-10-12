export interface BloodPressureReading {
  date: string;
  systolic: number;
  diastolic: number;
  pulse: number;
}

export interface GlucoseReading {
  date: string;
  value: number;
}

export interface BmiReading {
  date: string;
  value: number;
}

export interface SleepRecord {
  date: string;
  score: number;
  hours: number;
}

export interface CalorieRecord {
  date: string;
  value: number;
}

export interface HealthMetricsPayload {
  bloodPressure: BloodPressureReading[];
  glucose: GlucoseReading[];
  bmi: BmiReading[];
  sleep: SleepRecord[];
  activeCalories: CalorieRecord[];
}
