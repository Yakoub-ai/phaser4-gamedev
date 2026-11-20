// Pure game rules live in plain modules like this one: no Phaser import, so they are
// unit-tested with Vitest in milliseconds. Scenes call into them.

export const PICKUP_POINTS = 10;
export const ROUND_SECONDS = 30;

export function addScore(score: number, points: number): number {
  if (!Number.isFinite(points) || points < 0) throw new RangeError(`invalid points: ${points}`);
  return score + points;
}

export function isBetterScore(score: number, best: number | null): boolean {
  return best === null || score > best;
}
