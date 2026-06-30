# harmonyApp

这是登录示例的 HarmonyOS 原生 ArkTS + ArkUI 应用壳。

当前阶段：

- 不直接依赖 KMP `common`。
- DTO、状态、动作、一次性效果和业务流程与 `common` 保持一致。
- UI、状态管理和模拟登录服务都使用 ArkTS 原生实现。
- Kotlin/JS、Kotlin/Native + NAPI、第三方编译目标只在 `experimental/harmony-kmp` 下评估。

## 在 DevEco Studio 中打开

直接打开这个目录：

```text
harmonyApp
```

不要把仓库根目录作为 DevEco 工程打开。仓库根目录是 Android/KMP 的 Gradle 工作区，`harmonyApp` 才是 HarmonyOS ArkTS 工程。
