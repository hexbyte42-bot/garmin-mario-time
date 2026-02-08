# Garmin Mario Time 表盘开发记录

## 项目概述
将 Pebble Time 的 Mario 表盘移植到 Garmin FR265 手表。

## 当前状态（2026-02-06）

### ✅ 已完成

#### 1. 基础架构
- [x] 项目结构搭建（manifest.xml, resources.xml, source/）
- [x] 设备支持：FR265（416x416 屏幕）
- [x] SDK 版本：5.2.0

#### 2. 图片资源
- [x] 背景图片放大到 416x416（day/night/underground/castle）
- [x] 马里奥角色图片放大到 120x120（mario_normal/jump）
- [x] 问号方块放大到 100x100
- [x] Luigi 和 Bowser 角色图片

#### 3. 自定义字体
- [x] 使用 ttf2bmp 工具生成像素字体（Gamegirl-48.fnt/png）
- [x] 字体配置：fonts.xml
- [x] 字体位置：方块内居中（textY = blockY + 30）
- [x] 字体颜色：棕色 rgb(117, 58, 0) = 0x753A00

#### 4. 时间显示
- [x] 支持 12/24 小时格式
- [x] 小时和分钟分别显示在两个方块内
- [x] 使用自定义像素字体

#### 5. 布局
- [x] 背景：全屏显示（0,0）
- [x] 方块：Y=80，两个并排
- [x] 马里奥：头部位置 Y=253（方块下方）

### ✅ 已解决

#### 1. 马里奥跳跃动画（2026-02-06）
**问题**：马里奥停留在空中，没有正常跳跃

**根本原因**：
- `onMinuteChanged()` 不是 ConnectIQ 的标准回调函数
- 重复的 `lastMinute` 变量声明导致编译错误
- 缺少 Timer 导入

**解决方案**：
- 使用 `onUpdate()` 中的时间检测来触发跳跃
- 移除重复的变量声明
- 添加正确的 Timer 导入和使用
- 优化动画逻辑确保状态正确切换

**结果**：马里奥现在能正常完成跳跃动画，每分钟触发一次

### ✅ 已完成

#### 1. 背景自动切换（优先级：中）
- 根据时间自动切换 day/night/underground/castle 背景
- 实现了设置选项支持手动/自动模式切换

#### 2. 角色选择（优先级：低）
- 支持 Mario/Luigi/Bowser 切换
- 已添加设置界面

#### 3. 设置系统集成（优先级：中）
- 完整集成 Garmin Connect IQ 设置系统
- 支持角色选择和背景模式设置

#### 4. 偣健度指标显示（优先级：高）
- 顶部显示电池电量
- 9点钟方向显示步数（图标在上，数据在下，居中对齐）
- 3点钟方向显示心率（图标在上，数据在下，居中对齐）
- 使用 ConnectIQ 标准图标字体
- 优化心率读取频率以节省电量
- 调整字体大小和间距
- 修复了马里奥跳跃动画完成后正确返回正常状态的bug

## 技术细节

### 屏幕分辨率
- FR265: 416x416 像素
- 原版 Pebble: 144x168 像素
- 缩放比例：约 2.9x

### 字体生成
使用 ttf2bmp 工具：
```bash
ttf2bmp -f "Gamegirl.ttf" -s "48" -c "0123456789" -o resources/
```

### 文件结构
```
garmin-mario-time-color/
├── manifest.xml
├── monkey.jungle
├── resources/
│   ├── resources.xml
│   ├── fonts.xml          # 字体定义
│   ├── Gamegirl-48.fnt    # 自定义字体
│   ├── Gamegirl-48.png
│   ├── background_*.png   # 背景图
│   ├── mario_*.png        # 马里奥素材
│   ├── block.png          # 方块
│   └── ...
└── source/
    └── MarioTimeApp.mc    # 主代码
```

## 编译命令
```bash
java -Xms1g -Dfile.encoding=UTF-8 -jar ^
  c:\Users\lib.in\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-8.4.1-2026-02-03-e9f77eeaa\bin\monkeybrains.jar ^
  -o bin\garminmariotimecolor.prg ^
  -f c:\home\garmin\watchface\garmin-mario-time-color\monkey.jungle ^
  -y c:\home\garmin\developer_key ^
  -d fr265_sim -w
```

## 下一步工作
1. 测试所有新功能（角色选择、背景模式、日期显示）
2. 性能优化和电池续航测试
3. 处理边界情况（如闰年、夏令时等）
4. 准备发布版本

## 参考资料
- Pebble 原版：https://github.com/ClusterM/pebble-mario
- Garmin 字体文档：https://developer.garmin.com/connect-iq/connect-iq-faq/how-do-i-use-custom-fonts/
- 使用自定义字体的表盘 https://github.com/wkusnierczyk/garmin-fancyfont-time
- ttf2bmp 工具：https://github.com/wkusnierczyk/ttf2bmp
