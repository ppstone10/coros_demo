#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

python3 - <<'PY'
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

root = Path.cwd()
required = {
    "shared authentication message keys": root / "common/src/commonMain/kotlin/com/example/demo/common/login/AuthMessageKeys.kt",
    "Android authentication resolver": root / "androidApp/src/main/java/com/example/demo/login/components/AuthLocalization.kt",
    "Android default strings": root / "androidApp/src/main/res/values/strings.xml",
    "Android English strings": root / "androidApp/src/main/res/values-en/strings.xml",
    "iOS authentication resolver": root / "iosApp/iosApp/Resources/AppResources.swift",
    "iOS String Catalog": root / "iosApp/iosApp/Resources/Localizable.xcstrings",
    "HarmonyOS authentication resolver": root / "harmonyApp/entry/src/main/ets/resources/AuthLocalization.ets",
    "HarmonyOS default strings": root / "harmonyApp/entry/src/main/resources/base/element/string.json",
    "HarmonyOS English strings": root / "harmonyApp/entry/src/main/resources/en_US/element/string.json",
    "Android app language state": root / "androidApp/src/main/java/com/example/demo/ui/language/AppLanguage.kt",
    "Android language selector": root / "androidApp/src/main/java/com/example/demo/ui/language/LanguageSelection.kt",
    "iOS app language state": root / "iosApp/iosApp/Resources/AppResources.swift",
    "HarmonyOS app language state": root / "harmonyApp/entry/src/main/ets/resources/AppLanguage.ets",
}

errors = []
for label, path in required.items():
    if not path.is_file():
        errors.append(f"missing {label}: {path.relative_to(root)}")

if errors:
    for error in errors:
        print(f"FAIL: {error}")
    sys.exit(1)

key_source = required["shared authentication message keys"].read_text(encoding="utf-8")
expected = set(re.findall(r'const val \w+\s*=\s*"(auth_[a-z0-9_]+)"', key_source))
if not expected:
    errors.append("AuthMessageKeys.kt does not declare any auth_* keys")

def android_keys(path: Path) -> set[str]:
    tree = ET.parse(path)
    keys = [
        item.attrib["name"]
        for item in tree.getroot().findall("string")
        if item.attrib.get("name", "").startswith("auth_")
    ]
    duplicates = sorted({key for key in keys if keys.count(key) > 1})
    if duplicates:
        errors.append(f"{path.relative_to(root)} has duplicate keys: {', '.join(duplicates)}")
    return set(keys)

android_default = android_keys(required["Android default strings"])
android_en = android_keys(required["Android English strings"])

ios_data = json.loads(required["iOS String Catalog"].read_text(encoding="utf-8"))
ios_strings = ios_data.get("strings", {})
ios_keys = {key for key in ios_strings if key.startswith("auth_")}
for key in ios_keys:
    localizations = ios_strings[key].get("localizations", {})
    for locale in ("zh-Hans", "en"):
        value = localizations.get(locale, {}).get("stringUnit", {}).get("value")
        if not isinstance(value, str) or not value.strip():
            errors.append(f"iOS key {key} is missing {locale} value")

def harmony_keys(path: Path) -> set[str]:
    data = json.loads(path.read_text(encoding="utf-8"))
    keys = [
        item.get("name", "")
        for item in data.get("string", [])
        if item.get("name", "").startswith("auth_")
    ]
    duplicates = sorted({key for key in keys if keys.count(key) > 1})
    if duplicates:
        errors.append(f"{path.relative_to(root)} has duplicate keys: {', '.join(duplicates)}")
    return set(keys)

harmony_default = harmony_keys(required["HarmonyOS default strings"])
harmony_en = harmony_keys(required["HarmonyOS English strings"])

sets = {
    "Android default": android_default,
    "Android English": android_en,
    "iOS": ios_keys,
    "HarmonyOS default": harmony_default,
    "HarmonyOS English": harmony_en,
}
for label, actual in sets.items():
    missing = sorted(expected - actual)
    if missing:
        errors.append(f"{label} missing keys: {', '.join(missing)}")

reference_label = "Android default"
reference_keys = sets[reference_label]
for label, actual in sets.items():
    if label == reference_label:
        continue
    missing = sorted(reference_keys - actual)
    extra = sorted(actual - reference_keys)
    if missing or extra:
        details = []
        if missing:
            details.append(f"missing {', '.join(missing)}")
        if extra:
            details.append(f"extra {', '.join(extra)}")
        errors.append(f"{label} auth_* key set differs from {reference_label}: {'; '.join(details)}")

