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
- Date row
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

### Pebble parity improvements

Implemented:
- Date row restored
- Pebble-style auto background schedule restored
- April 1 Bowser behavior restored
- Time slide and delayed block bounce restored

## Removed or Deferred Features

### Device-side menu

Status:
- Deferred

Reason:
- Previous device-side settings work was unstable

Current approach:
- Use Connect IQ settings instead

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

## Next Work Items

1. Validate the current build on a real FR265
2. Add a lightweight validation script for build and doc consistency
3. Decide whether to reintroduce selected companion-style features in a Garmin-native way
4. Continue battery profiling on-device

## References

- Pebble original: <https://github.com/ClusterM/pebble-mario>
- Garmin custom font reference: <https://developer.garmin.com/connect-iq/connect-iq-faq/how-do-i-use-custom-fonts/>
- Example font-based watchface: <https://github.com/wkusnierczyk/garmin-fancyfont-time>
- `ttf2bmp`: <https://github.com/wkusnierczyk/ttf2bmp>
