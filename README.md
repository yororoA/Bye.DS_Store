# Bye.DS_Store

[English](README.en.md)

一个常驻 macOS 菜单栏的轻量工具。它定时读取 Finder 当前打开的文件夹，并清理相关目录中的 `.DS_Store`。Finder 窗口关闭或切换到其他目录后，原目录会在设定的宽限期内继续参与清理。

## 项目目标

- [x] 监听活跃文件夹
- [x] 延期监听近期活跃文件夹
- [x] 清理活跃文件夹中的 `.DS_Store`
- [ ] 扫描本机所有已有 `.DS_Store` 并清除

最后一项暂未实现。当前应用只清理通过 Finder 监听到的相关目录，不扫描整块磁盘。

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

### 为什么包含父文件夹

经实机排查，`.DS_Store` 不会直接生成在被打开文件夹的根目录，而是主要在进入其子文件夹时生成在原目录。因此默认清理范围包含被监控文件夹及其直接父文件夹。

## Finder 监听范围与限制

macOS 的 Finder AppleScript 接口只公开每个 Finder 窗口当前标签页的目标目录，无法枚举同一窗口中未激活的标签页。本应用也不会尝试读取其他应用内部打开的目录。

因此，未激活的 Finder 标签页可能要等到切换为当前标签页后才能被检测到。

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

删除桌面、文稿、下载或其他受保护位置中的文件时，macOS 还可能单独询问文件访问权限。菜单中的橙色错误状态会显示无法删除的具体目录。

## GitHub Release

仓库包含 `.github/workflows/release.yml` 工作流。

推送版本标签后，GitHub Actions 会自动测试、构建并发布 Release：

```bash
git tag v1.0.0
git push origin v1.0.0
```

工作流会：

1. 执行 Swift 单元测试。
2. 在 macOS 上构建并校验 `Bye.DS_Store.app`。
3. 将应用打包为 zip 文件。
4. 生成 SHA-256 校验文件。
5. 创建或更新对应标签的 GitHub Release。

构建产物使用 ad hoc 签名，未使用 Apple Developer 证书公证。首次运行时，macOS 可能要求用户手动确认打开。

## 项目结构

```text
Sources/SweeperCore/       目录状态机与 .DS_Store 删除器
Sources/DSStoreSweeper/    Finder 采集、菜单栏 UI 与应用生命周期
Tests/SweeperCoreTests/    核心行为测试
Support/Info.plist         macOS 应用包配置
scripts/                   应用构建与启动脚本
.github/workflows/         GitHub Release 自动发布工作流
```
