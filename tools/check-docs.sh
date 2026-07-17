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

require_path() {
  if [[ -e "$1" ]]; then
    pass "保留 $1"
  else
    fail "缺少应保留路径 $1"
  fi
}

require_absent() {
  if [[ -e "$1" ]]; then
    fail "仍存在已确认冗余路径 $1"
  else
    pass "已清理 $1"
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

protected_paths=(
  "common"
  "androidApp"
  "iosApp"
  "harmony-kmp-bridge"
  "harmonyApp"
  "docs/worklog"
  "docs/reference"
  "docs/archive"
  "login_register_resources"
  "health_dashboard_resources"
  "contract/analytics"
  "gradle"
  "tools"
)

for path in "${protected_paths[@]}"; do
  require_path "$path"
done

canonical_docs=(
  "README.md"
  "AGENTS.md"
  "LEARNINGS.md"
  "Codex_worklog.md"
  "REQUIREMENT_NOTES.md"
  "DESIGN.md"
  "TEST_REPORT.md"
  "docs/README.md"
  "docs/architecture.md"
  "docs/development-workflow.md"
  "docs/resource-management.md"
  "docs/proto与domain model之间的关系.md"
  "docs/reference/README.md"
  "docs/archive/README.md"
  "docs/archive/harmonyos-kmp/README.md"
)

for path in "${canonical_docs[@]}"; do
  require_path "$path"
done

obsolete_paths=(
  "skill.md"
  "test.md"
  "~"
  "experimental"
  "contract/openapi"
  "tools/generate-contracts.sh"
  "docs/android_app_resource_management_guide.md"
  "docs/ios_harmonyos_app_resource_management_guide.md"
  "docs/harmonyos-plan.md"
  "docs/harmonyos-kmp-experiment.md"
  "docs/kmp-boundary.md"
  "docs/ios-integration.md"
  "docs/注册登陆模块介绍.md"
)

for path in "${obsolete_paths[@]}"; do
  require_absent "$path"
done

restored_documents=(
  "docs/reference/android_app_resource_management_guide.md|fdd266bdecf26e6bf63311c1030388fa9c8178bc22d53815777a5da31e32bad6"
  "docs/reference/ios_harmonyos_app_resource_management_guide.md|048496338f303f1959569cfe4e57e96c543ed53404a093f040621180f4811c14"
  "docs/reference/kmp-boundary.md|fde21ba9737f954d35a4264fed54309ac0972053c4eeff8c6240ace225543b7b"
  "docs/reference/ios-integration.md|99fce2e763b165992685652c7338fe2901bec0fa08e62b6183823313eb0d9448"
  "docs/reference/注册登陆模块介绍.md|56b5213221cd08331a344ffa8cf4a8c5589de94820dc39865216afc8e88d2c7e"
  "docs/archive/harmonyos-kmp/harmonyos-plan.md|12852aca97f239f5f9b8ff4dc5dee8211becf2453fdb7ed6d274aababcd854fd"
  "docs/archive/harmonyos-kmp/harmonyos-kmp-experiment.md|c915524ebdc7e4ca38a88f9a1e639f20bce39f1fb5f9989174aa14d3e8ae1867"
  "docs/archive/harmonyos-kmp/experimental/harmony-kmp/README.md|b8f094a58a996a6b524c20fa783084599e5889dd3d939291c95bfeabd977e4fc"
  "docs/archive/harmonyos-kmp/experimental/harmony-kmp/kuiklybase-knoi/README.md|ebe3128c6020006383f523c9b7a3cfb0719e766b588f4592253b4fc85f182abb"
  "docs/archive/harmonyos-kmp/experimental/harmony-kmp/kuiklybase-knoi/CHECKLIST.md|fbd717162bc7de41d6909eb2fe06b2437c2bd4dba633de8cabc2ed9fc9e79445"
)

for item in "${restored_documents[@]}"; do
  IFS='|' read -r path expected_hash <<< "$item"
  if [[ ! -f "$path" ]]; then
    fail "缺少应完整恢复的文档 $path"
    continue
  fi
  actual_hash="$(shasum -a 256 "$path" | awk '{print $1}')"
  if [[ "$actual_hash" == "$expected_hash" ]]; then
    pass "恢复文档内容完整：$path"
  else
    fail "恢复文档内容与可信来源不一致：$path"
  fi
done

worklog_file="docs/worklog/2026-06-30-to-2026-07-17.md"
worklog_expected_hash="eb13d20f0d1d79b53976eed725671b8827ecabc2748943de269166b49973f530"
if [[ -f "$worklog_file" ]]; then
  worklog_actual_hash="$(shasum -a 256 "$worklog_file" | awk '{print $1}')"
  if [[ "$worklog_actual_hash" == "$worklog_expected_hash" ]]; then
    pass "历史 worklog 内容未变化"
  else
    fail "历史 worklog 内容发生变化：$worklog_file"
  fi
else
  fail "历史 worklog 被删除：$worklog_file"
fi

active_docs=(
  "README.md"
  "AGENTS.md"
  "LEARNINGS.md"
  "DESIGN.md"
  "REQUIREMENT_NOTES.md"
  "TEST_REPORT.md"
  "docs/README.md"
  "docs/architecture.md"
  "docs/development-workflow.md"
  "docs/resource-management.md"
  "docs/proto与domain model之间的关系.md"
  "iosApp/README.md"
  "harmonyApp/README.md"
  "harmony-kmp-bridge/README.md"
  "contract/README.md"
  "tools/README.md"
)

stale_references=(
  "experimental/harmony-kmp"
  "docs/harmonyos-plan.md"
  "docs/harmonyos-kmp-experiment.md"
  "docs/kmp-boundary.md"
  "docs/ios-integration.md"
  "docs/注册登陆模块介绍.md"
  "docs/android_app_resource_management_guide.md"
  "docs/ios_harmonyos_app_resource_management_guide.md"
  "tools/generate-contracts.sh"
)

for pattern in "${stale_references[@]}"; do
  found=false
  for file in "${active_docs[@]}"; do
    if [[ -f "$file" ]] && grep -Fq -- "$pattern" "$file"; then
      fail "$file 仍引用已清理内容：$pattern"
      found=true
    fi
  done
  if [[ "$found" == false ]]; then
    pass "当前文档不再引用：$pattern"
  fi
done

login_count="$(grep -c '@Test' common/src/commonTest/kotlin/com/example/demo/common/login/LoginUseCaseTest.kt)"
rules_count="$(grep -c '@Test' common/src/commonTest/kotlin/com/example/demo/common/login/LoginRulesTest.kt)"
business_count="$(grep -c '@Test' common/src/commonTest/kotlin/com/example/demo/common/login/BusinessMockDataSourceTest.kt)"
health_count="$(grep -c '@Test' common/src/commonTest/kotlin/com/example/demo/common/health/HealthDashboardUseCaseTest.kt)"
common_total=$((login_count + rules_count + business_count + health_count))

require_text "TEST_REPORT.md" "### LoginUseCaseTest（${login_count} 条）"
require_text "TEST_REPORT.md" "### HealthDashboardUseCaseTest（${health_count} 条）"
require_text "TEST_REPORT.md" "共享业务测试合计：**${common_total} 条**"
require_text "spec/TRACE.md" "| \`LoginUseCaseTest.kt\` | ${login_count} |"
require_text "spec/TRACE.md" "| \`HealthDashboardUseCaseTest.kt\` | ${health_count} |"
require_text "spec/TRACE.md" "| **合计** | **${common_total}** |"

require_text "docs/README.md" "docs/worklog/"
require_text "docs/README.md" "只追加"
require_text "docs/README.md" "reference/"
require_text "docs/README.md" "archive/"
require_text "README.md" "docs/README.md"
require_text "AGENTS.md" "./tools/check-docs.sh"
require_text "tools/README.md" "check-docs.sh"
require_text "spec/health-dashboard-cards.md" "[公共培训要求](common-training-requirements.md)"

if ((failures > 0)); then
  printf '\n文档治理校验失败：%d 项。\n' "$failures" >&2
  exit 1
fi

printf '\n文档治理校验通过。\n'
