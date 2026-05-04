# WALKTHROUGH — claude-second-brain-jp 運用ガイド

JP 経営者 / 1-5 名法人向けの実践的な使い方ガイド。インストール完了後、このファイルを読みながら進めることで第二の脳が動き始める。

---

## 初回セットアップ (30 分)

### 前提条件

- Claude Code がインストール済みであること
- Obsidian がインストール済みであること
- プラグインのインストールが完了していること

インストール手順:

```bash
claude plugin marketplace add Kazuya-Hibara/claude-second-brain-jp
claude plugin install claude-second-brain-jp@claude-second-brain-jp-marketplace
```

### Step 1: vault フォルダを決める

第二の脳として使うフォルダを決める。既存の Obsidian vault でも、新規フォルダでも問題ない。

```bash
# 新規の場合: フォルダを作成
mkdir ~/second-brain
cd ~/second-brain
```

### Step 2: Obsidian で vault を開く

Obsidian を起動し、「Manage Vaults → Open folder as vault」で上記フォルダを指定する。

### Step 3: Claude Code を同じフォルダで起動

```bash
cd ~/second-brain
claude
```

### Step 4: 初期化コマンドを実行

```
/wiki
```

Claude が以下の順で自動実行する:

1. vault 構造の確認・作成 (`wiki/`, `wiki/index.md`, `wiki/hot.md` 等)
2. CLAUDE.md の設定確認 (business_hours、freshness gate 等)
3. 最初の質問: 「この vault は何のために使いますか?」

### Step 5: 業務時間の設定

Claude が CLAUDE.md を設定する際、以下を伝える:

```
業務時間は平日 10:00-19:00 JST です
```

設定後の CLAUDE.md に以下が追加される:

```yaml
business_hours:
  timezone: "Asia/Tokyo"
  weekday: "10:00-19:00"
  weekend: "off"
  holidays: "off"
```

### Step 6: 動作確認

```
/sb-doctor
```

初回は「wiki が空です」という報告が出る。これが正常な初期状態。

---

## 1 日目 — 最初の知識を取り込む

### 既存の資料を取り込む

手元にある資料 (提案書 PDF、議事録テキスト、顧客情報等) を vault フォルダの `.raw/` に置き、取り込む:

```
/sb-ingest .raw/提案書_2026Q2.pdf
```

Claude が以下を自動実行する:

1. ドキュメントを読み込み、エンティティ・概念・プロジェクトを抽出
2. 8-15 件の wiki ページを生成
3. `wiki/index.md` にカタログ登録
4. `wiki/hot.md` を更新

取り込み後に確認:

```
wiki に何が入りましたか?
```

### 議事録を ADR に変換する

「〜と決定」「〜が承認」「期限: YYYY-MM-DD」「担当: 氏名」を含む議事録があれば:

```
/sb-graduate-meeting wiki/meetings/2026-05-05-キックオフ.md
```

`wiki/decisions/2026-05-05-<slug>.md` に ADR ファイルが自動生成される。元の議事録には `Graduated-to:` frontmatter が追記される。

### 知識に質問する

```
A 社の提案書で競合との差別化ポイントは何でしたか?
```

Claude は `wiki/hot.md` → `wiki/index.md` → 関連ページの順に読み進め、wiki ページを引用しながら回答する。

---

## 1 週間目 — 日常ワークフローを確立する

### 毎日の使い方パターン

**朝 (セッション開始時)**

Claude Code を開くと、hooks が自動で `wiki/hot.md` を読み込む。前回セッションのコンテキストが即座に復元される。

**作業中**

打ち合わせの後や資料を受け取ったタイミングで取り込む:

```
/sb-ingest .raw/[ファイル名]
```

会話の内容を wiki に残す:

```
/save キックオフ会議メモ
```

**夕方 (セッション終了前)**

```
update hot cache
```

---

### `/sb-doctor` で健全性を定期確認

週に 1 回を目安に実行する:

```
/sb-doctor
```

出力例:

```
🔴 CRITICAL  frontmatter 欠落: wiki/meetings/2026-05-01.md (Status, Last-verified 未設定)
🟡 WARN      memory freshness: wiki/entities/A社.md (Last-verified が 31 日超過)
🟡 WARN      append-only: 直近 3 ingests で既存ページ更新ゼロ
⚪ INFO       orphan: wiki/concepts/旧提案フレームワーク.md (被リンクなし)
```

