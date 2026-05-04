---
description: vault 内の矛盾を evidence-based に解消する。winner 確定時は敗者主張を ## History に保持、ambiguous case は user confirm prompt (デフォルト OFF + opt-in flag)
---
<!-- Adapted from eugeniughelbur/obsidian-second-brain (MIT, commit 69b9acb) -->

`sb-reconcile` skill を読み込んでから `/sb-reconcile $ARGUMENTS` を実行する。

引数 (任意):
- `--scope <topic-or-entity>`: 対象を絞る (例: `--scope "Business Hours Schema"`)。省略時は vault 全体。
- `--evidence-only`: evidence で決着する pair のみ自動処理、ambiguous は untouched で skip 報告。**autopilot / cron / scheduled-agent はこの mode を default で使う**。
- `--interactive`: ambiguous case を user confirm prompt で逐次確認 (default は prompt 出さず skip)。

## 実行手順

1. **vault 読み込み**: `CLAUDE.md` (`Memory Freshness Gate` 仕様) と `wiki/index.md` を読み、vault landscape を把握する。

2. **競合候補の並列抽出** (4 並列 subagent):
   - **Claims agent**: `wiki/concepts/` と `wiki/projects/` を scan、同一 topic で互いに矛盾する事実主張の pair を返す。
   - **Entity agent**: `wiki/entities/` を scan、role / company / 説明文が他ソースと衝突する entity page を返す。
   - **Decisions agent**: `wiki/decisions/` (ADR) を scan、後続 ADR で reverse / supersede されたが status を更新していない決定を返す。
   - **Source freshness agent**: `.raw/` 内ソースの date と `wiki/` 各 page の `Last-verified` / source 引用日付を突合、新ソース存在下での古い page を flag する。

3. **各 conflict pair に対し evidence-based judge を実行**: `skills/sb-reconcile/SKILL.md` の **Evidence-Based Winner Judge** セクション (5 軸の判定 ladder) を厳密に適用する。

4. **解決アクション (judge 結果別)**:
   - **Clear winner 確定** (mode: 全 mode 適用):
     - 敗者 page を rewrite。本文を winner 主張ベースに書き換え、敗者の元主張は **`## History` section** に格納:
       ```markdown
       ## History

       - **YYYY-MM-DD reconcile**: 旧主張 "<元主張一行>" は [[winner-page-name]] (source: <winner-source>, <date>) と衝突、evidence 比較で敗者と判定 (理由: <Last-verified 差 / source authority / specificity 等>)。本文を winner 側に同期。
       ```
     - 敗者 page の frontmatter を更新: `Status: SUPERSEDED` + `superseded_by: "[[winner-page-name]]"` + `Last-verified: <today>`。
   - **Ambiguous (evidence 不足)**:
     - **default mode**: 触らない。Lead 報告に `Ambiguous (skipped)` セクションを出し、両 page の path + 主張差分を提示。`--interactive` 推奨を 1 行添える。
     - **`--evidence-only` mode**: 同上 (default と同じ挙動 = ambiguous は untouched)。autopilot / cron で安全。
     - **`--interactive` mode**: user に AskUserQuestion (1 issue / 4-part: Context / Question / RECOMMENDATION / Options A/B/C)。RECOMMENDATION は「証拠不足のため判定保留が安全」を default 推奨。user が A/B どちらかを選んだら winner 側として確定処理 (上記 clear-winner 経路)。skip を選んだら次回までペンディング。
   - **Evolution (genuine update、矛盾ではない)**: 元 page を update して現状反映、`## History` に時系列推移を残す (敗者扱いではない)。

5. **後処理**:
   - 影響を受けた `wiki/index.md` のセクションを再構築。
   - `wiki/log.md` の TOP に append:
     ```
     ## [YYYY-MM-DD] reconcile | <found> 件検出、<auto-resolved> 件 evidence で自動解決、<flagged> 件 ambiguous (skipped/interactive)
     ```
   - 該当 entity / concept の domain hot cache (`wiki/hot-domain-{X}.md`) があれば、winner 主張に同期 (300 words 上限維持)。

6. **report 出力** (Lead/user 向け):
   - **Auto-resolved (evidence-clear)**: 旧主張 → 新主張、判定根拠 (どの軸で勝ったか)、敗者 page path (`## History` 格納済)。
   - **Ambiguous (skipped or pending interactive)**: pair の両 path + 主張差分。`--interactive` 提案。
   - **Stale pages updated**: 新ソース存在下で書き換えた page 一覧。

## 設計原則

vault は **2 つの page が無自覚に矛盾している状態** を許さない。矛盾は (a) evidence で解決、(b) `## History` で過程を可視化、(c) ambiguous なら明示的にペンディング、のいずれか。**`--evidence-only` mode を default とする運用**で autopilot / cron からも安全に呼べる。

---

**AI-first rule**: 本コマンドが update する全 page は `Memory Freshness Gate` (frontmatter `Status` / `Last-verified` / `Half-life`) を保持する。`## History` section は将来の Claude / sb-reconcile 実行時に「過去にどの主張がなぜ negated されたか」を即座に取り出せる構造で書く (date / 旧主張 / winner page 参照 / 判定根拠の 4 要素を 1 行ずつ)。
