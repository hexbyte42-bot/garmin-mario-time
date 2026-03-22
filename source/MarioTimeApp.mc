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
using Toybox.Math;

class MarioTimeApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() { return [new MarioTimeView()]; }
}

class MarioTimeView extends WatchUi.WatchFace {
    static const CHARACTER_COUNT = 3;
    static const BACKGROUND_COUNT = 4;
    static const JUMP_FRAME_INTERVAL_MS = 67;
    static const APRIL_FOOLS_MONTH = 4;
    static const APRIL_FOOLS_DAY = 1;
    static const TIME_SLIDE_DISTANCE = 62;
    static const BLOCK_ANIMATION_DELAY = 0.44;
    static const BOWSER_Y_OFFSET = 10;

    // Resource Constants to avoid runtime allocations
    static const CHAR_RES = [
        [Rez.Drawables.mario_normal, Rez.Drawables.mario_jump],
        [Rez.Drawables.luigi_normal, Rez.Drawables.luigi_jump],
        [Rez.Drawables.bowser_normal, Rez.Drawables.bowser_jump]
    ];
    static const BG_RES = [
        Rez.Drawables.background_day, Rez.Drawables.background_night, 
        Rez.Drawables.background_underground, Rez.Drawables.background_castle
    ];

    // Assets
    var charNormal, charJump, blockBmp, bgBmp;
    var timeFont, iconsFont;

    // State & Animation
    var marioIsDown = true;
    var inLowPower = false;
    var animationStartTime = 0;
    var animationDuration = 400;
    var jumpTimer = null;
    var minuteCheckTimer = null;
    
    // Cached values (UI Performance)
    var screenWidth, screenHeight;
    var lastMinute = -1;
    var is24Hour = true;
    var suppressNextMinuteJump = false;
    var timeStr as Lang.Array<Lang.String> = ["", ""] as Lang.Array<Lang.String>;
    var batLevel = 0;
    var isCharging = false;
    var steps = 0;
    var heartRate = "--";

    // User Settings
    var selectedCharacter = 0, selectedBackground = 0;
    var activeBackgroundIndex = -1;
    var activeCharacterIndex = -1;

    function initialize() { WatchFace.initialize(); }

    function onLayout(dc) {
        var now = Gregorian.info(Time.now(), Time.FORMAT_LONG);
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
        try { timeFont = WatchUi.loadResource(Rez.Fonts.pixel_font); } catch (e) { timeFont = Graphics.FONT_MEDIUM; }
        try { iconsFont = WatchUi.loadResource(Rez.Fonts.IconsFont); } catch (e) { iconsFont = null; }
        loadSettings();
        updateTimeStrings(now, false);
        lastMinute = now.min;
        refreshResources();
        updateSystemStats();
        startMinuteChecker();
    }

    function loadSettings() {
        try {
            selectedCharacter = Application.Properties.getValue("character");
            selectedBackground = Application.Properties.getValue("background");
        } catch (e) {
            selectedCharacter = 0;
            selectedBackground = 0;
        }
        selectedCharacter = normalizeSettingValue(selectedCharacter, 0, CHARACTER_COUNT - 1, 0);
        selectedBackground = normalizeSettingValue(selectedBackground, 0, BACKGROUND_COUNT, 0);
        is24Hour = System.getDeviceSettings().is24Hour;
    }

    function refreshResources() {
        var c = getEffectiveCharacterIndex(Gregorian.info(Time.now(), Time.FORMAT_LONG));
        activeCharacterIndex = c;
        try {
            charNormal = WatchUi.loadResource(CHAR_RES[c][0]);
            charJump = WatchUi.loadResource(CHAR_RES[c][1]);
            blockBmp = WatchUi.loadResource(Rez.Drawables.block);
        } catch (e) {}
        updateBackgroundResource(Gregorian.info(Time.now(), Time.FORMAT_LONG));
    }

