---
type: concept
title: "Frontmatter テスト: Status 欠落"
created: 2026-05-05
updated: 2026-05-05
tags: [test, sb-doctor]
Last-verified: 2026-05-05
Half-life: 30d
# Status フィールドが意図的に欠落している
---

<!-- acceptance: /sb-doctor がこのファイルに対して
     Category 1 (Frontmatter compliance) で 🟡 WARN を出力すること。
     "Status フィールドが欠落" の旨のメッセージが含まれること。
     Safe-auto fix (Status: ACTIVE を追加) の提案が表示されること。
-->

# Frontmatter 不完全ページ (テスト用)

このページは `Status` フィールドが欠落しているため、
`/sb-doctor` の Frontmatter compliance チェック (Category 1) で検出されるべきサンプルです。

## 意図的な欠落内容

- `Status:` フィールドなし → 🟡 WARN 期待

## 参考

Memory Freshness Gate では `Status` / `Last-verified` / `Half-life` の 3 フィールド全てが必須。
1つでも欠落している場合は WARN として報告する。
