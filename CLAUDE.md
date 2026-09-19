# York Padel Club App

Web app for the University of York Padel Club (~49 players, upper and lower skill groups, biweekly sessions). Used by the committee (Will, Emma, Maria, Leo) to run sessions and by members to view rankings. Will is the sole developer and relies on Claude for code changes, so explain what you change in plain language.

## Stack

- Single-file frontend: `index.html` at the repo root. Keep it a single file for now (see "Structure" below).
- Database: Supabase (project host `kzqbukjcimuqliwdhpsd.supabase.co`). Tables in use: `players`, `sessions`.
- Hosting: Vercel, auto-deploying from this GitHub repo. Work on a branch and use the Vercel preview link for testing before merging to `main`.
- Must work well on mobile (iOS Safari is the main target). Minimal running costs: stay on free tiers, no paid services without asking.

## Hard rules (learned the hard way)

- The entry file MUST be named `index.html` at the repo root. Any other name gives a 404 on Vercel.
- Supabase RLS policies did not work reliably for anon writes. Permissions currently use explicit grants (e.g. `grant all on players to anon`). Do not switch to RLS without discussing it first and testing it.
- ELO uses a flat K=16 for Americano sessions, with no provisional modifier. (The old Base44 version used K=40 under 10 games; that was deliberately dropped.) K for other formats is not decided yet. Ask before choosing one.
- Americano pairings are generated ONE ROUND AT A TIME, not all upfront, so late arrivals and early departures are handled. Keep this behaviour for every format.
- ELO changes are applied per round, and final ratings are written back to player records when a session is completed.

## Secrets

- Never commit passwords, the Supabase service-role key, or any secret to the repo. The Supabase anon key is public by design; nothing else is.
- The committee password is currently checked client-side, which is weak. Replacing it with Supabase Auth (one shared committee login, public read, authenticated-only writes) is a planned task.

## Current features

Leaderboard, player profiles, session history, live individual Americano runner with ELO. All 49 players are seeded at ELO 1000 for the new year.

## Data model reference

The app was migrated from Base44. Its old schemas are in the Claude project files and are a good starting point for new tables:

- Player: name, gender, elo_rating (default 1000), games_played, matches_played/won, group (upper/lower/unassigned), is_active. Promotion/relegation flags existed (thresholds 1075 / 925) but are not implemented.
- Session: title, date, location, type (training/tournament/inter_uni/social), session_format (normal/doubles_americano/round_robin/inter_uni_tournament), courts, attendees, status, points_to_play.
- Americano: format `pairs` or `individual`, players, rounds (team1, team2, scores), points_to_play (default 24), status.
- Match: match_type (singles/doubles), team players, per-set scores, winner_team, is_ranked, round_number.
- Event / inter-uni: opponent university, our_score vs opponent_score, participants, and per-category (men/women/mixed) pair lineups and match results.
- ExternalPlayer / NonMemberPlayer: players from other universities or non-members, kept separate from club members so they never affect club ELO.

## Implementation notes (current code)

- Page switching is done by toggling a `.active` CSS class on `.page` divs (`showPage()`) — there's no router.
- `calcRoundElo()`: each team's rating is the average of its two partners; the "result" fed into the standard ELO formula is the score ratio (`s1/(s1+s2)`), not a binary win/loss. K=16 per the hard rule above.
- `generateNextRound()`: sitters are whoever has sat out the fewest rounds so far; everyone else is sorted by cumulative points and split top/bottom into courts. It also computes `pairCount` (times two players have partnered) but does not currently use it to avoid repeat pairings — worth flagging if asked to reduce repeat partnerships, since that tracking looks like an unfinished hook rather than an active constraint.
- Session `status` flow: `upcoming` → `in_progress` (once the first round is submitted) → `completed` (via `completeSession()` — the only point ELO changes are actually written to the `players` table). Mid-session, ELO deltas live only in local `sessionEloState` plus `rounds[].elo_changes` on the session row; `loadLiveSession()` replays those on load to reconstruct current ratings after a refresh.
- `SEED_PLAYERS` / `seedAll()` (committee-only) upserts by `id`, so re-running the one-time import overwrites existing player rows rather than duplicating them.

## Roadmap (in order)

1. PWA support (manifest + icons) so it installs from Safari via "Add to Home Screen", plus auth clean-up.
2. Paired Americano / round robin format (pairs stay fixed, individual Americano already exists).
3. Inter-university match play: track individual matches between multiple university teams and roll results up into an overall university score. Scoring rule for the roll-up: TO BE DECIDED, so ask before implementing.
4. Pass check-in: a `pass_type` on attendance (member / single session / unpaid) with a tick box for whoever is on the door. No payment integration.

## Structure

Once paired Americano and inter-uni are added, one file will get unwieldy. Propose moving to a small Vite project (still deploying to Vercel) or splitting into modules before that point, and wait for approval.

## How to work with me

- Start in plan mode: propose the approach and list the files/tables you'll touch before editing.
- One feature per branch. Commit small and often so changes are easy to roll back.
- Put schema changes in versioned `.sql` files in the repo (e.g. `/migrations`) and tell me what to run in the Supabase SQL editor. Do not change the live schema without saying so.
- Keep the UI simple and thumb-friendly. Large tap targets, works on a phone in a sports hall.
- After each feature, give me a short test checklist to run on my phone.
