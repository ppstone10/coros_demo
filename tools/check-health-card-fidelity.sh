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

check_absent_text() {
  local file="$1"
  local marker="$2"
  if rg -Fq "$marker" "$root/$file"; then
    echo "FAIL: $file still contains direct resource reference $marker"
    failed=1
  else
    echo "PASS: $file does not contain direct resource reference $marker"
  fi
}

check_same_hash() {
  local first="$1"
  shift
  local expected
  expected="$(shasum -a 256 "$root/$first" | awk '{print $1}')"
  local file
  for file in "$@"; do
    local actual
    actual="$(shasum -a 256 "$root/$file" | awk '{print $1}')"
    if [[ "$actual" == "$expected" ]]; then
      echo "PASS: $file matches $first"
    else
      echo "FAIL: $file differs from $first"
      failed=1
    fi
  done
}

check_file androidApp/src/main/res/font/coros_app_bold.ttf
check_file androidApp/src/main/res/font/coros_app_regular.ttf
check_file iosApp/iosApp/Resources/Fonts/COROS-APP-Bold.ttf
check_file iosApp/iosApp/Resources/Fonts/COROS-APP-Regular.ttf
check_file harmonyApp/entry/src/main/resources/rawfile/coros_app_bold.ttf
check_file harmonyApp/entry/src/main/resources/rawfile/coros_app_regular.ttf
check_file androidApp/src/main/res/drawable-nodpi/health_activity_map.png
check_file iosApp/iosApp/Assets.xcassets/health_activity_map.imageset/health_activity_map.png
check_file harmonyApp/entry/src/main/resources/base/media/health_activity_map.png
check_file androidApp/src/main/res/drawable-nodpi/health_today_header.png
check_file iosApp/iosApp/Assets.xcassets/health_today_header.imageset/health_today_header.png
check_file harmonyApp/entry/src/main/resources/base/media/health_today_header.png
check_file androidApp/src/main/res/drawable-nodpi/health_today_runner.png
check_file iosApp/iosApp/Assets.xcassets/health_today_runner.imageset/health_today_runner.png
check_file harmonyApp/entry/src/main/resources/base/media/health_today_runner.png
check_file iosApp/iosApp/Assets.xcassets/health_recovery_status.imageset/health_recovery_status.svg
check_file harmonyApp/entry/src/main/resources/base/media/health_recovery_status.svg

check_same_hash androidApp/src/main/res/font/coros_app_bold.ttf \
  iosApp/iosApp/Resources/Fonts/COROS-APP-Bold.ttf \
  harmonyApp/entry/src/main/resources/rawfile/coros_app_bold.ttf
check_same_hash androidApp/src/main/res/font/coros_app_regular.ttf \
  iosApp/iosApp/Resources/Fonts/COROS-APP-Regular.ttf \
  harmonyApp/entry/src/main/resources/rawfile/coros_app_regular.ttf
check_same_hash androidApp/src/main/res/drawable-nodpi/health_activity_map.png \
  iosApp/iosApp/Assets.xcassets/health_activity_map.imageset/health_activity_map.png \
  harmonyApp/entry/src/main/resources/base/media/health_activity_map.png
check_same_hash androidApp/src/main/res/drawable-nodpi/health_today_header.png \
  iosApp/iosApp/Assets.xcassets/health_today_header.imageset/health_today_header.png \
  harmonyApp/entry/src/main/resources/base/media/health_today_header.png
check_same_hash androidApp/src/main/res/drawable-nodpi/health_today_runner.png \
  iosApp/iosApp/Assets.xcassets/health_today_runner.imageset/health_today_runner.png \
  harmonyApp/entry/src/main/resources/base/media/health_today_runner.png

# Android keeps legacy icons as WebP while iOS/HarmonyOS package PNG variants.
# The two PNG copies must remain byte-identical after conversion from the
# Android visual baseline, including transparent-pixel normalization.
health_png_assets=(
  icon_small_plan icon_small_training_load icon_small_training_effect
  icon_recovery_sports icon_small_running_ability icon_small_cycling
  icon_small_heart_rate icon_small_stress icon_small_sleep icon_small_sleep_hrv
  icon_small_rhr icon_small_health_detection icon_small_body icon_calendar
  icon_device_sportting steps_icon icon_calories sport_time_icon
  data_screen_edit_add delete
)
for asset in "${health_png_assets[@]}"; do
  check_same_hash "iosApp/iosApp/Assets.xcassets/${asset}.imageset/${asset}.png" \
    "harmonyApp/entry/src/main/resources/base/media/${asset}.png"
done

check_absent_text androidApp/src/main/kotlin/com/example/demo/health/components/DashboardCard.kt "FigmaCardHeight"
check_text androidApp/src/main/kotlin/com/example/demo/health/components/DashboardCard.kt "clipToBounds()"
check_absent_text iosApp/iosApp/Health/Views/HealthDashboardView.swift "figmaCardHeight"
check_text iosApp/iosApp/Health/Views/HealthDashboardCardRow.swift ".clipped()"
check_absent_text harmonyApp/entry/src/main/ets/health/components/DashboardCardComp.ets "minimumCardHeight"
check_text harmonyApp/entry/src/main/ets/health/components/DashboardCardComp.ets ".clip(true)"
check_text harmonyApp/entry/src/main/ets/entryability/EntryAbility.ets "COROSAPP"
check_text androidApp/src/main/res/values/strings.xml '<string name="health_visual_day_mon">一</string>'
check_text iosApp/iosApp/Resources/Localizable.xcstrings '"health_visual_day_mon"'
check_text harmonyApp/entry/src/main/resources/base/element/string.json '"name": "health_visual_day_mon", "value": "一"'

