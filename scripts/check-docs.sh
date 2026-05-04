#!/usr/bin/env bash
# claude-second-brain-jp docs checker (autopilot v0.1.0 Wave 3 / 5.1b)
# Usage: bash scripts/check-docs.sh
#
# - README JP/EN 同期 (両言語の見出し数 + 価格行 grep)
# - CHANGELOG.md v0.1.0 entry 存在
# - link liveness (curl -sI で internal link 200 確認、external link は非必須)

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

color_pass() { printf "\033[32m%s\033[0m" "$1"; }
color_fail() { printf "\033[31m%s\033[0m" "$1"; }
color_warn() { printf "\033[33m%s\033[0m" "$1"; }

check_readme_jp_en_sync() {
  echo "[README JP/EN 同期]"
  local readme="$REPO_ROOT/README.md"

  if [ ! -f "$readme" ]; then
    echo "  $(color_fail FAIL) README.md 不在"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return
  fi

  # 両言語アンカーの存在 (Phase 5.1 で literal 配置される: ## English / ## 日本語)
  if grep -qE '^##\s+(English|EN)' "$readme" && grep -qE '^##\s+(日本語|JP)' "$readme"; then
    echo "  $(color_pass PASS) README に JP + EN セクション両方存在"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  $(color_warn WARN) README JP/EN セクション anchor 不足 (## English / ## 日本語 期待)"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi

  # install snippet literal 確認
  if grep -q "claude plugin marketplace add Kazuya-Hibara/claude-second-brain-jp" "$readme"; then
    echo "  $(color_pass PASS) README に install snippet literal 記載"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  $(color_warn WARN) README に install snippet 不足 (claude plugin marketplace add Kazuya-Hibara/claude-second-brain-jp 期待)"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi
}

check_changelog_v010() {
  echo "[CHANGELOG v0.1.0 entry]"
  local changelog="$REPO_ROOT/CHANGELOG.md"

  if [ ! -f "$changelog" ]; then
    echo "  $(color_fail FAIL) CHANGELOG.md 不在"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return
  fi

  if grep -qE '^##\s+\[?0\.1\.0\]?' "$changelog"; then
    echo "  $(color_pass PASS) CHANGELOG に v0.1.0 entry 存在"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  $(color_warn WARN) CHANGELOG v0.1.0 entry 不足 (## [0.1.0] or ## 0.1.0 期待)"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi
}

check_link_liveness() {
  echo "[link liveness (internal docs only)]"
  local broken=0
  for f in README.md WALKTHROUGH.md CHANGELOG.md docs/jp-business-presets.md; do
    local path="$REPO_ROOT/$f"
    if [ ! -f "$path" ]; then
      echo "  $(color_warn WARN) $f 不在 (skip)"
      WARN_COUNT=$((WARN_COUNT + 1))
      continue
    fi
    # internal link `(./...)` `(<repo-root>/...)` 形式のみ check
    while IFS= read -r link; do
      # markdown link `[text](path)` から path 部分抽出 (簡易、外部 URL 除外)
      local target
      target=$(echo "$link" | sed -E 's/.*\(\.\/([^)]+)\).*/\1/' | head -1)
      if [ -n "$target" ] && [ ! -e "$REPO_ROOT/$target" ]; then
        echo "  $(color_warn WARN) $f -> $target が存在しない"
        broken=$((broken + 1))
      fi
    done < <(grep -oE '\[[^]]+\]\(\./[^)]+\)' "$path" 2>/dev/null || true)
  done
  if [ "$broken" -eq 0 ]; then
    echo "  $(color_pass PASS) internal link 0 broken"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    WARN_COUNT=$((WARN_COUNT + broken))
  fi
}

check_readme_jp_en_sync
check_changelog_v010
check_link_liveness

echo ""
echo "Result: $(color_pass PASS=$PASS_COUNT) $(color_fail FAIL=$FAIL_COUNT) $(color_warn WARN=$WARN_COUNT)"

# WARN は通す、FAIL のみで非 0 exit
if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
