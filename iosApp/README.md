# iosApp

iOS 使用 SwiftUI 原生 UI，并通过 KMP `Shared.framework` 调用 `common` 共享业务。

## 当前接入

- SwiftUI 页面、iOS ViewModel、导航和平台服务保留在本目录。
- `SharedLoginAdapter` 强制 `import Shared`，通过 `LoginFacade` 调用注册、登录、资料、会话和健康业务，不提供 Swift 业务 fallback。
- 认证与健康 JSON 编解码仍由 common 集中处理；adapter 只注入 `UserDefaults.standard` 字符串读写。
- 图片使用 `iosApp/Assets.xcassets`，视频、Lottie JSON 与资源语义入口位于 `iosApp/Resources`。

## 构建

用 Xcode 打开：

```text
iosApp/iosApp.xcodeproj
```

不要用 Xcode 打开仓库根目录。Xcode target 的 `Build Shared KMP Framework` phase 会在 Swift 编译前执行：

```bash
cd "$SRCROOT/.."
./gradlew :common:embedAndSignAppleFrameworkForXcode
```

工程的 framework 搜索路径覆盖模拟器与真机的 debug/release 输出；`ENABLE_USER_SCRIPT_SANDBOXING` 必须保持为 `NO`，否则 Gradle Run Script 会被拦截。

需要独立 XCFramework 时，从仓库根目录执行：

```bash
./tools/build-shared-xcframework.sh
```

## 维护边界

- SwiftUI 页面不拼装共享业务规则。
- 对 Swift 不友好的 sealed class、泛型或集合，优先在 common 提供简单 facade，不在 Swift 复制模型规则。
- Apple 生命周期、权限、Keychain、推送和系统 SDK 只留在 iOS 层。
- 共享接口或模型变化后，先构建 KMP framework，再用 Xcode 验证 Swift 编译和链接。
