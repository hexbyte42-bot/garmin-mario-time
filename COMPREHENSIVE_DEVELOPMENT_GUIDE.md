# 🎮 Garmin Mario Time 表盘 - 综合开发指南

## 项目概述
将 Pebble Time 的 Mario 表盘移植到 Garmin FR265 手表，支持 416x416 像素屏幕。

## 当前状态（2026-02-09）

### ✅ 核心功能
- **时间显示**: 支持 12/24 小时格式，使用自定义 Gamegirl 像素字体
- **背景切换**: 自动/手动切换 day/night/underground/castle 四种背景
- **角色支持**: Mario/Luigi/Bowser 三种角色，每分钟跳跃动画
- **健康指标**: 电池电量、步数、心率显示
- **稳定性**: 回退了有问题的设备端设置菜单，保持核心功能稳定

### ⚠️ 已知限制
- 无设备端设置菜单（通过 Connect IQ Mobile App 进行设置）
- 需要开发者密钥进行完整编译

## 开发环境

### SDK 信息
- **路径**: `/home/buzz-bot/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-8.4.1-2026-02-03-e9f77eeaa`
- **版本**: Connect IQ Compiler version 8.4.1
- **构建日期**: 2026-02-03
- **Git Commit**: e9f77eeaa

### 环境设置
```bash
# 安装 SDK 后设置环境变量
export CIQ_SDK_PATH="/path/to/connectiq-sdk"
export PATH="$PATH:$CIQ_SDK_PATH/bin"

# 创建开发者密钥（首次需要）
connectiq keys --create
```

## 编译方法

### 语法检查（无需密钥）
```bash
# 快速验证代码语法
monkeyc -f monkey.jungle -d fr265_sim -w --Eno-invalid-symbol
```

### 完整编译
```bash
# Linux/Mac
java -Xms1g -Dfile.encoding=UTF-8 -jar \
  $CIQ_SDK_PATH/bin/monkeybrains.jar \
  -o bin/garminmariotime.prg \
  -f monkey.jungle \
  -y developer_key \
  -d fr265_sim -w

# Windows (PowerShell)
java -Xms1g -Dfile.encoding=UTF-8 -jar `
  C:\Users\username\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-8.4.1-2026-02-03-e9f77eeaa\bin\monkeybrains.jar `
  -o bin\garminmariotime.prg `
  -f monkey.jungle `
  -y developer_key `
  -d fr265_sim -w
```

### 自动化脚本
**build.sh**:
```bash
#!/bin/bash
set -e
SDK_PATH="$HOME/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-8.4.1-2026-02-03-e9f77eeaa"
KEY_FILE="developer_key"

if [ ! -f "$KEY_FILE" ]; then
    echo "Error: developer_key not found. Run 'connectiq keys --create' first."
    exit 1
fi

echo "Compiling Mario Time watch face..."
java -Xms1g -Dfile.encoding=UTF-8 -jar \
    "$SDK_PATH/bin/monkeybrains.jar" \
    -o bin/garminmariotime.prg \
    -f monkey.jungle \
    -y "$KEY_FILE" \
    -d fr265_sim -w

echo "Compilation successful! Output: bin/garminmariotime.prg"
```

## 项目结构
```
garmin-mario-time/
├── manifest.xml          # 应用元数据
├── monkey.jungle         # 构建配置
├── build.xml            # Ant 构建脚本
├── resources/           # 资源文件
│   ├── resources.xml    # 资源定义
│   ├── fonts.xml        # 字体配置
│   └── *.png           # 图片资源
└── source/
    └── MarioTimeApp.mc  # 主源代码
```

## 开发规范

### 分支策略
- **master**: 稳定生产版本，只包含经过验证的功能
- **功能分支**: 新功能在独立分支中开发和测试
- **提交要求**: 所有代码必须先通过编译验证再提交

### 代码规范
- 使用 Connect IQ 官方 API 和最佳实践
- 避免使用非标准回调函数（如 `onMinuteChanged()`）
- 正确处理 Timer 资源，防止内存泄漏
- 实现完整的错误处理和回退机制

### 测试要求
- 所有功能必须在模拟器中编译通过
- 动画功能需要验证完整周期（开始→执行→结束→重置）
- 性能优化需要监控电池消耗

## 提交前检查清单
- [ ] 代码通过语法检查
- [ ] 完整编译成功
- [ ] 在模拟器中正常运行
- [ ] 所有新功能经过测试
- [ ] 无内存泄漏（Timer 正确停止）
- [ ] 错误处理完整（try-catch 块）
- [ ] 代码符合开发规范

## 常见问题解决

### 编译错误
- **"Private key not specified"**: 创建开发者密钥
- **"Symbol not found"**: 检查资源 ID 是否一致
- **"Type mismatch"**: 确保变量类型一致
- **"Memory limit exceeded"**: 优化资源大小

### 功能问题
- **动画卡住**: 确保 Timer 正确停止和状态重置
- **资源不显示**: 检查图片格式和路径
- **设置不生效**: 验证 Application.Properties 使用正确

## 下一步工作
1. **真实设备测试**: 在实际 FR265 手表上全面测试
2. **性能优化**: 进一步优化电池续航
3. **文档完善**: 更新用户手册
4. **发布准备**: 准备 Connect IQ Store 提交流程

## 参考资料
- [Pebble 原版](https://github.com/ClusterM/pebble-mario)
- [Garmin 开发者文档](https://developer.garmin.com/connect-iq/)
- [ttf2bmp 工具](https://github.com/wkusnierczyk/ttf2bmp)

---
*最后更新: 2026-02-09*