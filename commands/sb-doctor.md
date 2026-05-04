---
description: >
  Obsidian wiki vault の健全性診断を実行する。Frontmatter compliance / Memory freshness /
  hot.md サイズ / index.md 行長 / Append-only 検出 / Time-window guard /
  business_hours schema / Orphan check の 8 カテゴリを OMC severity (🔴 CRITICAL /
  🟡 WARN / ⚪ OK) で報告する。eug obsidian-health fork + JP business preset 統合版。
  トリガー: "sb-doctor", "vault 診断", "wiki 健康チェック", "ヘルスチェック"
---

<!-- Adapted from eugeniughelbur/obsidian-second-brain (MIT, commit 69b9acb) -->

`skills/sb-doctor/SKILL.md` を読み込み、vault 診断ワークフローを実行してください。

## 使い方

- `/sb-doctor` — vault 全体を 8 カテゴリで診断 (標準モード)
- `/sb-doctor --check frontmatter` — Category 1 (Frontmatter compliance) のみ実行
- `/sb-doctor --check freshness` — Category 2 (Memory freshness) のみ実行
- `/sb-doctor --check hot` — Category 3 (hot.md サイズ) のみ実行
- `/sb-doctor --check index` — Category 4 (index.md 行長) のみ実行
- `/sb-doctor --check append-only` — Category 5 (Append-only check) のみ実行
- `/sb-doctor --check time-window` — Category 6 (Time-window guard) のみ実行
- `/sb-doctor --check business-hours` — Category 7 (business_hours schema) のみ実行
- `/sb-doctor --check orphans` — Category 8 (Orphan check) のみ実行
- `/sb-doctor --fix safe` — Safe-auto fix 対象 (🟡 WARN のうち自動修正可能なもの) を一括適用

## 出力フォーマット

診断結果は `wiki/meta/doctor-report-YYYY-MM-DD.md` に保存し、コンソールにサマリを表示します。

```
/sb-doctor 診断結果

🔴 CRITICAL: N 件
🟡 WARN: N 件
⚪ OK: N 件

[詳細は wiki/meta/doctor-report-YYYY-MM-DD.md を参照]
```

vault がまだセットアップされていない場合は「Wiki vault が見つかりません。先に `/wiki` を実行してください。」と案内します。
