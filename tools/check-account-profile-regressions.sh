#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

root = Path.cwd()
files = {
    "android": root / "androidApp/src/main/kotlin/com/example/demo/auth/screens/profile/ProfileCompletionScreen.kt",
    "ios_profile": root / "iosApp/iosApp/Auth/Views/ProfileCompletionView.swift",
    "ios_health": root / "iosApp/iosApp/Health/Editor/NormalDataEditor.swift",
    "harmony": root / "harmonyApp/entry/src/main/ets/pages/ProfileCompletionPage.ets",
    "harmony_avatar_image": root / "harmonyApp/entry/src/main/ets/home/account/AvatarImage.ets",
}
texts = {name: path.read_text() for name, path in files.items()}
errors = []

required = {
    "android": ["profile_email", "clearFocus(force = true)", "LoginRules.profileDefaults"],
    "ios_profile": ["profile_email", "initialProfileDraft()"],
    "ios_health": ["values[field.id] ?? field.value"],
    "harmony": ["profile_email", "profileEmail", "getFocusController().clearFocus()", "profileDefaultUsername"],
    # MSRV-015：头像换后即时刷新（@Watch + 内容寻址 base64，路径恒定会被 ArkUI 缓存）且上传携带设备标识
    "harmony_avatar_image": [
        "@Watch('onAvatarInputChanged')",
        "data:image/jpeg;base64,",
        "'X-Device-Id'",
        # 信息修改页"选图后未保存"的本地预览（内存态，最高优先），"我"页不传该 prop
        "pendingAvatarBase64",
    ],
    # MSRV-015：信息修改页选图仅写入内存 pendingAvatarBase64 做本页预览，不写共享缓存文件；
    # 保存时才 uploadAvatarBytesToServer 提交（未保存返回时内存态销毁，"我"页保持旧头像）
    "harmony": [
        "profile_email",
        "profileEmail",
        "getFocusController().clearFocus()",
        "profileDefaultUsername",
        "this.pendingAvatarBase64 = avatarBytesToBase64(bytes)",
        "uploadAvatarBytesToServer(bytes, userId)",
        "this.pendingAvatarBytes = new Uint8Array(0)",
    ],
}
for name, needles in required.items():
    for needle in needles:
        if needle not in texts[name]:
            errors.append(f"{name} missing {needle!r}")

if errors:
    raise SystemExit("FAIL:\n- " + "\n- ".join(errors))
print("PASS: account-derived profile defaults, focus dismissal, avatar immediate-refresh, and iOS form fallback are present.")
PY
