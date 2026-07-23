#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
failed=0

check_present() {
  local file="$1"
  local marker="$2"
  if rg -Fq "$marker" "$root/$file"; then
    echo "PASS: $file contains $marker"
  else
    echo "FAIL: $file missing $marker"
    failed=1
  fi
}

check_absent() {
  local file="$1"
  local marker="$2"
  if rg -Fq "$marker" "$root/$file"; then
    echo "FAIL: $file still contains $marker"
    failed=1
  else
    echo "PASS: $file does not contain $marker"
  fi
}

android="androidApp/src/main/java/com/example/demo/health/components/DashboardCard.kt"
ios_model="iosApp/iosApp/Health/HealthCard.swift"
ios_view="iosApp/iosApp/Health/HealthDashboardView.swift"
harmony_types="harmonyApp/entry/src/main/ets/health/HealthDashboardTypes.ets"
harmony_view="harmonyApp/entry/src/main/ets/health/components/DashboardCardComp.ets"
harmony_page="harmonyApp/entry/src/main/ets/pages/SignedInPage.ets"
bridge="harmony-kmp-bridge/src/ohosArm64Main/kotlin/com/example/demo/harmony/bridge/HarmonyLoginService.kt"

check_present "$android" "card.status == HealthCardStatus.Empty"
check_present "$android" "private fun HealthCardVisualContent("
check_absent "$android" "FigmaCardHeight"
check_absent "$android" ".heightIn(min ="
check_absent "$android" "Column(Modifier.fillMaxSize())"
check_present "$android" "Spacer(Modifier.height(16.dp))"

check_present "$ios_model" "let status: String"
check_present "$ios_model" "var isEmpty: Bool"
check_absent "$ios_view" "cardMinimumHeight"
check_absent "$ios_view" "figmaCardHeight"
check_present "$ios_view" "private struct HealthCardVisualContent: View"
check_present "$ios_view" "private var contentMinimumHeight: CGFloat"
check_present "$ios_view" ".padding(.top, 12)"

check_present "$harmony_types" "status: string;"
check_present "$harmony_page" "c.status"
check_absent "$harmony_view" "minimumCardHeight"
check_present "$harmony_view" "private contentMinimumHeight(): number"
check_present "$harmony_view" ".constraintSize({ minHeight: this.contentMinimumHeight() })"
check_present "$harmony_view" "this.VisualContent()"
check_present "$harmony_view" "}.width('100%').margin({ top: 12 })"
check_present "$bridge" 'sb.append(",\"status\":\"")'

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "Health card adaptive layout check passed."
