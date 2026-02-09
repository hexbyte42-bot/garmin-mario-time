# Garmin Mario Time 表盘开发规范

## 项目概述
将 Pebble Time 的 Mario 表盘成功移植到 Garmin Connect IQ 平台，支持 FR265 等设备。

## 开发环境
- **SDK 版本**: Connect IQ SDK 8.4.1 (2026-02-03)
- **目标设备**: Garmin FR265 (416x416 分辨率)
- **开发语言**: Monkey C
- **构建工具**: monkeybrains.jar

## 代码规范

### 1. 文件结构
```
garmin-mario-time/
├── manifest.xml          # 应用元数据配置
├── monkey.jungle         # 项目依赖配置
├── build.xml             # 构建配置
├── resources/
│   ├── resources.xml     # 资源引用定义
│   ├── fonts.xml         # 字体配置
│   ├── *.png            # 图片资源
│   └── *.fnt            # 字体文件
└── source/
    └── MarioTimeApp.mc   # 主应用代码
```

### 2. 编码标准
- **命名规范**: 
  - 类名使用 PascalCase (`MarioTimeView`)
  - 变量使用 camelCase (`marioIsDown`, `animationStartTime`)
  - 常量使用 UPPER_SNAKE_CASE (`ANIMATION_DURATION`)
- **注释**: 关键逻辑必须添加注释，特别是动画和状态管理
- **错误处理**: 所有资源加载必须包含 try-catch 处理
- **性能优化**: 避免在 `onUpdate()` 中进行重复计算

### 3. 动画实现规范
- **触发机制**: 使用时间检测 (`now.min != lastMinute`) 而非自定义回调
- **状态管理**: 使用简单布尔值或枚举，避免复杂状态机
- **定时器**: 使用 `Timer.Timer()` 实现动画循环
- **帧率**: 默认 30 FPS (33ms 间隔)，省电模式可降至 15 FPS (66ms 间隔)
- **清理**: 动画完成后必须停止定时器并重置状态

### 4. 设置系统规范
- **属性定义**: 在 `Properties` 类中定义常量
  ```monkeyc
  class Properties {
      static const character = 1;
      static const background = 2;
  }
  ```
- **持久化**: 使用 `Application.Properties.getValue/setValue()`
- **默认值**: 必须提供合理的默认值处理
- **类型安全**: 所有设置值必须进行 null 检查和类型验证

### 5. 资源管理
- **图片尺寸**: 
  - 背景: 416x416 (全屏)
  - 角色: 120x120 
  - 方块: 100x100
- **字体生成**: 使用 ttf2bmp 工具生成自定义字体
  ```bash
  ttf2bmp -f "Gamegirl.ttf" -s "48" -c "0123456789" -o resources/
  ```
- **内存优化**: 所有资源在 `onLayout()` 中一次性加载

## 测试流程

### 1. 编译测试
```bash
# 基本编译
./test.sh

# 完整构建
java -jar $SDK_PATH/bin/monkeybrains.jar \
  -o bin/garminmariotime.prg \
  -f monkey.jungle \
  -y developer_key \
  -d fr265_sim -w
```

### 2. 功能测试清单
- [ ] 时间显示正确 (12/24小时制)
- [ ] 背景自动切换 (按时间段)
- [ ] 马里奥跳跃动画 (每分钟一次)
- [ ] 角色切换功能 (通过设置)
- [ ] 健康指标显示 (电池、步数、心率)
- [ ] 动画完成后正确返回正常状态
- [ ] 内存泄漏检查 (长时间运行)

### 3. 设备测试
- **模拟器测试**: 基本功能验证
- **真实设备测试**: 性能和电池消耗测试
- **边界情况**: 闰年、夏令时、低电量等

## 分支管理策略

### 主要分支
- **`master`**: 稳定发布版本，只接受经过充分测试的代码
- **`development`**: 当前开发分支，用于新功能开发
- **`feature/*`**: 特性分支，完成後合并到 development
- **`fix/*`**: 修复分支，紧急修复直接合并到 master

### 分支命名规范
- `feature/功能名称` - 新功能开发
- `fix/问题描述` - Bug 修复
- `release/vX.X.X` - 发布准备

### 合并策略
1. **特性开发**: feature → development → master
2. **紧急修复**: fix → master (直接)
3. **代码审查**: 所有合并必须经过测试验证
4. **回滚机制**: 保留最近3个稳定提交作为回滚点

## 发布流程

### 1. 准备阶段
- 更新 `DEVELOPMENT_LOG.md`
- 创建发布包 (`package_release.sh`)
- 生成 `RELEASE_NOTES.txt`

### 2. 测试阶段
- 完整功能测试
- 性能基准测试
- 用户体验验证

### 3. 发布阶段
- 提交到 Connect IQ Store
- 更新文档和用户指南
- 监控用户反馈

## 常见问题与解决方案

### 1. 动画卡住问题
**症状**: 角色停留在空中不返回
**原因**: 定时器未正确停止或状态未重置
**解决方案**: 
- 确保 `onJumpUpdate()` 中正确停止定时器
- 添加状态重置逻辑
- 使用 `WatchUi.requestUpdate()` 强制刷新

### 2. 设置无法保存
**症状**: 设备重启后设置丢失
**原因**: 未正确使用 `Application.Properties`
**解决方案**:
- 使用正确的属性常量
- 添加 null 值检查
- 在 `onSettingsChanged()` 中重新加载设置

### 3. 编译错误
**症状**: "undefined symbol" 或类型错误
**原因**: API 使用不当或缺少导入
**解决方案**:
- 检查所有 `using` 语句
- 验证 API 文档版本兼容性
- 使用正确的数据类型转换

## 性能优化指南

### 1. 电池优化
- 降低动画帧率 (15 FPS vs 30 FPS)
- 优化心率读取频率
- 避免不必要的屏幕更新

### 2. 内存优化  
- 重用对象而非创建新对象
- 及时释放定时器资源
- 避免大数组和复杂数据结构

### 3. 渲染优化
- 批量绘制操作
- 避免重复的资源加载
- 使用合适的字体大小

## 文档维护

### 必须维护的文档
- `DEVELOPMENT_LOG.md` - 开发进度和问题记录
- `DEVELOPMENT_GUIDELINES.md` - 本规范文档
- `README.md` - 用户使用指南
- `ISSUE_SUMMARY.md` - 已知问题汇总

### 更新频率
- 开发日志: 每次重要提交后更新
- 开发规范: 功能架构变更时更新  
- 用户文档: 每次发布前更新

---
*最后更新: 2026-02-09*