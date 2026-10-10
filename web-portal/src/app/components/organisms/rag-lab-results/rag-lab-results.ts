import { Component, computed, inject, signal } from '@angular/core';

import { MatchedSource } from '../../../core/models/prompt-lab.model';
import { RagMatchItem } from '../../../core/models/rag.model';
import { RagLabStore } from '../../../core/stores/rag-lab.store';

/**
 * Normalized view model for one semantic match card.
 *
 * The store exposes `MatchedSource[]` (camelCase, mapped from the
 * PascalCase `RagMatchItem[]` wire contract via `fromRagResponse`).
 * Optional `content` / `bodyZone` excerpts are rendered only when present.
 */
export interface RagResultCard {
  id: string;
  title: string;
  /** Cosine similarity score (0–1) from pgvector. */
  score: number;
  content: string | null;
  bodyZone: string | null;
}

/**
 * RLHF sentiment recorded per matched source.
 */
export type RagFeedbackSentiment = 'positive' | 'negative';

/**
 * Positive/Negative vote distribution over the current result set.
 * Mirrors the `{ positive, negative, reviewed }` analytics shape.
 */
export interface RagFeedbackDistribution {
  positive: number;
  negative: number;
  reviewed: number;
}

/**
 * Step 4 — Semantic Results Display ("Editorial Tech" brutalist).
 *
 * Reactive view over {@link RagLabStore}: it renders `store.isLoading()` /
 * `store.results()` loading, empty, error, and match-card states, plus local
 * Signals state for the selected detail card and per-card RLHF sentiment.
 * No constructor injection — dependencies resolve via `inject()`.
 */
@Component({
  selector: 'app-rag-lab-results',
  templateUrl: './rag-lab-results.html',
  styleUrl: './rag-lab-results.scss',
})
export class RagLabResults {
  readonly store = inject(RagLabStore);

  /** Id of the card expanded in the details modal, or null when closed. */
  readonly selectedId = signal<string | null>(null);
  /** One RLHF vote per source id. Scoped to the current result set. */
  readonly feedback = signal<Record<string, RagFeedbackSentiment>>({});

  readonly cards = computed<RagResultCard[]>(() =>
    (this.store.results()?.matchedSources ?? []).map((source, index) =>
      toResultCard(source, index),
    ),
  );

  readonly selectedCard = computed<RagResultCard | null>(
    () => this.cards().find((card) => card.id === this.selectedId()) ?? null,
  );

  readonly feedbackDistribution = computed<RagFeedbackDistribution>(() => {
    const votes = this.feedback();
    const currentIds = new Set(this.cards().map((card) => card.id));
    let positive = 0;
    let negative = 0;
    for (const [id, sentiment] of Object.entries(votes)) {
      if (!currentIds.has(id)) {
        continue;
      }
      if (sentiment === 'positive') {
        positive += 1;
      } else {
        negative += 1;
      }
    }
    return { positive, negative, reviewed: positive + negative };
  });

  formatScore(score: number): string {
    return `${(score * 100).toFixed(1)}%`;
  }

  openDetails(id: string): void {
    this.selectedId.set(id);
  }

  closeDetails(): void {
    this.selectedId.set(null);
  }

  /**
   * Records (or toggles off) an RLHF vote for a source. Voting the same
   * sentiment twice clears the vote; voting the opposite switches it.
   */
  rate(id: string, sentiment: RagFeedbackSentiment): void {
    this.feedback.update((votes) => {
      const next = { ...votes };
      if (next[id] === sentiment) {
        delete next[id];
        return next;
      }
      next[id] = sentiment;
      return next;
    });
  }
}

function toResultCard(source: MatchedSource | RagMatchItem | unknown, index: number): RagResultCard {
  const raw = (source ?? {}) as Record<string, unknown>;
  const zones = raw['bodyZones'];
  const firstZone =
    Array.isArray(zones) && typeof zones[0] === 'string' && zones[0].trim() !== ''
      ? (zones[0] as string)
      : null;

  return {
    id: text(raw['id'], raw['Id']) ?? `match-${index}`,
    title: text(raw['title'], raw['Title']) ?? 'Untitled source',
    score: numeric(raw['score'], raw['Score']),
    content:
      text(raw['content'], raw['Content'], raw['description'], raw['Description']) ?? null,
    bodyZone: text(raw['bodyZone'], raw['BodyZone']) ?? firstZone ?? text(raw['muscleGroup'], raw['MuscleGroup']),
  };
}

function text(...candidates: unknown[]): string | null {
  for (const candidate of candidates) {
    if (typeof candidate === 'string' && candidate.trim() !== '') {
      return candidate;
    }
  }
  return null;
}

function numeric(...candidates: unknown[]): number {
  for (const candidate of candidates) {
    if (typeof candidate === 'number' && Number.isFinite(candidate)) {
      return candidate;
    }
  }
  return 0;
}
