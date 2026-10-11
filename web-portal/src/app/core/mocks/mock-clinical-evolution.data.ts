import { ClinicalEvolutionPayload } from '../models/clinical-evolution.model';

export const MOCK_CLINICAL_EVOLUTION: ClinicalEvolutionPayload = {
  health_score: 32,
  metric: {
    title: 'Cardiometabolic follow-up',
    consumption_label: 'Saturated fat',
    consumption_unit: 'g',
    marker_label: 'Cholesterol',
    marker_unit: 'mg/dL',
  },
  historical_data: [
    { date: '2026-08-17', consumption: 42, actual_marker: 232 },
    { date: '2026-08-24', consumption: 45, actual_marker: 228 },
    { date: '2026-08-31', consumption: 41, actual_marker: 225 },
    { date: '2026-09-07', consumption: 38, actual_marker: 219 },
    { date: '2026-09-14', consumption: 36, actual_marker: 214 },
    { date: '2026-09-21', consumption: 33, actual_marker: 208 },
    { date: '2026-09-28', consumption: 30, actual_marker: 203 },
    { date: '2026-10-05', consumption: 28, actual_marker: 198 },
  ],
  projected_data: [
    { date: '2026-10-12', projected_marker: 193 },
    { date: '2026-10-19', projected_marker: 188 },
    { date: '2026-10-26', projected_marker: 182 },
    { date: '2026-11-02', projected_marker: 177 },
  ],
};
