using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Timer;
using Toybox.Lang;
using Toybox.Activity;
using Toybox.ActivityMonitor;

// Properties for settings
class Properties {
    static const character = 1;
    static const background = 2;
}

class MarioTimeApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {}
    function onStop(state) {}

    function getInitialView() {
        return [new MarioTimeView()];
    }
}

class MarioTimeView extends WatchUi.WatchFace {
    // Assets (Optimized: only load what's needed)
    var charNormal, charJump, blockBmp;
    var bgBmp;
    var timeFont, iconsFont;

    // State
    var marioIsDown = true;
    var animationStartTime = 0;
    var animationDuration = 400;
    var jumpTimer = null;
    var inLowPower = false;
    
    // Cached values
    var screenWidth, screenHeight;
    var lastMinute = -1;
    var is24Hour = true;
    var timeStr = ["", ""]; // Cache for [hour, min] strings
    
    // User Settings
    var selectedCharacter = 0; 
    var selectedBackground = 0;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
        try { timeFont = WatchUi.loadResource(Rez.Fonts.pixel_font); } catch (e) { timeFont = Graphics.FONT_MEDIUM; }
        try { iconsFont = WatchUi.loadResource(Rez.Fonts.IconsFont); } catch (e) { iconsFont = null; }
        loadSettings();
        refreshResources();
    }

    function loadSettings() {
        // Use modern Properties API with fallback for older devices
        if (Application has :Properties) {
            selectedCharacter = Application.Properties.getValue("Character");
            selectedBackground = Application.Properties.getValue("Background");
        } else {
            var app = Application.getApp();
            selectedCharacter = app.getProperty("Character");
            selectedBackground = app.getProperty("Background");
        }
        selectedCharacter = (selectedCharacter != null) ? selectedCharacter : 0;
        selectedBackground = (selectedBackground != null) ? selectedBackground : 0;
        
        is24Hour = System.getDeviceSettings().is24Hour;
    }

    // MEMORY OPTIMIZATION: Only load relevant character and background
    function refreshResources() {
        charNormal = null; charJump = null; bgBmp = null; blockBmp = null;
        
        var charRes = [
            [Rez.Drawables.mario_normal, Rez.Drawables.mario_jump],
            [Rez.Drawables.luigi_normal, Rez.Drawables.luigi_jump],
            [Rez.Drawables.bowser_normal, Rez.Drawables.bowser_jump]
        ];
        var c = (selectedCharacter >= 0 && selectedCharacter < 3) ? selectedCharacter : 0;
        try {
            charNormal = WatchUi.loadResource(charRes[c][0]);
            charJump = WatchUi.loadResource(charRes[c][1]);
            blockBmp = WatchUi.loadResource(Rez.Drawables.block);
        } catch (e) {}

        updateBackgroundResource();
    }

    function updateBackgroundResource() {
        var hour = Gregorian.info(Time.now(), Time.FORMAT_SHORT).hour;
        var res = Rez.Drawables.background_day;
        
        if (selectedBackground == 0) { // Auto
            if (hour >= 22 || hour < 6) { res = Rez.Drawables.background_night; }
            else if (hour >= 12 && hour < 18) { res = Rez.Drawables.background_underground; }
            else if (hour >= 18) { res = Rez.Drawables.background_castle; }
        } else {
            var bgs = [Rez.Drawables.background_day, Rez.Drawables.background_night, 
                       Rez.Drawables.background_underground, Rez.Drawables.background_castle];
            res = bgs[selectedBackground - 1];
        }
        try { bgBmp = WatchUi.loadResource(res); } catch (e) { bgBmp = null; }
    }

    function onHide() {
        stopAnimation();
        WatchFace.onHide();
    }

    function onUpdate(dc) {
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        
        // 1. Minute Change & Logic
        if (now.min != lastMinute) {
            lastMinute = now.min;
            updateTimeStrings(now);
            if (selectedBackground == 0) { updateBackgroundResource(); }
            if (!inLowPower) { startMarioJump(); }
        }
        
        handleSafetyCheck();

        // 2. Rendering (Optimized: single sin calculation)
        if (bgBmp != null) { dc.drawBitmap(0, 0, bgBmp); }
        else { 
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
            dc.fillRectangle(0, 0, screenWidth, screenHeight);
        }
        
        var sinProgress = (marioIsDown) ? 0 : Math.sin(getAnimationProgress() * Math.PI);
        
        drawBlocks(dc, sinProgress);
        drawCharacter(dc, sinProgress);
        drawFitnessMetrics(dc);
    }

    private function updateTimeStrings(now) {
        var h = now.hour;
        if (!is24Hour) { h = (h > 12) ? h - 12 : (h == 0 ? 12 : h); }
        timeStr[0] = h.format("%d");
        timeStr[1] = now.min.format("%02d");
    }

    private function handleSafetyCheck() {
        if (!marioIsDown && animationStartTime > 0) {
            try {
                var elapsed = System.getTimer() - animationStartTime;
                // If animation has been running longer than expected (with 500ms safety margin)
                if (elapsed > animationDuration + 500) {
                    stopAnimation();
                }
            } catch (e) {
                // Fallback: if any error occurs during safety check, force reset
                stopAnimation();
            }
        }
    }

    private function drawBlocks(dc, sinProgress) {
        var blockSize = 100;
        var blockX = (screenWidth - blockSize * 2) / 2;
        var blockY = 80 - (15 * sinProgress).toNumber();

        if (blockBmp != null) {
            dc.drawBitmap(blockX, blockY, blockBmp);
            dc.drawBitmap(blockX + blockSize, blockY, blockBmp);
        }

        // Draw time in blocks using cached strings and custom pixel font
        // Original project uses brown color rgb(117, 58, 0)
        dc.setColor(0x753A00, Graphics.COLOR_TRANSPARENT);
        dc.drawText(blockX + blockSize/2, blockY + 30, timeFont, timeStr[0], Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(blockX + blockSize + blockSize/2, blockY + 30, timeFont, timeStr[1], Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawCharacter(dc, sinProgress) {
        var bmp = marioIsDown ? charNormal : charJump;
        if (bmp != null) {
            var charX = (screenWidth - 120) / 2;
            var charY = 255 - (60 * sinProgress).toNumber();
            dc.drawBitmap(charX, charY, bmp);
        }
    }

    function startMarioJump() {
        if (!marioIsDown || inLowPower) { return; }
        try {
            marioIsDown = false;
            animationStartTime = System.getTimer();
            if (jumpTimer == null) { 
                jumpTimer = new Timer.Timer(); 
            } else {
                // Stop any existing timer to prevent conflicts
                jumpTimer.stop();
            }
            jumpTimer.start(method(:onJumpUpdate), 33, true); // ~30 FPS
            WatchUi.requestUpdate();
        } catch (e) {
            // Log error and ensure state is reset to prevent being stuck
            stopAnimation();
        }
    }

    function stopAnimation() {
        marioIsDown = true;
        animationStartTime = 0;
        if (jumpTimer != null) {
            try {
                jumpTimer.stop();
            } catch (e) {
                // Ignore errors during cleanup
            }
            jumpTimer = null;
        }
        WatchUi.requestUpdate();
    }

    function onJumpUpdate() {
        if (System.getTimer() - animationStartTime >= animationDuration) {
            stopAnimation();
        } else {
            WatchUi.requestUpdate();
        }
    }

    function getAnimationProgress() {
        if (animationStartTime == 0) { return 0.0; }
        var elapsed = System.getTimer() - animationStartTime;
        if (elapsed >= animationDuration) { return 1.0; }
        return elapsed.toFloat() / animationDuration.toFloat();
    }

    // Handle partial updates to ensure smooth animation and proper state transitions
    function onPartialUpdate(dc) {
        if (!marioIsDown) {
            WatchUi.requestUpdate();
        }
    }
    
    // Override to handle settings changes
    function onSettingsChanged() {
        loadSettings();
        refreshResources();
        WatchUi.requestUpdate();
    }
    
    function onEnterSleep() { 
        inLowPower = true; 
        stopAnimation(); 
    }
    
    function onExitSleep() { 
        inLowPower = false; 
        WatchUi.requestUpdate(); 
    }
    
    function drawFitnessMetrics(dc) {
        if (iconsFont == null) { return; }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        // Top: Battery icon
        var batteryLevel = 0;
        var isCharging = false;
        try {
            var stats = System.getSystemStats();
            if (stats != null) {
                batteryLevel = (stats.battery != null) ? stats.battery : 0;
                isCharging = (stats.charging != null) ? stats.charging : false;
            }
        } catch(e) {
            // Ignore errors
        }
        
        var batteryIcon = "m"; // default medium battery
        if (isCharging) {
            batteryIcon = "l"; // charging icon
        } else if (batteryLevel >= 90) {
            batteryIcon = "h"; // high battery
        } else if (batteryLevel < 20) {
            batteryIcon = "k"; // low battery
        }
        
        dc.drawText(screenWidth / 2, 15, iconsFont, batteryIcon, Graphics.TEXT_JUSTIFY_CENTER);

        // Left side: Steps count with icon
        var steps = 0;
        try {
            var activityInfo = ActivityMonitor.getInfo();
            if (activityInfo != null && activityInfo.steps != null) {
                steps = activityInfo.steps;
            }
        } catch(e) {
            // Ignore errors
        }
        
        dc.drawText(35, screenHeight / 2 - 25, iconsFont, "s", Graphics.TEXT_JUSTIFY_LEFT);
        // Prevent step count overflow by limiting to reasonable values
        var stepsDisplay = (steps > 99999) ? "99999" : steps.format("%d");
        dc.drawText(42, screenHeight / 2 + 15, Graphics.FONT_XTINY, stepsDisplay, Graphics.TEXT_JUSTIFY_CENTER);

        // Right side: Heart rate with optimized detection path
        var hrText = "--";
        // PERFORMANCE: Check Activity Info first (faster), then fall back to history
        try {
            if (Activity.Info has :currentHeartRate) {
                var actInfo = Activity.getActivityInfo();
                if (actInfo != null && actInfo.currentHeartRate != null && actInfo.currentHeartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                    hrText = actInfo.currentHeartRate.format("%d");
                }
            }
            
            // Fall back to history if needed
            if (hrText == "--" && ActivityMonitor has :getHeartRateHistory) {
                var hrIter = ActivityMonitor.getHeartRateHistory(new Time.Duration(60), true);
                var sample = hrIter.next();
                if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                    hrText = sample.heartRate.format("%d");
                }
            }
        } catch(e) {
            // Ignore errors, keep hrText as "--"
        }
        
        dc.drawText(screenWidth - 20, screenHeight / 2 - 25, iconsFont, "p", Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(screenWidth - 30, screenHeight / 2 + 15, Graphics.FONT_XTINY, hrText, Graphics.TEXT_JUSTIFY_CENTER);
    }
}