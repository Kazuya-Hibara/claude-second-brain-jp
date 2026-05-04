<!--
Acceptance test 意図 (sb-reconcile fixture pair: evidence-clear, page B = WINNER):

  対象 entity: "LLM Wiki Pattern" (concept page、相手 = conflict-evidence-clear-1)
  競合主張: hot.md 推奨サイズ = "300 words" と断定 (※ペア相手は "500 words")
  Winner 側の特徴 (evidence-based judge が即座に判定可能なシグナル):
    - Last-verified が 2026-04-15 (今日 2026-05-05 から見て Half-life 30d 内)
    - Status: ACTIVE で半減期内 → 信頼度高
    - Source: Karpathy 本人の primary post (2026-04-10、1 次ソース)
    - Source date: 2026-04-10 (相手の 2025-10-15 より 6 ヶ月新しい)
    - 「JP solo founder の小 context window 向け最適化」という具体的根拠を伴う
  期待挙動:
    - sb-reconcile がこの page を winner と確定
    - 敗者 (clear-1) の主張は loser 側 page の ## History section に格納
    - --evidence-only mode でも自動 winner 判定 (ambiguous ではない)
-->
---
type: concept
title: "LLM Wiki Pattern (hot.md size) — clear-2"
created: 2026-04-10
updated: 2026-04-15
tags: [domain/wiki, concept]
Status: ACTIVE
Last-verified: 2026-04-15
Half-life: 30d
sources:
  - "[[fixture-source-karpathy-primary]]"
---

# LLM Wiki Pattern — hot.md 推奨サイズ

`wiki/hot.md` の推奨サイズは **300 words** とする。JP solo founder の小 context window 向けに、upstream の ~500 words より厳しく絞る。300 words 超過分は `wiki/hot-week.md` に bleed させる運用が最適。

## 主張

- hot.md は 300 words までに絞る。
- 小 context window モデル (Sonnet/Haiku) でも session 開始の Layer 1 read が軽量に済む。
- overflow は週次集約 (hot-week.md, 500 words 上限) に逃がす。

## Sources

引用元: Karpathy 本人の primary post ([[fixture-source-karpathy-primary]]、2026-04-10、1 次ソース)。
