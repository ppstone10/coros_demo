# experimental/harmony-kmp

这里是 HarmonyOS 复用 KMP 能力的预留实验区。

规则：

- 不要在根目录 `settings.gradle.kts` 中引入这个目录。
- 不要让 Android/iOS 主线交付依赖这个目录。
- KuiklyBase-Kotlin + KNOI、Kotlin/JS、Kotlin/Native + NAPI、第三方 HarmonyOS KMP 编译目标都先在这里验证，再讨论是否进入主线。
- 本项目 HarmonyOS 方向保留 ArkTS + ArkUI 原生 UI，不在这里尝试 KuiklyUI 共享 UI。
- KNOI POC 入口改为独立 `harmony-kmp-bridge`，生成 `libkn.so` 和 `harmonyApp/entry/src/main/ets/knoi/provider.ets`；鸿蒙侧不再直接 import `libshared_login_bridge.so`。
- 每次实验结果都记录到 `docs/harmonyos-kmp-experiment.md`。
