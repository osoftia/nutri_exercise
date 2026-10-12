export function nearestIndex(sortedValues: readonly number[], target: number): number {
  if (sortedValues.length === 0) {
    return -1;
  }
  let low = 0;
  let high = sortedValues.length - 1;
  while (high - low > 1) {
    const mid = (low + high) >> 1;
    if (sortedValues[mid] < target) {
      low = mid;
    } else {
      high = mid;
    }
  }
  return Math.abs(sortedValues[low] - target) <= Math.abs(sortedValues[high] - target)
    ? low
    : high;
}
