# Design Brief: York Padel App visual redesign

**Instructions for Claude Code:** Read `CLAUDE.md` first. This is a visual redesign only. Do not change functionality, data logic, ELO, scoring, or permissions. Work in plan mode and follow the process at the bottom of this brief: a written design plan first, which I approve, then build in stages.

## The problem

The app currently uses black and muted gold and is meant to be glassmorphism, but it looks flat and low budget. The likely cause: frosted glass only looks premium when there is something rich behind it to blur. Over flat black there is nothing to refract, so panels read as grey boxes. The fix is a proper backdrop and a disciplined glass system, not more effects.

## Direction (fixed)

**Proper glassmorphism with a rich backdrop behind frosted panels, built on real photos of the club.** I will add photos to `assets/photos/`. Look at them yourself and let them drive the design: pull colour from them, and decide which photo suits which screen.

## Who and what this is for

The University of York Padel Club. Members (students) open it on their iPhones, often in a sports hall: checking rankings, watching a live session, entering scores with sweaty thumbs. It should feel like a confident, modern sports club, not a generic dashboard. It runs as an installed home-screen web app (PWA) on iOS Safari.

## Priority screens (spend the effort here)

1. **Home / dashboard** should feel like the club's front door. It needs the most striking use of photography, plus the most useful at-a-glance info (next session, top of the leaderboard, latest results).
2. **Live scoring** (Americano and match play). Legibility and speed beat decoration. Huge score numerals, big thumb-friendly tap targets, a calmer and darker backdrop so glare and blur never hurt readability, and clear feedback when a point or set is recorded.
3. **Leaderboard** should be beautiful and scannable. Rank, name and rating must be instantly readable, with a distinct treatment for the top three that is elegant rather than gimmicky.

Then apply the same system to every remaining screen (profiles, session history, inter-uni standings, admin/edit screens) so nothing looks left behind.

## Glass craft (this is where "cheap" comes from, so be deliberate)

- **Backdrop:** a fixed full-screen layer behind the UI made from club photos, darkened with a gradient overlay so text always passes contrast. Consider subtly different treatments per screen (a vivid hero on Home, a calmer dim one on Live scoring). If a photo is too plain, add soft colour light (blurred colour fields sampled from the photo) behind the glass.
- **Glass tiers by hierarchy, not one style for everything.** For example: a light, subtle tier for large containers, a brighter, stronger tier for the key card on a screen, and an opaque-enough tier for controls and small text where legibility matters. Vary radius and elevation with purpose, and do not put identical rounded cards everywhere.
- **Realism details:** `backdrop-filter` blur with a saturation boost, a thin 1px border with a light top-left highlight fading to near-transparent, a soft inner highlight, and a very light grain or noise to avoid a plastic look. Use shadows sparingly.
- **Safari:** include `-webkit-backdrop-filter`, and provide a solid, well-styled fallback for when blur is unavailable.
- **Performance:** many stacked blurred layers stutter on phones. Limit the number of simultaneous backdrop-filter elements, avoid animating blurred layers, and test scrolling on a real iPhone via the Vercel preview.

## Colour

Start from the current black and muted gold as a reference, but do not treat it as sacred. Propose a palette of 4 to 6 named hex values drawn from the photos, with one clear accent. Keep it restrained: one memorable colour moment, and everything else quiet. Ensure text on glass meets accessible contrast, including small text on the busiest part of a photo.

## Typography

Choose one or two typefaces deliberately for a modern sports-club feel, and avoid reaching for the usual defaults. Define a clear type scale and weights. Give scores, ratings and ranks strong numerals, ideally tabular figures so digits align in tables. Avoid these generic tells: tracked-out ALL CAPS eyebrow labels above headings, a single word in a headline accented in a different colour, spaced em-dash labels, "→" on every button, and middle-dot meta strings.

## Photos (technical)

- Compress and resize: serve WebP (or AVIF) at sensible sizes, with each photo ideally under about 300 KB. Tell me if any of mine are too large or low quality, and which ones you plan to use where.
- Use responsive images where it helps, lazy-load anything below the fold, and keep the first screen fast.
- Give every meaningful image proper alt text, or mark decorative ones as decorative.
- If there are not enough good photos for a particular screen, say so and propose a fallback (e.g. a tinted crop, or a coloured gradient built from the photos' palette) rather than stretching a bad image.

## Motion

Use it sparingly and only where it helps: one orchestrated entrance on Home, and feedback that answers a tap (score recorded, set won, saved). No fade-and-slide on every section, and no hover effects on every card. Respect `prefers-reduced-motion`.

## Mobile and PWA quality floor

Design for a 390px-wide iPhone first, then tablet and desktop. Respect safe areas (notch and home indicator). Tap targets at least 44px. Visible focus states. Nothing may overflow horizontally. Make sure it looks right when launched from the home screen in standalone mode, including the status bar style.

## Copy

Sentence case, plain verbs, active voice. Buttons say exactly what happens ("Save changes", not "Submit"). Empty states should tell the user what to do next. Errors should say what went wrong and how to fix it, without apologising.

## Process

1. **Plan first (no code yet):** look at the current app and the photos. Give me a compact design plan with: the colour tokens (4 to 6 named hex values), the typefaces and their roles, the glass tier definitions, a layout concept for Home, Live scoring and Leaderboard using short prose and ASCII wireframes, and which photo you'd use where. Then review your own plan against this brief: if any part reads like the generic default you'd produce for any sports app, revise it and tell me what you changed and why. Wait for my approval.
2. **Build in stages, one branch per stage, previewed on Vercel:**
   1. Design tokens as CSS variables, the backdrop system, glass components and type. Nothing else yet.
   2. Home
   3. Live scoring
   4. Leaderboard
   5. Everything else
3. **After each stage:** if you can run a browser or take screenshots, review at 390px wide and fix what looks off before showing me. Then give me a short list of things to check on my iPhone.
4. **Rules:** keep all colours, radii, blur values and spacing as CSS variables so I can tweak the look in one place. Do not touch scoring, ELO, auth or database code. If a design change would require one of those, stop and ask.
