import { Component, computed, input } from '@angular/core';

export interface BarChartDatum {
  label: string;
  value: number;
}

interface ProgressBlock {
  track: { x: number; y: number; width: number; height: number };
  block: { x: number; y: number; width: number; height: number };
  text: { x: number; y: number; label: string; value: number; percent: number };
}

const WIDTH = 320;
const HEIGHT = 180;
const TRACK_HEIGHT = 120;
const BLOCK_WIDTH = 22;
const BOTTOM = 148;

@Component({
  selector: 'app-bar-chart',
  imports: [],
  templateUrl: './bar-chart.html',
  styleUrl: './bar-chart.scss',
})
export class BarChart {
  readonly data = input<BarChartDatum[]>([]);

  readonly viewBoxValue = `0 0 ${WIDTH} ${HEIGHT}`;

  readonly blocks = computed<ProgressBlock[]>(() => {
    const items = this.data();
    if (items.length === 0) {
      return [];
    }
    const max = Math.max(...items.map((item) => item.value));
    const slot = WIDTH / items.length;
    return items.map((item, index) => {
      const normalized = max === 0 ? 0 : item.value / max;
      const percent = Math.round(normalized * 100);
      const x = index * slot + (slot - BLOCK_WIDTH) / 2;
      const blockHeight = normalized * TRACK_HEIGHT;
      const blockY = BOTTOM - blockHeight;
      return {
        track: {
          x,
          y: BOTTOM - TRACK_HEIGHT,
          width: BLOCK_WIDTH,
          height: TRACK_HEIGHT,
        },
        block: {
          x,
          y: blockY,
          width: BLOCK_WIDTH,
          height: blockHeight,
        },
        text: {
          x: index * slot + slot / 2,
          y: BOTTOM + 20,
          label: item.label,
          value: item.value,
          percent,
        },
      };
    });
  });
}
