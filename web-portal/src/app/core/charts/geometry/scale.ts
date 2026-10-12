export interface LinearScale {
  readonly domain: readonly [number, number];
  readonly range: readonly [number, number];
  map(value: number): number;
  invert(pixel: number): number;
}

export function createLinearScale(
  domain: readonly [number, number],
  range: readonly [number, number],
): LinearScale {
  const [d0, d1] = domain;
  const [r0, r1] = range;
  const domainSpan = d1 - d0 || 1;
  const rangeSpan = r1 - r0 || 1;
  return {
    domain,
    range,
    map: (value: number) => r0 + ((value - d0) / domainSpan) * rangeSpan,
    invert: (pixel: number) => d0 + ((pixel - r0) / rangeSpan) * domainSpan,
  };
}
