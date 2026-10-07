export type AiRating = 'thumbs_up' | 'thumbs_down';
export type AiInteractionStatus = 'pending' | 'completed' | 'failed';

export interface AiInteraction {
  id: string;
  userPrompt: string;
  generatedRoutine: string;
  rating: AiRating | null;
  feedbackText: string | null;
  createdAt: string;
  model?: string;
  status?: AiInteractionStatus;
}

export interface UpdateFeedbackRequest {
  feedbackText: string;
  userId: number;
}

export type UpdateFeedbackPayload = Pick<UpdateFeedbackRequest, 'feedbackText'>;

/**
 * Id of the seeded backend test user. Feedback payloads are linked to
 * this user automatically — no login required.
 */
export const DEFAULT_TEST_USER_ID = 1;

/**
 * Strictly validates a Test User ID before it is sent in a payload.
 * Throws when the id is missing or not a positive integer.
 */
export function resolveTestUserId(userId: unknown): number {
  if (typeof userId !== 'number' || !Number.isInteger(userId) || userId <= 0) {
    throw new Error(
      `Invalid Test User ID: ${String(userId)}. Expected a positive integer (e.g. ${DEFAULT_TEST_USER_ID}).`,
    );
  }
  return userId;
}