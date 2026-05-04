---
type: concept
title: "Half-life テスト: Last-verified 期限切れ"
created: 2026-01-01
updated: 2026-01-15
tags: [test, sb-doctor]
Status: ACTIVE
Last-verified: 2026-01-15
Half-life: 14d
---

<!-- acceptance: /sb-doctor がこのファイルに対して
     Category 2 (Memory freshness) で 🟡 WARN を出力すること。
     Last-verified (2026-01-15) から Half-life (14d) = 2026-01-29 が期限。
     2026-05-05 時点で 96 日以上超過しているため WARN 検出が期待される。
     "Last-verified が Half-life を超過" の旨のメッセージが含まれること。
     Safe-auto fix 提案 (再検証推奨 or SUPERSEDED マーク) が表示されること。
-->

# 期限切れ Memory Freshness ページ (テスト用)

このページは `Last-verified: 2026-01-15` / `Half-life: 14d` に設定されており、
現在日付 (2026-05-05) では大幅に期限超過しています。

`/sb-doctor` の Memory freshness チェック (Category 2) で検出されるべきサンプルです。

## 期限計算

- Last-verified: 2026-01-15
- Half-life: 14d
- 期限日: 2026-01-29
- 現在日: 2026-05-05
- 超過日数: 96 日以上

## 期待される診断

- 🟡 WARN: `Last-verified が Half-life を超過 (96+ 日超過)`
- 提案: `cheap-disproof を実施して Status を更新するか、SUPERSEDED にマーク`
