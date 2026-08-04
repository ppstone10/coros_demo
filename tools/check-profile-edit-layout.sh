#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

python3 - "$repo_root" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])

android = (root / "androidApp/src/main/kotlin/com/example/demo/auth/screens/profile/PersonalProfileEditScreen.kt").read_text()
ios = (root / "iosApp/iosApp/Home/Account/AccountView.swift").read_text()
harmony = (root / "harmonyApp/entry/src/main/ets/pages/ProfileCompletionPage.ets").read_text()

errors: list[str] = []

android_view = android[android.index("private fun PersonalProfileEditContent("):]
if android_view.index("Row(") >= android_view.index(".verticalScroll(rememberScrollState())"):
    errors.append("Android profile edit header must remain before the vertically scrolling profile content.")

ios_view = ios[ios.index("private struct PersonalProfileEditView: View"):]
if ios_view.index("HStack {") >= ios_view.index("ScrollView {"):
    errors.append("iOS profile edit header must remain before ScrollView.")

harmony_page = harmony[harmony.index("struct ProfileCompletionPage"):]
build_start = harmony_page.index("  build() {")
build_end = harmony_page.index("  private handleProfileBack", build_start)
harmony_build = harmony_page[build_start:build_end]

header_call = "this.ProfileEditHeader();"
scroll_call = "Scroll() {"
if header_call not in harmony_build:
    errors.append("HarmonyOS profile edit header must be extracted and called outside Scroll.")
elif harmony_build.index(header_call) >= harmony_build.index(scroll_call):
    errors.append("HarmonyOS ProfileEditHeader must be placed before Scroll.")

if ".align(Alignment.TopStart)" not in harmony_build:
    errors.append("HarmonyOS scrolling profile content must explicitly align to the top start.")

if errors:
    for error in errors:
        print(f"FAIL: {error}")
    raise SystemExit(1)

print("PASS: Android, iOS, and HarmonyOS profile edit headers are outside scrolling content.")
print("PASS: HarmonyOS short profile content is explicitly top-aligned.")
PY
