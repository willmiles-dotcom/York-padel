# Feature Brief: York Padel App v2

**Instructions for Claude Code:** Read `CLAUDE.md` first. Work in plan mode. Before writing any code, give me a plan that lists the tables and files you will change, the order you will build things in, and anything in this brief that is unclear or conflicts with the existing app. Then wait for my approval. Also update roadmap item 3 in `CLAUDE.md` with the scoring rules below, and add the "Editing and knock-on effects" section to `CLAUDE.md` as a hard rule.

## Goal

An easy-to-use, mobile-first, password-gated website (installable on iOS via Add to Home Screen) for tracking padel sessions in three formats, at minimal running cost (Vercel and Supabase free tiers only).

## The three formats

1. **Individual Americano** (already built): rotating partners, points per round, ELO per round, K=16.
2. **Paired Americano / round robin** (new): players are in fixed pairs for the whole session. Each round, pairs are matched against each other, and the standings are per pair. Pairings are still generated one round at a time so late arrivals and early departures are handled. Pairs can be formed by the committee or auto-balanced by ELO.
3. **Match play** (new): individual matches scored in sets, used for inter-university fixtures and also for ordinary friendlies.

## Match scoring (all match play)

Each match has a format chosen when it is created:
- **1 set**
- **Best of 3 sets** (this covers the "2 sets or 3 sets" case: the match ends after 2 sets if one side wins both, and a third set is played if it's 1-1). *Assumption: check this matches how you play.*
- Option: play the deciding third set as a match tie-break (first to 10, win by 2) instead of a full set. Default off. *Assumption: setting exists but defaults off.*

Entering scores:
- The user enters each set score (e.g. `6-4`, `7-6`). The app calculates the winner automatically. Nobody picks the winner by hand.
- Standard padel set rules: a set is won at 6 games with a 2-game lead (6-0 to 6-4), or 7-5, or 7-6 after a tie-break at 6-6 (first to 7 points, win by 2). Point-level rules (golden point at deuce) don't matter to the app, since we only record set scores.
- Valid completed set scores (either way round): 6-0, 6-1, 6-2, 6-3, 6-4, 7-5, 7-6. Reject anything else (6-5, 7-4, 8-6, etc.) with a clear message explaining why. Allow entering the tie-break score optionally (e.g. `7-6 (7-3)`) but it is not required.
- Winner = most sets won. The match completes automatically once the format's condition is met (1 set won; 2 sets won in best of 3). Third-set fields only appear when it's 1-1.
- Live entry: sets can be entered as they finish, with a running match status ("Team A leads 1-0").
- Build the score validation and winner logic as a small pure function with tests, since the whole inter-uni result depends on it. Test cases should include 6-4 7-6, 6-4 3-6 7-5, 7-6 6-7 6-3, and invalid scores.

## Inter-university match play

- Support **multiple universities** in one event (more than two), not just York vs one opponent.
- Each university has a team of players. Categories: **men, women, mixed**. Each category has one or more pairs per university.
- Fixtures: for each pair of universities, pairs play matches in each category. Each match is entered as above.
- **Overall scoring: each match won earns its university 1 point.** The university with the most match wins is top. Since tie-breaking is decided inside the matches, tied overall totals are shown as tied, with no extra tie-break rules. *Assumption: 1 point per match win. Tell me if it should be different, e.g. weighted by category.*
- Show a live **university standings table** (matches won/lost per university) and a per-fixture breakdown (which pair beat which, with set scores) that updates as each match is entered.
- Opposing players are external players (name, university, gender), stored separately from club members so they never affect club ELO. Their names can be added on the fly at match entry.
- *Assumption: inter-uni matches do NOT affect club ELO by default, with an `is_ranked` toggle per event so the committee can turn it on.*

## Passes / membership (light touch)

- Add a `pass_type` per attendee per session (member / single session / unpaid) and a check-in tick box for whoever is on the door. No payment integration.
- A simple session-day view showing who has checked in and who hasn't paid.

## Editing and knock-on effects (applies to the whole app)

Everything should be **easy to edit** (fix a typo'd score, change a pairing, correct an attendee, rename a player) **without silently breaking other data**. Knock-on effects to design for:

- **Editing a completed score** (Americano round or match) changes ELO for everyone involved, and because ELO is sequential, it also changes every later match those players have played. It changes their games played, wins, the session's final ratings, the leaderboard, and for inter-uni matches the university standings.
- **Changing attendees or pairs** after rounds have been played affects those rounds' results and ELO.
- **Deleting a player, session, match or university** would leave other records pointing at nothing.

Required behaviour:
1. **Make ELO recomputable.** Store ELO changes per match/round, and provide a function that replays all ranked matches in chronological order from 1000 to rebuild ratings deterministically. Use it to preview and apply edits. Wherever there is a K-factor, it must come from one shared place. (K=16 for Americano; other formats are undecided, so ask me before picking one.)
2. **Warn before saving.** When an edit has knock-on effects, show a confirmation that states the impact in numbers, e.g. "Changing this score will alter ratings for 4 players and 7 later matches. Sam 1032 → 1025, Priya 984 → 991 ..." with a clear Confirm and Cancel. Purely cosmetic edits (typos in a name, a location) save immediately with no warning.
3. **Soft delete.** Never hard-delete players, sessions or matches. Archive them instead, and warn about what references them.
4. **Audit log.** Record who changed what, when, and the old and new values, so mistakes can be traced and undone. Show a simple "recent changes" view for the committee.
5. **Undo** the last edit where feasible.
6. Editing must be committee-only. Members are read-only.

## Access and security

- Public read for the leaderboard; committee login required for any write.
- Replace the client-side committee password with Supabase Auth (one shared committee login is fine). Propose how to do this given that RLS previously misbehaved. Test it properly on a Vercel preview before switching, and do not lock the committee out.
- No secrets in the repo.

## Build order

1. PWA (manifest, icons, iOS home-screen behaviour) and the auth clean-up.
2. Score validation/winner function with tests, ELO replay function, audit log, and edit-with-warnings foundations. These support everything else.
3. Paired Americano / round robin.
4. Match play with 1-set and best-of-3 entry.
5. Inter-university events, teams, and standings.
6. Pass check-in.

Propose a file structure change (e.g. Vite) before the single `index.html` becomes unmanageable, and wait for approval.

## Test checklist (give me one after each feature, to run on my phone)

- Enter each valid set score and confirm the winner is right, including 7-6 and 6-7 6-3.
- Try invalid scores and confirm they are rejected with a clear message.
- Edit an old score and confirm the warning lists the correct impact before anything changes.
- Confirm a member (not logged in) can view but not edit.
- Confirm the app installs from Safari and opens full-screen.
