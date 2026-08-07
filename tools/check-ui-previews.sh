#!/usr/bin/env bash
set -euo pipefail

failures=0

require_pattern() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if ! rg -q "$pattern" "$file"; then
    echo "FAIL: $label ($file)"
    failures=$((failures + 1))
  fi
}

android_pages=(
  androidApp/src/main/kotlin/com/example/demo/health/screens/HealthDashboardScreen.kt
  androidApp/src/main/kotlin/com/example/demo/health/editor/CardEditor.kt
  androidApp/src/main/kotlin/com/example/demo/health/editor/NormalDataEditor.kt
  androidApp/src/main/kotlin/com/example/demo/health/detail/DetailPlaceholder.kt
  androidApp/src/main/kotlin/com/example/demo/home/MainTabsScreen.kt
  androidApp/src/main/kotlin/com/example/demo/home/ExplorePlaceholderScreen.kt
  androidApp/src/main/kotlin/com/example/demo/home/RecordsPlaceholderScreen.kt
  androidApp/src/main/kotlin/com/example/demo/auth/screens/entrance/EntranceScreen.kt
  androidApp/src/main/kotlin/com/example/demo/auth/screens/LoginPageScreen.kt
  androidApp/src/main/kotlin/com/example/demo/auth/screens/register/PhoneRegisterScreen.kt
  androidApp/src/main/kotlin/com/example/demo/auth/screens/register/EmailRegisterScreen.kt
  androidApp/src/main/kotlin/com/example/demo/auth/screens/verify/VerifyCodeScreen.kt
  androidApp/src/main/kotlin/com/example/demo/auth/screens/password/ForgotPasswordScreen.kt
  androidApp/src/main/kotlin/com/example/demo/auth/screens/password/PasswordSetupScreen.kt
  androidApp/src/main/kotlin/com/example/demo/auth/screens/password/ResetPasswordScreen.kt
  androidApp/src/main/kotlin/com/example/demo/auth/screens/profile/ProfileCompletionScreen.kt
  androidApp/src/main/kotlin/com/example/demo/auth/screens/profile/PersonalProfileEditScreen.kt
  androidApp/src/main/kotlin/com/example/demo/auth/screens/legal/LegalDocumentScreen.kt
  androidApp/src/main/kotlin/com/example/demo/auth/screens/signedin/SignedInScreen.kt
)

ios_pages=(
  iosApp/iosApp/App/ContentView.swift
  iosApp/iosApp/Home/Account/AccountView.swift
  iosApp/iosApp/Home/MainTabsView.swift
  iosApp/iosApp/Home/ExplorePlaceholderView.swift
  iosApp/iosApp/Home/RecordsPlaceholderView.swift
  iosApp/iosApp/Health/Views/HealthDashboardView.swift
  iosApp/iosApp/Health/Editor/HealthCardEditor.swift
  iosApp/iosApp/Health/Editor/NormalDataEditor.swift
  iosApp/iosApp/Health/Detail/HealthDetailView.swift
  iosApp/iosApp/Auth/Views/EntranceView.swift
  iosApp/iosApp/Auth/Views/LoginPageView.swift
  iosApp/iosApp/Auth/Views/PhoneRegisterView.swift
  iosApp/iosApp/Auth/Views/EmailRegisterView.swift
  iosApp/iosApp/Auth/Views/VerifyCodeView.swift
  iosApp/iosApp/Auth/Views/ForgotPasswordView.swift
  iosApp/iosApp/Auth/Views/PasswordSetupView.swift
  iosApp/iosApp/Auth/Views/ResetPasswordView.swift
  iosApp/iosApp/Auth/Views/ProfileCompletionView.swift
  iosApp/iosApp/Auth/Views/LegalDocumentView.swift
  iosApp/iosApp/Auth/Views/SignedInView.swift
)

