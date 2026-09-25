# Bye.DS_Store

## 自動讓 Mac 資料夾遠離 `.DS_Store`

Bye.DS_Store 是免費開源的原生 macOS 選單列工具。你繼續使用 Finder，它會在背景安靜地清理不需要留下的 `.DS_Store`。

[简体中文](README.md) · [繁體中文](README.zh-Hant.md) · [English](README.en.md) · [日本語](README.ja.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)

[下載最新 Apple Silicon DMG](https://github.com/yororoA/Bye.DS_Store/releases/latest) · [開啟宣傳頁](https://bye-dsstore.yororoice.top/) · [查看原始碼](https://github.com/yororoA/Bye.DS_Store)

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-0d171c?logo=apple&logoColor=white)
![Swift 6](https://img.shields.io/badge/Swift-6-00a994?logo=swift&logoColor=white)
![GitHub release](https://img.shields.io/github/v/release/yororoA/Bye.DS_Store?display_name=tag&color=f0aa3c)
![MIT License](https://img.shields.io/badge/license-MIT-00a994.svg)

**適合這些情境：**

- Git、Xcode、VS Code、Unity、Web 專案、NAS 資料夾和外接 SSD 中反覆出現 `.DS_Store`；
- 想自動清理，但不想安裝常駐 Dock 應用程式或執行危險的全盤刪除腳本；
- 需要原生 Swift 工具，清楚展示掃描範圍、失敗路徑和權限邊界。

## 快速了解

| 你在意的事 | Bye.DS_Store 的做法 |
| --- | --- |
| 會不會打擾工作？ | 常駐選單列，跟隨 Finder，安靜地在背景運作 |
| 會不會亂刪？ | 背景清理只處理 Finder 監控目錄；全磁碟掃描必須手動確認 |
| 可以控制範圍嗎？ | 支援父資料夾、磁碟位置、排除規則和符號連結跳過 |
| 可以複核結果嗎？ | 顯示掃描數量、刪除數量和失敗路徑 |

## 核心能力

| 能力 | 說明 |
| --- | --- |
| Finder 監控 | 讀取目前 Finder 視窗目標，多視窗自動去重 |
| 寬限期清理 | 資料夾關閉後預設繼續清理 60 秒 |
| 清理範圍 | 預設處理監控資料夾及其直接父資料夾，也可切換為只處理目前資料夾 |
| 全磁碟掃描 | 手動掃描啟動磁碟、外接磁碟、網路磁碟或所有已掛載磁碟 |
| 排除規則 | 以 `node_modules` 或 `lib/packages` 等名稱/路徑排除資料夾 |
| 安全邊界 | 掃描前確認、掃描中可停止、掃描後檢視失敗路徑 |
| 選單列體驗 | 不佔用 Dock，支援 `⌘⌥B` 全域快速鍵 |
| 多語言 | 自動偵測系統，也可固定為簡體中文、繁體中文、English、日本語、Deutsch 或 Русский |

## 為什麼預設包含父資料夾？

實機測試發現，`.DS_Store` 經常在進入子資料夾時寫入原始資料夾，而不是直接寫入目前開啟資料夾的根目錄。因此預設清理範圍包含：

1. 目前由 Finder 監控的資料夾
2. 它的直接父資料夾

應用程式不會向更高層遞迴，也不會自動遍歷子資料夾。

## 全磁碟掃描與安全設定

全磁碟掃描是一次明確的手動操作，不會加入背景輪詢。掃描會：

- 跳過符號連結，避免重複進入外部目錄樹；
- 跳過已設定的排除資料夾及其子資料夾；
- 記錄掃描項目、發現數量、刪除數量和失敗數量；
- 遇到受保護或無法存取的目錄時保留失敗資訊，不中斷整個掃描。

部分系統目錄可能需要在「隱私權與安全性」中授予**完整磁碟存取權限**。

## 排除規則

在設定頁輸入資料夾名稱或組合路徑並按下 Return：

```text
node_modules
lib/packages
```

規則會變成可移除標籤。初始規則包含常見依賴和建置目錄：

```text
node_modules、.venv、venv、__pycache__、vendor、Pods、target、.gradle
```

## 執行要求

- macOS 14 或更新版本
- Xcode 16 或更新版本
- Swift 6 工具鏈

## 本機執行

```bash
./scripts/run-app.sh
```

僅建置：

```bash
./scripts/build-app.sh
```

執行測試：

```bash
swift test --disable-index-store
```

建置產物位於 `dist/Bye.DS_Store.app`。

## 首次授權

首次啟動時，macOS 會詢問是否允許 Bye.DS_Store 控制 Finder。此權限只用於讀取 Finder 視窗目前所在位置。

如果之前拒絕過授權：

```text
系統設定 > 隱私權與安全性 > 自動化 > Bye.DS_Store > Finder
```

清理桌面、文件、下載等受保護位置中的檔案時，系統也可能要求另外授予檔案存取權限。

## Release 與 GitHub Actions

推送版本標籤即可觸發自動發布：

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

工作流程會執行測試、建置 macOS 應用程式、產生 zip/DMG 與 SHA-256 校驗檔；設定 Apple Developer secrets 後，還會執行 Developer ID 簽署和 notarization。

Release 說明放在：

```text
.github/release-notes/<tag>.md
```

宣傳頁透過 GitHub Pages 發布到 [bye-dsstore.yororoice.top](https://bye-dsstore.yororoice.top/)。Pages workflow 會在部署時讀取最新 Release，自動更新頁面版本和 DMG 下載位址。

## 授權條款

本專案採用 [MIT License](LICENSE)。

## 專案結構

```text
Sources/SweeperCore/       資料夾狀態、清理範圍與 .DS_Store 刪除邏輯
Sources/DSStoreSweeper/    Finder 整合、選單列 UI、設定與應用程式生命週期
Tests/SweeperCoreTests/    核心行為測試
Support/Info.plist         macOS 應用程式封裝設定
scripts/                   建置與啟動腳本
site/                      GitHub Pages 宣傳頁
.github/workflows/         Release 與 Pages 自動化
```
