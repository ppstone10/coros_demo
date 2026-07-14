# iOS 接入

iOS 使用 SwiftUI 原生 UI，通过 KMP 产物接入共享业务逻辑。

## 当前接入

- `iosApp/iosApp/Login/LoginView.swift`：SwiftUI 登录页。
- `iosApp/iosApp/Login/LoginViewModel.swift`：iOS ViewModel。
- `iosApp/iosApp/Login/SharedLoginAdapter.swift`：桥接 KMP `LoginFacade`。

`SharedLoginAdapter` 强制 `import Shared`，不再提供 Swift 本地兜底实现。iOS 登录、注册、验证码和登出流程必须通过 KMP `LoginFacade` 调用 `common` 业务逻辑。

认证持久化仍由 common 的 `JsonAuthStoreDataSource` 与 `MockAuthStoreJson` 负责；`SharedLoginAdapter` 只向它注入 `UserDefaults.standard` 的 JSON 字符串读写回调。SwiftUI 页面不直接读写账号库、Session 或验证码快照。

## Xcode 构建方式

`iosApp.xcodeproj` 已配置 `Build Shared KMP Framework` Run Script phase：

```bash
cd "$SRCROOT/.."
./gradlew :common:embedAndSignAppleFrameworkForXcode
```

这个 phase 在 Swift 编译前运行，并根据 Xcode 当前 SDK/架构生成对应的 `Shared.framework`。工程的 `FRAMEWORK_SEARCH_PATHS` 已指向 `common/build/bin/.../debugFramework` 和 `releaseFramework` 输出目录。

如需独立生成 XCFramework，仍可从仓库根目录执行：

```bash
./tools/build-shared-xcframework.sh
```

## 推荐接入原则

- SwiftUI 视图不直接依赖复杂 KMP 类型，统一经过适配器。
- 对 Swift 不友好的 sealed class、泛型、Flow 等类型，优先在 KMP 侧提供对 Swift 友好的门面类。
- iOS 生命周期、权限、Keychain、推送、埋点 SDK 调用只放在 iOS 层。
- `commonMain` 不写任何 SwiftUI 或 Apple SDK 代码。