# HLTH-VIS-015: Android is the semantic health-resource baseline. All three
# platform catalogs must expose the Figma overview assets instead of scattering
# literal resource names through the renderers.
check_text androidApp/src/main/kotlin/com/example/demo/core/resources/AppImages.kt "val ActivityMap"
check_text androidApp/src/main/kotlin/com/example/demo/core/resources/AppImages.kt "val TodayHeader"
check_text androidApp/src/main/kotlin/com/example/demo/core/resources/AppImages.kt "val TodayRunner"
check_text androidApp/src/main/kotlin/com/example/demo/core/resources/AppImages.kt "val BodyMuscleRegions = mapOf("
check_text androidApp/src/main/kotlin/com/example/demo/core/resources/AppImages.kt '"trapezius_back" to AppImageAsset(R.drawable.health_body_back_trapezius)'
check_text iosApp/iosApp/Core/Resources/AppResources.swift "static let activityMap"
check_text iosApp/iosApp/Core/Resources/AppResources.swift "static let todayHeader"
check_text iosApp/iosApp/Core/Resources/AppResources.swift "static let todayRunner"
check_text iosApp/iosApp/Core/Resources/AppResources.swift "static let bodyMuscleRegions: [String: String] = ["
check_text iosApp/iosApp/Core/Resources/AppResources.swift '"trapezius_back": "health_body_back_trapezius"'
check_text harmonyApp/entry/src/main/ets/core/resources/AppResources.ets "static activityMap()"
check_text harmonyApp/entry/src/main/ets/core/resources/AppResources.ets "static todayHeader()"
check_text harmonyApp/entry/src/main/ets/core/resources/AppResources.ets "static todayRunner()"
check_text harmonyApp/entry/src/main/ets/core/resources/AppResources.ets "static bodyMuscleRegion(region: string): Resource"
check_text harmonyApp/entry/src/main/ets/core/resources/AppResources.ets "case 'trapezius_back': return \$r('app.media.health_body_back_trapezius')"

check_absent_text androidApp/src/main/kotlin/com/example/demo/health/components/DashboardCard.kt "R.drawable.health_"
check_absent_text iosApp/iosApp/Health/Views/HealthDashboardView.swift 'Image("health_'
check_absent_text harmonyApp/entry/src/main/ets/health/components/DashboardCardComp.ets "Image(\$r('app.media.health_"

# HLTH-VIS-016: TodayActivity uses Android's general-card icon identity outside
# the dashboard's dedicated header treatment; it must never fall through to HR.
check_text iosApp/iosApp/Core/Resources/AppResources.swift 'static let todayActivity = "icon_small_training_effect"'
check_text iosApp/iosApp/Health/ViewModel/HealthDashboardViewModel.swift 'case "TodayActivity": return AppImages.Health.todayActivity'
check_text harmonyApp/entry/src/main/ets/core/resources/AppResources.ets "case 'TodayActivity': return \$r('app.media.icon_small_training_effect')"
check_text harmonyApp/entry/src/main/ets/health/editor/CardEditorComp.ets "AppImages.healthCardIcon(card.id)"
check_text harmonyApp/entry/src/main/ets/health/detail/HealthDetailComp.ets "AppImages.healthCardIcon(this.card().id)"

# HLTH-VIS-030..032: all native renderers keep the accepted Android behavior.
check_text iosApp/iosApp/Health/Components/Visuals/RestingHeartRateView.swift "path.move(to: CGPoint(x: markerX, y: 2))"
check_text iosApp/iosApp/Health/Views/HealthDashboardCardRow.swift "if card.id == \"HealthCheck\", let measuredTime = card.visual?.caption"
check_text iosApp/iosApp/Health/Components/HeroTopRow.swift "onTapWatch"
check_text iosApp/iosApp/Home/MainTabsView.swift "onWatchTap: { selected = .me }"
check_text harmonyApp/entry/src/main/ets/health/components/visuals/RestingHeartRateVisualComp.ets "this.RangeMarker()"
check_text harmonyApp/entry/src/main/ets/health/components/DashboardCardComp.ets "this.card.id === 'HealthCheck' && this.card.visual.captionKey"
check_text harmonyApp/entry/src/main/ets/health/components/HeroTopRowComp.ets "onTap?: () => void"
check_text harmonyApp/entry/src/main/ets/pages/SignedInPage.ets "onTap: () => { this.selectedTab = 3;"
check_text iosApp/iosApp/Health/Components/HeroArcView.swift "private var calorieProgress"
check_text iosApp/iosApp/Health/Components/Visuals/TrendView.swift "HeartRateIntervalOverviewView(points: visual.chartPoints)"
check_text iosApp/iosApp/Health/Components/Visuals/WeeklyPlanView.swift "selectedDay = index"
check_text harmonyApp/entry/src/main/ets/pages/SignedInPage.ets "private calorieArcProgress()"
check_text harmonyApp/entry/src/main/ets/health/components/visuals/TrendVisualComp.ets "this.HeartRateIntervalOverview()"
check_text harmonyApp/entry/src/main/ets/health/components/visuals/WeeklyPlanVisualComp.ets "this.weeklySelectedIndex()"
check_text iosApp/iosApp/Health/Components/Visuals/AbilityView.swift "AbilityGaugeOverviewView(progress: progress, accent: accent)"
check_text harmonyApp/entry/src/main/ets/health/components/visuals/AbilityVisualComp.ets "gaugeProgress(this.visual.progress)"

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "Health card fidelity check passed."
