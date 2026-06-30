# 架构说明

本项目采用 KMP + 原生 UI：

- Android：Kotlin + Jetpack Compose。
- iOS：Swift + SwiftUI。
- HarmonyOS：ArkTS + ArkUI 原生开发。
- 共享模块：`common` KMP 模块共享 Android/iOS 业务逻辑。

## 模块职责

| 目录 | 职责 |
| --- | --- |
| `common` | KMP 共享模块。只放平台无关业务逻辑、DTO、状态机、UseCase、Repository 接口、Mapper、Result、网络/存储抽象。 |
| `androidApp` | Android 原生 UI。Compose 页面、Activity、Android 平台服务实现。 |
| `iosApp` | iOS 原生 UI。SwiftUI 页面、ViewModel、KMP 框架适配器。 |
| `harmonyApp` | HarmonyOS 原生 ArkTS + ArkUI。第一阶段不依赖 KMP。 |
| `contract` | OpenAPI、JSON Schema、错误码、埋点事件。 |
| `docs` | 架构、边界、集成和工作流说明。 |
| `tools` | 构建、代码生成和验证脚本。 |
| `experimental/harmony-kmp` | HarmonyOS 复用 KMP 能力的实验区，不接入主线构建。 |

## 登录示例流

1. UI 层收集用户名和密码。
2. ViewModel 将用户操作映射为 `LoginAction`。
3. 状态容器或门面类根据动作更新 `LoginState`。
4. `LoginUseCase` 调用 `AuthRepository`。
5. 结果转换为新的 `LoginState` 和一次性 `LoginEffect`。

Android/iOS 使用 `common` 中的登录逻辑。HarmonyOS 当前用 ArkTS 复刻同一套状态和流程，保持契约对齐。
