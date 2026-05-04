#!/usr/bin/env bash
# claude-second-brain-jp test fixture runner (autopilot v0.1.0 Wave 0)
# Usage: bash tests/run-fixtures.sh {wave1|wave2|all|--self-test}
#
# - wave1: 5 task fixtures (sb-doctor / sb-reconcile / sb-synthesize-shell / sb-ingest / sb-graduate-meeting)
# - wave2: 2.3 JP synthesis 3 sub-mode fixtures
# - all: wave1 + wave2
# - --self-test: skeleton sanity (空 fixture でも 0 exit、Wave 0 PASS criterion)

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURES_DIR="${REPO_ROOT}/tests/fixtures"
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

color_pass() { printf "\033[32m%s\033[0m" "$1"; }
color_fail() { printf "\033[31m%s\033[0m" "$1"; }
color_skip() { printf "\033[33m%s\033[0m" "$1"; }

check_fixture() {
  local name="$1"
  local fixture_path="$2"
  local check_cmd="$3"

  if [ ! -e "$fixture_path" ]; then
    SKIP_COUNT=$((SKIP_COUNT + 1))
    echo "  $(color_skip SKIP) $name (fixture not found: $fixture_path)"
    return 0
  fi

  if eval "$check_cmd" >/dev/null 2>&1; then
    PASS_COUNT=$((PASS_COUNT + 1))
    echo "  $(color_pass PASS) $name"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo "  $(color_fail FAIL) $name (check: $check_cmd)"
  fi
}

# 簡易 acceptance: fixture が存在し、frontmatter が読めることを確認する placeholder
# 実際の acceptance は phase 着手後の subagent が fixture と一緒に拡張する
run_wave1() {
  echo "[Wave 1 fixtures]"

  # 3.1 sb-doctor
  echo " 3.1 sb-doctor"
  check_fixture "broken-frontmatter" "$FIXTURES_DIR/sb-doctor/broken-frontmatter.md" \
    "test -f '$FIXTURES_DIR/sb-doctor/broken-frontmatter.md'"
  check_fixture "expired-halflife" "$FIXTURES_DIR/sb-doctor/expired-halflife.md" \
    "test -f '$FIXTURES_DIR/sb-doctor/expired-halflife.md'"
  check_fixture "long-line-index" "$FIXTURES_DIR/sb-doctor/long-line-index.md" \
    "test -f '$FIXTURES_DIR/sb-doctor/long-line-index.md'"
  check_fixture "append-only-page" "$FIXTURES_DIR/sb-doctor/append-only-page.md" \
    "test -f '$FIXTURES_DIR/sb-doctor/append-only-page.md'"

  # 3.2 sb-reconcile
  echo " 3.2 sb-reconcile"
  check_fixture "conflict-evidence-clear-1" "$FIXTURES_DIR/sb-reconcile/conflict-evidence-clear-1.md" \
    "test -f '$FIXTURES_DIR/sb-reconcile/conflict-evidence-clear-1.md'"
  check_fixture "conflict-evidence-clear-2" "$FIXTURES_DIR/sb-reconcile/conflict-evidence-clear-2.md" \
    "test -f '$FIXTURES_DIR/sb-reconcile/conflict-evidence-clear-2.md'"
  check_fixture "conflict-ambiguous-1" "$FIXTURES_DIR/sb-reconcile/conflict-ambiguous-1.md" \
    "test -f '$FIXTURES_DIR/sb-reconcile/conflict-ambiguous-1.md'"
  check_fixture "conflict-ambiguous-2" "$FIXTURES_DIR/sb-reconcile/conflict-ambiguous-2.md" \
    "test -f '$FIXTURES_DIR/sb-reconcile/conflict-ambiguous-2.md'"

  # 3.3 sb-synthesize (shell)
  echo " 3.3 sb-synthesize-shell"
  check_fixture "cross-source-dir" "$FIXTURES_DIR/sb-synthesize/cross-source" \
    "test -d '$FIXTURES_DIR/sb-synthesize/cross-source'"
  check_fixture "orphan-rescue-dir" "$FIXTURES_DIR/sb-synthesize/orphan-rescue" \
    "test -d '$FIXTURES_DIR/sb-synthesize/orphan-rescue'"

  # 2.2 sb-ingest
  echo " 2.2 sb-ingest"
  check_fixture "jp-only" "$FIXTURES_DIR/sb-ingest/jp-only.md" \
    "test -f '$FIXTURES_DIR/sb-ingest/jp-only.md'"
  check_fixture "en-only" "$FIXTURES_DIR/sb-ingest/en-only.md" \
    "test -f '$FIXTURES_DIR/sb-ingest/en-only.md'"
  check_fixture "mixed" "$FIXTURES_DIR/sb-ingest/mixed.md" \
    "test -f '$FIXTURES_DIR/sb-ingest/mixed.md'"

  # 2.7 sb-graduate-meeting
  echo " 2.7 sb-graduate-meeting"
  check_fixture "with-decisions" "$FIXTURES_DIR/sb-graduate-meeting/with-decisions.md" \
    "test -f '$FIXTURES_DIR/sb-graduate-meeting/with-decisions.md'"
  check_fixture "with-multiple-decisions" "$FIXTURES_DIR/sb-graduate-meeting/with-multiple-decisions.md" \
    "test -f '$FIXTURES_DIR/sb-graduate-meeting/with-multiple-decisions.md'"
  check_fixture "no-decisions" "$FIXTURES_DIR/sb-graduate-meeting/no-decisions.md" \
    "test -f '$FIXTURES_DIR/sb-graduate-meeting/no-decisions.md'"
}

