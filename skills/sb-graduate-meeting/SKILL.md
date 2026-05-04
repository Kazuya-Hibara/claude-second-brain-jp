---
name: sb-graduate-meeting
description: "議事録ページから「決定事項」構文 (「〜と決定」「〜が承認」等) を抽出し、ADR (Architecture Decision Record) として wiki/decisions/ に自動書き出しする。複数 commitment は N 件別 ADR file に分割。元議事録に Graduated-to: frontmatter を追記。決定事項なしの場合は no-op。Triggers on: /sb-graduate-meeting, 議事録をADRに, 決定事項をgradiate, 議事録をgradiate"
---

# sb-graduate-meeting: 議事録 → ADR 自動 Graduate

議事録に含まれる「決定事項」を検出し、`wiki/decisions/` に ADR として書き出す。
Karpathy Wiki pattern の「1 SSOT」原則に従い、決定事項は decisions/ ディレクトリで一元管理する。

---

## ワークフロー概要

```
1. 対象議事録ページを特定する
2. commitment 抽出 (regex ベース、JP 構文)
3. commitment ごとに ADR ファイルを生成
4. 元議事録の frontmatter に Graduated-to: を追記
5. 完了サマリを出力
```

---

## Step 1: 対象ページの特定

`/sb-graduate-meeting [page]` で page が指定された場合はそのファイルを読む。
指定なしの場合は `wiki/` 配下の `type: meeting` ページのうち最新の `created:` 日付のものを自動選択する。

```bash
# type: meeting ページを created 日付降順で取得
grep -rl "^type: meeting" wiki/ | head -5
```

vault が未設定 (`wiki/` ディレクトリ不在) の場合は "No wiki vault found. Run /wiki first to set one up." を出力して終了。

---

## Step 2: commitment 抽出 (JP regex)

以下の正規表現パターンで commitment を抽出する。各パターンは行単位で適用。

### 抽出パターン (JP 決定事項構文)

| パターン | 例 |
|---|---|
| `〜と決定` / `〜に決定` | 「2026-06-01 にリリースすると決定した」 |
| `〜が承認` / `〜を承認` | 「エンジニア2名採用が承認された」 |
| `〜と合意` / `〜で合意` | 「移転先をAビルとすることで合意した」 |
| `〜に決まった` / `〜と決まった` | 「予算は100万円に決まった」 |

### regex (Python 相当表記)

```
COMMITMENT_PATTERNS = [
    r'[^。\n]*(?:と決定|に決定)[^。\n]*',
    r'[^。\n]*(?:が承認|を承認)[^。\n]*',
    r'[^。\n]*(?:と合意|で合意)[^。\n]*',
    r'[^。\n]*(?:に決まった|と決まった)[^。\n]*',
]
```

### 抽出手順

1. ページ本文 (frontmatter を除く) をパラグラフ単位で走査する
2. 各パラグラフに上記パターンが含まれる場合、マッチ文字列全体 (センテンス) を commitment として記録する
3. 重複除去する (同一センテンスが複数回出てくる場合は1件に統合)
4. commitment が0件の場合 → **no-op** (Step 3-4 をスキップして Step 5 に進む)

---

## Step 3: ADR ファイルの生成

### ファイル命名規則

- **commitment 1件の場合**: `wiki/decisions/YYYY-MM-DD-<slug>.md`
- **commitment N件の場合**: `wiki/decisions/YYYY-MM-DD-<slug>-1.md`, `YYYY-MM-DD-<slug>-2.md`, ... `YYYY-MM-DD-<slug>-N.md`

`YYYY-MM-DD` = 議事録ページの `created:` frontmatter 値  
`<slug>` = 議事録ページの `title:` frontmatter から生成 (JP タイトルはローマ字 slug 化、スペース→ハイフン、記号除去)  
`N` = 1-indexed の連番 (commitment が複数の場合のみ付与)

### slug 生成ルール

```
title "2026-05-05 経営会議"
  → 日付部分 "2026-05-05" を除去
  → "経営会議" → ローマ字 or 英語サマリ → "keiei-kaigi"
  → slug = "keiei-kaigi"
  → ファイル名 = "wiki/decisions/2026-05-05-keiei-kaigi-1.md"
```

slug 変換に迷う場合は commitment の内容からキーワードを英語で抽出しても良い
(例: 「モバイルアプリ開発優先」→ `mobile-app-priority`)。

