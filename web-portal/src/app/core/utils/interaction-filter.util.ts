import { AiInteraction } from '../models/interaction.model';

export interface InteractionFilters {
  query: string;
  from: Date | null;
  to: Date | null;
}

export function filterInteractions(
  items: AiInteraction[],
  filters: InteractionFilters,
): AiInteraction[] {
  const query = filters.query.trim().toLowerCase();
  return items.filter((interaction) => {
    const matchesQuery =
      query === '' ||
      [interaction.userPrompt, interaction.generatedRoutine, interaction.model ?? ''].some(
        (field) => field.toLowerCase().includes(query),
      );
    const created = new Date(interaction.createdAt);
    const matchesFrom = filters.from === null || created >= startOfDay(filters.from);
    const matchesTo = filters.to === null || created <= endOfDay(filters.to);
    return matchesQuery && matchesFrom && matchesTo;
  });
}

function startOfDay(date: Date): Date {
  const result = new Date(date);
  result.setHours(0, 0, 0, 0);
  return result;
}

function endOfDay(date: Date): Date {
  const result = new Date(date);
  result.setHours(23, 59, 59, 999);
  return result;
}