# Android 个人资料编辑 Activity Result 兼容性 Spec

## 元数据

- Spec ID：`ANDROID-PROFILE-ACTIVITY-RESULT`
- 状态：已采纳
- 适用范围：Android “我”页进入个人资料编辑页，以及该页相册/相机 Activity Result 入口

## 目标

- 已登录用户点击“我”页资料区域后能够稳定进入个人资料编辑页，不因 Activity Result owner 缺失闪退。
- 个人资料编辑页可以安全注册相册与相机 launcher。
- Android 本地化 Context 边界保持 Activity Result 宿主能力。

## 非目标

- 不改变个人资料字段、保存规则、头像文件格式或 KMP 业务模型。
- 不修改 iOS SwiftUI 或 HarmonyOS ArkUI 的资料编辑实现。
- 不升级 Activity Compose、Compose BOM、Navigation Compose、Kotlin 或其他依赖。

## 边界与依赖约束

### `ANDROID-PROFILE-AR-001` Activity Result owner

由 `ComponentActivity.setContent` 承载的 Android Composition 在 `ProvideAppLanguage` 覆盖本地化 `LocalContext` 后，仍必须能够取得非空的 `LocalActivityResultRegistryOwner`；个人资料编辑页注册 `rememberLauncherForActivityResult` 时不得抛出 `IllegalStateException`。

### `ANDROID-PROFILE-AR-002` 本地化 Context owner 透传

`ProvideAppLanguage` 创建并向下提供 `ConfigurationContext` 前，必须读取宿主 Composition 的 `LocalActivityResultRegistryOwner`；若 owner 存在，替换 `LocalContext` 后必须在同一子树继续显式提供该 owner。预览等无 Activity Result owner 的宿主继续允许组合，不强制构造伪 owner。修复只作用于 `androidApp`，不向 `commonMain`、iOS 或 HarmonyOS 引入 AndroidX 类型或依赖。

### `ANDROID-PROFILE-AR-003` 页面行为保持

点击“我”页资料卡片或资料完成状态文字后进入现有个人资料编辑界面；返回、保存、相册选择和相机入口的既有交互保持不变。

## 异常行为

- 如果 Composition 无法取得 `ActivityResultRegistryOwner`，自动化回归测试必须失败，不能通过捕获异常或禁用头像入口掩盖问题。
- 不允许在业务页面手工构造独立 `ActivityResultRegistry` 规避宿主生命周期。

## 验收标准

- Android 仪器测试验证 `MainActivity` 的 Composition 经 `ProvideAppLanguage` 后仍能取得 `LocalActivityResultRegistryOwner`，并能完成两个资料头像 launcher 的注册。
- `./gradlew :androidApp:assembleDebug` 通过。
- 模拟器中点击“我”页资料区域可进入编辑页，日志中不再出现本 Spec 对应的 `FATAL EXCEPTION`。
- `./gradlew :common:check` 通过，证明共享业务层没有因 Android 依赖修复产生回归。

## 测试要求

- 自动化测试名保持稳定：`profileActivityResultLaunchersCanRegisterInMainActivityComposition`。
- 实现前先以当前依赖运行该测试并确认红灯。
- 实现后重新运行同一测试，并完成 Android APK 构建和模拟器人工点击验证。
