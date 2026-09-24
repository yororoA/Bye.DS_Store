import Foundation
import SweeperCore

enum AppLanguage: String, CaseIterable, Sendable {
    case system
    case chinese
    case traditionalChinese
    case english
    case japanese
    case german
    case russian

    @MainActor
    func title(using language: AppLanguage) -> String {
        switch self {
        case .system:
            return AppStrings.text("跟随系统", "System default", language: language)
        case .chinese:
            return "简体中文"
        case .traditionalChinese:
            return "繁體中文"
        case .english:
            return "English"
        case .japanese:
            return "日本語"
        case .german:
            return "Deutsch"
        case .russian:
            return "Русский"
        }
    }
}

@MainActor
enum AppStrings {
    static var preferredLanguage: AppLanguage = .system

    private static let translations: [String: [AppLanguage: String]] = [
        "System default": [
            .traditionalChinese: "跟隨系統",
            .japanese: "システムに従う",
            .german: "Systemstandard",
            .russian: "Системный язык"
        ],
        "Scan the startup disk?": [
            .traditionalChinese: "要掃描啟動磁碟嗎？",
            .japanese: "起動ディスクをスキャンしますか？",
            .german: "Startvolume scannen?",
            .russian: "Сканировать загрузочный диск?"
        ],
        "Scan and clean": [
            .traditionalChinese: "掃描並清理",
            .japanese: "スキャンして削除",
            .german: "Scannen und bereinigen",
            .russian: "Сканировать и очистить"
        ],
        "Cancel": [
            .traditionalChinese: "取消",
            .japanese: "キャンセル",
            .german: "Abbrechen",
            .russian: "Отмена"
        ],
        "This recursively scans and permanently deletes .DS_Store files on the startup disk. It may take a while.": [
            .traditionalChinese: "這會遞迴掃描並直接刪除啟動磁碟上的 .DS_Store，可能需要一些時間。",
            .japanese: "起動ディスクを再帰的にスキャンし、.DS_Store を完全に削除します。時間がかかる場合があります。",
            .german: "Das Startvolume wird rekursiv gescannt und .DS_Store-Dateien werden dauerhaft gelöscht. Dies kann etwas dauern.",
            .russian: "Загрузочный диск будет рекурсивно просканирован, а файлы .DS_Store удалены безвозвратно. Это может занять время."
        ],
        "Monitoring enabled": [
            .traditionalChinese: "背景監控已開啟",
            .japanese: "監視を有効にしました",
            .german: "Überwachung aktiviert",
            .russian: "Мониторинг включён"
        ],
        "Monitoring paused": [
            .traditionalChinese: "背景監控已暫停",
            .japanese: "監視を一時停止中",
            .german: "Überwachung pausiert",
            .russian: "Мониторинг приостановлен"
        ],
        "Monitoring": [
            .traditionalChinese: "背景監控",
            .japanese: "監視",
            .german: "Überwachung",
            .russian: "Мониторинг"
        ],
        "Finder automation permission denied": [
            .traditionalChinese: "Finder 自動化權限被拒絕",
            .japanese: "Finder の自動化権限が拒否されています",
            .german: "Finder-Automatisierungsberechtigung verweigert",
            .russian: "Отказано в разрешении на автоматизацию Finder"
        ],
        "Unable to read Finder": [
            .traditionalChinese: "無法讀取 Finder",
            .japanese: "Finder を読み取れません",
            .german: "Finder kann nicht gelesen werden",
            .russian: "Не удалось прочитать Finder"
        ],
        "No folders are open in Finder": [
            .traditionalChinese: "Finder 中沒有開啟的資料夾",
            .japanese: "Finder で開いているフォルダはありません",
            .german: "Keine Ordner in Finder geöffnet",
            .russian: "В Finder нет открытых папок"
        ],
        "Shortcut ": [
            .traditionalChinese: "快速鍵 ",
            .japanese: "ショートカット ",
            .german: "Kurzbefehl ",
            .russian: "Сочетание клавиш "
        ],
        "Scan now": [
            .traditionalChinese: "立即掃描",
            .japanese: "今すぐスキャン",
            .german: "Jetzt scannen",
            .russian: "Сканировать сейчас"
        ],
        "Stop disk scan": [
            .traditionalChinese: "停止磁碟掃描",
            .japanese: "ディスクスキャンを停止",
            .german: "Festplattenscan stoppen",
            .russian: "Остановить сканирование диска"
        ],
        "Scan and clean disk": [
            .traditionalChinese: "掃描並清理磁碟",
            .japanese: "ディスクをスキャンして削除",
            .german: "Datenträger scannen und bereinigen",
            .russian: "Сканировать и очистить диск"
        ],
        "Settings": [
            .traditionalChinese: "設定",
            .japanese: "設定",
            .german: "Einstellungen",
            .russian: "Настройки"
        ],
        "Quit": [
            .traditionalChinese: "結束",
            .japanese: "終了",
            .german: "Beenden",
            .russian: "Выйти"
        ],
        "Allow": [
            .traditionalChinese: "允許",
            .japanese: "許可",
            .german: "Erlauben",
            .russian: "Разрешить"
        ],
        "Open": [
            .traditionalChinese: "開啟",
            .japanese: "開く",
            .german: "Offen",
            .russian: "Открыта"
        ],
        "Bye.DS_Store Settings": [
            .traditionalChinese: "Bye.DS_Store 設定",
            .japanese: "Bye.DS_Store 設定",
            .german: "Bye.DS_Store Einstellungen",
            .russian: "Настройки Bye.DS_Store"
        ],
        "Scanning disk...": [
            .traditionalChinese: "正在掃描磁碟...",
            .japanese: "ディスクをスキャン中...",
            .german: "Datenträger wird gescannt ...",
            .russian: "Сканирование диска..."
        ],
        "Enable background monitoring": [
            .traditionalChinese: "啟用背景監控",
            .japanese: "バックグラウンド監視を有効化",
            .german: "Hintergrundüberwachung aktivieren",
            .russian: "Включить фоновый мониторинг"
        ],
        "Polling interval": [
            .traditionalChinese: "掃描間隔",
            .japanese: "確認間隔",
            .german: "Abfrageintervall",
            .russian: "Интервал опроса"
        ],
        "Cleanup grace period": [
            .traditionalChinese: "資料夾關閉後繼續清理",
            .japanese: "フォルダを閉じた後の監視時間",
            .german: "Bereinigungsfrist nach dem Schließen",
            .russian: "Период очистки после закрытия"
        ],
        "Cleanup scope": [
            .traditionalChinese: "清理範圍",
            .japanese: "クリーンアップ範囲",
            .german: "Bereinigungsbereich",
            .russian: "Область очистки"
        ],
        "Interface language": [
            .traditionalChinese: "介面語言",
            .japanese: "インターフェース言語",
            .german: "Oberflächensprache",
            .russian: "Язык интерфейса"
        ],
        "In testing, .DS_Store was usually created in the original folder when entering one of its child folders, rather than directly in the opened folder.": [
            .traditionalChinese: "實機測試顯示，進入子資料夾時，.DS_Store 通常會建立在原始資料夾，而不是直接建立在開啟的資料夾中。",
            .japanese: "実機テストでは、.DS_Store は開いたフォルダ直下ではなく、子フォルダに入った際に元のフォルダへ作成されることが多く確認されました。",
            .german: "Tests auf macOS zeigten, dass .DS_Store beim Öffnen eines Unterordners meist im ursprünglichen Ordner und nicht direkt im geöffneten Ordner erstellt wird.",
            .russian: "Практические тесты показали, что .DS_Store обычно создаётся в исходной папке при входе в подпапку, а не непосредственно в открытой папке."
        ],
        "Disk scan": [
            .traditionalChinese: "磁碟掃描",
            .japanese: "ディスクスキャン",
            .german: "Festplattenscan",
            .russian: "Сканирование диска"
        ],
        "Manually scan the selected disks for .DS_Store files. This may take a while and may require Full Disk Access.": [
            .traditionalChinese: "手動掃描選取的磁碟中的 .DS_Store。可能需要一些時間，並可能需要完整磁碟存取權限。",
            .japanese: "選択したディスクを手動でスキャンして .DS_Store を探します。時間がかかる場合があり、フルディスクアクセスが必要になることがあります。",
            .german: "Durchsucht die ausgewählten Datenträger manuell nach .DS_Store-Dateien. Dies kann dauern und möglicherweise den vollständigen Festplattenzugriff erfordern.",
            .russian: "Вручную просканировать выбранные диски на наличие .DS_Store. Это может занять время и потребовать полного доступа к диску."
        ],
        "Scan locations": [
            .traditionalChinese: "掃描位置",
            .japanese: "スキャン場所",
            .german: "Scanorte",
            .russian: "Места сканирования"
        ],
        "Stop": [
            .traditionalChinese: "停止",
            .japanese: "停止",
            .german: "Stoppen",
            .russian: "Остановить"
        ],
        "Scan status": [
            .traditionalChinese: "掃描狀態",
            .japanese: "スキャン状態",
            .german: "Scanstatus",
            .russian: "Состояние сканирования"
        ],
        "Scan complete": [
            .traditionalChinese: "掃描完成",
            .japanese: "スキャン完了",
            .german: "Scan abgeschlossen",
            .russian: "Сканирование завершено"
        ],
        "Stopped": [
            .traditionalChinese: "已停止",
            .japanese: "停止済み",
            .german: "Gestoppt",
            .russian: "Остановлено"
        ],
        "Complete": [
            .traditionalChinese: "已完成",
            .japanese: "完了",
            .german: "Abgeschlossen",
            .russian: "Завершено"
        ],
        "Items scanned": [
            .traditionalChinese: "掃描項目",
            .japanese: "スキャン項目",
            .german: "Gescannte Elemente",
            .russian: "Просканировано"
        ],
        "Found .DS_Store": [
            .traditionalChinese: "發現 .DS_Store",
            .japanese: ".DS_Store 検出数",
            .german: ".DS_Store gefunden",
            .russian: "Найдено .DS_Store"
        ],
        "Removed": [
            .traditionalChinese: "已刪除",
            .japanese: "削除済み",
            .german: "Entfernt",
            .russian: "Удалено"
        ],
        "View scan details": [
            .traditionalChinese: "檢視掃描詳細資料",
            .japanese: "スキャン詳細を表示",
            .german: "Scandetails anzeigen",
            .russian: "Показать подробности сканирования"
        ],
        "Scan exclusions": [
            .traditionalChinese: "掃描排除",
            .japanese: "スキャン除外",
            .german: "Scan-Ausschlüsse",
            .russian: "Исключения сканирования"
        ],
        "Enter a folder name or a parent/target path. Full-disk scans skip matching folders and all descendants.": [
            .traditionalChinese: "輸入資料夾名稱，或輸入「父資料夾/目標資料夾」路徑。全磁碟掃描遇到符合的資料夾時會跳過整個目錄。",
            .japanese: "フォルダ名、または「親フォルダ/対象フォルダ」のパスを入力してください。フルディスクスキャンでは一致するフォルダとその配下をすべてスキップします。",
            .german: "Gib einen Ordnernamen oder einen Pfad im Format „Elternordner/Zielordner“ ein. Der vollständige Scan überspringt passende Ordner und alle Unterordner.",
            .russian: "Введите имя папки или путь «родительская папка/целевая папка». Полное сканирование пропустит совпадающие папки и всё их содержимое."
        ],
        "e.g. node_modules or lib/packages": [
            .traditionalChinese: "例如 node_modules 或 lib/packages",
            .japanese: "例: node_modules または lib/packages",
            .german: "z. B. node_modules oder lib/packages",
            .russian: "например node_modules или lib/packages"
        ],
        "Add exclusion": [
            .traditionalChinese: "新增排除規則",
            .japanese: "除外ルールを追加",
            .german: "Ausschluss hinzufügen",
            .russian: "Добавить исключение"
        ],
        "Restore defaults": [
            .traditionalChinese: "還原預設規則",
            .japanese: "デフォルトを復元",
            .german: "Standards wiederherstellen",
            .russian: "Восстановить значения по умолчанию"
        ],
        "Clear all": [
            .traditionalChinese: "全部清除",
            .japanese: "すべて消去",
            .german: "Alle löschen",
            .russian: "Очистить всё"
        ],
        "System": [
            .traditionalChinese: "系統",
            .japanese: "システム",
            .german: "System",
            .russian: "Система"
        ],
        "Launch at login": [
            .traditionalChinese: "登入時啟動",
            .japanese: "ログイン時に起動",
            .german: "Bei Anmeldung starten",
            .russian: "Запускать при входе"
        ],
        "Statistics": [
            .traditionalChinese: "統計",
            .japanese: "統計",
            .german: "Statistik",
            .russian: "Статистика"
        ],
        "Currently open": [
            .traditionalChinese: "目前開啟",
            .japanese: "現在開いているフォルダ",
            .german: "Derzeit geöffnet",
            .russian: "Сейчас открыто"
        ],
        "Grace-period folders": [
            .traditionalChinese: "延續清理",
            .japanese: "猶予期間中のフォルダ",
            .german: "Ordner in der Schonfrist",
            .russian: "Папки на отсроченной очистке"
        ],
        "Removed this run": [
            .traditionalChinese: "本次執行已刪除",
            .japanese: "今回削除した数",
            .german: "In diesem Lauf entfernt",
            .russian: "Удалено за этот запуск"
        ],
        "Scan the selected disks?": [
            .traditionalChinese: "要掃描選取的磁碟嗎？",
            .japanese: "選択したディスクをスキャンしますか？",
            .german: "Ausgewählte Datenträger scannen?",
            .russian: "Сканировать выбранные диски?"
        ],
        "This recursively scans and permanently deletes .DS_Store files on the selected disks. It may take a while and may require Full Disk Access.": [
            .traditionalChinese: "這會遞迴掃描並直接刪除選取磁碟中的 .DS_Store，可能需要一些時間，也可能需要完整磁碟存取權限。",
            .japanese: "選択したディスクを再帰的にスキャンし、.DS_Store を完全に削除します。時間がかかる場合があり、フルディスクアクセスが必要になることがあります。",
            .german: "Die ausgewählten Datenträger werden rekursiv gescannt und .DS_Store-Dateien dauerhaft gelöscht. Dies kann dauern und möglicherweise den vollständigen Festplattenzugriff erfordern.",
            .russian: "Выбранные диски будут рекурсивно просканированы, а файлы .DS_Store удалены безвозвратно. Это может занять время и потребовать полного доступа к диску."
        ],
        "Clear all exclusion rules?": [
            .traditionalChinese: "要清除所有排除規則嗎？",
            .japanese: "すべての除外ルールを消去しますか？",
            .german: "Alle Ausschlussregeln löschen?",
            .russian: "Очистить все исключения?"
        ],
        "Clear": [
            .traditionalChinese: "清除",
            .japanese: "消去",
            .german: "Löschen",
            .russian: "Очистить"
        ],
        "Full-disk scans will no longer skip any configured folders.": [
            .traditionalChinese: "全磁碟掃描將不再跳過任何已設定的資料夾。",
            .japanese: "フルディスクスキャンで設定済みのフォルダをスキップしなくなります。",
            .german: "Der vollständige Scan überspringt keine konfigurierten Ordner mehr.",
            .russian: "Полное сканирование больше не будет пропускать настроенные папки."
        ],
        "Finder permission": [
            .traditionalChinese: "Finder 權限",
            .japanese: "Finder の権限",
            .german: "Finder-Berechtigung",
            .russian: "Разрешение Finder"
        ],
        "Waiting to check": [
            .traditionalChinese: "等待檢查",
            .japanese: "確認待ち",
            .german: "Prüfung ausstehend",
            .russian: "Ожидание проверки"
        ],
        "Allowed": [
            .traditionalChinese: "已允許",
            .japanese: "許可済み",
            .german: "Erlaubt",
            .russian: "Разрешено"
        ],
        "Open System Settings": [
            .traditionalChinese: "開啟系統設定",
            .japanese: "システム設定を開く",
            .german: "Systemeinstellungen öffnen",
            .russian: "Открыть системные настройки"
        ],
        "Finder status": [
            .traditionalChinese: "Finder 狀態",
            .japanese: "Finder の状態",
            .german: "Finder-Status",
            .russian: "Состояние Finder"
        ],
        "Scan stopped": [
            .traditionalChinese: "掃描已停止",
            .japanese: "スキャンを停止しました",
            .german: "Scan gestoppt",
            .russian: "Сканирование остановлено"
        ],
        "Done": [
            .traditionalChinese: "完成",
            .japanese: "完了",
            .german: "Fertig",
            .russian: "Готово"
        ],
        "Failed items": [
            .traditionalChinese: "失敗項目",
            .japanese: "失敗した項目",
            .german: "Fehlgeschlagene Elemente",
            .russian: "Ошибочные элементы"
        ],
        "Failures": [
            .traditionalChinese: "失敗列表",
            .japanese: "失敗一覧",
            .german: "Fehler",
            .russian: "Ошибки"
        ],
        "No failures recorded": [
            .traditionalChinese: "沒有記錄到失敗項目",
            .japanese: "失敗した項目はありません",
            .german: "Keine Fehler aufgezeichnet",
            .russian: "Ошибок не обнаружено"
        ],
        "Enter a valid folder name or path, such as node_modules or lib/packages.": [
            .traditionalChinese: "請輸入有效的資料夾名稱或路徑，例如 node_modules、lib/packages。",
            .japanese: "有効なフォルダ名またはパスを入力してください。例: node_modules、lib/packages。",
            .german: "Gib einen gültigen Ordnernamen oder Pfad ein, z. B. node_modules oder lib/packages.",
            .russian: "Введите корректное имя папки или путь, например node_modules или lib/packages."
        ],
        "Startup disk only": [
            .traditionalChinese: "僅啟動磁碟",
            .japanese: "起動ディスクのみ",
            .german: "Nur Startvolume",
            .russian: "Только загрузочный диск"
        ],
        "Startup and external disks": [
            .traditionalChinese: "啟動磁碟和外接磁碟",
            .japanese: "起動ディスクと外部ディスク",
            .german: "Start- und externe Datenträger",
            .russian: "Загрузочный и внешние диски"
        ],
        "Startup and network disks": [
            .traditionalChinese: "啟動磁碟和網路磁碟",
            .japanese: "起動ディスクとネットワークディスク",
            .german: "Start- und Netzwerkdatenträger",
            .russian: "Загрузочный и сетевые диски"
        ],
        "All mounted volumes": [
            .traditionalChinese: "所有已掛載磁碟",
            .japanese: "マウント済みのすべてのボリューム",
            .german: "Alle eingebundenen Datenträger",
            .russian: "Все подключённые тома"
        ],
        "Monitored folder and parent": [
            .traditionalChinese: "監控資料夾及其父資料夾",
            .japanese: "監視対象フォルダと親フォルダ",
            .german: "Überwachter Ordner und Elternordner",
            .russian: "Отслеживаемая папка и родительская"
        ],
        "Monitored folder only": [
            .traditionalChinese: "僅監控資料夾",
            .japanese: "監視対象フォルダのみ",
            .german: "Nur überwachter Ordner",
            .russian: "Только отслеживаемая папка"
        ]
    ]

