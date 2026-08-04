#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
failed=0

check() {
  local file="$1"
  local marker="$2"
  if rg -Fq "$marker" "$root/$file"; then
    echo "PASS: $file contains $marker"
  else
    echo "FAIL: $file missing $marker"
    failed=1
  fi
}

android_hrv="androidApp/src/main/kotlin/com/example/demo/health/components/visuals/HrvAssessmentVisual.kt"
android_resting="androidApp/src/main/kotlin/com/example/demo/health/components/visuals/RestingHeartRateVisual.kt"
ios_hrv="iosApp/iosApp/Health/Components/Visuals/HrvAssessmentView.swift"
ios_resting="iosApp/iosApp/Health/Components/Visuals/RestingHeartRateView.swift"
harmony_hrv="harmonyApp/entry/src/main/ets/health/components/visuals/HrvAssessmentVisualComp.ets"
harmony_resting="harmonyApp/entry/src/main/ets/health/components/visuals/RestingHeartRateVisualComp.ets"
harmony_localization="harmonyApp/entry/src/main/ets/core/resources/HealthLocalization.ets"

check "$android_hrv" "val indicatorTop = 10.dp.toPx()"
check "$android_hrv" "moveTo(x, 2.dp.toPx())"
check "$android_hrv" "lineTo(x - 5.dp.toPx(), 14.dp.toPx())"
check "$android_resting" "val y = 10.dp.toPx()"
check "$android_resting" "moveTo(x, 2.dp.toPx())"
check "$android_resting" "lineTo(x - 5.dp.toPx(), 14.dp.toPx())"

check "$ios_hrv" ".offset(y: 10)"
check "$ios_hrv" "path.move(to: CGPoint(x: markerX, y: 2))"
check "$ios_hrv" "path.addLine(to: CGPoint(x: markerX - 4, y: 14))"
check "$ios_resting" ".offset(y: 10)"
check "$ios_resting" "path.move(to: CGPoint(x: markerX, y: 2))"
check "$ios_resting" "path.addLine(to: CGPoint(x: markerX - 4, y: 14))"

check "$harmony_hrv" ".margin({ left: Math.max(0, Math.min(122, 130 * rangeFraction(this.visual.range) - 4)), top: 7 })"
check "$harmony_hrv" ".width(130).height(4).borderRadius(2).clip(true).margin({ top: 10 })"
check "$harmony_hrv" ".width(130).height(18)"
check "$harmony_resting" ".margin({ left: Math.max(0, Math.min(122, 130 * rangeFraction(this.visual.range) - 4)), top: 7 })"
check "$harmony_resting" ".margin({ top: 10 })"
check "$harmony_resting" ".width(130).height(18)"

check "$harmony_localization" "case 'health_visual_normal_range_short': return \$r('app.string.health_visual_normal_range_short');"

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "Health range indicator parity check passed."
