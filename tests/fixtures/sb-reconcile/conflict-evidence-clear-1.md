<!--
Acceptance test 意図 (sb-reconcile fixture pair: evidence-clear, page A = LOSER):

  対象 entity: "LLM Wiki Pattern" (concept page)
  競合主張: hot.md 推奨サイズ = "500 words" と断定 (※ペア相手は "300 words")
  Loser 側の特徴 (evidence-based judge が即座に判定可能なシグナル):
    - Last-verified が 2025-11-01 (Half-life 30d を 6 ヶ月以上超過 = stale)
    - Status: ACTIVE のままだが半減期超過 → 信頼度低下
    - Source: 引用元が個人 blog (2025-10、Karpathy の元 tweet を要約しただけの 2 次ソース)
    - Source date: 2025-10-15 (相手の 2026-04-XX より 6 ヶ月古い)
  期待挙動 (--evidence-only mode 含む全 mode):
    - sb-reconcile が conflict-evidence-clear-2 を winner と判定
    - この page は loser 側として 敗者主張を ## History section に保持して書き換え
    - --evidence-only mode でもこの pair は触る (ambiguous ではない)
-->
---
type: concept
title: "LLM Wiki Pattern (hot.md size) — clear-1"
created: 2025-10-20
updated: 2025-11-01
tags: [domain/wiki, concept]
Status: ACTIVE
Last-verified: 2025-11-01
Half-life: 30d
sources:
  - "[[fixture-source-blog-secondary]]"
---

# LLM Wiki Pattern — hot.md 推奨サイズ

`wiki/hot.md` の推奨サイズは **500 words** とする。Karpathy の LLM Wiki 設計思想ではこの長さが session-spanning cache として最適とされる。

## 主張

- hot.md は 500 words までが最適である。
- これより短いと session で必要な context が不足する。

## Sources

引用元: 個人 blog の解説記事 ([[fixture-source-blog-secondary]]、2025-10-15、Karpathy の tweet を要約した 2 次ソース)。
