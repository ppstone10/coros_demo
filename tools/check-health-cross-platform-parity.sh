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

ios="iosApp/iosApp/Health/HealthDashboardView.swift"
ios_strings="iosApp/iosApp/Resources/Localizable.xcstrings"
harmony="harmonyApp/entry/src/main/ets/health/components/DashboardCardComp.ets"
harmony_page="harmonyApp/entry/src/main/ets/pages/SignedInPage.ets"
harmony_metric="harmonyApp/entry/src/main/ets/health/components/MetricComp.ets"
harmony_strings="harmonyApp/entry/src/main/resources/base/element/string.json"

check "$ios" "private var contentMinimumHeight: CGFloat"
check "$ios" "bars(forceColor: nil, highlightedIndex: selectedIndex)"
check "$ios" "LoadOverview(visual: visual)"
check "$ios" "StressOverview(points: points)"
check "$ios" "SleepStageOverview(stages: visual.sleepStages)"
check "$ios" "RecoveryGaugeOverview(progress: progress)"
check "$ios_strings" '"health_visual_recovery_ready"'
check "$ios_strings" '"health_visual_recovery_low"'

check "$harmony" "private contentMinimumHeight(): number"
check "$harmony" "this.Bars(80, 36, this.weeklySelectedIndex())"
check "$harmony" "this.LoadOverview()"
check "$harmony" "this.StressOverview()"
check "$harmony" "this.SleepOverview()"
check "$harmony" "this.RangeMarker()"
check "$harmony" "this.HealthCheckGrid()"
check "$harmony_page" ".width(116).height(116)"
check "$harmony_page" "const center: number = vp2px(58)"
check "$harmony_page" "const radius: number = vp2px(54)"
check "$harmony" "const centerX: number = vp2px(centerXValue)"
check "$harmony" "const centerY: number = vp2px(centerYValue)"
check "$harmony" "const radius: number = vp2px(radiusValue)"
check "$harmony" "const centerX: number = vp2px(60.5)"
check "$harmony" "const centerY: number = vp2px(55)"
check "$harmony" "const needleLength: number = vp2px(37)"
check "$harmony_metric" "@Prop iconColor: ResourceColor"
check "$harmony_metric" ".renderMode(ImageRenderMode.Template)"
check "$harmony_metric" ".fillColor(this.iconColor)"
check "$harmony_strings" '"name": "health_visual_recovery_ready"'
check "$harmony_strings" '"name": "health_visual_recovery_low"'

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "Health cross-platform parity check passed."
