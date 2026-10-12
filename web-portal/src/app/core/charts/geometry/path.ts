import { Point } from '../models/chart.model';

export function toPolyline(points: readonly Point[]): string {
  return points.map((point) => `${point.x},${point.y}`).join(' ');
}

export function toAreaPath(points: readonly Point[], baseline: number): string {
  if (points.length === 0) {
    return '';
  }
  const line = points.map((point, index) => `${index === 0 ? 'M' : 'L'}${point.x} ${point.y}`).join(' ');
  const first = points[0];
  const last = points[points.length - 1];
  return `${line} L${last.x} ${baseline} L${first.x} ${baseline} Z`;
}
