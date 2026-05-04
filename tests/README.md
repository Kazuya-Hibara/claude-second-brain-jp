# tests/ — fixture runner (autopilot v0.1.0)

このディレクトリは autopilot Phase 2 で実行する **fixture-based acceptance test** の skeleton。Wave 0 で Lead が直接配置、Wave 1 以降の subagent は **fixture を追加するのみ**で `run-fixtures.sh` 自体は変更しない。

## 構成

```
tests/
├── README.md            ← この file
├── run-fixtures.sh      ← runner (Lead 管理、subagent は変更禁止)
└── fixtures/
    ├── sb-doctor/             ← 3.1 fixture
    ├── sb-reconcile/          ← 3.2 fixture
    ├── sb-synthesize/         ← 3.3 + 2.3 fixture
    ├── sb-ingest/             ← 2.2 fixture
    └── sb-graduate-meeting/   ← 2.7 fixture
```

## Runner 仕様

```bash
bash tests/run-fixtures.sh {wave1|wave2|all|--self-test}
```

| サブコマンド | 対象 | exit code |
| --- | --- | --- |
| `wave1` | 3.1 / 3.2 / 3.3 / 2.2 / 2.7 fixtures | FAIL>0 で 1、それ以外 0 (SKIP 許容) |
| `wave2` | 2.3 JP synthesis 3 sub-modes | 同上 |
| `all` | wave1 + wave2 | 同上 |
| `--self-test` | fixture dir 存在確認のみ (Wave 0 PASS criterion) | FAIL>0 で 1、それ以外 0 |

## Subagent 向け rule (rev2 fix #4 対応)

1. **`run-fixtures.sh` は subagent 変更禁止** — Lead が Wave 0 で確定、Phase 2 task 着手 subagent は fixture 追加のみ
2. **新規 fixture 追加時の手順**:
   - 該当 task の subdirectory (例: `tests/fixtures/sb-doctor/`) に `<acceptance-name>.md` を配置
   - fixture 自体に YAML frontmatter (Status: ACTIVE / Last-verified / Half-life) を含めること
   - `run-fixtures.sh` の対応 wave 関数に `check_fixture` 行を 1 行追加 (改変必要時のみ Lead に PR)
3. **fixture 内容**: 実際の wiki page を模した markdown、acceptance criteria を満たす最小例
4. **acceptance criteria 拡張**: 単なる `test -f` チェックは Wave 0 placeholder。Phase 2 着手時に実 lint check (`/sb-doctor` 出力 grep 等) に subagent が拡張する

## Wave 0 verification

```bash
bash tests/run-fixtures.sh --self-test
# 期待: PASS=5 (5 fixture dir 存在) / FAIL=0 / SKIP=0、exit 0
```

## phase 着手後の verification flow (Lite)

各 wave 完了時:

```bash
bash tests/run-fixtures.sh wave1     # Wave 1 完了時
bash tests/run-fixtures.sh wave2     # Wave 2 完了時
bash scripts/check-docs.sh           # Wave 3 完了時
```

## phase 着手後の verification flow (Full、Wave 4 review 直前 1 回のみ)

```bash
/sb-doctor                           # 0 CRITICAL
/sb-ingest --rewrite-existing        # Phase 4.1 4 並列 fold rewrite
/sb-doctor --check append-only       # Phase 4.2 0 WARN
bash tests/run-fixtures.sh all       # 全 fixture
```
