2026-6-30
使用codex做跨android、ios、harmony的跨平台KMP+native UI框架

2026-07-02

## 采纳内容

1. 采纳“三端原生 UI + Android/iOS 共享 KMP 业务逻辑”的主线方案：
   - Android：`androidApp`，使用 Kotlin + Jetpack Compose。
   - iOS：`iosApp`，使用 Swift + SwiftUI。
   - HarmonyOS：`harmonyApp`，使用 ArkTS + ArkUI。
   - 共享逻辑：`common` KMP 模块，仅接入 Android/iOS。
   - HarmonyOS 第一阶段不直接依赖 KMP `common`，只保持协议、DTO、状态模型和业务流程一致。

2. 采纳当前仓库目录结构：
   - `common/`
   - `androidApp/`
   - `iosApp/`
   - `harmonyApp/`
   - `contract/`
   - `docs/`
   - `tools/`
   - `experimental/harmony-kmp/`

3. 采纳最小登录示例：
   - `common` 中包含登录 DTO、状态、动作、一次性效果、用例、仓储接口、模拟仓储、状态容器和门面类。
   - `androidApp` 中通过 Compose 登录页和 ViewModel 调用 KMP 共享逻辑。
   - `iosApp` 中通过 SwiftUI 登录页、ViewModel 和 `SharedLoginAdapter` 接入 KMP 框架。
   - `harmonyApp` 中通过 ArkTS 原生实现登录页、状态模型、ViewModel 和服务层，流程与 KMP 登录模块对齐。

4. 采纳契约和文档目录：
   - `contract` 存放 OpenAPI、JSON Schema、错误码和埋点事件。
   - `docs` 存放架构说明、KMP 边界、iOS 接入、HarmonyOS 计划、开发工作流和 HarmonyOS KMP 实验路线。
   - 所有 Markdown 说明已统一改为中文，保留必要技术名词和代码标识。

5. 采纳实验隔离原则：
   - 主线 Gradle 只 include `:common` 和 `:androidApp`。
   - 不在主线中加入 `harmonyTarget`、`harmonyArm64` 等非 Kotlin 官方标准编译目标。
   - HarmonyOS KMP 复用方案只放在 `experimental/harmony-kmp` 中验证。

6. 采纳 IDE 识别修正：
   - iOS 增加 `iosApp/iosApp.xcodeproj`、workspace 和共享 scheme。
   - HarmonyOS 增加 DevEco/Hvigor 所需的工程配置文件。
   - Android Studio 的 `.idea` 配置已从旧 `app` 模块引用调整为 `androidApp` 和 `common`。
   - `androidApp` 已补充 Kotlin Android 插件。
   - Gradle JDK 指定为 `jbr-21`。

## 人工审查点

1. Android Studio：
   - 只打开仓库根目录 `demo`。
   - Gradle 同步时确认使用 JDK 21。
   - 当前本机 SDK 已看到 `android-36.1`，项目继续使用 `compileSdk 36.1` 写法。
   - 如果仍然整片红，优先查看 Gradle Sync 第一个错误，不要先看编辑器里的连锁红线。
   - 如 Android Studio 仍缓存旧模块，执行 `Invalidate Caches / Restart` 后重新 Sync。

2. iOS / Xcode：
   - 不要用 Xcode 打开仓库根目录。
   - 应打开 `iosApp/iosApp.xcodeproj`。
   - 当前环境曾检测到只有 Command Line Tools，没有完整 Xcode；需要安装完整 Xcode 并设置 `xcode-select`。
   - 如需模拟器运行，需要在 Xcode 中安装对应 iOS Simulator Runtime。
   - 如需真实调用 KMP shared，需要先通过 Gradle 生成 `Shared.xcframework`，再加入 Xcode target。

3. HarmonyOS / DevEco Studio：
   - 不要用 DevEco 打开仓库根目录。
   - 应打开 `harmonyApp` 目录。
   - DevEco 首次使用需要补齐 HarmonyOS/OpenHarmony SDK 组件、ArkTS、Toolchains、Hvigor、ohpm、Previewer 等。
   - 当前 `harmonyApp` 是第一阶段 ArkTS 原生骨架，不依赖 KMP `common`。
   - `@ohos/hvigor` 和 `@ohos/hvigor-ohos-plugin` 的版本需要与本机 DevEco 版本匹配，必要时由 DevEco 自动修正。