    @MainActor
    static func resolvedLanguage(for language: AppLanguage? = nil) -> AppLanguage {
        let selectedLanguage = language ?? preferredLanguage
        guard selectedLanguage == .system else {
            return selectedLanguage
        }

        let identifier = Locale.current.identifier.lowercased()
        if identifier.hasPrefix("zh") {
            if identifier.contains("hant") || identifier.contains("_tw")
                || identifier.contains("_hk") || identifier.contains("_mo") {
                return .traditionalChinese
            }
            return .chinese
        }

        switch Locale.current.language.languageCode?.identifier {
        case "en":
            return .english
        case "ja":
            return .japanese
        case "de":
            return .german
        case "ru":
            return .russian
        default:
            return .chinese
        }
    }

    @MainActor
    static func isEnglish(for language: AppLanguage? = nil) -> Bool {
        resolvedLanguage(for: language) == .english
    }

    @MainActor
    static func text(
        _ chinese: String,
        _ english: String,
        language: AppLanguage? = nil
    ) -> String {
        switch resolvedLanguage(for: language) {
        case .chinese:
            return chinese
        case .english:
            return english
        case .system:
            return chinese
        case let selectedLanguage:
            return translations[english]?[selectedLanguage] ?? english
        }
    }

    static var monitoringEnabled: String {
        text("后台监控已开启", "Monitoring enabled")
    }

