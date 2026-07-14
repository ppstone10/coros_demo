# KuiklyBase-Kotlin + KNOI experiment

目标：验证 HarmonyOS ArkTS + ArkUI 原生 UI 通过 KNOI 调用 Kotlin business service。当前 bridge 会编译 `common/src/commonMain/kotlin` 中的登录业务源码，并通过 `HarmonyLoginService` 暴露完整的注册、登录、验证码、Session 和资料流程。

## 非目标

- 不迁移到 KuiklyUI。
- 不把 ArkUI、HarmonyOS SDK、KNOI runtime 对象放入 `commonMain`。
- 不把实验 Gradle/Hvigor 配置接入根 `settings.gradle.kts`。

## 当前 POC 接入点

- Kotlin bridge：`harmony-kmp-bridge/src/ohosArm64Main/kotlin/com/example/demo/harmony/bridge/HarmonyLoginService.kt`
- KNOI generated API：`harmonyApp/entry/src/main/ets/knoi/provider.ets`
- ArkTS adapter：`harmonyApp/entry/src/main/ets/login/KnoiLoginAdapter.ets`
- Native library：`harmonyApp/entry/src/main/libs/arm64-v8a/libkn.so` 和 `harmonyApp/entry/libs/arm64-v8a/libkn.so`

## 当前接入结论

1. bridge 使用 KuiklyBase Kotlin `2.0.21-KBA-003`，生成 `libkn.so` 和 `provider.ets`。
2. ArkTS 通过 `KnoiLoginAdapter` 调用 `HarmonyLoginService`，不再维护独立的 ArkTS 注册、登录或验证码规则。
3. Store 持久化由 ArkTS Preferences 保存 bridge 导出的 JSON 快照；恢复后重新创建 facade 并恢复 Session。
4. 当前仍需在 DevEco/Hvigor 环境中验证具体设备和打包产物；缺少 `libkn.so` 时不应将鸿蒙端视为已完成构建。

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
