# Bye.DS_Store

一个常驻 macOS 菜单栏的轻量工具。它定时读取 Finder 窗口当前指向的文件夹，并删除这些文件夹根目录中的 `.DS_Store`。Finder 窗口关闭或切换到其他目录后，原目录会在设定的宽限期内继续参与清理。

## 行为

- 默认每 5 秒读取一次 Finder 窗口。
- 默认在文件夹关闭后继续清理 60 秒。
- 只删除被监控文件夹根目录中的 `.DS_Store`，不递归遍历子目录。
- 同一个目录被多个窗口打开时只处理一次。
- 暂停监控后不读取 Finder，也不删除文件。
- 扫描间隔和关闭后的延续时间可在设置中调整。
- 支持注册为 macOS 登录项。

macOS 的 Finder AppleScript 接口只公开每个 Finder 窗口当前标签页的目标目录，无法枚举同一窗口中未激活的标签页。本应用也不会尝试读取其他应用内部打开的目录。

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
swift test
./scripts/build-app.sh
```

## 首次授权

首次运行时，macOS 会询问是否允许应用控制 Finder。该权限用于读取 Finder 窗口当前所在目录。

如果拒绝过授权，可在以下位置重新开启：

```text
系统设置 > 隐私与安全性 > 自动化 > Bye.DS_Store > Finder
```

删除桌面、文稿、下载或其他受保护位置中的文件时，macOS 还可能单独询问文件访问权限。菜单中的橙色错误状态会显示无法删除的具体目录。

## 项目结构

```text
Sources/SweeperCore/       目录状态机与 .DS_Store 删除器
Sources/DSStoreSweeper/    Finder 采集、菜单栏 UI 与应用生命周期
Tests/SweeperCoreTests/    核心行为测试
Support/Info.plist         macOS 应用包配置
scripts/                   应用构建与启动脚本
```