    static var monitoringPaused: String {
        text("后台监控已暂停", "Monitoring paused")
    }

    static var monitoringLabel: String {
        text("后台监控", "Monitoring")
    }

    static var emptyFolders: String {
        text("Finder 中没有打开的文件夹", "No folders are open in Finder")
    }

    static var immediateScan: String {
        text("立即扫描", "Scan now")
    }

    static var settings: String {
        text("设置", "Settings")
    }

    static var quit: String {
        text("退出", "Quit")
    }

    static var fullDiskScan: String {
        text("扫描本机并清理", "Scan and clean disk")
    }

    static var stopScan: String {
        text("停止本机扫描", "Stop disk scan")
    }

    static var scanInProgress: String {
        text("正在扫描本机...", "Scanning disk...")
    }

    static var shortcut: String {
        "⌘⌥B"
    }

    static func monitored(
        _ openCount: Int,
        _ graceCount: Int,
        language: AppLanguage? = nil
    ) -> String {
        switch resolvedLanguage(for: language) {
        case .chinese:
            return graceCount == 0
                ? "正在监控 \(openCount) 个文件夹"
                : "监控 \(openCount) 个，延续清理 \(graceCount) 个"
        case .traditionalChinese:
            return graceCount == 0
                ? "正在監控 \(openCount) 個資料夾"
                : "監控 \(openCount) 個，延續清理 \(graceCount) 個"
        case .english:
            if graceCount == 0 {
                return "Monitoring \(openCount) folder\(openCount == 1 ? "" : "s")"
            }
            return "Monitoring \(openCount), cleaning \(graceCount) recently active"
        case .japanese:
            return graceCount == 0
                ? "\(openCount) 個のフォルダを監視中"
                : "\(openCount) 個を監視中、最近使用した \(graceCount) 個を清掃"
        case .german:
            return graceCount == 0
                ? "Überwache \(openCount) Ordner"
                : "Überwache \(openCount), bereinige \(graceCount) zuletzt aktive"
        case .russian:
            return graceCount == 0
                ? "Отслеживается папок: \(openCount)"
                : "Отслеживается \(openCount), очищаются недавно активные: \(graceCount)"
        case .system:
            return ""
        }
    }

