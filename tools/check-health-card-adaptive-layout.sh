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

check_present "$android" "FigmaCardHeight.minimumFor(card)"
check_present "$android" ".heightIn(min = FigmaCardHeight.minimumFor(card))"
check_present "$android" "card.status == HealthCardStatus.Empty"
check_absent "$android" ".height(FigmaCardHeight.forKind(card.visual.kind))"

check_present "$ios_model" "let status: String"
check_present "$ios_model" "var isEmpty: Bool"
check_present "$ios_view" "minHeight: cardMinimumHeight(card)"
check_absent "$ios_view" "maxHeight: figmaCardHeight(card.visual)"

check_present "$harmony_types" "status: string;"
check_present "$harmony_page" "c.status"
check_present "$harmony_view" ".constraintSize({ minHeight: this.minimumCardHeight() })"
check_absent "$harmony_view" ".height(this.figmaCardHeight())"
check_present "$bridge" 'sb.append(",\"status\":\"")'

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "Health card adaptive layout check passed."
