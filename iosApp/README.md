# iosApp

这是登录示例的 iOS SwiftUI 原生应用壳，用于接入 KMP 共享逻辑。

正式接入路径：

1. 从 `common` 构建 KMP 框架。
2. 将 `Shared.xcframework` 或 `Shared.framework` 加入 Xcode 编译目标。
3. SwiftUI 视图和 iOS 平台服务保留在本目录。
4. 通过 `SharedLoginAdapter` 这类轻量适配器调用共享业务逻辑。

本目录会刻意将 iOS UI 代码与 `common/commonMain` 隔离。

## 在 Xcode 中打开

打开：

```text
iosApp/iosApp.xcodeproj
```

不要把仓库根目录作为 Xcode 工程打开。仓库根目录是 Android/KMP 的 Gradle 工作区，`iosApp` 才是 iOS 原生应用壳。
