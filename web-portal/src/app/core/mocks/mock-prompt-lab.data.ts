import { PromptLabResult } from '../models/prompt-lab.model';
import { DEFAULT_RAG_USER_ID, RagIngestRequest, RagIngestResponse } from '../models/rag.model';

export const MOCK_PROMPT_LAB_RESULT: PromptLabResult = {
  answer:
    '## Recovery Routine After Intense Dance Rehearsal\n\n' +
    '1. **Cool-down (5 min):** Low-intensity stretching focusing on calves, hamstrings, and hip flexors.\n' +
    '2. **Hydration:** 500 ml water with electrolytes within 30 minutes.\n' +
    '3. **Nutrition:** 20 g whey protein + fast-acting carbs (banana or rice cake) within 45 minutes.\n' +
    '4. **Active recovery (next day):** 20 min light yoga or swimming.\n' +
    '5. **Sleep:** Target 8 hours; magnesium supplement (200 mg) before bed.',
  matchedSources: [
    { id: 'src-001', title: 'Dance-specific recovery protocols', score: 0.94 },
    { id: 'src-002', title: 'Post-exercise nutrition for performers', score: 0.87 },
    { id: 'src-003', title: 'Sleep and muscle recovery in athletes', score: 0.79 },
  ],
  latencyMs: 1842,
  tokensPerSecond: 38,
};

export function mockPromptLabResponse(query: string): PromptLabResult {
  return {
    ...MOCK_PROMPT_LAB_RESULT,
    answer: MOCK_PROMPT_LAB_RESULT.answer.replace(
      'Recovery Routine After Intense Dance Rehearsal',
      `Response to: "${query}"`,
    ),
  };
}

export function mockRagIngestResponse(request: RagIngestRequest): RagIngestResponse {
  return {
    Id: 'doc-mock-001',
    UserId: DEFAULT_RAG_USER_ID,
    Message: `Document "${request.Title}" ingested successfully.`,
  };
}