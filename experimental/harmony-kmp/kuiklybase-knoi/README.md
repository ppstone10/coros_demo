# KuiklyBase-Kotlin + KNOI experiment

目标：验证 HarmonyOS ArkTS + ArkUI 原生 UI 是否能通过 KNOI 调用 Kotlin business service。当前先用独立 `harmony-kmp-bridge` POC 跑通 `validateLogin()`，不修改现有 `common`。

## 非目标

- 不迁移到 KuiklyUI。
- 不把 ArkUI、HarmonyOS SDK、KNOI runtime 对象放入 `commonMain`。
- 不把实验 Gradle/Hvigor 配置接入根 `settings.gradle.kts`。

## 当前 POC 接入点

- Kotlin bridge：`harmony-kmp-bridge/src/ohosArm64Main/kotlin/com/example/demo/harmony/bridge/HarmonyLoginService.kt`
- KNOI generated API：`harmonyApp/entry/src/main/ets/knoi/provider.ets`
- ArkTS adapter：`harmonyApp/entry/src/main/ets/login/KnoiLoginAdapter.ets`
- Native library：`harmonyApp/entry/src/main/libs/arm64-v8a/libkn.so` 和 `harmonyApp/entry/libs/arm64-v8a/libkn.so`

## 待验证

1. KuiklyBase-Kotlin/KNOI 插件链路已跑通，桥模块使用 KuiklyBase Kotlin `2.0.21-KBA-003`。
2. KNOI 已导出 `HarmonyLoginService.validateLogin(account, password)`。
3. DevEco/Hvigor 已把 KNOI 生成的 `libkn.so` 打入 `entry` HAP。
4. ArkTS 已调用生成的 `getHarmonyLoginService()`。
5. 下一步再接入 `shared-core` 真实 `LoginValidator`，逐步替换剩余 ArkTS 业务壳。

## 生成与安装

生成 KNOI 产物并验证：

```bash
./tools/build-shared-harmony.sh
```

单独生成 bridge：

```bash
cd harmony-kmp-bridge
./gradlew ohosArm64Binaries
```

脚本会先跑 `:common:check`，再生成 `libkn.so` 与 `provider.ets`，最后用 DevEco/Hvigor 验证 `assembleApp`。
