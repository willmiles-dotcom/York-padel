import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validateSetScore, matchWinner, calcSetElo } from './scoring.js';

test('valid set scores', () => {
  for (const [a, b] of [[6,0],[6,1],[6,2],[6,3],[6,4],[7,5],[7,6]]) {
    assert.equal(validateSetScore(a, b), true, `${a}-${b} should be valid`);
    assert.equal(validateSetScore(b, a), true, `${b}-${a} should be valid`);
  }
});

test('invalid set scores', () => {
  for (const [a, b] of [[6,5],[7,4],[8,6],[6,6],[5,3],[9,7],[7,7]]) {
    assert.equal(validateSetScore(a, b), false, `${a}-${b} should be invalid`);
  }
});

test('rejects non-integer or negative scores', () => {
  assert.equal(validateSetScore(6.5, 4), false);
  assert.equal(validateSetScore(-6, 4), false);
});

test('matchWinner: straight sets 2-0', () => {
  const sets = [{s1:6,s2:4},{s1:6,s2:3}];
  assert.equal(matchWinner(sets), 't1');
});

test('matchWinner: reverse straight sets 0-2', () => {
  const sets = [{s1:4,s2:6},{s1:3,s2:6}];
  assert.equal(matchWinner(sets), 't2');
});

test('matchWinner: three-setter 6-4 3-6 7-5 -> t1', () => {
  const sets = [{s1:6,s2:4},{s1:3,s2:6},{s1:7,s2:5}];
  assert.equal(matchWinner(sets), 't1');
});

test('matchWinner: undecided after one set', () => {
  const sets = [{s1:6,s2:4}];
  assert.equal(matchWinner(sets), null);
});

test('matchWinner: undecided 1-1', () => {
  const sets = [{s1:6,s2:4},{s1:4,s2:6}];
  assert.equal(matchWinner(sets), null);
});

test('calcSetElo: equal-rated players, 6-0 blowout gives full-weight change', () => {
  const eloState = {a1:1000,a2:1000,b1:1000,b2:1000};
  const changes = calcSetElo(['a1','a2'],['b1','b2'],6,0,eloState,45);
  assert.equal(changes.a1, changes.a2);
  assert.equal(changes.b1, changes.b2);
  assert.ok(changes.a1 > 0);
  assert.ok(changes.b1 < 0);
  // Math.round's asymmetric handling of .5 for negative numbers (a JS
  // quirk already present in the original calcRoundElo) means winner
  // and loser deltas aren't always exact negations - just very close.
  assert.ok(Math.abs(changes.a1 + changes.b1) <= 1);
});

test('calcSetElo with k=45 produces a bigger swing than k=16 for the same score ratio', () => {
  const eloState1 = {a1:1000,a2:1000,b1:1000,b2:1000};
  const eloState2 = {a1:1000,a2:1000,b1:1000,b2:1000};
  const changesHighK = calcSetElo(['a1','a2'],['b1','b2'],6,4,eloState1,45);
  const changesLowK = calcSetElo(['a1','a2'],['b1','b2'],6,4,eloState2,16);
  assert.ok(Math.abs(changesHighK.a1) > Math.abs(changesLowK.a1),
    `expected |${changesHighK.a1}| > |${changesLowK.a1}|`);
});

test('calcSetElo: no games played returns no changes', () => {
  const changes = calcSetElo(['a1','a2'],['b1','b2'],0,0,{},45);
  assert.deepEqual(changes, {});
});
