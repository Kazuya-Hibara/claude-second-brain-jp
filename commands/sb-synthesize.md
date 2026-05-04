---
description: 4 並列 fold で vault を走査し、未命名のパターンを検出して synthesis page を自動生成する。Phase 3.3 shell — JP sub-modes (--meeting-commitments / --proposal-diff / --slack-tldr) は Wave 2 で接続予定の stub。
---
<!-- Adapted from eugeniughelbur/obsidian-second-brain (MIT, commit 69b9acb) -->

`sb-synthesize` skill を読む。次に `/sb-synthesize` を実行する。

このコマンドは手動でも scheduled agent からでも起動できる。vault が自分で考える。

## 起動 mode

```
/sb-synthesize                          # 既定 mode = 4 並列 fold で全 vault scan
/sb-synthesize --meeting-commitments    # JP sub-mode: 議事録から commitment / 期日 / 担当 抽出 (Wave 2 接続)
/sb-synthesize --proposal-diff          # JP sub-mode: 新提案書 vs 過去案件 wiki page diff (Wave 2 接続)
/sb-synthesize --slack-tldr             # JP sub-mode: JP Slack thread → TL;DR + 関係者 + EN 翻訳 alias (Wave 2 接続)
```

## 実行手順 (既定 mode = 4 並列 fold)

1. vault root に `CLAUDE.md` があれば最初に読む
2. `wiki/index.md` を読み、既存 page 一覧を把握する
3. `wiki/log.md` の直近 20 entry を読み、最近の vault activity を確認する

4. **synthesis 機会を 4 並列 subagent で scan** (各 fold は独立、results は最後に集約):

   - **cross-source agent**: 過去 7 日に ingest された source (`.raw/`、`tests/fixtures/sb-synthesize/cross-source/` 等) を読み、2 つ以上の **無関係な** source に登場する concept を探す。同一 idea がポッドキャスト書き起こし AND 記事 AND daily note に出ていれば synthesis 候補
   - **entity convergence agent**: `wiki/entities/` を scan し、複数の context で並んで出現するが connection page を持たない人物を探す。Person A と Person B が同じ project / decision に繰り返し登場するなら、connection note を書く
   - **concept evolution agent**: `wiki/concepts/` を scan し、3 回以上 update された idea を探す。concept がどう evolve したかを timeline で記録し、user の思考変化を "Concept Evolution" section として書き出す
   - **orphan rescue agent**: `wiki/` 配下で inbound link が無い page のうち、本文 claim や言及から既存 page にリンクすべき内容を探す。欠落 link を作成し理由を説明する

5. 各 synthesis hit について:
   - `wiki/concepts/Synthesis — <Title>.md` を以下の frontmatter で作成:
     ```yaml
     ---
     type: concept
     title: "Synthesis — <Title>"
     created: YYYY-MM-DD
     updated: YYYY-MM-DD
     tags: [concept, synthesis]
     auto_generated: true
     Status: ACTIVE
     Last-verified: YYYY-MM-DD
     Half-life: 30d
     ---
     ```
   - 何の pattern を検出したか / どの source・page から来たか (link 付き) / 意味 / 推奨アクション を記述
   - 参照元 note 群 **から** synthesis page **へ** の link も追加 (双方向)

6. `wiki/index.md` を新 synthesis page で更新
7. `wiki/log.md` の **先頭** に append: `## [YYYY-MM-DD] sb-synthesize | X synthesis pages created, Y orphans rescued, Z connections found`
8. 当日の daily note があれば "Synthesis" section を追加し、今回の hit summary を 2-3 行で書く

vault は自分で insight を生む。聞かれた時だけでなく、自分の schedule で。

---

## JP Sub-modes (Wave 2 接続予定、本 shell では stub)

`--meeting-commitments` / `--proposal-diff` / `--slack-tldr` の各 flag は **Phase 2.3 (Wave 2)** で sub-mode prompt fold が接続される。本 shell (Phase 3.3) では stub として以下の error を返して exit 1 する:

```
[sb-synthesize] sub-mode "<flag>" is not wired yet. Wave 2 (Phase 2.3) will connect the prompt fold. See skills/sb-synthesize/SKILL.md "JP Sub-mode Hook" section.
```

接続後は各 sub-mode の fixture (`tests/fixtures/sb-synthesize/jp-meeting-minutes.md` 等) が acceptance test の起点になる。

---

**AI-first rule**: このコマンドが作成・更新する全 note は wiki の AI-first 規約に従う:
- frontmatter 必須 (`type` / `title` / `created` / `updated` / `tags` / `Status` / `Last-verified` / `Half-life`)
- 外部 claim には recency marker
- 言及される全 person / project / concept は `[[wikilink]]`
- source は URL とともに verbatim で保持
- 該当時は confidence level を明記

vault は **未来の Claude の retrieval のため** であり、人間の reading のためではない。