    static func recentCleanup(
        _ count: Int,
        language: AppLanguage? = nil
    ) -> String {
        switch resolvedLanguage(for: language) {
        case .chinese:
            return "最近清理 \(count) 个"
        case .traditionalChinese:
            return "最近清理 \(count) 個"
        case .english:
            return "Last cleanup: \(count)"
        case .japanese:
            return "最近の削除: \(count)"
        case .german:
            return "Zuletzt bereinigt: \(count)"
        case .russian:
            return "Последняя очистка: \(count)"
        case .system:
            return ""
        }
    }

    static func totalCleanup(
        _ count: Int,
        language: AppLanguage? = nil
    ) -> String {
        switch resolvedLanguage(for: language) {
        case .chinese:
            return "累计清理 \(count) 个"
        case .traditionalChinese:
            return "累計清理 \(count) 個"
        case .english:
            return "Total cleaned: \(count)"
        case .japanese:
            return "合計削除: \(count)"
        case .german:
            return "Insgesamt bereinigt: \(count)"
        case .russian:
            return "Всего очищено: \(count)"
        case .system:
            return ""
        }
    }

    static func duration(
        _ interval: TimeInterval,
        language: AppLanguage? = nil
    ) -> String {
        let seconds = Int(interval)
        let selectedLanguage = resolvedLanguage(for: language)

        if seconds < 60 {
            switch selectedLanguage {
            case .chinese:
                return "\(seconds) 秒"
            case .traditionalChinese:
                return "\(seconds) 秒"
            case .english:
                return "\(seconds) sec"
            case .japanese:
                return "\(seconds) 秒"
            case .german:
                return "\(seconds) Sek."
            case .russian:
                return "\(seconds) с"
            case .system:
                return ""
            }
        }

        let minutes = seconds / 60
        switch selectedLanguage {
        case .chinese:
            return "\(minutes) 分钟"
        case .traditionalChinese:
            return "\(minutes) 分鐘"
        case .english:
            return "\(minutes) min"
        case .japanese:
            return "\(minutes) 分"
        case .german:
            return "\(minutes) Min."
        case .russian:
            return "\(minutes) мин"
        case .system:
            return ""
        }
    }