CRITICAL は即日対応、WARN は今週中に対応するのが目安。

---

### `/sb-reconcile` で矛盾を解消する

同じ顧客や案件について複数のページが矛盾する情報を持っていると、Claude が自動検出する。

```
/sb-reconcile
```

evidence が明確な場合は自動解決される。ambiguous な場合は確認を求められる:

```
wiki/entities/A社.md と wiki/projects/A社_Phase1.md で「契約単価」が矛盾しています。
どちらを正として採用しますか?
  A) 2026-04-15 の議事録を根拠とする wiki/entities/A社.md (¥500,000/月)
  B) 2026-05-01 の提案書を根拠とする wiki/projects/A社_Phase1.md (¥480,000/月)
```

---

### `/sb-synthesize` で横断的な知識をまとめる

複数の案件・顧客・ソース間に共通するパターンを発見したいとき:

```
/sb-synthesize
```

4 並列の fold が実行される:

- **cross-source fold**: 複数ソースで言及される概念を統合
- **entity convergence fold**: 同一エンティティへの記述を収束
- **concept evolution fold**: 時系列で変化した概念を追跡
- **orphan rescue fold**: 孤立ページを既存ネットワークに接続

JP ビジネス向けサブモード:

```
/sb-synthesize --meeting-commitments wiki/meetings/
```

詳細: [docs/jp-business-presets.md](docs/jp-business-presets.md)

---

## 1 ヶ月目 — 知識が複利で積み上がる段階

### 知識グラフの成長を確認する

Obsidian の Graph View を開く。1 ヶ月間のインジェストで、エンティティ・概念・プロジェクトが網の目状につながっているはずだ。

中心ノードが自然と浮かび上がる。これが現在の業務における「核心知識」であり、経営判断の起点になる。

### memory freshness を回す

`/sb-doctor` が `Last-verified` 超過の警告を出したページを再確認し、更新する:

```
wiki/entities/A社.md を最新情報で更新してください
(A社の最新状況: 〜〜〜)
```

Claude が該当ページを書き換え、`Last-verified` を今日の日付に更新する。

### 週次レビューを自動化する

`wiki/hot-week.md` は週次集約レイヤーとして機能する。毎週末のセッション終了前:

```
update hot cache
```

`wiki/hot-week.md` が今週の活動サマリで更新される。翌週の月曜に開始すると、先週のコンテキストが即座に復元される。

### 長期的な知識資産として育てる

1 ヶ月後の理想状態:

- `wiki/` 配下に 50-200 ページが蓄積
- 主要顧客・案件・概念のページが相互リンクで接続
- 議事録の決定事項が `wiki/decisions/` に ADR として蓄積
- `wiki/hot.md` が業務の「現在地」を正確に反映

この状態になると、新しい案件に着手する際に「過去の類似案件との差分」を Claude に即座に聞ける。新しいスタッフへの引き継ぎも wiki を読ませるだけで完了する。

---

## トラブルシューティング

### `/sb-doctor` で CRITICAL が出た場合

**frontmatter 欠落の場合**

Claude に修正を依頼:

```
wiki/meetings/2026-05-01.md の frontmatter に Status, Last-verified, Half-life を追加してください
```

**append-only 警告が出た場合**

インジェストのたびに新規ページだけ作られ、既存ページが更新されていない状態。次のインジェスト時に明示的に指示:

```
/sb-ingest .raw/[ファイル] --rewrite-existing
```

### プラグインが見つからない場合

```bash
claude plugin list
```

`claude-second-brain-jp` が表示されない場合は再インストール:

```bash
claude plugin marketplace add Kazuya-Hibara/claude-second-brain-jp
claude plugin install claude-second-brain-jp@claude-second-brain-jp-marketplace
```

### コマンドが動作しない場合

Claude Code を再起動する (エージェントレジストリは起動時に読み込まれる)。

---

*詳細仕様: [WIKI.md](WIKI.md) / リリース履歴: [CHANGELOG.md](CHANGELOG.md)*
