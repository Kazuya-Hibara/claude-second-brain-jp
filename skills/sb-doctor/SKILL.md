---
name: sb-doctor
description: >
  Obsidian wiki vault の健全性を 8 カテゴリで診断する。OMC severity (🔴 CRITICAL /
  🟡 WARN / ⚪ OK) + Safe-auto / Destructive-confirm の二段階 fix を支持。
  eug obsidian-health fork + JP business preset 統合版。
  トリガー: "sb-doctor", "vault 診断", "wiki 健康チェック", "ヘルスチェック",
  "lint", "health check", "orphan check", "frontmatter check"
---

<!-- Adapted from eugeniughelbur/obsidian-second-brain (MIT, commit 69b9acb) -->

# sb-doctor: Vault 健全性診断

vault の健全性を 8 カテゴリで診断し、OMC severity に従って問題を報告する。
10〜15 回の ingest ごと、または週次で実行推奨。

---

## Severity 定義 (OMC 準拠)

| マーク | 意味 | 対応方針 |
|--------|------|----------|
| 🔴 CRITICAL | 即時対応必須。vault の整合性や運用に支障が生じる | 診断完了後すぐに報告、fix 方法を明示 |
| 🟡 WARN | 放置すると問題になるが即座に壊れるわけではない | Safe-auto fix か Destructive-confirm fix に分類して提案 |
| ⚪ OK | 正常、または情報提供のみ | サマリに件数のみ記載 |

---

## 診断ワークフロー

### Step 0: 前提確認

```
1. CLAUDE.md を読み、vault のルートパスを特定する
2. wiki/ ディレクトリが存在するか確認する
3. 存在しない場合: 「Wiki vault が見つかりません。先に /wiki を実行してください。」を表示して終了
4. 引数 --check <category> が指定されている場合は該当 Category のみ実行する
5. 引数 --fix safe が指定されている場合は診断後に Safe-auto fix を一括適用する
```

### Step 1: 8 カテゴリ診断

各カテゴリを順番に実行する。`--check <name>` 指定時は該当カテゴリのみ。

---

## Category 1: Frontmatter Compliance (フロントマター整合性)

**目的**: Memory Freshness Gate に必要な 3 フィールドが全 wiki page に存在するか確認する。

**チェック内容**:

```
対象: wiki/**/*.md (wiki/meta/ 配下を除く)
必須フィールド: Status / Last-verified / Half-life

各ページについて:
- 3 フィールドが全て存在する → ⚪ OK
- 1 つでも欠落 → 🟡 WARN
  メッセージ: "[[PageName]]: 欠落フィールド: <field1>, <field2>"
```

**Fix 方針**:

- Safe-auto fix: 欠落フィールドにデフォルト値を追加
  - `Status: ACTIVE`
  - `Last-verified: <today>`
  - `Half-life: 30d`
  - プレビューを表示してから確認後に適用する

---

## Category 2: Memory Freshness (メモリ鮮度)

**目的**: `(today - Last-verified) > Half-life` のページを検出し、stale な情報を報告する。

**チェック内容**:

```
対象: wiki/**/*.md (frontmatter に Last-verified と Half-life がある全ページ)

各ページについて:
1. Half-life を日数に変換 (14d→14, 30d→30, 90d→90)
2. (today - Last-verified の日付) を計算
3. 経過日数 > Half-life → 🟡 WARN
   メッセージ: "[[PageName]]: Last-verified <date>, Half-life <Xd> (= <N>日超過). Status: <status>"

4. Status: HYPOTHESIS かつ (today - created) > 30日 → 🟡 WARN
   メッセージ: "[[PageName]]: HYPOTHESIS ページが <N>日間放置されています"

5. Status: SUPERSEDED かつ superseded_by: フィールドなし → 🟡 WARN
   メッセージ: "[[PageName]]: SUPERSEDED ですが superseded_by: フィールドがありません"
```

**Fix 方針**:

- Safe-auto fix: 対象なし (stale かどうかの判断は人間が行う)
- Destructive-confirm: Status を SUPERSEDED に変更する (必ず確認を取る)
- 推奨アクション: cheap-disproof を実施してから Status を更新する

---

## Category 3: hot.md サイズ (Hot Cache Size)

**目的**: 5-layer hot cache のトークン効率を維持する。

**チェック内容**:

```
wiki/hot.md          → ワード数 > 300 → 🟡 WARN
wiki/hot-domain-*.md → ワード数 > 300 (各ファイル) → 🟡 WARN
wiki/hot-week.md     → ワード数 > 500 → 🟡 WARN

メッセージ例: "wiki/hot.md: <N>ワード (上限 300w、<M>w 超過)"
```

**Fix 方針**:

