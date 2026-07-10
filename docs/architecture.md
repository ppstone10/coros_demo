# 架构说明

本项目采用 KMP + 原生 UI：

- Android：Kotlin + Jetpack Compose。
- iOS：Swift + SwiftUI。
- HarmonyOS：ArkTS + ArkUI 原生开发。
- 共享模块：`common` KMP 模块共享平台无关业务逻辑；Android/iOS 直接接入，HarmonyOS 通过 KuiklyBase-Kotlin + KNOI bridge 接入。

## 模块职责

| 目录 | 职责 |
| --- | --- |
| `common` | KMP 共享模块。只放平台无关业务逻辑、DTO、状态机、UseCase、Repository 接口、Mapper、Result、网络/存储抽象。 |
| `androidApp` | Android 原生 UI。Compose 页面、Activity、Android 平台服务实现。 |
| `iosApp` | iOS 原生 UI。SwiftUI 页面、ViewModel、KMP 框架适配器。 |
| `harmonyApp` | HarmonyOS 原生 ArkTS + ArkUI。UI 不走 KuiklyUI；登录业务通过 `LoginLogicAdapter` 接 KNOI native bridge，不保留 ArkTS 登录业务 fallback。 |
| `contract` | 后端 API 契约与埋点事件定义。当前为轻量骨架，数据模型由 `common` 定义。 |
| `docs` | 架构、边界、集成和工作流说明。 |
| `tools` | 构建、代码生成和验证脚本。 |
| `experimental/harmony-kmp` | HarmonyOS 复用 KMP 能力的实验区，不接入主线构建。 |

## 登录示例流

1. UI 层收集用户名和密码。
2. ViewModel 将用户操作映射为 `LoginAction`。
3. 状态容器或门面类根据动作更新 `LoginState`。
4. `LoginUseCase` 调用 `AuthRepository`。
5. 结果转换为新的 `LoginState` 和一次性 `LoginEffect`。

Android/iOS 使用 `common` 中的登录逻辑。HarmonyOS 保留 ArkUI 原生页面，通过独立 `harmony-kmp-bridge` 生成的 `libkn.so` 调用 `HarmonyLoginService`；该 service 编译并复用 `common/src/commonMain` 的 `LoginFacade`、`LoginStore` 与 mock auth 业务逻辑。缺少 KNOI 生成模块时，鸿蒙构建或运行应直接失败。

## 平台接入原则

- Android 是 Kotlin 侧调用方，可以直接使用 `common` 的 `LoginStore`、`LoginRules`、`LoginAction` 和 `LoginEffect`；不要为了形式统一强制绕一层 facade。
- iOS 和 HarmonyOS 是跨语言调用方，优先通过 `LoginFacade`、KNOI service 或平台 adapter 暴露 primitive-friendly API。
- 平台 ViewModel 只做原生 UI 状态、导航、提示和平台系统能力适配；登录规则、状态迁移、mock auth 流程继续放在 `common`。
- 当前不引入 DI 框架。mock 数据和本地持久化场景使用集中构造点即可；只有真实网络层、多环境数据源或复杂替换策略出现后再评估 DI。

## HarmonyOS 维护约束

- `HarmonyLoginService` 只做 KNOI API 暴露和 `LoginFacade` 调用；JSON snapshot 编解码集中在 `HarmonyLoginJson`。
- `KnoiLoginAdapter.ets` 只做 bridge 调用、状态/effect 映射和持久化触发，不复写登录、注册、验证码、密码或 profile 业务规则。
- 成功改变 Kotlin store 的 HarmonyOS 调用必须触发 `saveStoreSnapshot()`；保存前和恢复后必须通过 bridge round-trip 校验。
- `pages/LoginPage` 是历史对照页，不作为主流程入口；`DebugStatePage` 只用于开发期诊断，不在首屏或正式导航中暴露。
