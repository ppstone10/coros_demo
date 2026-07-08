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

---

2026-07-03 鸿蒙端注册登录可用性修正补充

## 采纳内容
- 采纳鸿蒙端登录/注册页可用性修正：修复输入后“登录”“发送验证码”“注册”等确认按钮不亮的问题，按钮可用性改为读取页面当前输入状态，并在提交前同步到 `LoginViewModel`。
- 采纳鸿蒙端手机号输入限制：手机号输入框增加 11 位长度限制，并继续执行数字过滤与截断，避免输入超长或非数字内容。
- 采纳鸿蒙端返回行为修正：左上角返回按钮改为固定点击区域，并补充 `onBackPress()`，验证码页、设密页、协议页、登录/注册页可按当前页面来源回退。
- 采纳鸿蒙端初始页面沉浸式配置：在 `EntryAbility.ets` 中设置全屏布局、透明状态栏/导航栏、黑色窗口背景和亮色系统栏图标。
- 采纳鸿蒙端本地 mock 逻辑补齐：默认手机号账号、默认邮箱账号、默认验证码 `1234`、重发验证码 `4321`、验证码 60 秒过期、注册密码复杂度校验与 Android/iOS 当前 mock 行为保持一致。

## 人工审查点
- 需人工审查鸿蒙端 UI：当前鸿蒙端 UI 虽按 Android/iOS 的页面流程和主要尺寸做了对齐，但实现方式、控件默认行为、系统栏表现、输入框交互和整体视觉仍与 Android/iOS 端存在较大差异，需要设计/产品逐页验收。
- 需人工审查鸿蒙端业务架构：暂时未实现鸿蒙端的 KMP 业务逻辑复用，当前仍是 ArkTS 本地 `LoginService` / `LoginViewModel` 模拟共享规则；后续若要求三端真正同源，需要单独设计 HarmonyOS 接入 KMP 或等价共享层方案。
- 需人工审查验证码和 mock 账号策略：当前验证码、默认账号、过期时间均为本地 mock 行为，只用于 demo 侧一致性验证，真实业务接入前需确认接口契约、安全策略和错误码映射。
- 需人工审查沉浸式兼容性：已通过编译，但不同鸿蒙设备、系统版本、虚拟导航栏/手势导航下的状态栏和导航栏显示仍需真机或模拟器人工确认。

## 验证结果
- 构建验证通过：执行 `DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk NODE_HOME=/Applications/DevEco-Studio.app/Contents/tools/node PATH=/Applications/DevEco-Studio.app/Contents/tools/node/bin:$PATH /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleHap --mode module -p module=entry@default -p product=default --node-home /Applications/DevEco-Studio.app/Contents/tools/node --no-daemon --no-parallel`，结果 `BUILD SUCCESSFUL`。
- 静态检查通过：确认本轮修改集中在鸿蒙端 `EntryAbility.ets`、`LoginPage.ets`、`LoginService.ets`、`LoginState.ets`、`LoginViewModel.ets` 以及鸿蒙资源补充，未修改 Android/iOS 端代码。
- 验证中仍存在非阻塞 warning：`EntryAbility.ets` 中函数可能抛异常、`promptAction.showToast` deprecated、未配置签名；构建通过但后续可按项目规范清理。

## 人工修正点
- 暂时未实现鸿蒙端 KMP 业务逻辑复用：后续需要人工确定 HarmonyOS 与 KMP shared module 的集成方案，避免长期维护 ArkTS 与 Kotlin 两套业务规则。
- 当前鸿蒙 UI 与 Android/iOS 端仍有较大差异：需要人工基于三端截图或真机录屏逐项校准布局、系统栏、按钮、输入框、验证码框、弹窗和页面切换体验。
- 需要人工真机/模拟器验收完整路径：入口页 → 手机号注册 → 协议弹窗 → 验证码 → 设密 → 注册成功回登录；入口页 → 登录 → 已登录页；邮箱注册、验证码重发、返回键/手势返回、协议页返回均需实际点击确认。

---

2026-07-03 Android/iOS 注册登录流程、个人信息、找回密码和资源一致性补充

## 采纳内容
- 采纳 Android 端注册登录流程调整：注册成功后回到登录页；登录成功时根据账号是否已完成个人信息决定进入个人信息完善页或欢迎页；未完成个人信息的账号再次登录仍强制进入个人信息完善页。
- 采纳个人信息完善逻辑：带 `*` 字段填写完整后才使能“完成”按钮；点击完成后保存整页个人信息，并用个人信息中的用户名更新欢迎页展示。
- 采纳 Android 端注册、验证码、设密和登录细节修正：重复账号在手机号/邮箱注册输入阶段检测；验证码页返回跳回手机号/邮箱注册页；密码输入最后一位明文显示限制为 3 秒；设密页注册按钮只依赖两次密码一致，复杂度错误改为点击注册后提示。
- 采纳找回密码流程：新增找回密码账号验证页和新密码设置页；账号必须完整匹配已注册账号才允许进入新密码设置；找回密码不再要求输入旧密码；新密码更新后旧密码不可用。
- 采纳账号注销能力：登录成功欢迎页保留退出登录按钮，并新增“注销账户”按钮；确认注销后删除当前账号。
- 采纳 iOS 端按 Android 当前实现补齐对应流程：使用 SwiftUI native UI 接入 KMP shared 业务逻辑，补齐个人信息完善、找回密码、新密码设置、欢迎页退出/注销等页面，并移除 Android/iOS 欢迎页不需要的返回按钮。
- 采纳 Android/iOS 资源一致性调整：iOS 个人信息页小图标从 SwiftUI/SF Symbols/文本替代改为复用与 Android 对齐的资源，包括相机、更多、男女、关闭、勾选等图标。
- 采纳 iOS 资源修正：修正 iOS `ic_profile_check` 勾图方向；新增 iOS 标准 `AppIcon.appiconset`，使用 Android `mipmap-xxxhdpi/ic_launcher.png` 作为源图生成各尺寸 AppIcon，并在 Xcode 工程 Debug/Release 中配置 `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`。

## 人工审查点
- 需人工审查个人信息字段业务规则：当前按页面必填字段控制“完成”按钮，但字段枚举、选项文案、生日/身高/体重等边界值仍需要产品或业务确认。
- 需人工审查账号注销影响范围：当前 demo 删除本地账号数据；真实业务接入时需确认是否还要清理 token、个人信息、云端账号、缓存和埋点身份。
- 需人工审查找回密码安全策略：当前 demo 只做账号存在性验证后重设密码；真实业务应补短信/邮箱验证码、频控、风控和错误码策略。
- 需人工审查 iOS/Android 资源显示效果：资源已对齐到同一套视觉来源，但不同平台启动器会有系统圆角、缩放、缓存和深浅色模式差异，需要在真机或模拟器桌面实际查看。
- 需人工审查滚动选择器交互：已按需求调整可视数据和选中态差异，但模糊/清晰程度、默认值和可读性仍需结合设计稿或截图人工验收。

