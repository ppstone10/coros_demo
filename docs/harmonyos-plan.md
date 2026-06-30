# HarmonyOS 计划

HarmonyOS 第一阶段采用 ArkTS + ArkUI 原生开发，不直接依赖 KMP `common`。

## 第一阶段

目标是主线稳定交付：

- 使用 `harmonyApp` 维护原生 ArkTS 工程骨架。
- 登录示例保持 DTO、状态、动作、一次性效果、错误码和流程与 `common` 对齐。
- 不在根目录的 `settings.gradle.kts` 中加入 HarmonyOS KMP 编译目标。
- 不引入 `harmonyTarget`、`harmonyArm64` 等非 Kotlin 官方标准编译目标。

## 对齐方式

- 业务协议放在 `contract`。
- Kotlin、Swift、ArkTS 的 DTO 命名和字段保持一致。
- 状态迁移流程以 `common` 登录状态容器为参考。
- 错误码与埋点事件以 `contract` 为准。

## 后续方向

可在 `experimental/harmony-kmp` 中评估：

- Kotlin/JS：将纯业务逻辑编译为 JS，由 ArkTS 调用。
- Kotlin/Native + NAPI：通过原生模块暴露给 ArkTS。
- 第三方或内部框架：如 Kuikly、社区 Kotlin-OHOS、公司内部 Harmony KMP 编译目标。

任何实验失败都不能阻塞 Android/iOS 主线构建。
