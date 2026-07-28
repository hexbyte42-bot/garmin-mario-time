# Garmin Mario Time Development Log

## Project Summary

This project ports the Pebble Time Mario watchface to the Garmin Forerunner 265.

## Current Snapshot

### Completed Foundation Work

1. Project structure
- `manifest.xml`, `resources.xml`, and `source/` created
- Target device set to FR265
- Connect IQ SDK baseline configured

2. Visual resources
- Backgrounds scaled to 416x416
- Character sprites scaled for the Garmin display
- Block art integrated
- Luigi and Bowser variants added

3. Typography
- Pixel font generated from `Gamegirl.ttf`
- Font resources configured in `resources/fonts.xml`
- Time text centered inside the two blocks

4. Core watchface behavior
- 12/24 hour display support
- Two-block time layout
- Minute jump animation
- Automatic and manual backgrounds
- Character switching
- April 1 Bowser override

5. Garmin-specific metrics
- Watch battery indicator
- Steps display
- Heart-rate display
- Sensor reads cached on minute boundaries instead of per animation frame

## Notable Fixes

### Mario jump animation

Problem:
- The jump could get stuck or fail to complete correctly

Root causes:
- Incorrect reliance on non-standard callback assumptions
- Timer and animation state issues

Fix:
- Trigger minute changes from `onUpdate()`
- Manage timer lifecycle explicitly
- Reset state cleanly when the animation ends or the watchface sleeps

Result:
- Mario completes the jump and returns to the resting state correctly

### Character selection

Problem:
- Character switching could fail on device because settings values were not normalized safely

Fix:
- Normalize settings values before indexing sprite arrays
- Clamp out-of-range values
- Refresh resources on settings changes

Result:
- Character switching is stable on-device for valid settings values

### On-device settings

Problem:
- Sideloaded builds could not be configured from Garmin Connect
- Early watch-side settings attempts rendered but did not react to selection on the device

Root cause:
- The watch face used `getSettingsView()`, but the menu delegate compared string ids with `==`
- In practice, the settings rows appeared on-device but the branch logic did not fire reliably

Fix:
- Keep the `getSettingsView()` + `Menu2` approach
- Refactor the settings flow to match the working Protomolecule watch face pattern
- Compare menu ids with `.equals(...)` instead of `==`

Result:
- On-device settings now work on FR265 hardware
- Character and background can be changed directly from the watch face settings menu

### Pebble parity improvements

Implemented:
- Date row restored
- Pebble-style auto background schedule restored
- April 1 Bowser behavior restored
- Time slide and delayed block bounce restored

## Removed or Deferred Features

### Pebble companion features

Not currently implemented:
- weather
- phone battery
- Bluetooth disconnect icon
- vibration alerts

## Technical Notes

### Display Scaling

- FR265: 416x416
- Original Pebble: 144x168
- The Garmin port is visually adapted rather than pixel-perfect

### Font Generation

Example command:

```bash
ttf2bmp -f "Gamegirl.ttf" -s "48" -c "0123456789" -o resources/
```

### Repository Layout

```text
garmin-mario-time/
├── manifest.xml
├── monkey.jungle
├── resources/
│   ├── resources.xml
│   ├── fonts.xml
│   ├── Gamegirl-48.fnt
│   ├── Gamegirl-48.png
│   ├── background_*.png
│   ├── mario_*.png
│   ├── luigi_*.png
│   ├── bowser_*.png
│   └── block.png
└── source/
    └── MarioTimeApp.mc
```

## Working Practices

### Main branch expectations

- Keep `master` releasable
- Compile before committing
- Avoid landing unstable features directly

### Feature work

- Prefer isolated changes with build verification
- Reconcile docs with implementation as part of the same change
- Favor stable Garmin lifecycle behavior over speculative shortcuts

## 2025-07-24: Top bar HUD refactor (battery + date)

### Changes

- **Battery moved** from top-center to top-left, aligned with hour block center
- **Date added** at top-right, format `EEE DD` (e.g. `THU 24`), `FONT_XTINY` white
- **Circular screen awareness**: positions computed via `dx²+dy² < (radius-margin)²`
- **Font baseline alignment**: battery (iconsFont, bitmap, y=top) and date (FONT_XTINY, system, y=baseline) use different y coordinates to share same visual center
- **Date format fixed length** (7 chars: EEE+SPACE+DD) via manual English lookup arrays, locale-independent

### Key Constants

| Parameter | Value |
|-----------|-------|
| batteryTop (y) | 24 (top of 43px icon) |
| iconCenterY (y) | 45 (VCENTER for date) |
| battery x | hour block center (cX-50, center-justified) |
| date x | `cX+maxDx-10` (right-justified, 10px left shift for balance) |
| battery-date gap | ~13px to time blocks at y=80 |
| circular margin | 15px from visible circle edge |

### Branch & Merge

- Branch: `feat/top-bar-battery-date` (10 commits)
- Merged to master as `72bd3b9`
- Stale branches deleted: `cleanup/resource-optimization`, `fix/mario-jump-stuck`, `fix/mario-jump-stuck-gemini`, `test/april-fools-bowser-fix`, `test/watchface-settings-callback`

## Next Work Items

1. Add a lightweight validation script for build and doc consistency
2. Decide whether to reintroduce selected companion-style features in a Garmin-native way
3. Continue battery profiling on-device

## References

- Pebble original: <https://github.com/ClusterM/pebble-mario>
- Garmin custom font reference: <https://developer.garmin.com/connect-iq/connect-iq-faq/how-do-i-use-custom-fonts/>
- Example font-based watchface: <https://github.com/wkusnierczyk/garmin-fancyfont-time>
- `ttf2bmp`: <https://github.com/wkusnierczyk/ttf2bmp>
