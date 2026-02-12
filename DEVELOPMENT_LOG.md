# Garmin Mario Time 表盘开发记录

## 项目概述
将 Pebble Time 的 Mario 表盘移植到 Garmin FR265 手表。

## 当前状态（2026-02-12）

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

### ✅ 最新改进（2026-02-12）

#### 1. 跳跃稳定性修复
- **分支**: `fix/mario-jump-stuck-gemini`
- **问题**: Mario 卡在跳跃状态，导致动画无法正常结束
- **解决方案**: 
  - 添加低功耗模式检测 (`inLowPower` 标志)
  - 实现 `onEnterSleep()`/`onExitSleep()` 正确处理睡眠/唤醒
  - 添加安全超时机制防止动画无限循环
  - 优化资源管理和错误处理
- **实际行为**: 抬起手腕时如果超过一分钟未查看，Mario 会跳跃（这是预期行为）
- **功耗影响**: 更省电，因为只在必要时执行动画

#### 2. 资源文件清理
- **删除了不必要的文件**:
  - `Gamegirl-48.fnt` 和 `Gamegirl-48.png`（旧字体，已被 pixel_font 替代）
  - `fonts.xml`（旧的字体配置）
  - `settings.xml`（未使用的设置文件）
- **保留了必要的开发脚本和源文件**:
  - `Gamegirl.ttf`, `emulogic.ttf`（字体生成源文件）
  - `font_generator.py`（字体生成脚本）
  - `scale_images.py`（图片缩放脚本）

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

#### 4. 健康度指标显示（优先级：高）
- 顶部显示电池电量
- 9点钟方向显示步数（图标在上，数据在下，居中对齐）
- 3点钟方向显示心率（图标在上，数据在下，居中对齐）
- 使用 ConnectIQ 标准图标字体
- 优化心率读取频率以节省电量
- 调整字体大小和间距
- 修复了马里奥跳跃动画完成后正确返回正常状态的bug

### ⚠️ 已回退的功能

#### 1. 设备端设置菜单（2026-02-09）
**问题**：设备端角色选择和背景模式菜单功能不稳定，无法正常工作

**决策**：回退到稳定版本，移除有问题的设备端菜单实现
**当前状态**：保留通过 Connect IQ Mobile App 进行设置的功能，移除设备端直接设置

## 开发工具和脚本

### 字体生成脚本 (`font_generator.py`)
- **用途**: 从 TTF 字体文件生成 Garmin 兼容的 FNT + PNG 字体
- **输入**: TTF 字体文件（如 `Gamegirl.ttf`）
- **输出**: FNT 配置文件和 PNG 图集
- **保留原因**: 便于未来修改或生成新字体

### 图片缩放脚本 (`scale_images.py`)
- **用途**: 将原始 Pebble 素材放大到 Garmin FR265 分辨率
- **输入**: 原始 144x168 尺寸的 PNG 文件
- **输出**: 416x416 (背景)、120x120 (角色)、100x100 (方块) 等尺寸
- **保留原因**: 便于适配其他设备或重新生成素材

### 必要的源文件
- **TTF 字体文件**: `Gamegirl.ttf`, `emulogic.ttf` - 字体生成的源文件
- **原始 PNG 素材**: 所有角色和背景 PNG - 图片缩放的源文件

## 技术细节

### 屏幕分辨率
- FR265: 416x416 像素
- 原版 Pebble: 144x168 像素
- 缩放比例：约 2.9x

### 字体生成
使用 font_generator.py 工具：
```bash
python3 font_generator.py Gamegirl.ttf pixel_font 48
```

### 文件结构
```
garmin-mario-time-color/
├── manifest.xml
├── monkey.jungle
├── resources/
│   ├── resources.xml
│   ├── background_*.png   # 背景图
│   ├── mario_*.png        # 马里奥素材
│   ├── block.png          # 方块
│   ├── launcher_icon.png  # 启动图标
│   ├── pixel_font.fnt     # 自定义字体配置
│   ├── pixel_font.png     # 自定义字体图集
│   ├── icons-43px.fnt     # 图标字体配置  
│   ├── icons-43px_0.png   # 图标字体图集
│   ├── Gamegirl.ttf       # 字体源文件（保留用于开发）
│   └── emulogic.ttf       # 备用字体源文件（保留用于开发）
├── source/
│   └── MarioTimeApp.mc    # 主代码
├── font_generator.py      # 字体生成脚本
└── scale_images.py        # 图片缩放脚本
```

## 编译和开发指南

详细的编译方法、环境设置和开发流程请参考 `COMPREHENSIVE_DEVELOPMENT_GUIDE.md` 文件。

## 分支管理策略

### 主分支（master）
- 只包含经过充分测试的稳定功能
- 每次提交必须通过编译验证
- 保持可发布状态

### 功能分支
- 每个新功能在独立分支中开发
- 充分测试后再考虑合并到 master
- 如果功能不稳定，及时回退

### 清理策略
- 定期清理已完成或废弃的本地分支
- 保留远程分支作为历史备份
- 保持工作目录整洁

## 下一步工作
1. **稳定版本维护**: 基于当前稳定版本进行小修小补
2. **真实设备测试**: 在实际 FR265 手表上全面测试
3. **性能优化**: 进一步优化电池续航
4. **文档完善**: 更新用户手册和开发者指南
5. **发布准备**: 准备 Connect IQ Store 提交流程

## 参考资料
- Pebble 原版：https://github.com/ClusterM/pebble-mario
- Garmin 字体文档：https://developer.garmin.com/connect-iq/connect-iq-faq/how-do-i-use-custom-fonts/
- 使用自定义字体的表盘 https://github.com/wkusnierczyk/garmin-fancyfont-time
- ttf2bmp 工具：https://github.com/wkusnierczyk/ttf2bmp
- Connect IQ 开发者文档：https://developer.garmin.com/connect-iq/