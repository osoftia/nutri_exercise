import {
  MatchedSource,
  PromptLabRequest,
  PromptLabResult,
} from './prompt-lab.model';

/**
 * Wire contracts for the .NET 8 RAG endpoint
 * (`POST {backendUrl}/api/rag/query`).
 * Property casing mirrors the C# DTOs (System.Text.Json defaults), e.g.:
 * `public string Query { get; set; }`, `public double Temperature { get; set; }`.
 */
export interface RagRequest {
  Query: string;
  SystemPrompt: string;
  Temperature: number;
  SimilarityThreshold: number;
}

export interface RagMatchItem {
  Id: string;
  Title: string;
  /** Cosine similarity score (0–1) from pgvector. */
  Score: number;
  Content?: string;
}

export interface RagTelemetry {
  LatencyMs: number;
  TokensPerSecond: number;
}

export interface RagResponse {
  Answer: string;
  MatchedSources: RagMatchItem[];
  Telemetry: RagTelemetry;
}

/**
 * Id of the seeded backend test user. The ingest form links every
 * document to this user automatically — no login required.
 */
export const DEFAULT_RAG_USER_ID = 1;

/**
 * Wire contract for the .NET 8 ingestion endpoint
 * (`POST {backendUrl}/api/rag/ingest`).
 * Property casing mirrors the C# DTOs (System.Text.Json defaults).
 */
export interface RagIngestRequest {
  Title: string;
  Content: string;
  BodyZone: string;
}

export interface RagIngestResponse {
  Id: string;
  UserId: number;
  Message: string;
}

export function toRagIngestRequest(title: string, content: string, bodyZone: string): RagIngestRequest {
  return {
    Title: title.trim(),
    Content: content,
    BodyZone: bodyZone.trim(),
  };
}
export function toRagRequest(request: PromptLabRequest): RagRequest {
  return {
    Query: request.query,
    SystemPrompt: request.systemPrompt,
    Temperature: request.temperature,
    SimilarityThreshold: request.similarityThreshold,
  };
}

function toMatchedSource(source: RagMatchItem): MatchedSource {
  return { id: source.Id, title: source.Title, score: source.Score };
}

export function fromRagResponse(response: RagResponse): PromptLabResult {
  return {
    answer: response.Answer,
    matchedSources: [...response.MatchedSources]
      .sort((a, b) => b.Score - a.Score)
      .map(toMatchedSource),
    latencyMs: response.Telemetry.LatencyMs,
    tokensPerSecond: response.Telemetry.TokensPerSecond,
  };
}
