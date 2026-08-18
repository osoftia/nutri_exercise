import { AiInteraction } from '../models/interaction.model';

export interface DpoDatasetRow {
  prompt: string;
  chosen: string;
  rejected: string;
  model: string;
  interaction_id: string;
  created_at: string;
}

export function isDpoEligible(interaction: AiInteraction): boolean {
  return (
    interaction.rating !== null &&
    interaction.feedbackText !== null &&
    interaction.feedbackText.trim() !== ''
  );
}

export function toDpoRow(interaction: AiInteraction): DpoDatasetRow {
  const thumbsUp = interaction.rating === 'thumbs_up';
  return {
    prompt: interaction.userPrompt,
    chosen: thumbsUp ? interaction.generatedRoutine : interaction.feedbackText ?? '',
    rejected: thumbsUp ? interaction.feedbackText ?? '' : interaction.generatedRoutine,
    model: interaction.model ?? '',
    interaction_id: interaction.id,
    created_at: interaction.createdAt,
  };
}

export function buildDpoJsonl(interactions: AiInteraction[]): string {
  const lines = interactions
    .filter(isDpoEligible)
    .map((interaction) => JSON.stringify(toDpoRow(interaction)));
  return lines.length > 0 ? `${lines.join('\n')}\n` : '';
}

export function buildDpoFileName(date: Date = new Date()): string {
  const yyyy = date.getFullYear();
  const mm = String(date.getMonth() + 1).padStart(2, '0');
  const dd = String(date.getDate()).padStart(2, '0');
  return `dpo-dataset-${yyyy}-${mm}-${dd}.jsonl`;
}