# 项目架构

本项目采用 KMP 共享业务层 + 三端原生 UI：Android 使用 Compose，iOS 使用 SwiftUI，HarmonyOS 使用 ArkUI。

## 实现目录职责

| 目录 | 职责 |
|------|------|
| `common/` | 平台无关模型、规则、UseCase、Repository 抽象、本地 mock、Proto 镜像、状态容器和共享测试 |
| `androidApp/` | Compose UI、Android ViewModel、导航、生命周期和 Android 存储适配 |
| `iosApp/` | SwiftUI、iOS ViewModel、导航、UserDefaults 适配和 KMP framework 调用 |
| `harmony-kmp-bridge/` | 独立 KuiklyBase-Kotlin/KNOI 构建，包装共享 facade 并生成 `libkn.so` 与 ArkTS API |
| `harmonyApp/` | ArkTS + ArkUI UI、HarmonyOS 生命周期/Preferences 和 KNOI adapter |

根 Gradle 只包含 `:common` 和 `:androidApp`。`harmony-kmp-bridge` 使用独立 Gradle wrapper 和锁定工具链，避免 HarmonyOS 非标准编译链影响 Android/iOS 主线。

## commonMain 边界

允许放入：

- domain/data model、UI state、Action、Effect、Result 与错误枚举。
- 纯业务 UseCase、Validator、Mapper、状态机和排序/聚合规则。
- Repository、存储、时间、日志等平台能力抽象。
- 受 `.proto` 字段契约约束的本地 mock 与集中编解码。

禁止放入：

- Android `Context`、Activity、Compose 或 Android SDK 类型。
- Swift、SwiftUI、UIKit、Foundation 平台对象。
- ArkTS、ArkUI、HarmonyOS SDK 或 KNOI runtime 类型。
- KuiklyUI 或其他共享 UI 实现。

需要平台能力时，先在共享层定义最小接口，再由对应平台注入实现。

## 调用关系

```text
Android Compose ───────────────┐
                              ├─ common：Rules / UseCase / Store / Repository
iOS SwiftUI → LoginFacade ────┤
                              │
HarmonyOS ArkUI               │
  → KnoiLoginAdapter          │
  → HarmonyLoginService ──────┘
```

Android 与共享层同为 Kotlin，可直接调用 `LoginStore`、规则和 UseCase。iOS 与 HarmonyOS 跨语言调用时，通过 primitive-friendly facade、service 或稳定 JSON snapshot 限制边界复杂度。

## 数据与持久化

- `.proto` 定义认证、健康 mock 和状态保存的字段契约。
- Kotlin `Mock*` 类是当前手工维护的 Proto 镜像；项目未运行 protoc 生成 Kotlin Message。
- `MockAuthStoreJson` 等集中编解码器负责 protobuf JSON 命名约束，平台只提供字符串读写。
- Android 使用 SharedPreferences，iOS 使用 UserDefaults，HarmonyOS 使用 Preferences；共享业务不依赖平台存储 API。
- 业务 mock 数据读取必须经过认证门禁，UI 不自行拼装登录判断。

详细映射见 [`proto与domain model之间的关系.md`](proto与domain%20model之间的关系.md)。

## 平台维护原则

- ViewModel/adapter 只做 UI 状态、导航、提示、生命周期和平台能力适配，不复制业务规则。
- HarmonyOS `HarmonyLoginService` 只暴露 KNOI API 并调用共享 facade；集中 JSON 映射不散落到 service 方法。
- 改变 HarmonyOS Kotlin Store 的成功操作必须触发 ArkTS 持久化快照保存。
- 缺少 `libkn.so` 或生成的 `provider.ets` 时 HarmonyOS 构建应失败，不能回退到 ArkTS 业务复写。
- 当前不引入 DI 框架；复杂度确实增长后再评估。
