import {
  BloodPressureReading,
  BmiReading,
  CalorieRecord,
  GlucoseReading,
  HealthInsight,
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

function bloodPressureInsight(systolic: number, diastolic: number): HealthInsight | undefined {
  if (systolic >= 140 || diastolic >= 90) {
    return {
      risk: 'Hypertensive-range reading. Recheck after 5 minutes of rest.',
      advice: 'If it stays high, contact your clinician and log the readings.',
    };
  }
  if (systolic >= 130 || diastolic >= 85) {
    return {
      warning: 'Blood pressure is above the optimal range today.',
      advice: 'Cut back on sodium and caffeine, then take a short walk.',
    };
  }
  return undefined;
}

function glucoseInsight(value: number): HealthInsight | undefined {
  if (value >= 126) {
    return {
      risk: 'Fasting glucose in the diabetic range.',
      advice: 'Prioritise fibre and protein and review this with your clinician.',
    };
  }
  if (value >= 100) {
    return {
      warning: 'Fasting glucose above the 70-99 mg/dL target.',
      advice: 'Pair carbohydrates with protein and walk after meals.',
    };
  }
  return undefined;
}

function bmiInsight(value: number): HealthInsight | undefined {
  if (value >= 30) {
    return {
      warning: 'BMI is in the obese range.',
      advice: 'Aim for a 300-500 kcal daily deficit plus 2 strength sessions.',
    };
  }
  if (value >= 25) {
    return { advice: 'BMI is trending down - keep this gradual pace.' };
  }
  return undefined;
}

function sleepInsight(score: number, hours: number): HealthInsight | undefined {
  if (score < 55 || hours < 6) {
    return {
      warning: 'Short, low-quality sleep detected.',
      advice: 'Set a consistent bedtime and avoid screens one hour before.',
    };
  }
  if (score >= 85) {
    return { advice: 'Excellent recovery - protect this routine.' };
  }
  return undefined;
}

function calorieInsight(value: number): HealthInsight | undefined {
  if (value >= 750) {
    return { advice: 'Strong activity day - great cardiovascular stimulus.' };
  }
  if (value < 250) {
    return {
      warning: 'Very low activity today.',
      advice: 'Add a 20-minute brisk walk to reach your base target.',
    };
  }
  return undefined;
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

    const systolic = clamp(
      round(122 + 8 * Math.sin(day / 34) - recovery + (random() - 0.5) * 9),
      108,
      165,
    );
    const diastolic = clamp(
      round(78 + 4 * Math.sin(day / 27) - recovery * 0.4 + (random() - 0.5) * 6),
      66,
      104,
    );
    bloodPressure.push({
      date,
      systolic,
      diastolic,
      pulse: round(68 + (random() - 0.5) * 8),
      insights: bloodPressureInsight(systolic, diastolic),
    });

    const glucoseValue = round(
      clamp(101 - day * 0.02 + 9 * Math.sin(day / 16) + (random() - 0.5) * 11, 72, 138),
    );
    glucose.push({ date, value: glucoseValue, insights: glucoseInsight(glucoseValue) });

    const bmiValue = round(28.4 - day * 0.006 + (random() - 0.5) * 0.18, 1);
    bmi.push({ date, value: bmiValue, insights: bmiInsight(bmiValue) });

    const weekend = [0, 6].includes(new Date(Date.UTC(2025, 9, 6 + day)).getUTCDay()) ? 1 : 0;
    const calories = round(
      clamp(420 + 130 * Math.sin(day / 6.5) + weekend * 140 + (random() - 0.5) * 150, 120, 980),
    );
    activeCalories.push({ date, value: calories, insights: calorieInsight(calories) });

    const score = round(clamp(74 + 16 * Math.sin(day / 8) + (random() - 0.5) * 22, 8, 99));
    const hours = round(clamp(7.1 + 1.1 * Math.sin(day / 8) + (random() - 0.5) * 1.4, 4.2, 9.4), 1);
    sleep.push({ date, score, hours, insights: sleepInsight(score, hours) });
  }

  return { bloodPressure, glucose, bmi, sleep, activeCalories };
}

export const MOCK_HEALTH_METRICS: HealthMetricsPayload = buildMockHealthMetrics();
