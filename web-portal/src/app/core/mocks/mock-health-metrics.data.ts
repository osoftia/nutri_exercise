import {
  BloodPressureReading,
  BmiReading,
  CalorieRecord,
  GlucoseReading,
  HealthMetricsPayload,
  SleepRecord,
} from '../models/health-metrics.model';

const DAYS = 365;
const START_MS = Date.UTC(2025, 9, 6);
const MS_PER_DAY = 86_400_000;

function mulberry32(seed: number): () => number {
  let state = seed;
  return () => {
    state += 0x6d2b79f5;
    let t = state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function isoDate(dayIndex: number): string {
  return new Date(START_MS + dayIndex * MS_PER_DAY).toISOString().slice(0, 10);
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

function round(value: number, decimals = 0): number {
  const factor = Math.pow(10, decimals);
  return Math.round(value * factor) / factor;
}

export function buildMockHealthMetrics(): HealthMetricsPayload {
  const random = mulberry32(20261006);
  const bloodPressure: BloodPressureReading[] = [];
  const glucose: GlucoseReading[] = [];
  const bmi: BmiReading[] = [];
  const sleep: SleepRecord[] = [];
  const activeCalories: CalorieRecord[] = [];

  for (let day = 0; day < DAYS; day += 1) {
    const date = isoDate(day);
    const recovery = day < 200 ? (200 - day) * 0.035 : 0;

    const systolic = round(122 + 8 * Math.sin(day / 34) - recovery + (random() - 0.5) * 9);
    const diastolic = round(78 + 4 * Math.sin(day / 27) - recovery * 0.4 + (random() - 0.5) * 6);
    bloodPressure.push({
      date,
      systolic: clamp(systolic, 108, 165),
      diastolic: clamp(diastolic, 66, 104),
      pulse: round(68 + (random() - 0.5) * 8),
    });

    glucose.push({
      date,
      value: round(clamp(101 - day * 0.02 + 9 * Math.sin(day / 16) + (random() - 0.5) * 11, 72, 138)),
    });

    bmi.push({ date, value: round(28.4 - day * 0.006 + (random() - 0.5) * 0.18, 1) });

    const weekend = [0, 6].includes(new Date(Date.UTC(2025, 9, 6 + day)).getUTCDay()) ? 1 : 0;
    activeCalories.push({
      date,
      value: round(clamp(420 + 130 * Math.sin(day / 6.5) + weekend * 140 + (random() - 0.5) * 150, 120, 980)),
    });

    sleep.push({
      date,
      score: round(clamp(74 + 16 * Math.sin(day / 8) + (random() - 0.5) * 22, 8, 99)),
      hours: round(clamp(7.1 + 1.1 * Math.sin(day / 8) + (random() - 0.5) * 1.4, 4.2, 9.4), 1),
    });
  }

  return { bloodPressure, glucose, bmi, sleep, activeCalories };
}

export const MOCK_HEALTH_METRICS: HealthMetricsPayload = buildMockHealthMetrics();
