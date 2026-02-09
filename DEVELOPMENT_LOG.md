# Garmin Mario Time 表盘开发记录

## 项目概述
将 Pebble Time 的 Mario 表盘移植到 Garmin FR265 手表。

## 当前状态（2026-02-09）

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

## 编译方法和验证流程

### 1. 开发环境设置
- **SDK**: Garmin Connect IQ SDK 8.4.1 或更高版本
- **开发者密钥**: 需要生成或使用现有的 `.developer_key` 文件
- **目录结构**: 确保项目根目录包含 `monkey.jungle` 文件

### 2. 编译命令（Windows）
```bash
java -Xms1g -Dfile.encoding=UTF-8 -jar ^
  c:\Users\lib.in\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-8.4.1-2026-02-03-e9f77eeaa\bin\monkeybrains.jar ^
  -o bin\garminmariotimecolor.prg ^
  -f c:\home\garmin\watchface\garmin-mario-time-color\monkey.jungle ^
  -y c:\home\garmin\developer_key ^
  -d fr265_sim -w
```

### 3. 编译命令（Linux/Mac）
```bash
java -Xms1g -Dfile.encoding=UTF-8 -jar \
  /home/user/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-8.4.1-2026-02-03-e9f77eeaa/bin/monkeybrains.jar \
  -o bin/garminmariotimecolor.prg \
  -f /path/to/garmin-mario-time/monkey.jungle \
  -y /path/to/developer_key \
  -d fr265_sim -w
```

### 4. 语法验证（无需密钥）
```bash
# 仅检查语法，不生成可执行文件
monkeyc -f monkey.jungle -d fr265_sim --Eno-invalid-symbol
```

### 5. 编译验证流程
1. **语法检查**: 确保代码无语法错误
2. **资源验证**: 检查所有图片和字体文件存在且格式正确
3. **模拟器测试**: 在 Connect IQ 模拟器中运行测试
4. **真实设备测试**: 在实际 Garmin 设备上验证功能
5. **性能测试**: 监控电池消耗和内存使用

### 6. 提交前检查清单
- [ ] 代码通过语法检查
- [ ] 所有资源文件已包含
- [ ] 功能在模拟器中正常工作
- [ ] 动画逻辑完整（开始→执行→结束→重置）
- [ ] 无内存泄漏（Timer 正确停止）
- [ ] 错误处理完善（try-catch 块）
- [ ] 开发日志已更新

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