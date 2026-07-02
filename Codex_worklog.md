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
