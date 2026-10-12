import { DataPoint } from '../models/chart.model';

export function lttbIndices(
  xs: readonly number[],
  ys: readonly number[],
  threshold: number,
): number[] {
  const length = xs.length;
  if (threshold >= length || threshold <= 0) {
    return xs.map((_, index) => index);
  }
  if (threshold < 3) {
    return [0, length - 1];
  }

  const sampled: number[] = [0];
  const every = (length - 2) / (threshold - 2);
  let anchor = 0;

  for (let bucket = 0; bucket < threshold - 2; bucket += 1) {
    const averageStart = Math.min(Math.floor((bucket + 1) * every) + 1, length - 1);
    const averageEnd = Math.min(Math.floor((bucket + 2) * every) + 1, length);
    let averageX = 0;
    let averageY = 0;
    for (let index = averageStart; index < averageEnd; index += 1) {
      averageX += xs[index];
      averageY += ys[index];
    }
    const averageCount = Math.max(averageEnd - averageStart, 1);
    averageX /= averageCount;
    averageY /= averageCount;

    const rangeStart = Math.floor(bucket * every) + 1;
    const rangeEnd = Math.min(Math.floor((bucket + 1) * every) + 1, length - 1);
    const anchorX = xs[anchor];
    const anchorY = ys[anchor];

    let maxArea = -1;
    let selected = rangeStart;
    for (let index = rangeStart; index < rangeEnd; index += 1) {
      const area = Math.abs(
        (anchorX - averageX) * (ys[index] - anchorY) -
          (anchorX - xs[index]) * (averageY - anchorY),
      );
      if (area > maxArea) {
        maxArea = area;
        selected = index;
      }
    }

    sampled.push(selected);
    anchor = selected;
  }

  sampled.push(length - 1);
  return sampled;
}

export function bucketAverage(data: readonly DataPoint[], targetCount: number): DataPoint[] {
  if (targetCount <= 0 || data.length <= targetCount) {
    return [...data];
  }
  const bucketSize = Math.ceil(data.length / targetCount);
  const result: DataPoint[] = [];
  for (let start = 0; start < data.length; start += bucketSize) {
    const slice = data.slice(start, start + bucketSize);
    const total = slice.reduce((sum, point) => sum + point.value, 0);
    result.push({ date: slice[0].date, value: Math.round((total / slice.length) * 100) / 100 });
  }
  return result;
}
