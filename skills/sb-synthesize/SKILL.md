---
name: sb-synthesize
description: >
  vault の未命名パターンを 4 並列 fold (cross-source / entity convergence / concept evolution / orphan rescue)
  で検出し、synthesis page を自動生成する。聞かれた時だけでなく schedule でも走る。
  JP business 向け 3 sub-mode (--meeting-commitments / --proposal-diff / --slack-tldr) を
  備える (Wave 2 / Phase 2.3 で接続済)。
  Triggers on: "/sb-synthesize", "synthesize the vault", "find unnamed patterns",
  "vault に潜むパターン抽出", "sb-synthesize", "auto synthesis", "scheduled synthesis",
  "議事録 commitment 抽出", "提案書 diff", "Slack thread TL;DR".
allowed-tools: Read Write Edit Glob Grep Bash Task
---
<!-- Adapted from eugeniughelbur/obsidian-second-brain (MIT, commit 69b9acb) -->

# sb-synthesize: 4 並列 fold で vault を考えさせる

このスキルは vault に「自分で insight を生ませる」ための fold dispatch shell。`/sb-synthesize` command の implementation backbone。

源流: [eugeniughelbur/obsidian-second-brain](https://github.com/eugeniughelbur/obsidian-second-brain) `commands/obsidian-synthesize.md` (commit `69b9acb`、MIT)。本 fork (claude-second-brain-jp) では JP business 向け sub-mode hook を追加し、4 fold は eug 版の構造を踏襲。

---

## Pre-flight

実行前に以下を Read:

1. vault root の `CLAUDE.md` (存在すれば)
2. `wiki/index.md` (既存 page 一覧)
3. `wiki/log.md` の直近 20 entry (最近の vault activity)

これらは 4 fold subagent への briefing material となる。

---

## Mode dispatch (top-level)

```
/sb-synthesize                                       → run_default_4_fold()
/sb-synthesize --meeting-commitments <path>          → run_meeting_commitments(path)
/sb-synthesize --proposal-diff <path>                → run_proposal_diff(path)
/sb-synthesize --slack-tldr <path>                   → run_slack_tldr(path)
```

mode 判定は flag の literal match。複数 flag は許可しない (`mutually exclusive`)。sub-mode は引数として input file path を受け取る (例: `tests/fixtures/sb-synthesize/jp-meeting-minutes.md`)。

---

## Default mode: 4 並列 fold

**設計原則**: 4 fold は **並列・独立** で動作させる。各 fold は他 fold の出力を待たない。最後に Lead が unified report に集約する。

`Task` tool で 4 つの subagent を **single message multi tool call** で同時 spawn する (CLAUDE.md `<execution_protocols>` "2+ independent tasks in parallel"、`rules/subagent-parallel-dispatch.md` の Default Parallel Batch)。

### Fold 1: cross-source agent

**Goal**: 過去 7 日以内に ingest された source (`.raw/` + `tests/fixtures/sb-synthesize/cross-source/` 等) を読み、**2+ の無関係な source に登場する concept** を抽出。

**Input**:
- vault root の `.raw/` 配下 (`find .raw/ -mtime -7 -type f` 想定)
- `wiki/sources/` 配下の最近 page
- (test 環境では) `tests/fixtures/sb-synthesize/cross-source/` 配下 3 page

**Detection criterion**:
- 同一 concept (= 同一名詞句 or 同一 wikilink target) が異なる source kind (podcast / article / daily-note / 議事録 等) に **2 回以上** 出現
- 各 source の `tags` / `source_kind` frontmatter で「無関係」を判定 (同一 tag 集合は redundant、異なる tag 集合に同一 concept がある場合に hit)

**Output (= synthesis page draft)**:
- `wiki/concepts/Synthesis — <concept-name>.md`
- 本文: 検出 concept / 出現 source の wikilink list / 共通 entity / 推奨アクション

### Fold 2: entity convergence agent

**Goal**: `wiki/entities/` の人物群のうち、**複数 context で並んで出現** するが connection page を持たないペアを抽出。

**Input**:
- `wiki/entities/*.md` 全件
- 各 entity の inbound link 元 page (`wiki/projects/` / `wiki/decisions/` 等)

**Detection criterion**:
- Person A と Person B が同一 project / decision page に **2 回以上** 共起
- かつ、両者を結ぶ explicit connection page (`Connection — A & B.md` 等) が **存在しない**

**Output**:
- `wiki/concepts/Synthesis — <A> × <B> connection.md`
- 本文: 共起 page list / 共通 domain / 共著・協業の事実があれば明記

### Fold 3: concept evolution agent

**Goal**: `wiki/concepts/` の idea のうち、**3 回以上 update された** ものの evolution timeline を書き出す。

**Input**:
- `wiki/concepts/*.md` 全件
- 各 page の `git log --oneline -- <path>` (history) または frontmatter `updated:` の改訂履歴

**Detection criterion**:
- 同一 concept page に対し独立した update が **3 回以上**
- 各 update で本文の意味が変化している (typo fix のみは除外)

**Output**:
- 既存 concept page に "## Concept Evolution" section を追記 (新規 file ではなく **rewrite**)
- timeline: `YYYY-MM-DD: <変化の要約>`
- ※ Phase 4.1 rewrite emphasis と整合: 新規 file は作らず既存を書き換える

### Fold 4: orphan rescue agent

**Goal**: `wiki/` 配下で **inbound wikilink を持たない** page のうち、本文 claim から既存 page に link すべき内容を持つものを救出。

**Input**:
- `wiki/**/*.md` 全件
- 各 page の inbound link 数 (`grep -r "[[<page-name>]]" wiki/` の結果)

**Detection criterion**:
- inbound link 数 = 0
- かつ本文に既存 page (entity / concept / project) への言及が 1 つ以上ある

**Output**:
- 既存 entity / concept / project page に "## 関連" or "## Mentions" section を追加し、orphan page への link を挿入
- orphan page 自身の frontmatter に rescue marker を追加 (`rescued_at: YYYY-MM-DD`)

---

## Synthesis page format (Fold 1 / 2 で新規 file 作成時)

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

frontmatter は claude-second-brain-jp の **memory freshness gate** (`Status` / `Last-verified` / `Half-life`) を必須化。eug 版より厳格。

---

## Aggregation (4 fold 完了後の Lead 集約)

各 fold の result を unified report に集約:

```markdown
# /sb-synthesize report (YYYY-MM-DD)

## Cross-source hits (Fold 1)
- <concept-A> @ [[podcast]] [[article]] [[daily-note]] → wiki/concepts/Synthesis — <concept-A>.md
- ...

## Entity convergence (Fold 2)
- [[Person A]] × [[Person B]] in [[Project X]] [[Decision Y]] → wiki/concepts/Synthesis — A × B connection.md
- ...

## Concept evolution (Fold 3)
- [[Concept C]]: 3 updates (2026-04-01 / 2026-04-15 / 2026-05-02) → 既存 page に Evolution section 追記
- ...

## Orphan rescue (Fold 4)
- [[Orphan page Z]]: rescued via [[Entity α]] / [[Concept β]] への inbound link 追加
- ...

## Summary
- X synthesis pages created
- Y orphans rescued
- Z connections found
```

最後に:
- `wiki/index.md` を新 page で更新
- `wiki/log.md` 先頭に 1 行 entry を append: `## [YYYY-MM-DD] sb-synthesize | X synthesis pages created, Y orphans rescued, Z connections found`

---

## JP Sub-mode prompt fold (Wave 2 / Phase 2.3 接続済)

本 SKILL.md は JP business 向け 3 sub-mode の prompt fold を内蔵する。各 sub-mode は **input file path を必須引数** で受け取り、所定の output 構造を生成する。flag を literal match して下記 prompt fold を Lead が読み実行する。

### Sub-mode 1: `--meeting-commitments`

**Input contract**: 議事録 markdown (例: `tests/fixtures/sb-synthesize/jp-meeting-minutes.md`)。frontmatter 任意、本文に決定事項を JP で記述。

**Prompt fold (Lead がこの手順を 1 ターンで実行)**:

1. 引数 path を `Read` で全文取得
2. 本文を行単位で走査し、以下の **JP commitment 動詞パターン** を regex 相当の意味マッチで検出:
   - 「〜と決定」「〜と決まった」「〜が決定」
   - 「〜が承認」「〜を承認」「承認された」
   - 「〜することにした」「〜することに決定」
   - 「〜とする」「〜となる」 (能動的決定の文脈に限る)
   - 除外パターン: 「議論した」「検討中」「保留」「次回までに」「検討事項」「結論を出さず」(これらが同一段落にあれば commitment ではない)
3. 各 commitment hit について、**同一段落 or 直後 5 行以内** の以下を抽出:
   - 期日: `期限:` `期日:` `納期:` `〜まで` `YYYY-MM-DD` 形式の日付
   - 担当: `担当:` `担当者:` または `[[人名]]` wikilink
4. 抽出結果を Markdown table で structured output:

   ```markdown
   ## 抽出 commitment

   | # | commitment | 期日 | 担当 |
   |---|------------|------|------|
   | 1 | β版リリース日確定 (2026-06-01) | 2026-06-01 | [[田中]] |
   | 2 | 価格モデル A 採用 | 2026-05-15 | [[佐藤]] |
   | ... | ... | ... | ... |
   ```

5. 末尾に summary 1 行: `合計 N 件の commitment を抽出 (除外パターン M 件)`
6. 抽出 0 件なら「commitment 検出なし。本文には決定事項が含まれていません。」と出力

**Acceptance**:
- 上記 fixture で **4 件以上** の commitment table 行を生成
- 「議論のみ」「検討中」「保留」段落 (議題5・採用計画) を除外
- 各行に commitment / 期日 / 担当 の 3 列が揃っている

---

### Sub-mode 2: `--proposal-diff`

**Input contract**: 新旧 2 提案を含む markdown (例: `tests/fixtures/sb-synthesize/jp-proposal-vs-past.md`)。`## NEW:` / `## PAST:` セクション、または比較 table を含む。

**Prompt fold**:

1. 引数 path を `Read` で全文取得
2. **NEW (新提案) と PAST (過去案件)** の 2 ブロックを section heading or table で識別
3. 比較対象軸を抽出 (典型: 価格 / 納期 / SLA / オプション機能 / 契約条項 / サポート範囲 / 担当)。table 形式があれば 1 列ずつ突合
4. 各軸の差分を以下の 3 要素で評価:
   - **diff**: NEW と PAST の値 + 変化の方向 (例: `$30,000 → $45,000 (+50%)`)
   - **重要度**: `HIGH` (顧客満足 / リスクに直結) / `MEDIUM` (運用影響あり) / `LOW` (cosmetic)
   - **推奨**: `取り込み推奨` / `却下推奨` / `要検討` + 1-2 行の理由 (PAST の振り返り = 成功/失敗 を根拠として明示)
5. 結果を Markdown table で structured output:

   ```markdown
   ## 提案 diff & 推奨

   | # | 項目 | NEW | PAST | 差分 | 重要度 | 推奨 | 理由 |
   |---|------|-----|------|------|--------|------|------|
   | 1 | 価格 | $45,000 | $30,000 | +$15,000 (+50%) | HIGH | 要検討 | 顧客規模差を反映するが、PAST 比 50% 増は justification 要 |
   | 2 | 納期 | 4ヶ月 | 3ヶ月 | +1ヶ月 | MEDIUM | 要検討 | multi-tenant 対応で +1ヶ月妥当だが、競合提案次第 |
   | 3 | SLA | 99.9% | 99.5% | +0.4pt | HIGH | 取り込み推奨 | 大規模顧客は 99.9% 期待、PAST は 99.5% で十分だった (NPS 8.5) ことを踏まえても upgrade は market 整合 |
   | ... | ... | ... | ... | ... | ... | ... | ... |
   ```

6. 末尾に **取り込み推奨セクション** (推奨 = 取り込み推奨 行のみ抜粋した action list) と **却下推奨セクション** (リスク警告) を別 markdown heading で提示
7. PAST に振り返り (成功/失敗の教訓) があれば、推奨理由欄で literal 引用

**Acceptance**:
- 上記 fixture で **5 件以上** の diff table 行を生成
- 各行に 重要度 (HIGH/MEDIUM/LOW) + 推奨 (取り込み / 却下 / 要検討) が明記されている
- 推奨理由欄に PAST の「成功した部分」「失敗した部分」「教訓」を 1 件以上引用

---

### Sub-mode 3: `--slack-tldr`

**Input contract**: JP Slack thread の markdown (例: `tests/fixtures/sb-synthesize/jp-slack-thread.md`)。**`<人名>**` (太字) + 時刻 + メッセージ本文の繰り返し構造、frontmatter `translate_to_en: true` で EN 併記要求。

**Prompt fold**:

1. 引数 path を `Read` で全文取得
2. frontmatter の `translate_to_en` を確認 (true なら EN 翻訳 alias 必須)
3. thread の発言を時系列に追い、以下を判定:
   - **議題の核**: thread が主に何を扱っているか
   - **決着**: 決まったこと / 結論 (なければ「未決着」)
   - **残課題**: 次アクション or open question
4. 上記を **3-5 行** の日本語 TL;DR に圧縮:

   ```markdown
   ### TL;DR (JP)
   <3-5 行で議題の核 + 決着 + 残課題を要約>
   ```

5. `translate_to_en: true` なら直後に EN translation alias (同 3-5 行 EN):

   ```markdown
   ### TL;DR (EN translation alias)
   <same content in EN, 3-5 lines>
   ```

6. 関係者 list を生成 (thread 内の `[[人名]]` or 太字人名を全件抽出、重複排除)。各人について **1 行で立場・役割** を本文発言から推論:

   ```markdown
   ### 関係者 (N 名)
   - [[田中]]: リリース PM、QA gate 主催、go/no-go 判定責任者
   - [[佐藤]]: マーケ側責任者、press release / LP 公開担当
   - [[鈴木]]: インフラ責任者、認証 token P1 修正担当
   - [[高橋]]: ドキュメント責任者、β版 walkthrough 日英対応
   ```

7. URL や file path への literal 言及があれば末尾に「### 参照 link」として保持 (verbatim)

**Acceptance**:
- TL;DR (JP) が **3-5 行** に収まっている
- frontmatter `translate_to_en: true` の時のみ EN translation alias を出力 (同じ 3-5 行構造)
- 関係者 list が **thread 内の全人物** を漏れなく抽出 (上記 fixture では 4 名: [[田中]] [[佐藤]] [[鈴木]] [[高橋]])
- 各関係者の立場が 1 行で具体的に明記されている (役職名のみは NG、本文発言から推論した役割)

---

### 共通設計原則 (3 sub-mode 全て)

- **Read-only on input file**: input path に対する `Edit`/`Write` は禁止。output は **本 ターンの assistant message** に Markdown で直接出力する (新規 wiki page を作る必要があるかは user 判断)
- **JP 出力デフォルト**: `--slack-tldr` の EN alias 以外、出力は全て日本語
- **存在しない値は省略しない**: `期日: 未指定` のように literal で「未指定」を明記。silently 空欄にしない
- **wikilink 保持**: input に `[[人名]]` がある場合、output でも `[[人名]]` 形式を維持

### Mutually exclusive 制約

複数 flag を同時指定された場合 (例: `--meeting-commitments --proposal-diff <path>`) は以下を出力して 1 sub-mode のみ実行する:

```
[sb-synthesize] 複数 sub-mode flag は同時指定不可。最初に指定された flag のみ実行します。
```

---

## 想定 invocation 例

```text
# 既定 (4 fold)
/sb-synthesize

# JP sub-mode (Wave 2 接続済)
/sb-synthesize --meeting-commitments tests/fixtures/sb-synthesize/jp-meeting-minutes.md
/sb-synthesize --proposal-diff tests/fixtures/sb-synthesize/jp-proposal-vs-past.md
/sb-synthesize --slack-tldr tests/fixtures/sb-synthesize/jp-slack-thread.md
```

---

## TDD acceptance

### Phase 3.3 (default 4 fold shell)

`tests/fixtures/sb-synthesize/cross-source/` 配下 3 page (`podcast-transcript.md` / `article-summary.md` / `daily-note.md`) と `tests/fixtures/sb-synthesize/orphan-rescue/` 配下 2 page (`orphan-concept.md` / `orphan-entity.md`) が、各 fold の最小起動 input。

`bash tests/run-fixtures.sh wave1` で `cross-source-dir` / `orphan-rescue-dir` の存在確認が PASS することを完了条件とする。

### Phase 2.3 (JP sub-modes、本接続)

`tests/fixtures/sb-synthesize/` 配下 3 fixture が各 sub-mode の最小起動 input:

| Flag | Fixture | Acceptance (本 SKILL.md 内 prompt fold が満たす設計) |
|---|---|---|
| `--meeting-commitments` | `jp-meeting-minutes.md` | 4 件以上の commitment table 行 (3 列: commitment / 期日 / 担当)、「保留」「議論のみ」を除外 |
| `--proposal-diff` | `jp-proposal-vs-past.md` | 5 件以上の diff table 行 (重要度 + 推奨 + PAST 教訓引用) |
| `--slack-tldr` | `jp-slack-thread.md` | TL;DR 3-5 行 (JP) + EN translation alias (translate_to_en: true) + 関係者 4 名各 1 行立場明記 |

`bash tests/run-fixtures.sh wave2` で 3 fixture の存在確認が PASS することを Phase 2.3 完了条件とする。

---

## AI-first rule

このスキルが作成・更新する全 note は claude-second-brain-jp の AI-first 規約に従う:

- frontmatter 必須 (`type` / `title` / `created` / `updated` / `tags` / `Status` / `Last-verified` / `Half-life`)
- 言及される全 person / project / concept は `[[wikilink]]`
- 外部 claim は URL を verbatim で保持
- vault は **未来の Claude の retrieval のため** であり、人間の reading のためではない

---

## 関連 skill

- `wiki` — vault scaffold + 5-layer hot cache
- `wiki-lint` — orphan / dead link / stale claim 検出 (本 skill の Fold 4 と相補)
- `wiki-ingest` (rename → `sb-ingest`、Phase 2.2) — source ingestion
- `sb-graduate-meeting` (Phase 2.7) — 議事録 → ADR auto-graduate (本 skill の `--meeting-commitments` と棲み分け: graduate は ADR file 化、synthesis は commitment 抽出)
