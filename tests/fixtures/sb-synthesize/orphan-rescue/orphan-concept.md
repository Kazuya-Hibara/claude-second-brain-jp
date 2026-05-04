---
type: concept
title: "オーケストレーション疲労"
created: 2026-04-25
updated: 2026-04-25
tags: [concept, domain/ai-agent]
Status: ACTIVE
Last-verified: 2026-04-25
Half-life: 30d
---

<!--
Acceptance 意図:
orphan-rescue fixture (1/2)。このページは inbound wikilink を持たない
孤立した concept page。本文中で [[山田 太郎]] / [[自律ループ]] を
"明示的に" 言及している (= 既存ページに接続できる claim を持つ)
にもかかわらず orphan のまま放置されている。

orphan-rescue agent はこのページを検出し、
- 既存の [[山田 太郎]] entity page から本ページへの link
- 既存の [[自律ループ]] concept page から本ページへの link
を提案 (= rescue) すべき。
-->

# オーケストレーション疲労

## 定義

複数の自律エージェントを同時並行で運用する人間オペレーターが、
状態追跡の cognitive load で意思決定品質を落とす現象。

## 発生条件

- 3 つ以上のエージェントが並行稼働
- 観測ダッシュボードが複数画面に分散
- 人間介入点の閾値が個別設定

## 関連概念 (本来 link されるべき)

[[山田 太郎]] のインタビューでも触れられていた "[[自律ループ]] 疲労" と
本質的に同じ問題。複数ループを同時に観測する負荷を指す。

## 緩和策

- 統合ダッシュボード
- 介入点の閾値を一元管理
- ループ毎の自動停止条件
