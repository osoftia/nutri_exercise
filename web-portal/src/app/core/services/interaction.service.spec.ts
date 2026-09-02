import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { firstValueFrom } from 'rxjs';
import {
  provideHttpClient,
  withInterceptors,
} from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';

import { environment } from '../../../environments/environment';
import { AiInteraction } from '../models/interaction.model';
import { mockInteractions } from '../mocks/mock-interactions.data';
import { errorInterceptor } from '../interceptors/error.interceptor';
import { InteractionService } from './interaction.service';

const interaction: AiInteraction = {
  id: 'fixture-id',
  userPrompt: 'Age: 28, Goal: build_muscle, Level: intermediate',
  generatedRoutine: 'Weekly routine\nDay 1 - Push: Bench press 4x8',
  rating: null,
  feedbackText: null,
  createdAt: '2026-08-17T09:30:00Z',
};

describe('InteractionService', () => {
  let service: InteractionService;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        InteractionService,
        provideHttpClient(withInterceptors([errorInterceptor])),
        provideHttpClientTesting(),
      ],
    });
    service = TestBed.inject(InteractionService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    environment.useMocks = true;
    vi.useRealTimers();
    http.verify();
  });

  describe('mock mode', () => {
    it('returns mock interactions', async () => {
      vi.useFakeTimers();
      const result = firstValueFrom(service.getInteractions());
      await vi.advanceTimersByTimeAsync(500);

      expect(await result).toEqual(mockInteractions);
    });

    it('applies feedback to the matching mock interaction', async () => {
      vi.useFakeTimers();
      const id = mockInteractions[0].id;
      const result = firstValueFrom(service.updateFeedback(id, { feedbackText: 'Nice volume' }));
      await vi.advanceTimersByTimeAsync(300);

      const updated = await result;
      expect(updated?.id).toBe(id);
      expect(updated?.feedbackText).toBe('Nice volume');
    });
  });

  describe('http mode', () => {
    beforeEach(() => {
      environment.useMocks = false;
    });

    it('GETs interactions from the API', () => {
      let result: AiInteraction[] | undefined;
      service.getInteractions().subscribe((data) => (result = data));

      const req = http.expectOne('http://localhost:5000/api/interactions');
      expect(req.request.method).toBe('GET');
      req.flush([interaction]);

      expect(result).toEqual([interaction]);
    });

    it('PATCHes feedback to the API', () => {
      let result: AiInteraction | undefined;
      service.updateFeedback('fixture-id', { feedbackText: 'Nice volume' }).subscribe((data) => (result = data));

      const req = http.expectOne('http://localhost:5000/api/interactions/fixture-id/feedback');
      expect(req.request.method).toBe('PATCH');
      expect(req.request.body).toEqual({ feedbackText: 'Nice volume' });
      req.flush({ ...interaction, feedbackText: 'Nice volume' });

      expect(result?.feedbackText).toBe('Nice volume');
    });
  });
});