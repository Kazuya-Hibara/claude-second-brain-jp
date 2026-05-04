---
name: sb-synthesize
description: >
  vault の未命名パターンを 4 並列 fold (cross-source / entity convergence / concept evolution / orphan rescue)
  で検出し、synthesis page を自動生成する。聞かれた時だけでなく schedule でも走る。
  JP business 向け sub-mode (--meeting-commitments / --proposal-diff / --slack-tldr) hook
  を備える (中身は Wave 2 / Phase 2.3 で接続)。
  Triggers on: "/sb-synthesize", "synthesize the vault", "find unnamed patterns",
  "vault に潜むパターン抽出", "sb-synthesize", "auto synthesis", "scheduled synthesis".
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
/sb-synthesize                          → run_default_4_fold()
/sb-synthesize --meeting-commitments    → run_jp_submode("meeting-commitments")  [Wave 2 で接続]
/sb-synthesize --proposal-diff          → run_jp_submode("proposal-diff")        [Wave 2 で接続]
/sb-synthesize --slack-tldr             → run_jp_submode("slack-tldr")           [Wave 2 で接続]
```

mode 判定は flag の literal match。複数 flag は許可しない (`mutually exclusive`)。

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

## JP Sub-mode Hook (Wave 2 / Phase 2.3 で接続)

本 shell (Phase 3.3) では JP business 向け sub-mode は **stub のみ**。flag を literal match して以下の error を出力して exit 1 する:

```
[sb-synthesize] sub-mode "<flag>" is not wired yet. Wave 2 (Phase 2.3) will connect the prompt fold. See skills/sb-synthesize/SKILL.md "JP Sub-mode Hook" section.
```

### Wave 2 接続契約 (Phase 2.3 connector が満たすべき仕様)

Wave 2 で `executor opus` が本 SKILL.md に以下を追記する想定:

| Flag | Sub-mode 名 | Fixture (Wave 2 で追加) | Acceptance |
|---|---|---|---|
| `--meeting-commitments` | meeting-commitments | `tests/fixtures/sb-synthesize/jp-meeting-minutes.md` | commitment / 期日 / 担当 を抽出した structured output |
| `--proposal-diff` | proposal-diff | `tests/fixtures/sb-synthesize/jp-proposal-vs-past.md` | 新旧 diff + 推奨セクション提示 |
| `--slack-tldr` | slack-tldr | `tests/fixtures/sb-synthesize/jp-slack-thread.md` | TL;DR + 関係者 + EN 翻訳 alias |

### Stub 実装 (本 shell)

`run_jp_submode(name)` 関数の現状実装:

```text
function run_jp_submode(name):
    error_message = '[sb-synthesize] sub-mode "--' + name + '" is not wired yet. ' +
                    'Wave 2 (Phase 2.3) will connect the prompt fold. ' +
                    'See skills/sb-synthesize/SKILL.md "JP Sub-mode Hook" section.'
    print(error_message) to stderr
    exit(1)
```

Wave 2 connector はこの関数を **置き換える** のではなく、stub の `print + exit` を **削除し** sub-mode 別の prompt fold を inject する。stub を残したまま新 fold を追加する形は禁止 (silent override が起きる)。

### Connector が探す target string

Wave 2 connector は本 SKILL.md 内で以下の文字列を grep する:

- `[sb-synthesize] sub-mode "--meeting-commitments" is not wired yet.`
- `[sb-synthesize] sub-mode "--proposal-diff" is not wired yet.`
- `[sb-synthesize] sub-mode "--slack-tldr" is not wired yet.`

これらが Wave 2 完了後の SKILL.md には **存在しない** ことが connector の self-check になる。

---

## 想定 invocation 例

```text
# 既定 (4 fold)
/sb-synthesize

# JP sub-mode (Wave 2 接続後)
/sb-synthesize --meeting-commitments tests/fixtures/sb-synthesize/jp-meeting-minutes.md
/sb-synthesize --proposal-diff tests/fixtures/sb-synthesize/jp-proposal-vs-past.md
/sb-synthesize --slack-tldr tests/fixtures/sb-synthesize/jp-slack-thread.md
```

---

## TDD acceptance (Phase 3.3、本 task)

`tests/fixtures/sb-synthesize/cross-source/` 配下 3 page (`podcast-transcript.md` / `article-summary.md` / `daily-note.md`) と `tests/fixtures/sb-synthesize/orphan-rescue/` 配下 2 page (`orphan-concept.md` / `orphan-entity.md`) が、各 fold の最小起動 input になる。

`bash tests/run-fixtures.sh wave1` で `cross-source-dir` / `orphan-rescue-dir` の存在確認が PASS することを Phase 3.3 完了条件とする (Phase 2.3 fixture は Wave 2 で追加)。

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