harmony_pages=(
  harmonyApp/entry/src/main/ets/pages/EntrancePage.ets
  harmonyApp/entry/src/main/ets/pages/LoginFormPage.ets
  harmonyApp/entry/src/main/ets/pages/PhoneRegisterPage.ets
  harmonyApp/entry/src/main/ets/pages/EmailRegisterPage.ets
  harmonyApp/entry/src/main/ets/pages/VerifyCodePage.ets
  harmonyApp/entry/src/main/ets/pages/ForgotPasswordPage.ets
  harmonyApp/entry/src/main/ets/pages/PasswordSetupPage.ets
  harmonyApp/entry/src/main/ets/pages/ResetPasswordPage.ets
  harmonyApp/entry/src/main/ets/pages/ProfileCompletionPage.ets
  harmonyApp/entry/src/main/ets/pages/PrivacyPolicyPage.ets
  harmonyApp/entry/src/main/ets/pages/ServiceTermsPage.ets
  harmonyApp/entry/src/main/ets/pages/SignedInPage.ets
  harmonyApp/entry/src/main/ets/pages/HealthCardEditorPage.ets
  harmonyApp/entry/src/main/ets/pages/HealthDetailPage.ets
  harmonyApp/entry/src/main/ets/pages/NormalDataEditorPage.ets
  harmonyApp/entry/src/main/ets/pages/NormalDataSectionPage.ets
)

for file in "${android_pages[@]}"; do require_pattern "$file" '@Preview' 'Android page preview missing'; done
for file in "${ios_pages[@]}"; do require_pattern "$file" '#Preview' 'iOS page preview missing'; done
for file in "${harmony_pages[@]}"; do require_pattern "$file" '@Preview' 'HarmonyOS page preview missing'; done

while IFS= read -r file; do
  require_pattern "$file" '#Preview' 'iOS SwiftUI View file preview missing'
done < <(rg -l 'struct[[:space:]]+[A-Za-z0-9_]+:[[:space:]]*View' iosApp/iosApp -g '*.swift' | sort)

while IFS= read -r file; do
  require_pattern "$file" '@Preview' 'Android health Visual preview missing'
  require_pattern "$file" 'previewHealthVisual' 'Android health Visual must consume common preview fixture adapter'
done < <(find androidApp/src/main/kotlin/com/example/demo/health/components/visuals -maxdepth 1 -type f -name '*Visual.kt' | sort)
require_pattern androidApp/src/main/kotlin/com/example/demo/health/components/visuals/PreviewSupport.kt 'HealthPreviewFixtures' 'Android Visual preview fixture adapter missing'

while IFS=: read -r file line _; do
  preview_block="$(tail -n +"$line" "$file" | sed -n '1,/^[[:space:]]*build()[[:space:]]*{/p')"
  if rg -q '@(Consume|Link|ObjectLink|Prop)' <<<"$preview_block"; then
    echo "FAIL: HarmonyOS decorated child component is previewed directly ($file:$line)"
    failures=$((failures + 1))
  fi
done < <(rg -n '^[[:space:]]*@Preview' harmonyApp/entry/src/main/ets -g '*.ets' | sort)

require_pattern common/src/commonMain/kotlin/com/example/demo/common/health/mock/HealthPreviewFixtures.kt 'object HealthPreviewFixtures' 'shared preview fixture missing'
require_pattern androidApp/src/main/kotlin/com/example/demo/health/screens/HealthDashboardScreen.kt 'HealthPreviewFixtures' 'Android preview must consume shared fixture'
require_pattern iosApp/iosApp/Health/ViewModel/HealthDashboardViewModel.swift 'previewState: HealthState' 'iOS typed preview adapter missing'
require_pattern iosApp/iosApp/Health/Views/HealthDashboardView.swift 'HealthPreviewFixtures' 'iOS preview must consume shared fixture'
require_pattern harmony-kmp-bridge/src/ohosArm64Main/kotlin/com/example/demo/harmony/bridge/HarmonyLoginService.kt 'previewHealthSnapshot' 'HarmonyOS preview JSON bridge missing'
require_pattern harmonyApp/entry/src/main/ets/health/HealthDashboardViewModel.ets 'loadPreview' 'HarmonyOS preview mapper missing'
require_pattern harmonyApp/entry/src/main/ets/health/HealthDashboardViewModel.ets 'applyPreviewFallback' 'HarmonyOS design-host fallback missing'
require_pattern harmonyApp/entry/src/main/ets/preview/ComponentPreviewCatalog.ets 'DashboardCardComp' 'HarmonyOS health component preview catalog missing'
require_pattern harmonyApp/entry/src/main/ets/preview/ComponentPreviewCatalog.ets 'AccountOverviewComp' 'HarmonyOS shell component preview catalog missing'
require_pattern harmonyApp/entry/src/main/ets/preview/ComponentPreviewCatalog.ets 'CardEditorPreviewHost' 'HarmonyOS card editor parent preview host missing'
require_pattern harmonyApp/entry/src/main/ets/preview/ComponentPreviewCatalog.ets 'HealthDetailPreviewHost' 'HarmonyOS health detail parent preview host missing'
require_pattern harmonyApp/entry/src/main/ets/preview/VisualPreviewCatalog.ets '@Preview' 'HarmonyOS Visual parent preview catalog missing'
while IFS= read -r file; do
  visual_name="$(rg -o 'export struct [A-Za-z0-9_]+' "$file" | head -1 | sed 's/export struct //')"
  if [[ -n "$visual_name" ]]; then
    if ! rg -q "$visual_name" harmonyApp/entry/src/main/ets/preview/VisualPreviewCatalog*.ets; then
      echo "FAIL: HarmonyOS Visual parent catalogs do not cover $visual_name"
      failures=$((failures + 1))
    fi
  fi
