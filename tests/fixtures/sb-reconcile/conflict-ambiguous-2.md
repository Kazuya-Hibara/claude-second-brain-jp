<!--
Acceptance test 意図 (sb-reconcile fixture pair: ambiguous, page B):

  対象 entity: "Business Hours Schema timezone" (concept page、相手 = conflict-ambiguous-1)
  競合主張: 推奨デフォルト timezone = "Asia/Osaka" (※ペア相手は "Asia/Tokyo")
  Ambiguous シグナル (どちらが winner か evidence では決められない):
    - Last-verified が同日 (2026-04-30) — Half-life も同 30d、両方とも freshness 内
    - Status は両方とも ACTIVE
    - Source は両方とも同種 (内部 ADR 文書、同じ peer-review tier)
    - Source date は両方とも 2026-04-29 (1 日違いも無し)
    - どちらも具体的根拠を 1 個だけ持つ (片方=東京本社多数、片方=大阪本社多数)
  期待挙動:
    - default mode: user に confirm prompt を出す ("どちらを採用?" の 2 択 + skip)
    - --evidence-only mode: untouched (両 page そのまま、Lead に skip 報告)
    - --interactive flag (opt-in): user prompt を強制的に出す
    - History section への自動移動は発生しない (winner 不確定のため)
-->
---
type: concept
title: "Business Hours Schema timezone — ambiguous-2"
created: 2026-04-25
updated: 2026-04-30
tags: [domain/business-hours, concept]
Status: ACTIVE
Last-verified: 2026-04-30
Half-life: 30d
sources:
  - "[[fixture-adr-osaka-default]]"
---

# Business Hours Schema timezone — 推奨デフォルト

CLAUDE.md の `business_hours.timezone` 推奨デフォルトは **Asia/Osaka** とする。

## 主張

- 関西圏の中小企業顧客向けには大阪本社がデフォルトのほうが UX 上自然 (内部 ADR で集計)。
- IANA tz database では Asia/Osaka も valid identifier。

## Sources

引用元: 内部 ADR ([[fixture-adr-osaka-default]]、2026-04-29)。