4. HarmonyOS KMP 实验：
   - Kotlin/JS、Kotlin/Native + NAPI、第三方 Harmony KMP target 都不能直接进入主线。
   - 实验必须先验证构建、产物、ArkTS 调用链、依赖支持、测试复用和 CI 稳定性。
   - 实验失败不能影响 Android/iOS 主线交付。

5. 当前工作区注意事项：
   - 工作区中已有登录相关代码改动和新增 `LoginRules` 文件，后续修改前需要先确认这些改动是否为人工新增，避免覆盖。

## 验证结果

1. 已完成的静态验证：
   - `commonMain` 未发现 Android、iOS、HarmonyOS 平台 UI/API 侵入。
   - iOS Swift 源码曾通过 `swiftc -parse` 解析。
   - iOS `project.pbxproj` 曾通过 `plutil` 校验。
   - iOS workspace 和 scheme XML 曾通过 `xmllint` 校验。
   - HarmonyOS JSON/JSON5 结构文件曾通过基础格式检查。
   - Markdown 文档已扫描并改为中文说明。
   - `.idea` 中旧 `app`、`:app`、`demo.app`、`Android App.app` 等引用已清理。
   - `.idea` XML 文件格式校验通过。

2. 本机环境观察结果：
   - JDK 21 可用。
   - Android SDK 路径存在：`/Users/shiliangcan/Library/Android/sdk`。
   - 本机已安装 Android SDK Platform `android-36.1`。
   - 本机已安装 Android Build Tools `36.0.0`、`36.1.0`、`37.0.0`。
   - 曾观察到 Xcode 侧只有 Command Line Tools，未选中完整 Xcode。
   - 曾观察到 `hvigor`、`node` 命令不可用，需要由 DevEco 环境补齐。

3. 未完成的验证：
   - Codex 沙箱内无法完整执行 Gradle 构建。
   - 直接使用 `~/.gradle` 时失败原因是沙箱禁止写 Gradle wrapper 锁文件。
   - 使用项目内临时 Gradle 缓存时，因当前环境无法访问 `services.gradle.org`，无法下载 Gradle 发行包。
   - 因此 `:common:check`、`:androidApp:assembleDebug`、iOS KMP framework 生成和 HarmonyOS Hvigor 构建仍需在本机 IDE/终端中人工复验。

## 人工修正点

1. Android Studio 仍然整片红时：
   - 先执行 Gradle Sync。
   - 如果仍然失败，记录 Gradle Sync 窗口的第一个错误。
   - 如果错误仍指向旧 `app` 模块，关闭 Android Studio 后重新打开项目，并执行 `Invalidate Caches / Restart`。
   - 如果错误是依赖无法下载，检查网络、代理、Gradle 插件仓库访问和 Android Studio 离线模式。
   - 如果错误是 SDK 不匹配，确认 SDK Manager 中安装的是 `Android SDK Platform 36.1`。

2. Xcode 侧：
   - 安装完整 Xcode，而不是只安装 Command Line Tools。
   - 执行 `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`。
   - 在 Xcode 中安装需要的 iOS Simulator Runtime。
   - 需要 KMP 共享逻辑时，先生成并接入 `Shared.xcframework`。

3. DevEco 侧：
   - 用 DevEco Studio 打开 `harmonyApp`。
   - 按 SDK Manager 提示安装 HarmonyOS/OpenHarmony SDK、ArkTS、Toolchains、Hvigor、ohpm 等组件。
   - 如果 DevEco 自动调整 Hvigor 插件版本，需要同步更新 `harmonyApp/oh-package.json5`。
   - 当前阶段不把 HarmonyOS 直接接入 KMP shared。

4. 后续代码修正：
   - 若登录模型继续演进，需要同步检查 Kotlin、Swift、ArkTS 三端 DTO、状态字段、动作和错误码是否一致。
   - 如果引入真实网络请求，先在 `commonMain` 定义抽象接口，再由 Android/iOS 平台层提供实现。
   - HarmonyOS 继续保持 ArkTS 原生实现，直到实验目录中的 KMP 复用方案验证通过。

