# Garmin Connect IQ SDK 环境信息

## SDK 版本信息
- **SDK 版本**: 8.4.1
- **SDK 构建日期**: 2026-02-03
- **SDK 构建哈希**: e9f77eeaa
- **完整版本标识**: connectiq-sdk-lin-8.4.1-2026-02-03-e9f77eeaa

## 环境配置
- **操作系统**: Linux (Ubuntu/Debian-based)
- **SDK 安装路径**: `/home/buzz-bot/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-8.4.1-2026-02-03-e9f77eeaa`
- **编译器版本**: Connect IQ Compiler version: 8.4.1

## SDK 目录结构
```
connectiq-sdk-lin-8.4.1-2026-02-03-e9f77eeaa/
├── bin/                    # 可执行文件和工具
│   ├── connectiq           # 主命令行工具
│   ├── monkeyc             # Monkey C 编译器
│   ├── monkeybrains.jar    # 核心编译器 JAR 文件 (22.6MB)
│   ├── simulator           # 模拟器可执行文件 (27.9MB)
│   └── ...                 # 其他工具
├── doc/                    # 文档文件
├── resources/              # SDK 资源文件
├── samples/                # 示例项目
├── share/                  # 共享资源
└── templates/              # 项目模板
```

## 关键工具文件
- **monkeybrains.jar**: 22,620,607 bytes (22.6 MB) - 核心编译器
- **simulator**: 27,979,168 bytes (28.0 MB) - 设备模拟器
- **api.db**: 77,917 bytes - API 数据库
- **api.mir**: 1,766,408 bytes - API MIR 文件
- **compilerInfo.xml**: 3,080 bytes - 编译器配置信息

## 编译器功能
- **支持的语言**: Monkey C (专为 Garmin Connect IQ 设计)
- **目标设备**: 支持所有 Garmin Connect IQ 设备，包括 FR265
- **优化级别**: 支持多种优化选项 (0-3, p, z)
- **调试支持**: 完整的调试信息和警告系统

## 环境变量设置
```bash
# SDK 环境变量 (推荐设置)
export GARMIN_CONNECTIQ_SDK=/home/buzz-bot/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-8.4.1-2026-02-03-e9f77eeaa
export PATH=$PATH:$GARMIN_CONNECTIQ_SDK/bin
```

## 兼容性说明
- **目标设备**: Garmin Forerunner 265 (FR265)
- **屏幕分辨率**: 416x416 像素
- **API 级别**: Connect IQ 5.2.0 (对应 SDK 8.4.1)

## 已知问题
- **模拟器兼容性**: 在某些 Linux 发行版上可能存在 libsoup2/libsoup3 冲突
- **解决方案**: 如果模拟器无法启动，可以使用真实设备进行测试

## 项目配置
- **项目类型**: Watch Face (表盘)
- **目标设备**: FR265
- **编译选项**: `-d fr265_sim -w` (启用警告)

## 开发环境验证
- ✅ SDK 安装完整
- ✅ 编译器可用 (`monkeyc --version`)
- ✅ 项目结构符合 SDK 要求
- ⚠️ 模拟器可能存在兼容性问题（需要真实设备测试）

## 参考资料
- [Garmin Connect IQ Developer Documentation](https://developer.garmin.com/connect-iq/)
- [Connect IQ SDK Release Notes](https://developer.garmin.com/connect-iq/sdk-release-notes/)
- [Monkey C Programming Guide](https://developer.garmin.com/connect-iq/monkey-c-programming-guide/)

---
**最后更新**: 2026-02-09 16:44 UTC
**记录人**: Hex