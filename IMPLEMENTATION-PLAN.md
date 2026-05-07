# claude-second-brain-jp — Implementation Plan

**Status**: **Phase 1-5 完了 (v0.1.0、2026-05-07)**
**Repo**: https://github.com/Kazuya-Hibara/claude-second-brain-jp (v0.1.0)
**Release**: https://github.com/Kazuya-Hibara/claude-second-brain-jp/releases/tag/v0.1.0
**Distribution**: `claude plugin marketplace add Kazuya-Hibara/claude-second-brain-jp` (self-hosted、Anthropic 公式 marketplace は社員 bundled 専用のため不要)
**Remaining**: Phase 5.4 (告知、user voice 必須) + Phase 6 (maintenance) は v0.1.0 scope 外

## Phase 0: Pre-flight (user 確認事項)

実装着手前に user 承認が必要な項目:

- [x] GitHub repo 作成: `Kazuya-Hibara/claude-second-brain-jp` (public, MIT、2026-05-05 完了)
- [x] AgriciDaniel/claude-obsidian の fork 方針: **gh fork** (upstream merge 経路を維持)
- [x] CC plugin self-hosted distribution 採用 (v0.1.0、`claude plugin publish` subcommand 不在を確認、Anthropic 公式 marketplace は @anthropic.com 社員 bundled 専用 → 第三者 plugin は repo 自前 marketplace.json + `claude plugin marketplace add <repo>` で配布)
- [ ] `claude-second-brain-jp.com` 等の docs site ドメイン (保留、`github.io` で十分時に再検討)

## Phase 1: Fork & local clone ✅ 完了 (2026-05-05、commit `93a5a20`)

実行内容:

```bash
# 1. AgriciDaniel/claude-obsidian を fork
gh repo fork AgriciDaniel/claude-obsidian --fork-name=claude-second-brain-jp --clone --remote --default-branch-only

# 2. attribution / license / metadata 整理
# - LICENSE: MIT 維持、Kazuya Hibara copyright を AgriciDaniel と並列で追記
# - README.md: 冒頭に Phase 1 status banner + "Forked from..." 明記、本文は upstream を一時保持 (Phase 5 で全面差替)
# - ATTRIBUTION.md: 派生宣言を冒頭追加、末尾に fork 側 author / repository / contact / forked-at
# - .claude-plugin/plugin.json: name → claude-second-brain-jp、version 0.1.0-jp.1、author / homepage / repository / description / keywords を JP 化
# - .claude-plugin/marketplace.json: 同様
# - IMPLEMENTATION-PLAN.md: 上流 SSOT を fork repo に複製
```

GitHub side: description / homepage / topics (8 種) を API 経由で設定済。fork=true、parent=AgriciDaniel/claude-obsidian。

## Phase 2: 7 JP additions ✅ 全完了

**Status**: 2.1 / 2.4 / 2.5 / 2.6 完了 (2026-05-05、commit `7419f94`)、2.2 / 2.3 / 2.7 完了 (2026-05-07、Wave 1+2 commits `e018e8e` / `8b46d99` / `7af1996`)。

### 2.1: 5-layer hot cache ✅ 完了

- `wiki/hot.md` を ~300 words に絞る (CLAUDE.md schema rule で enforce)
- `wiki/hot-domain-{X}.md` 生成 logic を `/sb-init` に追加
- `wiki/hot-week.md` 週次集約を `/sb-digest` の出力先に追加
- CLAUDE.md `## Reading order` を 4-layer → 5-layer に書き換え

### 2.2: Multilingual ingestion

- `/wiki-ingest` (改名 → `/sb-ingest`) のプロンプトに JP/EN auto-detect を追加
- frontmatter `aliases:` 自動生成 (LLM に「JP primary、EN alias を併記」指示)

### 2.3: JP business synthesis prompts

- `/sb-synthesize` に 3 系統サブモード追加:
  - `--meeting-commitments`: 議事録から決定 / 期日 / 担当抽出
  - `--proposal-diff`: 提案書 vs 過去案件 wiki diff + 推奨セクション
  - `--slack-tldr`: Slack JP スレッド要約 + 関係者 + 任意 EN 翻訳

