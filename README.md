
# claude-second-brain-jp

> **Status**: v0.1.0 (Phase 1-5 完了)
> **Forked from**: [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian) (MIT)
> **Maintainer**: [Kazuya Hibara](https://github.com/Kazuya-Hibara) — `contact@kazuyahibara.com`

[![Forked from](https://img.shields.io/badge/Forked_from-AgriciDaniel%2Fclaude--obsidian-orange)](https://github.com/AgriciDaniel/claude-obsidian)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-plugin-8B5CF6)](https://code.claude.com/docs/en/discover-plugins)
[![Version](https://img.shields.io/badge/Version-v0.1.0-green)](https://github.com/Kazuya-Hibara/claude-second-brain-jp/releases/tag/v0.1.0)

---

## 日本語

JP 経営者 / 1-5 名法人向け Claude + Obsidian 第二の脳プラグイン。[Karpathy LLM Wiki パターン](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) を **小 context window** と **日本語ビジネスワーク** 向けに最適化。

### なぜ claude-second-brain-jp か

汎用の Obsidian AI プラグインは「既存ノートへの質問」に特化している。本プラグインは知識を **自律的に構築・維持・進化** させる。さらに日本の経営現場特有のワーク (議事録 → ADR 変換、提案書差分比較、Slack JP スレッド要約) を組み込み専用コマンドとして提供する。

| 機能 | claude-second-brain-jp | 汎用 AI プラグイン |
|---|---|---|
| **5-layer hot cache** | wiki/hot.md から wiki/<page>.md まで 5 段階を自動管理 | なし |
| **JP ビジネス preset** | 議事録 / 提案書 / 受託案件 / Slack 翻訳 専用コマンド | なし |
| **業務時間外ガード** | `business_hours` フィールドで cron を制限 | なし |
| **memory freshness gate** | `Status / Last-verified / Half-life` で陳腐化を検出 | なし |
| **Karpathy literal 準拠** | 新規作成だけでなく既存ページの rewrite を強制 | まちまち |
| **矛盾検出 + 調停** | `/sb-reconcile` で evidence-based winner 自動判定 | なし |
| **Wiki 健全性診断** | `/sb-doctor` で 8 カテゴリ Severity 付き診断 | なし |
| **自律知識合成** | `/sb-synthesize` で 4 並列 fold + JP サブモード | なし |

### クイックスタート (5 分インストール)

**Step 1: プラグインを追加**

```bash
claude plugin marketplace add Kazuya-Hibara/claude-second-brain-jp
```

**Step 2: プラグインをインストール**

```bash
claude plugin install claude-second-brain-jp@claude-second-brain-jp-marketplace
```

**Step 3: Obsidian vault を開く**

Obsidian で vault フォルダを開き、Claude Code を同じフォルダで起動する。

**Step 4: 初期化**

Claude Code セッションで入力:

```
/wiki
```

Claude が vault の設定チェック → scaffold → 使い方案内の順で起動する。

インストール確認:

```bash
claude plugin list
```

### 主要コマンド

| コマンド | 動作 |
|---------|------|
| `/wiki` | vault セットアップ確認 / scaffold / 継続 |
| `/sb-ingest [ファイル]` | JP/EN 自動判定でソースを取り込み、8-15 wiki ページを生成 |
| `/sb-doctor` | 8 カテゴリ健全性診断 (frontmatter / freshness / hot.md サイズ / index 行長 / append-only / time-window / business_hours / orphan) |
| `/sb-reconcile` | 矛盾ページを evidence-based で自動調停 |
| `/sb-synthesize` | 4 並列 fold で知識を横断合成 |
| `/sb-graduate-meeting` | 議事録の決定事項を ADR として `wiki/decisions/` へ自動昇格 |
| `/save` | 現在の会話を wiki ノートとして保存 |
| `/autoresearch [トピック]` | 自律 web 調査ループ: 検索 → 取得 → 合成 → 保存 |

### 機能ハイライト

**5-layer hot cache**

```
Layer 1: wiki/hot.md            ~300 words   全体サマリ (セッション間コンテキスト)
Layer 2: wiki/hot-domain-{X}.md ~300 words   ドメイン別 (顧客 / 案件 / 提案 / 業務)
Layer 3: wiki/hot-week.md       ~500 words   週次集約
Layer 4: wiki/index.md          1 行 ≤ 15 文字  カテゴリ別カタログ
Layer 5: wiki/<page>.md         page-level   個別ページ
```

Claude は質問に答える際、Layer 1 から順に読み進め、必要最小限のコンテキストで動作する。小 context window (Claude Haiku 等) でも高精度を維持。

**JP ビジネス preset**

`/sb-synthesize` のサブモードで日本語ビジネス文書を処理:

- `--meeting-commitments`: 議事録から決定事項 / 期日 / 担当を構造化抽出
- `--proposal-diff`: 提案書と過去案件 wiki を比較し、推奨セクションを提示
- `--slack-tldr`: JP Slack スレッドを要約 + 関係者整理 + EN 翻訳

詳細: [docs/jp-business-presets.md](docs/jp-business-presets.md)

**業務時間外ガード**

CLAUDE.md に `business_hours` フィールドを設定すると、scheduled agent が業務時間外にのみ動作する。`/sb-doctor` で業務時間内発火を 🟡 WARN として検出。

```yaml
business_hours:
  timezone: "Asia/Tokyo"
  weekday: "10:00-19:00"
  weekend: "off"
  holidays: "off"
```

**memory freshness gate**

すべての wiki ページに 3 フィールドを必須化。`(today - Last-verified) > Half-life` になったページは自動で ADVISORY 扱いとなり、`/sb-doctor` が警告を出す。

```yaml
Status: ACTIVE
Last-verified: 2026-05-05
Half-life: 30d
```

**Karpathy literal 準拠**

`/sb-ingest` は "REWRITE the vault — this is the critical step. Don't just create new pages. Rewrite existing ones." を強制する。Entities / Concepts / Projects / Contradictions の 4 並列エージェントが既存ページを更新し続ける。

### 初回セットアップ詳細

詳細な運用ガイド: [WALKTHROUGH.md](WALKTHROUGH.md)

---

## English

JP-focused Claude + Obsidian second-brain plugin for solo founders and small teams (1-5 people). Optimizes the [Karpathy LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) for small context windows and Japanese business workflows.

### Key features

- **5-layer hot cache**: tiered context management from global summary to individual pages
- **JP business presets**: dedicated commands for meeting minutes, proposal diffs, Slack summaries
- **Business hours guard**: `business_hours` field restricts scheduled agents to off-hours
- **Memory freshness gate**: `Status / Last-verified / Half-life` frontmatter detects stale knowledge
- **Karpathy literal compliance**: forces vault rewrite (not just new page creation) on every ingest
- **Wiki health diagnostics**: `/sb-doctor` with 8-category severity scoring
- **Conflict reconciliation**: `/sb-reconcile` with evidence-based winner selection
- **Knowledge synthesis**: `/sb-synthesize` with 4 parallel folds + JP sub-modes

### Quick start

```bash
# Step 1: add marketplace
claude plugin marketplace add Kazuya-Hibara/claude-second-brain-jp

# Step 2: install plugin
claude plugin install claude-second-brain-jp@claude-second-brain-jp-marketplace
```

Open your Obsidian vault folder in Claude Code. Type `/wiki` to begin.

### Attribution

- Forked from [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian) (MIT) — upstream knowledge engine foundation
- eug commands (`/sb-doctor`, `/sb-reconcile`, `/sb-synthesize`) adapted from [eugeniughelbur/obsidian-second-brain](https://github.com/eugeniughelbur/obsidian-second-brain) (MIT, commit `69b9acb`)
- Based on [Andrej Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
- Built by [Kazuya Hibara](https://github.com/Kazuya-Hibara)

Full attribution details: [ATTRIBUTION.md](ATTRIBUTION.md)

---

*MIT License. See [LICENSE](LICENSE) for details.*
