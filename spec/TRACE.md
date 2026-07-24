# Spec → Code 追溯映射

此文件是 SDD 规格驱动开发的核心索引，将每个 Spec 条目映射到具体代码位置。
新功能开发时：**先写 Spec → 在 TRACE.md 预留映射行 → 写测试 → 写实现 → 更新状态**。

---

## sdd-workflow.md 追溯

| Spec ID | 规范 | 测试/验证 | 实现/文档 | 状态 |
|---------|------|-----------|-----------|------|
| `SDD-001` | 会话预检 | `tools/check-sdd.sh`：核心入口与流程标记检查 | `AGENTS.md`、`spec/SESSION_START.md` | ✅ |
| `SDD-002` | 先定义 Spec | `tools/check-sdd.sh`：模板固定章节检查 | `spec/README.md`、`spec/TEMPLATE.md` | ✅ |
| `SDD-003` | 预留 TRACE 映射 | 本轮在实现前以 `⏳` 预留本表，完成后人工核对 | `spec/TRACE.md` | ✅ |
| `SDD-004` | 测试是可执行 Spec | `bash ./tools/check-sdd.sh`：首次 30 项红灯，最终绿灯 | `tools/check-sdd.sh`、`AGENTS.md` | ✅ |
| `SDD-005` | 最小实现 | `./tools/check-sdd.sh` | `AGENTS.md`“强制 SDD 顺序” | ✅ |
| `SDD-006` | 完成追溯 | `./tools/check-sdd.sh`：规范 ID 与映射检查 | 本文件、`spec/README.md` | ✅ |
| `SDD-007` | 更新 Worklog | `tools/check-sdd.sh`：真实时间标题、历史补录标题和每轮四段顺序检查 | `Codex_worklog.md`、`AGENTS.md`、`spec/SESSION_START.md` | ✅ |
| `SDD-008` | 提炼 Learnings | `./tools/check-sdd.sh`：治理章节检查 | `LEARNINGS.md`“SDD 治理约定” | ✅ |
| `SDD-009` | 关闭门禁 | `bash -n ./tools/check-sdd.sh`；`./tools/check-sdd.sh` | `AGENTS.md`、`docs/development-workflow.md`、`README.md` | ✅ |
| `SDD-010` | 三端同步原则 | 代码审查：所有 UI 结构/行为变更涉及三端 | `AGENTS.md`、`LEARNINGS.md`、`spec/sdd-workflow.md` | ✅ |

---

## documentation-governance.md 追溯

| Spec ID | 规范 | 测试/验证 | 实现/文档 | 状态 |
|---------|------|-----------|-----------|------|
| `DOC-001` | 实现与历史保护 | `tools/check-docs.sh` + worklog SHA-256 `eb13…f530` | `AGENTS.md`、`docs/README.md` | ✅ |
| `DOC-002` | 根目录信息架构 | `./tools/check-docs.sh` | `README.md` | ✅ |
| `DOC-003` | docs 三层集合 | `./tools/check-docs.sh` + 分类目录检查 | `docs/README.md`、`docs/reference/`、`docs/archive/`、`docs/worklog/` | ✅ |
| `DOC-004` | 参考与归档分类 | 分类路径、导航和恢复文件哈希检查 | `docs/reference/README.md`、`docs/archive/README.md` | ✅ |
| `DOC-005` | 资源源文件保护 | `./tools/check-docs.sh`：两组源资源目录存在 | 两个 `*_resources/` 目录及映射文档 | ✅ |
| `DOC-006` | 契约与工具去占位 | `./tools/check-docs.sh`：实际契约保留、空占位消失 | `contract/README.md`、`tools/README.md` | ✅ |
| `DOC-007` | 平台说明就近维护 | 当前引用扫描 + `git diff --name-only` | `iosApp/README.md`、`harmonyApp/README.md`、`harmony-kmp-bridge/README.md` | ✅ |
| `DOC-008` | 测试事实同步 | `tools/check-docs.sh` 动态核对 `@Test`：31/8/4/39，合计 82 | `TEST_REPORT.md`、本文件 | ✅ |
| `DOC-009` | 可执行文档门禁 | 首次 31 项红灯；最终 `bash -n`、`check-docs`、`check-sdd`、`git diff --check` 通过 | `tools/check-docs.sh` | ✅ |
| `DOC-010` | 误删文档完整恢复 | `tools/check-docs.sh`：10份目标文件 SHA-256 与 Git 恢复源逐一一致 | `docs/reference/`、`docs/archive/harmonyos-kmp/` | ✅ |
| `DOC-011` | 恢复后的目录归类 | `find docs` + 分类导航检查 | `docs/README.md`、三个分类 README | ✅ |
| `DOC-012` | 参考与归档保护门禁 | `bash -n tools/check-docs.sh`；红灯17项后最终绿灯 | `tools/check-docs.sh` | ✅ |

---

## auth-mock-spec.md 追溯