---

2026-07-02 iOS 真 KMP 接入补充

## 采纳内容

1. 采纳 iOS 强制接入 KMP `Shared.framework` 的方案：
   - `iosApp/iosApp/Login/SharedLoginAdapter.swift` 不再使用 `#if canImport(Shared)`。
   - 删除 Swift 本地 fallback mock。
   - iOS 登录、注册、验证码、登出流程必须通过 KMP `LoginFacade` 调用 `common` 业务逻辑。

2. 采纳 Xcode 自动构建 KMP framework 的方式：
   - `iosApp.xcodeproj` 增加 `Build Shared KMP Framework` Run Script phase。
   - Xcode 构建 iOS target 前执行：
     ```bash
     cd "$SRCROOT/.."
     ./gradlew :common:embedAndSignAppleFrameworkForXcode
     ```
   - `FRAMEWORK_SEARCH_PATHS` 指向 `common/build/bin/.../debugFramework` 和 `releaseFramework`。
   - `OTHER_LDFLAGS` 增加 `-framework Shared`。
   - iOS target 关闭 `ENABLE_USER_SCRIPT_SANDBOXING`，避免 Xcode 脚本沙箱阻断 Gradle framework 构建。

3. 采纳 `LoginFacade` 作为 Swift 导出 API：
   - `LoginFacade.kt` 保留在 `commonMain`。
   - 增加 `@Suppress("unused")`，因为 Kotlin/Android 侧不直接引用它，Swift 通过 `Shared.framework` 使用它。
   - 这类 unused warning 属于跨语言导出 API 的 IDE 识别问题，不代表代码应删除。

4. 采纳文档同步：
   - `docs/ios-integration.md` 改为描述强制 `import Shared` 的真实 KMP 接入方式。
   - `iosApp/README.md` 改为说明 Xcode 自动执行 KMP framework 构建。
   - `README.md` 修正 iOS 说明和当前登录测试账号。

## 人工审查点

1. iOS 工程审查：
   - 打开 `iosApp/iosApp.xcodeproj`，不要用 Xcode 打开仓库根目录。
   - 检查 target Build Phases 中 `Build Shared KMP Framework` 是否位于 `Compile Sources` 之前。
   - 检查 target Build Settings 中 `FRAMEWORK_SEARCH_PATHS` 是否包含 `common/build/bin/iosSimulatorArm64`、`iosX64`、`iosArm64` 的 debug/release framework 输出路径。
   - 检查 `OTHER_LDFLAGS` 是否包含 `-framework Shared`。
   - 检查 `ENABLE_USER_SCRIPT_SANDBOXING` 是否为 `NO`。

2. Swift/KMP 桥接审查：
   - `SharedLoginAdapter.swift` 应直接 `import Shared`。
   - 不应再出现 Swift fallback mock 账号、验证码、本地 accounts 数组等逻辑。
   - Kotlin `AuthMode.Register` 导出到 Swift 后名称为 `AuthMode.register_`，不是 `AuthMode.register`。
   - SwiftUI 页面不直接操作复杂 KMP 类型，仍通过 `SharedLoginAdapter` 做薄适配。

3. KMP 导出审查：
   - `LoginFacade` 是 Swift 友好的门面类，应继续保持方法签名简单。
   - 避免直接把 sealed interface、泛型结果、复杂 Kotlin 集合暴露给 Swift 页面层。
   - 如果后续新增登录流程能力，优先在 `LoginFacade` 中提供 Swift 易用方法。

4. 环境审查：
   - 本机必须安装完整 Xcode，而不是只安装 Command Line Tools。
   - `xcode-select` 需要指向 `/Applications/Xcode.app/Contents/Developer`。
   - 模拟器运行需要安装对应 iOS Simulator Runtime。

## 验证结果