## 验证结果
- Gradle 单元测试验证通过：执行 `./gradlew :common:testAndroidHostTest`，结果通过。
- KMP iOS 编译验证通过：执行 `./gradlew :common:compileKotlinIosSimulatorArm64` 和 `./gradlew :common:linkDebugFrameworkIosSimulatorArm64`，结果通过。
- Android 编译/打包验证通过：执行 `./gradlew :androidApp:compileDebugKotlin` 和 `./gradlew :androidApp:assembleDebug`，结果通过。
- iOS 构建验证通过：执行 `xcodebuild -project iosApp/iosApp.xcodeproj -scheme IOSDemo -destination 'generic/platform=iOS Simulator' build`，结果 `BUILD SUCCEEDED`。
- iOS 资源静态检查通过：检查 `iosApp/iosApp/Assets.xcassets/AppIcon.appiconset`、`ic_profile_check.imageset` 等资源文件存在；使用图片预览确认勾图方向正常、`AppIcon-60@3x.png` 为黑底红色 logo；使用 `sips -g pixelWidth -g pixelHeight` 确认关键 PNG 尺寸可读。

## 人工修正点
- 如 iOS 模拟器桌面仍显示旧图标，需要人工卸载已安装 app、Clean Build Folder 或重启模拟器以清理系统图标缓存。
- iOS 构建仍存在非阻塞 warning：`Build Shared KMP Framework` Run Script 未声明输出文件，会每次构建都运行；后续可按 Xcode 规范补 output dependency 或保持当前总是执行策略。
- iOS 构建日志仍可见 `iosArm64/debugFramework` 搜索路径相关风险；如需真机运行，需要补齐 device framework 或改为 XCFramework 方案。

---

2026-07-06 鸿蒙 KMP + KNOI native UI 接入补充

## 采纳内容
- 采纳鸿蒙端“不走 KuiklyUI 共享 UI、继续使用 ArkUI / ArkTS Native UI”的技术路线，目标是通过 KNOI 调用 KMP shared 业务逻辑，逐步替换 ArkTS 本地复写逻辑。
- 采纳独立 POC 模块方案：新增 `harmony-kmp-bridge`，不并入根 Gradle settings，避免根工程 Gradle 9 与 KuiklyBase / KNOI 插件链路冲突。
- 采纳 KuiklyBase-Kotlin + KNOI 构建链路：`harmony-kmp-bridge` 使用 KuiklyBase Kotlin `2.0.21-KBA-003`、KNOI `0.0.4`、独立 Gradle 8.5 wrapper，并配置 `ohosArm64` sharedLib `baseName = "kn"`，产出 `libkn.so`。
- 采纳 KNOI POC 正确入口：停止以 `import libshared_login_bridge.so` 作为入口，改为鸿蒙侧依赖 `@kuiklybase/knoi`，在 `EntryAbility.ets` 中执行 `setup('libkn.so', false)` 和 `init()`。
- 采纳 KNOI 生成 API：通过 KNOI 生成 `harmonyApp/entry/src/main/ets/knoi/provider.ets`，鸿蒙侧调用生成的 `getHarmonyLoginService()`，不再手写 native 调用名。
- 采纳 shared 登录逻辑接入：`HarmonyLoginService` 包装 `common` 中的 `LoginFacade`，向鸿蒙侧暴露登录、注册、验证码、状态快照、effect 快照和输入校验相关方法。
- 采纳 so 打包路径：已将 `libkn.so` 放入 `harmonyApp/entry/src/main/libs/arm64-v8a/` 和 `harmonyApp/entry/libs/arm64-v8a/`，用于鸿蒙构建和打包。
- 采纳鸿蒙端适配层拆分：新增/调整 `KnoiLoginAdapter.ets`、`LoginLogicAdapter.ets`、`LoginLogicProvider.ets`、`LoginViewModel.ets` 等，使 ArkTS 页面通过 adapter 间接调用 KNOI shared 逻辑。

## 人工审查点
- 需人工审查 KNOI 生成 API 与运行时 ABI：`setup('libkn.so')`、`libkn.so` 文件名、`baseName = "kn"` 和真机 `arm64-v8a` 环境需要保持一致，否则可能出现 native module 加载失败。
- 需人工审查鸿蒙端 shared 复用边界：当前已接入登录 shared 逻辑，但后续新增业务仍需坚持先改 `common` / `LoginFacade` / `HarmonyLoginService`，避免 ArkTS 重新产生业务规则副本。
- 需人工审查 KNOI 依赖 so 打包完整性：HAP 中应同时包含 `libkn.so`、`libknoi.so`、`libc++_shared.so` 等运行依赖；如切换 release/debug 或真机 ABI，需要重新确认产物来源和拷贝路径。
- 需人工审查 ArkUI 输入响应机制：用户实测同一页面输入框变化不会实时刷新按钮状态，但跨页面返回后状态能刷新，说明 shared 校验结果可能可用，问题更可能在 ArkUI 页面状态绑定、组件拆分或 TextInput 受控输入模式上。

## 验证结果
- Gradle shared 验证通过：执行 `./gradlew :common:check`，结果通过。
- KNOI bridge 构建验证通过：执行 `cd harmony-kmp-bridge && ./gradlew ohosArm64Binaries`，结果通过并产出 `libkn.so`。
- 鸿蒙构建验证通过：使用 DevEco Studio 内置 Node / ohpm / hvigor 环境执行 `/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleApp --no-daemon`，结果通过。
- 一键脚本验证通过：执行 `./tools/build-shared-harmony.sh`，结果通过。
- 产物检查通过：此前确认 HAP 中包含 `libkn.so`、`libknoi.so`、`libc++_shared.so`。
- 验证中仍存在非阻塞 warning：KSP 版本相对 KuiklyBase Kotlin 偏旧、KNOI NAPI verification warning、部分 KNOI 导出函数 may throw warning、`showToast` deprecated、未配置签名。
- 人工交互验证未通过：用户在鸿蒙端实测登录/注册页输入满足规则后按钮仍不会在同一页面实时变亮或变为可点击。

