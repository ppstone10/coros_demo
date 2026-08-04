#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

failures=0

require_text() {
  local file="$1"
  local text="$2"
  if [[ -f "$file" ]] && grep -Fq -- "$text" "$file"; then
    printf 'PASS: %s 包含 %s\n' "$file" "$text"
  else
    printf 'FAIL: %s 缺少 %s\n' "$file" "$text" >&2
    failures=$((failures + 1))
  fi
}

require_absent() {
  local file="$1"
  local text="$2"
  if [[ -f "$file" ]] && ! grep -Fq -- "$text" "$file"; then
    printf 'PASS: %s 不包含 %s\n' "$file" "$text"
  else
    printf 'FAIL: %s 仍包含 %s\n' "$file" "$text" >&2
    failures=$((failures + 1))
  fi
}

require_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    printf 'PASS: 存在 %s\n' "$file"
  else
    printf 'FAIL: 缺少 %s\n' "$file" >&2
    failures=$((failures + 1))
  fi
}

require_same_file() {
  local expected="$1"
  local actual="$2"
  if [[ -f "$expected" && -f "$actual" ]] && cmp -s "$expected" "$actual"; then
    printf 'PASS: %s 与 %s 内容一致\n' "$actual" "$expected"
  else
    printf 'FAIL: %s 与 %s 不一致或缺失\n' "$actual" "$expected" >&2
    failures=$((failures + 1))
  fi
}

require_text "common/src/commonMain/kotlin/com/example/demo/common/health/EditableHealthData.kt" \
  "fun derive(source: EditableHealthData)"
require_text "common/src/commonMain/kotlin/com/example/demo/common/health/HealthEditableForms.kt" \
  "fun apply("
require_text "common/src/commonMain/kotlin/com/example/demo/common/health/HealthEditableForms.kt" \
  "fun mutate("
require_text "common/src/commonMain/kotlin/com/example/demo/common/health/HealthEditableForms.kt" \
  "enum class BodyMuscleGroup"
require_text "common/src/commonMain/kotlin/com/example/demo/common/health/HealthDashboardStore.kt" \
  "transientDashboardDraft"
require_text "common/src/commonMain/kotlin/com/example/demo/common/health/HealthDashboardStore.kt" \
  "stored.editableData"
require_text "common/src/commonMain/kotlin/com/example/demo/common/health/HealthEditableForms.kt" \
  "bodyManagement = source.bodyManagement.copy("
require_absent "common/src/commonMain/kotlin/com/example/demo/common/health/HealthDashboardStore.kt" \
  "baseSource.copy(bodyManagement = requireNotNull(previousBody))"
require_text "common/src/commonTest/kotlin/com/example/demo/common/health/EditableHealthDataTest.kt" \
  "bodyMuscleDraftReplacesOldMusclesOnRefreshWhileWeightHistoryIsPreserved"
require_text "common/src/commonMain/kotlin/com/example/demo/common/health/HealthDashboardModels.kt" \
  "val highlightedBodyRegions: List<String> = emptyList()"
require_text "common/src/commonMain/kotlin/com/example/demo/common/health/HealthDashboardModels.kt" \
  "val footer: LocalizedTextSpec? = null"
require_text "common/src/commonMain/kotlin/com/example/demo/common/health/HealthDashboardVisuals.kt" \
  "highlightedBodyRegions = bodyHighlightRegions"

require_text "androidApp/src/main/kotlin/com/example/demo/auth/navigation/AuthRoute.kt" \
  "NormalDataEditorRoute"
require_text "androidApp/src/main/kotlin/com/example/demo/health/editor/NormalDataEditor.kt" \
  "delay(1_500.milliseconds)"
require_text "androidApp/src/main/kotlin/com/example/demo/health/editor/NormalDataEditor.kt" \
  "viewModel.normalEditForm(section)"
require_text "androidApp/src/main/kotlin/com/example/demo/health/editor/NormalDataEditor.kt" \
  "OutlinedTextFieldDefaults.colors"
require_text "androidApp/src/main/kotlin/com/example/demo/health/editor/NormalDataEditor.kt" \
  "RepeatGroupEditor"
require_text "androidApp/src/main/kotlin/com/example/demo/health/editor/NormalDataEditor.kt" \
  "ChoiceSelectionDialog"
