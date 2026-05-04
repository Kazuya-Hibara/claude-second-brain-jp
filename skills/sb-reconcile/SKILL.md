---
name: sb-reconcile
description: "vault 内の矛盾を evidence-based に解消する。同一 entity / concept について複数 page が衝突している場合、5 軸の judge ladder (freshness / authority / specificity / recency / status) で winner を確定し、敗者主張は ## History section に保持。evidence で決着しない ambiguous case は default で skip (`--evidence-only` mode、autopilot / cron 安全)、`--interactive` opt-in flag で user confirm prompt を出す。Triggers on: reconcile, 矛盾解消, 競合解決, contradiction resolution, vault 整合性, conflict resolution, evidence-based merge."
---
<!-- Adapted from eugeniughelbur/obsidian-second-brain (MIT, commit 69b9acb) -->

# sb-reconcile: Evidence-based vault reconciliation

vault は SSOT であるべきで、**自覚なき矛盾** (= 同じ事実について 2 page が異なる主張をし、両者がそれを知らない) は禁止。本 skill は矛盾を見つけて解決し、過程を `## History` で残す。

CLAUDE.md の **Memory Freshness Gate** (`Status` / `Last-verified` / `Half-life`) を judge の主軸に据える。

---

## Mode 一覧 (default + opt-in flags)

| Mode | command flag | Ambiguous case の挙動 | 用途 |
|---|---|---|---|
| **Default** | (flag なし) | 触らず skip、Lead 報告にリスト | 手動実行で「自動で済むものだけやって、残りは目視」 |
| **Evidence-only** | `--evidence-only` | 触らず skip、Lead 報告にリスト | **autopilot / cron / scheduled-agent はこれを default で使う** |
| **Interactive** | `--interactive` | user に AskUserQuestion (4-part) | 人間が腰を据えて vault 監査する時 |

`--scope <topic-or-entity>` は全 mode 共通の絞り込み。

---

## Conflict 抽出 (4 並列 subagent)

`/sb-reconcile` 起動後、Lead が以下を **single-message multi-Agent** (CLAUDE.md `<execution_protocols>` "2+ independent tasks in parallel") で並列発火:

1. **Claims agent** (`wiki/concepts/` + `wiki/projects/`)
   - 同一 topic / 同一 entity を扱う page pair で、本文中の事実主張 (数値 / 推奨値 / 動作仕様) が直接矛盾するものを返す。
   - 出力: `[ {pair: [pathA, pathB], topic: "...", claim_a: "...", claim_b: "..."} ]`

2. **Entity agent** (`wiki/entities/`)
   - 同一 entity の role / company / 説明文が異なる version で並んでいるものを返す (例: 同じ人物の所属が page A と page B で違う)。
   - 出力: `[ {entity: "...", pair: [pathA, pathB], field: "role|company|...", value_a: "...", value_b: "..."} ]`

3. **Decisions agent** (`wiki/decisions/` ADR)
   - 後続 ADR で revoke / supersede されたが status field を更新していない過去 ADR を返す。
   - 出力: `[ {ancestor: pathA, descendant: pathB, decision: "...", status_in_a: "ACTIVE", supersede_evidence_in_b: "..."} ]`

4. **Source freshness agent** (`.raw/` ソース date vs `wiki/` page date)
   - `.raw/` 内に同一 topic の新ソースが存在するのに `wiki/` page が古い source を引用したまま。`(today - Last-verified) > Half-life` の page を優先 surface。
   - 出力: `[ {wiki_page: pathA, raw_new_source: pathB, raw_new_date: "...", page_last_verified: "...", page_source_date: "..."} ]`

---

## Evidence-Based Winner Judge — 5 軸 ladder

**順番厳守**。上から評価し、決着した時点で確定。決着しなければ次の軸へ。すべての軸で互角なら **ambiguous** 確定。

### 軸 1: Status (Memory Freshness Gate)

| 状況 | 判定 |
|---|---|
| 片方が `Status: SUPERSEDED` で他方が `ACTIVE` | ACTIVE 側 winner |
| 片方が `Status: HYPOTHESIS` で他方が `ACTIVE` (かつ Last-verified 内) | ACTIVE 側 winner |
| 片方が `Status: RESOLVED` (過去事例) で他方が `ACTIVE` | ACTIVE 側 winner |
| 両方とも同じ Status | 次の軸へ |

### 軸 2: Freshness (Last-verified vs Half-life)

| 状況 | 判定 |
|---|---|
| 片方が `(today - Last-verified) ≤ Half-life`、他方が超過 | 半減期内 winner |
| 両方半減期内、Last-verified 差が **30 日以上** | 新しい側 winner |
| 両方半減期内、Last-verified 差が 30 日未満 | 次の軸へ |
| 両方超過 | 次の軸へ (両者共に ADVISORY only) |