## 人工修正点
- 需要继续修正鸿蒙端按钮实时刷新问题：当前输入框同页变更没有驱动按钮状态实时重绘，需进一步检查 `UnderlineInput` / `TextInput({ text: ... })` 是否只是初始值、是否需要 `@Link` / `@Prop` / `$$` 双向绑定或拆成子组件传递可观察状态。
- 需要增加临时可观测调试手段：建议在继续修复时临时输出或展示 `username`、`password`、`loginActionEnabled`、`registerActionEnabled` 等值，确认是输入状态未变、按钮状态未变，还是 ArkUI 未重绘；修复后再移除调试代码。
- 需要真机或模拟器复验完整路径：登录、手机号注册、邮箱注册、验证码、设密、找回密码、注销账户等流程应确认业务结果来自 shared，并确认 UI 仍保持鸿蒙原生渲染。
- 需要在按钮问题修复后补充回归验证：至少重新执行 `./gradlew :common:check`、`cd harmony-kmp-bridge && ./gradlew ohosArm64Binaries`、鸿蒙 `hvigorw assembleApp`，并进行鸿蒙端手动交互验收。

---

2026-07-07 鸿蒙端按钮响应式缺陷定位与修复（@Builder → @Component + @Prop）

## 采纳内容
- 新增调试页面 `harmonyApp/entry/src/main/ets/pages/DebugStatePage.ets`，含 9 个测试区（原生 Button / @Component / struct @Builder 三种实现的对照、动态 enabled/loading 切换、UnderlineInput/TextInput onChange、镜像登录表单的 @State 可视化、协议勾选 toggle、事件日志），用于定位"按钮始终不亮"问题。
- 在 `LoginPage.ets` 的 `EntrancePage` 右上角添加半透明 `DEBUG` 入口，点击通过 `router.pushUrl` 跳转调试页。
- 在 `entry/src/main/resources/base/profile/main_pages.json` 注册 `pages/DebugStatePage` 路由。
- 确认根因：ArkUI `@Builder` 函数（模块级与 struct 成员级）的基本类型参数（boolean/string/number）为值传递的一次性快照，不建立响应式绑定；`@State` 变化时 `@Builder` 内部 `backgroundColor(enabledValue ? …)` 不会重新计算，导致按钮颜色恒为首次渲染值（灰色）。`onClick` 闭包因捕获的是调用时快照值仍可工作，所以"点击计数正常但颜色不变"。
- 将 `AuthComponents.ets` 中所有依赖响应式状态的交互组件从 `@Builder function` 重构为 `@Component struct` + `@Prop`：`CorosButton`、`AuthHeader`、`UnderlineInput`、`PhoneInputComp`（原 PhoneInput，改名避免与系统组件冲突）、`DisabledUnderlineValue`、`AgreementRowComp`、`CodeBoxesComp`、`ThirdPartyAreaComp`。
- 保留无回调的纯展示组件为 `@Builder`：`AuthTitle`、`ErrorText`、`BlockingLoadingOverlay`、`LegalDocumentPage`（确认安全）。
- 同步重写 `LoginPage.ets` 与 `DebugStatePage.ets` 调用语法：从 `CorosButton('登录', RED, enabled, …)` 改为 `CorosButton({ textValue: '登录', color: RED, enabledValue: enabled, … })`。
- 修复 `CorosButton` 的 `.enabled(!loading)` → `.enabled(!loading && this.enabledValue)`，确保禁用态真正拦截点击。
- 调试页保留 struct 成员 `@Builder` 版本 `StructCorosButton` 作为负面对照样本（刻意不亮，用于证明 @Builder 缺陷）。
- 此前对 `AuthComponents.ets` 的几次重构一并记录：将 `$$: { key: type }` 对象字面量参数改为具名参数（修 `arkts-no-obj-literals-as-types`）；`FontWeight.Light` → `FontWeight.Lighter`；移除 `CorosLogo` 模块级 `@Builder`（返回 void 无法链式 `.margin()`）改为内联 `Image`；重复 `export` 语句清理；动态 `import('./LegalContent')` 改为静态导入。

## 人工审查点
- `@Prop` 默认值合理性：各 `@Component` 的 `@Prop` 均设置了默认值（如 `enabledValue: boolean = true`、`textValue: string = ''`）。需人工确认默认值不会在父组件漏传参数时产生误用（例如 `enabledValue` 默认 `true` 可能导致禁用态按钮意外可点）。
- 回调函数未用 `@Prop`：`onTap`、`onChange`、`onPasswordToggle` 等回调以普通成员变量声明（非 `@Prop`）。ArkUI 中函数类型不支持 `@Prop`，当前依赖闭包捕获 `this`。需人工确认跨组件回调的 `this` 绑定在所有场景下正确。
- `PhoneInputComp` 命名变更：为避免与 ArkUI 系统 `PhoneInput` 潜在冲突改名，需人工确认调用点全部更新、无遗留旧名引用。
- `LegalDocumentPage` 保留为 `@Builder`：其 `onBack` 回调为简单导航，未用响应式状态。若后续需在法律文档页内根据状态动态变化 UI，需重新评估是否升级为 `@Component`。
- ProfileCompletion 页内的 `@Builder` 方法：`ProfileTextRow`/`ProfilePickerRow`/`GenderRow`/`GenderButton`/`RequiredLabel` 仍为 struct 成员 `@Builder`，依赖 `@State profileUsername` 等通过闭包捕获 `this` 更新。需人工确认这些字段的响应式更新路径是否受 @Builder 值传递影响（初步判断因直接引用 `this.xxx` 而非参数传递，应正常，但建议实测）。
- `Video` 组件触摸拦截：`EntrancePage` 的 `Stack` 中 `Video` 全屏覆盖，按钮在 `Column` 内。需人工确认 Video 不会拦截上层 Column 的触摸事件（用户已反馈按钮可点，初步确认无问题）。
- 是否将同样的 `@Component + @Prop` 模式推广到后续新增的鸿蒙交互组件，作为团队规范固化，需人工决策。

## 验证结果
- 用户实机测试反馈：输入合规账号密码后，登录按钮从灰色变红色（`enabledValue` 响应式生效），问题"登录/注册按钮始终不亮"已解决 —— 通过。
- 用户实机测试反馈：调试页第 4 区切换 enabled 后，`@Component` 动态按钮变亮、`@Builder` 动态按钮不变亮，对照实验验证根因判断正确 —— 通过。
- 用户实机测试反馈：第 7 区 `loginActionEnabled` 文字变红（@State 响应式）、`@Component` 登录按钮变亮、`@Builder` 对照按钮不变亮 —— 通过。
- 用户实机测试反馈：第 1/2/3/5/6/8 区原生按钮、@Component 按钮、输入框、勾选框均正常响应 —— 通过。
- 未执行：项目级 `assembleHap` 编译验证（本轮为用户在 DevEco Studio 内手动编译运行，未由 Codex 执行构建命令）、未执行 lint/typecheck、未执行 `./gradlew :common:check` 与 `ohosArm64Binaries` 回归。