### 2.2: Multilingual ingestion ✅ 完了 (commit `e018e8e`、wiki-ingest → sb-ingest rename + JP/EN auto-detect + aliases 自動生成 + active config 8 file 一括書き換え)

### 2.3: JP business synthesis prompts ✅ 完了 (commit `8b46d99`、/sb-synthesize に 3 sub-mode 統合、stub block 完全削除)

### 2.4: 小 context window 最適化 ✅ 完了

- CLAUDE.md `## Style rules` に追加:
  - hot.md: max 300 words
  - index.md: 1 行 max 15 文字
- `/sb-doctor` の lint check に長さ警告追加

### 2.5: Time-window guard ✅ 完了 (`/schedule` 実連携は Phase 2 後半)

- CLAUDE.md schema に `business_hours: "weekday 09:00-18:00 JST"` フィールド
- `/schedule` agent 登録時にこのフィールドを反映、業務時間外発火に制限
- `/sb-doctor` で「業務時間内に scheduled agent が走った」を WARN

### 2.6: Memory freshness gate ✅ 完了

- 全 wiki page frontmatter に `Status / Last-verified / Half-life` 必須化
- `/sb-init` の page generator template を更新
- `/sb-doctor` の Frontmatter compliance check で missing を 🟡 WARN
- `/sb-doctor` の Memory freshness check で `> Half-life` を 🟡 WARN

### 2.7: 議事録 → ADR auto-graduate ✅ 完了 (commit `7af1996`)

- 新 command `/sb-graduate-meeting`
- 議事録の commitment が "決定事項" 構文 (例: 「〜と決定」「〜が承認」) を含む時、`wiki/decisions/YYYY-MM-DD-<slug>.md` に ADR フォーマットで書き出し
- 複数 commitment は N 件別 ADR file に分割 (`<slug>-<N>` suffix)
- 元議事録 page に `Graduated-to:` frontmatter で参照
- slug allowlist regex `^[a-z0-9-]{1,60}$` + path traversal 防止 (Wave 4.5 security HIGH 反映)

## Phase 3: eug 3 commands 移植 ✅ 全完了 (commit pin 69b9acb、Wave 1 commits `4253b89` / `b751301` / `7f2ba8c`)

### 3.1: `/sb-doctor` (steal `/obsidian-health`) ✅ 完了

- eug の 8 categories + omc-doctor 6-step CRITICAL/WARN/OK skeleton fusion
- 並列 subagent (Task tool) で各 category を分担
- Severity 🔴/🟡/⚪ + Safe-auto / Destructive-confirm 二段階 fix

### 3.2: `/sb-reconcile` (steal `/obsidian-reconcile`) ✅ 完了

- 矛盾検出時、evidence-based winner 判定 + 敗者は `## History` section に保持
- ambiguous case は user confirm (デフォルト OFF + opt-in flag)
- 自動 mode は `--evidence-only` (明確な evidence ある時だけ)

### 3.3: `/sb-synthesize` (steal `/obsidian-synthesize`) ✅ 完了 (shell + Wave 2 で JP sub-mode 統合)

- cross-source / entity convergence / concept evolution / orphan rescue 4 並列 subagent
- JP 系 3 サブモード (Phase 2.3 参照) を `--meeting-commitments` / `--proposal-diff` / `--slack-tldr` で切り替え

## Phase 4: Karpathy compliance gap fix ✅ 全完了 (2026-05-05、commit `7419f94`)

AgriciDaniel に対して spec から外れている点を修復:

### 4.1: Sources rewrite 強度 ✅ 完了

- `/sb-ingest` の prompt に "REWRITE the vault — this is the critical step. Don't just create new pages. Rewrite existing ones" を eug から literal copy
- Entities / Concepts / Projects / Contradictions の 4 並列 rewrite agent を ingest 内に組み込み

### 4.2: Anti-pattern guard ✅ 完了

