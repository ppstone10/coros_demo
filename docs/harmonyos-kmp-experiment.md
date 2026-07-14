# HarmonyOS KMP/KNOI 实验路线

主线不直接引入 HarmonyOS KMP 编译目标。工具链、产物和 DevEco/Hvigor 绑定实验放在 `experimental/harmony-kmp`，并且不能阻塞 Android/iOS 共享模块构建。

## 实验目标

验证是否能基于 KuiklyBase-Kotlin + KNOI，把 `commonMain` 中的纯业务能力复用到 HarmonyOS，同时保持 ArkTS + ArkUI 原生 UI。不采用 KuiklyUI 共享 UI 路线。

## 当前落地点

- `harmony-kmp-bridge`：独立 KuiklyBase-Kotlin/KNOI bridge 构建，不接入根 Gradle，并编译 `common/src/commonMain` 中的登录业务源码。
- `harmony-kmp-bridge/src/ohosArm64Main/.../HarmonyLoginService.kt`：KNOI-facing service，包装 `LoginFacade`，暴露登录、注册、验证码、登出、校验和状态快照接口。
- `harmony-kmp-bridge/src/ohosArm64Main/.../HarmonyLoginJson.kt`：集中维护 KNOI State/Effect snapshot JSON 与认证 Store 编解码的转发，避免在 service 中继续堆叠手写解析逻辑。
- `harmonyApp/entry/src/main/ets/knoi/provider.ets`：由 KNOI 生成，包含 `getHarmonyLoginService()`。
- `harmonyApp/entry/src/main/ets/login/KnoiLoginAdapter.ets`：ArkTS 登录状态壳，调用生成的 `getHarmonyLoginService()`，只负责状态/effect 映射，不再维护 ArkTS mock 账号、验证码或登录注册流程。
- `harmonyApp/entry/src/main/ets/login/StorePersister.ets`：负责本地 Store snapshot 持久化；从 ArkTS Preferences 读取或写入字符串，并交由 bridge 的集中编解码路径恢复认证数据。
- `harmonyApp/entry/src/main/ets/entryability/EntryAbility.ets`：显式执行 `setup('libkn.so', false)` 和 `init()`。
- `harmonyApp/entry/src/main/libs/arm64-v8a/libkn.so`：用户约定的 POC 产物落点。
- `harmonyApp/entry/libs/arm64-v8a/libkn.so`：Hvigor 实际打包使用的 POC 产物落点。

## KuiklyBase-Kotlin + KNOI 方案

思路：由独立 `harmony-kmp-bridge` 验证并承载 KuiklyBase-Kotlin/KNOI 插件链路，产出 `libkn.so` 和生成的 ArkTS API。bridge 编译 `common/src/commonMain` 登录业务源码，ArkTS 原生页面只通过 `LoginLogicAdapter` 访问业务，不感知 Kotlin 运行时。

接入顺序：

1. 使用 KuiklyBase-Kotlin `2.0.21-KBA-003`、KNOI plugin `0.0.4`、Gradle `8.5` 建立独立 bridge。
2. 配置 `ohosArm64` 和 `binaries.sharedLib { baseName = "kn" }`，生成 `libkn.so`。
3. 由 KNOI 生成 `provider.ets`，ArkTS 通过 `getHarmonyLoginService()` 调用 `HarmonyLoginService` 的完整登录服务接口。
4. 使用现有 ArkUI 登录流程保持默认账号登录、手机号注册验证码、邮箱注册验证码、退出登录、错误提示。
5. 在 DevEco/Hvigor 中验证 `harmonyApp` 构建和 HAP 打包，确认 HAP 内包含 `libkn.so`、`libknoi.so`、`libc++_shared.so`。

工具链约束：

- KuiklyBase 当前要求 Kotlin `2.0.21-KBA-003`，`harmony-kmp-bridge` 必须继续作为独立工程锁定该工具链，不随根 KMP/Android/iOS 工具链升级。
- KSP 版本警告不作为主线阻塞项；验收以 `ohosArm64Binaries` 成功、`provider.ets` 生成、`libkn.so` 复制到 Harmony 工程两个 ABI 落点、Hvigor `assembleApp` 成功为准。
- 如果 KuiklyBase/KNOI 官方兼容矩阵更新，再评估 Kotlin/KSP/KNOI 版本联动升级，不能只为消除警告单独升级 KSP。
- shared 业务源码或 bridge service 变更后，必须重新运行 `ohosArm64Binaries` 并将新的 `libkn.so` 与 `provider.ets` 复制到 Harmony 工程，避免复用旧 native 产物。

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

- KuiklyBase-Kotlin + KNOI。
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
- 有明确失败策略：缺少 KNOI native module 时鸿蒙构建或启动失败，不能悄悄回退到 ArkTS 业务复写。

实验失败时，只保留记录，不改主线。