- Safe-auto fix: 対象なし (hot cache の内容圧縮は人間の判断が必要)
- 推奨アクション: 超過分を `wiki/hot-week.md` や個別ページに移動する

---

## Category 4: index.md 行長 (Index Line Length)

**目的**: `wiki/index.md` の各エントリが 15 文字以内に収まることを確認する。

**チェック内容**:

```
対象: wiki/index.md の全行 (空行・frontmatter・見出し行を除く)

各行について:
- 文字数 ≤ 15 → ⚪ OK
- 文字数 > 15 → 🟡 WARN
  メッセージ: "wiki/index.md L<N>: '<内容>' は <M>文字 (上限 15文字超過)"
```

**Fix 方針**:

- Destructive-confirm: 長い行を短縮する (内容の変更を伴うため確認必須)
- 推奨アクション: エントリ名を省略形や略語に変更する

---

## Category 5: Append-only Check (Karpathy 準拠確認)

**目的**: Karpathy rewrite principle 違反 (新規ページのみ作成し既存ページを更新しない) を検出する。

**チェック内容**:

```
対象: wiki/log.md の ingest エントリ (直近 10 件)

各エントリを解析:
  ## [YYYY-MM-DD] ingest | <title>
  - Pages created: <list>
  - Pages updated: <list>

Rule 1 (per-ingest): Pages updated: が空 かつ Pages created: ≥ 2 → ⚪ INFO
  メッセージ: "ingest '<title>': <N>ページ作成、更新なし (単発は許容)"

Rule 2 (trend): 3回以上連続で Pages updated: が空 → 🟡 WARN
  メッセージ: "直近 3+ 件の ingest で Pages updated: が空 — rewrite 規律が低下しています"

Rule 3 (aggregate): 直近 10 件の合計で (pages_created / pages_updated) > 5 → 🟡 WARN
  メッセージ: "作成/更新比率 <X>/<Y> = <R> (目標: ≤ 2.0) — vault が追記専用化しています"
```

**Fix 方針**:

- 診断のみ (auto-fix 不適切: rewrite はソース再読み込みと判断が必要)
- 推奨アクション: 直近ソースを再 ingest して `--rewrite-only` パスを実行する

---

## Category 6: Time-window Guard (時間窓ガード)

**目的**: scheduled agent が顧客の業務時間内に実行されていないかチェックする。

**チェック内容**:

```
前提: CLAUDE.md に business_hours schema が定義されている場合のみ実行

business_hours:
  timezone: "Asia/Tokyo"
  weekday: "10:00-19:00"
  weekend: "off"
  holidays: "off"

wiki/log.md の全エントリのタイムスタンプを確認:
- "scheduled" または "cron" を含むエントリが業務時間内のタイムスタンプを持つ → 🟡 WARN
  メッセージ: "[[ログエントリ]]: scheduled agent が業務時間内 (<time> JST) に実行されました"

business_hours schema が未定義の場合: このカテゴリをスキップ
```

**Fix 方針**:

- 診断のみ (スケジュール変更は /schedule agent との連携で対応)

---

## Category 7: business_hours Schema (業務時間スキーマ)

**目的**: CLAUDE.md の `business_hours` 定義が正しい形式で存在するか確認する。

**チェック内容**:

```
CLAUDE.md を読み、business_hours セクションを探す:

存在しない → ⚪ OK (INFO として推奨設定を案内)
  メッセージ: "business_hours schema 未設定。scheduled agent の業務時間外実行を保証するには CLAUDE.md に設定を追加してください (任意)"

存在する場合、以下を検証:
- timezone フィールドの存在と形式 (例: "Asia/Tokyo")
- weekday フィールドの形式 (例: "HH:MM-HH:MM" または "off")
- weekend フィールドの形式
- 時刻範囲が有効 (開始 < 終了)

形式不正 → 🟡 WARN
  メッセージ: "business_hours.<field>: 形式が不正です (<現在値>)"
```

**Fix 方針**:

- Safe-auto fix: 欠落フィールドにデフォルト値を補完 (確認後に適用)

---

## Category 8: Orphan Check (孤立ページ検出)

**目的**: どこからも wikilink で参照されていない孤立ページを検出する。

**チェック内容**:

```
対象: wiki/**/*.md

各ページについて:
1. ページのファイル名 (拡張子なし) を抽出
2. 他の全ページを grep して [[ファイル名]] の wikilink を探す
3. inbound wikilink が 0 件 → ⚪ OK (INFO として報告)
   ※ 孤立ページは即削除対象ではなく、意図的孤立の可能性があるため WARN ではなく INFO

特別除外:
- wiki/hot.md, wiki/hot-week.md, wiki/hot-domain-*.md, wiki/index.md, wiki/log.md
  (これらはシステムページのため孤立チェック対象外)
- wiki/meta/ 配下のファイル (メタ情報のため対象外)

メッセージ例: "[[PageName]]: inbound wikilink なし (孤立ページ候補)"
```

