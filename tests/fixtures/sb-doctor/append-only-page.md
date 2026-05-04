---
type: concept
title: "Append-only テスト: rewrite 痕跡なし"
created: 2026-04-01
updated: 2026-05-05
tags: [test, sb-doctor]
Status: ACTIVE
Last-verified: 2026-05-05
Half-life: 30d
---

<!-- acceptance: /sb-doctor がこのファイルに対して
     Category 5 (Append-only check) で 🟡 WARN を出力すること。
     log.md に対応する ingest エントリで Pages updated: が空のまま
     Pages created: が 3 件以上のパターンを模擬する。
     "rewrite 痕跡がない append-only パターンを検出" の旨のメッセージが含まれること。
     (Karpathy rewrite principle: REWRITE the vault — don't just append)
-->

# Append-only パターン テスト用ページ

このページは Karpathy rewrite principle 違反のサンプルです。
複数回の ingest で既存ページが一切更新されず、新規ページのみ追加されています。

## 模擬 log.md エントリ (テスト用参考)

以下のようなパターンが wiki/log.md に存在する場合、WARN が発生します:

```
## [2026-04-29] ingest | Source A
- Pages created: [[Page 1]], [[Page 2]], [[Page 3]]
- Pages updated:

## [2026-04-30] ingest | Source B
- Pages created: [[Page 4]], [[Page 5]]
- Pages updated:

## [2026-05-01] ingest | Source C
- Pages created: [[Page 6]], [[Page 7]], [[Page 8]]
- Pages updated:
```

3回連続で `Pages updated:` が空 → 🟡 WARN (Append-only Anti-pattern)

## 期待される診断

- 🟡 WARN: `3回以上連続で Pages updated: が空 — rewrite 規律が低下しています`
- 推奨アクション: 直近の ingest ソースを再読み込みし、手動 rewrite パスを実行