require_text "androidApp/src/main/kotlin/com/example/demo/health/editor/NormalDataEditor.kt" \
  "stringResource(R.string.common_save)"
require_absent "androidApp/src/main/kotlin/com/example/demo/health/editor/NormalDataEditor.kt" \
  "% field.options.size"
require_text "androidApp/src/main/kotlin/com/example/demo/core/resources/AppImages.kt" \
  "ChoiceChevron = AppImageAsset(R.drawable.right_more)"
require_text "androidApp/src/main/kotlin/com/example/demo/core/resources/AppImages.kt" \
  "ChoiceCheck = AppImageAsset(R.drawable.ic_profile_check)"
require_text "androidApp/src/main/kotlin/com/example/demo/health/editor/NormalDataEditor.kt" \
  "AppImages.Health.ChoiceChevron"
require_text "androidApp/src/main/kotlin/com/example/demo/health/editor/NormalDataEditor.kt" \
  "AppImages.Health.ChoiceCheck"
require_absent "androidApp/src/main/kotlin/com/example/demo/health/editor/NormalDataEditor.kt" \
  "Text(\"⌄\""
require_absent "androidApp/src/main/kotlin/com/example/demo/health/editor/NormalDataEditor.kt" \
  "Text(\"✓\""

require_text "iosApp/iosApp/Auth/AuthCoordinator.swift" \
  "NormalDataEditorOverview"
require_text "iosApp/iosApp/Health/Editor/NormalDataEditor.swift" \
  "1_500_000_000"
require_text "iosApp/iosApp/Health/Editor/NormalDataEditor.swift" \
  "viewModel.normalEditFormJson(section)"
require_text "iosApp/iosApp/Health/Editor/NormalDataEditor.swift" \
  "repeatGroupEditor"
require_text "iosApp/iosApp/Health/Editor/NormalDataEditor.swift" \
  "choiceSelectionOverlay"
require_text "iosApp/iosApp/Health/Editor/NormalDataEditor.swift" \
  "AppColors.Health.addAction"
require_absent "iosApp/iosApp/Health/Editor/NormalDataEditor.swift" \
  "Picker("
require_text "iosApp/iosApp/Core/Resources/AppResources.swift" \
  "static let choiceChevron = \"right_more\""
require_text "iosApp/iosApp/Core/Resources/AppResources.swift" \
  "static let choiceCheck = \"ic_profile_check\""
require_text "iosApp/iosApp/Health/Editor/NormalDataEditor.swift" \
  "Image(AppImages.Health.choiceChevron)"
require_text "iosApp/iosApp/Health/Editor/NormalDataEditor.swift" \
  "Image(AppImages.Health.choiceCheck)"
require_absent "iosApp/iosApp/Health/Editor/NormalDataEditor.swift" \
  "systemName: \"chevron.down\""
require_absent "iosApp/iosApp/Health/Editor/NormalDataEditor.swift" \
  "systemName: \"checkmark\""
require_text "iosApp/iosApp/Health/Components/Visuals/BodyView.swift" \
  "bodyRegionLayer"
require_text "iosApp/iosApp/Core/Resources/AppResources.swift" \
  "static let bodyMuscleRegions:"
require_absent "iosApp/iosApp/Health/Components/Visuals/BodyView.swift" \
  "muscleMarker"
require_absent "iosApp/iosApp/Health/Components/Visuals/BodyView.swift" \
  "muscleNames"

require_text "harmonyApp/entry/src/main/ets/auth/AuthRoutes.ets" \
  "NORMAL_DATA_EDITOR"
require_text "harmonyApp/entry/src/main/ets/pages/NormalDataEditorPage.ets" \
  "normalHealthEditFormJson(section)"
require_text "harmonyApp/entry/src/main/ets/pages/NormalDataSectionPage.ets" \
  "duration: 1500"
require_text "harmonyApp/entry/src/main/ets/pages/NormalDataSectionPage.ets" \
  "RepeatGroupEditor"
require_text "harmonyApp/entry/src/main/ets/pages/NormalDataSectionPage.ets" \
  "ChoiceSelectionOverlay"
require_text "harmonyApp/entry/src/main/ets/pages/NormalDataSectionPage.ets" \
  "AppColors.ADD_ACTION"