run_wave2() {
  echo "[Wave 2 fixtures]"
  echo " 2.3 JP synthesis sub-modes"
  check_fixture "jp-meeting-minutes" "$FIXTURES_DIR/sb-synthesize/jp-meeting-minutes.md" \
    "test -f '$FIXTURES_DIR/sb-synthesize/jp-meeting-minutes.md'"
  check_fixture "jp-proposal-vs-past" "$FIXTURES_DIR/sb-synthesize/jp-proposal-vs-past.md" \
    "test -f '$FIXTURES_DIR/sb-synthesize/jp-proposal-vs-past.md'"
  check_fixture "jp-slack-thread" "$FIXTURES_DIR/sb-synthesize/jp-slack-thread.md" \
    "test -f '$FIXTURES_DIR/sb-synthesize/jp-slack-thread.md'"
}

run_self_test() {
  # Wave 0 PASS criterion: runner 自体が起動・終了する (fixture 不在は SKIP として 0 exit)
  echo "[--self-test] runner skeleton sanity check"
  # fixture dirs 存在確認のみ
  for dir in sb-doctor sb-reconcile sb-synthesize sb-ingest sb-graduate-meeting; do
    if [ -d "$FIXTURES_DIR/$dir" ]; then
      echo "  $(color_pass PASS) $FIXTURES_DIR/$dir exists"
      PASS_COUNT=$((PASS_COUNT + 1))
    else
      echo "  $(color_fail FAIL) $FIXTURES_DIR/$dir missing"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  done
}

case "${1:-}" in
  wave1) run_wave1 ;;
  wave2) run_wave2 ;;
  all) run_wave1; run_wave2 ;;
  --self-test) run_self_test ;;
  ""|-h|--help)
    cat <<USAGE
Usage: $0 {wave1|wave2|all|--self-test}

  wave1       Wave 1 fixtures (sb-doctor / sb-reconcile / sb-synthesize-shell / sb-ingest / sb-graduate-meeting)
  wave2       Wave 2 fixtures (JP synthesis 3 sub-modes)
  all         Wave 1 + Wave 2
  --self-test Wave 0 PASS criterion (skeleton sanity)

Fixture path: $FIXTURES_DIR
USAGE
    exit 0
    ;;
  *)
    echo "Unknown command: $1" >&2
    exit 2
    ;;
esac

echo ""
echo "Result: $(color_pass PASS=$PASS_COUNT) $(color_fail FAIL=$FAIL_COUNT) $(color_skip SKIP=$SKIP_COUNT)"

# self-test は FAIL=0 で exit 0、wave1/wave2/all は SKIP も許容 (fixture は phase 着手で追加)
if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
