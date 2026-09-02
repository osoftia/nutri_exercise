import { AiInteraction } from '../models/interaction.model';

export const mockInteractions: AiInteraction[] = [
  {
    id: '2f4d7c1a-9c3e-4b8f-8a2e-6d1f5a9c0b31',
    userPrompt: 'Age: 28, Goal: build_muscle, Level: intermediate, Days: 4',
    generatedRoutine:
      'Weekly routine\n\nDay 1 - Push: Bench press 4x8, Overhead press 3x10, Lateral raise 3x12\nDay 2 - Pull: Deadlift 3x5, Pull-ups 4x8, Barbell row 3x10\nDay 3 - Legs: Squat 4x6, Romanian deadlift 3x8, Leg press 3x12\nDay 4 - Upper: Incline bench 4x8, Cable row 3x10, Curl 3x12',
    rating: null,
    feedbackText: null,
    createdAt: '2026-08-17T09:30:00Z',
    model: 'llama3.2',
    status: 'completed',
  },
  {
    id: '7a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d',
    userPrompt: 'Age: 35, Goal: fat_loss, Level: beginner, Days: 3',
    generatedRoutine:
      'Weekly routine\n\nDay 1 - Full body: Squats 3x12, Push-ups 3x10, Dumbbell row 3x10\nDay 2 - Rest\nDay 3 - Full body: Lunges 3x10, Bench press 3x10, Lat pulldown 3x12',
    rating: 'thumbs_up',
    feedbackText: 'Great volume but reduce rest to 60s.',
    createdAt: '2026-08-16T18:05:00Z',
    model: 'llama3.2',
    status: 'completed',
  },
  {
    id: '3c4d5e6f-7a8b-9c0d-1e2f-3a4b5c6d7e8f',
    userPrompt: 'Age: 42, Goal: strength, Level: advanced, Days: 5',
    generatedRoutine:
      'Weekly routine\n\nDay 1 - Squat focus: Squat 5x5, Front squat 4x8\nDay 2 - Bench focus: Bench press 5x5, Incline dumbbell 4x10\nDay 3 - Rest\nDay 4 - Deadlift focus: Deadlift 5x3, Rack pull 4x5\nDay 5 - Press focus: Overhead press 5x5, Dips 4x8',
    rating: null,
    feedbackText: null,
    createdAt: '2026-08-15T07:45:00Z',
    model: 'llama3.2',
    status: 'completed',
  },
];

export function mockApplyFeedback(id: string, feedbackText: string): AiInteraction {
  const current = mockInteractions.find((interaction) => interaction.id === id);
  if (!current) {
    throw new Error(`Unknown interaction: ${id}`);
  }
  const updated: AiInteraction = { ...current, feedbackText };
  const index = mockInteractions.findIndex((interaction) => interaction.id === id);
  mockInteractions[index] = updated;
  return updated;
}