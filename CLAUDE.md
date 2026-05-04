# claude-second-brain-jp — Claude + Obsidian Wiki Vault (JP fork)

This folder is both a Claude Code plugin and an Obsidian vault.

**Plugin name:** `claude-second-brain-jp`
**Forked from:** [`AgriciDaniel/claude-obsidian`](https://github.com/AgriciDaniel/claude-obsidian) (MIT) v1.6.0
**Skills:** `/wiki`, `/wiki-ingest`, `/wiki-query`, `/wiki-lint`, `/save`, `/autoresearch`, `/canvas`
**Vault path:** This directory (open in Obsidian directly)

## What This Vault Is For

JP 経営者 / 1-5 名法人向けの「Second Brain」。Claude が **会社の context を前提として読み取れる土台** を Obsidian + claude-obsidian の派生プラグインで構築・運用する。

Karpathy LLM Wiki pattern を JP solo founder の小 context window 向けに最適化。差別化軸 (詳細は `IMPLEMENTATION-PLAN.md`):

1. **5-layer hot cache** (token efficiency)
2. **Multilingual ingestion** (JP primary、EN alias) — Phase 2.2 で実装予定
3. **JP business synthesis prompts** (議事録 / 提案書 / Slack 翻訳) — Phase 2.3 で実装予定
4. **小 context window 最適化** (hot.md ≤ 300w、index.md 1 行 ≤ 15 文字)
5. **Time-window guard** (顧客の業務時間外で cron / scheduled agent を発火)
6. **Memory freshness gate** (frontmatter `Status` / `Last-verified` / `Half-life` 必須化)
7. **議事録 → ADR auto-graduate** (`/sb-graduate-meeting`) — Phase 2.7 で実装予定

---

## Vault Structure

```
.raw/                source documents — immutable, Claude reads but never modifies
wiki/                Claude-generated knowledge base
  hot.md             session-spanning cache (~300 words、5-layer 最上位)
  hot-domain-{X}.md  domain hot caches (顧客 / 案件 / 提案 / 業務 等、各 ~300 words)
  hot-week.md        weekly aggregation (週末 cron 生成、~500 words)
  index.md           1-line catalog (1 entry ≤ 15 文字)
  log.md             chronological mutations (append-only、新エントリは TOP)
  entities/          people / companies / clients
  concepts/          topics / ideas / frameworks
  projects/          active engagements
  decisions/         ADR (Architecture Decision Records、Phase 2.7 で auto-graduate)
  meta/              dashboards / lint reports
_templates/          Obsidian Templater templates
_attachments/        images and PDFs referenced by wiki pages
```

### Reading order (5-layer)

```
Layer 1: wiki/hot.md            ~300 words   全体サマリ (毎セッション最初に読む)
Layer 2: wiki/hot-domain-{X}.md ~300 words   ドメイン別 (該当 domain がある時だけ)
Layer 3: wiki/hot-week.md       ~500 words   週次集約 (週/月をまたぐ作業時に)
Layer 4: wiki/index.md          1 line ≤ 15  category 別カタログ (検索の入口)
Layer 5: wiki/<page>.md         page-level   個別 page (index で当たりをつけて)
```

Cost-conscious solo founder の context budget を delivery 単位で削るための階層化。`wiki/log.md` は逆順で append-only、frontmatter は flat YAML、internal link は `[[wikilink]]`。

---

## Style Rules (small context window 最適化)

- **`hot.md` max 300 words** — upstream の ~500 words より厳しく絞る。overflow は `wiki/hot-week.md` に bleed
- **`index.md` 1 行 ≤ 15 文字** — category catalog は scan 時間を最短化
- **`hot-domain-{X}.md` max 300 words / 各 domain** — 全 domain 同時 hit でも合計 token が抑えられる
- **`hot-week.md` max 500 words** — 週次集約は少し厚くて OK、ただし 500w 上限
- **wiki page max 100-300 行** — 300 行超えは split 推奨
- **frontmatter は flat YAML** — nested key 禁止
- **dates は `YYYY-MM-DD`** — ISO datetime ではなく日付のみ
- **`/wiki-lint` で hot cache 長さ警告** — 上記閾値超過は WARN

---

## Memory Freshness Gate (frontmatter required)

すべての wiki page は以下の 3 フィールドを **必須** で持つ:

```yaml
---
type: concept | entity | project | decision | source
title: "ページ名"
created: 2026-05-05
updated: 2026-05-05
tags: [domain/foo, ...]
Status: ACTIVE | RESOLVED | SUPERSEDED | HYPOTHESIS
Last-verified: 2026-05-05
Half-life: 14d | 30d | 90d
---
```

### Status semantics

| 値 | 意味 | 信頼度 |
|----|------|--------|
| `ACTIVE` | 現行の正しい動作モデル。Last-verified 時点で実機確認済み | High |
| `RESOLVED` | 過去のインシデント記録。現状は解消済み、再発時の早期診断用に保持 | Historical only |
| `SUPERSEDED` | 別 page に置き換えられた。参照先を frontmatter `superseded_by:` で明示 | Redirect only |
| `HYPOTHESIS` | 仮説ベース。cheap-disproof 未完了 | **Do not apply blindly** |

### Half-life の目安

| カテゴリ | Half-life | 理由 |
|----------|-----------|------|
| 外部 CLI / SDK / ツール | **14d** | release cadence が速く、breaking change が頻出 |
| API / SaaS | **30d** | エンドポイント・schema は比較的安定だが認証方式や quota が変わる |
| Workflow / 運用フロー | **30d** | rule 追加で運用が変わる頻度がそれなり |
| Infrastructure / OS / Claude Code harness | **90d** | macOS update / Claude Code release に合わせて再検証 |
| 議事録 / 決定事項 (ADR) | **90d** | 決定事項は持続するが 90 日で再確認 |

### Read-time gate

wiki page を参照する時:

1. **frontmatter 確認**: `Status` と `Last-verified`、`Half-life` を読む
2. **(today - Last-verified) > Half-life** の場合 → 記載内容を **ADVISORY only** として扱う。再採用前に cheap-disproof
3. **Status: HYPOTHESIS** → 同様に cheap-disproof 先行
4. **Status: RESOLVED** → 過去事例として参考にするが、「今そこに問題がある」前提で読まない
5. **Status: SUPERSEDED** → `superseded_by:` の参照先を読む

### `/wiki-lint` でのチェック

- frontmatter 3 フィールド (`Status` / `Last-verified` / `Half-life`) のいずれか欠落 = 🟡 WARN
- `(today - Last-verified) > Half-life` の page = 🟡 WARN (`stale claims` セクション)
- `Status: HYPOTHESIS` で 30 日以上経過 = 🟡 WARN (放置仮説の検出)

---

## Business Hours Schema

vault の運用主体である顧客企業の業務時間を schema に持たせる。`/schedule` agent や cron で発火する scheduled task は **業務時間外** にのみ走るようにする。

```yaml
# CLAUDE.md 冒頭または別 schema file に
business_hours:
  timezone: "Asia/Tokyo"
  weekday: "10:00-19:00"  # JST
  weekend: "off"          # off | "10:00-18:00" 等
  holidays: "off"         # off | "10:00-18:00" 等
```

### 効果

- 顧客が朝 vault を開いた時にすでに **最新化されている**
- 業務中に LLM API 呼び出しが裏で走らない (顧客の Pro クォータ消費を avoid)
- ingest / digest / doctor の重い処理は深夜帯か週末にずれる

### `/wiki-lint` でのチェック

- `business_hours` schema 不在 = ⚪ INFO (推奨設定)
- 業務時間内に scheduled agent が走った形跡 (log.md timestamp) = 🟡 WARN

### `/schedule` agent との連携

scheduled agent 登録時に上記 `business_hours` を参照、`weekday "10:00-19:00"` の枠を avoid して cron 時刻を選ぶ。詳細実装は Phase 2 後半で `/schedule` 連携時に。

---

## How to Use

Drop a source file into `.raw/`, then tell Claude: "ingest [filename]".

Ask any question. Claude reads `wiki/hot.md` (Layer 1) first, then `wiki/index.md` (Layer 4), then drills into relevant pages (Layer 5). Domain-specific question なら Layer 2 の `wiki/hot-domain-{X}.md` も先に読む。

Run `/wiki` to scaffold a new vault or check setup status.

Run "lint the wiki" every 10-15 ingests to catch orphans, gaps, and **stale claims** (memory freshness gate に基づく).

---

## Cross-Project Access

To reference this wiki from another Claude Code project, add to that project's CLAUDE.md:

```markdown
## Wiki Knowledge Base
Path: /path/to/this/vault

When you need context not already in this project, follow 5-layer reading order:
1. Read wiki/hot.md first (Layer 1, ~300 words)
2. If domain-specific: read wiki/hot-domain-<domain>.md (Layer 2)
3. If week/month-spanning: read wiki/hot-week.md (Layer 3)
4. If still not enough: read wiki/index.md (Layer 4)
5. Drill into individual wiki pages (Layer 5)

Memory Freshness Gate:
- Check frontmatter Status / Last-verified / Half-life on every page
- (today - Last-verified) > Half-life → treat as ADVISORY only, run cheap-disproof
- Status: HYPOTHESIS → cheap-disproof before applying

Do NOT read the wiki for general coding questions or things already in this project.
```

---

## Plugin Skills

| Skill | Trigger |
|-------|---------|
| `/wiki` | Setup, scaffold, route to sub-skills |
| `ingest [source]` | Single or batch source ingestion (memory freshness frontmatter 自動付与) |
| `query: [question]` | Answer from wiki content (frontmatter freshness gate を read-time に適用) |
| `lint the wiki` | Health check (orphans / dead links / **stale claims** / **append-only anti-pattern** 検出) |
| `/save` | File the current conversation as a structured wiki note |
| `/autoresearch [topic]` | Autonomous research loop |
| `/canvas` | Visual layer: add images, PDFs, notes to Obsidian canvas |

---

## MCP (Optional)

If you configured the MCP server, Claude can read and write vault notes directly.
See `skills/wiki/references/mcp-setup.md` for setup instructions.

---

## Roadmap

- ✅ Phase 1 (2026-05-05): Fork + JP attribution + plugin metadata
- 🚧 Phase 2 部分完了 (2026-05-05): 5-layer hot cache (2.1) / 小 context 最適化 (2.4) / business_hours (2.5) / memory freshness gate (2.6)
- ⏳ Phase 2 残: multilingual ingest (2.2) / JP synthesis prompts (2.3) / 議事録→ADR (2.7)
- ⏳ Phase 3: eug 3 commands 移植 (`/sb-doctor` / `/sb-reconcile` / `/sb-synthesize`)
- 🚧 Phase 4 (2026-05-05): rewrite emphasis (4.1) / append-only anti-pattern lint (4.2) / 1 SSOT 維持 (4.3、no-op confirmed)
- ⏳ Phase 5: docs 全面 JP 化 / GitHub release / CC marketplace submit / 認知拡大

詳細: `IMPLEMENTATION-PLAN.md` 参照。