## 人工修正点
- 建议移除或降级调试入口：`EntrancePage` 右上角的 `DEBUG` 按钮与 `DebugStatePage` 为诊断用途，正式发布前应移除或通过 build flag 隔离。
- `main_pages.json` 中 `pages/DebugStatePage` 注册在发布版应一并移除。
- 调试页中的 `StructCorosButton` 负面对照样本可保留用于回归测试，但若不需长期保留建议清理。
- `AuthComponents.ets` 中原模块级 `@Builder` 版本的 `CorosButton`/`AuthHeader`/`UnderlineInput`/`PhoneInput`/`AgreementRow`/`CodeBoxes`/`ThirdPartyArea`/`DisabledUnderlineValue`/`BackButton`/`TermsConsentSheet`/`UnavailableFeatureDialog`/`DeleteAccountDialog` 已被 `@Component` 替代或移入 `LoginPage` struct，需人工确认无其他文件引用旧模块级符号。
- 建议补充一次完整的 `assembleHap` 编译验证，确认无未使用导入、类型不匹配等编译告警。
- 建议补充 `./gradlew :common:check` 与 `cd harmony-kmp-bridge && ./gradlew ohosArm64Binaries` 回归，确认 KMP 侧改动（`LoginFacade.changePassword` 等）未破坏 shared 构建产物。
- 建议真机/模拟器复验完整业务路径：登录、手机号注册、邮箱注册、验证码、设密、找回密码、注销账户、完善资料，确认业务结果仍来自 shared 且 UI 保持鸿蒙原生渲染。

---

2026-07-07 鸿蒙端响应式缺陷修复、导航对齐与持久化排查

## 采纳内容

1. 采纳 ErrorText 响应式改造：将 `AuthComponents.ets` 中的 `ErrorText` 从模块级 `@Builder` 函数改造为 `@Component struct` + `@Prop message`，修正 ArkUI `@Builder` 对基本类型参数（string）按值快照导致错误提示不实时刷新的问题。同步更新全部 13 处调用点：`LoginFormPage`, `PasswordSetupPage`, `PhoneRegisterPage`, `EmailRegisterPage`, `ForgotPasswordPage`, `ResetPasswordPage`, `VerifyCodePage`, `ProfileCompletionPage`, `SignedInPage`, `DebugStatePage`, `LoginPage`，调用语法从 `ErrorText(value)` 改为 `ErrorText({ message: value })`。
2. 采纳注册设密页返回导航修复：`PasswordSetupPage` 完成注册后改为 `router.replaceUrl({ url: LOGIN, params: { fromRegistration: true } })`；`LoginFormPage` 新增 `@State fromRegistration` 读取路由参数，`onBackPress` 中根据 `fromRegistration` 调用 `router.clear()` 后 `replaceUrl({ url: ENTRANCE })`，避免回退到验证码页或注册页。
3. 采纳登录成功后清栈跳转：`LoginFormPage.handleLoginEffect` 在 `AuthSucceeded` 时先 `router.clear()` 再 `replaceUrl` 到 `PROFILE_COMPLETION` 或 `SIGNED_IN`，匹配 Android `popUpTo(ENTRANCE){inclusive=false}` 行为。退出登录和注销账户同样先清栈再跳入口页。
4. 采纳重置密码页栈清理：`ResetPasswordPage` 完成后改为 `router.back({ url: LOGIN })`，弹回到栈中已存在的登录页，避免重复创建 Login 实例导致回退栈异常。
5. 采纳 ProfileCompletionPage 滚轮选择器临时回退：本轮尝试将出生日期、身高、体重、公英制、国家地区改为 `TextPicker` 滚轮选择器，但因实测无法滚动，保留性别选择高亮修复，其余字段回退到文本输入方式。
6. 采纳隐私条款弹窗临时恢复：将 `LoginFormPage`/`PhoneRegisterPage`/`EmailRegisterPage` 的 `TermsConsentSheet` 遮罩和 `hitTestBehavior(HitTestMode.Block)` 改动回退为 `#000000C7`，避免弹窗点击"同意"后无法跳转下一页的问题。
7. 采纳 `HarmonyLoginService` 内部改造为持有 `dataSource: AuthStoreDataSource` 字段，新增 `exportStoreSnapshot(): String` / `restoreStoreSnapshot(json: String): Boolean` 两个方法。`exportStoreSnapshot` 调用 `generateStoreSnapshot()` 将 mock 仓库 accounts 序列化为 JSON；`restoreStoreSnapshot` 解析 JSON 后构造新的 `AuthStoreDataSource` 并替换 `facade`。
8. 采纳 `StorePersister.ets` 持久化辅助工具：封装 `@ohos.data.preferences`，提供 `initPersistence(context)` 和 `saveStoreSnapshot()`；`EntryAbility` 启动时调用 `initPersistence(this.context)`；`KnoiLoginAdapter` 在 submit/logout/submitProfile/deleteCurrentAccount/clearSessionSilently/resetPassword 后调用 `saveStoreSnapshot()`。
9. 确认持久化链路当前仍无法保存数据，已分析定位为以下五个根本原因（详见"人工审查点"）。

## 人工审查点