done < <(find harmonyApp/entry/src/main/ets/health/components/visuals -maxdepth 1 -type f -name '*VisualComp.ets' | sort)
for file in harmonyApp/entry/src/main/ets/preview/VisualPreviewCatalog*.ets; do
  preview_count="$(rg -c '^[[:space:]]*@Preview' "$file")"
  if (( preview_count > 10 )); then
    echo "FAIL: HarmonyOS permits at most 10 Preview decorators per file ($file has $preview_count)"
    failures=$((failures + 1))
  fi
done
require_pattern harmonyApp/entry/src/main/ets/preview/VisualPreviewData.ets \
  'const weekPoints: HealthChartPointData\[\]' \
  'HarmonyOS Visual Preview object array must use an explicit contract type'
if rg -q '(chartPoints|metrics|sleepStages|weeklyDayPlans|segments):[[:space:]]*\[' \
  harmonyApp/entry/src/main/ets/preview/VisualPreviewData.ets; then
  echo 'FAIL: HarmonyOS Visual Preview contract arrays must be assigned through explicitly typed variables'
  failures=$((failures + 1))
fi
if rg -q '@kuiklybase/knoi|knoi/provider|getService|loadPreview|aboutToAppear' \
  harmonyApp/entry/src/main/ets/preview/VisualPreviewCatalog*.ets \
  harmonyApp/entry/src/main/ets/preview/VisualPreviewData.ets; then
  echo 'FAIL: HarmonyOS Visual preview catalog/data must remain pure ArkTS and native-module-free'
  failures=$((failures + 1))
fi
if rg -q 'getService|loadPreview|aboutToAppear' harmonyApp/entry/src/main/ets/preview/ComponentPreviewCatalog.ets; then
  echo 'FAIL: HarmonyOS parent preview hosts must not depend on runtime services'
  failures=$((failures + 1))
fi

require_pattern harmonyApp/entry/src/main/ets/core/bridge/HarmonyServiceProvider.ets 'installHarmonyService' 'HarmonyOS runtime service installation boundary missing'
if rg -q '@kuiklybase/knoi|knoi/provider' harmonyApp/entry/src/main/ets/core/bridge/HarmonyServiceProvider.ets; then
  echo 'FAIL: HarmonyServiceProvider must remain native-module-free for Preview'
  failures=$((failures + 1))
fi
if rg -q 'KnoiLoginAdapter' harmonyApp/entry/src/main/ets/auth/LoginLogicProvider.ets; then
  echo 'FAIL: LoginLogicProvider statically imports the native adapter'
  failures=$((failures + 1))
fi
if rg -q '^const[[:space:]]+loginViewModel:.*new LoginViewModel' harmonyApp/entry/src/main/ets/auth/LoginViewModelProvider.ets; then
  echo 'FAIL: LoginViewModelProvider eagerly creates a module-level ViewModel'
  failures=$((failures + 1))
fi

while IFS= read -r native_file; do
  case "$native_file" in
    harmonyApp/entry/src/main/ets/entryability/EntryAbility.ets|harmonyApp/entry/src/main/ets/knoi/provider.ets|harmonyApp/entry/src/main/ets/core/bridge/KnoiHarmonyServiceAdapter.ets) ;;
    *)
      echo "FAIL: native KNOI import escaped runtime composition root ($native_file)"
      failures=$((failures + 1))
      ;;
  esac
done < <(rg -l '@kuiklybase/knoi|knoi/provider' harmonyApp/entry/src/main/ets -g '*.ets' | sort)

if (( failures > 0 )); then
  echo "$failures UI preview check(s) failed."
  exit 1
fi

echo "UI preview coverage checks passed."
