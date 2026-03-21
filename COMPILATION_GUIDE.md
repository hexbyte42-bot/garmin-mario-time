# Compilation Guide

## Requirements

- Garmin Connect IQ SDK 8.4.1 or newer
- Java Runtime Environment (JRE)
- A valid Garmin developer key

## SDK Location

The current local SDK installation is:

`~/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-8.4.1-2026-02-03-e9f77eeaa`

## Developer Key

This project requires a valid developer key to produce a signed PRG file.

Current working key path:

`~/.Garmin/ConnectIQ/developer_key/developer_key.der`

### Generating a Developer Key

If you need to generate a new key, use one of the following approaches:

1. Garmin SDK Manager
   Recommended when available.

   ```bash
   ~/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-8.4.1-2026-02-03-e9f77eeaa/bin/sdkmanager
   ```

   Then choose `Generate Developer Key` in the UI.

2. Connect IQ CLI
   This may fail on this machine because of local simulator/CLI library conflicts.

   ```bash
   ~/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-8.4.1-2026-02-03-e9f77eeaa/bin/connectiq keys --create
   ```

## Build Commands

### Recommended

Use the project helper script:

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

## Current Local Status

- SDK is installed and usable
- `manifest.xml` and `monkey.jungle` are valid for the current build target
- `./compile.sh` builds the project successfully in the current environment
- Output file: `bin/MarioTimeColor.prg`

## Quick Start

```bash
./compile.sh
```

## Known Local Issues

1. Some Connect IQ CLI operations may fail because of local `libsoup2` and `libsoup3` conflicts.
2. A valid developer key is still required for any signed build.

## Suggested Recovery Steps

1. Use the installed `./compile.sh` path first.
2. If key generation is needed, prefer Garmin SDK Manager over the CLI on this machine.
3. If the local environment breaks, rebuild in a clean Garmin development environment with the same SDK version.

## Git Hook

This repository may use a pre-commit hook to ensure the project still builds before commit.

Expected hook path:

`.git/hooks/pre-commit`

That hook will only work if the local developer key is configured correctly.
