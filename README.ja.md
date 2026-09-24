# Bye.DS_Store

> Finder のフォルダを、静かにきれいに保つ。

[简体中文](README.md) · [繁體中文](README.zh-Hant.md) · [English](README.en.md) · [日本語](README.ja.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)

[製品ページ](https://bye-dsstore.yororoice.top/) · [最新 Release](https://github.com/yororoA/Bye.DS_Store/releases/latest) · [GitHub](https://github.com/yororoA/Bye.DS_Store)

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-0d171c?logo=apple&logoColor=white)
![Swift 6](https://img.shields.io/badge/Swift-6-00a994?logo=swift&logoColor=white)
![GitHub release](https://img.shields.io/github/v/release/yororoA/Bye.DS_Store?display_name=tag&color=f0aa3c)

Bye.DS_Store は macOS のメニューバーに常駐するネイティブアプリです。Finder で現在開いているフォルダを読み取り、関連する場所の `.DS_Store` を定期的に削除します。ウィンドウを閉じた後も、最近使ったフォルダを一定時間監視します。

## 主な機能

| 機能 | 内容 |
| --- | --- |
| Finder 監視 | 現在の Finder ウィンドウを読み取り、複数ウィンドウを自動で重複排除 |
| 猶予期間 | フォルダを閉じた後も標準で 60 秒間クリーンアップ |
| クリーンアップ範囲 | 標準では監視対象と直接の親フォルダ。対象フォルダのみの設定も可能 |
| ディスク全体のスキャン | 起動ディスク、外部ディスク、ネットワークディスク、全マウントボリュームを手動スキャン |
| 除外ルール | `node_modules` や `lib/packages` などを名前またはパスで除外 |
| 安全な操作 | 開始前の確認、実行中の停止、終了後の失敗パス表示 |
| メニューバー運用 | Dock アイコンなし。グローバルショートカット `⌘⌥B` に対応 |
| 多言語 | システム自動判定、または简体中文 / 繁體中文 / English / 日本語 / Deutsch / Русский を固定 |

## 親フォルダも対象にする理由

macOS の実機テストでは、`.DS_Store` は開いたフォルダの直下ではなく、子フォルダへ入ったときに元のフォルダへ書き込まれることが多く確認されました。そのため標準範囲は次の 2 つです。

1. Finder で現在監視しているフォルダ
2. その直接の親フォルダ

さらに上の階層へは遡らず、子フォルダも自動的には再帰スキャンしません。

## ディスク全体のスキャンと安全性

ディスク全体のスキャンは明示的に開始する手動操作で、バックグラウンド監視とは別に実行されます。

- シンボリックリンクをスキップし、別のディレクトリツリーへ重複して入らない；
- 設定済みの除外フォルダとその配下をスキップ；
- スキャン数、検出数、削除数、失敗数を記録；
- 保護された場所にアクセスできなくても全体を中断せず、失敗情報を表示。

一部のシステムフォルダでは、macOS の「プライバシーとセキュリティ」で**フルディスクアクセス**が必要です。

## 除外ルール

設定画面でフォルダ名または親/対象パスを入力して Return を押します。

```text
node_modules
lib/packages
```

ルールは削除可能なタグになります。初期設定には代表的な依存・生成フォルダが含まれます。

```text
node_modules、.venv、venv、__pycache__、vendor、Pods、target、.gradle
```

## 動作要件

- macOS 14 以降
- Xcode 16 以降
- Swift 6 ツールチェーン

## ローカルで実行

```bash
./scripts/run-app.sh
```

ビルドのみ：

```bash
./scripts/build-app.sh
```

テスト：

```bash
swift test --disable-index-store
```

ビルドされたアプリは `dist/Bye.DS_Store.app` に出力されます。

## 初回権限

初回起動時、macOS は Bye.DS_Store に Finder の操作を許可するか確認します。この権限は Finder ウィンドウの現在位置を読み取るためだけに使用します。

以前拒否した場合：

```text
システム設定 > プライバシーとセキュリティ > オートメーション > Bye.DS_Store > Finder
```

デスクトップ、書類、ダウンロードなど保護された場所の削除には、別途ファイルアクセスの許可が必要になる場合があります。

## Release と GitHub Actions

バージョンタグを push すると自動公開が始まります。

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

ワークフローはテスト、macOS アプリのビルド、zip/DMG と SHA-256 チェックサムの生成を行います。Apple Developer secrets を設定すると Developer ID 署名と notarization も実行します。

Release の説明は次に保存します。

```text
.github/release-notes/<tag>.md
```

製品ページは GitHub Pages の [bye-dsstore.yororoice.top](https://bye-dsstore.yororoice.top/) で公開されます。Pages workflow はデプロイ時に最新 Release を読み取り、表示するバージョンと DMG URL を更新します。

## ライセンス

このプロジェクトは [MIT License](LICENSE) で配布されます。

## プロジェクト構成

```text
Sources/SweeperCore/       フォルダ状態、クリーンアップ範囲、削除ロジック
Sources/DSStoreSweeper/    Finder 連携、メニューバー UI、設定、ライフサイクル
Tests/SweeperCoreTests/    コア動作テスト
Support/Info.plist         macOS アプリバンドル設定
scripts/                   ビルドと起動スクリプト
site/                      GitHub Pages 製品ページ
.github/workflows/         Release と Pages の自動化
```