    function updateBackgroundResource(now) {
        var bgIndex;
        if (selectedBackground == 0) {
            bgIndex = getAutoBackgroundIndex(now);
        } else {
            bgIndex = selectedBackground - 1;
        }
        bgIndex = normalizeSettingValue(bgIndex, 0, BACKGROUND_COUNT - 1, 0);
        if (bgIndex == activeBackgroundIndex && bgBmp != null) { return; }
        activeBackgroundIndex = bgIndex;
        try { bgBmp = WatchUi.loadResource(BG_RES[bgIndex]); } catch (e) { bgBmp = null; }
    }

    function onHide() {
        stopAnimation();
        stopMinuteChecker();
        suppressNextMinuteJump = true;
    }

    function onUpdate(dc) {
        var now = Gregorian.info(Time.now(), Time.FORMAT_LONG);
        if (selectedBackground == 0) { updateBackgroundResource(now); }

        if (now.min != lastMinute) {
            handleMinuteChange(now, !suppressNextMinuteJump);
        }
        suppressNextMinuteJump = false;

        handleSafetyCheck();

        if (bgBmp != null) { dc.drawBitmap(0, 0, bgBmp); }
        else { dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK); dc.clear(); }

        var animationProgress = getAnimationProgress();
        var marioProgress = (marioIsDown) ? 0.0 : Math.sin(animationProgress * Math.PI);
        var blockProgress = getBlockAnimationProgress(animationProgress);
        var blockBounce = (marioIsDown) ? 0.0 : Math.sin(blockProgress * Math.PI);