| Spec 章节 | 对应代码位置 | 状态 |
|-----------|-------------|------|
| **§1 模块定位** | `common/src/commonMain/kotlin/.../login/` 全部 | ✅ |
| **§2 安全边界** | 全线遵守；Proto → `common/.../proto/auth_mock.proto` | ✅ |
| **§3 Protobuf 结构定义** | `common/.../proto/auth_mock.proto`；Kotlin 镜像类 `LoginModels.kt:60-91` | ✅ |
| **§4 本地会话模型** | 接口 `AuthRepository.kt:21-45`；实现 `AuthRepository.kt:47-509` | ✅ |
| **§5 本地 mock 结果** | `MockResult` → `LoginModels.kt:122-125`；`MockError` → `LoginModels.kt:134-147` | ✅ |
| **§6 注册区域** | `AuthRepository.kt:485-488`（DefaultRegions）；`LoginModels.kt:35-48`（AuthRegion） | ✅ |
| **§7 验证码** | `requestVerifyCode()` → `AuthRepository.kt:62-94`；`verifyCode()` → `AuthRepository.kt:96-108`；`verifyCodeRemainingSeconds()` → `AuthRepository.kt:110-116` | ✅ |
| **§8 注册** | `register()` → `AuthRepository.kt:331-374`；`RegisterUseCase` → `LoginUseCase.kt:39-58`；`validateRegister()` → `AuthRepository.kt:433-452` | ✅ |
| **§9 登录** | `login()` → `AuthRepository.kt:376-412`；`LoginUseCase` → `LoginUseCase.kt:6-37` | ✅ |
| **§10 登出** | `clearSession()` → `AuthRepository.kt:182-189` | ✅ |
| **§11 会话失效** | `markSessionExpired()` → `AuthRepository.kt:191-204`；`verifyBusinessAccess()` → `AuthRepository.kt:414-417` | ✅ |
| **§12 本地状态保存** | `MockAuthStoreJson` → `MockAuthStoreJson.kt` 全部；`JsonAuthStoreDataSource` → `MockAuthStoreJson.kt:502-514` | ✅ |
| **§13 验收标准** | 参见下方测试追溯 | ✅ |
| **§14 单元测试要求** | | |
| §14.1 注册成功 | `LoginUseCaseTest.kt:11-22`（registerSuccessSavesSessionAndCanBeRestored） | ✅ |
| §14.2 重复注册失败 | `LoginUseCaseTest.kt:25-33`（duplicateRegisterFails） | ✅ |
| §14.3 验证码错误 | `LoginUseCaseTest.kt:36-52`（invalidVerifyCodeFails） | ✅ |
| §14.4 登录成功 | `LoginUseCaseTest.kt:139-149`（loginSuccessSavesSession） | ✅ |
| §14.5 密码错误 | `LoginUseCaseTest.kt:257-266`（incorrectPasswordFails） | ✅ |
| §14.6 未登录访问业务数据 | `LoginUseCaseTest.kt:343-350`（businessAccessRequiresLogin）；`BusinessMockDataSourceTest.kt:42-47`（anonymousUserCannotReadBusinessMockData） | ✅ |
| §14.7 登出后访问业务数据 | `BusinessMockDataSourceTest.kt:20-29`（loggedOutUserCannotReadBusinessMockData） | ✅ |
| §14.8 会话失效后访问业务数据 | `BusinessMockDataSourceTest.kt:31-40`（expiredSessionCannotReadBusinessMockData） | ✅ |
| §14.9 本地登录态保存和恢复 | `LoginUseCaseTest.kt:381-398`（localSessionCanBeRestoredAfterLogin） | ✅ |

---

## health-dashboard-cards.md 追溯

| Spec 章节 | 对应代码位置 | 状态 |
|-----------|-------------|------|
| **项目目标** | `common/src/commonMain/kotlin/.../health/` 全部 | ✅ |
| **实现范围 - mock 数据源** | `HealthDashboardModels.kt:19-32`（DailySummary, SleepSummary, TrainingLoad, Recovery） | ✅ |
| **实现范围 - 卡片类型** | `HealthDashboardModels.kt:5-9`（HealthCardType） | ✅ |
| **实现范围 - 排序策略** | `HealthDashboardUseCase.kt:90-91`（sortedWith compareBy priority） | ✅ |
| **实现范围 - UI model** | `HealthDashboardModels.kt:51-59`（HealthCardUiModel） | ✅ |
| **实现范围 - mock 场景** | `HealthDashboardModels.kt:3`（HealthMockScenario）；`HealthDashboardUseCase.kt:22-73`（sample 各场景数据） | ✅ |
| **验收标准** | 参见下方测试追溯 | ✅ |
| **测试要求 - 12 条以上** | `HealthDashboardUseCaseTest.kt` → **39 条测试** | ✅ |
| 测试：全量数据 | `HealthDashboardUseCaseTest.kt:17`（normalScenarioShowsCompleteCardCatalog） | ✅ |
| 测试：睡眠缺失 | `HealthDashboardUseCaseTest.kt:19`（partialMissingShowsSleepEmptyCard） | ✅ |
| 测试：今日运动缺失 | `HealthDashboardUseCaseTest.kt:20`（partialMissingKeepsAvailableTodayActivity） | ✅ |
| 测试：恢复状态异常 | `HealthDashboardUseCaseTest.kt:7`（abnormalRecoveryIsFirst） | ✅ |
| 测试：卡片排序 | `HealthDashboardUseCaseTest.kt:26`（cardsUseStablePriorityOrder） | ✅ |

---

## common-training-requirements.md 追溯

