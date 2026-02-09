# Garmin Mario Time 表盘编译指南

## 📋 编译前提条件

### 1. 安装 Connect IQ SDK
- 下载并安装 [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/)
- 当前项目使用 SDK 版本：8.4.1-2026-02-03-e9f77eeaa

### 2. 创建开发者密钥
```bash
# 在项目根目录执行
connectiq keys --create
```
这将生成 `developer_key` 文件，用于签署应用程序。

### 3. 环境变量设置（可选）
```bash
export CIQ_SDK_PATH="/path/to/connectiq-sdk"
export PATH="$PATH:$CIQ_SDK_PATH/bin"
```

## 🔧 编译命令

### 基本编译命令
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

### 参数说明
- `-o`: 输出文件路径
- `-f`: Jungle 配置文件
- `-y`: 开发者私钥文件
- `-d`: 目标设备 (fr265_sim = FR265 模拟器)
- `-w`: 显示编译警告

### 支持的设备
- `fr265_sim` - Forerunner 265 模拟器
- `fr265` - Forerunner 265 真实设备
- `fenix7_sim` - fēnix 7 系列模拟器

## 🧪 编译验证流程

### 1. 语法检查（无需密钥）
```bash
# 只检查语法错误，不生成可执行文件
monkeyc -f monkey.jungle -d fr265_sim -w
```

### 2. 完整编译
```bash
# 生成完整的 .prg 文件
./build.sh
```

### 3. 模拟器测试
```bash
# 启动模拟器并安装应用
connectiq install garminmariotime.prg
```

## 📁 项目文件结构

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

## ⚠️ 常见编译错误及解决方案

### 1. "Private key not specified"
**原因**: 缺少 `-y developer_key` 参数
**解决**: 创建开发者密钥或在命令中指定密钥路径

### 2. "Symbol not found"
**原因**: 资源文件未正确引用
**解决**: 检查 `resources.xml` 中的资源 ID 是否与代码中一致

### 3. "Type mismatch"
**原因**: 变量类型不匹配
**解决**: 确保所有变量声明和使用保持一致的类型

### 4. "Memory limit exceeded"
**原因**: 应用超出设备内存限制
**解决**: 优化资源大小，减少不必要的变量

## 🚀 自动化编译脚本

### build.sh (Linux/Mac)
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

### test_compile.sh (快速语法检查)
```bash
#!/bin/bash
# 快速语法检查，无需密钥
monkeyc -f monkey.jungle -d fr265_sim -w --Eno-invalid-symbol
if [ $? -eq 0 ]; then
    echo "✅ Syntax check passed!"
else
    echo "❌ Syntax errors found!"
    exit 1
fi
```

## 📝 提交前检查清单

- [ ] 代码通过语法检查 (`test_compile.sh`)
- [ ] 完整编译成功 (`build.sh`)
- [ ] 在模拟器中正常运行
- [ ] 所有新功能经过测试
- [ ] 无内存泄漏（Timer 正确停止）
- [ ] 错误处理完整（try-catch 块）
- [ ] 代码符合开发规范

## 🔄 版本管理

- **主分支 (master)**: 只包含经过完整测试的稳定代码
- **功能分支**: 新功能在独立分支开发，通过编译和测试后再合并
- **标签**: 发布版本使用语义化版本标签 (v1.0.0, v1.1.0, etc.)

---
*最后更新: 2026-02-09*