require_absent "harmonyApp/entry/src/main/ets/pages/NormalDataSectionPage.ets" \
  "Select("
require_text "harmonyApp/entry/src/main/ets/core/resources/AppResources.ets" \
  "static choiceChevron(): Resource { return \$r('app.media.right_more'); }"
require_text "harmonyApp/entry/src/main/ets/core/resources/AppResources.ets" \
  "static choiceCheck(): Resource { return \$r('app.media.ic_profile_check'); }"
require_text "harmonyApp/entry/src/main/ets/pages/NormalDataSectionPage.ets" \
  "Image(AppImages.choiceChevron())"
require_text "harmonyApp/entry/src/main/ets/pages/NormalDataSectionPage.ets" \
  "Image(AppImages.choiceCheck())"
require_absent "harmonyApp/entry/src/main/ets/pages/NormalDataSectionPage.ets" \
  "Text('⌄')"
require_absent "harmonyApp/entry/src/main/ets/pages/NormalDataSectionPage.ets" \
  "Text('✓')"
require_text "harmonyApp/entry/src/main/ets/health/components/visuals/BodyManagementVisualComp.ets" \
  "BodyRegionLayer"
require_text "harmonyApp/entry/src/main/ets/core/resources/AppResources.ets" \
  "static bodyMuscleRegion(region: string): Resource"
require_absent "harmonyApp/entry/src/main/ets/health/components/visuals/BodyManagementVisualComp.ets" \
  "MuscleMarker"
require_absent "harmonyApp/entry/src/main/ets/health/components/visuals/BodyManagementVisualComp.ets" \
  "muscleNames"
require_text "harmonyApp/entry/src/main/ets/health/components/visuals/HrvAssessmentVisualComp.ets" \
  ".height(24)"

require_text "androidApp/src/main/kotlin/com/example/demo/health/components/visuals/BodyVisual.kt" \
  "BodyRegionLayer"
require_text "androidApp/src/main/kotlin/com/example/demo/core/resources/AppImages.kt" \
  "val BodyMuscleRegions = mapOf("
require_absent "androidApp/src/main/kotlin/com/example/demo/health/components/visuals/BodyVisual.kt" \
  "MuscleMarker"
require_absent "androidApp/src/main/kotlin/com/example/demo/health/components/visuals/BodyVisual.kt" \
  "selectedNames"

body_assets=(
  health_body_male_front_base
  health_body_male_back_base
  health_body_shoulders_front
  health_body_shoulders_back
  health_body_chest_front
  health_body_back_trapezius
  health_body_back_latissimus
  health_body_back_erector_spinae
  health_body_biceps_front
  health_body_triceps_back
  health_body_abdominals_front
  health_body_glutes_back
  health_body_quadriceps_front
  health_body_hamstrings_back
  health_body_calves_front
  health_body_calves_back
)
for asset in "${body_assets[@]}"; do
  canonical="health_dashboard_resources/body_muscle_masks/${asset}.png"
  android="androidApp/src/main/res/drawable-nodpi/${asset}.png"
  ios="iosApp/iosApp/Assets.xcassets/${asset}.imageset/${asset}.png"
  harmony="harmonyApp/entry/src/main/resources/base/media/${asset}.png"
  require_file "$canonical"
  require_same_file "$canonical" "$android"
  require_same_file "$canonical" "$ios"
  require_same_file "$canonical" "$harmony"
  require_text "tools/resource-inventory.json" "\"${asset}\""
done

android_localization="androidApp/src/main/kotlin/com/example/demo/health/HealthLocalization.kt"
harmony_localization="harmonyApp/entry/src/main/ets/core/resources/HealthLocalization.ets"
while IFS= read -r key; do
  require_text "$android_localization" "\"${key}\" -> R.string.${key}"
  require_text "$harmony_localization" "case '${key}': return \$r('app.string.${key}');"
done < <(
  jq -r '
    .sharedTextKeys[]
    | select(startswith("health_edit_") or startswith("health_visual_"))
  ' tools/resource-inventory.json
)

if ((failures > 0)); then
  printf '\n可编辑正常数据结构门禁失败：%d 项。\n' "$failures" >&2
  exit 1
fi

printf '\n可编辑正常数据结构门禁通过。\n'