### 軸 3: Source Authority (peer-review > 1 次 > 2 次 > opinion)

| 状況 | 判定 |
|---|---|
| 片方が **1 次ソース** (本人発言 / 公式 docs / RFC / peer-reviewed paper)、他方が 2 次 (要約 blog / news re-write / 個人解説) | 1 次側 winner |
| 片方が peer-reviewed (学術 / 公式 standards body)、他方が 1 次 (公式 docs / 著者 post) | peer-reviewed 側 winner |
| 同 tier (両方 1 次 / 両方 2 次) | 次の軸へ |

### 軸 4: Source Specificity (具体的根拠の本数)

| 状況 | 判定 |
|---|---|
| 片方が **2 個以上の独立根拠** (定量 / 引用 / 例) を持ち、他方が 1 個以下 | 多い側 winner |
| 両方とも同数 | 次の軸へ |

### 軸 5: Source Recency (引用元 source の date)

| 状況 | 判定 |
|---|---|
| 引用 source の date 差が **3 ヶ月以上** | 新しい source 側 winner |
| 3 ヶ月未満の差 | **ambiguous 確定** |

### 例外: Evolution (矛盾ではなく更新)

軸 1-5 を回す前に、以下のシグナルが揃う場合は **evolution** とラベル (winner / loser ではなく、両者を時系列でマージ):

- 同一著者 / 同一プロジェクト由来の連続 source
- 古い page が「以前は X だった」式の含意で書かれており、新 page が「今は Y」と明示
- decisions/ ADR で `superseded-by:` 互いに明示済

evolution の場合: 新 page を本文 winner、旧 page の主張は `## History` に時系列ログとして残す (敗者扱いの SUPERSEDED マークは付けない)。

---

## 解決アクション (judge 結果別)

### Clear winner 確定時

敗者 page に対して以下を **atomic** に実行 (frontmatter + 本文 + History を 1 回の Edit で):

1. **frontmatter update**:
   ```yaml
   Status: SUPERSEDED
   superseded_by: "[[<winner-page-title>]]"
   Last-verified: <today YYYY-MM-DD>
   updated: <today YYYY-MM-DD>
   ```
2. **本文書き換え**: winner 側主張をベースに書き換え。
3. **`## History` section append** (既存があれば TOP に追記、無ければ末尾に新規追加):
   ```markdown
   ## History

   - **YYYY-MM-DD reconcile**: 旧主張「<元主張 1 行要約>」は [[<winner-page-title>]] (source: <winner-source>, <source-date>) と衝突。evidence 比較で敗者判定 (軸<N>: <理由 1 行>)。本文を winner 側に同期、Status を SUPERSEDED に変更。
   ```
4. **winner page** 側にも軽い cross-reference を 1 行追加 (本文 or `## See also` 末尾):
   ```markdown
   - 旧主張「<元主張 1 行>」は [[<loser-page-title>]] で SUPERSEDED 済 (YYYY-MM-DD reconcile)。
   ```

### Ambiguous (judge ladder の 5 軸でも決着せず)

| Mode | 挙動 |
|---|---|
| default (flag なし) | **触らない**。Lead 報告に `## Ambiguous (skipped)` を追加、両 page path + 主張差分を提示。`--interactive` 提案を 1 行添える。 |
| `--evidence-only` | default と同じ (触らない、skipped 報告)。autopilot / cron で安全。 |
| `--interactive` | user に AskUserQuestion (CLAUDE.md `<important>` Decision Hygiene 4-part):<br>**Context**: vault reconcile 中、entity「<topic>」で証拠不足の競合発見<br>**Question**: どちらを採用?<br>**RECOMMENDATION**: `Choose 「skip / 後で再検証」 because 証拠不足のまま強制決着は今後の vault 整合性を悪化させる`<br>**Options**: A) page A 採用 / B) page B 採用 / C) skip (両方そのまま) |

user が A/B 選択した場合 → そのまま clear-winner 経路に流す (frontmatter + 本文 + History 全更新)。C 選択 → 両 page そのまま、log.md の reconcile entry に `flagged_ambiguous: [pair_id]` を 1 行残し、次回 reconcile 時に再 surface する。

### Evolution

新 page (= 時系列で後の page) を winner 扱い、旧 page の主張を `## History` に時系列で並べる:

```markdown
## History

- **2026-01-15** (created): 「<旧主張>」(source: <旧 source>)
- **2026-04-10** (evolution): 「<中間主張>」(source: <中間 source>)
- **YYYY-MM-DD reconcile**: 現行主張「<新主張>」に統合 (source: <新 source>)。Status は ACTIVE 維持、SUPERSEDED にはしない。
```

