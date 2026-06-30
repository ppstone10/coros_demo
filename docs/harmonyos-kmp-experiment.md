# HarmonyOS KMP 实验路线

主线不直接依赖 HarmonyOS KMP 编译目标。所有实验放在 `experimental/harmony-kmp`，并且不能阻塞 Android/iOS 共享模块构建。

## 实验目标

验证是否能把 `commonMain` 中的纯业务能力复用到 HarmonyOS，同时保持 ArkTS + ArkUI 原生 UI。

## 方案一：Kotlin/JS

思路：将部分纯业务逻辑编译为 JS，再由 ArkTS 调用。

验证项：

1. 当前 Kotlin 版本是否能稳定编译 JS 产物。
2. ArkTS 是否能加载并调用 JS 入口。
3. DTO、状态模型和错误码是否能无损传递。
4. commonTest 或等价测试是否能复用。
5. `kotlinx.coroutines`、`serialization`、`datetime`、`ktor` 等依赖在 JS 侧是否满足需求。
6. CI 是否能稳定构建 JS 产物。

## 方案二：Kotlin/Native + NAPI

思路：将 Kotlin/Native 产物编译为 HarmonyOS 可加载原生模块，通过 NAPI 暴露给 ArkTS。

验证项：

1. 当前 Kotlin 版本是否能生成目标 native 产物。
2. 当前 HarmonyOS SDK、DevEco Studio、Hvigor 版本是否能构建原生模块。
3. 是否能产出 HarmonyOS 可加载的 `.so`、HAR 或 HAP 相关产物。
4. ArkTS 是否能通过 NAPI 调用共享逻辑。
5. 内存管理、线程模型、异常传播是否可控。
6. commonTest 或等价测试是否能复用。
7. CI 是否能稳定构建。

## 方案三：第三方或内部框架

候选：

- Kuikly。
- 社区 Kotlin-OHOS。
- 公司内部 Harmony KMP 编译目标、编译器或框架。

验证项：

1. 是否兼容当前 Kotlin 版本。
2. 是否兼容当前 HarmonyOS SDK、DevEco Studio、Hvigor。
3. 是否能生成 HarmonyOS 可加载的 `.so`、JS、HAR 或 HAP 产物。
4. ArkTS 是否能通过 NAPI、JS 桥或框架 API 调用共享逻辑。
5. `kotlinx.coroutines`、`serialization`、`datetime`、`ktor` 等依赖是否支持该编译目标。
6. commonTest 或等价测试是否能复用。
7. CI 是否稳定。

## 出口标准

实验只有满足以下条件，才允许提议进入主线设计：

- 不破坏 Android/iOS KMP 共享模块构建。
- 能在本地和 CI 稳定产出 HarmonyOS 可加载产物。
- ArkTS 调用路径清晰，有错误处理和版本兼容策略。
- 对依赖生态、调试体验、包体积和性能有记录。
- 有失败回退方案。

实验失败时，只保留记录，不改主线。
