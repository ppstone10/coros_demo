# demo

Android + iOS + HarmonyOS 三端跨平台项目骨架，技术路线是 KMP + 原生 UI。

## 项目目标

- Android 和 iOS 通过 KMP `common` 共享平台无关业务逻辑。
- Android 使用 Kotlin + Jetpack Compose。
- iOS 使用 Swift + SwiftUI。
- HarmonyOS 使用 ArkTS + ArkUI 原生开发。
- HarmonyOS 采用 ArkUI 原生 UI，通过 KuiklyBase-Kotlin + KNOI 调用 KMP `common` 业务逻辑，不再保留 ArkTS 登录业务复写路径。

## 目录结构

```text
demo/
├── common/       # KMP 共享模块，Android/iOS 共享业务逻辑
├── androidApp/   # Android Compose 原生 UI
├── iosApp/       # iOS SwiftUI 原生 UI 示例
├── harmonyApp/   # HarmonyOS ArkTS + ArkUI 原生工程骨架
├── contract/     # OpenAPI、JSON Schema、错误码、埋点事件
├── docs/         # 架构与接入文档
├── tools/        # 构建和代码生成脚本
├── experimental/ # HarmonyOS KMP 实验区，不接入主线构建
├── settings.gradle.kts
└── build.gradle.kts
```

## 最小登录示例

- `common`：`LoginState`、`LoginAction`、`LoginEffect`、`LoginUseCase`、`AuthRepository`、`FakeAuthRepository`、`LoginStore`、`LoginFacade`。
- `androidApp`：`LoginScreen` 和 `LoginViewModel` 调用共享模块。
- `iosApp`：`LoginView`、`LoginViewModel`、`SharedLoginAdapter`，通过 `Shared.framework` 调用 KMP `LoginFacade`。
- `harmonyApp`：`LoginPage.ets` 保持 ArkUI 原生 UI，`LoginViewModel.ets` 通过 `LoginLogicAdapter` 调用 KNOI POC bridge，再进入独立 `harmony-kmp-bridge` 生成的 `HarmonyLoginService`。

测试账号：

- 用户名：`13107012029`
- 密码：`123456`

手机号注册验证码：`1234`

## 日常开发

检查共享模块：

```bash
./gradlew :common:check
```

构建 Android：

```bash
./gradlew :androidApp:assembleDebug
```

生成 iOS 框架：

```bash
./tools/build-shared-xcframework.sh
```

HarmonyOS 用 DevEco Studio 打开 `harmonyApp`。当前不从 Gradle 主线构建 HarmonyOS。

## 关键限制

- `common/src/commonMain` 不允许出现 Android、iOS、HarmonyOS 平台 API 或 UI 框架。
- 主线不添加 HarmonyOS KMP 编译目标，不默认使用 `harmonyTarget`、`harmonyArm64` 等非 Kotlin 官方标准编译目标。
- HarmonyOS 不采用 KuiklyUI 共享 UI 路线，UI 继续由 ArkTS + ArkUI 原生维护。
- HarmonyOS shared 业务接入通过独立 `harmony-kmp-bridge` 的 KuiklyBase-Kotlin + KNOI bridge；`harmonyApp` 需要 KNOI 生成的 `libkn.so`，不能回退到旧的 ArkTS direct native import。

## 后续路线图

1. 从 `contract` 生成 Kotlin、Swift、ArkTS DTO。
2. 为真实 Auth API 增加平台网络实现和依赖注入。
3. 完善 Android/iOS/HarmonyOS 登录页的导航和错误态。
4. 在 `harmony-kmp-bridge` 中补齐 KuiklyBase-Kotlin + KNOI 构建验证，并产出 `libkn.so`。
5. 建立持续集成：`common:check`、Android 打包、iOS 框架生成、HarmonyOS Hvigor 验证分开执行。

更多说明见 `docs/`。
