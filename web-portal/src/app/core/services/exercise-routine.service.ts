import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { delay, map } from 'rxjs/operators';
import { environment } from '../../../environments/environment';
import { GenericExercise, CreateExercisePayload, UpdateExercisePayload } from '../models/routine-board.model';
import { mockWorkoutRoutines } from '../mocks/mock-routine.data';
import { fromWorkoutDay, toGenericExercise } from '../utils/exercise.mapper';

const STORAGE_KEY = 'nutri_exercise_generic_exercises';

@Injectable({ providedIn: 'root' })
export class ExerciseRoutineService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${environment.apiUrl}/api/v1/exercises/generic`;

  getCatalog(): Observable<GenericExercise[]> {
    if (environment.useMocks) {
      return of(this.loadFromStorageOrMocks()).pipe(delay(300));
    }
    return this.http.get<GenericExercise[]>(this.baseUrl);
  }

  create(payload: CreateExercisePayload): Observable<GenericExercise> {
    const exercise = toGenericExercise(payload, Date.now());
    if (environment.useMocks) {
      const catalog = this.loadFromStorageOrMocks();
      const next = [...catalog, exercise];
      this.saveToStorage(next);
      return of(exercise).pipe(delay(300));
    }
    return this.http.post<GenericExercise>(this.baseUrl, payload);
  }

  update(id: number, payload: UpdateExercisePayload): Observable<GenericExercise> {
    if (environment.useMocks) {
      const catalog = this.loadFromStorageOrMocks();
      const idx = catalog.findIndex((e) => e.id === id);
      if (idx === -1) return of(null as unknown as GenericExercise).pipe(delay(300));
      const updated = { ...catalog[idx], ...payload } as GenericExercise;
      const next = catalog.map((e) => (e.id === id ? updated : e));
      this.saveToStorage(next);
      return of(updated).pipe(delay(300));
    }
    return this.http.patch<GenericExercise>(`${this.baseUrl}/${id}`, payload);
  }

  bulkDelete(ids: number[]): Observable<void> {
    if (environment.useMocks) {
      const catalog = this.loadFromStorageOrMocks().filter((e) => !ids.includes(e.id));
      this.saveToStorage(catalog);
      return of(void 0).pipe(delay(300));
    }
    return this.http.post<void>(`${this.baseUrl}/bulk-delete`, { ids });
  }

  search(query: string): Observable<GenericExercise[]> {
    return this.getCatalog().pipe(map((items) => filterByQuery(items, query)));
  }

  private loadFromStorageOrMocks(): GenericExercise[] {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) return JSON.parse(raw) as GenericExercise[];
    } catch {
      // fallback to mocks if storage fails
    }
    const fromMocks = mockWorkoutRoutines.flatMap((d) => fromWorkoutDay(d));
    this.saveToStorage(fromMocks);
    return fromMocks;
  }

  private saveToStorage(items: GenericExercise[]): void {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(items));
    } catch {
      // ignore quota errors
    }
  }
}

function filterByQuery(items: GenericExercise[], query: string): GenericExercise[] {
  const q = query.trim().toLowerCase();
  if (!q) return items;
  return items.filter((e) => e.name.toLowerCase().includes(q) || e.muscleGroup.toLowerCase().includes(q));
}
