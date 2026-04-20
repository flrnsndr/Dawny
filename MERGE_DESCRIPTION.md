## Summary

Polishing pass on the Dawny marketing site: manifesto copy and layout, 3 AM reset section, Two Lists section with real screenshots and alignment fixes, contrast block copy, and i18n (EN/DE).

## Changes

### Manifest (`ManifestStatement.astro`, `en.json` / `de.json`)

- Manifest body split into three columns (`bodyMain`, `bodyMid`, `bodyAside`) with vertical dividers on large screens; priority message column first.
- Copy tightened (no em-dash overload in places); English phrasing updates (e.g. conscious decision, priority flag).
- Removed the decorative horizontal highlight bar under the quote.
- Wider content container for the manifest body block where needed.

### 3 AM reset (`ResetAnimation.astro`, i18n)

- Headline layout: lead line (“While you sleep,” / DE equivalent) full width above the diagram; accent line and body in the left column.
- Reset body copy shortened; no em dashes in the EN strings where requested; removed “scoreboard” clause.
- Removed the clock / “03:00 — …” footer line under the body text.

### Two lists (`TwoLists.astro`, `en.json` / `de.json`, assets)

- Three phone screenshots side by side (`backlog`, `today-open`, `today-progress`) under `public/assets/screenshots/`.
- Sun (`SunMark`) anchored to the same content column as the phone grid; symmetric disc variant for this section; grid and column centering tweaks.
- Unified grey styling for the three column kickers (`two-lists-kicker`).
- Copy updates for backlog, daily focus, and “back to backlog” column (including “Not enough time in your day?” headline).
- DE labels and body text kept in sync.

### Sun mark (`SunMark.astro`)

- Optional `sun-mark-two-lists` gradient on the disc for a more centered visual highlight where used.

### Contrast (`ContrastBlock.astro`, i18n)

- Headline replaced with the new EN pair: “Other apps keep you chasing old plans.” / “Dawny gives you a fresh focus for each day.”
- Matching DE headline pair.

## Testing

- `npm run build` in `website/` (recommended before merge).

---

_Use this block as the merge / PR description as-is._