1. 已通过验证：
   - `./gradlew :common:compileKotlinIosSimulatorArm64` 通过。
   - 使用 `swiftc -typecheck -F common/build/bin/iosSimulatorArm64/debugFramework ...` 验证 Swift 可 `import Shared`，类型检查通过。
   - `plutil -lint iosApp/iosApp.xcodeproj/project.pbxproj` 通过。
   - `SharedLoginAdapter.swift` 已不再包含 `canImport(Shared)` 和 fallback mock。

2. 仍受环境阻塞的验证：
   - `./gradlew :common:linkDebugFrameworkIosSimulatorArm64` 失败。
   - 失败原因是当前环境执行 `/usr/bin/xcrun xcodebuild -version` 报错，提示 Xcode 或 Command Line Tools 未正确配置。
   - 这是本机 Xcode 选择/安装问题，不是 Swift adapter 或 `LoginFacade` 代码链路问题。

3. 当前结论：
   - 代码层面已从“iOS 可选接入 KMP + Swift fallback”调整为“iOS 强制接入 KMP”。
   - 在未正确生成/链接 `Shared.framework` 的环境中，iOS 应直接编译失败，这是强制 KMP 接入后的预期行为。

## 人工修正点

1. Xcode 环境修正：
   - 安装完整 Xcode。
   - 执行：
     ```bash
     sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
     ```
   - 执行：
     ```bash
     xcodebuild -version
     ```
     确认能输出完整 Xcode 版本。

2. iOS 构建复验：
   - 在 Xcode 打开 `iosApp/iosApp.xcodeproj`。
   - 选择 iOS Simulator。
   - 执行 Build，确认 `Build Shared KMP Framework` phase 能成功运行。
   - 如果 Xcode build 找不到 `Shared`，优先检查 `FRAMEWORK_SEARCH_PATHS` 和 Gradle script phase 是否执行。

3. KMP framework 复验：
   - Xcode 环境修好后，在仓库根目录执行：
     ```bash
     ./gradlew :common:linkDebugFrameworkIosSimulatorArm64
     ```
   - 如需独立产出 XCFramework，执行：
     ```bash
     ./tools/build-shared-xcframework.sh
     ```

4. 后续维护修正：
   - 不要因为 IDEA 显示 `LoginFacade` unused 就删除它。
   - 如果需要减少 IDE warning，应保留 `@Suppress("unused")` 和注释。
   - 后续新增 iOS 登录能力时，先扩展 `common` 和 `LoginFacade`，再在 `SharedLoginAdapter` 做 Swift 映射。

---

2026-07-02 Android/iOS KMP + native UI 边界收敛补充

## 采纳内容

1. 采纳“Android/iOS 端侧只做展示、交互和平台适配”的边界：
   - Android 继续使用 Compose 原生 UI。
   - iOS 继续使用 SwiftUI 原生 UI。
   - HarmonyOS 本轮不处理。
   - 登录业务模型、mock 数据结构、输入规则和规则测试统一沉淀在 `common`。

2. 采纳 common 规则层：
   - 新增 `common/src/commonMain/kotlin/com/example/demo/common/login/LoginRules.kt`。
   - 将手机号、邮箱、验证码、登录按钮可用性、注册密码规则和输入归一化规则放入 common。
   - 新增 `common/src/commonTest/kotlin/com/example/demo/common/login/LoginRulesTest.kt` 锁定规则行为。
   - `LocalMockAuthRepository` 和 `LoginUseCase` 改为复用 common 规则，避免端侧和仓储层规则不一致。

3. 采纳端侧薄适配：
   - Android `LoginScreen` 不再直接处理 `MockResult` 或引用 mock 验证码常量。
   - Android `LoginViewModel` 作为 Compose UI 到 common 规则/状态容器的薄适配层。
   - iOS `SharedLoginAdapter` 只保留 Swift 到 KMP `LoginFacade` 的薄转发，不再做状态模型和 effect payload 映射。

4. 采纳 iOS 直接使用 KMP 导出类型：
   - 删除 `iosApp/iosApp/Login/LoginState.swift`。
   - 删除 `IOSLoginState`、`IOSAuthMode`、`IOSAuthSession`、`IOSLoginEffect`。
   - `LoginViewModel.state` 直接使用 KMP 导出的 `Shared.LoginState`。
   - iOS effect 处理直接使用 KMP 导出的 `LoginEffectAuthSucceeded`、`LoginEffectNavigateHome`、`LoginEffectLoggedOut`、`LoginEffectSessionExpired`、`LoginEffectShowMessage`。
   - common 中删除旧 Swift 桥接用的 `LoginEffectPayload` 和 `consumeEffectPayload()`。