| Spec 章节 | 对应代码位置 | 状态 |
|-----------|-------------|------|
| **§2 安全边界** | 全线：proto 文件、无真实数据/接口 | ✅ |
| **§3 技术栈与架构** | KMP `common/` 模块、Android Compose、iOS SwiftUI、HarmonyOS ArkUI | ✅ |
| **§4 注册登录前置** | 整个 `common/.../login/` 模块 + 三端适配 | ✅ |
| §4 验收脚本 1（注册保存 AuthSession） | `AuthRepository.kt:331-374`（register） | ✅ |
| §4 验收脚本 2（登录后业务可读） | `BusinessMockDataSourceTest.kt:9-18` | ✅ |
| §4 验收脚本 3（密码/验证码/账号不存在的错误态） | `LoginUseCaseTest.kt:257-266`（密码错误）；`LoginUseCaseTest.kt:36-52`（验证码错误）；`LoginUseCaseTest.kt:343-350`（未登录） | ✅ |
| §4 验收脚本 4（登出后业务不可读） | `BusinessMockDataSourceTest.kt:20-29` | ✅ |
| §4 验收脚本 5（会话失效引导重新登录） | `BusinessMockDataSourceTest.kt:31-40` | ✅ |
| §4 验收脚本 6（单测通过，无真实数据） | `TEST_REPORT.md`；代码无真实 token/接口 | ✅ |
| **§6 统一交付物** | 所有文档均已创建 | ✅ |
| **§7 Codex 协作** | `Codex_worklog.md` → 本 TRACE.md 提供 Spec 索引 | ✅ |

---

## resource-localization.md 追溯

| Spec ID | 规范 | 测试/验证 | 实现/文档 | 状态 |
|---------|------|-----------|-----------|------|
| `RES-LOC-001` | 共享认证层输出稳定语义键 | `LoginRulesTest.validationFailuresExposeStableLocalizationKeys`；`./gradlew :common:check` | `AuthMessageKeys.kt`、`LoginModels.kt`、`LoginRules.kt`、`LoginUseCase.kt`、`LoginStore.kt` | ✅ |
| `RES-LOC-002` | Android 原生字符串资源解析 | `./tools/check-resources.sh`；`./gradlew :androidApp:assembleDebug` | `values/strings.xml`、`values-en/strings.xml`、`AuthLocalization.kt`、认证错误与 Snackbar 展示入口 | ✅ |
| `RES-LOC-003` | iOS String Catalog 解析 | `./tools/check-resources.sh`；iOS simulator `xcodebuild` | `Localizable.xcstrings`、`AppResources.swift`、认证错误与 Snackbar 展示入口、Xcode Resources phase | ✅ |
| `RES-LOC-004` | HarmonyOS 限定词资源解析 | `./tools/check-resources.sh`；`hvigorw assembleApp --no-daemon` | `base/element/string.json`、`en_US/element/string.json`、`AuthLocalization.ets`、认证错误与 Toast 展示入口 | ✅ |
| `RES-LOC-005` | 资源一致性门禁 | 实现前首次运行失败；认证静态键加入后门禁先因误判“未映射”红灯，修正职责边界后通过：23 个共享消息键完整、三端全部 `auth_*` 资源集合一致 | `tools/check-resources.sh`、`tools/README.md` | ✅ |
| `RES-LOC-006` | 设计源与运行资源边界不变 | `./tools/check-docs.sh`；`git diff --name-only` 人工核对 | `docs/resource-management.md`；两组设计源和既有图片/视频/Lottie 路径未迁移 | ✅ |

---

## resource-maintainability.md 追溯

| Spec ID | 规范 | 测试/验证 | 实现/文档 | 状态 |
|---------|------|-----------|-----------|------|
| `RES-MAINT-001` | 全资源机器可读清单 | `./tools/check-resource-maintainability.sh`：JSON 格式、重复集合检查 | `tools/resource-inventory.json`、`docs/resource-inventory.md` | ✅ |
| `RES-MAINT-002` | 共享图片跨端存在性 | 门禁扫描 Android drawable/mipmap、iOS imageset、HarmonyOS media | 37 个共享语义图片名 | ✅ |
| `RES-MAINT-003` | 共享 Raw 内容一致 | 门禁校验三端 `home.mp4`、`watch_status.json` SHA-256 | 三端原生 Raw/Bundle 目录 | ✅ |
| `RES-MAINT-004` | 硬编码资源债务只降不升 | 门禁核对 4 组文案、3 组颜色计数不高于基线 | 生产源码三端文案/颜色上限均为 0；common 国家领域值上限为 7；Token 定义和 HarmonyOS 非发布调试页使用精确路径排除 | ✅ |
| `RES-MAINT-005` | 消除纯硬编码资源包装 | 资源清单扩展时先因 81 个键缺失红灯；`AppText` 引用扫描、三端构建及最终门禁通过 | 三端 192 个共享文字键已接入原生资源；认证、资料、账户、导航、健康和法律生产模块不再依赖纯硬编码文字包装 | ✅ |
| `RES-MAINT-006` | 可执行资源维护门禁 | 首次因清单缺失红灯；实现后 `./tools/check-resource-maintainability.sh` 绿灯 | `tools/check-resource-maintainability.sh`、`tools/README.md` | ✅ |
| `RES-MAINT-007` | 法律正文结构化内容资源 | 资源键缺失红灯；三端资源一致性门禁与平台构建通过 | `legal_privacy_body`、`legal_service_terms_body`；三端 `LegalContent` 轻量结构解析器和法律页面 | ✅ |
| `RES-MAINT-008` | 健康结构化本地化契约 | `HealthDashboardUseCaseTest.healthUiModelsExposeLocalizationKeysAndTypedArguments` 先因 `key/arguments` 缺失红灯，实施后通过；三端构建通过 | `LocalizedTextSpec`、`HealthDashboardUseCase`、三端 `HealthLocalization` 展示入口、KNOI 健康 JSON 桥接 | ✅ |
| `RES-MAINT-009` | 调试资源与生产债务分离 | `./tools/check-resource-maintainability.sh` 校验唯一调试排除路径；HarmonyOS Debug 构建仍通过 | `resource-inventory.json.debtExclusions`；`DebugStatePage.ets` 原样保留且不进入共享资源 | ✅ |
| `RES-MAINT-010` | 有限语义视觉 Token | 直接颜色扫描降至 Android/iOS/HarmonyOS 生产源码均为 0；三端构建通过 | Android `AppColors/AppTypography/AppSpacing`、iOS `AppColors/AppTypography/AppSpacing`、HarmonyOS `AppColors/AppTypography/AppSpacing` | ✅ |

