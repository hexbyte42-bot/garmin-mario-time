# Issue-Based Task Backlog

## 1) Typo fix task
**Task:** Fix the stale project-name typo in `README.md` where the tree root is shown as `garmin-mario-time-color/` instead of the current repository name `garmin-mario-time/`.

**Why this matters:** New contributors can copy commands/paths from the README and fail because the documented root folder name does not match the real repo name.

**Acceptance criteria:**
- The README project tree uses `garmin-mario-time/` consistently.
- Any other occurrences of `garmin-mario-time-color` are reviewed and corrected if they refer to this repo.

---

## 2) Bug fix task
**Task:** Guard `selectedBackground` before indexing `BG_RES` in `updateBackgroundResource()`.

**Observed issue:** The code directly indexes `BG_RES[selectedBackground - 1]` for manual mode. If settings are corrupted or out-of-range (e.g., `selectedBackground = 99`), this can cause an invalid index access.

**Acceptance criteria:**
- `selectedBackground` is clamped/validated to valid values before use.
- Out-of-range values safely fall back to auto mode or day background.
- Manual setting changes still work for all supported background options.

---

## 3) Code comment / documentation discrepancy task
**Task:** Align README feature list with implemented behavior for date and April Fools logic.

**Observed discrepancy:** README says date display and an April Fools Bowser surprise are implemented, but `source/MarioTimeApp.mc` currently renders time + metrics and does not include date rendering or April-1 character override logic.

**Acceptance criteria:**
- Either implement the missing features, or update README to accurately describe current behavior.
- Add a short "Implemented vs Planned" section to prevent future drift.

---

## 4) Test improvement task
**Task:** Add a lightweight, repeatable validation script that runs static checks for settings bounds and documentation consistency.

**Current gap:** The repo has no dedicated automated tests; regressions in settings handling and README drift are likely.

**Suggested scope:**
- Add a script (e.g., `scripts/checks.sh`) that:
  - runs syntax/build validation (when SDK is available),
  - checks documented feature flags against code markers,
  - verifies setting ranges used for character/background selectors.
- Wire the script into CI (or pre-commit) with clear pass/fail output.

**Acceptance criteria:**
- Single command to run checks locally.
- Fails on out-of-range selector logic and obvious docs/feature mismatches.
- Documented in `README.md` under a "Validation" section.

# Code Review Notes

Date: 2026-03-06
Scope: Current `master` codebase review with focus on correctness and maintainability.

## Summary
The watchface is functional and readable, but there are a few correctness and documentation issues worth addressing first.

## Key findings

1. **Potential background index bug**
   - In `updateBackgroundResource()`, manual mode uses `BG_RES[selectedBackground - 1]` directly.
   - If `selectedBackground` is out of bounds (for example from corrupted settings), this can select an invalid index.
   - Recommendation: validate/clamp the setting before indexing and fall back to auto/day when invalid.

2. **README and implementation are out of sync**
   - README currently advertises date display and April Fools behavior.
   - The current implementation renders time blocks, character animation, battery/steps/heart rate only.
   - Recommendation: either implement the advertised behavior or update README to match what exists today.

3. **Stale project name in docs**
   - README project tree uses `garmin-mario-time-color/`, but the repository is `garmin-mario-time/`.
   - Recommendation: update naming for onboarding clarity.

4. **Testing/validation gap**
   - There is no single command that checks code + documentation consistency.
   - Recommendation: add a lightweight validation script (syntax/build when SDK exists, plus simple consistency checks).

## Suggested priority
1. Fix `selectedBackground` bounds handling (runtime safety).
2. Reconcile README claims with actual behavior.
3. Correct stale naming in docs.
4. Add lightweight checks script and document it.

## Definition of done for this review
- Findings are now persisted in-repo for follow-up implementation planning.