5. 采纳视觉不变原则：
   - 本轮不修改登录页视觉结构、颜色、字体、间距、文案、视频背景、Logo 和控件样式。
   - 输入过滤和按钮可用性逻辑迁移到 common，但端上显示效果保持原样。

## 人工审查点

1. KMP 边界审查：
   - `common/src/commonMain` 只能放平台无关业务模型、状态、规则、mock 数据结构、UseCase、Repository 抽象和门面类。
   - `androidApp` 不应新增业务规则副本，只保留 Compose UI、Android 存储适配和 ViewModel 转发。
   - `iosApp` 不应新增 Swift 业务状态模型副本，只保留 SwiftUI 页面状态、页面流转和 KMP adapter。

2. iOS 去冗余审查：
   - Xcode project 中不应再引用 `LoginState.swift`。
   - iOS 源码中不应再出现 `IOSLoginState`、`IOSAuthMode`、`IOSAuthSession`、`IOSLoginEffect`。
   - `SharedLoginAdapter.consumeEffect()` 应直接返回 KMP `LoginEffect?`。
   - 不应再通过 `LoginEffectPayload.type` 这类字符串分发 effect。

3. common 规则审查：
   - 新增登录规则时先改 `LoginRules`。
   - 同步补 `LoginRulesTest` 或相关 common test。
   - 端侧按钮可用性、输入归一化、错误文案如属于业务规则，应从 common 获取。

4. 视觉审查：
   - Android/iOS 登录页截图应与本轮改动前保持一致。
   - 如果视觉变化，应优先检查是否误改了 `LoginScreen.kt` 或 `LoginView.swift` 中的布局、颜色、字体、间距和资源引用。

## 验证结果

1. 静态验证通过：
   - Android/iOS 登录目录未再发现本地邮箱、手机号、验证码、密码等重复规则实现。
   - iOS 源码和 Xcode 工程未再发现 `IOSLoginState`、`IOSAuthMode`、`IOSAuthSession`、`IOSLoginEffect`、`LoginEffectPayload`、`consumeEffectPayload` 残留。
   - `iosApp/iosApp/Login/LoginState.swift` 已删除，Xcode project Sources 引用已移除。

2. Gradle 验证通过：
   ```bash
   ./gradlew :common:testAndroidHostTest
   ./gradlew :androidApp:assembleDebug
   ./gradlew :common:linkDebugFrameworkIosSimulatorArm64
   ```

3. Xcode 验证通过：
   ```bash
   xcodebuild -project iosApp/iosApp.xcodeproj \
     -scheme IOSDemo \
     -sdk iphonesimulator \
     -configuration Debug \
     -derivedDataPath /tmp/codex-ios-build \
     CODE_SIGNING_ALLOWED=NO \
     build
   ```

4. 环境修正后观察：
   - `xcode-select -p` 已指向 `/Applications/Xcode.app/Contents/Developer`。
   - `xcodebuild -version` 可输出完整 Xcode 版本。
   - iOS 构建能执行 KMP framework Run Script，并完成 Swift 编译和链接。
   - 构建中仍有非阻塞 warning：`AccentColor` 资源缺失，以及 simulator 构建时 `iosArm64/debugFramework` 搜索路径不存在。

## 人工修正点

1. 如后续 iOS 又出现重复状态模型：
   - 不要新增 `IOS*State`、`IOS*Effect` 这类业务模型副本。
   - 优先检查 KMP 导出的 `LoginState`、`LoginEffect` 是否已满足 Swift 使用。
   - 必要时扩展 `LoginFacade`，而不是在 Swift 侧重新建模型。

2. 如后续 Swift 处理 KMP sealed type 不方便：
   - 可在 `LoginFacade` 中增加 Swift 友好的简单方法。
   - 不要恢复 `LoginEffectPayload` 字符串映射，除非明确需要兼容外部 ABI。

