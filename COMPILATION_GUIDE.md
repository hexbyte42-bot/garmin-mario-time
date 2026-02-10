# 编译指南

## 环境要求

- Garmin Connect IQ SDK 8.4.1 或更高版本
- Java 运行时环境 (JRE)
- 有效的开发者密钥

## SDK 位置

SDK 安装在: `~/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-8.4.1-2026-02-03-e9f77eeaa`

## 开发者密钥配置

编译需要有效的开发者密钥。密钥文件位置:
`~/.Garmin/ConnectIQ/mykey/developer_key`

### 生成开发者密钥

如果密钥格式不正确，可以通过以下方式生成:

1. **使用 Garmin SDK Manager** (推荐):
   ```bash
   # 启动 SDK Manager
   ~/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-8.4.1-2026-02-03-e9f77eeaa/bin/sdkmanager
   
   # 在界面中选择 "Generate Developer Key"
   ```

2. **使用命令行** (如果 SDK Manager 可用):
   ```bash
   # 注意: 当前模拟器有兼容性问题，可能无法使用
   ~/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-8.4.1-2026-02-03-e9f77eeaa/bin/connectiq keys --create
   ```

3. **手动创建** (需要正确的格式):
   当前环境中的密钥格式可能不正确。正确的格式应该是 ConnectIQ 特定的格式。

## 编译命令

### 使用编译脚本

```bash
# 设置密钥路径环境变量
export DEV_KEY=/path/to/your/developer_key

# 运行编译
./compile.sh
```

### 手动编译

```bash
# 基本编译命令
~/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-8.4.1-2026-02-03-e9f77eeaa/bin/monkeyc \
    -f monkey.jungle \
    -d fr265 \
    -o bin/MarioTimeColor.prg \
    -y /path/to/developer_key \
    -w
```

## 当前状态

- ✅ SDK 已正确安装
- ✅ 项目配置正确 (monkey.jungle, manifest.xml)
- ✅ 开发者密钥已配置: `~/.Garmin/ConnectIQ/developer_key/developer_key.der`
- ✅ 编译脚本可以正常工作

## 快速开始

```bash
# 直接运行编译脚本
./compile.sh

# 或者手动编译
~/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-8.4.1-2026-02-03-e9f77eeaa/bin/monkeyc \
    -f monkey.jungle \
    -d fr265 \
    -o bin/MarioTimeColor.prg \
    -y ~/.Garmin/ConnectIQ/developer_key/developer_key.der \
    -w
```

## 已知问题

1. **密钥格式问题**: 当前环境中的密钥格式可能不正确
2. **模拟器兼容性**: libsoup2/libsoup3 冲突导致无法使用 connectiq 命令行工具

## 解决方案

1. 在完整配置的 Garmin 开发环境中编译
2. 使用 Garmin Connect IQ SDK Manager 生成正确的开发者密钥
3. 或者使用之前成功编译过的密钥文件

## Git 预提交钩子

项目已配置预提交钩子，确保提交前代码可以编译通过。

钩子位置: `.git/hooks/pre-commit`

**注意**: 预提交钩子需要正确配置的开发者密钥才能正常工作。