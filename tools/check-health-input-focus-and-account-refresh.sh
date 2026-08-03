#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

failures=0

require_text() {
  local file="$1"
  local text="$2"
  if rg -Fq "$text" "$file"; then
    echo "PASS: $file contains $text"
  else
    echo "FAIL: $file missing $text"
    failures=$((failures + 1))
  fi
}

forbid_text() {
  local file="$1"
  local text="$2"
  if rg -Fq "$text" "$file"; then
    echo "FAIL: $file still contains $text"
    failures=$((failures + 1))
  else
    echo "PASS: $file excludes $text"
  fi
}

HARMONY_EDITOR="harmonyApp/entry/src/main/ets/pages/NormalDataSectionPage.ets"
IOS_VIEW_MODEL="iosApp/iosApp/Health/HealthDashboardViewModel.swift"
IOS_VIEW="iosApp/iosApp/Health/HealthDashboardView.swift"

forbid_text "$HARMONY_EDITOR" '${field.id}_${field.value}'
require_text "$HARMONY_EDITOR" '(field: NormalEditField) => field.id)'

require_text "$IOS_VIEW_MODEL" '@Published private(set) var accountRefreshPending = false'
require_text "$IOS_VIEW_MODEL" '@Published private(set) var accountRefreshPhase: AccountRefreshPhase = .idle'
require_text "$IOS_VIEW_MODEL" 'func staleForNewAccount(shouldRefreshOnDashboard: Bool)'
require_text "$IOS_VIEW_MODEL" 'func startPendingAccountRefresh()'
require_text "$IOS_VIEW_MODEL" 'accountRefreshTask = Task'
forbid_text "$IOS_VIEW_MODEL" 'var needsProgrammaticRefresh = false'
forbid_text "$IOS_VIEW_MODEL" 'claimProgrammaticRefreshRequest'
forbid_text "$IOS_VIEW" 'consumedProgrammaticRefreshRequestID'
require_text "$IOS_VIEW" '.onChange(of: viewModel.accountRefreshPending)'
require_text "$IOS_VIEW" '.onChange(of: viewModel.isLoading)'
require_text "$IOS_VIEW" 'viewModel.startPendingAccountRefresh()'
require_text "$IOS_VIEW" 'effectiveRefreshPhase'
require_text "$IOS_VIEW" 'effectiveDragOffset'
require_text "iosApp/iosApp/Login/AuthCoordinator.swift" 'staleForNewAccount(shouldRefreshOnDashboard: true)'
require_text "iosApp/iosApp/Login/AuthCoordinator.swift" 'staleForNewAccount(shouldRefreshOnDashboard: false)'

if (( failures > 0 )); then
  echo
  echo "Health input focus/account refresh gate failed: $failures issue(s)."
  exit 1
fi

echo
echo "Health input focus/account refresh gate passed."
