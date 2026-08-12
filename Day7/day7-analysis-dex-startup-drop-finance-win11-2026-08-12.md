# Analysis: DEX Startup Performance Drop (Finance-Win11)

Date: 2026-08-12
Scope basis used: Finance-Win11 changed at 2026-08-04 02:00; startup time and score degraded immediately after; IT-Win11 had no config change and remained stable.

## Ranked Top 3 Likely Causes (Most Probable First)

### 1) New startup compliance logging script in the Finance-only security baseline

Why this fits the evidence:
- Timing alignment is exact: the profile change was applied at 02:00 on 2026-08-04 and the first post-change day shows startup median jump from 17.5s to 41.3s with score dropping from 84 to 61.
- Scope alignment is clean: only Finance-Win11 received the new profile; IT-Win11 did not and stayed stable.
- Persistence pattern matches: elevated startup times continued on 2026-08-05 and 2026-08-06, consistent with an ongoing startup-path overhead.

Fastest check to confirm or eliminate:
- Temporarily exclude a small Finance test subset from the startup script portion of the profile for one login cycle and compare next-day startup median against matched in-scope Finance devices.

### 2) Additional Defender scan policy introduced in the same Finance-only baseline

Why this fits the evidence:
- It changed at the same timestamp as the observed break and applies only to the affected group.
- A sustained performance impact across multiple days is consistent with an always-on policy effect rather than a one-off event.
- The unaffected group provides a clean control: no policy change, no startup degradation.

Fastest check to confirm or eliminate:
- In a pilot subset, keep baseline controls but disable only the new Defender scan setting, then compare startup median and login-to-usable trace duration to unchanged Finance peers over 24 hours.

### 3) Combined effect of both new baseline elements at startup (script plus scan)

Why this fits the evidence:
- Both controls were introduced together in a single change event at 2026-08-04 02:00, matching the immediate and material metric shift.
- The magnitude (+23.8 seconds median startup) is large enough to plausibly reflect cumulative overhead rather than a minor single-setting variance.
- IT-Win11 remained stable, reinforcing that the Finance-only change package is the strongest explanatory factor.

Fastest check to confirm or eliminate:
- Run a controlled A/B/C comparison inside Finance: Group A with both items, Group B without script, Group C without added scan, and compare median startup next day; the largest recovery path isolates whether single-factor or combined effect dominates.

## Ranking note

This ranking is intentionally weighted to the strongest evidence available: exact change timing and a clean unaffected comparison group with no config change and stable metrics.