#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
failed=0

check_file() {
  if [[ -f "$root/$1" ]]; then
    echo "PASS: $1"
  else
    echo "FAIL: missing $1"
    failed=1
  fi
}

check_text() {
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

android_visuals="androidApp/src/main/java/com/example/demo/health/components/visuals"
ios_visuals="iosApp/iosApp/Health/Components/Visuals"
harmony_visuals="harmonyApp/entry/src/main/ets/health/components/visuals"

for file in \
  "$android_visuals/RecoveryVisual.kt" \
  "$android_visuals/AbilityVisual.kt" \
  "$android_visuals/RestingHeartRateVisual.kt" \
  "$android_visuals/HrvAssessmentVisual.kt" \
  "$ios_visuals/RecoveryView.swift" \
  "$ios_visuals/AbilityView.swift" \
  "$ios_visuals/RestingHeartRateView.swift" \
  "$ios_visuals/HrvAssessmentView.swift" \
  "$harmony_visuals/RecoveryVisualComp.ets" \
  "$harmony_visuals/AbilityVisualComp.ets" \
  "$harmony_visuals/RestingHeartRateVisualComp.ets" \
  "$harmony_visuals/HrvAssessmentVisualComp.ets"; do
  check_file "$file"
done

android_dispatch="androidApp/src/main/java/com/example/demo/health/components/DashboardCard.kt"
ios_dispatch="iosApp/iosApp/Health/HealthDashboardView.swift"
harmony_dispatch="harmonyApp/entry/src/main/ets/health/components/DashboardCardComp.ets"

check_text "$android_dispatch" "HealthCardType.Recovery -> RecoveryVisual(visual)"
check_text "$android_dispatch" "HealthCardType.RunningAbility, HealthCardType.CyclingAbility -> AbilityVisual(type, visual)"
check_text "$android_dispatch" "HealthCardType.RestingHeartRate -> RestingHeartRateVisual(visual)"
check_text "$android_dispatch" "HealthCardType.HrvAssessment -> HrvAssessmentVisual(visual)"
check_absent "$android_dispatch" "GaugeVisual(type, visual)"
check_absent "$android_dispatch" "RangeVisual(type, visual)"

check_text "$ios_dispatch" 'case "Recovery": RecoveryView(visual: visual)'
check_text "$ios_dispatch" 'case "RunningAbility", "CyclingAbility": AbilityView(cardType: cardType, visual: visual)'
check_text "$ios_dispatch" 'case "RestingHeartRate": RestingHeartRateView(visual: visual)'
check_text "$ios_dispatch" 'case "HrvAssessment": HrvAssessmentView(visual: visual)'
check_absent "$ios_dispatch" "GaugeView(cardType: cardType, visual: visual)"
check_absent "$ios_dispatch" "RangeView(cardType: cardType, visual: visual)"

check_text "$harmony_dispatch" "this.card.id === 'Recovery'"
check_text "$harmony_dispatch" "AbilityVisualComp({ cardType: this.card.id, visual: this.card.visual })"
check_text "$harmony_dispatch" "this.card.id === 'RestingHeartRate'"
check_text "$harmony_dispatch" "this.card.id === 'HrvAssessment'"
check_absent "$harmony_dispatch" "GaugeVisualComp({"
check_absent "$harmony_dispatch" "RangeIndicatorVisualComp({"

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "Health card style decoupling check passed."
