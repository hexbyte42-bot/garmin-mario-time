# Garmin Mario Time: Comprehensive Development Guide

## Project Overview

This repository ports the Pebble Time `pebble-mario` watchface to Garmin Connect IQ devices, currently targeting the Garmin Forerunner 265 with a 416x416 display.

The implementation is intentionally split between:

- Pebble-faithful behavior where it matters visually and behaviorally
- Garmin-specific utility where it adds practical value, such as watch battery, steps, and heart rate

## Current Status

### Core Features Implemented

- 12/24 hour support
- Minute-based Mario jump animation
- Delayed block bounce with synchronized time movement
- Character selection: Mario, Luigi, Bowser
- April 1 Bowser override
- Automatic and manual background selection
- Watch battery indicator
- Garmin activity metrics: steps and heart rate
- On-device settings menu for character and background

### Known Constraints

- Pebble companion features are not implemented:
  - phone battery
  - weather
  - Bluetooth disconnect icon
  - vibration alerts
- The date row is intentionally removed on FR265 to keep the battery indicator visible

## Development Environment

### SDK

- Path: `/home/buzz-bot/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-8.4.1-2026-02-03-e9f77eeaa`
- Compiler version: 8.4.1
- Build date: 2026-02-03
- Commit: `e9f77eeaa`

### Environment Setup

```bash
export CIQ_SDK_PATH="$HOME/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-8.4.1-2026-02-03-e9f77eeaa"
export PATH="$PATH:$CIQ_SDK_PATH/bin"
```

## Build Workflow

### Recommended

```bash
./compile.sh
```

### Manual Build

```bash
~/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-8.4.1-2026-02-03-e9f77eeaa/bin/monkeyc \
  -f monkey.jungle \
  -d fr265 \
  -o bin/MarioTimeColor.prg \
  -y ~/.Garmin/ConnectIQ/developer_key/developer_key.der \
  -w
```

## Repository Structure

```text
garmin-mario-time/
├── manifest.xml
├── monkey.jungle
├── build.xml
├── resources/
│   ├── resources.xml
│   ├── fonts.xml
│   └── *.png
└── source/
    └── MarioTimeApp.mc
```

## Code Guidelines

- Prefer official Connect IQ APIs and stable watchface lifecycle hooks.
- Do not rely on non-existent callbacks such as `onMinuteChanged()`.
- Keep recurring work cached and update it on minute boundaries rather than during every animation frame.
- Stop timers cleanly when leaving the view or entering sleep.
- Clamp and normalize settings values before indexing any resource arrays.
- Preserve user changes in a dirty worktree unless the task explicitly requires otherwise.

## Behavioral Parity Goals

When changing the watchface, preserve or improve these upstream Pebble traits:

- Mario jumps every minute
- Question blocks bounce after the jump starts
- The time moves with the blocks during the bounce
- Background changes follow the original Pebble schedule
- April 1 forces Bowser

Garmin-specific additions are acceptable if they do not overwhelm the original composition.

## Testing Expectations

- The project must compile cleanly.
- Minute transition behavior must be checked through a full animation cycle.
- Character switching must be validated through both Connect IQ settings and on-device settings.
- Background switching must be checked in both auto and manual modes.
- Battery, steps, and heart rate should degrade gracefully when data is unavailable.

## Pre-Commit Checklist

- Code compiles successfully
- Settings changes still apply correctly
- No timer leak or stuck animation state
- Docs still match the implementation
- No unrelated user changes were reverted

## Troubleshooting

### Build Errors

- `Private key not specified`: configure a valid developer key
- `Symbol not found`: verify resource IDs, imports, and API names
- `Type mismatch`: check Connect IQ API return types carefully
- `Memory limit exceeded`: reduce allocations and avoid repeated resource loads

### Runtime Issues

- Animation gets stuck: verify timer stop/reset logic
- Character or background changes do not apply: verify settings normalization, `onSettingsChanged()`, and string id comparisons in the on-device settings delegate
- Missing resources: verify bitmap IDs and filenames in `resources/resources.xml`
- Missing heart rate: fall back cleanly when current or historical HR data is unavailable

## Next Recommended Work

1. Real-device validation on FR265 hardware
2. Add a lightweight validation script for build plus doc consistency checks
3. Revisit selected Pebble companion features if parity becomes a higher priority
4. Keep README and backlog docs synchronized with actual behavior

## References

- Upstream Pebble project: <https://github.com/ClusterM/pebble-mario>
- Garmin Connect IQ docs: <https://developer.garmin.com/connect-iq/>
- `ttf2bmp`: <https://github.com/wkusnierczyk/ttf2bmp>

---

Last updated: 2026-03-23
