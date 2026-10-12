import { RagInsightsReport } from '../models/rag-insights.model';

export const MOCK_RAG_INSIGHTS: RagInsightsReport = {
  generatedAt: '2026-10-05',
  summaryKey: 'rag.report.summary',
  categories: [
    {
      id: 'lifestyle',
      titleKey: 'rag.category.lifestyle',
      rows: [
        {
          id: 'sleep-schedule',
          labelKey: 'rag.row.sleepSchedule',
          detailKey: 'rag.row.sleepSchedule.detail',
          metric: '6.4 h avg',
          severity: 'watch',
          chartId: 'sleep',
        },
        {
          id: 'stress-load',
          labelKey: 'rag.row.stressLoad',
          detailKey: 'rag.row.stressLoad.detail',
          metric: 'High',
          severity: 'watch',
        },
        {
          id: 'sedentary-evenings',
          labelKey: 'rag.row.sedentaryEvenings',
          detailKey: 'rag.row.sedentaryEvenings.detail',
          metric: '3.1k steps',
          severity: 'neutral',
          chartId: 'calories',
        },
      ],
    },
    {
      id: 'nutrition',
      titleKey: 'rag.category.nutrition',
      rows: [
        {
          id: 'sodium',
          labelKey: 'rag.row.sodium',
          detailKey: 'rag.row.sodium.detail',
          metric: '3.8 g/day',
          severity: 'risk',
          chartId: 'blood-pressure',
        },
        {
          id: 'added-sugar',
          labelKey: 'rag.row.addedSugar',
          detailKey: 'rag.row.addedSugar.detail',
          metric: '48 g/day',
          severity: 'watch',
          chartId: 'glucose',
        },
        {
          id: 'fiber',
          labelKey: 'rag.row.fiber',
          detailKey: 'rag.row.fiber.detail',
          metric: '12 g/day',
          severity: 'watch',
          chartId: 'glucose',
        },
      ],
    },
    {
      id: 'exercise',
      titleKey: 'rag.category.exercise',
      rows: [
        {
          id: 'cardio',
          labelKey: 'rag.row.cardio',
          detailKey: 'rag.row.cardio.detail',
          metric: '2 / week',
          severity: 'watch',
          chartId: 'calories',
        },
        {
          id: 'resistance',
          labelKey: 'rag.row.resistance',
          detailKey: 'rag.row.resistance.detail',
          metric: '1 / week',
          severity: 'watch',
          chartId: 'bmi',
        },
        {
          id: 'mobility',
          labelKey: 'rag.row.mobility',
          detailKey: 'rag.row.mobility.detail',
          metric: 'None',
          severity: 'neutral',
        },
      ],
    },
    {
      id: 'diseases',
      titleKey: 'rag.category.diseases',
      rows: [
        {
          id: 'hypertension',
          labelKey: 'rag.row.hypertension',
          detailKey: 'rag.row.hypertension.detail',
          metric: '136/88 mmHg',
          severity: 'risk',
          chartId: 'blood-pressure',
        },
        {
          id: 'prediabetes',
          labelKey: 'rag.row.prediabetes',
          detailKey: 'rag.row.prediabetes.detail',
          metric: '108 mg/dL',
          severity: 'risk',
          chartId: 'glucose',
        },
        {
          id: 'bmi-trajectory',
          labelKey: 'rag.row.bmiTrajectory',
          detailKey: 'rag.row.bmiTrajectory.detail',
          metric: '26.4',
          severity: 'watch',
          chartId: 'bmi',
        },
        {
          id: 'sleep-apnea',
          labelKey: 'rag.row.sleepApnea',
          detailKey: 'rag.row.sleepApnea.detail',
          metric: 'Score 52',
          severity: 'watch',
          chartId: 'sleep',
        },
      ],
    },
  ],
};
