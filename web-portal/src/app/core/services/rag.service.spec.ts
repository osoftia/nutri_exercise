import '@angular/compiler';
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { Injector, runInInjectionContext } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom, of } from 'rxjs';

import { environment } from '../../../environments/environment';
import { MOCK_PROMPT_LAB_RESULT } from '../mocks/mock-prompt-lab.data';import {
  RagIngestRequest,
  RagIngestResponse,
  RagRequest,
  RagResponse,
  fromRagResponse,
  toRagIngestRequest,
  toRagRequest,
} from '../models/rag.model';
import { RagService } from './rag.service';
import { RagLoggerService } from './rag-logger.service';

const ragRequest: RagRequest = {
  Query: 'Recovery routine after intense dance rehearsal',
  SystemPrompt: 'You are a sports nutrition expert',
  Temperature: 0.7,
  SimilarityThreshold: 0.8,
};

describe('rag.model mappers', () => {
  it('maps a PromptLab request to the PascalCase .NET contract', () => {
    expect(
      toRagRequest({
        query: 'q',
        systemPrompt: 's',
        temperature: 0.5,
        similarityThreshold: 0.9,
      }),
    ).toEqual({ Query: 'q', SystemPrompt: 's', Temperature: 0.5, SimilarityThreshold: 0.9 });
  });

  it('maps a RAG response back and sorts sources by descending score', () => {
    const response: RagResponse = {
      Answer: 'answer',
      MatchedSources: [
        { Id: 'b', Title: 'B', Score: 0.5 },
        { Id: 'a', Title: 'A', Score: 0.9 },
      ],
      Telemetry: { LatencyMs: 100, TokensPerSecond: 40 },
    };
    expect(fromRagResponse(response)).toEqual({
      answer: 'answer',
      matchedSources: [
        { id: 'a', title: 'A', score: 0.9 },
        { id: 'b', title: 'B', score: 0.5 },
      ],
      latencyMs: 100,
      tokensPerSecond: 40,
    });
  });
});

