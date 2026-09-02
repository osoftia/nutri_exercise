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
}