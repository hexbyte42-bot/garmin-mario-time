# Mario Time for Garmin (Color Version)

A port of the popular Pebble Mario watchface to Garmin Connect IQ devices, specifically designed for the Garmin Forerunner 265.

## 🎮 Features

- **Mario jumps when screen wakes up** (if more than 1 minute has passed since last view)
- **Question blocks bounce** when Mario jumps
- **Custom pixel fonts** for time and date display
- **Date display** (Day, Month, Date)
- **Watch battery indicator only** (simplified as requested)
- **Character selection** (Mario, Luigi, Bowser)
- **Auto background** that changes with time of day
- **April Fools surprise** (Bowser appears on April 1st!)
- **Low power mode optimization** - animations disabled during sleep mode
- **Stuck animation fix** - prevents Mario from getting stuck in jump state

## 🎨 Color Resources

This version uses **color resources specifically created for Pebble Time** (the color version of Pebble), which provides:

- **Rich color backgrounds** (Day, Night, Underground, Castle themes)
- **Color character sprites** (Mario, Luigi, Bowser in full color)
- **Color UI elements** (blocks, battery icons with proper colors)
- **Optimized for color displays** like the Garmin Forerunner 265

All graphics have been copied directly from the original Pebble Mario repository's color assets.

## 📦 Project Structure

```
garmin-mario-time-color/
├── README.md
├── manifest.xml
├── build.xml
├── font_generator.py          ← Font generation script (TTF → FNT/PNG)
├── scale_images.py           ← Image scaling script (Pebble → Garmin)
├── resources/
│   ├── mario_normal.png        ← Color version from Pebble Time
│   ├── mario_jump.png          ← Color version from Pebble Time
│   ├── luigi_normal.png        ← Color version from Pebble Time
│   ├── luigi_jump.png          ← Color version from Pebble Time
│   ├── bowser_normal.png       ← Color version from Pebble Time
│   ├── bowser_jump.png         ← Color version from Pebble Time
│   ├── background_day.png      ← Color basalt version (Pebble Time)
│   ├── background_night.png    ← Color basalt version (Pebble Time)
│   ├── background_underground.png ← Color basalt version (Pebble Time)
│   ├── background_castle.png   ← Color basalt version (Pebble Time)
│   ├── block.png              ← Color version from Pebble Time
│   ├── launcher_icon.png      ← App icon
│   ├── Gamegirl.ttf           ← Source TTF font for custom pixel font
│   ├── emulogic.ttf           ← Alternative source TTF font
│   ├── Gamegirl~color.ttf     ← Color variant TTF font
│   ├── pixel_font.fnt         ← Generated Garmin font (time display)
│   ├── pixel_font.png         ← Generated font atlas
│   ├── icons-43px.fnt         ← Generated Garmin font (fitness icons)
│   └── icons-43px_0.png       ← Generated icon atlas
└── source/
    └── MarioTimeApp.mc        # Main source code
```

## 🔧 Development Scripts

### Font Generation (`font_generator.py`)
Generates Garmin-compatible FNT + PNG font files from TTF sources:
```bash
python3 font_generator.py Gamegirl.ttf pixel_font 48
```

### Image Scaling (`scale_images.py`)
Scales Pebble-sized assets (144x168) to Garmin FR265 size (416x416):
```bash
python3 scale_images.py
```

These scripts are essential for maintaining and updating the visual assets.

## 🔧 Setup Instructions

1. **Clone this repository**
2. **Install Garmin Connect IQ SDK** on your machine
3. **Set environment variable**: `export CONNECTIQ_SDK=/path/to/sdk`
4. **Build the watchface**: `ant build`
5. **Install to your watch**: `ant install`

## 💡 Power Consumption Notes

The current implementation is **power-optimized**:
- Animations only trigger when user views the watchface (not every minute in background)
- Sleep mode completely disables animations
- Fixed stuck animation bug that could cause unnecessary battery drain
- Low power mode detection prevents animations during battery saving

This approach is **more efficient** than traditional minute-based triggers.

## 📥 Resources Source

All graphics and font files have been **copied directly from the original Pebble Mario watchface repository**:
- https://github.com/ClusterM/pebble-mario

Specifically using the **color assets** created for **Pebble Time** (basalt platform) to ensure the best visual experience on your color Garmin Forerunner 265!

Enjoy your Mario Time watchface! 🍄