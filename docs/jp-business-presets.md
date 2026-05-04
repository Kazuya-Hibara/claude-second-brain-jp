# JP ビジネス preset ガイド

`/sb-synthesize` のサブモード 3 種と `/sb-graduate-meeting` を合わせた 4 プリセットの解説。JP 経営者 / 1-5 名法人の日常ワークフローに直結するコマンド群。

---

## preset 一覧

| preset | コマンド | 用途 |
|--------|---------|------|
| [議事録コミットメント抽出](#1-議事録コミットメント抽出) | `/sb-synthesize --meeting-commitments` | 議事録から決定 / 期日 / 担当を構造化抽出 |
| [提案書差分比較](#2-提案書差分比較) | `/sb-synthesize --proposal-diff` | 提案書と過去案件 wiki を比較し推奨セクションを提示 |
| [受託案件 ADR 自動生成](#3-受託案件-adr-自動生成) | `/sb-graduate-meeting` | 議事録の決定事項を `wiki/decisions/` へ ADR として昇格 |
| [Slack JP スレッド要約](#4-slack-jp-スレッド要約) | `/sb-synthesize --slack-tldr` | JP Slack スレッドを TL;DR + 関係者 + EN 翻訳に変換 |

---

## 1. 議事録コミットメント抽出

### 概要

議事録テキストから「決定事項 / 期日 / 担当者」を自動抽出し、構造化された commitment リストを生成する。打ち合わせ後のフォローアップ漏れを防ぐ。

### 使い方

```
/sb-synthesize --meeting-commitments wiki/meetings/2026-05-05-キックオフ.md
```

ディレクトリ単位で一括処理:

```
/sb-synthesize --meeting-commitments wiki/meetings/
```

### サブモード詳細

{{SUBMODE_DETAIL_MEETING}}

### 入力ファイルの条件

以下の構文を含む議事録が最も精度高く処理される:

- 「〜と決定」「〜が承認」「〜に決まった」
- 「期限: YYYY-MM-DD」「〜日まで」「〜日までに」
- 「担当: 氏名」「〜さんが担当」「〜チームにて」

---

## 2. 提案書差分比較

### 概要

新しい提案書と、wiki に蓄積された過去案件の情報を比較する。「前回の提案から何が変わったか」「どのセクションを強化すべきか」を Claude が分析して提示する。

### 使い方

```
/sb-synthesize --proposal-diff .raw/提案書_A社_2026Q2.pdf
```

比較対象の wiki ページを明示する場合:

```
/sb-synthesize --proposal-diff .raw/提案書_A社_2026Q2.pdf wiki/projects/A社_Phase1.md
```

### サブモード詳細

{{SUBMODE_DETAIL_PROPOSAL}}

### 典型的なユースケース

- 同一顧客への 2 回目提案前に前回との差分を確認する
- 類似業種への横展開時に過去の成功案件と構成を比較する
- 提案書レビュー前に Claude に「抜けているセクション」を指摘させる

---

## 3. 受託案件 ADR 自動生成

### 概要

`/sb-graduate-meeting` は `/sb-synthesize` のサブモードではなく独立コマンド。議事録の「決定事項」を検出し、Architecture Decision Record (ADR) フォーマットで `wiki/decisions/` に自動書き出しする。

受託案件では「いつ、何を、なぜ決めたか」の記録が後の工程で重要になる。毎回 ADR を手書きするコストを排除する。

### 使い方

```
/sb-graduate-meeting wiki/meetings/2026-05-05-キックオフ.md
```

### 動作

1. 議事録を読み込み、「決定事項」構文を検出
2. 1 件の決定事項 = 1 ADR ファイルを生成

   出力先: `wiki/decisions/2026-05-05-<slug>.md`

   複数決定事項の場合: `wiki/decisions/2026-05-05-<slug>-1.md`, `-2.md`, ...

3. 元議事録に frontmatter を追記:

   ```yaml
   Graduated-to:
     - wiki/decisions/2026-05-05-<slug>.md
   ```

4. 決定事項がない議事録は no-op (新規 ADR を作らない)

### 生成 ADR のフォーマット

```markdown
---
date: 2026-05-05
status: accepted
context: [議事録から抽出したコンテキスト]
---

# [決定事項のタイトル]

## 決定内容

[「〜と決定」構文から抽出した内容]

## 背景

[議事録の前後文から抽出した背景]

## 期日 / 担当

- 期日: [抽出した期日]
- 担当: [抽出した担当者]

## Source

[元議事録への wiki リンク]
```

---

## 4. Slack JP スレッド要約

### 概要

JP で書かれた Slack スレッドを取り込み、TL;DR / 関係者 / アクションアイテム / EN 翻訳を生成する。長い非同期議論を素早くキャッチアップするために使う。

### 使い方

Slack スレッドをテキストとして `.raw/` に保存してから実行:

```
/sb-synthesize --slack-tldr .raw/slack-thread-2026-05-05.txt
```

### サブモード詳細

{{SUBMODE_DETAIL_SLACK}}

### 出力形式

生成されるサマリには以下が含まれる:

- **TL;DR**: 3-5 行で議論の結論を要約
- **関係者**: スレッドに登場した人物と各自のスタンス
- **アクションアイテム**: 次のアクションが必要な項目リスト
- **EN 翻訳** (オプション): 日本語 → 英語の全文翻訳

EN 翻訳を省略したい場合は `--no-translate` フラグを付ける:

```
/sb-synthesize --slack-tldr .raw/slack-thread.txt --no-translate
```

---

## 組み合わせパターン

### 打ち合わせ後の標準フロー

```
# 1. 議事録を取り込む
/sb-ingest .raw/2026-05-05-打ち合わせメモ.md

# 2. コミットメントを抽出する
/sb-synthesize --meeting-commitments wiki/meetings/2026-05-05-打ち合わせ.md

# 3. 決定事項を ADR に昇格する
/sb-graduate-meeting wiki/meetings/2026-05-05-打ち合わせ.md
```

### 提案書作成前の標準フロー

```
# 1. 新しい提案書案を .raw/ に置く
# 2. 過去案件との差分を比較する
/sb-synthesize --proposal-diff .raw/新提案書案.pdf

# 3. Claude が推奨セクションと強化ポイントを提示する
# 4. フィードバックを反映した提案書を再度インジェスト
/sb-ingest .raw/提案書_最終版.pdf
```

---

*Wave 2 (Phase 2.3) 完了後、各サブモード詳細のプレースホルダー (`{{SUBMODE_DETAIL_*}}`) が実装詳細で置換される。*
