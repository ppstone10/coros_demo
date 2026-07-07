# KMP 边界

`common/src/commonMain` 是平台无关业务层，只允许稳定的 Kotlin 通用代码。

## 允许放入 commonMain

- DTO：如 `LoginRequestDto`、`UserDto`。
- 状态模型：如 `LoginState`。
- Action/Effect/Result：如 `LoginAction`、`LoginEffect`、`LoginResult`。
- UseCase：纯业务流程。
- Repository 接口：只定义能力，不绑定平台实现。
- Mapper、Validator、纯状态机、错误码映射。
- 网络、存储、日志、加密等抽象接口。

## 禁止放入 commonMain

- Android `Context`、`Activity`、`Fragment`、`ViewModel`。
- Jetpack Compose。
- Swift、SwiftUI、UIKit。
- ArkTS、ArkUI、HarmonyOS SDK。
- 任意平台 SDK 或平台生命周期对象。
- 非 Kotlin 官方标准编译目标的 HarmonyOS 配置。
- KuiklyUI、ArkUI 组件或 KNOI runtime 对象。

## 平台能力接入方式

平台能力只能在平台模块实现：

- Android 实现在 `androidApp` 或 `common/src/androidMain`。
- iOS 实现在 `iosApp` 或 `common/src/iosMain`。
- HarmonyOS UI 实现在 `harmonyApp`，保持 ArkTS + ArkUI 原生。
- HarmonyOS 业务复用通过 KuiklyBase-Kotlin + KNOI 调用 `commonMain` 中的纯 Kotlin bridge；bridge 只能暴露 primitive-friendly DTO 和方法，不能把 HarmonyOS SDK 类型带入 `commonMain`。

需要跨平台共享时，先在 `commonMain` 定义接口，再由平台层注入实现。
