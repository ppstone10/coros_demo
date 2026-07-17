#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

python3 - <<'PY'
import hashlib
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

root = Path.cwd()
manifest_path = root / "tools/resource-inventory.json"
errors: list[str] = []

if not manifest_path.is_file():
    print("FAIL: missing machine-readable resource inventory: tools/resource-inventory.json")
    sys.exit(1)

try:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
except (json.JSONDecodeError, OSError) as error:
    print(f"FAIL: invalid resource inventory: {error}")
    sys.exit(1)

if manifest.get("schemaVersion") != 1:
    errors.append("resource inventory schemaVersion must be 1")

shared_images = manifest.get("sharedImages", [])
if not isinstance(shared_images, list) or not shared_images:
    errors.append("sharedImages must be a non-empty array")
    shared_images = []
if len(shared_images) != len(set(shared_images)):
    errors.append("sharedImages contains duplicate semantic names")

def stems(paths: list[Path]) -> set[str]:
    return {path.stem for path in paths if path.is_file()}

android_images = stems([
    *root.glob("androidApp/src/main/res/drawable*/*"),
    *root.glob("androidApp/src/main/res/mipmap*/*"),
])
ios_images = {
    path.name.removesuffix(".imageset")
    for path in root.glob("iosApp/iosApp/Assets.xcassets/*.imageset")
    if path.is_dir()
}
harmony_images = stems(list(root.glob("harmonyApp/entry/src/main/resources/base/media/*")))

for name in shared_images:
    for platform, available in (
        ("Android", android_images),
        ("iOS", ios_images),
        ("HarmonyOS", harmony_images),
    ):
        if name not in available:
            errors.append(f"{platform} is missing shared image: {name}")

raw_roots = {
    "Android": root / "androidApp/src/main/res/raw",
    "iOS": root / "iosApp/iosApp/Resources",
    "HarmonyOS": root / "harmonyApp/entry/src/main/resources/rawfile",
}
shared_raw = manifest.get("sharedRaw", [])
if not isinstance(shared_raw, list) or not shared_raw:
    errors.append("sharedRaw must be a non-empty array")
    shared_raw = []

for item in shared_raw:
    name = item.get("name", "") if isinstance(item, dict) else ""
    if not name:
        errors.append("sharedRaw contains an item without name")
        continue
    hashes: dict[str, str] = {}
    for platform, directory in raw_roots.items():
        path = directory / name
        if not path.is_file():
            errors.append(f"{platform} is missing shared raw resource: {name}")
            continue
        hashes[platform] = hashlib.sha256(path.read_bytes()).hexdigest()
    if item.get("contentMustMatch", False) and len(set(hashes.values())) > 1:
        errors.append(f"shared raw resource differs across platforms: {name}")

shared_text_keys = manifest.get("sharedTextKeys", [])
if not isinstance(shared_text_keys, list) or len(shared_text_keys) != len(set(shared_text_keys)):
    errors.append("sharedTextKeys must be an array without duplicates")
    shared_text_keys = []

def android_string_keys(path: Path) -> set[str]:
    return {
        node.attrib.get("name", "")
        for node in ET.parse(path).getroot().findall("string")
    }

def harmony_string_keys(path: Path) -> set[str]:
    data = json.loads(path.read_text(encoding="utf-8"))
    return {item.get("name", "") for item in data.get("string", [])}

ios_catalog = json.loads(
    (root / "iosApp/iosApp/Resources/Localizable.xcstrings").read_text(encoding="utf-8")
).get("strings", {})
text_sets = {
    "Android default": android_string_keys(root / "androidApp/src/main/res/values/strings.xml"),
    "Android English": android_string_keys(root / "androidApp/src/main/res/values-en/strings.xml"),
    "iOS": set(ios_catalog),
    "HarmonyOS default": harmony_string_keys(root / "harmonyApp/entry/src/main/resources/base/element/string.json"),
    "HarmonyOS English": harmony_string_keys(root / "harmonyApp/entry/src/main/resources/en_US/element/string.json"),
}
for key in shared_text_keys:
    for platform, available in text_sets.items():
        if key not in available:
            errors.append(f"{platform} is missing shared text key: {key}")
    localizations = ios_catalog.get(key, {}).get("localizations", {})
    for locale in ("zh-Hans", "en"):
        value = localizations.get(locale, {}).get("stringUnit", {}).get("value")
        if not isinstance(value, str) or not value.strip():
            errors.append(f"iOS shared text key {key} is missing {locale} value")

