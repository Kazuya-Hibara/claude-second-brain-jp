# Changelog

All notable changes to **claude-second-brain-jp** (JP fork) and the upstream **claude-obsidian** lineage that preceded it. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: [SemVer](https://semver.org/) + JP fork suffix `-jp.N`.

## [0.1.0-jp.1] - 2026-05-05 (JP fork — Phase 1 + Phase 2 部分 + Phase 4)

`claude-second-brain-jp` initial release. Forked from upstream `AgriciDaniel/claude-obsidian@v1.6.0` (MIT). JP 経営者 / 1-5 名法人向けに schema preset + small-context optimization + memory freshness gate + Karpathy compliance fix を追加。

### Phase 1 — Fork attribution + plugin metadata

- `LICENSE`: 桧原和也 (Kazuya Hibara) copyright を AgriciDaniel の隣に追記、MIT 互換維持。
- `.claude-plugin/plugin.json`: name → `claude-second-brain-jp`、version → `0.1.0-jp.1`、author / homepage / repository / description / keywords を JP 向けに更新 (議事録・提案書・受託案件・Slack 翻訳 keywords 追加)。
- `.claude-plugin/marketplace.json`: 同上。Phase 5 で Anthropic 公式 marketplace へ submit 予定。
- `README.md`: 冒頭に Phase 1 status banner + fork attribution + JP positioning。upstream README 本文は Phase 5 で全面差替予定、それまで保持。
- `ATTRIBUTION.md`: 派生宣言を冒頭追加、末尾に fork-side author / repository / contact / forked-at 情報。
- `IMPLEMENTATION-PLAN.md`: Phase 0-5 の roadmap、上流 SSOT (kazuyahibara/Second-brain repo) を fork repo にも複製。

### Phase 2.1 — 5-layer hot cache (`CLAUDE.md`)

upstream の `wiki/hot.md` (~500 words) を 5 階層に拡張:

```
Layer 1: wiki/hot.md            ~300 words   全体サマリ
Layer 2: wiki/hot-domain-{X}.md ~300 words   ドメイン別 (顧客 / 案件 / 提案 / 業務)
Layer 3: wiki/hot-week.md       ~500 words   週次集約 (週末 cron 生成)
Layer 4: wiki/index.md          1 行 ≤ 15 文字 category 別カタログ
Layer 5: wiki/<page>.md         page-level   個別 page
```

CLAUDE.md の Reading order を 4-layer → 5-layer に更新、Cross-Project Access ブロックも 5-layer 順序に更新。

### Phase 2.4 — Small context window optimization (`CLAUDE.md`)

- `hot.md` max **300 words** (upstream の 500 から厳格化)
- `index.md` 1 行 max **15 文字**
- `hot-domain-{X}.md` max 300 words / domain
- `hot-week.md` max 500 words
- wiki page max 100-300 行 (upstream 踏襲)
- `/wiki-lint` で hot cache 長さ警告を追加 (Lint Check #11)

### Phase 2.5 — `business_hours` time-window guard (`CLAUDE.md`)

```yaml
business_hours:
  timezone: "Asia/Tokyo"
  weekday: "10:00-19:00"
  weekend: "off"
  holidays: "off"
```

`/schedule` agent や cron で発火する scheduled task は業務時間外にのみ走るようにする。`/wiki-lint` で業務時間内発火を WARN (Lint Check #12)。`/schedule` 連携の実装本体は Phase 2 後半に持ち越し。

### Phase 2.6 — Memory freshness gate (frontmatter required)

すべての wiki page で 3 フィールドを必須化:

```yaml
Status: ACTIVE | RESOLVED | SUPERSEDED | HYPOTHESIS
Last-verified: 2026-05-05
Half-life: 14d | 30d | 90d
```

- Half-life 推奨値表 (CLI/SDK = 14d、API/workflow = 30d、infra/decisions = 90d) を CLAUDE.md に明記
- Read-time gate (`(today - Last-verified) > Half-life` → ADVISORY only、再採用前に cheap-disproof) を documentation 化
- `skills/wiki-ingest/SKILL.md`: Single Source Ingest steps 3-5 で freshness frontmatter を **必須付与** に変更。新ページ用テンプレ + page type 別 Half-life デフォルト表を追加。
- `skills/wiki-lint/SKILL.md`: Memory Freshness Check section を追加 (Lint Check #9)。完全性 / Half-life 超過 / 長期 HYPOTHESIS / SUPERSEDED orphans の 4 種を検出。

### Phase 4.1 — Sources rewrite emphasis (`skills/wiki-ingest/SKILL.md`)

Karpathy LLM Wiki の literal 原則 "REWRITE the vault — this is the critical step. Don't just create new pages. Rewrite existing ones." を冒頭に明記。4 並列 rewrite pass (Entities / Concepts / Projects / Contradictions) を Single Source Ingest step 4-7 に組み込み。Acceptance test として `pages_updated count ≥ pages_created count` を提示。

### Phase 4.2 — Append-only anti-pattern lint (`skills/wiki-lint/SKILL.md`)

`wiki/log.md` を解析し、「new page だけ作成、既存 page 更新ゼロ」が連続するパターンを検出 (Lint Check #10):

- 単発: 単一 ingest で `Pages updated:` 空 = ⚪ INFO
- 連続: 3+ ingests で `Pages updated:` 空 = 🟡 WARN
- 集計: 直近 10 ingests で create/update 比率 > 5 = 🟡 WARN

### Phase 4.3 — Schema 1 SSOT 維持 (no-op)

upstream の `CLAUDE.md` 1 枚 SSOT を維持。eug の dual-file pattern (`CLAUDE.md` + `_CLAUDE.md`) は **作らない**。Phase 4.3 は no-op 確認のみ、構造変更なし。

### Deferred to next milestone

- Phase 2.2: Multilingual ingestion (`/sb-ingest` JP/EN auto-detect、frontmatter `aliases:` 自動生成)
- Phase 2.3: JP business synthesis prompts (`--meeting-commitments` / `--proposal-diff` / `--slack-tldr`)
- Phase 2.7: 議事録 → ADR auto-graduate (`/sb-graduate-meeting`)
- Phase 3: eug 3 commands 移植 (`/sb-doctor` / `/sb-reconcile` / `/sb-synthesize`)
- Phase 5.2: GitHub release v0.1.0
- Phase 5.3: CC marketplace submit (user 承認 + Anthropic 審査)
- Phase 5.4: 認知拡大 (X / note / connpass)

詳細: `IMPLEMENTATION-PLAN.md`。

---

## Upstream history (claude-obsidian)

下記は upstream の `AgriciDaniel/claude-obsidian` の履歴。fork base は v1.6.0。

## [1.6.0] - 2026-04-24

### Added (DragonScale Mechanism 4, opt-in)

- **Boundary-first autoresearch**: `scripts/boundary-score.py` computes `(out_degree - in_degree) * recency_weight` across the wikilink graph and emits top-K frontier pages. `/autoresearch` invoked without a topic now offers the top-5 frontier pages as research candidates when the vault has adopted DragonScale.
- `tests/test_boundary_score.py` — 35 unit tests covering frontmatter parsing, recency weight, wikilink extraction (with code-block guard), graph construction, scoring, CLI interface.
- `make test-boundary` target + integration into `make test`.

### Changed

- `skills/autoresearch/SKILL.md` — new Topic Selection section with three paths: explicit (A), boundary-first (B, opt-in), user-ask (C, default without DragonScale).
- `commands/autoresearch.md` — no-topic usage documented for both modes.
- `wiki/concepts/DragonScale Memory.md` — Mechanism 4 flipped from NOT IMPLEMENTED to shipped; exact scoring formula and "what is NOT included" callout added. Version bumped to v0.4.
- Version synced to 1.6.0 across plugin.json and marketplace.json.

## [1.5.1] - 2026-04-24 (Phase 3.6 hardening)

### Fixed

- `scripts/tiling-check.py`: `--report PATH` now resolved against VAULT_ROOT and rejected if it escapes (security: prevents hostile or accidental writes outside the vault).
- `.vault-meta/legacy-pages.txt`: rollout baseline corrected from 2026-04-24 to 2026-04-23 (matches earliest addressed page in the seed vault).
- `AGENTS.md`: wiki-fold listed in the skills table; stale claim that "all skills use only name/description" narrowed to newer skills (older skills still carry allowed-tools for Claude Code compatibility).
- `skills/wiki-ingest/SKILL.md`: resolves the internal contradiction between "immutable .raw/" and "maintain .raw/.manifest.json" — user-dropped source documents remain immutable; only the manifest is wiki-ingest-maintained.
- `docs/install-guide.md`: version 1.2.0 -> 1.5.0 with a DragonScale optional-install callout.

## [1.5.0] - 2026-04-24

### Added (DragonScale Memory extension, opt-in)

- **Mechanism 1 — Fold operator** (`skills/wiki-fold/`): extractive, structurally-idempotent rollups of `wiki/log.md` entries into per-batch meta-pages under `wiki/folds/`. Dry-run via stdout by default (does not trigger PostToolUse auto-commit hook); commit mode explicit.
- **Mechanism 2 — Deterministic page addresses** (opt-in): `scripts/allocate-address.sh` flock-guarded atomic allocator; new `address: c-NNNNNN` frontmatter convention; re-ingest idempotency via `.raw/.manifest.json address_map`. `wiki-ingest` and `wiki-lint` skills feature-detect DragonScale setup.
- **Mechanism 3 — Semantic tiling lint** (opt-in): `scripts/tiling-check.py` uses local `nomic-embed-text` via ollama to flag candidate duplicate pages by cosine similarity. Banded thresholds (error/review/pass) documented as conservative seeds with manual calibration procedure.
- `wiki/concepts/DragonScale Memory.md` — full design spec (v0.3) with four mechanisms, scope boundary, and primary-source citations.
- `bin/setup-dragonscale.sh` — idempotent installer that provisions `.vault-meta/` counter, thresholds, and legacy-pages manifest.
- `tests/` — shell + python test suite for the allocator and tiling-check. Run via `make test`.
- `Makefile` — developer targets (`test`, `setup-dragonscale`, `clean-test-state`).

### Changed

- `hooks/hooks.json` PostToolUse now stages `.vault-meta/` in addition to `wiki/` and `.raw/` so DragonScale runtime state is captured by the auto-commit hook.
- `skills/wiki-ingest/SKILL.md` and `skills/wiki-lint/SKILL.md` gained opt-in DragonScale sections behind feature-detection guards; original behavior unchanged for vaults that have not run `setup-dragonscale.sh`.
- `agents/wiki-ingest.md` explicitly forbids parallel sub-agents from calling the allocator (single-writer rule for address assignment).
- `agents/wiki-lint.md` extended to describe Address Validation and Semantic Tiling checks.
- Stale `allowed-tools` frontmatter removed from `wiki-ingest` and `wiki-lint` SKILL.md (kepano convention: only `name` and `description`).
- Version strings synced across `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, and documentation.

### Security

- `scripts/tiling-check.py` locks `OLLAMA_URL` to localhost by default. Remote endpoints require `--allow-remote-ollama`. Symlinks and vault-root escapes are rejected before any read.

### Not in this release

- **Mechanism 4 — Boundary-first autoresearch**: documented in the spec as a future proposal; no code shipped. `skills/autoresearch/SKILL.md` unchanged.

## [1.4.3] - prior

Previous state. See git log for details.
