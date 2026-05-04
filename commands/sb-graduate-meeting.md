---
description: 議事録ページから「決定事項」構文を抽出し、ADR (Architecture Decision Record) として wiki/decisions/ に自動書き出しする。決定事項がない場合は no-op。
---

Read the `sb-graduate-meeting` skill. Then run the graduate-meeting workflow for the specified meeting page.

Usage:
- `/sb-graduate-meeting [page]` — 指定した議事録ページの決定事項を ADR に変換
- `/sb-graduate-meeting` — 直近の議事録ページを自動検出して変換

## 動作概要

1. 議事録ページのテキストから「決定事項」構文 (「〜と決定」「〜が承認」等) を抽出する
2. 抽出した commitment ごとに `wiki/decisions/YYYY-MM-DD-<slug>.md` へ ADR を書き出す
3. commitment が複数の場合は `YYYY-MM-DD-<slug>-1.md`, `YYYY-MM-DD-<slug>-2.md`, ... と suffix N で別ファイル生成
4. 元の議事録ページ frontmatter に `Graduated-to:` を追記する (複数の場合は YAML list)
5. 決定事項が見つからない場合は no-op (何も生成しない)

## 例

```
/sb-graduate-meeting wiki/2026-05-05-weekly.md
```

議事録に「2026-06-01 にリリースすると決定した」が含まれる場合:
- `wiki/decisions/2026-05-05-release-date.md` を生成
- 元ページ frontmatter に `Graduated-to: wiki/decisions/2026-05-05-release-date.md` を追記

複数の決定事項がある場合:
- `wiki/decisions/2026-05-05-decision-1.md`, `-2.md`, `-3.md` を生成
- 元ページ frontmatter に `Graduated-to:` YAML list で追記

If no wiki vault is set up yet, say: "No wiki vault found. Run /wiki first to set one up."
