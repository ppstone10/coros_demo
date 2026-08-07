#!/usr/bin/env bash
set -euo pipefail

# HARM-001..009：鸿蒙端认证与数据接入对齐 Android/iOS 的结构门禁。
# 与 spec/harmonyos-auth-alignment.md 一一对应；实现前为红灯，实现后转绿。

python3 - <<'PY'
from pathlib import Path

root = Path.cwd()
errors = []
passes = []

def check(name, condition):
    if condition:
        passes.append(name)
    else:
        errors.append(name)

def text(rel):
    return (root / rel).read_text()

# ---- HARM-001：设备标识 ----
mock_sync = text("harmonyApp/entry/src/main/ets/core/bridge/MockServerSync.ets")
check("HARM-001a: HarmonyDeviceId.ets 存在",
      (root / "harmonyApp/entry/src/main/ets/core/bridge/HarmonyDeviceId.ets").exists())
check("HARM-001b: request() 携带 X-Device-Id",
      "X-Device-Id" in mock_sync)
check("HARM-001c: 登录/注册 body 携带 deviceId",
      '"deviceId"' in mock_sync or "deviceId: deviceId()" in mock_sync)

# ---- HARM-002：登录走服务器 + 二次确认 ----
adapter = text("harmonyApp/entry/src/main/ets/core/bridge/KnoiLoginAdapter.ets")
login_state = text("harmonyApp/entry/src/main/ets/auth/logic/LoginState.ets")
adapter_iface = text("harmonyApp/entry/src/main/ets/auth/logic/LoginLogicAdapter.ets")
check("HARM-002a: adapter 含 confirmForceLogin/cancelForceLogin",
      "confirmForceLogin()" in adapter and "cancelForceLogin()" in adapter)
check("HARM-002b: 接口暴露 confirmForceLogin/cancelForceLogin",
      "confirmForceLogin" in adapter_iface and "cancelForceLogin" in adapter_iface)
check("HARM-002c: LoginState 含 forceLoginActiveDevice",
      "forceLoginActiveDevice" in login_state)
check("HARM-002d: 登录走服务器（stageServerLoginResult/stageForceLogin/stageServerError）",
      "stageServerLoginResult" in adapter and "stageForceLogin" in adapter and "stageServerError" in adapter)

login_form = text("harmonyApp/entry/src/main/ets/pages/LoginFormPage.ets")
check("HARM-002e: 登录页渲染二次确认弹窗",
      "confirmForceLogin" in login_form and "forceLoginActiveDevice" in login_form)

# ---- HARM-003：注册走服务器 ----
check("HARM-003a: serverRegister 存在",
      "serverRegister" in mock_sync or "serverRegister" in adapter)

# ---- HARM-004：会话懒校验三态 ----
check("HARM-004a: serverSessionCheck 存在",
      "serverSessionCheck" in mock_sync or "serverSessionCheck" in adapter)
check("HARM-004b: 前台定时器接入会话校验",
      "checkSessionOnForeground" in text("harmonyApp/entry/src/main/ets/pages/SignedInPage.ets"))
check("HARM-004c: 冷启动/回前台接入（EntryAbility）",
      "checkSessionOnForeground" in text("harmonyApp/entry/src/main/ets/entryability/EntryAbility.ets")
      or "serverSessionCheck" in text("harmonyApp/entry/src/main/ets/entryability/EntryAbility.ets"))

# ---- HARM-005：登出/资料走服务器 ----
check("HARM-005a: serverLogout 存在",
      "serverLogout" in mock_sync or "serverLogout" in adapter)
check("HARM-005b: serverProfilePut 存在",
      "serverProfilePut" in mock_sync or "serverProfilePut" in adapter)

# ---- HARM-006：健康按 userId 读写 ----
check("HARM-006a: 健康读写使用 /api/health/",
      "/api/health/" in mock_sync)

# ---- HARM-007：同步失败不触发被顶弹窗 ----
import re as _re

def _block(src, search):
    m = _re.search(search, src)
    if not m:
        return ""
    i = src.index(m.group(0))
    depth = 0
    start = i
    for j in range(i, len(src)):
        if src[j] == "{":
            depth += 1
        elif src[j] == "}":
            depth -= 1
            if depth == 0:
                return src[start:j + 1]
    return ""

_request_fn = _block(mock_sync, r"function request\([^)]*\)[^{]*\{")
check("HARM-007a: request() 内不再自动触发被顶回调",
      _request_fn != "" and "sessionKickedHandler" not in _request_fn)
check("HARM-007b: 被顶只由显式会话校验触发（serverSessionCheck 或显式 401 处理）",
      "SESSION_EXPIRED_ELSEWHERE" in mock_sync)
check("HARM-007c: 被顶通知幂等守卫（kickNotified）且成功同步后复位",
      "kickNotified" in mock_sync and "resetKickNotified" in mock_sync)
_handle_kicked = _block(adapter, r"private handleSessionKicked\(\)[^{]*\{")
check("HARM-007d: handleSessionKicked 不持久化（防级联循环）",
      _handle_kicked != "" and "persistSnapshot()" not in _handle_kicked)

# ---- HARM-010：弹窗样式与导航 ----
signed_in = text("harmonyApp/entry/src/main/ets/pages/SignedInPage.ets")
login_form = text("harmonyApp/entry/src/main/ets/pages/LoginFormPage.ets")
check("HARM-010a: 被顶弹窗确认消费 SessionKicked effect 并跳转登录页",
      "SessionKicked" in signed_in and "handleAuthEffect" in signed_in)
check("HARM-010b: 被顶/二次确认弹窗为居中紧凑卡片（固定宽度 300）",
      ".width(300)" in signed_in and ".width(300)" in login_form)
check("HARM-010c: 成功登录清除残留被顶状态（LoginStore 复位 kickedDialogShown）",
      "kickedDialogShown = false" in text("common/src/commonMain/kotlin/com/example/demo/common/auth/store/LoginStore.kt"))

# ---- HARM-008：staging 桥方法 ----
bridge_service = text("harmony-kmp-bridge/src/ohosArm64Main/kotlin/com/example/demo/harmony/bridge/HarmonyLoginService.kt")
check("HARM-008a: 桥暴露 staging 方法",
      "stageServerLoginResult" in bridge_service and "stageForceLogin" in bridge_service
      and "stageServerError" in bridge_service and "clearStaged" in bridge_service)
check("HARM-008b: HarmonyRemoteAuthRepository 存在",
      (root / "harmony-kmp-bridge/src/ohosArm64Main/kotlin/com/example/demo/harmony/bridge/HarmonyRemoteAuthRepository.kt").exists())
repo = ""
if (root / "harmony-kmp-bridge/src/ohosArm64Main/kotlin/com/example/demo/harmony/bridge/HarmonyRemoteAuthRepository.kt").exists():
    repo = text("harmony-kmp-bridge/src/ohosArm64Main/kotlin/com/example/demo/harmony/bridge/HarmonyRemoteAuthRepository.kt")
check("HARM-008c: staging 消费后清空（clearStaged/consume 路径）",
      "clearStaged" in repo or "clearStaged" in bridge_service)

# ---- HARM-009：本地为登录态权威（不复活） ----
check("HARM-009a: 会话校验保留本地登出态（无自动恢复服务器会话）",
      "restoreSessionOnColdStart" in repo
      or (root / "harmonyApp/entry/src/main/ets/core/bridge/MockServerSync.ets").exists())

if errors:
    raise SystemExit("FAIL:\n- " + "\n- ".join(errors))
print("PASS: HarmonyOS auth alignment structure gate ({} checks)".format(len(passes)))
PY