**Fix 方針**:

- Destructive-confirm のみ (孤立ページの削除やアーカイブは必ず確認を取る)
- 推奨アクション: 関連ページからのリンク追加、または意図的孤立として記録

---

## Step 2: レポート生成

診断完了後、`wiki/meta/doctor-report-YYYY-MM-DD.md` にレポートを保存する。

```markdown
---
type: meta
title: "Doctor Report YYYY-MM-DD"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [meta, doctor]
Status: ACTIVE
Last-verified: YYYY-MM-DD
Half-life: 30d
---

# /sb-doctor 診断レポート: YYYY-MM-DD

## サマリ

- スキャン対象ページ数: N
- 🔴 CRITICAL: N 件
- 🟡 WARN: N 件
- ⚪ OK / INFO: N 件

## Category 1: Frontmatter Compliance
<結果>

## Category 2: Memory Freshness
<結果>

## Category 3: hot.md サイズ
<結果>

## Category 4: index.md 行長
<結果>

## Category 5: Append-only Check
<結果>

## Category 6: Time-window Guard
<結果>

## Category 7: business_hours Schema
<結果>

## Category 8: Orphan Check
<結果>

## 推奨アクション

1. Safe-auto fix 可能: N 件 (`/sb-doctor --fix safe` で一括適用可能)
2. 要確認 fix: N 件 (各 Destructive-confirm 項目を参照)
```

---

## Step 3: コンソールサマリ表示

レポート保存後、以下のサマリをコンソールに表示する:

```
/sb-doctor 診断完了

🔴 CRITICAL: N 件
🟡 WARN: N 件
⚪ OK: N 件

詳細レポート: wiki/meta/doctor-report-YYYY-MM-DD.md

Safe-auto fix 可能な項目が N 件あります。
一括適用するには `/sb-doctor --fix safe` を実行してください。
```

---

## Fix 実行ポリシー

### Safe-auto fix (`/sb-doctor --fix safe`)

以下の操作は確認後に自動適用可能:

| 対象 | 操作 |
|------|------|
| Frontmatter 欠落フィールド | `Status: ACTIVE` / `Last-verified: <today>` / `Half-life: 30d` を追加 |
| business_hours 欠落フィールド | デフォルト値を補完 |

プレビューを表示 → ユーザー確認 → 適用の 3 ステップで実行する。

### Destructive-confirm fix

以下の操作は **必ず個別確認** を取る:

| 対象 | 操作 | 理由 |
|------|------|------|
| index.md 長行 | 行を短縮 | 内容の変更を伴う |
| Status を SUPERSEDED に変更 | ステータス変更 | 参照元が壊れる可能性 |
| 孤立ページの削除・アーカイブ | ファイル削除 | 意図的孤立の可能性 |

**自動実行禁止** — 必ず `「〜を実行してよいですか？」` と確認してから実行する。

---

## テスト fixtures (TDD)

`tests/fixtures/sb-doctor/` に以下の acceptance test 用 fixture が存在する:

| fixture | 期待する診断 |
|---------|------------|
| `broken-frontmatter.md` | Category 1: 🟡 WARN (Status 欠落) |
| `expired-halflife.md` | Category 2: 🟡 WARN (Last-verified 96日+ 超過) |
| `long-line-index.md` | Category 4: 🟡 WARN (16文字行を含む) |
| `append-only-page.md` | Category 5: 🟡 WARN (append-only パターン説明) |

---

## eug obsidian-health との対応関係

| eug カテゴリ | sb-doctor カテゴリ | 変更点 |
|------------|-----------------|--------|
| Links (Broken links) | — | wiki-lint が担当のため除外 |
| Duplicates | — | sb-reconcile が担当のため除外 |
| Frontmatter | Category 1 + 2 | JP Memory Freshness Gate (3 必須フィールド) に特化 |
| Staleness | Category 2 | Half-life ベースの期限管理に変換 |
| Orphans | Category 8 | 同等機能、JP 命名 |
| Contradictions | — | sb-reconcile が担当のため除外 |
| Concept gaps | — | wiki-lint が担当のため除外 |
| Stale claims | Category 2 | Half-life gate に統合 |
| (新規) hot.md size | Category 3 | JP 5-layer cache サイズ管理 |
| (新規) index.md line | Category 4 | JP small context window 最適化 |
| (新規) Append-only | Category 5 | Karpathy rewrite principle 検出 |
| (新規) Time-window | Category 6 | JP business hours guard |
| (新規) business_hours | Category 7 | JP business schema 検証 |