3. 如 Xcode build 再次因 Gradle wrapper lock 失败：
   - 确认不是代码错误，而是沙箱/权限阻止访问 `~/.gradle`。
   - 在本机终端或 Xcode 中直接构建，或允许当前环境提升权限执行 `xcodebuild`。

4. 如需清理当前 warning：
   - `AccentColor` warning 可在 `Assets.xcassets` 中补 AccentColor，或关闭全局 AccentColor 引用。
    - `iosArm64/debugFramework` search path warning 可通过生成 device framework 或按构建配置拆分 framework search path 处理。

---

2026-07-03 Android/iOS 页面架构统一为 Navigation 导航 + 组件化

## 采纳内容

1. 采纳 Android 页面架构重构：从状态驱动切换到 Navigation Compose
   - 添加 `navigation-compose` 依赖（`gradle/libs.versions.toml` + `androidApp/build.gradle.kts`）。
   - 创建 `navigation/AuthNavGraph.kt`：定义 `AuthRoutes` 路由常量 + `NavHost` + 统一的 `LoginEffect` → 导航监听。
   - 创建 `login/components/` 共享组件层：`AuthColors.kt`（颜色/尺寸常量）、`LegalContent.kt`（隐私条款文本）、`AuthComponents.kt`（15+ 共享UI组件，包括 `AuthBlackPage`、`UnderlineInput`、`CorosFilledButton`、`CodeBoxes`、`AgreementRow`、`TermsConsentSheet` 等）。
   - 创建 9 个独立 Screen 文件：`entrance/EntranceScreen.kt`、`login/LoginPageScreen.kt`、`register/PhoneRegisterScreen.kt`、`register/EmailRegisterScreen.kt`、`verify/VerifyCodeScreen.kt`、`password/PasswordSetupScreen.kt`、`signedin/SignedInScreen.kt`、`legal/LegalDocumentScreen.kt`。
   - 修改 `MainActivity.kt`：将 `LoginScreen()` 替换为 `AuthNavGraph()`。
   - 删除原 2050 行的 `LoginScreen.kt`。

2. 采纳 iOS 页面架构重构：从状态驱动切换到 NavigationStack
   - 创建 `AuthCoordinator.swift` + `AuthRoute` 枚举（`Hashable`）：使用 `NavigationStack` + `NavigationPath` 管理导航栈，统一监听 `LoginViewModel.effectTrigger` 处理导航。
   - 创建 `Components/` 共享组件层：`AuthColors.swift`、`LegalContent.swift`、`AuthComponents.swift`（16+ 共享UI组件，与 Android 对应）。
   - 创建 8 个独立 View 文件：`Views/EntranceView.swift`、`Views/LoginPageView.swift`、`Views/PhoneRegisterView.swift`、`Views/EmailRegisterView.swift`、`Views/VerifyCodeView.swift`、`Views/PasswordSetupView.swift`、`Views/SignedInView.swift`、`Views/LegalDocumentView.swift`。
   - 简化 `LoginViewModel.swift`：移除所有导航状态（`page`、`legalReturnPage`、`localError`、`codeInput`、`emailInput`、`setupPassword`、`confirmPassword`、`verifyTargetKind`、`termsPromptAction`、`unavailableDialogVisible`），改为 `effectTrigger` + `consumeEffect()` 单向数据流。
   - 修改 `ContentView.swift`：将 `LoginView()` 替换为 `AuthCoordinator()`。
   - 更新 `project.pbxproj`：移除 `LoginView.swift`，添加 12 个新文件引用。
   - 删除原 1319 行的 `LoginView.swift`。
   - 导航返回机制：iOS 无硬件返回键，使用 NavigationStack 自动系统返回按钮 + 左滑手势 + 自定义 `‹` 按钮（`path.removeLast()`），View 通过 `.navigationBarBackButtonHidden(true)` 隐藏系统按钮但保留左滑手势。