for label in ("Android authentication resolver", "HarmonyOS authentication resolver"):
    resolver = required[label].read_text(encoding="utf-8")
    for key in expected:
        if key not in resolver:
            errors.append(f"{label} does not map key: {key}")

ios_resolver = required["iOS authentication resolver"].read_text(encoding="utf-8")
if "localizedAuthMessage" not in ios_resolver or "localizedBundle.localizedString" not in ios_resolver:
    errors.append("iOS authentication resolver does not use the shared localization entry")

language_contracts = {
    "Android app language state": ("zh-Hans", "getSharedPreferences", "LocalResources"),
    "Android language selector": ("LanguageIconButton", "AppLanguageDialogHost", "countryDisplayName"),
    "iOS app language state": ("AppLanguageStore", "UserDefaults", "LanguageSelectionButton", "Image(systemName: \"globe\")"),
    "HarmonyOS app language state": ("PersistentStorage.persistProp", "setAppPreferredLanguage", "zh-Hans"),
}
for label, tokens in language_contracts.items():
    source = required[label].read_text(encoding="utf-8")
    for token in tokens:
        if token not in source:
            errors.append(f"{label} is missing language contract token: {token}")

language_entrypoints = {
    "Android Entrance": root / "androidApp/src/main/java/com/example/demo/login/entrance/EntranceScreen.kt",
    "Android Me": root / "androidApp/src/main/java/com/example/demo/login/signedin/SignedInScreen.kt",
    "iOS Entrance": root / "iosApp/iosApp/Login/Views/EntranceView.swift",
    "iOS Me": root / "iosApp/iosApp/Account/AccountView.swift",
    "HarmonyOS Entrance": root / "harmonyApp/entry/src/main/ets/pages/EntrancePage.ets",
    "HarmonyOS Me": root / "harmonyApp/entry/src/main/ets/pages/SignedInPage.ets",
}
for label, path in language_entrypoints.items():
    source = path.read_text(encoding="utf-8")
    if not any(token in source for token in ("LanguageIconButton", "LanguageSelectionButton", "sys.symbol.worldclock")):
        errors.append(f"{label} is missing the language selector entry point")

ios_refresh_contracts = {
    "iOS Entrance": ("@EnvironmentObject private var languageStore", "languageStore.current", "EntranceTopBar"),
    "iOS Me": ("@EnvironmentObject private var languageStore", "languageStore.current"),
    "iOS bottom navigation": ("@EnvironmentObject private var languageStore", "languageStore.current"),
}
ios_refresh_paths = {
    "iOS Entrance": language_entrypoints["iOS Entrance"],
    "iOS Me": language_entrypoints["iOS Me"],
    "iOS bottom navigation": root / "iosApp/iosApp/Home/MainTabsView.swift",
}
for label, tokens in ios_refresh_contracts.items():
    source = ios_refresh_paths[label].read_text(encoding="utf-8")
    for token in tokens:
        if token not in source:
            errors.append(f"{label} is missing immediate refresh/layout contract token: {token}")

harmony_entrance = language_entrypoints["HarmonyOS Entrance"].read_text(encoding="utf-8")
if "this.EntranceTopBar()" not in harmony_entrance:
    errors.append("HarmonyOS Entrance must place the logo and language selector in a full-width top bar")

target_files = [
    root / "common/src/commonMain/kotlin/com/example/demo/common/login/LoginModels.kt",
    root / "common/src/commonMain/kotlin/com/example/demo/common/login/LoginRules.kt",
    root / "common/src/commonMain/kotlin/com/example/demo/common/login/LoginUseCase.kt",
    root / "common/src/commonMain/kotlin/com/example/demo/common/login/LoginStore.kt",
]
for path in target_files:
    text = path.read_text(encoding="utf-8")
    for phrase in (
        "请先登录", "请输入完整且有效的信息", "账号已存在", "账号不存在", "密码不正确",
        "新密码不能与旧密码相同", "验证码不正确", "验证码已过期，请重新获取", "请选择注册地区",
        "请输入账号", "请输入密码", "请输入11位手机号", "请输入有效邮箱", "请输入验证码",
        "密码需要为6-20位", "密码只能包含字母和数字", "密码需要包含字母和数字",
        "两次输入的密码不一致", "请输入账号、密码、区域和验证码", "请输入账号和密码",
    ):
        if phrase in text:
            errors.append(f"localized authentication phrase remains in common: {path.relative_to(root)}: {phrase}")

if errors:
    for error in errors:
        print(f"FAIL: {error}")
    sys.exit(1)

print(f"Resource localization check passed: {len(expected)} authentication keys aligned across 3 platforms.")
PY
