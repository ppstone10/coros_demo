# iOS 接入

iOS 使用 SwiftUI 原生 UI，通过 KMP 产物接入共享业务逻辑。

## 当前示例

- `iosApp/iosApp/Login/LoginView.swift`：SwiftUI 登录页。
- `iosApp/iosApp/Login/LoginViewModel.swift`：iOS ViewModel。
- `iosApp/iosApp/Login/SharedLoginAdapter.swift`：桥接 KMP `LoginFacade`。

`SharedLoginAdapter` 使用 `#if canImport(Shared)`：

- 能导入 `Shared.framework` 时，调用 KMP `LoginFacade`。
- 尚未接入框架时，使用 Swift 本地兜底实现，方便 UI 先运行。

## 构建 KMP 框架

从仓库根目录执行：

```bash
./tools/build-shared-xcframework.sh
```

产物通常位于 `common/build/XCFrameworks`。把 `Shared.xcframework` 加入 Xcode 编译目标，并确保框架名称为 `Shared`。

## 推荐接入原则

- SwiftUI 视图不直接依赖复杂 KMP 类型，统一经过适配器。
- 对 Swift 不友好的 sealed class、泛型、Flow 等类型，优先在 KMP 侧提供对 Swift 友好的门面类。
- iOS 生命周期、权限、Keychain、推送、埋点 SDK 调用只放在 iOS 层。
- `commonMain` 不写任何 SwiftUI 或 Apple SDK 代码。