han_literal = re.compile(r'["\'][^"\'\n]*[\u4e00-\u9fff][^"\'\n]*["\']')
debt_sources = {
    "androidHanLiterals": (root / "androidApp/src/main/java", {".kt"}, han_literal),
    "iosHanLiterals": (root / "iosApp/iosApp", {".swift"}, han_literal),
    "harmonyHanLiterals": (root / "harmonyApp/entry/src/main/ets", {".ets"}, han_literal),
    "commonHanLiterals": (root / "common/src/commonMain/kotlin", {".kt"}, han_literal),
    "androidDirectColors": (root / "androidApp/src/main/java", {".kt"}, re.compile(r'Color\((?:0x[0-9A-Fa-f]+)|Color\.(?:Black|White|Red|Gray|Transparent)')),
    "iosDirectColors": (root / "iosApp/iosApp", {".swift"}, re.compile(r'Color\(red:|Color\.(?:black|white|red|gray|clear)')),
    "harmonyDirectColors": (root / "harmonyApp/entry/src/main/ets", {".ets"}, re.compile(r'#[0-9A-Fa-f]{6,8}')),
}

debt_exclusions = manifest.get("debtExclusions", {})

def count_matches(name: str, directory: Path, suffixes: set[str], pattern: re.Pattern[str]) -> int:
    total = 0
    excluded = set(debt_exclusions.get(name, []))
    for path in directory.rglob("*"):
        if path.is_file() and path.suffix in suffixes:
            relative = path.relative_to(root).as_posix()
            if relative in excluded:
                continue
            total += len(pattern.findall(path.read_text(encoding="utf-8")))
    return total

ceilings = manifest.get("debtCeilings", {})
actual_debt: dict[str, int] = {}
for name, (directory, suffixes, pattern) in debt_sources.items():
    actual = count_matches(name, directory, suffixes, pattern)
    actual_debt[name] = actual
    ceiling = ceilings.get(name)
    if not isinstance(ceiling, int) or ceiling < 0:
        errors.append(f"debtCeilings.{name} must be a non-negative integer")
    elif actual > ceiling:
        errors.append(f"resource debt increased: {name} is {actual}, ceiling is {ceiling}")

expected_debug_exclusion = "harmonyApp/entry/src/main/ets/pages/DebugStatePage.ets"
if debt_exclusions.get("harmonyHanLiterals") != [expected_debug_exclusion]:
    errors.append("HarmonyOS debug text exclusion must contain only DebugStatePage.ets")

expected_color_token_exclusions = {
    "androidDirectColors": [
        "androidApp/src/main/java/com/example/demo/ui/resources/AppColors.kt",
        "androidApp/src/main/java/com/example/demo/ui/theme/Color.kt",
        "androidApp/src/main/java/com/example/demo/ui/theme/Theme.kt",
    ],
    "iosDirectColors": [
        "iosApp/iosApp/Login/Components/AuthColors.swift",
        "iosApp/iosApp/Resources/AppResources.swift",
    ],
    "harmonyDirectColors": [
        "harmonyApp/entry/src/main/ets/pages/DebugStatePage.ets",
        "harmonyApp/entry/src/main/ets/login/components/AuthColors.ets",
        "harmonyApp/entry/src/main/ets/resources/AppResources.ets",
    ],
}
for debt_name, expected in expected_color_token_exclusions.items():
    if debt_exclusions.get(debt_name) != expected:
        errors.append(f"{debt_name} exclusions must contain only approved token definition files")

for source_dir in ("login_register_resources", "health_dashboard_resources"):
    if not (root / source_dir).is_dir():
        errors.append(f"missing protected design source directory: {source_dir}")

if errors:
    for error in errors:
        print(f"FAIL: {error}")
    sys.exit(1)

print(
    "Resource maintainability check passed: "
    f"{len(shared_images)} shared images, {len(shared_raw)} shared raw files, "
    f"{len(shared_text_keys)} shared text keys; "
    + ", ".join(f"{key}={value}" for key, value in actual_debt.items())
)
PY
