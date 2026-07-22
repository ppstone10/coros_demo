#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
ios="$root/iosApp/iosApp/Health/Editor/HealthCardEditor.swift"
harmony="$root/harmonyApp/entry/src/main/ets/health/editor/CardEditorComp.ets"
failed=0

check_present() {
  local file="$1"
  local marker="$2"
  if rg -Fq "$marker" "$file"; then
    echo "PASS: $(basename "$file") contains $marker"
  else
    echo "FAIL: $(basename "$file") missing $marker"
    failed=1
  fi
}

check_absent() {
  local file="$1"
  local marker="$2"
  if rg -Fq "$marker" "$file"; then
    echo "FAIL: $(basename "$file") still contains $marker"
    failed=1
  else
    echo "PASS: $(basename "$file") excludes $marker"
  fi
}

check_present "$harmony" 'this.editingHealthCards = createDefaultHealthCards();'
check_absent "$harmony" 'if (this.onRestoreDefaults) this.onRestoreDefaults();'
check_present "$ios" 'title: appLocalized(cardTitleKey(typeID))'
check_present "$ios" '("TodayActivity", AppImages.Health.todayActivity)'
check_absent "$ios" 'title: "", summary: ""'

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "Health card editor regression check passed."
