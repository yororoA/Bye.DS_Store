# Bye.DS_Store

## 自动让 Mac 文件夹远离 `.DS_Store`

Bye.DS_Store 是一款免费开源的原生 macOS 菜单栏工具：你继续使用 Finder，它在后台自动清理不需要留下的 `.DS_Store` 文件。

[简体中文](README.md) · [繁體中文](README.zh-Hant.md) · [English](README.en.md) · [日本語](README.ja.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)

[下载最新 Apple Silicon DMG](https://github.com/yororoA/Bye.DS_Store/releases/latest) · [打开宣传页](https://bye-dsstore.yororoice.top/) · [查看源代码](https://github.com/yororoA/Bye.DS_Store)

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-0d171c?logo=apple&logoColor=white)
![Swift 6](https://img.shields.io/badge/Swift-6-00a994?logo=swift&logoColor=white)
![GitHub release](https://img.shields.io/github/v/release/yororoA/Bye.DS_Store?display_name=tag&color=f0aa3c)
![MIT License](https://img.shields.io/badge/license-MIT-00a994.svg)

**适合这些场景：**

- Git、Xcode、VS Code、Unity、Web 项目和外接 SSD 中反复出现 `.DS_Store`；
- 希望自动清理，但不想安装常驻 Dock 应用或运行危险的全盘删除脚本；
- 需要一个原生 Swift 工具，清楚展示扫描范围、失败路径和权限边界。

## 一眼看懂

| 你关心的事 | Bye.DS_Store 的做法 |
| --- | --- |
| 会不会打扰工作？ | 常驻菜单栏，跟随 Finder，后台安静运行 |
| 会不会乱删？ | 后台只处理 Finder 监控目录；全盘扫描必须手动确认 |
| 能不能控制范围？ | 支持父目录、磁盘范围、排除规则和符号链接跳过 |
| 能不能复核？ | 展示扫描数量、删除数量和失败路径 |

## 核心能力

| 能力 | 说明 |
| --- | --- |
| Finder 监听 | 读取当前 Finder 窗口目标，多窗口自动去重 |
| 延续清理 | 文件夹关闭后默认继续清理 60 秒 |
| 清理范围 | 默认处理被监控文件夹及其直接父文件夹，也可切换为仅处理当前文件夹 |
| 全盘扫描 | 手动扫描启动盘、外接盘、网络盘或全部已挂载磁盘 |
| 排除规则 | 用 `node_modules` 或 `lib/packages` 等名称/路径排除目录 |
| 安全边界 | 扫描前确认、扫描中可停止、扫描后查看失败路径 |
| 菜单栏体验 | 不占用 Dock，支持 `⌘⌥B` 全局快捷键 |
| 多语言 | 系统自动识别，也可固定为简体中文、繁體中文、English、日本語、Deutsch 或 Русский |

## 为什么默认包含父文件夹？

实机测试发现，`.DS_Store` 经常在进入子文件夹时写入原始文件夹，而不是直接写入当前打开文件夹的根目录。因此默认清理范围包含：

1. 当前被 Finder 监控的文件夹
2. 它的直接父文件夹

应用不会向更高层递归，也不会自动遍历子文件夹。

## 全盘扫描与安全设置

全盘扫描是一次明确的手动操作，不会加入后台轮询。扫描会：

- 跳过符号链接，避免重复进入外部目录树；
- 跳过已配置的排除目录及其子目录；
- 记录扫描项目、发现数量、删除数量和失败数量；
- 在访问受保护目录时保留失败信息，而不是中断整个扫描。

部分系统目录可能需要在“隐私与安全性”中授予**完整磁盘访问权限**。

## 排除规则

在设置页输入文件夹名称或组合路径并按回车：

```text
node_modules
lib/packages
```

规则会变成可移除标签。初始规则包含常见依赖和构建目录：

```text
node_modules、.venv、venv、__pycache__、vendor、Pods、target、.gradle
```

## 运行要求

- macOS 14 或更高版本
- Xcode 16 或更新版本
- Swift 6 工具链

## 本地运行

```bash
./scripts/run-app.sh
```

仅构建：

```bash
./scripts/build-app.sh
```

运行测试：

```bash
swift test --disable-index-store
```

构建产物位于 `dist/Bye.DS_Store.app`。

## 首次授权

首次启动时，macOS 会询问是否允许 Bye.DS_Store 控制 Finder。该权限只用于读取 Finder 窗口当前目录。

如果之前拒绝过授权：

```text
系统设置 > 隐私与安全性 > 自动化 > Bye.DS_Store > Finder
```

删除桌面、文稿、下载等受保护位置中的文件时，系统还可能要求单独的文件访问权限。

## Release 与 GitHub Actions

推送版本标签即可触发自动发布：

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

工作流会运行测试、构建 macOS 应用、生成 zip/DMG 及 SHA-256 校验文件，并在配置 Apple Developer secrets 时执行 Developer ID 签名和 notarization。

对应版本的 Release 说明放在：

```text
.github/release-notes/<tag>.md
```

宣传页通过 GitHub Pages 发布到 [bye-dsstore.yororoice.top](https://bye-dsstore.yororoice.top/)。Pages workflow 会在部署时读取最新 Release，自动更新页面上的版本号和 DMG 下载地址。

## 许可证

本项目采用 [MIT License](LICENSE)。

## 项目结构

```text
Sources/SweeperCore/       文件夹状态、清理范围与 .DS_Store 删除逻辑
Sources/DSStoreSweeper/    Finder 集成、菜单栏 UI、设置与应用生命周期
Tests/SweeperCoreTests/    核心行为测试
Support/Info.plist         macOS 应用包配置
scripts/                   构建与启动脚本
site/                      GitHub Pages 宣传页
.github/workflows/         Release 与 Pages 自动化
```