        drawBlocks(dc, blockBounce, blockProgress);
        drawCharacter(dc, marioProgress);
        drawBattery(dc);
        drawActivityMetrics(dc);
    }

    private function updateTimeStrings(now, shouldAnimate) {
        var h = now.hour;
        if (!is24Hour) { h = (h > 12) ? h - 12 : (h == 0 ? 12 : h); }
        timeStr[0] = h.format("%02d");
        timeStr[1] = now.min.format("%02d");
    }

    private function updateSystemStats() {
        var stats = System.getSystemStats();
        batLevel = stats.battery;
        isCharging = stats.charging;

        var info = ActivityMonitor.getInfo();
        steps = (info != null && info.steps != null) ? info.steps : 0;

        var actInfo = Activity.getActivityInfo();
        if (actInfo != null && actInfo.currentHeartRate != null) {
            heartRate = actInfo.currentHeartRate.format("%d");
            return;
        }

        try {
            var hrIter = ActivityMonitor.getHeartRateHistory(1, true);
            var sample = hrIter.next();
            if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                heartRate = sample.heartRate.format("%d");
            } else {
                heartRate = "--";
            }
        } catch (e) {
            heartRate = "--";
        }
    }

    private function handleSafetyCheck() {
        if (!marioIsDown && animationStartTime > 0) {
            if (System.getTimer() - animationStartTime > 900) { stopAnimation(); }
        }
    }

    private function drawBlocks(dc, bounceProgress, blockProgress) {
        var blockX = (screenWidth - 200) / 2;
        var blockY = 80 - (15 * bounceProgress).toNumber();
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
            var baseY = 255;
            if (activeCharacterIndex == 2) { baseY -= BOWSER_Y_OFFSET; }
            var charY = baseY - (60 * sinProgress).toNumber();
            dc.drawBitmap(charX, charY, bmp);
        }
    }

    private function drawBattery(dc) {
        if (iconsFont == null) { return; }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var batIcon = (batLevel > 90) ? "h" : (batLevel < 20 ? "k" : "m");
        if (isCharging) { batIcon = "l"; }
        dc.drawText(screenWidth / 2, 15, iconsFont, batIcon, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawActivityMetrics(dc) {
        if (iconsFont == null) { return; }

        var centerY = screenHeight / 2;
        var leftMetricX = 42;
        var rightMetricX = screenWidth - 42;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        dc.drawText(leftMetricX, centerY - 24, iconsFont, "s", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(leftMetricX, centerY + 14, Graphics.FONT_XTINY, steps.format("%d"), Graphics.TEXT_JUSTIFY_CENTER);

        dc.drawText(rightMetricX, centerY - 24, iconsFont, "p", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(rightMetricX, centerY + 14, Graphics.FONT_XTINY, heartRate, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function startMarioJump() {
        if (!marioIsDown || inLowPower) { return; }
        try {
            marioIsDown = false;
            animationStartTime = System.getTimer();
            if (jumpTimer == null) { jumpTimer = new Timer.Timer(); }
            jumpTimer.start(method(:onJumpUpdate), JUMP_FRAME_INTERVAL_MS, true);
            WatchUi.requestUpdate();
        } catch (e) { stopAnimation(); }
    }

    function startMinuteChecker() {
        if (inLowPower) { return; }
        if (minuteCheckTimer != null) { return; }

        try {
            minuteCheckTimer = new Timer.Timer();
            minuteCheckTimer.start(method(:onMinuteCheck), 1000, true);
        } catch (e) {
            minuteCheckTimer = null;
        }
    }

    function stopMinuteChecker() {
        if (minuteCheckTimer != null) {
            try { minuteCheckTimer.stop(); } catch (e) {}
            minuteCheckTimer = null;
        }
    }

    function onMinuteCheck() as Void {
        if (inLowPower) { return; }

        var now = Gregorian.info(Time.now(), Time.FORMAT_LONG);
        if (now.min != lastMinute) {
            WatchUi.requestUpdate();
        }
    }

    function handleMinuteChange(now, shouldAnimate) {
        updateTimeStrings(now, true);
        updateSystemStats();
        if (selectedBackground == 0) { updateBackgroundResource(now); }
        if (getEffectiveCharacterIndex(now) != activeCharacterIndex) { refreshResources(); }
        if (shouldAnimate && !inLowPower) { startMarioJump(); }
        lastMinute = now.min;
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

    function getBlockAnimationProgress(animationProgress) {
        if (animationProgress <= BLOCK_ANIMATION_DELAY) { return 0.0; }

        var adjusted = (animationProgress - BLOCK_ANIMATION_DELAY) / (1.0 - BLOCK_ANIMATION_DELAY);
        if (adjusted >= 1.0) { return 1.0; }
        return adjusted;
    }

    function getAutoBackgroundIndex(now) {
        var hour = now.hour;
        if (hour >= 22 || hour < 6) { return 1; }
        if (hour >= 12 && hour < 18) { return 2; }
        if (hour >= 18) { return 3; }
        return 0;
    }

    function getEffectiveCharacterIndex(now) {
        if (now.month == APRIL_FOOLS_MONTH && now.day == APRIL_FOOLS_DAY) {
            return 2;
        }

        return normalizeSettingValue(selectedCharacter, 0, CHARACTER_COUNT - 1, 0);
    }

    function onEnterSleep() {
        inLowPower = true;
        stopAnimation();
        stopMinuteChecker();
        suppressNextMinuteJump = true;
    }

    function onExitSleep() {
        inLowPower = false;
        startMinuteChecker();
        WatchUi.requestUpdate();
    }
    function onSettingsChanged() { loadSettings(); refreshResources(); WatchUi.requestUpdate(); }

    private function normalizeSettingValue(value, minValue, maxValue, defaultValue) {
        var normalized = defaultValue;

        if (value != null) {
            if (value instanceof Lang.Number) {
                normalized = value.toNumber();
            } else if (value instanceof Lang.String) {
                try {
                    normalized = value.toNumber();
                } catch (e) {
                    normalized = defaultValue;
                }
            }
        }

        if (normalized < minValue || normalized > maxValue) {
            return defaultValue;
        }

        return normalized;
    }
}
