#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
ios="$root/iosApp/iosApp/Health/Editor/HealthCardEditor.swift"
harmony="$root/harmonyApp/entry/src/main/ets/health/editor/CardEditorComp.ets"
harmony_page="$root/harmonyApp/entry/src/main/ets/pages/HealthCardEditorPage.ets"
harmony_view_model="$root/harmonyApp/entry/src/main/ets/health/HealthDashboardViewModel.ets"
harmony_bridge="$root/harmony-kmp-bridge/src/ohosArm64Main/kotlin/com/example/demo/harmony/bridge/HarmonyLoginService.kt"
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
check_present "$harmony_page" 'if (!this.healthVM.saveCardConfiguration(types, this))'
check_present "$harmony" "Button(\$r('app.string.common_save'), { type: ButtonType.Normal })"
check_present "$harmony_view_model" "getService().saveCardConfig(types.join(','))"
check_absent "$harmony_view_model" 'getService().saveCardConfig(JSON.stringify(types))'
check_present "$harmony_bridge" 'fun saveCardConfig(typeNamesCsv: String): String'

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "Health card editor regression check passed."
