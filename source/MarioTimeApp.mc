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

class MarioTimeApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() { return [new MarioTimeView()]; }
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

    function initialize() { WatchFace.initialize(); }

    function onLayout(dc) {
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
        try { timeFont = WatchUi.loadResource(Rez.Fonts.pixel_font); } catch (e) { timeFont = Graphics.FONT_MEDIUM; }
        try { iconsFont = WatchUi.loadResource(Rez.Fonts.IconsFont); } catch (e) { iconsFont = null; }
        loadSettings();
        refreshResources();
    }

    function loadSettings() {
        var app = Application.getApp();
        if (Application has :Properties) {
            selectedCharacter = Application.Properties.getValue("Character");
            selectedBackground = Application.Properties.getValue("Background");
        } else {
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

    function onHide() { stopAnimation(); }

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
        else { dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK); dc.clear(); }
        
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
            if (System.getTimer() - animationStartTime > animationDuration + 500) { stopAnimation(); }
        }
    }

    private function drawBlocks(dc, sinProgress) {
        var blockX = (screenWidth - 200) / 2;
        var blockY = 80 - (15 * sinProgress).toNumber();
        if (blockBmp != null) {
            dc.drawBitmap(blockX, blockY, blockBmp);
            dc.drawBitmap(blockX + 100, blockY, blockBmp);
        }
        dc.setColor(0x753A00, Graphics.COLOR_TRANSPARENT);
        dc.drawText(blockX + 50, blockY + 30, timeFont, timeStr[0], Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(blockX + 150, blockY + 30, timeFont, timeStr[1], Graphics.TEXT_JUSTIFY_CENTER);
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
            if (jumpTimer == null) { jumpTimer = new Timer.Timer(); }
            jumpTimer.start(method(:onJumpUpdate), 33, true);
            WatchUi.requestUpdate();
        } catch (e) { stopAnimation(); }
    }

    function stopAnimation() {
        marioIsDown = true;
        animationStartTime = 0;
        if (jumpTimer != null) {
            try { jumpTimer.stop(); } catch (e) {}
            jumpTimer = null;
        }
        WatchUi.requestUpdate();
    }

    function onJumpUpdate() {
        if (System.getTimer() - animationStartTime >= animationDuration) { stopAnimation(); }
        else { WatchUi.requestUpdate(); }
    }

    function getAnimationProgress() {
        if (animationStartTime == 0) { return 0.0; }
        var elapsed = System.getTimer() - animationStartTime;
        return (elapsed >= animationDuration) ? 1.0 : elapsed.toFloat() / animationDuration;
    }

    function onEnterSleep() { inLowPower = true; stopAnimation(); }
    function onExitSleep() { inLowPower = false; WatchUi.requestUpdate(); }
    
    function onSettingsChanged() { 
        loadSettings(); 
        refreshResources(); 
        WatchUi.requestUpdate(); 
    }

    function drawFitnessMetrics(dc) {
        if (iconsFont == null) { return; }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        var stats = System.getSystemStats();
        var batIcon = (stats.battery > 90) ? "h" : (stats.battery < 20 ? "k" : "m");
        if (stats.charging) { batIcon = "l"; }
        dc.drawText(screenWidth / 2, 15, iconsFont, batIcon, Graphics.TEXT_JUSTIFY_CENTER);

        var info = ActivityMonitor.getInfo();
        var steps = (info != null && info.steps != null) ? info.steps : 0;
        dc.drawText(35, screenHeight / 2 - 25, iconsFont, "s", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(42, screenHeight / 2 + 15, Graphics.FONT_XTINY, steps.format("%d"), Graphics.TEXT_JUSTIFY_CENTER);

        var hr = "--";
        // PERFORMANCE: Check Activity Info first, it's faster than history
        var actInfo = Activity.getActivityInfo();
        if (actInfo != null && actInfo.currentHeartRate != null) {
            hr = actInfo.currentHeartRate.format("%d");
        } else {
            var hrIter = ActivityMonitor.getHeartRateHistory(1, true);
            var sample = hrIter.next();
            if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                hr = sample.heartRate.format("%d");
            }
        }
        dc.drawText(screenWidth - 20, screenHeight / 2 - 25, iconsFont, "p", Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(screenWidth - 30, screenHeight / 2 + 15, Graphics.FONT_XTINY, hr, Graphics.TEXT_JUSTIFY_CENTER);
    }
}