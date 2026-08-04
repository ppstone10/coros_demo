#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

require_file() {
  local relative="$1"
  local label="$2"
  if [[ -f "$ROOT/$relative" ]]; then
    pass "$label"
  else
    fail "$label"
  fi
}

require_contains() {
  local relative="$1"
  local pattern="$2"
  local label="$3"
  if rg -q -- "$pattern" "$ROOT/$relative"; then
    pass "$label"
  else
    fail "$label"
  fi
}

require_absent() {
  local relative="$1"
  local pattern="$2"
  local label="$3"
  if rg -q -- "$pattern" "$ROOT/$relative"; then
    fail "$label"
  else
    pass "$label"
  fi
}

ANDROID_ROUTES="androidApp/src/main/kotlin/com/example/demo/auth/navigation/AuthRoute.kt"
ANDROID_GRAPH="androidApp/src/main/kotlin/com/example/demo/auth/navigation/AuthNavGraph.kt"
ANDROID_HEALTH_ROUTES="androidApp/src/main/kotlin/com/example/demo/health/navigation/HealthRoute.kt"
ANDROID_HEALTH_GRAPH="androidApp/src/main/kotlin/com/example/demo/health/navigation/HealthNavGraph.kt"
ANDROID_TABS="androidApp/src/main/kotlin/com/example/demo/home/MainTabsScreen.kt"
ANDROID_DASHBOARD="androidApp/src/main/kotlin/com/example/demo/health/screens/HealthDashboardScreen.kt"
ANDROID_ACCOUNT="androidApp/src/main/kotlin/com/example/demo/auth/screens/signedin/SignedInScreen.kt"

require_contains "$ANDROID_HEALTH_ROUTES" 'data class HealthDetailRoute' "Android registers a typed health detail route"
require_contains "$ANDROID_HEALTH_ROUTES" 'object HealthEditorRoute' "Android registers a typed health editor route"
require_contains "$ANDROID_ROUTES" 'object ProfileEditRoute' "Android registers a typed profile edit route"
require_contains "$ANDROID_HEALTH_GRAPH" 'composable<HealthDetailRoute>' "Android health graph owns health detail"
require_contains "$ANDROID_HEALTH_GRAPH" 'composable<HealthEditorRoute>' "Android health graph owns health editor"
require_contains "$ANDROID_GRAPH" 'composable<ProfileEditRoute>' "Android NavHost owns profile edit"
require_contains "$ANDROID_GRAPH" 'healthNavGraph' "Android NavHost mounts the health graph by domain"
require_contains "$ANDROID_TABS" 'healthListState' "Android hoists the health list state above the route destination"
require_contains "$ANDROID_DASHBOARD" 'listState: LazyListState' "Android dashboard consumes retained list state"
require_absent "$ANDROID_DASHBOARD" 'data class Detail' "Android no longer models detail as a local DashboardPage"
require_absent "$ANDROID_DASHBOARD" 'data object Editor' "Android no longer models editor as a local DashboardPage"
require_absent "$ANDROID_ACCOUNT" 'editingProfile' "Android profile edit no longer uses local full-screen branching"

IOS_COORDINATOR="iosApp/iosApp/Auth/AuthCoordinator.swift"
IOS_HEALTH_NAV="iosApp/iosApp/Health/Navigation/HealthNavigation.swift"
IOS_DASHBOARD="iosApp/iosApp/Health/Views/HealthDashboardView.swift"
IOS_ACCOUNT="iosApp/iosApp/Home/Account/AccountView.swift"