---

## `--evidence-only` flag の semantics

`--evidence-only` は **autopilot / cron / scheduled-agent からの呼び出し** を想定した安全 mode。default mode との違いはほぼ無いが、以下の 2 点で **明示的に user 介入を排除**する:

1. **Ambiguous case で user prompt を絶対に出さない** (default も出さないが、`--evidence-only` は明示宣言で「prompt 出ないことが contract」)。
2. **報告のみ** で次の wave / cron job を block しない (Lead が context 圧迫しない、scheduled-agent が業務時間外で sleep に戻れる)。

**運用例**:

- `business_hours.weekday "10:00-19:00"` 外の cron で `/sb-reconcile --evidence-only` を毎週末発火。
- evidence-clear な矛盾だけ自動修復、ambiguous は週次レポートで人間レビューに回す。
- autopilot Phase 2 ループで `/sb-reconcile --evidence-only --scope "<触ったばかりの topic>"` を ingest 直後に挟む。

---

## 後処理 (全 mode 共通)

1. **`wiki/index.md` 再構築**: 影響を受けた catalog 行を更新 (1 行 ≤ 15 文字維持)。
2. **`wiki/log.md` TOP に append**:
   ```markdown
   ## [YYYY-MM-DD] reconcile | <found> 件検出、<auto-resolved> 件 evidence で自動解決、<flagged> 件 ambiguous

   - Pages updated: [[<loser-1>]], [[<loser-2>]], ...
   - Pages SUPERSEDED: [[<loser-1>]], ...
   - Ambiguous (skipped): [[<pair-1-a>]] vs [[<pair-1-b>]], ...
   - Mode: default | --evidence-only | --interactive
   - Scope: <vault 全体 | --scope ...>
   ```
3. **影響 domain hot cache 同期**: `wiki/hot-domain-{X}.md` が該当 entity / concept を含むなら、winner 側主張に書き換え (300 words 上限維持、超過分は `wiki/hot-week.md` に bleed)。

---

## Report format (Lead / user 向け最終出力)

```markdown
## sb-reconcile 実行結果 (YYYY-MM-DD, mode: <mode>, scope: <scope>)

### Auto-resolved (evidence-clear)
- [[<loser-page>]] : 旧主張「<...>」 → 新主張「<...>」 (winner: [[<winner-page>]], 軸<N>: <理由>)
  - SUPERSEDED, ## History 追記済

### Ambiguous (<mode 別: skipped | resolved by user | pending>)
- [[<pair-a>]] vs [[<pair-b>]] : topic「<...>」、主張差分「<...>」
  - Action: skip (default/--evidence-only) | A 採用 / B 採用 / skip 選択 (--interactive)

### Stale pages updated (新ソース存在下で書き換え)
- [[<page>]] : `Last-verified` <old> → <today>、source `[[<old-src>]]` → `[[<new-src>]]`

### Summary
- 検出: <N> pair
- 自動解決: <X> pair
- ambiguous: <Y> pair (<flagged> remains)
```

---

## Edge cases

- **3-way 矛盾 (page A, B, C が三者三様)**: pair で 2 回 reconcile を回す。最初の (A, B) で winner を確定し、その winner と C で次の reconcile。3-way 同時 judge は実装しない (judge ladder が 2-way 前提)。
- **History section が既に長大 (10+ entry)**: 6 ヶ月以上前の entry を `wiki/decisions/<topic>-history-archive.md` に切り出して footnote リンク。本 skill 内で archive 自動生成は v0.2.0 に持ち越し、v0.1.0 では検出して INFO 報告のみ。
- **frontmatter Half-life 不在**: Memory Freshness Gate が機能しないので、軸 2 (Freshness) を skip し軸 3 以降で評価。最終 report で「Half-life 不在 → /sb-doctor 推奨」を 1 行添える。
- **scope 指定で対象 0 件**: `No conflicts found in scope "<...>"` を 1 行返して終了 (`log.md` には append しない、空 reconcile はノイズ)。

---

## 関連 skill / command

- `/sb-doctor` : reconcile 実行前に走らせると frontmatter 不備 page が事前に判明、judge 軸 1-2 が機能しやすくなる。
- `/wiki-lint` : reconcile 後に走らせると orphan / stale claims が再 surface される。
- `/sb-graduate-meeting` : ADR 自動生成側。reconcile が ADR を SUPERSEDED にした時、graduate 側で生成した元 page も合わせて更新する必要がある (両 skill で同 ADR を編集しないよう scope を絞る)。
