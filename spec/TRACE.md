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
| `DOC-008` | 测试事实同步 | `tools/check-docs.sh` 动态核对 `@Test`：29/8/4/16，合计 57 | `TEST_REPORT.md`、本文件 | ✅ |
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
| **测试要求 - 12 条以上** | `HealthDashboardUseCaseTest.kt` → **16 条测试** | ✅ |
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

## 测试总览

| 测试类 | 测试数 | 所属 Spec |
|--------|--------|-----------|
| `LoginRulesTest.kt` | 8 | auth-mock-spec §7, §8, §9；RES-LOC-001 |
| `LoginUseCaseTest.kt` | 29 | auth-mock-spec §14 |
| `BusinessMockDataSourceTest.kt` | 4 | auth-mock-spec §10, §11, §14 |
| `HealthDashboardUseCaseTest.kt` | 16 | health-dashboard-cards 测试要求；RES-MAINT-008 |
| **合计** | **57** | |

---

## 使用约定

1. **新加功能**：先在 `spec/` 下写 .md 或追加章节 → 在本文件预留映射行（状态标为 ⏳）→ 写测试 → 写实现 → 改状态为 ✅
2. **Codex 协作**：`Codex_worklog.md` 的每一条“采纳/审查/验证/修正”必须引用稳定 Spec ID；历史 Spec 尚无稳定 ID 时可引用章节号，例如 `[auth-mock-spec §8]`
3. **评审验收**：按 TRACE.md 逐条核对 Spec 落地情况