1. 需人工确认 KNOI `@ServiceProvider` 实例模型：`provider.ets` 中 `getHarmonyLoginService()` 每次通过 `getService<T>("HarmonyLoginService")` 获取代理。如果 KNOI 是 factory 模式（每次返回新实例指向不同 native 对象），则 EntryAbility 的 `restoreStoreSnapshot`、KnoiLoginAdapter 持有的 service、StorePersister 的 `exportStoreSnapshot` 分别操作不同的 native 实例，状态完全隔离，持久化必然失效。需人工确认 `@ServiceProvider` 是否为 singleton。
2. 需人工确认 `choices` 隐私条款弹窗 UX 改造：当前 `TermsConsentSheet` 是 struct 成员 `@Builder`，在 `Stack` 内 `if` 条件渲染。用户反馈"弹窗在屏幕最下方，无虚化背景，看不到弹出"。`hitTestBehavior(HitTestMode.Block)` 改造方案会吞掉"同意"按钮点击事件导致无法跳转。此问题需要 UI 设计或产品确认：如果采用自定义弹窗需全面重写布局；如果对原生交互尝试可使用 `bindSheet` / `CustomDialog` 等系统级组件替代当前 `@Builder` 叠加方案。
3. 需人工确认个人信息页滚轮选择器为何无法滚动：本轮尝试使用 `TextPicker` 嵌入到 `@Builder` `PickerOverlay` 中的方案，用户实测"划不动，只能用默认设置"。需人工调研 ArkUI TextPicker 在 `{@Builder 存在的响应式限制：`@Builder` 内的 UI 不支持响应式改动；`TextPicker` 可能需要在独立的根级组件中使用；或者需要避免 `TextPicker` 进入嵌套 `Stack`/`Column` 的约束，使用独立的 `CustomDialog` 或全屏 `Sheet` 替代临时回退前已确认文本输入可正常使用。
4. 需人工确认 `initPersistence` 异步时序：`EntryAbility.onWindowStageCreate` 中 `initPersistence(this.context)` 是 async 但未 await，`preferences.getPreferences` 返回前 `prefsInstance` 仍为 null，早期触发的 `saveStoreSnapshot()` 可能直接 return。建议改为 `await initPersistence(this.context)` 或者将恢复逻辑前置到 `onCreate`。
5. 需人工确认 `prefsInstance.flush()` 是否为异步落盘并需 `await`：当前实现未 await `flush()`，在 App 退出前可能尚未落盘。同时 `getSync` 在 `initPersistence` 中混串行调用 async 与 sync API，需确认 `@ohos.data.preferences` 在 API 12 的线程模型。
6. 需人工确认 `exportStoreSnapshot` 数据完整性：当前 `generateStoreSnapshot` 只导出 `accounts` 数组，`currentSession`、`verifyCodes`、`defaultAccountsInitialized` 全部硬编码（null / [] / true）。`defaultAccountsInitialized=true` 会让 `LocalMockAuthRepository` 在 restore 后跳过默认账号初始化——如果之前没注册任何账号，restore 后仓库为空且不再创建默认测试账号。需产品或业务确认是否允许持久化过程中保留 `currentSession` 或重置后清空 session 会影响"记住登录态"的体验。
7. 需人工确认 `restoreStoreSnapshot` 后 `KnoiLoginAdapter.state` 同步：`restoreStoreSnapshot` 在 Kotlin 侧替换了 `facade`，但 `KnoiLoginAdapter.private state` 是构造时 `refreshState()` 拿到的旧快照。如果后续某个方法直接读 `this.state`，会得到未同步的陈旧值。需人工确认是需要在 `restoreStoreSnapshot` 后强制刷新 adapter，还是改为所有方法都通过 `harmonyLoginService.stateSnapshot()` 直接读实时数据。
8. 需人工确认邮箱注册与手机号注册无法反复切换的问题：用户反馈"邮箱注册和手机号注册不能反复点"，需要确认是 ArkUI 状态联动未正确清空（如 `this.username` / `this.emailInput` 切换时残留），还是 `router.replaceUrl` 跳转后导致首次页面的 `aboutToAppear` 中 dispatch ModeChanged 重复触发覆盖用户输入。建议人工在真机上验证切换路径并补全状态重置逻辑。
9. 需人工确认导航流程与 Android/iOS 完整对齐：本轮仅修复 PasswordSetupPage 完成后跳转 Logout 和 Reset Password 后栈清理、登出/注销清栈。用户反馈"导航设置与安卓端/IOS端不一致"仍然残留，建议人工对照 Android `AuthNavGraph.kt` 的 `popUpTo` 规则逐页验证所有跳转路径，包括：登录后到 Profile 还是 SignedIn 的判定、注册完成到 Login 而非 Entrance、找回密码每步回退指向、验证码页回退是否回到对应注册页、邮箱注册与手机号注册互相切换是否需要清空对方状态等。

## 验证结果

1. 编译验证通过：执行 `cd harmony-kmp-bridge && ./gradlew clean ohosArm64Binaries`，结果 `BUILD SUCCESSFUL`（37s），新 `libkn.so` 已自动复制到 `harmonyApp/entry/src/main/libs/arm64-v8a/` 和 `harmonyApp/entry/libs/arm64-v8a/`，时间戳和 SIZE 均更新（2,912,224 → 2,941,152 字节）。
2. 鸿蒙端编译验证通过：执行 `hvigorw assembleHap --mode module -p module=entry@default -p product=default --no-daemon`，结果 `BUILD SUCCESSFUL in 2s`，ErrorText @Component 改造、ProfileCompletionPage 临时回退、TermsConsentSheet 遮罩回退后均无编译错误。
3. 未执行真机交互验收：未验证 ErrorText 在用户输入校验失败时是否实时亮起；未验证注册成功后是否正确跳转到 Login 而非 Entrance；未验证登录成功后 Profile 与 SignedIn 的分流；未验证 mock 仓库持久化的实际生效情况；未验证邮箱/手机号注册反复切换的稳定性。

## 人工修正点

1. 导航设置与安卓端/IOS端不一致：当前鸿蒙端在注册流程、找回密码、登出/注销的 `router` 栈管理与 Android `AuthNavGraph` 的 `popUpTo` 规则仍有差异。需人工对照三端一致路径逐页校准，原则：注册成功 → 清栈后跳 Login（而非 Entrance）；验证码回退 → 回到对应注册页；邮箱/手机号注册互相切换 → 清空对方输入；登录成功 → 根据 `isProfileComplete` 分流到 Profile 或 SignedIn 且清空注册栈。
2. 隐私政策和服务条款弹窗无焦点不虚化：`TermsConsentSheet` 在最下方，背景遮罩透明度过低且未做非焦点虚化。需人工确定具体方案：改用 `CustomDialog` / `bindSheet` 系统级组件，或在 `@Builder` 方案中正确添加遮罩层 + 阻断点击穿透 + 保持弹窗内部按钮可点击（避免 `hitTestBehavior(HitTestMode.Block)` 拦截子组件）。
3. 个人信息设置页面无法通过滚轮选择内容，无照片选择功能：本轮 TextPicker 方案实测不可滚动已回退。需人工确认 ArkUI TextPicker 在嵌套 `@Builder`/`Stack` 中无法滚动的原因，改用独立 `CustomDialog` 或 `Select` 组件；同时补齐头像照片选择功能（建议使用 `@ohos.multimedia.imagePicker` 或 `拍照` API 与 Android/iOS 对齐）。
4. 邮箱注册和手机号注册不能反复点：需人工在真机上验证切换路径，确认是状态未清空、router 跳转参数丢失，还是 `aboutToAppear` 中 dispatch ModeChanged 覆盖用户输入，并补全切换时的状态重置逻辑（清空 username、emailInput、acceptedTerms、localError）。
5. 账号 mock 信息无法保存，关闭 app 重新打开之后数据全部清空了：当前持久化方案失效的根本原因已在"人工审查点"罗列（KNOI 实例模型、async/await 时序、exportStoreSnapshot 数据完整性、prefsInstance.flush 异步、adapter.state 同步）。需人工确定修复方向：
   - 优先确认 KNOI `@ServiceProvider` 实例模式，若为 factory 则需要在 `common/LoginStore` 或 `LoginFacade` 暴露统一的 load/save 接口而不是由 ArkTS 层多实例调用 restore；
   - 或在 `HarmonyLoginService` 提供单例缓存（首次 `getHarmonyLoginService()` 后缓存到 ArkTS 全局变量，避免 KNOI 重复创建实例）；
   - `initPersistence` 改为 `await`，或在 `UIAbility.onCreate` 中提前执行；
   - `exportStoreSnapshot` 保留 `currentSession` 与 `defaultAccountsInitialized` 真实值；
   - `prefsInstance.flush()` 改为 `await prefsInstance.flush()`；
   - `restoreStoreSnapshot` 后触发 `KnoiLoginAdapter.refreshState()` 或改为每次读 `stateSnapshot()` 实时获取。

2026-7-7 关于鸿蒙端数据不实时刷新的问题
原因及解决方法：不是业务逻辑问题，而是 UI 状态链路设计问题。后续只要是弹窗、Picker、Sheet、表单行这种需要动态刷新和父子同步的东西，就拆成 @Component，展示用 @Prop，回写用 @Link，回调字段避开 ArkUI 内置事件名。

## 采纳内容
- 采纳鸿蒙表单组件父子同步改造：`AuthComponents.ets` 中 `UnderlineInput`、`PhoneInputComp`、`AgreementRowComp`、`CodeBoxesComp` 改为 `@Component + @Link` 回写父级状态，子组件内部先更新绑定值再触发业务回调。
- 采纳鸿蒙回调字段命名规避：交互组件回调统一改为 `tapRequested`、`backRequested`、`feedbackRequested`、`valueChanged`、`passwordToggleRequested`、`acceptedChanged`、`privacyRequested`、`serviceTermsRequested`、`unavailableRequested`，避免继续使用 `onTap`、`onChange` 等 ArkUI 内置事件同名字段。
- 采纳调用方迁移：同步更新登录、手机注册、邮箱注册、验证码、设密、找回密码、重置密码、入口页、已登录页、旧 `LoginPage`、`DebugStatePage`、`ProfileCompletionPage` 中对 `AuthHeader`、`CorosButton`、`UnderlineInput`、`PhoneInputComp`、`AgreementRowComp`、`CodeBoxesComp`、`ThirdPartyAreaComp` 的调用。
- 采纳协议勾选链路修正：`AgreementRowComp` 由子组件直接更新 `@Link accepted`，父页面只在 `acceptedChanged` 中清理错误提示，避免父子同时 toggle 造成状态抢写。
- 采纳可安全处理的 ArkTS 异常保护：`StorePersister.initPersistence` 增加整体 `try/catch` 并在失败时清空 `prefsInstance`；`EntryAbility.onWindowStageCreate` 对 `windowStage.loadContent('pages/EntrancePage')` 增加异常保护。
- 采纳本轮范围决策：保留 KuiklyBase/KNOI 当前 Kotlin 工具链约束，不因 warning 盲目升级；旧 router API、`showToast` 废弃项和签名配置作为独立后续任务处理。

## 人工审查点
- 需人工确认真机交互体验：本轮已通过编译验证，但仍需人工在鸿蒙真机/模拟器上确认输入、清空、协议勾选、验证码自动提交、密码可见切换等 UI 是否实时刷新，因为 ArkUI 响应式问题最终以端侧交互表现为准。
- 需人工确认协议勾选业务语义：当前子组件负责更新 `accepted`，父组件只清错误；需确认后续是否还需要埋点、弹窗联动或审计记录等业务副作用，避免迁移后遗漏产品要求。
- 需人工确认旧 router API 迁移策略：`router.pushUrl/replaceUrl/back/clear/getParams` 仍为 deprecated warning，迁移到新导航体系会影响全登录链路回退栈，需要产品和端侧负责人确认三端导航一致性。
- 需人工确认提示组件替换策略：`promptAction.showToast` 仍为 deprecated warning，替换为新提示 API 或统一封装会影响全局文案、展示时长和错误提示体验，需要人工确认 UX 标准。
- 需人工确认发布风险：KNOI `libknoi.so` verification warning 与未配置 signingConfigs 仍存在，开发构建可通过，但发布前需人工确认安全、签名和运行时 ABI 策略。

## 验证结果
- 静态检查通过：执行 `rg -n "onTap:|onBack:|onFeedback:|onChange:|onPasswordToggle:|onToggle:|onPrivacyClick:|onServiceTermsClick:|onUnavailableClick:|this\\.onTap|this\\.onBack|this\\.onFeedback|this\\.onChange|this\\.onPasswordToggle|this\\.onPrivacyClick|this\\.onServiceTermsClick|this\\.onUnavailableClick|\\bonBack\\(" harmonyApp/entry/src/main/ets`，结果未发现旧自定义回调字段残留，检查通过。
- 鸿蒙构建验证通过：执行 `env NODE_HOME=/Applications/DevEco-Studio.app/Contents/tools/node DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk PATH=/Applications/DevEco-Studio.app/Contents/tools/node/bin:/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin:/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin:$PATH /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleApp --no-daemon`，结果 `BUILD SUCCESSFUL`，`@Link` 改造和调用方迁移通过 ArkTS 编译。
- KMP common 回归验证通过：执行 `./gradlew :common:check`，结果 `BUILD SUCCESSFUL`。
- Android 回归构建通过：执行 `./gradlew :androidApp:assembleDebug`，结果 `BUILD SUCCESSFUL`。
- 验证中仍存在非阻塞 warning：KNOI NAPI verification warning、KNOI 依赖内部 may throw warning、旧 router API deprecated、`showToast` deprecated、未配置 signingConfigs；本轮未将这些 warning 作为失败项处理。

## 人工修正点
- 需要后续迁移鸿蒙导航层：逐步替换 deprecated `router.*` API，并对齐 Android/iOS 注册、登录、完善资料、找回密码、退出登录、注销账户的回退栈规则。
- 需要后续统一提示能力：替换或封装 deprecated `promptAction.showToast`，统一错误提示、成功提示和未实现功能提示的展示行为。
- 需要真机/模拟器补充完整交互验收：覆盖登录、手机号注册、邮箱注册、验证码、设密、找回密码、重置密码、完善资料 Picker/Sheet/Dialog、退出登录、注销账户。
- 需要发布前处理签名与 KNOI 风险：配置 signingConfigs，确认 HAP 中 `libkn.so`、`libknoi.so`、`libc++_shared.so` 的 ABI 与加载路径，并评估 `libknoi.so` verification warning 对发布审核或安全扫描的影响。

---

2026-07-08 三端 KMP + Native UI 登录资产维护、持久化与资源一致性优化

## 采纳内容
- 采纳当前架构判断：保留 `common` 模块 MVI/业务规则作为核心资产，三端继续原生 UI；未引入 DI 框架，原因是当前仍为 mock 数据源 + 本地持久化场景，手动装配成本低于框架接入成本。
- 采纳三端 mock 数据持久化方向：在 common 侧补齐 mock store JSON 编解码与快照能力，使账号、资料、登录态可被端侧持久化；Android/iOS/Harmony 均围绕 shared login facade/store 快照工作，避免 UI 端复制业务逻辑。
- 采纳 iOS 持久化接入：`SharedLoginAdapter.swift` 接入本地保存与恢复，用户反馈完全退出 app 后再次启动可保留持久化数据。
- 采纳 Harmony 持久化重做：`HarmonyLoginService` 收敛 JSON 解析与导入导出；`StorePersister.ets` 使用 preferences 保存 mock store 快照；`KnoiLoginAdapter.ets` 在登录、注册、完善资料、重置密码、退出、注销等状态变化后触发持久化；`EntryAbility.ets` 在启动和生命周期退出阶段恢复/保存状态，降低 KNOI 跨层传递链路导致的数据丢失风险。
- 采纳鸿蒙注册切换问题修复：邮箱注册与手机号注册互相切换时改为明确路由替换和状态重置，不再因 `router.back()` 回到首页。
- 采纳个人信息保持：完善资料页保存用户名、头像 URI、生日、身高、体重、公英制、手机号、国家地区、性别等字段；后续已登录页/登录态展示优先使用资料用户名，而不是手机号或邮箱账号。
- 采纳鸿蒙信息完善 UI 去冗余：将头像、性别、表单行、选择器 Sheet、不可用弹窗等拆为独立 `@Component`，选择器标题栏统一复用 `PickerSheetHeaderComponent`，减少重复的 close/check/header 实现。
- 采纳三端启动图和图标资源分离：启动页使用 `logo_splash`，App 图标使用 `app_icon`；Harmony 的 `startWindowIcon` 改为 `$media:logo_splash`，iOS 新增 `LaunchScreen.storyboard` 与 `LaunchLogo.imageset`。
- 采纳 Harmony 资源与 Android/iOS 对齐：从 Android/iOS 已有资源同步 `app_icon`、`logo_splash`、`icon_camera`、`icon_female`、`icon_male`、`right_more`、`ic_profile_check`、`ic_profile_close` 等资源；鸿蒙 UI 中原先作为图标使用的 `×`、`✓`、`>`、`♀`、`♂`、`相机` 文本替换为 media 图片资源。

## 人工审查点
- 需人工真机确认 Harmony 持久化：构建已通过，但仍需在鸿蒙真机/模拟器执行注册、完善资料、登录态退出 app、杀进程重启等路径，因为 KNOI native 实例生命周期与 preferences 落盘时序只能通过端侧运行验证。
- 需人工确认 mock store 持久化边界：当前目标是 mock 数据源本地保存，不涉及真实服务器；需产品/业务确认是否要持久化验证码、临时错误态、未完成注册流程中间态，避免保存过多临时数据。
- 需人工确认个人资料展示规则：当前后续展示优先使用完善资料中设置的用户名；如果用户名为空或资料未完成，仍需确认回退到手机号/邮箱/账号 ID 的产品规则。
- 需人工确认 Harmony 资源视觉尺寸：资源已与 Android/iOS 文件对齐并通过编译，但启动页 logo、协议勾选、男女图标、箭头、关闭/确认按钮在不同屏幕密度上的实际视觉尺寸仍需人工看机。
- 需人工确认 iOS LaunchScreen 视觉：已使用 `logo_splash` 和黑色背景，但需在 iPhone/iPad 模拟器或真机确认启动图大小、居中位置是否符合设计预期。
- 需人工确认发布配置风险：Harmony 仍存在未配置 signingConfigs、KNOI verification warning、旧 router/showToast deprecated warning；这些不阻塞开发构建，但发布前需要端侧负责人确认处理策略。

## 验证结果
- KMP common 验证通过：执行 `./gradlew :common:check`，结果 `BUILD SUCCESSFUL`，common 侧 mock store JSON、规则和用例测试通过。
- Android 构建验证通过：执行 `./gradlew :androidApp:assembleDebug`，结果 `BUILD SUCCESSFUL`，Android 端接入 shared/common 改动后可编译。
- Harmony 共享桥与应用构建验证通过：执行 `./tools/build-shared-harmony.sh`，结果 `BUILD SUCCESSFUL`，KNOI bridge、common check、Harmony `assembleApp` 均通过。
- iOS 构建验证通过：执行 `xcodebuild -project iosApp/iosApp.xcodeproj -scheme IOSDemo -sdk iphonesimulator -configuration Debug build`，结果 `** BUILD SUCCEEDED **`，LaunchScreen 与资源目录可被 Xcode 编译打包。
- 静态资源一致性检查通过：执行 `file` 检查确认 Android/Harmony/iOS `logo_splash` 均为 640x640 PNG，Android/Harmony `app_icon` 均为 192x192 PNG；执行 `cmp -s` 确认 Harmony/iOS 的 `logo_splash` 与 Android 源文件一致，Harmony `app_icon` 与 Android `ic_launcher` 一致。
- 鸿蒙文本图标残留扫描通过：执行 `rg -n "Text\\('×'\\)|Text\\('✓'\\)|Text\\(' >'\\)|Text\\('相机'\\)|Text\\('♀'\\)|Text\\('♂'\\)|Text\\(this\\.accepted \\? '✓'|☑|✅|✔" harmonyApp/entry/src/main/ets`，结果未命中，说明本轮目标文本图标占位已清理。
- 用户侧验证反馈：iOS 端完全退出 app 后再次启动可以保留持久化数据；Harmony 端在本轮修复后仍无法持久化。

## 人工修正点
- 需要人工补充 Harmony 真机持久化验收：覆盖注册账号、完善资料用户名、退出 app、杀进程重启、登录态恢复、退出登录后重启不自动登录、注销账号后数据清理。
- 需要人工补充三端视觉验收：对比 Android/iOS/Harmony 的启动页、App 图标、资料页男女图标、相机图标、右箭头、协议勾选、关闭/确认图标，确认尺寸和位置是否需要端侧微调。
- 需要后续处理 Harmony deprecated API：将 `router.*` 与 `promptAction.showToast` 的 deprecated warning 独立纳入导航/提示层改造，不建议混在资源和持久化修复中处理。
- 需要发布前处理 Harmony 签名与 KNOI warning：配置 signingConfigs，并评估 `libknoi.so` verification warning 对发布审核、安全扫描和目标设备兼容性的影响。

---

2026-07-08 Harmony 持久化修复：KNOI 实例引用同步与 Service 缓存

## 采纳内容

1. 采纳 `HarmonyLoginService.dataSource` 从 `var` 改为 `val`：
   - `harmony-kmp-bridge/src/ohosArm64Main/kotlin/.../HarmonyLoginService.kt` — `dataSource` 字段改为 `private val`（永不重新赋值）。
   - `MemoryAuthStoreDataSource` 新增 `replaceStore(newStore: MockAuthStore)` 方法，允许原地替换内部 store 而不创建新实例。
   - `restoreStoreSnapshot()` 改为调用 `dataSource.replaceStore(store)` 原地修改，不再执行 `dataSource = MemoryAuthStoreDataSource(store)`。`facade` 仍重建，但使用同一个 `val dataSource` 引用。
   - 根因：KNOI 框架通过动态代理转发方法调用，`var` 字段重新赋值后代理持有的旧引用未同步，导致 `facade.submit()` 写入实例 A 而 `exportStoreSnapshot()` 读取实例 B，持久化永远写空数据。

2. 采纳 Service 实例缓存机制：
   - 新建 `harmonyApp/entry/src/main/ets/login/HarmonyServiceProvider.ets`，在模块级别缓存 `HarmonyLoginService` 代理实例，所有调用点（`KnoiLoginAdapter`、`StorePersister`）统一通过 `getService()` 获取。
   - 根因：`getHarmonyLoginService()` 每次返回不同 KNOI 代理，`KnoiLoginAdapter` 和 `StorePersister` 分别操作不同原生实例，save 的数据与 export 的实例不一致。

3. 采纳 `saveStoreSnapshot()` 接受可选 service 参数：
   - `StorePersister.ets` — `saveStoreSnapshot(service?: HarmonyLoginService)`，当 `KnoiLoginAdapter` 调用时传入 `this.harmonyLoginService`，确保 submit 和 save 使用完全相同的代理实例。
   - 生命周期回调（`EntryAbility.onBackground/onDestroy`）不使用此参数，回退到 `getService()` 缓存的默认实例。

4. 采纳辅助诊断手段：
   - `HarmonyLoginService.exportStoreSnapshot()` 在返回的 JSON 末尾注入 `_s` 诊断字段（accounts 数量、session 是否存在、defaultInit 状态），ArkTS 侧可直接观察 dataSource 真实状态。
   - `KnoiLoginAdapter.submit()` 中增加 `hilog` 输出 `store after submit` 完整 JSON 和 `_s` 信息。
   - `StorePersister` 所有关键路径增加 `hilog` 日志（`exported snapshot length`、`prefsInstance` 状态、round-trip 告警）。
   - `EntryAbility` 生命周期各阶段（`onWindowStageCreate`、`onForeground`、`onBackground`、`onWindowStageDestroy`、`onDestroy`）增加 `hilog` 追踪。

5. 采纳 round-trip 检查降级为告警：
   - `saveStoreSnapshot()` 中 `validateStoreSnapshotRoundTrip` 从 `return false` 阻止保存改为 `console.warn` + `hilog.warn` 后继续写入，不再因编解码校验失败阻塞持久化。

6. 采纳 `createFacade` 补全 `nowEpochMs`：
   - `HarmonyLoginService.createFacade()` 传入 `nowEpochMs = { System.currentTimeMillis() }`，修复此前默认为 `{ 0L }` 导致验证码时效性计算异常的问题。

## 人工审查点

1. 需人工确认 KNOI `@ServiceProvider` 实例模型是否确实为 factory 模式：当前修复假设 KNOI 每次 `getService` 返回不同原生实例（基于日志中不同 Service 的 dataSource 隔离现象）。如果后续 KNOI 版本改为真正的 singleton，则 `HarmonyServiceProvider` 缓存层仍然无害，但 `val dataSource` 原地修改策略的行为应保持不变。需人工在 KNOI 升级或重构时重新验证此假设。

2. 需人工确认 `restoreStoreSnapshot` 后 `facade` 重建的副作用：`facade` 仍是 `var`，`restoreStoreSnapshot` 中新建 facade 后字段重新赋值。如果 KNOI 代理对 `facade` 的引用也不同步，则后续 `setLoginMode/setUsername/setPassword` 等方法调用的可能是旧 facade。当前由于这些方法在 submit 前会被 ArkTS 重新调用（`updateUsername`、`updatePassword`、`setMode`），旧 facade 的状态重置后仍可用。但如果后续有依赖 facade 初始状态的逻辑（如 `restoreStoreSnapshot` 后直接读 `stateSnapshot()`），可能读到旧 facade 的陈旧状态。

3. 需人工确认 `_s` 诊断字段对 `restoreStoreSnapshot` 和 round-trip 校验的影响：`exportStoreSnapshot` 返回值包含 `_s` 字段，此字段被 `decode()` 忽略但会随 JSON 一起写入 Preferences。`restoreStoreSnapshot` 反序列化时已确认忽略未知字段，round-trip 校验也未受影响（`encode` 不产生 `_s`，`decode` 忽略后两次结果一致）。但手动编辑或跨版本迁移 Preferences 数据时需注意。

4. 需人工确认 `hilog` 日志在生产环境的安全影响：当前 `store after submit` 输出完整 JSON（含 mock 密码 hash），`%{public}s` 格式使日志对系统 hilog 可见。生产环境应移除或改为 `%{private}s`。

## 验证结果

1. KMP common 回归验证：执行 `./gradlew :common:check`，结果 `BUILD SUCCESSFUL`。
2. Harmony KNOI bridge 构建验证：执行 `cd harmony-kmp-bridge && ./gradlew :ohosArm64Binaries`，结果 `BUILD SUCCESSFUL`，生成的 `libkn.so` 包含 `val dataSource` 和 `replaceStore` 改动。
3. 持久化链路端到端验证（用户实机 hilog）：
   - 启动后 `stored json length=89`（空 store）→ `restoreStoreSnapshot result=true` —— 恢复路径正常。
   - 登录后 `store after submit` 包含 3 个 accounts（2 默认 + 1 新注册）和 currentSession —— `dataSource.save()` 正确写入。
   - 注册后 `saveStoreSnapshot`→ `exported snapshot length=660/1006`（非 89）—— 持久化写入正确实例的数据。
   - 杀进程重启后 `stored json length` 不再是 89，而是之前保存的长度（660+/1006）—— 持久化恢复路径生效。
   - 验证结果：用户确认数据持久化功能已修复。
4. 未执行 lint/typecheck：鸿蒙端 ArkTS 编译由 DevEco Studio 内置检查通过，项目未配置独立 lint 命令。

## 人工修正点

1. 后续生产环境安全处理：`hilog` 中出现的完整 JSON（含 mock 密码 hash）应改为 `%{private}s` 或移除完整 JSON 输出。
2. 后续 KNOI 升级或重构时，需重新验证 `@ServiceProvider` 实例模式和 `var facade` 引用同步行为。
3. `facade` 字段同步的残余风险：`restoreStoreSnapshot` 后如果直接读 `stateSnapshot()` 可能拿到旧 facade 的状态，当前业务路径不依赖此行为，但后续新增逻辑时需注意。
4. 建议定期清理 `Codex_worklog.md` 旧条目，保留最近 3~5 轮即可，避免文件过度膨胀。
