#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

failures=0
require_text() {
  local file="$1"
  local text="$2"
  if [[ -f "$file" ]] && grep -Fq -- "$text" "$file"; then
    printf 'PASS: %s contains %s\n' "$file" "$text"
  else
    printf 'FAIL: %s missing %s\n' "$file" "$text" >&2
    failures=$((failures + 1))
  fi
}

require_text "common/src/commonMain/kotlin/com/example/demo/common/health/model/EditableHealthData.kt" "enum class HealthEditSourceKind"
require_text "common/src/commonMain/kotlin/com/example/demo/common/health/rules/HealthEditableRules.kt" "fun project(data: HealthDashboardData"
require_text "common/src/commonMain/kotlin/com/example/demo/common/health/rules/HealthEditableRules.kt" "fun validateSection("
require_text "common/src/commonMain/kotlin/com/example/demo/common/health/store/HealthDashboardStore.kt" "transientEditSourceKind"
require_text "common/src/commonMain/kotlin/com/example/demo/common/health/rules/HealthEditableForms.kt" "fun applyDetailed("
require_text "common/src/commonMain/kotlin/com/example/demo/common/health/rules/HealthEditableForms.kt" "fun applyResultJson("
require_text "common/src/commonTest/kotlin/com/example/demo/common/health/EditableHealthDataTest.kt" "abnormalScenarioProjectsCurrentMemoryAndPersistedValuesIntoEditor"
require_text "common/src/commonTest/kotlin/com/example/demo/common/health/EditableHealthDataTest.kt" "emptyAndCorruptedScenariosShareZeroProjectionButKeepDifferentSourceMeaning"
require_text "common/src/commonTest/kotlin/com/example/demo/common/health/EditableHealthDataTest.kt" "detailedFormAuditNamesTheFieldAndReasonInsteadOfReturningOnlyFalse"

require_text "androidApp/src/main/kotlin/com/example/demo/health/editor/NormalDataEditor.kt" "validationIssueText(issue)"
require_text "androidApp/src/main/kotlin/com/example/demo/health/editor/NormalDataEditor.kt" "SourceNotice(key)"
require_text "iosApp/iosApp/Health/Editor/NormalDataEditor.swift" "sourceMessageKey"
require_text "iosApp/iosApp/Health/Editor/NormalDataEditor.swift" "validationMessage(_ issue: NormalEditValidationIssue)"
require_text "harmonyApp/entry/src/main/ets/pages/NormalDataEditorPage.ets" "sourceMessageKey"
require_text "harmonyApp/entry/src/main/ets/pages/NormalDataSectionPage.ets" "saveNormalHealthEditFormResultJson"
require_text "harmonyApp/entry/src/main/ets/pages/NormalDataSectionPage.ets" "validationMessage(issue: NormalEditValidationIssue)"
require_text "harmonyApp/entry/src/main/ets/knoi/provider.ets" "saveNormalHealthEditFormResultJson"

if ((failures > 0)); then
  printf '\nCross-scenario health editing gate failed: %d item(s).\n' "$failures" >&2
  exit 1
fi

printf '\nCross-scenario health editing gate passed.\n'
