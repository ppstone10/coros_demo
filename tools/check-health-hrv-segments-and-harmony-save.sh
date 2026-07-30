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

models="common/src/commonMain/kotlin/com/example/demo/common/health/HealthDashboardModels.kt"
visuals="common/src/commonMain/kotlin/com/example/demo/common/health/HealthDashboardVisuals.kt"
android="androidApp/src/main/java/com/example/demo/health/components/visuals/HrvAssessmentVisual.kt"
ios="iosApp/iosApp/Health/Components/Visuals/HrvAssessmentView.swift"
harmony="harmonyApp/entry/src/main/ets/health/components/visuals/HrvAssessmentVisualComp.ets"
harmony_types="harmonyApp/entry/src/main/ets/health/HealthDashboardTypes.ets"
bridge="harmony-kmp-bridge/src/ohosArm64Main/kotlin/com/example/demo/harmony/bridge/HarmonyLoginService.kt"
provider="harmonyApp/entry/src/main/ets/knoi/provider.ets"
editor="harmonyApp/entry/src/main/ets/pages/NormalDataSectionPage.ets"

check "$models" "enum class HealthRangeLevel { VeryLow, Low, Normal, High }"
check "$models" "val segments: List<HealthRangeSegment> = emptyList()"
check "$visuals" "HealthRangeSegment(40.0, 42.0, HealthRangeLevel.VeryLow)"
check "$visuals" "HealthRangeSegment(42.0, resolvedNormalMin, HealthRangeLevel.Low)"
check "$visuals" "HealthRangeSegment(resolvedNormalMin, resolvedNormalMax, HealthRangeLevel.Normal)"
check "$visuals" "HealthRangeSegment(resolvedNormalMax, 65.0, HealthRangeLevel.High)"

check "$android" "currentRange.segments.forEach"
check "$ios" "ForEach(Array(segments.enumerated()), id: \\.offset)"
check "$harmony" "ForEach(this.rangeSegments()"
check "$harmony_types" "segments?: HealthRangeSegmentData[]"
check "$bridge" "sb.append(\",\\\"segments\\\":[\")"

reject "$android" "val segmentWidth = (size.width - gap * 3) / 4f"
reject "$ios" "geometry.size.width * 0.18"
reject "$harmony" "Row().width(23)"

check "$bridge" "fun saveNormalHealthEditForm(sectionName: String, valuesSpec: String): Boolean ="
check "$provider" "saveNormalHealthEditForm(sectionName: string, valuesSpec: string): boolean;"
check "$editor" "Button(\$r('app.string.common_save'), { type: ButtonType.Normal })"
check "$editor" "if (!getService().saveNormalHealthEditForm(this.section, this.valuesSpec()))"
reject "$editor" "saveNormalHealthEditForm(this.section, this.valuesSpec()) !== 'true'"

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "Health HRV segments and Harmony save check passed."