---

## app-language-switching.md 追溯

| Spec ID | 规范 | 测试/验证 | 实现/文档 | 状态 |
|---------|------|-----------|-----------|------|
| `APP-LANG-001` | 应用语言状态统一且持久化 | `./tools/check-resources.sh`；三端构建 | Android `AppLanguage.kt`、iOS `AppLanguageStore`、HarmonyOS `AppLanguage.ets`；均默认 `zh-Hans` 并使用原生偏好存储 | ✅ |
| `APP-LANG-002` | Entrance 与“我”页共享语言选择行为 | 资源门禁静态入口检查；三端构建 | Android `LanguageSelection.kt`、iOS `LanguageSelectionButton`、HarmonyOS 两页 `LanguageDialog`；平台原生地球图标 | ✅ |
| `APP-LANG-003` | 选择后全应用即时刷新 | Android/iOS/HarmonyOS 构建；运行时人工点击与重启待设备验收 | Android CompositionLocal 资源上下文、iOS selected Bundle + ObservableObject、HarmonyOS preferred language + StorageLink version | ✅（人工运行待验收） |
| `APP-LANG-004` | 国家与地区持久化稳定代码 | `LoginRulesTest.registrationRegionAndLegacyNamesNormalizeToCountryCodes` 首次因符号缺失红灯，实施后通过；`LoginUseCaseTest.mockStoreJsonReadsLegacyAndroidSnakeCaseSnapshot` | `toProfileCountryCode`、`MockAuthStoreJson`、`AuthRepository.saveProfile`；三端资料选择器保存代码、展示资源名称 | ✅ |
| `APP-LANG-005` | 三端资源集合继续一致 | `check-resources.sh`、`check-resource-maintainability.sh`、三端构建 | 共享文字清单 196 键；新增 4 个 `language_*` 键；common 中文债务 0 | ✅ |
| `APP-LANG-006` | iOS 当前页面即时响应语言状态 | `./tools/check-resources.sh` 首次准确报告 Entrance/“我”页/底部导航缺少观察契约，实施后通过；iOS simulator `xcodebuild` 通过；运行时两入口人工点击待复验 | iOS `EntranceView`、`AccountView`、`MainTabsView` 观察并读取同一 `AppLanguageStore.current`，不重建协调器或导航树 | ✅（运行时待验） |
| `APP-LANG-007` | Entrance 语言入口跨端位置对齐 | `./tools/check-resources.sh` 首次准确报告两端顶部栏契约缺失，实施后通过；iOS/HarmonyOS 构建通过；最终截图人工对比待复验 | iOS `EntranceTopBar` + 36pt 底部留白；HarmonyOS `EntranceTopBar` 全宽 Logo/尾部语言按钮布局 | ✅（截图待验） |
| `APP-LANG-008` | Android Compose 资源读取响应配置变化 | `./gradlew :androidApp:lintDebug` 红灯：1 个 `LocalContextConfigurationRead`、8 个 `LocalContextGetResourceValueCall`；实施后 `lintDebug` 与 `assembleDebug` 均通过 | `AppLanguage.kt` 使用 `LocalConfiguration`；`AuthNavGraph.kt`、`AuthComponents.kt` 与 `AuthLocalization.kt` 使用 `LocalResources`/`Resources` | ✅ |

---

## android-profile-activity-result.md 追溯

| Spec ID | 规范 | 测试/验证 | 实现/配置 | 状态 |
|---------|------|-----------|-----------|------|
| `ANDROID-PROFILE-AR-001` | `MainActivity` Composition 提供 Activity Result owner，资料页 launcher 可注册 | `ProfileActivityResultOwnerTest.profileActivityResultLaunchersCanRegisterInMainActivityComposition`：实施前在两台模拟器精确红灯，实施后两台均通过 | `ProvideAppLanguage` 捕获并透传 `LocalActivityResultRegistryOwner` | ✅ |
| `ANDROID-PROFILE-AR-002` | 本地化 Context 显式透传 Activity Result owner，不影响共享层和其他端 | `./gradlew :common:check :androidApp:assembleDebug` 通过；Activity Compose 版本保持不变 | Android `AppLanguage.kt`；`common`、iOS、HarmonyOS 无实现或依赖变更 | ✅ |
| `ANDROID-PROFILE-AR-003` | “我”页资料区域进入编辑页且无崩溃 | emulator-5556 使用本地 mock 账号点击“我”→“资料已完善”，编辑页显示且进程存活；清空后的 `AndroidRuntime` 日志无新崩溃 | `SignedInScreen`、`PersonalProfileEditScreen` 既有行为保持 | ✅ |

---

## 测试总览

| 测试类 | 测试数 | 所属 Spec |
|--------|--------|-----------|
| `LoginRulesTest.kt` | 8 | auth-mock-spec §7, §8, §9；RES-LOC-001 |
| `LoginUseCaseTest.kt` | 31 | auth-mock-spec §14 |
| `BusinessMockDataSourceTest.kt` | 4 | auth-mock-spec §10, §11, §14 |
| `HealthDashboardUseCaseTest.kt` | 39 | health-dashboard-cards 测试要求；RES-MAINT-008；HLTH-VIS-001~003、027~032；HLTH-PERSIST-001~007 |
| **合计** | **82** | |

