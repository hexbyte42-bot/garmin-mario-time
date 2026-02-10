#!/bin/bash
# compile.sh - 编译 Garmin Connect IQ 表盘
# 注意: 需要配置正确的开发者密钥才能编译

set -e

# SDK 路径
SDK_PATH="$HOME/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-8.4.1-2026-02-03-e9f77eeaa"
MONKEYC="$SDK_PATH/bin/monkeyc"

# 项目路径
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$PROJECT_DIR/bin"
OUTPUT_FILE="$OUTPUT_DIR/MarioTimeColor.prg"

# 开发者密钥路径 - 需要配置正确的密钥
# 密钥格式要求: PKCS#12 或 ConnectIQ 特定格式
DEV_KEY="${DEV_KEY:-$HOME/.Garmin/ConnectIQ/mykey/developer_key.p12}"

# 确保输出目录存在
mkdir -p "$OUTPUT_DIR"

echo "=================================="
echo "编译 Mario Time Color 表盘"
echo "=================================="
echo "SDK 路径: $SDK_PATH"
echo "项目路径: $PROJECT_DIR"
echo "输出文件: $OUTPUT_FILE"
echo "开发者密钥: $DEV_KEY"
echo "=================================="

# 检查 SDK 是否存在
if [ ! -f "$MONKEYC" ]; then
    echo "错误: 找不到 monkeyc 编译器"
    echo "请检查 SDK 路径: $SDK_PATH"
    exit 1
fi

# 检查密钥是否存在
if [ ! -f "$DEV_KEY" ]; then
    echo "警告: 找不到开发者密钥: $DEV_KEY"
    echo "请配置正确的开发者密钥路径"
    echo ""
    echo "生成密钥的方法:"
    echo "1. 使用 Garmin Connect IQ SDK Manager 生成"
    echo "2. 或使用命令: openssl pkcs12 -export -in cert.pem -inkey key.pem -out developer_key.p12"
    echo ""
    exit 1
fi

# 编译命令
echo "开始编译..."
"$MONKEYC" \
    -f "$PROJECT_DIR/monkey.jungle" \
    -d fr265 \
    -o "$OUTPUT_FILE" \
    -y "$DEV_KEY" \
    -w

if [ $? -eq 0 ]; then
    echo "=================================="
    echo "✓ 编译成功!"
    echo "输出文件: $OUTPUT_FILE"
    echo "=================================="
else
    echo "=================================="
    echo "✗ 编译失败!"
    echo "=================================="
    exit 1
fi