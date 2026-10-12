export interface GaugeArc {
  radius: number;
  circumference: number;
  dashOffset: number;
  fraction: number;
}

export function buildGaugeArc(score: number, radius: number): GaugeArc {
  const fraction = Math.min(Math.max(score, 0), 100) / 100;
  const circumference = 2 * Math.PI * radius;
  return { radius, circumference, dashOffset: circumference * (1 - fraction), fraction };
}