- `/sb-doctor` に "append-only check" を追加 (新規 page だけ生成して既存 page が更新されない pattern を WARN)

### 4.3: Schema 1 SSOT 維持 ✅ no-op 確認済

- `_CLAUDE.md` (eug の dual-file pattern) は **作らない**
- root `CLAUDE.md` 1 枚で完結

## Phase 5: Publish ✅ 完了 (5.1-5.3、5.4 は Out of scope)

### 5.1: Docs ✅ 完了 (commits `1ac783a` 5.1a draft + `489f0e4` 5.1b paste-merge)

- `README.md`: JP / EN 両方、attribution、quick start (5 min install)
- `WALKTHROUGH.md`: 初回 setup → 1 日目 → 1 週間目 → 1 ヶ月目の運用ガイド
- `CHANGELOG.md`: semantic versioning、初回 v0.1.0
- `docs/jp-business-presets.md`: 議事録 / 提案書 / Slack 翻訳 prompt 解説

### 5.2: GitHub ✅ 完了 (USER GATE #1 通過 2026-05-07、release v0.1.0 published)

- public リリース、release notes 作成
- topics: `claude-code`, `obsidian`, `second-brain`, `knowledge-management`, `japanese`, `llm-wiki`, `karpathy`
- README badge: stars / license / version

### 5.3: CC marketplace ✅ 完了 (self-hosted、Premise 修正済)

**実機 verify 結果**: `claude plugin publish` subcommand は **存在しない** (`claude plugin --help` の subcommands は disable / enable / install / list / marketplace / uninstall / update / validate のみ)。`anthropics/claude-code/.claude-plugin/marketplace.json` は社員 bundled 専用 (13 entries 全員 @anthropic.com)。第三者 plugin は **repo 自前の `.claude-plugin/marketplace.json`** + user 側 `claude plugin marketplace add <repo>` で subscribe する self-hosted パターン。

実装内容 (commit `b482fee`):
- `.claude-plugin/plugin.json` version `0.1.0-jp.1` → `0.1.0`
- `.claude-plugin/marketplace.json` version 同期 + `ref: "main"` → `ref: "v0.1.0"` (release integrity)
- README install snippet literal: `claude plugin marketplace add Kazuya-Hibara/claude-second-brain-jp`
- `claude plugin validate` PASS

### 5.4: 認知拡大 (sb-persona-jp.md の channel ranking より)

- X (`#ClaudeCode` 系) で release 告知 + Hero copy 適用
- note 記事 1 本「JP 経営者向け Second Brain プラグイン公開しました」
- connpass で release イベント (主催 or 既存 CC もくもく会で LT)
- Anthropic 公式 JP イベント参加時に自己紹介で言及

## Phase 6: Maintenance

- 週 1 issue triage (1-2h)
- 月 1 release (bug fix + minor feature)
- 顧客フィードバックを priority list に反映
- AgriciDaniel upstream の重要 update を merge (security / breaking changes)

## Risk / mitigation

| Risk | Mitigation |
|---|---|
| 16 個目の clone と認識される | 差別化 7 軸 (JP preset, hot cache 5-layer, time-window, freshness gate 等) を Hero / README 冒頭で明示 |
| AgriciDaniel upstream の breaking change | 月 1 で upstream 確認、3 ヶ月以上不整合は major version bump で吸収 |
| eug 流用部分の credit 不足クレーム | LICENSE と README で attribution、eug 作者に notify (Issue or DM) |
| 顧客が Plugin だけ install して service を買わない | OSS funnel 設計の前提通り。Service は Discovery + 設計 + 月次 review の labor で価値出す |
| Anthropic marketplace 審査落ち | private GitHub release で先行配布、marketplace は後追い |

## Out of scope (v0.1.0)

- LP 作成 (本 repo 内 LP は別タスク)
- Stripe 決済 (Phase 2 of `~/.claude/plans/second-brain-scalable-comet.md`)
- LINE bot (Phase 3 of 同 plan)
- 多言語対応 (JP + EN のみ、CN/KR は v0.2+)
- Plugin auto-update mechanism (CC marketplace 任せ)
