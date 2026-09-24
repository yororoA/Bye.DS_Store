# Bye.DS_Store

[English](README.en.md)

最新版本：[v1.0.3](https://github.com/yororoA/Bye.DS_Store/releases/tag/v1.0.3)

一个常驻 macOS 菜单栏的轻量工具。它定时读取 Finder 当前打开的文件夹，并清理相关目录中的 `.DS_Store`。Finder 窗口关闭或切换到其他目录后，原目录会在设定的宽限期内继续参与清理。

## 项目目标

- [x] 监听活跃文件夹
- [x] 延期监听近期活跃文件夹
- [x] 清理活跃文件夹中的 `.DS_Store`
- [x] 扫描本机所有已有 `.DS_Store` 并清除

全盘扫描是用户手动触发的一次性操作，不会加入活跃文件夹的定时轮询。

## 工作方式

- 默认每 5 秒读取一次 Finder 窗口。
- 默认在文件夹关闭后继续清理 60 秒。
- 默认清理被监控文件夹及其直接父文件夹中的 `.DS_Store`，也可以在设置中切换为仅清理被监控文件夹。
- 清理范围不会向上递归到更高层父目录，也不会递归遍历子目录。
- 同一个目录被多个窗口打开时只处理一次。
- 暂停监控后不读取 Finder，也不删除文件。
- 扫描间隔和关闭后的延续时间可在设置中调整。
- 支持注册为 macOS 登录项。
- 应用以 `Bye` 和状态图标常驻 macOS 顶部菜单栏，不占用 Dock 图标。
- 可手动扫描整块磁盘，查找并清理已有的 `.DS_Store`。
- 全盘扫描过程中可以停止操作。
- 开始全盘扫描前会显示确认提示，避免误触直接删除。
- 扫描结束后可查看扫描数量、删除数量和失败项目列表。
- 全盘扫描支持添加文件夹排除规则，例如 `node_modules`、`lib/packages`。
- 全局快捷键：按 `⌘⌥B`，可在状态栏项目被收起时打开控制面板。
- 状态栏弹窗显示最近清理时间、本轮清理数量和快捷键提示。
- 设置页支持恢复默认排除规则或清空全部规则。
- 全盘扫描支持选择启动磁盘、外接磁盘、网络磁盘或所有已挂载磁盘。
- UI 默认跟随 macOS 系统语言，也可以在设置中固定为中文或 English。

### 为什么包含父文件夹

经实机排查，`.DS_Store` 不会直接生成在被打开文件夹的根目录，而是主要在进入其子文件夹时生成在原目录。因此默认清理范围包含被监控文件夹及其直接父文件夹。

### 全盘扫描

设置页和菜单栏都提供手动全盘扫描入口。扫描从 `/` 开始，包含隐藏文件和应用包内容，跳过符号链接，并显示扫描项目数、删除数量以及访问或删除失败数量。

由于 macOS 会保护部分文件系统目录，全盘扫描可能需要“完整磁盘访问权限”。无法访问的目录会被记录并显示，不会导致整个扫描中断。

开始前会显示确认对话框，完成后可在“查看扫描详情”中查看失败路径和错误信息。

扫描位置可以在设置中选择：

- 仅启动磁盘
- 启动磁盘和外接磁盘
- 启动磁盘和网络磁盘
- 所有已挂载磁盘

### 扫描排除

设置页会将排除规则保存为可移除的名称标签。输入 `node_modules` 这样的文件夹名称，或输入 `lib/packages` 这样的父文件夹/目标文件夹路径后按回车即可添加。扫描遇到匹配的文件夹时，会跳过该文件夹及其全部子目录。

初始排除规则覆盖常见的依赖和生成目录：

```text
node_modules、.venv、venv、__pycache__、vendor、Pods、target、.gradle
```

## Finder 监听范围与限制

macOS 的 Finder AppleScript 接口只公开每个 Finder 窗口当前标签页的目标目录，无法枚举同一窗口中未激活的标签页。本应用也不会尝试读取其他应用内部打开的目录。

因此，未激活的 Finder 标签页可能要等到切换为当前标签页后才能被检测到。

## 全局快捷键

按下 `⌘⌥B`，即可打开 Bye.DS_Store 控制面板。该快捷键在应用不处于前台时也可使用，控制面板通常会显示在状态栏图标旁边。

该快捷键使用 macOS 原生全局快捷键注册，不需要额外的辅助功能授权。

## 界面语言

设置页的“界面语言”提供三个选项：

- 跟随系统
- 中文
- English

语言选择会保存到本机，并立即应用到菜单栏弹窗、设置窗口、确认框和扫描详情。

## 系统要求

- macOS 14 或更高版本
- Xcode 16 或更新版本
- Swift 6 工具链

## 构建与运行

```bash
./scripts/run-app.sh
```

构建后的应用位于：

```text
dist/Bye.DS_Store.app
```

也可以只运行测试或只构建应用：

```bash
swift test --disable-index-store
./scripts/build-app.sh
```

## 首次授权

首次运行时，macOS 会询问是否允许应用控制 Finder。该权限用于读取 Finder 窗口当前所在目录。

如果拒绝过授权，可在以下位置重新开启：

```text
系统设置 > 隐私与安全性 > 自动化 > Bye.DS_Store > Finder
```

删除桌面、文稿、下载或其他受保护位置中的文件时，macOS 还可能单独询问文件访问权限。全盘扫描可能需要“完整磁盘访问权限”。菜单中的橙色错误状态会显示无法删除的具体目录。

## GitHub Release

仓库包含 `.github/workflows/release.yml` 工作流。

推送版本标签后，GitHub Actions 会自动测试、构建并发布 Release：

```bash
git tag v1.0.3
git push origin v1.0.3
```

工作流会：

1. 执行 Swift 单元测试。
2. 在 macOS 上构建并校验 `Bye.DS_Store.app`。
3. 将应用打包为 zip 和 DMG 文件。
4. 生成两个安装包的 SHA-256 校验文件。
5. 如果配置 Apple Developer secrets，则使用 Developer ID 签名并 notarize DMG。
6. 创建或更新对应标签的 GitHub Release。

要启用签名和 notarization，需要在 GitHub Actions secrets 中配置：

```text
APPLE_CERTIFICATE_BASE64
APPLE_CERTIFICATE_PASSWORD
APPLE_KEYCHAIN_PASSWORD
APPLE_DEVELOPER_IDENTITY
APPLE_ID
APPLE_TEAM_ID
APPLE_APP_PASSWORD
```

如果仓库中存在 `.github/release-notes/<tag>.md`，工作流会使用该文件作为 Release 介绍；否则自动生成变更说明。

构建产物使用 ad hoc 签名，未使用 Apple Developer 证书公证。首次运行时，macOS 可能要求用户手动确认打开。

## 项目结构

```text
Sources/SweeperCore/       目录状态机与 .DS_Store 删除器
Sources/DSStoreSweeper/    Finder 采集、菜单栏 UI 与应用生命周期
Tests/SweeperCoreTests/    核心行为测试
Support/Info.plist         macOS 应用包配置
scripts/                   应用构建与启动脚本
.github/workflows/         GitHub Release 自动发布工作流
.github/release-notes/     按版本保存的 Release 介绍
```
