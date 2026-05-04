---
description: 4 並列 fold で vault を走査し、未命名のパターンを検出して synthesis page を自動生成する。JP business 向け 3 sub-mode (--meeting-commitments / --proposal-diff / --slack-tldr) を備える。
---
<!-- Adapted from eugeniughelbur/obsidian-second-brain (MIT, commit 69b9acb) -->

`sb-synthesize` skill を読む。次に `/sb-synthesize` を実行する。

このコマンドは手動でも scheduled agent からでも起動できる。vault が自分で考える。

## 起動 mode

```
/sb-synthesize                                          # 既定 mode = 4 並列 fold で全 vault scan
/sb-synthesize --meeting-commitments <path>             # 議事録から commitment / 期日 / 担当 を抽出
/sb-synthesize --proposal-diff <path>                   # 新提案書 vs 過去案件 の diff + 推奨セクション
/sb-synthesize --slack-tldr <path>                      # JP Slack thread → TL;DR + 関係者 + 任意 EN 翻訳 alias
```

### Sub-mode 概要

- **`--meeting-commitments`**: 議事録 markdown を読み、JP 動詞パターン (「〜と決定」「〜が承認」「〜することにした」「〜とする」) で commitment を検出。近傍行の「期限: YYYY-MM-DD」「担当: <氏名>」をペアで抽出し、`commitment / 期日 / 担当` の 3 列 structured output (Markdown table) を生成する。「議論した」「検討中」「保留」は除外。
- **`--proposal-diff`**: 新提案書 (NEW) と過去案件 wiki page (PAST) を読み比較。価格・納期・SLA・オプション機能・契約条項などの差分を抽出し、各差分に **重要度 (HIGH/MEDIUM/LOW)** + **推奨 (取り込み / 却下 / 要検討)** + 1-2 行の理由を付与した推奨セクションを提示する。過去案件の成功/失敗の振り返りを根拠として活用。
- **`--slack-tldr`**: JP Slack thread を読み、(1) 3-5 行の日本語 TL;DR、(2) 関係者 list (各人 1 行で立場明記)、(3) frontmatter `translate_to_en: true` がある時のみ TL;DR の EN 翻訳 alias、を生成する。

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

## JP Sub-modes 詳細

`--meeting-commitments` / `--proposal-diff` / `--slack-tldr` は Phase 2.3 (Wave 2) で接続済。各 sub-mode の prompt fold 設計と acceptance criteria は `skills/sb-synthesize/SKILL.md` の **「JP Sub-mode prompt fold (Wave 2 / Phase 2.3 接続済)」** section を参照。

各 sub-mode の fixture は `tests/fixtures/sb-synthesize/` 配下:
- `jp-meeting-minutes.md` (`--meeting-commitments`)
- `jp-proposal-vs-past.md` (`--proposal-diff`)
- `jp-slack-thread.md` (`--slack-tldr`)

---

**AI-first rule**: このコマンドが作成・更新する全 note は wiki の AI-first 規約に従う:
- frontmatter 必須 (`type` / `title` / `created` / `updated` / `tags` / `Status` / `Last-verified` / `Half-life`)
- 外部 claim には recency marker
- 言及される全 person / project / concept は `[[wikilink]]`
- source は URL とともに verbatim で保持
- 該当時は confidence level を明記

vault は **未来の Claude の retrieval のため** であり、人間の reading のためではない。