---

---

## health-dashboard-visual-cards.md 追溯

| Spec ID | 规范 | 测试/验证 | 实现/文档 | 状态 |
|---------|------|-----------|-----------|------|
| `HLTH-VIS-001` | protobuf 与 domain 提供完整可视化字段契约 | `HealthDashboardUseCaseTest.normalScenarioProvidesFigmaVisualData`；`:common:check` | `health_dashboard_mock.proto`、`HealthDashboardMock.kt`、`HealthDashboardModels.kt` | ✅ |
| `HLTH-VIS-002` | common 输出类型化可视化 UI 数据 | `HealthDashboardUseCaseTest.cardsExposeStableVisualKinds`；`:common:check` | `HealthCardVisualData`、`HealthDashboardUseCase` visual builders | ✅ |
| `HLTH-VIS-003` | 默认首页包含 Figma 今日运动卡 | `HealthDashboardUseCaseTest.defaultOrderIncludesTodayActivityBeforeWeeklyPlan` | `DefaultHealthCardOrder`、三端默认卡目录 | ✅ |
| `HLTH-VIS-004` | 三端按 visual kind 渲染专用数据卡 | `:androidApp:assembleDebug`；`xcodebuild ... IOSDemo ... build`；`hvigorw assembleApp` | `DashboardCard.kt`、`HealthDashboardView.swift`、`DashboardCardComp.ets` | ✅ |
| `HLTH-VIS-005` | HarmonyOS 桥接传递可视化数据 | `hvigorw assembleApp --no-daemon`（含 bridge 重建） | `HarmonyLoginService.healthSnapshotJson`、`HealthVisualData` | ✅ |
| `HLTH-VIS-006` | 体型管理使用 Figma 原始人体资产 | 三端 PNG SHA-256 一致；三端构建通过 | `health_body_front.png`、`health_body_back.png` 三端资源 | ✅ |
| `HLTH-VIS-007` | 无 Figma 动效稿时保持静态终态 | 三端代码审查与构建；Figma motion inventory 为空 | 三端 visual renderer 直接按共享数据绘制终态 | ✅ |
| `HLTH-VIS-008` | Android 无参数文案不得进入格式化路径 | `HealthLocalizationTest.percentUnitWithoutArgumentsDoesNotEnterFormatter`；emulator-5556 冷启动后进程存活且无 `AndroidRuntime` 异常 | `Resources.localizedHealthText`、`HealthLocalization.kt` | ✅ |
| `HLTH-VIS-009` | 卡片采用 Figma 2031 分状态几何与安全区 | `tools/check-health-card-fidelity.sh`；emulator-5556 顶部/中部/底部截图核对 | 三端内容驱动 renderer、周标签资源与固定图表安全区 | ✅ |
| `HLTH-VIS-010` | 右侧概览图使用受约束分栏并裁剪 | Android emulator-5556 全列表滚动截图；`hvigorw assembleApp --no-daemon`；专项结构门禁 | 三端 overview/gauge/trend/range/sleep/body 固定安全区与父级 clip | ✅ |
| `HLTH-VIS-011` | 三端使用同源 COROS 数值字体 | 专项门禁验证三端 Bold/Regular SHA-256 一致；Android/iOS/HarmonyOS 构建通过 | 三端字体文件、Android `CorosFontFamily`、SwiftUI `Font.custom`、ArkUI `font.registerFont` | ✅ |
| `HLTH-VIS-012` | 卡片图标与缩略图使用可追溯原始资源 | 地图三端 SHA-256 `87b98b5d...c8123f9`；`check-resource-maintainability.sh` | 三端 `health_activity_map`、既有 COROS 标题图标、Figma 人体资产 | ✅ |
| `HLTH-VIS-013` | HarmonyOS 编辑器恢复默认只重置编辑草稿 | `tools/check-health-card-editor-regressions.sh`；`hvigorw assembleApp --no-daemon` | `CardEditorComp.ets` 直接重建 `editingHealthCards`；`SignedInPage.ets` 移除错误回读回调 | ✅ |
| `HLTH-VIS-014` | iOS 编辑器重建卡片时保留本地化标题 | `tools/check-health-card-editor-regressions.sh`；`xcodebuild ... IOSDemo ... build` | `HealthCardEditor.swift` 的完整类型目录、`cardTitleKey` 与 `editorCard` | ✅ |
| `HLTH-VIS-015` | 三端健康图像通过完整的语义资源目录访问 | `tools/check-health-card-fidelity.sh`；Android/iOS/HarmonyOS 构建 | 三端 `AppImages.Health` / `AppImages` 概览资源入口；三端 `DashboardCard` renderer | ✅ |
| `HLTH-VIS-016` | 今日运动在列表、编辑与详情场景保持图标身份稳定 | `tools/check-health-card-fidelity.sh`；`tools/check-health-card-editor-regressions.sh`；iOS/HarmonyOS 构建 | iOS `todayActivity` / `iconForCardType`；HarmonyOS `healthCardIcon(typeName)` 及编辑/详情调用 | ✅ |
| `HLTH-VIS-017` | 空态卡片按显式状态和说明内容自适应高度 | `tools/check-health-card-adaptive-layout.sh`；三端构建 | 三端显式 Empty 状态分支、内容固有高度与完整说明渲染 | ✅ |
| `HLTH-VIS-018` | HarmonyOS 有数据卡不撑开列表视口 | 用户实机截图红灯；专项门禁禁止数据 renderer `height('100%')`；HarmonyOS `assembleApp` | `DashboardCardComp` 全宽受限外壳 + 固有高度 Visual | ✅ |
| `HLTH-VIS-019` | HarmonyOS 手表 Lottie 跟随同步状态播放一次 | 专项门禁；HarmonyOS `assembleApp` | `HeroTopRowComp.isSyncing/onSyncingChanged`；`SignedInPage.refreshing` | ✅ |
| `HLTH-VIS-020` | iOS 下拉刷新仅允许从列表顶部开始 | 两轮用户实机反馈红灯；专项门禁要求单一 UIScrollView pan observer；iOS `xcodebuild` | `ScrollViewPanObserver.ObserverView.handlePan` 在 began 锁定顶部，64pt 触发 | ✅ |
| `HLTH-VIS-021` | iOS 自定义刷新与右上角手表 Lottie 命令式同步 | 用户实机反馈声明式联动未播放；专项门禁红灯后转绿；iOS `xcodebuild` | `WatchSyncLottieView` 直接 `play/stop/currentProgress`；`syncCycle/isLoading` | ✅ |
| `HLTH-VIS-022` | iOS 手表 Lottie 约束在 30pt 容器内 | 用户截图红灯；专项门禁红灯 6 项后转绿；iOS `xcodebuild`；iPhone 17 模拟器截图 | `WatchSyncLottieView` 裁剪 UIView 容器 + 四边 Auto Layout；SwiftUI 30×30 frame | ✅ |
| `HLTH-VIS-023` | 三端卡片外壳按内容固有高度测量 | `tools/check-health-card-adaptive-layout.sh` 实施前 10 项红灯、最终绿灯；`:common:check`、`:androidApp:assembleDebug`、iOS `xcodebuild`、HarmonyOS `assembleApp` | Android `DashboardCard/HealthCardVisualContent`；iOS `cardRow/HealthCardVisualContent`；HarmonyOS `DashboardCardComp.VisualContent` | ✅ |
| `HLTH-VIS-024` | 三端卡片概览图按 2031 类型分别绘制 | `tools/check-health-card-fidelity.sh` 红灯 6 项后转绿；Android/iOS/HarmonyOS 构建通过；iPhone 17 模拟器截图 | 三端按卡片类型选择恢复/能力、心率/压力、静息心率/HRV、睡眠专用绘制器；iOS/HarmonyOS 增加恢复人体资源 | ✅ |
| `HLTH-VIS-025` | 三端顶部卡路里圆弧按 0–800 数据渲染 | 三端结构门禁与构建通过；iPhone 17 模拟器 769 Kcal 截图显示约 96% 弧长 | Android `calorieArcProgress`、iOS `HeroArcView.calorieProgress`、HarmonyOS `SignedInPage.calorieArcProgress` 均夹紧到 0–800 | ✅ |
| `HLTH-VIS-026` | 三端顶部卡路里弧保持正圆几何 | 三端结构门禁与构建通过；Android 与 iPhone 17 模拟器截图 | 三端均在 116×116 正方形绘制区内绘制 270° 圆弧 | ✅ |
| `HLTH-VIS-027` | 三端心率按半小时最低/最高/平均区间表达 | common/Android 测试通过；三端结构门禁与构建通过 | 共享 48 个半小时区间；三端 `HeartRateIntervalOverview` 每柱按自身 minimum/maximum 绘制 | ✅ |
| `HLTH-VIS-028` | 5 分钟模拟心率按每 6 点聚合为半小时区间；当前只启用正常 1、正常 2、异常三个有心率场景 | `fiveMinuteHeartSamplesAggregateIntoHalfHourIntervals`、`enabledHeartDataScenariosUseThreeProvidedFiveMinuteSamples`；枚举精确目录断言先因 `Normal3` 多余红灯，最终 `:common:testAndroidHostTest` 通过；emulator-5554 长按场景弹窗仅显示 5 个既有场景 | `HealthMockScenario`/`HealthScenarios` 移除 `Normal3`；`LocalHealthDashboardDataSource` 只映射 normal1/normal2/abnormal；三端场景选择入口和资源同步移除正常数据 3 | ✅ |
| `HLTH-VIS-029` | 三端周计划日期点击仅切换卡内七日计划，其他区域进入详情 | common/Android 测试通过；三端结构门禁与构建通过；iPhone 17 模拟器确认默认日计划 | 三端各自维护卡内选中日，日期子节点消费点击并从共享 `weeklyDayPlans` 切换内容 | ✅ |
| `HLTH-VIS-030` | 三端 HRV 与静息心率三角指针位于指标线下方 | Android 单测与模拟器通过；三端结构门禁与构建通过 | Android Compose、iOS Canvas、HarmonyOS Path 均在线下绘制朝上三角 | ✅ |
| `HLTH-VIS-031` | 三端健康快测测量时间与标题同行且缺失时隐藏 | common 测试、三端结构门禁与构建通过 | 三端 CardHeader 右侧条件渲染 nullable caption，内容区不再重复时间行 | ✅ |
| `HLTH-VIS-032` | 三端手表短按进入“我”，长按保留场景切换 | Android 模拟器通过；三端互斥手势结构门禁与构建通过 | Android `combinedClickable`、iOS exclusive gesture、HarmonyOS `GestureGroup(Exclusive)` 分离短按与长按 | ✅ |
| `HLTH-VIS-033` | iOS/HarmonyOS 有数据卡采用 Android 内容安全高度 | 用户反馈作为红灯；`check-health-cross-platform-parity.sh` 19 项红灯后转绿；两端构建通过；iPhone 17 首屏截图 | iOS `contentMinimumHeight`；HarmonyOS `contentMinimumHeight()` + 仅有数据分支的 `constraintSize` | ✅ |
| `HLTH-VIS-034` | 周计划日期同步切换内容与高亮柱 | 专项门禁转绿；iPhone 17 截图确认周四圆点与第 4 柱同时高亮；HarmonyOS 构建通过 | iOS 显式传入 `selectedIndex`；HarmonyOS `Bars(...weeklySelectedIndex())` | ✅ |
| `HLTH-VIS-035` | 负荷、趋势与睡眠概览按 Android 几何绘制 | 专项门禁、资源门禁与两端构建通过；iPhone 17 首屏确认负荷完整轨道/星期与训练评估高度 | iOS `LoadOverview/StressOverview/SleepStageOverview`；HarmonyOS `LoadOverview/StressOverview/SleepOverview` | ✅ |
| `HLTH-VIS-036` | 恢复/能力仪表完整且状态本地化 | 专项门禁、三端资源 JSON 与两端构建通过；模拟器下半屏自动翻页受系统辅助功能权限限制 | 两端 114×78 恢复与 121×71 能力安全区；补齐中英文恢复状态资源 | ✅ |
| `HLTH-VIS-037` | HarmonyOS 顶部指标、范围指针、快测网格对齐 Android | 专项门禁与 `assembleApp` 通过；当前无在线 HarmonyOS 设备，真机截图待人工回归 | 独立 116×116 弧容器；`MetricComp.iconColor`；可见 `RangeMarker`；`HealthCheckGrid` 两行三列 | ✅ |
| `HLTH-VIS-038` | HarmonyOS Path 几何按 vp 设计尺寸换算 | 用户高密度设备截图作为红灯；`check-health-cross-platform-parity.sh` 8 项坐标断言红灯后转绿；HarmonyOS `assembleApp` 通过 | `SignedInPage.calorieArcPath`、`DashboardCardComp.gaugeArcPath/abilitySegmentPath/abilityNeedlePath/rangeMarkerPath` 在生成 Path 命令前调用 `vp2px` | ✅ |
| `HLTH-VIS-039` | HarmonyOS 顶部指标 PNG 使用模板色 | 用户截图显示白/蓝原图色作为红灯；专项门禁模板模式断言红灯后转绿；HarmonyOS `assembleApp` 通过 | `MetricComp` 使用 `ImageRenderMode.Template` 后应用 `AppColors.STEPS/CALORIES/ACTIVE` | ✅ |

