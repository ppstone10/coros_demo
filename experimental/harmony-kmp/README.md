# experimental/harmony-kmp

这里是 HarmonyOS 复用 KMP 能力的预留实验区。

规则：

- 不要在根目录 `settings.gradle.kts` 中引入这个目录。
- 不要让 Android/iOS 主线交付依赖这个目录。
- Kotlin/JS、Kotlin/Native + NAPI、第三方 HarmonyOS KMP 编译目标都先在这里验证，再讨论是否进入主线。
- 每次实验结果都记录到 `docs/harmonyos-kmp-experiment.md`。
