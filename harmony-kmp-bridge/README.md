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