require_contains "$IOS_COORDINATOR" 'case healthDetail\(cardID: String\)' "iOS registers a health detail route"
require_contains "$IOS_COORDINATOR" 'case healthEditor' "iOS registers a health editor route"
require_contains "$IOS_COORDINATOR" 'case profileEdit' "iOS registers a profile edit route"
require_contains "$IOS_HEALTH_NAV" 'HealthDetailView' "iOS health navigation owns health detail"
require_contains "$IOS_HEALTH_NAV" 'HealthCardEditor' "iOS health navigation owns health editor"
require_contains "$IOS_COORDINATOR" 'healthDestination' "iOS coordinator forwards health navigation to the health module"
require_contains "$IOS_DASHBOARD" 'onOpenDetail' "iOS dashboard delegates detail navigation"
require_contains "$IOS_DASHBOARD" 'onOpenEditor' "iOS dashboard delegates editor navigation"
require_absent "$IOS_DASHBOARD" 'case detail' "iOS no longer models detail as a local DashboardPage"
require_absent "$IOS_DASHBOARD" 'case editor' "iOS no longer models editor as a local DashboardPage"
require_absent "$IOS_ACCOUNT" 'editingProfile' "iOS profile edit no longer uses local full-screen branching"

HARMONY_ROUTES="harmonyApp/entry/src/main/ets/auth/navigation/AuthRoutes.ets"
HARMONY_ROOT="harmonyApp/entry/src/main/ets/pages/SignedInPage.ets"
HARMONY_PAGES="harmonyApp/entry/src/main/resources/base/profile/main_pages.json"

require_contains "$HARMONY_ROUTES" 'DETAIL: .pages/HealthDetailPage.' "HarmonyOS health group registers a health detail route"
require_contains "$HARMONY_ROUTES" 'EDITOR: .pages/HealthCardEditorPage.' "HarmonyOS health group registers a health editor route"
require_contains "$HARMONY_ROUTES" 'toHealthDetail' "HarmonyOS provides a stable health detail factory"
require_file "harmonyApp/entry/src/main/ets/pages/HealthDetailPage.ets" "HarmonyOS has a health detail page"
require_file "harmonyApp/entry/src/main/ets/pages/HealthCardEditorPage.ets" "HarmonyOS has a health editor page"
require_contains "$HARMONY_PAGES" 'pages/HealthDetailPage' "HarmonyOS page profile includes health detail"
require_contains "$HARMONY_PAGES" 'pages/HealthCardEditorPage' "HarmonyOS page profile includes health editor"
require_contains "$HARMONY_ROOT" 'toHealthDetail' "HarmonyOS root pushes health detail with a stable ID"
require_contains "$HARMONY_ROOT" 'NavOperation.Push, AuthRoutes.health.EDITOR' "HarmonyOS root pushes health editor"
require_absent "$HARMONY_ROOT" "PAGE_DETAIL" "HarmonyOS no longer models detail as a local page"
require_absent "$HARMONY_ROOT" "PAGE_EDITOR" "HarmonyOS no longer models editor as a local page"
require_contains "$HARMONY_ROOT" 'return false;' "HarmonyOS root allows the system back action to exit"

require_file "androidApp/src/main/res/drawable/health_recovery_time.xml" "Android recovery time icon exists"
require_file "iosApp/iosApp/Assets.xcassets/health_recovery_time.imageset/Contents.json" "iOS recovery time image set exists"
require_file "iosApp/iosApp/Assets.xcassets/health_recovery_time.imageset/health_recovery_time.svg" "iOS recovery time SVG exists"
require_file "harmonyApp/entry/src/main/resources/base/media/health_recovery_time.svg" "HarmonyOS recovery time icon exists"
require_contains "androidApp/src/main/kotlin/com/example/demo/core/resources/AppImages.kt" 'health_recovery_time' "Android Recovery maps to recovery time icon"
require_contains "iosApp/iosApp/Core/Resources/AppResources.swift" 'health_recovery_time' "iOS Recovery maps to recovery time icon"
require_contains "harmonyApp/entry/src/main/ets/core/resources/AppResources.ets" 'health_recovery_time' "HarmonyOS Recovery maps to recovery time icon"
require_contains "tools/resource-inventory.json" '"health_recovery_time"' "Shared resource inventory tracks recovery time icon"

if (( failures > 0 )); then
  printf '\n%d health navigation checks failed.\n' "$failures" >&2
  exit 1
fi

printf '\nAll health navigation checks passed.\n'