describe('RagService', () => {
  let service: RagService;
  let httpPost: ReturnType<typeof vi.fn>;
  let useMocks: boolean;

  beforeEach(() => {
    useMocks = environment.useMocks;
    httpPost = vi.fn();
    const injector = Injector.create({
      providers: [
        { provide: HttpClient, useValue: { post: httpPost } },
        RagLoggerService,
        RagService,
      ],
    });
    service = runInInjectionContext(injector, () => injector.get(RagService));
  });

  afterEach(() => {
    environment.useMocks = useMocks;
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  it('serves the mock answer in mock mode without HTTP', async () => {
    environment.useMocks = true;
    vi.useFakeTimers();
    const result = firstValueFrom(service.runPromptLab({
      query: ragRequest.Query,
      systemPrompt: ragRequest.SystemPrompt,
      temperature: ragRequest.Temperature,
      similarityThreshold: ragRequest.SimilarityThreshold,
    }));
    await vi.advanceTimersByTimeAsync(800);

    expect(await result).toMatchObject({ latencyMs: 1842, tokensPerSecond: 38 });
    expect(httpPost).not.toHaveBeenCalled();
  });

  it('serves the PascalCase mock response for query() in mock mode', async () => {
    environment.useMocks = true;
    vi.useFakeTimers();
    const result = firstValueFrom(service.query(ragRequest));
    await vi.advanceTimersByTimeAsync(800);

    const response = await result;
    expect(response.Telemetry.LatencyMs).toBe(1842);
    expect(response.MatchedSources.map((s) => s.Score)).toEqual([0.94, 0.87, 0.79]);
    expect(httpPost).not.toHaveBeenCalled();
  });

  it('posts the PascalCase payload to the Mac backend when mocks are off', async () => {
    environment.useMocks = false;
    const backend: RagResponse = {
      Answer: 'backend answer',
      MatchedSources: [{ Id: 's1', Title: 'Doc', Score: 0.91 }],
      Telemetry: { LatencyMs: 900, TokensPerSecond: 42 },
    };
    httpPost.mockReturnValue(of(backend));

    const result = await firstValueFrom(service.query(ragRequest));

    expect(httpPost).toHaveBeenCalledWith(
      `${environment.backendUrl}/api/rag/query`,
      ragRequest,
    );
    expect(result).toEqual(backend);
  });

  it('maps the backend response to the PromptLab result shape', async () => {
    environment.useMocks = false;
    httpPost.mockReturnValue(
      of({
        Answer: MOCK_PROMPT_LAB_RESULT.answer,
        MatchedSources: [{ Id: 's1', Title: 'Doc', Score: 0.91 }],
        Telemetry: { LatencyMs: 900, TokensPerSecond: 42 },
      } satisfies RagResponse),
    );

    const result = await firstValueFrom(
      service.runPromptLab({
        query: 'q',
        systemPrompt: 's',
        temperature: 0.5,
        similarityThreshold: 0.9,
      }),
    );

    expect(httpPost).toHaveBeenCalledWith(
      `${environment.backendUrl}/api/rag/query`,
      { Query: 'q', SystemPrompt: 's', Temperature: 0.5, SimilarityThreshold: 0.9 },
    );
    expect(result.answer).toBe(MOCK_PROMPT_LAB_RESULT.answer);
    expect(result.matchedSources).toEqual([{ id: 's1', title: 'Doc', score: 0.91 }]);
    expect(result.latencyMs).toBe(900);
    expect(result.tokensPerSecond).toBe(42);
  });
});

describe('RagService.ingest', () => {
  let service: RagService;
  let httpPost: ReturnType<typeof vi.fn>;
  let useMocks: boolean;

  const ingestRequest: RagIngestRequest = {
    Title: 'Hip mobility basics',
    Content: 'Deep squat holds improve hip range of motion.',
    BodyZone: 'Legs',
  };

  beforeEach(() => {
    useMocks = environment.useMocks;
    httpPost = vi.fn();
    const injector = Injector.create({
      providers: [
        { provide: HttpClient, useValue: { post: httpPost } },
        RagLoggerService,
        RagService,
      ],
    });
    service = runInInjectionContext(injector, () => injector.get(RagService));
  });

  afterEach(() => {
    environment.useMocks = useMocks;
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  it('builds a trimmed PascalCase ingest payload', () => {
    expect(toRagIngestRequest('  Hip mobility  ', 'content', '  Legs ')).toEqual({
      Title: 'Hip mobility',
      Content: 'content',
      BodyZone: 'Legs',
    });
  });

  it('serves the mock ingest response in mock mode without HTTP', async () => {
    environment.useMocks = true;
    vi.useFakeTimers();
    const result = firstValueFrom(service.ingest(ingestRequest));
    await vi.advanceTimersByTimeAsync(800);

    const response = await result;
    expect(response.UserId).toBe(1);
    expect(response.Message).toContain('Hip mobility basics');
    expect(httpPost).not.toHaveBeenCalled();
  });

  it('posts the document to /api/rag/ingest when mocks are off', async () => {
    environment.useMocks = false;
    const backend: RagIngestResponse = {
      Id: 'doc-123',
      UserId: 1,
      Message: 'Document ingested successfully.',
    };
    httpPost.mockReturnValue(of(backend));

    const result = await firstValueFrom(service.ingest(ingestRequest));

    expect(httpPost).toHaveBeenCalledWith(
      `${environment.backendUrl}/api/rag/ingest`,
      ingestRequest,
    );
    expect(result).toEqual(backend);
  });

  it('logs [RAG-INFO]: on successful ingestion and [RAG-ERROR]: on HTTP failure', async () => {
    environment.useMocks = false;
    const infoSpy = vi.spyOn(console, 'info').mockImplementation(() => undefined);
    const errorSpy = vi.spyOn(console, 'error').mockImplementation(() => undefined);

    httpPost.mockReturnValue(
      of({ Id: 'doc-1', UserId: 1, Message: 'ok' } satisfies RagIngestResponse),
    );
    await firstValueFrom(service.ingest(ingestRequest));
    expect(infoSpy).toHaveBeenCalledWith(
      expect.stringContaining('[RAG-INFO]:'),
      expect.objectContaining({ title: 'Hip mobility basics', userId: 1 }),
    );

    const { throwError } = await import('rxjs');
    httpPost.mockReturnValue(throwError(() => new Error('network down')));
    await expect(firstValueFrom(service.ingest(ingestRequest))).rejects.toThrow('network down');
    expect(errorSpy).toHaveBeenCalledWith(
      expect.stringContaining('[RAG-ERROR]:'),
      expect.any(Error),
    );
  });
});
