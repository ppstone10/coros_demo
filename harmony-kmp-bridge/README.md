# 鸿蒙 KMP 桥接层

这是一个面向 HarmonyOS 的独立 KuiklyBase-Kotlin + KNOI 桥接构建模块。

- 它会编译 `../common/src/commonMain/kotlin` 中可复用的登录业务源码。
- 鸿蒙界面仍使用原生 ArkTS/ArkUI；登录业务通过 `HarmonyLoginService` 与 `LoginFacade` 调用。
- 使用 KuiklyBase Kotlin `2.0.21-KBA-003`。
- 将 `ohosArm64` 构建为共享库，`baseName = "kn"`，产物为 `libkn.so`。
- KNOI 会将 ArkTS API 生成到 `build/ts-api`，随后复制到 `harmonyApp/entry/src/main/ets/knoi`。
- 认证 Store 不会直接持久化到原生库的文件系统；ArkTS 侧的 `StorePersister` 通过 HarmonyOS Preferences 保存和恢复 JSON 快照。

执行构建：

```bash
./gradlew ohosArm64Binaries
```

预期复制出的产物：

```text
harmonyApp/entry/src/main/libs/arm64-v8a/libkn.so
harmonyApp/entry/libs/arm64-v8a/libkn.so
harmonyApp/entry/src/main/ets/knoi/provider.ets
```

## 工具链约束

- bridge 使用 KuiklyBase Kotlin `2.0.21-KBA-003` 和自己的 Gradle wrapper，不加入根 `settings.gradle.kts`。
- 只编译 `commonMain` 中可用于该工具链的纯 Kotlin 业务；不得引入 Compose、ArkUI 或 HarmonyOS SDK 类型。
- UI 始终由 `harmonyApp` 的 ArkUI 实现，不采用 KuiklyUI。
- shared 业务或 service 变化后必须重新运行 `ohosArm64Binaries`，不能继续使用旧 `libkn.so` 或 `provider.ets`。

## 验收条件

1. `ohosArm64Binaries` 成功并更新两处 `libkn.so` 与生成的 `provider.ets`。
2. HarmonyOS HAP 包含 `libkn.so`、`libknoi.so` 和 `libc++_shared.so`。
3. ArkTS 只通过生成 API/adapter 调用共享业务，没有注册、登录或健康规则 fallback。
4. DevEco/Hvigor 构建通过；缺少 native 产物时前置检查明确失败。
5. bridge 工具链升级必须按 Kotlin、KSP、KNOI 兼容矩阵整体评估，不能只为消除警告单独升级其中一项。
