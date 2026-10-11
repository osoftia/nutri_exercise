import '@angular/compiler';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { Injector, runInInjectionContext } from '@angular/core';
import { firstValueFrom } from 'rxjs';

import { MOCK_CLINICAL_EVOLUTION } from '../mocks/mock-clinical-evolution.data';
import { ClinicalEvolutionService } from './clinical-evolution.service';

describe('ClinicalEvolutionService', () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  it('emits the mock payload after a short delay', async () => {
    const injector = Injector.create({ providers: [ClinicalEvolutionService] });
    const service = runInInjectionContext(injector, () =>
      injector.get(ClinicalEvolutionService),
    );

    vi.useFakeTimers();
    const pending = firstValueFrom(service.load());
    await vi.advanceTimersByTimeAsync(600);

    await expect(pending).resolves.toEqual(MOCK_CLINICAL_EVOLUTION);
  });
});