### ADR テンプレート (1 commitment = 1 ファイル)

```markdown
---
type: decision
title: "<commitment の簡潔な要約>"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [decision, <議事録の tags から継承>]
Status: ACTIVE
Last-verified: YYYY-MM-DD
Half-life: 90d
source_meeting: "[[<議事録ページ名>]]"
---

# <commitment の簡潔な要約>

## 決定内容

<commitment センテンス (議事録から抜粋)>

## 背景・経緯

<議事録の当該議題セクションから関連コンテキストを抽出して記載>

## 関係者

<議事録の「参加者」または議題セクションから担当者を抽出>

## 期限

<議事録から「期限:」「担当:」情報を抽出。なければ「記載なし」>

## 関連ページ

- 元議事録: [[<議事録ページ名>]]

## 変更履歴

| 日付 | 内容 |
|------|------|
| YYYY-MM-DD | 初版作成 (sb-graduate-meeting による自動 graduate) |
```

---

## Step 4: 元議事録 frontmatter への `Graduated-to:` 追記

生成した ADR ファイルパスを元議事録の frontmatter に追記する。

### commitment 1件の場合 (scalar)

```yaml
Graduated-to: wiki/decisions/2026-05-05-release-date.md
```

### commitment 複数件の場合 (YAML list)

```yaml
Graduated-to:
  - wiki/decisions/2026-05-05-keiei-kaigi-1.md
  - wiki/decisions/2026-05-05-keiei-kaigi-2.md
  - wiki/decisions/2026-05-05-keiei-kaigi-3.md
```

### 追記ルール

- 既に `Graduated-to:` が存在する場合は上書きではなく **マージ** (重複除去して追記)
- frontmatter の末尾 `---` の直前に追加する
- ファイルは **直接編集** する (Read → Edit のペア)

---

## Step 5: 完了サマリの出力

```
## sb-graduate-meeting 完了

議事録: <ページ名>
抽出した commitment: N 件

生成した ADR:
  - wiki/decisions/YYYY-MM-DD-<slug>-1.md → "<要約>"
  - wiki/decisions/YYYY-MM-DD-<slug>-2.md → "<要約>"
  ...

元議事録に Graduated-to: を追記済み。
```

commitment が0件だった場合:

```
## sb-graduate-meeting: no-op

議事録: <ページ名>
決定事項が見つかりませんでした (「〜と決定」「〜が承認」等の構文なし)。
ADR は生成されませんでした。
```

---

## エラーハンドリング

| 状況 | 対応 |
|---|---|
| `wiki/` ディレクトリが存在しない | "No wiki vault found. Run /wiki first." を出力して終了 |
| 指定ページが見つからない | "Page not found: <path>" を出力して終了 |
| `wiki/decisions/` ディレクトリが存在しない | 自動作成してから ADR を書き出す |
| 同名の ADR ファイルが既存 | "ADR already exists: <path>. Skip (use --force to overwrite)." を出力してスキップ |
| frontmatter が壊れている (YAML parse error) | WARN を出力して Graduated-to: 追記をスキップ、ADR 生成は続行 |

---

## Acceptance Test (TDD)

### with-decisions.md (commitment × 1)

**入力**: `tests/fixtures/sb-graduate-meeting/with-decisions.md`  
**期待出力**:
- `wiki/decisions/2026-05-05-<slug>.md` が生成される (1ファイル)
- ADR frontmatter に `type: decision`, `Status: ACTIVE`, `source_meeting:` が含まれる
- 元 fixture frontmatter に `Graduated-to: wiki/decisions/2026-05-05-<slug>.md` が追記される

### with-multiple-decisions.md (commitment × 3)

**入力**: `tests/fixtures/sb-graduate-meeting/with-multiple-decisions.md`  
**期待出力**:
- `wiki/decisions/2026-05-05-<slug>-1.md`, `-2.md`, `-3.md` が生成される (3ファイル)
- 各 ADR は異なる決定内容を持つ
- 元 fixture frontmatter の `Graduated-to:` が YAML list (3件) になる

### no-decisions.md (commitment なし)

**入力**: `tests/fixtures/sb-graduate-meeting/no-decisions.md`  
**期待出力**:
- ADR ファイルは生成されない
- 元 fixture frontmatter に `Graduated-to:` は追記されない
- "no-op" サマリが出力される