---

## health-dashboard-persistence.md 追溯

| Spec ID | 规范 | 测试/验证 | 实现/文档 | 状态 |
|---|---|---|---|---|
| `HLTH-PERSIST-001` | 快照保存完整健康领域数据 | `HealthDashboardUseCaseTest.fullDashboardSnapshotRoundTripsAllModuleData`；`./gradlew :common:check` | `health_dashboard_mock.proto`、`HealthDashboardSnapshot`、`MockHealthDashboardStoreJson` | ✅ |
| `HLTH-PERSIST-002` | 加载以模块数据为权威 | `storedDashboardDataWinsOverScenarioTemplate`；common 全目标测试 | `HealthDashboardStore.resolveSnapshot` / `toPersistedDashboard` | ✅ |
| `HLTH-PERSIST-003` | 场景选择仅暂存，刷新成功后才更新首页并持久化模块数据 | `scenarioSelectionDoesNotChangeDashboardUntilRefresh`、`refreshPersistsSelectedScenarioModuleData`、`failedRefreshPreservesLastDashboardSnapshot`；三端构建 | `HealthDashboardStore.selectScenario/refresh`；Android/iOS/HarmonyOS 刷新入口 | ✅ |
| `HLTH-PERSIST-004` | 卡片配置更新保留健康数据 | `cardConfigurationUpdatePreservesDashboardData`、最少卡片回归测试 | `HealthDashboardStore.saveCardConfiguration` | ✅ |
| `HLTH-PERSIST-005` | 旧配置快照安全迁移 | `legacyScenarioSnapshotMigratesToFullData`、`corruptedDashboardSnapshotIsIgnoredWithoutCrash` | `MockHealthDashboardStoreJson`、`JsonHealthDashboardStateDataSource`、`resolveSnapshot` | ✅ |
| `HLTH-PERSIST-006` | 多用户数据隔离 | `fullDashboardSnapshotsAreIsolatedByUserId`、`twentyFullDashboardSnapshotsRoundTripWithinPreferencesBudget`、`deletingAccountClearsOnlyItsHealthSnapshot` | common snapshot map；Android/iOS 既有按 userId Key adapter | ✅ |
| `HLTH-PERSIST-007` | HarmonyOS 使用单一健康快照集合 | 集合 codec 测试；KNOI `ohosArm64Binaries`、`hvigorw assembleApp --no-daemon`、结构扫描 | `HarmonyLoginService.export/restoreHealthSnapshot`、`StorePersister.ets`、`SignedInPage.ets` | ✅ |
| `HLTH-PERSIST-008` | 三端读取失败展示独立前台损坏态并保留最后有效快照 | `failedRefreshPreservesLastDashboardSnapshot`；专项门禁；`:common:check` 与三端构建 | `LoginFacade.healthDashboardError`；Android `result`；iOS `isDataCorrupted`；Harmony bridge error JSON / `healthDataCorrupted` | ✅ |

