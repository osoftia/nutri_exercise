import { AiInteraction } from '../models/interaction.model';

export interface AnalyticsMetrics {
  totalRoutines: number;
  reviewedCount: number;
  positiveCount: number;
  negativeCount: number;
  positivePercent: number;
  negativePercent: number;
}

export function computeAnalytics(interactions: AiInteraction[]): AnalyticsMetrics {
  const totalRoutines = interactions.length;
  const reviewedCount = interactions.filter((interaction) => interaction.rating !== null).length;
  const positiveCount = interactions.filter(
    (interaction) => interaction.rating === 'thumbs_up',
  ).length;
  const negativeCount = interactions.filter(
    (interaction) => interaction.rating === 'thumbs_down',
  ).length;
  return {
    totalRoutines,
    reviewedCount,
    positiveCount,
    negativeCount,
    positivePercent: percentage(positiveCount, reviewedCount),
    negativePercent: percentage(negativeCount, reviewedCount),
  };
}

function percentage(part: number, total: number): number {
  return total === 0 ? 0 : Math.round((part / total) * 100);
}