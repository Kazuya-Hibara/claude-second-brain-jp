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

**何ができるか**

議事録 markdown を渡すと、本文から「決定事項 / 期日 / 担当者」を自動抽出し、Markdown テーブル形式の commitment リストを出力する。「議論した」「検討中」「保留」などの未決定フレーズを含む段落は自動除外するため、確定した事項だけが抽出される。

**どう呼ぶか**

```
/sb-synthesize --meeting-commitments wiki/meetings/2026-05-05-キックオフ.md
```

**出力形式**

```markdown
## 抽出 commitment

| # | commitment | 期日 | 担当 |
|---|------------|------|------|
| 1 | β版リリース日確定 | 2026-06-01 | [[田中]] |
| 2 | 価格モデル A 採用 | 2026-05-15 | [[佐藤]] |
```

末尾に `合計 N 件の commitment を抽出 (除外パターン M 件)` という 1 行サマリが付く。決定事項がゼロ件の場合は「commitment 検出なし」と明示する。

**期日・担当の認識パターン**

- 期日: `期限:` `期日:` `〜まで` `YYYY-MM-DD` 形式
- 担当: `担当:` `担当者:` または `[[人名]]` wikilink 形式

期日・担当が明記されていない場合は `未指定` と記載する (空欄にはしない)。

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

**何ができるか**

新旧 2 つの提案内容を含む markdown を渡すと、価格 / 納期 / SLA / 契約条項などの軸ごとに差分を比較し、「取り込み推奨 / 却下推奨 / 要検討」の推奨セクションを生成する。過去案件の成功・失敗の教訓を根拠として推奨理由に明示するため、感覚ではなくエビデンスベースで判断できる。

**どう呼ぶか**

```
/sb-synthesize --proposal-diff .raw/提案書_A社_2026Q2.pdf
```

比較対象の wiki ページを明示する場合:

```
/sb-synthesize --proposal-diff .raw/提案書_A社_2026Q2.pdf wiki/projects/A社_Phase1.md
```

**入力ファイルの構成**

`## NEW:` / `## PAST:` の見出しで新旧ブロックを区切るか、比較テーブルを含む形式に対応している。

**出力形式**

```markdown
## 提案 diff & 推奨

| # | 項目 | NEW | PAST | 差分 | 重要度 | 推奨 | 理由 |
|---|------|-----|------|------|--------|------|------|
| 1 | 価格 | $45,000 | $30,000 | +$15,000 (+50%) | HIGH | 要検討 | 顧客規模差を反映するが、PAST 比 50% 増は justification 要 |
```

重要度は `HIGH` (顧客満足 / リスク直結) / `MEDIUM` (運用影響あり) / `LOW` (cosmetic) の 3 段階。末尾に「取り込み推奨」行だけを抜粋したアクションリストと「却下推奨」行のリスク警告セクションを別見出しで提示する。

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

**何ができるか**

JP Slack スレッドの markdown を渡すと、議題の核 / 決着 / 残課題を 3〜5 行の TL;DR に圧縮し、スレッドに登場した関係者と各自の役割を一覧で出力する。frontmatter に `translate_to_en: true` を指定すると EN 翻訳 alias を TL;DR の直後に追加する。

**どう呼ぶか**

```
/sb-synthesize --slack-tldr .raw/slack-thread-2026-05-05.txt
```

EN 翻訳を省略したい場合:

```
/sb-synthesize --slack-tldr .raw/slack-thread.txt --no-translate
```

**入力ファイルの形式**

`**人名** HH:MM メッセージ本文` の繰り返し構造に対応。frontmatter に `translate_to_en: true` を記載すると EN alias が自動付与される。

**出力形式**

```markdown
### TL;DR (JP)
<3-5 行で議題の核 + 決着 + 残課題を要約>

### TL;DR (EN translation alias)
<translate_to_en: true の場合のみ、同じ内容を英語で 3-5 行>

### 関係者 (N 名)
- [[田中]]: リリース PM、QA gate 主催、go/no-go 判定責任者
- [[佐藤]]: マーケ側責任者、press release / LP 公開担当
```

スレッド内の URL や file path への言及は末尾の「### 参照 link」セクションに verbatim で保持する。関係者の役割は役職名だけでなく、発言内容から推論した具体的な責任範囲を 1 行で記載する。

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