---

## health-maintainability.md 追溯

| Spec ID | 规范 | 测试/验证 | 实现/文档 | 状态 |
|---------|------|-----------|-----------|------|
| `HLTH-MAINT-001` | 最少卡片数验证在 common 层统一执行 | `HealthDashboardUseCaseTest.cardSaveRejectsMinimumConfig` / `cardSaveAcceptsSufficientConfig` | `HealthDashboardUseCase.kt:286-301` `saveCardConfiguration` | ✅ |
| `HLTH-MAINT-002` | `LoginFacade` 暴露卡片保存错误消息 | 人工验收：三端减少卡片到 <3 张时显示错误提示 | `LoginFacade.kt:257-268` `saveHealthCardConfiguration` / `healthCardSaveError` | ✅ |
| `HLTH-MAINT-003` | 场景名和展示键由 common 提供 | `HealthDashboardUseCaseTest.healthScenariosMatchMockEntries` | `HealthDashboardModels.kt:81-90` `HealthScenarios` | ✅ |
| `HLTH-MAINT-004` | iOS 移除 `HealthCard` 和 `defaultHealthCards` | 人工验收：iOS 构建通过 + 健康仪表盘展示一致 | `HealthDashboardView.swift`（精简 `HealthCard`） / `HealthDashboardViewModel.swift`（直接映射） | ✅ |
| `HLTH-MAINT-005` | HarmonyOS `SignedInPage.ets` 按职责拆分 | 人工验收：HarmonyOS 构建通过 + 页面交互无差异 | `health/HealthDashboardTypes.ets` / `SignedInPage.ets`（精简） | ✅ |
| `HLTH-MAINT-006` | 登录后导航规则由 `LoginEffect` 携带 | `LoginUseCaseTest.loginSuccessCarriesSignedInRouteWhenProfileComplete` / `loginSuccessCarriesProfileCompletionRouteWhenProfileIncomplete` | `LoginModels.kt` `PostLoginRoute` + `LoginEffect.AuthSucceeded.nextRoute`；三端导航文件已更新 | ✅ |

