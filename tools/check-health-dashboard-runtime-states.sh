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

android="androidApp/src/main/java/com/example/demo/health/HealthDashboardScreen.kt"
facade="common/src/commonMain/kotlin/com/example/demo/common/login/LoginFacade.kt"
ios_adapter="iosApp/iosApp/Login/SharedLoginAdapter.swift"
ios_model="iosApp/iosApp/Health/HealthDashboardViewModel.swift"
ios_view="iosApp/iosApp/Health/HealthDashboardView.swift"
ios_hero="iosApp/iosApp/Health/Components/HeroTopRow.swift"
harmony_bridge="harmony-kmp-bridge/src/ohosArm64Main/kotlin/com/example/demo/harmony/bridge/HarmonyLoginService.kt"
harmony_page="harmonyApp/entry/src/main/ets/pages/SignedInPage.ets"
harmony_card="harmonyApp/entry/src/main/ets/health/components/DashboardCardComp.ets"
harmony_hero="harmonyApp/entry/src/main/ets/health/components/HeroTopRowComp.ets"

check_present "$android" "result = viewModel.refreshHealthDashboard()"
check_present "$facade" "fun healthDashboardError(): String?"
check_present "$ios_adapter" "func healthDashboardError() -> String?"
check_present "$ios_model" "isDataCorrupted"
check_present "$ios_view" "health_data_corrupted"
check_present "$ios_view" "ScrollViewPanObserver"
check_present "$ios_view" "contentOffset.y <= -scrollView.adjustedContentInset.top + 1"
check_present "$ios_view" "gestureBeganAtTop"
check_present "$ios_view" "syncCycle: viewModel.syncCycle"
check_present "$ios_view" "onPullChanged"
check_present "$ios_view" "onPullEnded"
check_absent "$ios_view" "DragGesture("
check_absent "$ios_view" ".simultaneousGesture("
check_absent "$ios_view" ".refreshable {"
check_present "$ios_model" "@Published private(set) var syncCycle = 0"
check_present "$ios_model" "syncCycle += 1"
check_present "$ios_hero" "UIViewRepresentable"
check_present "$ios_hero" "animationView.play()"
check_present "$ios_hero" "animationView.stop()"
check_present "$ios_hero" "animationView.currentProgress = 0"
check_present "$ios_hero" "container.clipsToBounds = true"
check_present "$ios_hero" "animationView.translatesAutoresizingMaskIntoConstraints = false"
check_present "$ios_hero" "animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor)"
check_present "$ios_hero" "animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor)"
check_present "$ios_hero" "animationView.topAnchor.constraint(equalTo: container.topAnchor)"
check_present "$ios_hero" "animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor)"
check_absent "$ios_hero" "LottieView(animation:"
check_present "$harmony_bridge" '"{\"error\":\"$error\"}"'
check_present "$harmony_page" "healthDataCorrupted"
check_present "$harmony_page" "health_data_corrupted"
check_present "$harmony_card" ".layoutWeight(1)"
check_present "$harmony_card" ".padding({ left: 16, right: 16, top: 6, bottom: 6 })"
check_absent "$harmony_card" ".height('100%')"
check_present "$harmony_hero" "isSyncing: boolean = false;"
check_present "$harmony_hero" "this.lottieItem.play('lottieWatch')"

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "Health dashboard runtime state check passed."
