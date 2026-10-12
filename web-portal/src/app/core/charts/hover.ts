import { Signal, WritableSignal, computed, signal } from '@angular/core';

import { nearestIndex } from './geometry/nearest';
import { Rect, SeriesPoint } from './models/chart.model';

export interface HoverTooltip {
  x: number;
  y: number;
  width: number;
  height: number;
  lines: string[];
}

export interface NearestHoverOptions {
  points: () => SeriesPoint[];
  lines: (point: SeriesPoint) => string[];
  plot: () => Rect | null;
  viewWidth: () => number;
  width?: number;
}

export interface NearestHover {
  hoveredIndex: WritableSignal<number>;
  tooltip: Signal<HoverTooltip | null>;
  onMove(event: MouseEvent): void;
  clear(): void;
}

export function useNearestHover(options: NearestHoverOptions): NearestHover {
  const hoveredIndex = signal(-1);
  const boxWidth = options.width ?? 168;

  const tooltip = computed<HoverTooltip | null>(() => {
    const plot = options.plot();
    const points = options.points();
    const point = points[hoveredIndex()];
    if (!plot || !point) {
      return null;
    }
    const lines = options.lines(point);
    const height = lines.length * 18 + 12;
    const x = Math.min(Math.max(point.x - boxWidth / 2, plot.x), plot.x + plot.width - boxWidth);
    return { x, y: plot.y + 6, width: boxWidth, height, lines };
  });

  return {
    hoveredIndex,
    tooltip,
    onMove(event: MouseEvent): void {
      const plot = options.plot();
      const points = options.points();
      if (!plot || points.length === 0) {
        return;
      }
      const element = event.currentTarget as SVGGraphicsElement;
      const bounds = element.getBoundingClientRect();
      const ratio = options.viewWidth() / (bounds.width || 1);
      const x = (event.clientX - bounds.left) * ratio;
      hoveredIndex.set(nearestIndex(points.map((point) => point.x), x));
    },
    clear(): void {
      hoveredIndex.set(-1);
    },
  };
}
