<!--
Acceptance test 意図 (sb-reconcile fixture pair: ambiguous, page A):

  対象 entity: "Business Hours Schema timezone" (concept page)
  競合主張: 推奨デフォルト timezone = "Asia/Tokyo" (※ペア相手は "Asia/Osaka")
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
title: "Business Hours Schema timezone — ambiguous-1"
created: 2026-04-25
updated: 2026-04-30
tags: [domain/business-hours, concept]
Status: ACTIVE
Last-verified: 2026-04-30
Half-life: 30d
sources:
  - "[[fixture-adr-tokyo-default]]"
---

# Business Hours Schema timezone — 推奨デフォルト

CLAUDE.md の `business_hours.timezone` 推奨デフォルトは **Asia/Tokyo** とする。

## 主張

- 顧客企業の本社所在地が東京である割合が高い (内部 ADR で集計)。
- JST 表記は対外コミュニケーションでも標準的。

## Sources

引用元: 内部 ADR ([[fixture-adr-tokyo-default]]、2026-04-29)。
