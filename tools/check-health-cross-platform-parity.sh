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

reject() {
  local file="$1"
  local marker="$2"
  if rg -Fq "$marker" "$root/$file"; then
    echo "FAIL: $file still contains $marker"
    failed=1
  else
    echo "PASS: $file excludes $marker"
  fi
}

ios="iosApp/iosApp/Health/Views/HealthDashboardView.swift"
ios_weekly="iosApp/iosApp/Health/Components/Visuals/WeeklyPlanView.swift"
ios_load="iosApp/iosApp/Health/Components/Visuals/TrainingLoadView.swift"
ios_trend="iosApp/iosApp/Health/Components/Visuals/TrendView.swift"
ios_sleep="iosApp/iosApp/Health/Components/Visuals/SleepView.swift"
ios_recovery="iosApp/iosApp/Health/Components/Visuals/RecoveryView.swift"
ios_strings="iosApp/iosApp/Resources/Localizable.xcstrings"
harmony="harmonyApp/entry/src/main/ets/health/components/DashboardCardComp.ets"
harmony_weekly="harmonyApp/entry/src/main/ets/health/components/visuals/WeeklyPlanVisualComp.ets"
harmony_load="harmonyApp/entry/src/main/ets/health/components/visuals/TrainingLoadVisualComp.ets"
harmony_trend="harmonyApp/entry/src/main/ets/health/components/visuals/TrendVisualComp.ets"
harmony_sleep="harmonyApp/entry/src/main/ets/health/components/visuals/SleepVisualComp.ets"
harmony_hrv="harmonyApp/entry/src/main/ets/health/components/visuals/HrvAssessmentVisualComp.ets"
harmony_helpers="harmonyApp/entry/src/main/ets/health/components/visuals/HealthVisualHelpers.ets"
harmony_page="harmonyApp/entry/src/main/ets/pages/SignedInPage.ets"
harmony_metric="harmonyApp/entry/src/main/ets/health/components/MetricComp.ets"
harmony_strings="harmonyApp/entry/src/main/resources/base/element/string.json"

check "iosApp/iosApp/Health/Views/HealthDashboardCardRow.swift" "private var contentMinimumHeight: CGFloat"
check "$ios_weekly" "MiniBarsView(points: visual.chartPoints, highlightedIndex: selectedDay, width: 80, height: 36, dense: true)"
check "$ios_load" "LoadOverviewView(visual: visual)"
check "$ios_trend" "StressOverviewView(points: visual.chartPoints)"
check "$ios_sleep" "SleepStageOverviewView(stages: visual.sleepStages)"
check "$ios_recovery" "RecoveryGaugeOverviewView(progress: progress)"
check "$ios_strings" '"health_visual_recovery_ready"'
check "$ios_strings" '"health_visual_recovery_low"'

check "$harmony" "private contentMinimumHeight(): number"
check "$harmony_weekly" "barColor(this.visual.kind, point, index, this.weeklySelectedIndex())"
check "$harmony_load" "this.LoadOverview()"
check "$harmony_trend" "this.StressOverview()"
check "$harmony_sleep" "this.SleepOverview()"
check "$harmony_hrv" "this.RangeMarker()"
check "$harmony" "HealthGridVisualComp({ visual: this.card.visual })"
check "$harmony_page" ".width(116).height(116)"
check "$harmony_page" "const center: number = vp2px(58)"
check "$harmony_page" "const radius: number = vp2px(54)"
check "$harmony_helpers" "const centerX: number = vp2px(centerXValue)"
check "$harmony_helpers" "const centerY: number = vp2px(centerYValue)"
check "$harmony_helpers" "const radius: number = vp2px(radiusValue)"
check "$harmony_helpers" "const centerX: number = vp2px(60.5)"
check "$harmony_helpers" "const centerY: number = vp2px(55)"
check "$harmony_helpers" "const needleLength: number = vp2px(37)"
check "$harmony_metric" "@Prop icon: Resource;"
check "$harmony_metric" "Image(this.icon).width(22).height(22).objectFit(ImageFit.Contain)"
reject "$harmony_metric" "renderMode(ImageRenderMode.Template)"
check "$harmony_strings" '"name": "health_visual_recovery_ready"'
check "$harmony_strings" '"name": "health_visual_recovery_low"'

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "Health cross-platform parity check passed."
