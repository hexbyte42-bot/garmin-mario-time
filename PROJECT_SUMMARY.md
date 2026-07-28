# Garmin Mario Time - Project Summary

## Overview

Garmin Mario Time 是将 Pebble Mario 表盘移植到 Garmin Connect IQ 的彩色版本，专门适配 Garmin Forerunner 265。Monkey C 单文件实现（`source/MarioTimeApp.mc`，555 行）。

## 当前状态（最新 commit: `72bd3b9`）

所有核心功能已开发完毕，处于维护阶段。

### 已实现功能

| 功能 | 状态 | 说明 |
|------|------|------|
| 每分钟马里奥跳跃动画 | ✅ | 分钟变化时触发跳跃 + 砖块弹跳 |
| 时间砖块滚动 | ✅ | 分钟变化时时间文字随砖块上移 |
| 角色选择（Mario/Luigi/Bowser） | ✅ | 设备端设置 + Connect IQ App 设置 |
| 背景模式（自动/手动 + 4 种主题） | ✅ | Day/Night/Underground/Castle |
| 顶部状态栏（电池 + 日期） | ✅ | 电池左上、日期右上，形成 HUD 状态栏 |
| 步数 + 心率 | ✅ | 底部对称布局 |
| 圆形屏幕适配 | ✅ | 所有 UI 元素均在圆形可见区域内，使用 dx²+dy² < r² 计算安全坐标 |
| 设备端设置菜单 | ✅ | 长按菜单进入设置 |
| 4月1日 Bowser 强制覆盖 | ✅ | 自动切换到 Bowser，优先级高于用户设置 |

### 最近修复

- 顶部状态栏重构：电池移至左上角，新增日期右上角（commit `72bd3b9`）
- 圆形屏幕适配：所有元素按圆形可见区域定位（commit `00d8fda`）
- 4月1日 Bowser 覆盖不刷新问题（commit `1d5a28d`）
- 动画滞后/重影问题（commit `6158dbc`）
- 跳转一致性修复（commit `f5e54f0`）
- 设备端设置菜单修复（commits `ab62d47` ~ `00830b6`）

### 待办事项

1. 添加构建和文档一致性验证脚本
2. 决定是否以 Garmin 原生方式引入部分 companion 风格功能
3. 继续在设备上进行电池性能分析

## 项目结构

```
garmin-mario-time/
├── source/MarioTimeApp.mc      # 唯一源代码 (594 行)
├── resources/                   # 资源文件（图片、字体、设置）
├── manifest.xml                 # 应用清单
├── README.md                    # 项目 README
├── COMPILATION_GUIDE.md         # 编译指南
├── COMPREHENSIVE_DEVELOPMENT_GUIDE.md  # 开发指南
└── DEVELOPMENT_LOG.md           # 开发日志
```

## 代码结构

MarioTimeApp.mc 包含三个主要类：

### MarioTimeApp (AppBase)
- `getInitialView()` → 返回 MarioTimeView
- `getSettingsView()` → 返回设置菜单 + 委托
- `onSettingsChanged()` → 重载设置

### MarioTimeView (WatchFace)
- **常量**: 角色数(3)、背景数(4)、跳跃帧间隔(67ms)、愚人节日期等
- **状态变量**: 角色/背景资源、动画状态、缓存数值、用户设置
- **关键方法**:
  - `onLayout()` — 初始化布局、字体、设置
  - `onUpdate()` — 主渲染循环
  - `onPartialUpdate()` — 低功耗模式部分刷新
  - `drawTopBar()` — 绘制顶部状态栏（电池 + 日期），适配圆形屏幕
  - `compute()` — 动画计算（跳跃、砖块位移）
  - `loadSettings()` — 读取用户设置
  - `refreshResources()` — 根据设置加载资源
  - `updateSystemStats()` — 更新电量、步数、心率缓存
  - `drawBackground/Time/Blocks/Character/TopBar/ActivityMetrics()` — 各元素绘制
  - `minuteJump()/blockAnimate()` — 动画触发器

### MarioTimeSettingsMenu + MarioTimeSettingsMenuDelegate
- 设备端设置界面（角色选择、背景选择）

## 编译

```bash
cd ~/.openclaw/workspace/garmin-mario-time
./compile.sh
```

需要 Monkey C 编译器（`monkeyc`）和开发者密钥。

## 关键配置

- **默认模型**: dspark (deepseek-v4-flash-dspark)
- **工作目录**: `~/.openclaw/workspace/garmin-mario-time`
- **Git**: master 分支，保持可发布状态