3. 采纳架构对齐原则
   - Android ↔ iOS 页面导航方式统一：`when(page)` / `switch page` → 路由栈（`NavHost` / `NavigationStack`）。
   - 共享组件提取统一：两边均提取颜色常量、法律文本、15+ 公共 UI 组件到 `components/`。
   - ViewModel 职责统一：两边 ViewModel 只保留业务状态和 KMP 桥接，移除导航和局部 UI 状态。
   - 导航副作用处理统一：两边均由导航协调器（`AuthNavGraph` / `AuthCoordinator`）监听 ViewModel 的副作用，而非 ViewModel 自行控制导航。
   - KMP `common` 模块本轮零变更。

## 人工审查点

1. Android 导航审查：
   - `AuthNavGraph` 中的 `startDestination` 使用了 `viewModel.state.isLoggedIn`，确保已登录用户不经过入口页。
   - 注册成功后流程：`PasswordSetupScreen` → 注册成功 → `clearSessionSilently()` → 跳转 `LOGIN` 页，而非自动登录。
   - `SIGNED_IN` 路由使用 `popUpTo(ENTRANCE) { inclusive = true }` 清空导航栈，防止从已登录页回退到登录页。
   - 各 Screen 的 `localError`、`acceptedTerms`、`codeInput` 等局部状态使用 `rememberSaveable`。

2. iOS 导航审查：
   - `IPHONEOS_DEPLOYMENT_TARGET = 17.0`，NavigationStack（iOS 16+）兼容性无问题。
   - `AuthCoordinator` 使用 `.onAppear` 推入首路由，正确支持已登录状态直接进入 `signedIn`。
   - `handleNavigation` 使用 `path = NavigationPath()` 清空栈 + `path.append()` 重置导航。
   - `.navigationBarBackButtonHidden(true)` 隐藏系统返回按钮但保留左滑手势；`‹` 按钮通过 `path.removeLast()` 弹出当前页。
   - 各 View 的局部 UI 状态用 `@State`，与 ViewModel 的业务状态分离。

3. 全局审查：
   - Android `AuthComponents.kt` 和 iOS `AuthComponents.swift` 保持组件签名一致。
   - Android 9 个 Screen vs iOS 8 个 View（iOS 将 PrivacyPolicy 和 ServiceTerms 合并到 `LegalDocumentView.swift`），功能等价。
   - 两边 `LoginViewModel` 保持 MVI 模式不变，未修改 `LoginStore.dispatch(action)` 链路。
   - `common/` 本轮零变更。

## 验证结果

1. Gradle 构建验证通过：
   ```bash
   ./gradlew :androidApp:assembleDebug → BUILD SUCCESSFUL（41s）
   ./gradlew :common:check → BUILD SUCCESSFUL（23s，含 commonTest）
   ```

2. Xcode 构建验证通过：
   ```bash
   xcodebuild -project iosApp/iosApp.xcodeproj -scheme IOSDemo -destination 'platform=iOS Simulator,name=iPhone 17' build → BUILD SUCCESSFUL
   ```

3. 静态验证通过：
   - Android 目录结构：12 个新文件分布到 `navigation/`、`login/components/`、`login/entrance/`、`login/login/`、`login/register/`、`login/verify/`、`login/password/`、`login/signedin/`、`login/legal/`。
   - iOS 目录结构：14 个文件分布到 `Login/AuthCoordinator.swift`、`Login/Components/`、`Login/Views/`。
   - 两侧均已删除原单体文件（Android 2050 行 / iOS 1319 行）。
   - 两侧均不再存在 `when(page)` / `switch page` 状态切换导航。

## 人工修正点

1. 如需在真实 iOS 设备上运行：
   - 补全 `FRAMEWORK_SEARCH_PATHS` 中的 `iosArm64` device framework 路径。
   - 或使用 `./tools/build-shared-xcframework.sh` 生成通用 XCFramework。

2. 如后续增加新页面：
   - Android：`AuthRoutes` 添加常量 → `AuthNavGraph` 注册 `composable` → 创建对应 `Screen.kt`。
   - iOS：`AuthRoute` 添加枚举值 → `AuthCoordinator` 注册 `navigationDestination` → 创建对应 `View.swift`。

3. 如后续需要自定义返回行为：
   - Android：`popBackStack()` / `navigate(route) { popUpTo(...) }`。
   - iOS：`path.removeLast()` / `path = NavigationPath()` + `path.append(...)`。
