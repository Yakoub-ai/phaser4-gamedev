import { describe, expect, it } from 'vitest';
import { addScore, isBetterScore, PICKUP_POINTS } from '../src/logic/score';

describe('score rules', () => {
  it('adds pickup points', () => {
    expect(addScore(0, PICKUP_POINTS)).toBe(10);
  });

  it('rejects negative or non-finite points', () => {
    expect(() => addScore(0, -1)).toThrow(RangeError);
    expect(() => addScore(0, Number.NaN)).toThrow(RangeError);
  });

  it('treats any score as a best when none is stored', () => {
    expect(isBetterScore(0, null)).toBe(true);
    expect(isBetterScore(5, 10)).toBe(false);
  });
});
