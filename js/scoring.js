// Pure padel match-scoring functions - no DOM/Supabase dependency, so
// they're directly testable with `node --test js/scoring.test.js`.

export function validateSetScore(a, b) {
  if (!Number.isInteger(a) || !Number.isInteger(b) || a < 0 || b < 0) return false;
  if (a === b) return false;
  const hi = Math.max(a, b), lo = Math.min(a, b);
  if (hi === 6 && lo <= 4) return true;
  if (hi === 7 && (lo === 5 || lo === 6)) return true;
  return false;
}

// sets: array of {s1,s2} (1-3 entries). Returns 't1', 't2', or null if undecided.
export function matchWinner(sets) {
  let w1 = 0, w2 = 0;
  for (const s of sets) {
    if (s.s1 > s.s2) w1++; else if (s.s2 > s.s1) w2++;
  }
  if (w1 >= 2) return 't1';
  if (w2 >= 2) return 't2';
  return null;
}

function expectedScore(ra, rb) { return 1 / (1 + Math.pow(10, (rb - ra) / 400)); }

// Same proportional-score ELO formula as index.html's calcRoundElo, but
// takes k as a parameter (Match Play uses a much higher k than Americano).
export function calcSetElo(t1ids, t2ids, gamesA, gamesB, eloState, k) {
  const total = gamesA + gamesB;
  if (total === 0) return {};
  const score1 = gamesA / total, score2 = gamesB / total;
  const avgR1 = t1ids.reduce((a, id) => a + (eloState[id] || 1000), 0) / t1ids.length;
  const avgR2 = t2ids.reduce((a, id) => a + (eloState[id] || 1000), 0) / t2ids.length;
  const exp1 = expectedScore(avgR1, avgR2);
  const exp2 = expectedScore(avgR2, avgR1);
  const changes = {};
  t1ids.forEach(id => { changes[id] = Math.round(k * (score1 - exp1)); });
  t2ids.forEach(id => { changes[id] = Math.round(k * (score2 - exp2)); });
  return changes;
}