    static func remaining(
        _ seconds: Int,
        language: AppLanguage? = nil
    ) -> String {
        switch resolvedLanguage(for: language) {
        case .chinese:
            return "\(seconds) 秒"
        case .traditionalChinese:
            return "\(seconds) 秒"
        case .english:
            return "\(seconds) sec"
        case .japanese:
            return "\(seconds) 秒"
        case .german:
            return "\(seconds) Sek."
        case .russian:
            return "\(seconds) с"
        case .system:
            return ""
        }
    }

    static func failureSummary(
        _ count: Int,
        language: AppLanguage? = nil
    ) -> String {
        switch resolvedLanguage(for: language) {
        case .chinese:
            return "\(count) 个项目无法访问或删除"
        case .traditionalChinese:
            return "\(count) 個項目無法存取或刪除"
        case .english:
            return "\(count) item(s) could not be accessed or removed"
        case .japanese:
            return "\(count) 件にアクセスまたは削除できませんでした"
        case .german:
            return "\(count) Element(e) konnten nicht gelesen oder entfernt werden"
        case .russian:
            return "Не удалось получить доступ или удалить: \(count)"
        case .system:
            return ""
        }
    }

    static func failureRecordsSummary(
        _ count: Int,
        language: AppLanguage? = nil
    ) -> String {
        switch resolvedLanguage(for: language) {
        case .chinese:
            return "仅显示前 \(count) 条失败记录。"
        case .traditionalChinese:
            return "僅顯示前 \(count) 筆失敗記錄。"
        case .english:
            return "Showing the first \(count) failure records."
        case .japanese:
            return "失敗記録の最初の \(count) 件のみ表示しています。"
        case .german:
            return "Die ersten \(count) Fehler werden angezeigt."
        case .russian:
            return "Показаны первые записи об ошибках: \(count)."
        case .system:
            return ""
        }
    }

    static func scanScopeTitle(
        _ scope: DiskScanScope,
        language: AppLanguage? = nil
    ) -> String {
        switch scope {
        case .startupDisk:
            return text("仅启动磁盘", "Startup disk only", language: language)
        case .externalDisks:
            return text("启动磁盘和外接磁盘", "Startup and external disks", language: language)
        case .networkDisks:
            return text("启动磁盘和网络磁盘", "Startup and network disks", language: language)
        case .allMountedVolumes:
            return text("所有已挂载磁盘", "All mounted volumes", language: language)
        }
    }

    static func cleanupScopeTitle(
        _ scope: CleanupScope,
        language: AppLanguage? = nil
    ) -> String {
        switch scope {
        case .monitoredAndParent:
            return text("被监控文件夹及其父文件夹", "Monitored folder and parent", language: language)
        case .monitoredOnly:
            return text("仅被监控文件夹", "Monitored folder only", language: language)
        }
    }
}