---

---

## health-ui-refactor.md 追溯

| Spec ID | 规范 | 测试/验证 | 实现/文档 | 状态 |
|---------|------|-----------|-----------|------|
| `HLTH-UI-ARCH-001` | DashboardCard 按视觉种类拆为独立文件 | `./gradlew :androidApp:assembleDebug`；`xcodebuild`；截图人工对比 | Android `DashboardCard.kt`（骨架）+ `visuals/` 10 文件；iOS `HealthDashboardView.swift`（256 行）+ `Visuals/` 11 文件；HarmonyOS `DashboardCardComp.ets`（109 行）+ `visuals/` 10 文件 | ✅ |
| `HLTH-UI-ARCH-002` | 页面子模式改为密封类状态驱动 | 待补 | 待补 | ⏳ |
| `HLTH-UI-ARCH-003` | 下拉刷新抽取为独立组件 | 待补 | 待补 | ⏳ |
| `HLTH-UI-ARCH-004` | 创建独立 HealthDashboardViewModel | 待补 | 待补 | ⏳ |
| `HLTH-UI-ARCH-005` | 引入 HealthDashboardEffect | 待补 | 待补 | ⏳ |
| `HLTH-UI-ARCH-006` | Screen 状态归约为单一对象 | 待补 | 待补 | ⏳ |
| `HLTH-UI-ARCH-007` | selectedWeeklyDay 下放到 WeeklyVisual/WeeklyPlan | Android `./gradlew :androidApp:assembleDebug`；代码审查 | Android `WeeklyVisual.kt` 内部 `selectedDay`；iOS `WeeklyPlanView.swift` 内部 `@State selectedDay`；HarmonyOS `WeeklyPlanVisualComp.ets` 内部 `@State selectedDay` | ✅ |
| `HLTH-UI-ARCH-008` | 三端同一子模式状态驱动对齐 | 待补 | 待补 | ⏳ |
| `HLTH-UI-ARCH-009` | iOS `HealthDashboardView.swift` 按视觉种类拆分 | `xcodebuild`（待运行） | iOS `HealthDashboardView.swift`（256 行）+ `Visuals/` 11 个独立文件 | ✅（待验证） |
| `HLTH-UI-ARCH-010` | HarmonyOS `DashboardCardComp.ets` 按视觉种类拆分 | `hvigorw assembleApp`（待运行） | HarmonyOS `DashboardCardComp.ets`（109 行）+ `visuals/` 10 个独立文件 | ✅（待验证） |

---

## 使用约定

1. **新加功能**：先在 `spec/` 下写 .md 或追加章节 → 在本文件预留映射行（状态标为 ⏳）→ 写测试 → 写实现 → 改状态为 ✅
2. **Codex 协作**：`Codex_worklog.md` 的每一条“采纳/审查/验证/修正”必须引用稳定 Spec ID；历史 Spec 尚无稳定 ID 时可引用章节号，例如 `[auth-mock-spec §8]`
3. **评审验收**：按 TRACE.md 逐条核对 Spec 落地情况

## 跨平台预览注解

| Spec 章节 | 对应代码位置 | 状态 |
|-----------|-------------|------|
| **iOS #Preview** | 23 个 View 文件均有 `#Preview` 块（Login/Home/Account/Health 全部 View 和组件） | ✅ |
| **HarmonyOS @Preview** | 6 个纯 `@Component` 文件均有 `@Preview` 装饰器（DashboardCard/HeroTopRow/Metric/ScenarioPicker/HealthDetail/CardEditor） | ✅ |
| **Android @Preview** | 21 个 Compose 屏幕/组件文件均有 `@Preview` 注解 | ✅ |
