export interface PromptLabRequest {
  query: string;
  systemPrompt: string;
  temperature: number;
  similarityThreshold: number;
}

export interface MatchedSource {
  id: string;
  title: string;
  score: number;
}

export interface PromptLabResult {
  answer: string;
  matchedSources: MatchedSource[];
  latencyMs: number;
  tokensPerSecond: number;
}