# HarmonyOS 计划

HarmonyOS 当前采用 ArkTS + ArkUI 原生 UI，并通过独立 `harmony-kmp-bridge` 生成的 KNOI native bridge 调用 KMP `common` 业务逻辑。根 KMP 工程仍不直接声明 HarmonyOS target，避免 Android/iOS 主线构建被非官方工具链耦合。

## 当前阶段

目标是主线稳定交付：

- 使用 `harmonyApp` 维护原生 ArkTS 工程骨架。
- 登录 UI 保持 ArkUI 原生；登录规则、状态迁移、mock auth 流程通过 KNOI 复用 `common`。
- ArkTS 层只保留 UI 状态镜像、导航、提示、系统能力和 bridge adapter，不再保留登录业务 fallback。
- 不在根目录的 `settings.gradle.kts` 中加入 HarmonyOS KMP 编译目标。
- 不引入 `harmonyTarget`、`harmonyArm64` 等非 Kotlin 官方标准编译目标。

## 对齐方式

- 业务协议放在 `contract`。
- Kotlin、Swift、ArkTS 的 DTO 命名和字段保持一致；新增字段优先从 `common`/`contract` 推导。
- 状态迁移流程以 `common` 登录状态容器为准。
- HarmonyOS bridge 必须暴露 primitive-friendly API 或稳定 JSON snapshot，并为新增字段补映射验证。
- 错误码与埋点事件以 `contract` 为准。

## 后续方向

可在 `experimental/harmony-kmp` 中继续评估替代路线：

- Kotlin/JS：将纯业务逻辑编译为 JS，由 ArkTS 调用。
- Kotlin/Native + NAPI：通过原生模块暴露给 ArkTS。
- 第三方或内部框架：如 Kuikly、社区 Kotlin-OHOS、公司内部 Harmony KMP 编译目标。

任何实验失败都不能阻塞 Android/iOS 主线构建。
