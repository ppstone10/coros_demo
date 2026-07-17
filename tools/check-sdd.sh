#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

require_file() {
  if [[ -f "$1" ]]; then
    pass "存在 $1"
  else
    fail "缺少 $1"
  fi
}

require_text() {
  local file="$1"
  local text="$2"
  if [[ -f "$file" ]] && grep -Fq -- "$text" "$file"; then
    pass "$file 包含：$text"
  else
    fail "$file 缺少：$text"
  fi
}

core_files=(
  "AGENTS.md"
  "LEARNINGS.md"
  "Codex_worklog.md"
  "spec/README.md"
  "spec/TEMPLATE.md"
  "spec/SESSION_START.md"
  "spec/TRACE.md"
  "spec/sdd-workflow.md"
)

for file in "${core_files[@]}"; do
  require_file "$file"
done

for id in SDD-001 SDD-002 SDD-003 SDD-004 SDD-005 SDD-006 SDD-007 SDD-008 SDD-009; do
  require_text "spec/sdd-workflow.md" "$id"
  require_text "spec/TRACE.md" "$id"
done

for marker in \
  "读取 LEARNINGS.md 和 spec/TRACE.md" \
  "先写或更新 Spec" \
  "在 TRACE 中预留映射" \
  "先写测试并确认测试能捕获缺失行为" \
  "编写最小实现让测试通过" \
  "更新 TRACE、Worklog 和 Learnings"; do
  require_text "AGENTS.md" "$marker"
done

for heading in \
  "## 元数据" \
  "## 目标" \
  "## 非目标" \
  "## 边界与约束" \
  "## 数据与状态" \
  "## 行为规范" \
  "## 测试要求" \
  "## 验收标准"; do
  require_text "spec/TEMPLATE.md" "$heading"
done

for heading in "## 采纳内容" "## 人工审查点" "## 验证结果" "## 人工修正点"; do
  require_text "Codex_worklog.md" "$heading"
done

if grep -Eq '^# [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2} — .+' "Codex_worklog.md"; then
  pass "Codex_worklog.md 包含真实写入时间和内容概要"
else
  fail "Codex_worklog.md 缺少格式为 # YYYY-MM-DD HH:mm — 内容概要 的记录"
fi

if awk '
  $0 ~ /^# [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9] — .+/ ||
  $0 ~ /^# [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]（时间未记录）— .+/ {
    if (seen && state != 4) exit 1
    seen = 1
    state = 0
    next
  }
  !seen { next }
  /^## 采纳内容$/ {
    if (state != 0) exit 1
    state = 1
    next
  }
  /^## 人工审查点$/ {
    if (state != 1) exit 1
    state = 2
    next
  }
  /^## 验证结果$/ {
    if (state != 2) exit 1
    state = 3
    next
  }
  /^## 人工修正点$/ {
    if (state != 3) exit 1
    state = 4
    next
  }
  END {
    if (!seen || state != 4) exit 1
  }
' "Codex_worklog.md"; then
  pass "Codex_worklog.md 每轮均按时间概要 + 固定四段排列"
else
  fail "Codex_worklog.md 存在缺少时间概要或四段顺序不完整的记录"
fi

require_text "LEARNINGS.md" "## SDD 治理约定"
require_text "README.md" "spec/"
require_text "README.md" "LEARNINGS.md"
require_text "README.md" "Codex_worklog.md"
require_text "docs/development-workflow.md" "./tools/check-sdd.sh"
require_text "tools/README.md" "check-sdd.sh"

active_governance_files=(
  "AGENTS.md"
  "LEARNINGS.md"
  "README.md"
  "docs/development-workflow.md"
  "spec/README.md"
  "spec/TEMPLATE.md"
  "spec/SESSION_START.md"
  "spec/TRACE.md"
  "spec/sdd-workflow.md"
  "spec/common-training-requirements.md"
)

for file in "${active_governance_files[@]}"; do
  if [[ -f "$file" ]] && grep -Fq -- 'CODEX_WORKLOG.md' "$file"; then
    fail "$file 仍引用错误大小写 CODEX_WORKLOG.md"
  fi
done

if ((failures > 0)); then
  printf '\nSDD 框架校验失败：%d 项。\n' "$failures" >&2
  exit 1
fi

printf '\nSDD 框架校验通过。\n'
