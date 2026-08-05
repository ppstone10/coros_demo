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
| `DOC-008` | 测试事实同步 | `tools/check-docs.sh` 动态核对业务映射测试 35/8/4/47/11，合计 105；另含 11 条 Health MVI 测试，common 合计 116 | `TEST_REPORT.md`、本文件 | ✅ |
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
| **§12 iOS 头像持久化** | `AppResources.swift:242-263`（`ProfileImageStore`），以 `UserDefaults` 替代文件系统 | ✅ |

### 会话生命周期增量追溯

| Spec ID | 规范 | 测试/验证 | 实现/文档 | 状态 |
|---------|------|-----------|-----------|------|
| `AUTH-SESSION-001` | 单一 TTL 仅在冷启动恢复时判定 | `LoginUseCaseTest.sessionExpiresAfterBackgroundTtlAndIsRemovedFromPersistence`、`coldStartRestoreExpiresSessionAfterPersistedDeadline`；`:common:check` | `AuthRepository.pauseSession/restoreSessionOnColdStart` | ✅ |
| `AUTH-SESSION-002` | 冷启动恢复与同进程暖恢复分离并同步三端 | `warmResumeKeepsSessionActiveAfterBackgroundTtlAndClearsDeadline`、`warmResumePreventsStaleDeadlineFromExpiringNextColdStart`；Android/iOS/HarmonyOS 构建 | `resumeSessionInSameProcess`；Android `AuthNavGraph`、iOS `AuthCoordinator`、HarmonyOS `EntryAbility` | ✅ |
| `AUTH-SESSION-003` | Android 首次 `ON_START` 串行执行冷恢复，后续才暖恢复 | `SessionLifecycleCoordinatorTest.firstStartRestoresColdSessionAndLaterStartsResumeWarmSession`、`recreatedCoordinatorTreatsItsFirstStartAsColdEvenInSameProcess`；红灯后 `:androidApp:testDebugUnitTest` 通过 | Android `SessionLifecycleCoordinator`、`LoginViewModel.onAppStarted`、`AuthNavGraph` 单一 `ON_START` 接线 | ✅ |

---

## health-architecture-alignment.md 追溯

| Spec ID | 规范 | 测试/验证 | 实现/文档 | 状态 |
|---------|------|-----------|-----------|------|
| `HLTH-MVI-001` | HealthAction sealed interface | ✅ `HealthStoreTest.healthActionDispatchProducesExpectedState` | ✅ `common/.../health/HealthModels.kt:3-10` | ✅ |
| `HLTH-MVI-002` | HealthState data class | ✅ `HealthStoreTest.healthStateReflectsScenarioSelection` | ✅ `common/.../health/HealthModels.kt:12-18` | ✅ |
| `HLTH-MVI-003` | HealthEffect 迁移至 common | ✅ `HealthStoreTest.healthEffectIsProducedAfterRefresh` | ✅ `common/.../health/HealthModels.kt:20-24`；三端平台 HealthDashboardEffect 文件已删除 | ✅ |
| `HLTH-MVI-004` | HealthStore MVI 实现 | ✅ `HealthStoreTest.healthStoreRejectsInvalidCardConfiguration` | ✅ `common/.../health/HealthStore.kt` | ✅ |
| `HLTH-MVI-005` | HealthFacade 独立门面 | ✅ 代码评审 LoginFacade 不再包含 health 方法；`LoginFacade.kt` | ✅ `common/.../health/HealthFacade.kt` | ✅ |
| `HLTH-MVI-006` | HealthRules 纯函数提取 | ✅ `HealthRules.validateMinimumCards` / `HealthRules.computeCardPriority` | ✅ `common/.../health/HealthRules.kt` | ✅ |
| `HLTH-MVI-007` | HealthMessageKeys 独立 | ✅ `MockError.MinimumCardsRequired` 引用 `HealthMessageKeys`；`AuthMessageKeys` 不再包含 health 键 | ✅ `common/.../health/HealthMessageKeys.kt` | ✅ |
| `HLTH-MVI-008` | HealthDashboardUseCase 拆分 | ✅ `./gradlew :common:check` 全部 92 条测试通过 | ✅ `HealthDashboardUseCase.kt`(toUiState) + `HealthDashboardDataSource.kt`(接口) + `LocalHealthDashboardDataSource.kt`(mock) + `HealthDashboardVisuals.kt`(visuals) | ✅ |
| `HLTH-MVI-009` | HealthDashboardVisuals 独立 | ✅ 代码评审 visual 构建器在独立文件 | ✅ `common/.../health/HealthDashboardVisuals.kt` | ✅ |
| `HLTH-MVI-010` | Android ViewModel 薄包装 | ✅ `./gradlew :androidApp:compileDebugKotlin` 通过 | ✅ `HealthDashboardViewModel.kt` (mutableStateOf + dispatch/consumeEffect) | ✅ |
| `HLTH-MVI-011` | iOS ViewModel 薄包装 | ✅ 通过代码审查及属性/方法一致性验证；19 处 View 引用与 ViewModel 属性完全匹配 | ✅ `HealthDashboardViewModel.swift` + `SharedLoginAdapter.swift` | ✅ |
| `HLTH-MVI-012` | HarmonyOS ViewModel + 桥接更新 | ⏳ 待 hvigorw assembleApp 验证；代码已修改 | ✅ `HarmonyLoginService.kt` + `HealthDashboardViewModel.ets` + `SignedInPage.ets` | ⏳（待构建验证） |
| `HLTH-MVI-013` | LoginStore/Facade 不再代理 health | ✅ `./gradlew :common:check` 通过；`LoginStore.kt` 无 `healthDashboardStore`；`LoginFacade.kt` 无 health 方法 | ✅ `LoginStore.kt` + `LoginFacade.kt` | ✅ |
| `HLTH-MVI-014` | 三端平台 Effect 文件删除 | ✅ 文件系统确认三端文件已删除 | ✅ 删除 `androidApp/.../health/HealthDashboardEffect.kt`、`iosApp/.../HealthDashboardEffect.swift`、`harmonyApp/.../HealthDashboardEffect.ets` | ✅ |

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

### 健康契约与空态增量追溯

| Spec ID | 规范 | 测试/验证 | 实现/文档 | 状态 |
|---------|------|-----------|-----------|------|
| `HLTH-EMPTY-001` | 业务卡自身 Empty 状态承担空态引导 | `HealthDashboardUseCaseTest.coreEmptyCardsExposeGuidanceKeysAndActions`；资源门禁与三端构建 | `HealthDashboardUseCase.empty`；三端 `health_summary_*_empty` 原生资源 | ✅ |
| `HLTH-CONTRACT-001` | Proto 定义类型化健康场景和错误契约 | `healthProtoScenarioAndErrorContractsRoundTrip`；`:common:check` | `health_dashboard_mock.proto`、`HealthMockContracts.kt`、`HealthModels.kt` | ✅ |
| `HLTH-CONTRACT-002` | 旧字符串场景快照兼容迁移 | `snapshotsEncodeProtoScenarioNamesAndDecodeLegacyNames`、`legacyScenarioSnapshotMigratesToFullData` | `MockHealthDashboardStoreJson`、schema version 5、`HealthDashboardSnapshotMock` 字段 2/6 | ✅ |
| `HLTH-SCENARIO-001` | 三端场景选择器消费 common 场景目录 | `healthScenariosMatchMockEntries`；Android/iOS/HarmonyOS 构建 | `HealthScenarios.entries`、`HealthFacade.scenarioDescriptors`、三端 ScenarioPicker | ✅ |

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

## profile-edit-layout.md 追溯

| Spec ID | 规范 | 测试/验证 | 实现/文档 | 状态 |
|---------|------|-----------|-----------|------|
| `PROFILE-EDIT-001` | 三端个人资料编辑标题栏固定在资料滚动区外 | `./tools/check-profile-edit-layout.sh`；HarmonyOS `hvigorw assembleApp --no-daemon` 通过；设备人工滚动待复验 | Android `PersonalProfileEditContent`、iOS `PersonalProfileEditView` 既有固定标题结构；HarmonyOS `ProfileCompletionPage.ProfileEditHeader` | ⚠️（自动验证完成，无连接设备） |
| `PROFILE-EDIT-002` | 短资料内容从滚动视口顶部起排，不整体垂直居中 | 结构门禁先因鸿蒙标题仍在 `Scroll` 内红灯，实施后通过；设备截图待复验 | HarmonyOS `ProfileCompletionPage` 滚动内容显式 `Alignment.TopStart` | ⚠️（自动验证完成，无连接设备） |

---

## 测试总览

| 测试类 | 测试数 | 所属 Spec |
|--------|--------|-----------|
| `LoginRulesTest.kt` | 8 | auth-mock-spec §7, §8, §9；RES-LOC-001 |
| `LoginUseCaseTest.kt` | 36 | auth-mock-spec §14；AUTH-SESSION-001~002；AUTH-PROFILE-DEFAULT-001 |
| `BusinessMockDataSourceTest.kt` | 4 | auth-mock-spec §10, §11, §14 |
| `HealthDashboardUseCaseTest.kt` | 47 | health-dashboard-cards 测试要求；HLTH-EMPTY-001；HLTH-CONTRACT-001~002；HLTH-SCENARIO-001；RES-MAINT-008；HLTH-VIS-001~003、027~032、042、044、046；HLTH-PERSIST-001~007 |
| `EditableHealthDataTest.kt` | 16 | HLTH-EDIT-001~005、008、011~013、017~018、020、022~024 |
| `HealthPreviewFixturesTest.kt` | 1 | UI-PREVIEW-001 |
| **合计** | **112** | 业务需求映射测试 |
| `HealthStoreTest.kt` | 11 | HLTH-MVI-001~004、HLTH-MVI-010；HLTH-VIS-042 |
| **common 全部合计** | **123** | 含 Health MVI 架构测试 |
| `SessionLifecycleCoordinatorTest.kt` | 2 | AUTH-SESSION-003（Android JVM） |

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
| `HLTH-VIS-030` | 三端 HRV 与静息心率指针与指标线同层叠放，尖端朝上且底边跨过横条 | 用户 HarmonyOS 截图作为方向基准；`rangeMarkerTrianglePointsUpAndCrossesIndicatorLine`；Android 模拟器截图；三端构建 | Android/iOS 三角 Path 已对齐 HarmonyOS `rangeMarkerPath` | ✅ |
| `HLTH-VIS-031` | 三端健康快测测量时间与标题同行且缺失时隐藏 | common 测试、三端结构门禁与构建通过 | 三端 CardHeader 右侧条件渲染 nullable caption，内容区不再重复时间行 | ✅ |
| `HLTH-VIS-032` | 三端手表短按进入“我”，长按保留场景切换 | Android 模拟器通过；三端互斥手势结构门禁与构建通过 | Android `combinedClickable`、iOS exclusive gesture、HarmonyOS `GestureGroup(Exclusive)` 分离短按与长按 | ✅ |
| `HLTH-VIS-033` | iOS/HarmonyOS 有数据卡采用 Android 内容安全高度 | 用户反馈作为红灯；`check-health-cross-platform-parity.sh` 19 项红灯后转绿；两端构建通过；iPhone 17 首屏截图 | iOS `contentMinimumHeight`；HarmonyOS `contentMinimumHeight()` + 仅有数据分支的 `constraintSize` | ✅ |
| `HLTH-VIS-034` | 周计划日期同步切换内容与高亮柱 | 专项门禁转绿；iPhone 17 截图确认周四圆点与第 4 柱同时高亮；HarmonyOS 构建通过 | iOS 显式传入 `selectedIndex`；HarmonyOS `Bars(...weeklySelectedIndex())` | ✅ |
| `HLTH-VIS-035` | 负荷、趋势与睡眠概览按 Android 几何绘制 | 专项门禁、资源门禁与两端构建通过；iPhone 17 首屏确认负荷完整轨道/星期与训练评估高度 | iOS `LoadOverview/StressOverview/SleepStageOverview`；HarmonyOS `LoadOverview/StressOverview/SleepOverview` | ✅ |
| `HLTH-VIS-036` | 恢复/能力仪表完整且状态本地化 | 专项门禁、三端资源 JSON 与两端构建通过；模拟器下半屏自动翻页受系统辅助功能权限限制 | 两端 114×78 恢复与 121×71 能力安全区；补齐中英文恢复状态资源 | ✅ |
| `HLTH-VIS-037` | HarmonyOS 顶部指标、范围指针、快测网格对齐 Android | 专项门禁与 `assembleApp` 通过；当前无在线 HarmonyOS 设备，真机截图待人工回归 | 独立 116×116 弧容器；`MetricComp.iconColor`；可见 `RangeMarker`；`HealthCheckGrid` 两行三列 | ✅ |
| `HLTH-VIS-038` | HarmonyOS Path 几何按 vp 设计尺寸换算 | 用户高密度设备截图作为红灯；`check-health-cross-platform-parity.sh` 8 项坐标断言红灯后转绿；HarmonyOS `assembleApp` 通过 | `SignedInPage.calorieArcPath`、`DashboardCardComp.gaugeArcPath/abilitySegmentPath/abilityNeedlePath/rangeMarkerPath` 在生成 Path 命令前调用 `vp2px` | ✅ |
| `HLTH-VIS-039` | HarmonyOS 顶部指标 PNG 使用模板色 | 用户截图显示白/蓝原图色作为红灯；专项门禁模板模式断言红灯后转绿；HarmonyOS `assembleApp` 通过 | `MetricComp` 使用 `ImageRenderMode.Template` 后应用 `AppColors.STEPS/CALORIES/ACTIVE` | ✅ |
| `HLTH-VIS-040` | 14 张卡片解耦为 12 类顶层样式，仅能力双卡与趋势双卡复用 | `check-health-card-style-decoupling.sh` 实施前 30 项红灯、实施后全绿；`:common:check`；Android/iOS/HarmonyOS 构建；emulator-5554 中下段截图 | 三端 `Recovery`/`Ability`/`RestingHeartRate`/`HrvAssessment` 独立顶层组件；`DashboardCard` 按稳定卡片类型分发 | ✅ |
| `HLTH-VIS-041` | HRV/静息心率范围信息紧凑叠放并显示近 30 天平均虚线 | Android 单测及三端构建通过；HRV 状态/均值层级、静息心率平均虚线与紧凑端点已落地，设备截图待人工回归 | 三端 `HrvAssessment` / `RestingHeartRate` 独立视觉组件 | ✅（人工运行待验收） |
| `HLTH-VIS-042` | 体重编辑历史按确认顺序完整持久化且刷新保留 | `bodyWeightHistoryRoundTripPreservesEditOrderAndDuplicates`、`legacyBodyWeightMigratesToSingleHistoryEntry`、`bodyWeightEditsAppendInOrderAndScenarioRefreshPreservesHistory`、`BodyWeightChanged` action 测试；`:common:check` 通过 | `BodyManagement.weightHistoryKg`、`HealthDashboardStore.saveBodyWeight`、健康快照 proto/JSON schema v6 | ✅ |
| `HLTH-VIS-043` | 三端体型管理卡提供体重滑轮编辑入口与周锻炼部位说明 | 三端构建通过；编辑图标、30.0–200.0/0.1 滑轮、确认保存入口及精确文案已落地，设备点击待人工回归 | Android `WeightSheet`；iOS `HealthWeightPickerSheet`；HarmonyOS `HealthWeightPickerSheetComp`；三端 Body 视觉组件 | ✅（人工运行待验收） |
| `HLTH-VIS-044` | HRV 四档短状态高亮并统一三端范围指针朝向 | `hrvStatusUsesFourShortRangeLabels` 红灯后通过；Android 指针几何测试、模拟器截图及三端构建通过 | common `hrvStatusKey`；三端 HRV 32 号白色粗体/4 间距；Android/iOS 上尖三角 | ✅ |
| `HLTH-VIS-045` | HRV 指针与静息心率采用相同重叠几何，HarmonyOS 正常范围文案不回退 | `tools/check-health-range-indicator-parity.sh` 实施前 4 项红灯、实施后全绿；Android/iOS/HarmonyOS 构建通过；当前无在线 HarmonyOS 设备 | `HrvAssessmentVisualComp.RangeMarker` 与横条改用静息心率同一纵向边界；`HealthLocalization.healthResource` 显式映射正常范围键 | ⚠️（自动验证通过，鸿蒙设备截图待验收） |
| `HLTH-VIS-046` | HRV 四段横条与指针按 common 真实范围绘制 | `hrvRangeSegmentsAndPointerUseActualValues` 实现前因分段模型缺失编译红灯、实现后通过；专项门禁与 common/Android/iOS/HarmonyOS 构建通过 | `HealthDashboardVisuals.hrvRange` 输出连续分段与统一范围；三端 HRV 组件按 `HealthRange.segments` 比例绘制，指针按相同 minimum/maximum 归一化 | ✅ |
| `HLTH-VIS-047` | 卡片编辑器长按拖拽无滚动泄露延迟 | `./gradlew :androidApp:assembleDebug` 通过；人工验收：长按卡片立即变灰后拖拽响应无滚动窗口期 | `androidApp/.../health/editor/CardEditor.kt` 替换 `detectDragGesturesAfterLongPress` 为 `awaitLongPressOrCancellation` + 手动拖拽循环 | ✅（构建通过，运行时待验收） |

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
| `HLTH-PERSIST-009` | 账号切换时健康首页重置为空卡片并触发刷新动画，刷新后恢复新账号持久化数据 | `./gradlew :common:check :androidApp:assembleDebug` 通过；人工验收：登出→换号登录后健康首页初始为空，刷新动画播放，数据正确切换 | `HealthStore.staleForNewAccount`；`HealthDashboardViewModel.staleForNewAccount`；`HealthDashboardScreen.LaunchedEffect` 延迟加载；`AuthNavGraph.AuthSucceeded/LoggedOut` 调用重置 | ✅（构建通过，运行时待验收） |
| `AUTH-ACCOUNT-DELETE-001` | 注销账户同步删除该用户健康快照且保留其他用户数据 | `HealthDashboardUseCaseTest.deletingAccountClearsOnlyItsHealthSnapshot` 在新增删除回调前编译红灯、实现后通过；`:common:check`；三端构建 | `LoginStore.onDeleteUserData`、`HealthStore.clear`、三端 Store/Adapter 注销组合根 | ✅ |

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
| `HLTH-MAINT-007` | HarmonyOS 编辑卡片保存沿用 bridge CSV 参数契约 | `tools/check-health-card-editor-regressions.sh` 实现前 4 项红灯、修复后通过；HarmonyOS `assembleApp` 通过；设备点击待验收 | `CardEditorComp` 原生保存 Button；`HealthDashboardViewModel.saveCardConfiguration` 以 `types.join(',')` 调用 CSV bridge 并返回成功状态；`HealthCardEditorPage` 仅成功后持久化并返回 | ⚠️（自动验证通过，鸿蒙设备点击待验收） |

---

---

## health-ui-refactor.md 追溯

| Spec ID | 规范 | 测试/验证 | 实现/文档 | 状态 |
|---------|------|-----------|-----------|------|
| `HLTH-UI-ARCH-001` | DashboardCard 按视觉种类拆为独立文件 | `./gradlew :androidApp:assembleDebug`；`xcodebuild`；截图人工对比 | Android `DashboardCard.kt`（骨架）+ `visuals/` 10 文件；iOS `HealthDashboardView.swift`（256 行）+ `Visuals/` 11 文件；HarmonyOS `DashboardCardComp.ets`（109 行）+ `visuals/` 10 文件 | ✅ |
| `HLTH-UI-ARCH-002` | 页面子模式改为密封类状态驱动 | `./gradlew :androidApp:assembleDebug` | Android `DashboardPage` 密封接口 + `when(page)` 替代 `if {} return`；iOS `DashboardPage` 枚举 + `switch`；HarmonyOS `currentPage` string + `if/else` 链 | ✅ |
| `HLTH-UI-ARCH-003` | 下拉刷新抽取为独立组件 | `./gradlew :androidApp:assembleDebug` | Android `PullToRefreshState.kt` + `Modifier.pullToRefresh()`/`pullTranslation()`；iOS `ScrollViewPanObserver.swift` 独立文件（HarmonyOS 使用原生 `Refresh` 无需改动） | ✅ |
| `HLTH-UI-ARCH-004` | 创建独立 HealthDashboardViewModel | `./gradlew :androidApp:assembleDebug`；`hvigorw assembleApp`（待运行） | Android `HealthDashboardViewModel.kt` + `LoginViewModel.kt` 移除健康方法 + `MainTabsScreen.kt` 桥接；iOS 已有 ViewModel 补 Effect 回调；HarmonyOS `HealthDashboardViewModel.ets` | ✅（Android/iOS），⏳（HarmonyOS 待构建验证） |
| `HLTH-UI-ARCH-005` | 引入 HealthDashboardEffect | `./gradlew :androidApp:assembleDebug`；`hvigorw assembleApp`（待运行） | Android `HealthDashboardEffect.kt` 密封接口；iOS `HealthDashboardEffect.swift` 枚举；HarmonyOS `HealthDashboardEffect.ets` 类 | ✅（Android/iOS），⏳（HarmonyOS 待构建验证） |
| `HLTH-UI-ARCH-006` | Screen 状态归约为单一对象 | `./gradlew :androidApp:assembleDebug` | Android `DashboardScreenState` data class（替代 5 个独立变量）；iOS `DashboardScreenState` struct（替代 4 个 @State）；HarmonyOS `currentPage` + `detailCardId` 替代 `editingCards`/`showScenarioPicker`/`detailCardId` | ✅ |
| `HLTH-UI-ARCH-007` | selectedWeeklyDay 下放到 WeeklyVisual/WeeklyPlan | Android `./gradlew :androidApp:assembleDebug`；代码审查 | Android `WeeklyVisual.kt` 内部 `selectedDay`；iOS `WeeklyPlanView.swift` 内部 `@State selectedDay`；HarmonyOS `WeeklyPlanVisualComp.ets` 内部 `@State selectedDay` | ✅ |
| `HLTH-UI-ARCH-008` | 三端同一子模式状态驱动对齐 | `./gradlew :androidApp:assembleDebug`；代码审查 | 三端均使用枚举/密封类 + `when`/`switch` 管理子页面，不再使用 `if {} return` 或 `if/else` 条件截断 | ✅ |
| `HLTH-UI-ARCH-009` | iOS `HealthDashboardView.swift` 按视觉种类拆分 | `xcodebuild`（待运行） | iOS `HealthDashboardView.swift`（256 行）+ `Visuals/` 11 个独立文件 | ✅（待验证） |

---

## health-navigation.md 追溯

| Spec ID | 规范 | 测试/验证 | 实现/文档 | 状态 |
|---------|------|-----------|-----------|------|
| `HLTH-NAV-001` | 四个底部页面属于同一根层级，Tab 不入栈，根返回不回认证流程 | `check-health-navigation.sh` 先红后绿；三端构建；Android emulator-5554 根层系统返回后 Launcher 可见 | Android `MainTabsScreen`、iOS `MainTabsView`、HarmonyOS `SignedInPage` 保持 Tab 为根层 UI 状态 | ✅（iOS/HarmonyOS 根层运行时待设备复验） |
| `HLTH-NAV-002` | 健康详情与卡片编辑使用三端原生二级路由 Push/Pop | `check-health-navigation.sh` 实现前 40 项失败、实现后 40 项通过；三端构建；Android 详情系统返回验收 | Android `AuthNavGraph`；iOS `AuthCoordinator`；HarmonyOS `AuthRoutes`、`HealthDetailPage`、`HealthCardEditorPage` | ✅（iOS/HarmonyOS 运行时待设备复验） |
| `HLTH-NAV-003` | 个人资料编辑作为二级路由返回“我”页面 | `check-health-navigation.sh`；Android/iOS/HarmonyOS 构建 | Android/iOS 新增资料编辑路由；HarmonyOS 复用 `ProfileCompletionPage(editMode=true)` | ✅（三端资料编辑运行时待复验） |
| `HLTH-NAV-004` | 详情返回恢复进入前的健康列表位置 | 导航结构门禁；三端构建；Android emulator-5554 详情往返前后 Recovery 标题 bounds 均为 `[150,1417][996,1480]` | Android hoist `LazyListState`；iOS 保留同一根 View/VM；HarmonyOS 普通 Pop 不重载根 Scroll | ✅（iOS/HarmonyOS 滚动位置待设备复验） |
| `HLTH-NAV-005` | 业务逻辑继续沉淀 common，平台只负责导航与 UI 状态 | `./gradlew :common:check`；代码审查；三端构建 | 路由和滚动状态仅位于平台层，common 健康模型、规则、Store 与持久化契约未引入平台导航依赖 | ✅ |
| `HLTH-NAV-006` | Recovery 使用设计源回转箭头时钟语义图标 | `check-health-navigation.sh`、`check-resource-maintainability.sh`、`check-resources.sh`；三端构建 | 三端 `health_recovery_time` 语义资源、`AppImages` 映射及 `resource-inventory.json` | ✅（iOS/HarmonyOS 视觉待设备复验） |
| `HLTH-UI-ARCH-010` | HarmonyOS `DashboardCardComp.ets` 按视觉种类拆分 | `hvigorw assembleApp`（待运行） | HarmonyOS `DashboardCardComp.ets`（109 行）+ `visuals/` 10 个独立文件 | ✅（待验证） |
| `HLTH-UI-ARCH-011` | Android 健康首页固定 Hero、仅主体下移，拖动提示与主体固定间距联动 | `PullToRefreshStateTest.draggingIndicatorKeepsFixedGapAndMovesWithBody` 红灯后转绿；`:androidApp:assembleDebug`、`:androidApp:lintDebug`；emulator-5554 同一手势阈值前后截图 | `indicatorTopAttachedToBody` 使用主体顶部、提示高度和当前 80dp 固定间距；Dragging/Armed 直接使用随动位置并绕过停靠插值；三态/层级/提前淡入保持 | ✅ |
| `HLTH-UI-ARCH-012` | Android 达阈值后主体固定吸附，刷新与复位仍保持提示固定间距，4460ms Lottie 同步 | `PullToRefreshStateTest.refreshAndResetKeepTheSameBodyAttachment` 红灯后转绿；`:androidApp:assembleDebug`、`:androidApp:lintDebug`；emulator-5554 阈值保持态与松手同步态截图 | `indicatorTopForPhase` 将五个阶段统一映射为 `bodyTop - indicatorHeight - 80dp`，主体吸附到当前 34dp，删除刷新停靠插值与复位额外上移 | ✅ |
| `HLTH-UI-ARCH-013` | iOS/HarmonyOS 对齐 Android 最终分层下拉刷新与 `80/34/80/0.4/300/4460` 视觉参数 | 五态/参数静态检查由无匹配红灯转绿；`xcodebuild ... -scheme IOSDemo ... build`；HarmonyOS `hvigorw assembleApp --no-daemon`；Android 基准测试/构建/Lint 回归 | iOS `HealthDashboardView` + `ScrollViewPanObserver`；HarmonyOS `PullToRefreshState.ets` + `SignedInPage.HealthDashboard`；三端中英刷新文案与资源清单同步 | ✅（编译与静态验证；双端交互截图待设备人工复核） |
| `HLTH-UI-ARCH-014` | HarmonyOS 刷新阈值与主体停留高度独立可调 | `.refreshOffset(PULL_REFRESH_HOLD_OFFSET)`、`.pullToRefresh(false)`、手动释放资格静态检查由无匹配红灯转绿；HarmonyOS `hvigorw assembleApp --no-daemon` | `SignedInPage.handleRefreshOffset/finishRefreshGesture/beginHarmonyRefresh`；有效 `refreshOffset` 使用停留高度，80 阈值由页面独立判定 | ✅ |
| `HLTH-UI-ARCH-015` | iOS 账号切换刷新由长期存活 ViewModel 持有，首页展示 pending/refreshing/resetting 全周期 | 上一版请求被旧 View 抢先认领后用户复验仍无动画；修订门禁产生 13 项红灯，ViewModel 所有权实现后通过；iOS Simulator 构建 | `HealthDashboardViewModel.accountRefreshPending/accountRefreshPhase/accountRefreshTask/startPendingAccountRefresh`；`HealthDashboardView.effectiveRefreshPhase/effectiveDragOffset`；`AuthCoordinator` 登录 true/退出 false | ⚠️（结构与构建通过，换号动画待设备人工复验） |

---

## health-editable-normal-data.md 追溯

| Spec ID | 规范 | 测试/验证 | 实现/文档 | 状态 |
|---------|------|-----------|-----------|------|
| `HLTH-EDIT-001` | 默认、持久化与恢复统一使用最小健康源数据 | `EditableHealthDataTest.editableSourcePersistsOnlyCanonicalInputsAndRebuildsDerivedData`；全量 common 测试 | `health_dashboard_mock.proto`、`EditableHealthData`、`MockHealthDashboardStoreJson`、`HealthDashboardStore.resolveSnapshot` | ✅ |
| `HLTH-EDIT-002` | 正常数据草稿仅驻留进程内，刷新成功才提交持久化 | `normalDraftDoesNotChangeSnapshotUntilRefreshAndIsNotRestored` | `HealthDashboardStore.transientNormalDraft` / `refresh`；`HealthStore.normalDraftForEditing` | ✅ |
| `HLTH-EDIT-003` | 支持单模块恢复默认和整套使用默认数据 | `singleModuleAndWholeDraftRestoreUseCommonDefaults`；专项结构门禁 | `HealthEditableRules.restoreSection/restoreAll`；三端编辑总览与模块页 | ✅ |
| `HLTH-EDIT-004` | 所有派生业务规则只位于 common | `commonFormSchemaAppliesRawPlatformInputsAndGeneratesCanonicalSequences`、`derivedWeeklyPlanUsesOnlyWorkoutTypeAndDistance`；`./gradlew :common:check` | `HealthEditableRules`、`HealthEditableForms`；平台只提交原始字段并渲染共享表单 | ✅ |
| `HLTH-EDIT-005` | common 快捷生成完整心率与压力序列 | `heartAndStressGeneratorsProduceDeterministicFullSequences` | `HealthEditableRules.generateHeartRateSamples/generateStressSamples`；快照只保存 288/48 完整序列 | ✅ |
| `HLTH-EDIT-006` | 三端提供独立正常数据总览和模块编辑原生路由 | `./tools/check-health-editable-normal-data.sh`；Android/iOS/HarmonyOS 构建 | Android `NormalDataEditor`/Navigation Compose；iOS `NormalDataEditor.swift`/Coordinator；HarmonyOS 两个 `@Entry` 页面/Router | ✅（设备返回与输入体验待人工复验） |
| `HLTH-EDIT-007` | 三端保存提示 latest-wins 并在 1500ms 后消失 | 专项结构门禁；三端构建 | Android eventId + `LaunchedEffect(1500)`；iOS cancel task + 1.5s；HarmonyOS native toast 1500ms | ✅（连续快速保存待设备人工复验） |
| `HLTH-EDIT-008` | 睡眠阶段连续且结束时间由 common 计算 | `sleepStagesMustBeContinuousAndEndTimeIsDerived` | `HealthEditableRules.validateSleep/derive`；`HealthEditableForms.apply` 重建连续区间 | ✅ |
| `HLTH-EDIT-009` | common 新增编辑/派生健康键必须进入 Android 与 HarmonyOS 显式本地化解析白名单 | `check-health-editable-normal-data.sh` 首次 148 项缺键红灯，修复后通过；Android/iOS/HarmonyOS 构建 | Android `HealthLocalization.healthStringResource`；HarmonyOS `HealthLocalization.healthResource`；三端 `health_visual_workout_rest` 资源；HarmonyOS 模块页常驻字段标签 | ✅ |
| `HLTH-EDIT-010` | 三端编辑页保存操作、常驻字段提示和输入内容在深色界面清晰一致 | `check-health-editable-normal-data.sh`；三端构建；Android emulator-5554 截图 | common `labelArguments`；Android `common_save` 直接使用通用资源、固定操作区与高对比输入色；iOS/HarmonyOS 常驻字段标签 | ⚠️（Android 保存按钮实机通过；iOS/HarmonyOS 本轮无运行设备） |
| `HLTH-EDIT-011` | 睡眠阶段由 common 表单规则动态新增、删除、重编号并连续保存 | `EditableHealthDataTest.dynamicSleepStagesAreMutatedAndAppliedByCommon`；全量 `:common:check` | `HealthEditableForms.mutate`、`HealthEditRepeatGroup`、三端 RepeatGroup editor 与 facade/bridge | ✅ |
| `HLTH-EDIT-012` | 体型锻炼部位使用 common 选项集并支持数量可变的增删选择 | `EditableHealthDataTest.dynamicMuscleGroupsUseSharedSelectableOptions`；全量 `:common:check` | `BodyMuscleGroup`、`HealthEditableRules.validate`、`HealthEditableForms.mutate/apply`、三端 Choice 重复项 | ✅ |
| `HLTH-EDIT-013` | 三端体型卡片右侧人体图区域反映 common 输出的当前锻炼部位 | `EditableHealthDataTest.bodyVisualUsesSelectedMuscleIds`；专项结构门禁；三端构建 | common `bodyVisual.metrics`；Android `MuscleMarker`、iOS `muscleMarker`、HarmonyOS `MuscleMarker`；人体底图 Template 中和 | ⚠️（业务输出与构建通过，无连接设备） |
| `HLTH-EDIT-014` | HarmonyOS HRV 三角标记、横条和下方正常范围图例完整显示 | `check-health-editable-normal-data.sh`；`build-shared-harmony.sh`/`assembleApp` | `HrvAssessmentVisualComp.RangeMarker` 绝对定位；24vp 横条容器与双行范围图例 | ⚠️（ArkTS 构建通过，无连接设备） |
| `HLTH-EDIT-015` | 三端 Choice 字段同行展示并弹出统一深色选择面板，重复项添加操作统一绿色 | `check-health-editable-normal-data.sh` 首次 9 项红灯、修复后通过；三端构建；Android emulator-5554 选择/关闭/更新截图验收 | Android `ChoiceSelectionDialog`；iOS `choiceSelectionOverlay`；HarmonyOS `ChoiceSelectionOverlay`；三端 Choice 同行入口与 AddAction | ⚠️（Android 运行时通过；iOS/HarmonyOS 构建通过但本轮无设备截图） |
| `HLTH-EDIT-016` | Choice 下拉和当前项勾选统一复用 `right_more`/`ic_profile_check` 共享资源 | `check-health-editable-normal-data.sh` 首次 18 项红灯、修复后通过；资源门禁；三端构建；Android emulator-5554 截图 | 三端 `AppImages` ChoiceChevron/ChoiceCheck 语义映射；Android `AppImage`、iOS/ArkUI `Image` Template 着色；`right_more` 旋转 90° | ⚠️（Android 运行时通过；iOS/HarmonyOS 构建通过但本轮无设备截图） |
| `HLTH-EDIT-017` | 体型管理按 common 区域契约叠加同画布蒙版并只显示“本周锻炼部位” | `EditableHealthDataTest.bodyVisualDerivesAlignedHighlightRegions` 实现前因字段缺失编译红灯、实现后通过；专项门禁实现前 95 项红灯、实现后通过；16 份资源三端逐文件一致性检查；common/Android/iOS/HarmonyOS 构建；Android emulator-5554 截图 | common `bodyRegionsByMuscleGroup`/`highlightedBodyRegions`/`footer`；`health_dashboard_resources/body_muscle_masks`；三端 `AppImages` 语义映射与 Body visual 同画布 Template 蒙版叠加 | ⚠️（Android 运行时确认胸部/股四头肌精确高光；iOS/HarmonyOS 构建通过但本轮无设备截图） |
| `HLTH-EDIT-018` | Normal 刷新只保留用户体重及历史，草稿锻炼部位进入有效快照并改变高光 | `EditableHealthDataTest.bodyMuscleDraftReplacesOldMusclesOnRefreshWhileWeightHistoryIsPreserved` 实现前在刷新区域断言红灯、修复后通过；全量 `:common:check`；Android emulator-5554 实际选择“背部”并完成刷新前/后截图；三端构建 | `HealthDashboardStore.refresh` 只把旧 `weightKg/weightHistoryKg` 合并到草稿 `bodyManagement`，保留草稿 `trainedMuscleGroups`；专项结构门禁禁止旧整对象覆盖写法 | ⚠️（Android 完整编辑—刷新链路通过；iOS/HarmonyOS 共享逻辑与构建通过但本轮无设备截图） |
| `HLTH-EDIT-019` | HarmonyOS 模块编辑页保存按钮可点击并直接消费布尔保存结果 | 专项门禁实现前因字符串返回、Text 操作入口等 5 项红灯，修复后通过；KNOI bridge 生成与 HarmonyOS `assembleApp` 通过；设备点击待验收 | `HarmonyLoginService.saveNormalHealthEditForm`/生成 provider 返回 Boolean；`NormalDataSectionPage` 使用原生 Button、保存中禁用与直接布尔判断 | ⚠️（自动验证通过，鸿蒙设备点击待验收） |
| `HLTH-EDIT-020` | 体型管理正常数据编辑器只编辑锻炼部位并保留体重历史 | `EditableHealthDataTest.bodyManagementFormEditsOnlyMusclesAndPreservesWeightHistory` 实现前因表单仍含体重而红灯、实现后通过；专项门禁；`:common:check`；三端构建 | `HealthEditableForms.form/apply`；三端消费共享表单，无平台体重字段 | ✅ |
| `HLTH-EDIT-021` | iOS 正常数据编辑器使用 common 当前表单值初始化 | `./tools/check-account-profile-regressions.sh`；iOS Simulator 构建 | `NormalDataEditor.swift` 输入 Binding 缺本地值时回退 `field.value` | ⚠️（结构与构建通过，已有持久数据的设备展示待人工复验） |
| `HLTH-EDIT-022` | 五场景同构数据按内存/持久化优先级投影到编辑器，单模块审核不受其他缺失模块连带影响 | `abnormalScenarioProjectsCurrentMemoryAndPersistedValuesIntoEditor`、`partialScenarioCanSaveOneValidModuleWithoutAuditingMissingModules` 实现前因异常场景被强制替换为空草稿、整份数据联审而红灯，修复后通过；`:common:check`；三端构建 | `HealthEditableRules.project/validateSection/deriveSection`；`HealthDashboardStore.resolveBaseDraft/saveNormalDraft`；`HealthStore.normalDraftForEditing` | ✅ |
| `HLTH-EDIT-023` | 全空与数据损坏均映射 0/无数据但保留 Empty/Corrupted 来源语义 | `emptyAndCorruptedScenariosShareZeroProjectionButKeepDifferentSourceMeaning` 实现前因无来源状态 API 编译红灯，修复后通过；`check-health-cross-scenario-editing.sh`；三端构建 | `HealthEditSourceKind`/`HealthEditableProjection`；`HealthState.editSourceKind`；三端来源提示 | ⚠️（自动验证通过，三端来源提示待设备人工复验） |
| `HLTH-EDIT-024` | 编辑保存失败返回具体字段、原因和范围/数量参数 | `detailedFormAuditNamesTheFieldAndReasonInsteadOfReturningOnlyFalse` 实现前因保存仅返回 nullable/Boolean 编译红灯，修复后通过；专项门禁、资源门禁、三端构建 | `HealthEditValidationIssue`/`HealthEditApplyResult`/`applyDetailed`；Facade/KNOI 结果 JSON；三端字段级提示渲染 | ⚠️（自动验证通过，三端具体提示文案待设备人工复验） |
| `HLTH-EDIT-025` | HarmonyOS 正常数据输入框逐字符更新时保持稳定组件身份和当前焦点 | `check-health-input-focus-and-account-refresh.sh` 实现前因两处 key 包含字段值而红灯，改为稳定 `field.id` 后通过；HarmonyOS `assembleApp` | `NormalDataSectionPage` 独立字段和重复字段 `ForEach` key 均只使用 `field.id` | ⚠️（结构与构建通过，连续输入焦点待设备人工复验） |

---

## auth-mock-spec.md 本轮补充追溯

| Spec ID | 规范 | 测试/验证 | 实现/文档 | 状态 |
|---------|------|-----------|-----------|------|
| `AUTH-PROFILE-DEFAULT-001` | 首次资料完善以账号类型预填手机号/邮箱且用户名默认为 COROS user | `LoginUseCaseTest.profileDefaultsUseAccountTypeAndCorosUserName` 实现前因默认值 API/email 字段缺失编译红灯、实现后通过；专项门禁；三端构建 | `LoginRules.profileDefaults`、`UserProfile.email`、Proto/JSON/KNOI/Swift/ArkTS 资料链路及三端 Profile Completion UI | ✅ |
| `AUTH-PROFILE-FOCUS-001` | Android/HarmonyOS 离开输入操作后清焦点并收起键盘 | `./tools/check-account-profile-regressions.sh`；Android/HarmonyOS 构建 | Android `FocusManager.clearFocus(force=true)`；HarmonyOS API 12 `UIContext.getFocusController().clearFocus()` 接入非输入操作 | ⚠️（结构与构建通过，键盘/红色高光交互待设备复验） |

---

## three-platform-structure.md 追溯

| Spec ID | 规范 | 测试/验证 | 实现/文档 | 状态 |
|---------|------|-----------|-----------|------|
| `STRUCT-001` | common 大文件按职责拆分且公共 API 不变 | ✅ `./gradlew :common:check` 全绿 | ✅ 拆分 `HealthEditableForms.kt`→`HealthEditFormModels/HealthEditFormJson`；`EditableHealthData.kt`→`DefaultEditableHealthData/HealthEditableRules`；`MockHealthDashboardStoreJson.kt`→`HealthJson.kt`；`AuthRepository.kt`→`AuthStoreDataSource/LocalMockAuthRepository`；`MockAuthStoreJson.kt`→`AuthJson/JsonAuthStoreDataSource` | ✅ |
| `STRUCT-002` | health 导航按域从 auth 导航拆出，路由行为不变 | ✅ Android `assembleDebug`；iOS `xcodebuild`（Simulator build）；HarmonyOS `hvigorw assembleApp` 全部通过 | ✅ Android `health/navigation/HealthNavGraph.kt`+`HealthRoute.kt`（AuthNavGraph 单行挂载）；iOS `Health/Navigation/HealthNavigation.swift`（AuthCoordinator 转发）；HarmonyOS `AuthRoutes` 按 `auth/home/health/debug` 分组（interface 类型，13 个调用文件同步更新） | ✅ |
| `STRUCT-003` | 平台大文件按组件拆分，三端一一对应 | ✅ Android `./gradlew :androidApp:assembleDebug`；iOS/HarmonyOS 其余项未执行（见债务） | ⚠️ Android `ProfileCompletionScreen.kt`(883)→`ProfileFieldRows/ProfilePickerSheets/ProfileAvatarSheet/ProfileEditHelpers`（368 行主文件）；**债务**：HarmonyOS `ProfileCompletionPage.ets`(1557)、`SignedInPage.ets`(563)、三端 `AuthComponents.*`（.kt785/.swift608/.ets474）、三端 `NormalDataEditor`（.kt571/.swift519/页466）、iOS `HealthDashboardView.swift`(491) 未拆分 | ⚠️（部分完成，剩余为显式结构债务） |
| `STRUCT-004` | 拆分可追溯，不留孤儿代码 | ✅ `./tools/check-sdd.sh` 通过；`git diff --check` 无冲突标记；`./tools/check-docs.sh` 仅因既有 `docs/reference/注册登陆模块介绍.md` 可信哈希不一致失败（本轮未修改，见历史 worklog） | ✅ 本 TRACE 行记录拆前→拆后落点，无孤儿重复声明 | ✅ |
| `STRUCT-005` | common 包 `login` 重命名为 `auth` | ✅ `./gradlew :common:check` 全绿；Android `assembleDebug`；iOS `build-shared-xcframework.sh`+`xcodebuild`；HarmonyOS `build-shared-harmony.sh`（libkn.so 重建）+`hvigorw assembleApp` 全部通过 | ✅ `git mv` 目录（commonMain/commonTest login→auth）+ 47 处引用替换 + tools 7 个脚本路径同步 | ✅ |
| `STRUCT-006` | 错误类型聚合保持 auth 域（评估结论：不抽取） | ✅ `./gradlew :common:check` 全绿；三端构建通过 | ✅ 评估：`MockResult.Failure` 携带 `MockError`，`MockError` 引用 `AuthMessageKeys`/`HealthMessageKeys`，core 抽取会产生反向依赖；`MockResult`/`MockError`/`SessionResumeResult` 保留 `com.example.demo.common.auth` | ✅（已评估并记录结论） |
| `STRUCT-007` | `HarmonyLoginService.kt` 文件拆分，契约不变 | ✅ `hvigorw assembleApp` 通过；`provider.ets` git diff 为空（KNOI 契约不变） | ✅ `HarmonyHealthBridge`（内部委托类）+ `HarmonyHealthSnapshotJson`（序列化）；`HarmonyLoginService.kt` 558→338 行，health 方法委托 bridge | ✅ |
| `STRUCT-008` | iOS `SharedLoginAdapter.swift` 按域扩展拆分，契约不变 | ✅ iOS `xcodebuild` 通过 | ✅ `SharedLoginAdapter+Health.swift`（`extension SharedLoginAdapter`，healthFacade 放开为 internal）+ pbxproj 4 处登记 | ✅ |
| `STRUCT-009` | ArkTS `KnoiLoginAdapter.ets` 拆分评估 | ✅ 评估结论登记 | ✅ ArkTS 无跨文件 extension，需内部辅助类重构并同步 Preview/StorePersister，DevEco 预览 import 图依赖完整；暂缓为债务 | ✅（已评估并记录结论） |
| `STRUCT-010` | common 两个域按职责子包划分 | ✅ `./gradlew :common:check`（216 符号映射后全绿）；Android `assembleDebug`；iOS `build-shared-xcframework.sh`+`xcodebuild`；HarmonyOS `build-shared-harmony.sh`+`hvigorw assembleApp` 全部通过；`provider.ets` 无 diff | ✅ `git mv` auth/health 各 7 个子包（model/rules/store/usecase/repository/mock/facade），package 声明 + 190 处 import + 20 处 FQN 重写，36 处误导入清理，4 处残留修正 | ✅ |

---

## mock-server-api-spec.md 追溯

| Spec ID | 规范 | 测试/验证 | 实现/文档 | 状态 |
|---------|------|-----------|-----------|------|
| `MSRV-001` | Mock 服务器是唯一权威数据源 | `node --test test/contract.test.js`：`MSRV-001: 登录默认种子账号返回服务器权威会话`、`MSRV-001: 健康 GET 返回服务器权威数据（空态为 EMPTY_DATA）` | `mock-server/src/store.js`、`mock-server/src/app.js` | ✅ |
| `MSRV-002` | HTTP 请求只位于三端平台层 | `./gradlew :androidApp:testDebugUnitTest --tests 'com.example.demo.auth.data.RemoteAuthRepositoryTest'`（12 条通过）；`./gradlew :common:compileKotlinIosSimulatorArm64` + iOS `xcodebuild`；`:androidApp:assembleDebug`、`:androidApp:lintDebug` | `common` 无网络类型；Android `RemoteAuthRepository`/`RemoteHealthDashboardStateDataSource`/`MockServerHttpClient`/`MockServerConfig`；iOS `iosMain` `IosRemoteAuthRepository`/`IosRemoteHealthDashboardStateDataSource`/`IosHttpTransport`（Swift 注入 URLSession）；HarmonyOS `MockServerSync.ets`（ArkTS `ohos.net.http`） | ✅（Android/iOS）⚠️（HarmonyOS 代码已写，待 DevEco 构建验证） |
| `MSRV-003` | 认证按业务逐接口请求 | 服务端 21 条契约测试 + Android `RemoteAuthRepositoryTest` 12 条（login/register/verify-code/regions/hasAccount/profile/password/logout/account 全部映射）；iOS 逻辑复用同一契约（编译验证） | `mock-server/src/app.js` 认证域路由；Android `RemoteAuthRepository`；iOS `IosRemoteAuthRepository` | ✅（服务端 + Android + iOS 编译） |
| `MSRV-004` | 健康快照按 `userId` 整文档读写 | 服务端契约测试（PUT 读回/隔离/场景）+ Android `healthSourceRoundTripsSnapshot`/`healthSourceEmptyReturnsNull`；iOS 同契约 | `mock-server/src/app.js` 健康域路由；Android `RemoteHealthDashboardStateDataSource`；iOS `IosRemoteHealthDashboardStateDataSource` | ✅（服务端 + Android + iOS 编译） |
| `MSRV-005` | HTTP 状态码映射到既有错误语义 | Android `RemoteAuthRepositoryTest` 错误路径断言 + 服务端 HTTP 状态映射 | Android/iOS `parseError`（`MockErrorMessage.toMockError`）；服务端 HTTP_BY_ERROR | ✅（服务端 + Android/iOS 客户端映射）⚠️（网络不可达的专用枚举与三端文案未落地） |
| `MSRV-006` | 会话由服务器签发，客户端冷启动惰性校验 | Android `RemoteAuthRepositoryTest`：`sessionExpiresAfterBackgroundTtlWhenClockAdvances`、`sessionSurvivesBackgroundWithinTtl`（先因 `nowEpochMs` 缺注入而 TTL 永不失效，注入真实时钟后通过）；Harmony `syncFromServer` 本地会话失效时不恢复服务器会话 | Android `RemoteAuthRepository`（注入 `nowEpochMs`）本地 TTL + 冷启动恢复；iOS `IosRemoteAuthRepository` 本地 TTL；Harmony `MockServerSync.ets` 本地登录态权威保护；`GET /api/auth/session?userId=` 已提供 | ⚠️（Android 已验证；iOS 复用同一逻辑；Harmony 待 DevEco 验证） |
| `MSRV-007` | 三端 base URL 为平台注入配置 | Android `MockServerConfig.baseUrl` + `network_security_config.xml`（10.0.2.2/localhost 明文）+ `assembleDebug`；iOS `IosMockServerConfig.baseUrl`（localhost）+ xcodebuild；HarmonyOS `MockServerSync.ets` `MOCK_SERVER_BASE_URL` | `androidApp/.../core/network/MockServerConfig.kt`、`common/src/iosMain/.../net/IosMockServerConfig.kt`、`harmonyApp/.../core/bridge/MockServerSync.ets` | ✅（Android/iOS）⚠️（HarmonyOS 待设备验证） |
| `MSRV-007-PORT` | mock server 数据按端口隔离 | `cd mock-server && npm test` 27/27 通过；双实例脚本（3000/3001）各自独立文件 `mock-server-store-{PORT}.json`，互不出现对方账号（grep 计数 3/0 验证） | `mock-server/src/server.js`（`DATA_FILE` 按 PORT 派生）、`mock-server/src/store.js`（`configureDataFile`）、`mock-server/README.md` | ✅ |
| `MSRV-008` | HarmonyOS 通过 ArkTS 侧 HTTP 复用 KNOI 快照入口 | 服务端 4 个 snapshot 端点契约测试 2 条通过（`MSRV-008: 认证 store 快照可按 userId 拉取与提交`、`MSRV-008: 健康快照集合可整体拉取与提交`）；HarmonyOS 代码已写、待 DevEco 构建 + KNOI 契约 diff | `harmonyApp/.../core/bridge/MockServerSync.ets`（`@ohos.net.http` + `syncFromServer/syncToServer`）、`StorePersister.ets`（启动拉取/保存推送）、`module.json5` INTERNET 权限；服务端 `/api/sync/auth`、`/api/sync/health` | ⚠️（服务端 ✅；ArkTS 代码已写，本环境无 DevEco/hvigor，构建与 provider.ets 契约 diff 待验证） |
| `MSRV-008-SYNC` | 快照同步按用户合并，不整体覆盖其他端数据 | `cd mock-server && npm test`：`MSRV-008-SYNC: 同步健康快照按 userId 合并，不覆盖其他用户`、`MSRV-008-SYNC: 认证 store 同步只更新当前会话用户，不覆盖其他账号`（先因 replaceAll 覆盖红、改 merge 后绿）；27/27 通过；端到端脚本验证 B 用户保留 | 服务端 `PUT /api/sync/health` 改为逐条 `saveHealthSnapshot` upsert、`PUT /api/sync/auth` 只处理当前会话用户；鸿蒙 `MockServerSync.syncToServer` 只提交当前 userId、`syncFromServer` 未登录跳过 auth 且服务器无该用户时保留本地；`KnoiLoginAdapter.submit` 成功后 `syncFromServer` | ✅（服务端已验证；鸿蒙代码待 DevEco 构建验证） |
| `MSRV-009` | 本地持久化降级为缓存兜底 | Android `RemoteHealthDashboardStateDataSource` 以本地数据源作缓存（网络失败回退本地）；`RemoteAuthRepository` 以 `AndroidAuthStoreDataSource` 作会话缓存；iOS 同模式；HarmonyOS `StorePersister` 保留本地 prefs + 同步失败沿用缓存 | Android/iOS remote 数据源 cache 兜底；`harmonyApp/.../core/bridge/StorePersister.ets` | ⚠️（Android/iOS 落地；HarmonyOS 代码已写，运行时待验证） |
| `MSRV-010` | 三端数据一致靠服务器权威 + 刷新拉取 | 待补：三端交叉验收（需服务器运行 + 多端登录） | 待补：三端刷新接入 | ⏳ |
| `MSRV-011` | 服务器不可达或写失败时展示明确错误 | 待补：错误提示测试（三端 UI） | 待补：三端错误提示接入 | ⏳ |
| `MSRV-012` | 种子数据与场景模板由服务器提供 | `node --test test/contract.test.js`：`MSRV-012: 重置后种子账号与健康空态可恢复`；`mock-server/src/store.js` 种子账号与 REGIONS | `mock-server/src/store.js`（seedAccounts/REGIONS/DEFAULT_VERIFY_CODE）；`mock-server/README.md` | ✅ |
| `MSRV-013` | 服务器不包含任何真实凭据或敏感信息 | `git diff` 人工核对；`mock-server/src/*.js` 与 `data/`（gitignore）扫描 | `mock-server/.gitignore` 排除 `data/`；README 明确 mock 约定 | ✅（服务端已满足；三端与门禁扫描待后续轮） |
| `MSRV-014` | `/api/sync/auth` 遍历全部账号 upsert，会话按 userId 匹配；`buildUserId` 与 common Int32 语义一致 | `cd mock-server && npm test`：`MSRV-008: 注册新账号经 sync/auth 持久化（非首个账号也能保存）` 先红（accounts[0] 之外丢失）后绿；22/22 通过 | `mock-server/src/app.js` PUT `/api/sync/auth`；`mock-server/src/store.js` `buildUserId` | ✅ |
| `MSRV-015` | 头像保存真实内容（base64 data URI，缩放 + JPEG 统一编码），跨设备可展示 | Android `:androidApp:assembleDebug`/`lintDebug` 通过；iOS `xcodebuild` 通过；服务端 22/22 契约测试；mock data 旧 769KB 原图 base64 已清理，改为 512px JPEG | Android `ProfileEditHelpers.scaleToAvatar/toAvatarDataUri/decodeAvatarDataUri`；iOS `ProfileImageStore.downscaledJPEG/save/image(at:)`；Harmony `avatarToDataUri`（decode→scale→pack→base64）+ `AvatarImage.ets`（`scalePixelMap`/`AVATAR_MAX_DIMENSION`） | ✅（Android/iOS 编译验证）⚠️（Harmony 代码已写，待 DevEco 构建验证） |

---

## 使用约定

1. **新加功能**：先在 `spec/` 下写 .md 或追加章节 → 在本文件预留映射行（状态标为 ⏳）→ 写测试 → 写实现 → 改状态为 ✅
2. **Codex 协作**：`Codex_worklog.md` 的每一条“采纳/审查/验证/修正”必须引用稳定 Spec ID；历史 Spec 尚无稳定 ID 时可引用章节号，例如 `[auth-mock-spec §8]`
3. **评审验收**：按 TRACE.md 逐条核对 Spec 落地情况

## 跨平台预览注解

> 旧计数仅代表历史注解存在性；完整生产页面、独立视觉组件与跨语言 fixture 的新验收口径见 `cross-platform-ui-previews.md`。

| Spec 章节 | 对应代码位置 | 状态 |
|-----------|-------------|------|
| **iOS #Preview** | 23 个 View 文件均有 `#Preview` 块（Login/Home/Account/Health 全部 View 和组件） | ✅ |
| **HarmonyOS @Preview** | 6 个纯 `@Component` 文件均有 `@Preview` 装饰器（DashboardCard/HeroTopRow/Metric/ScenarioPicker/HealthDetail/CardEditor） | ✅ |
| **Android @Preview** | 21 个 Compose 屏幕/组件文件均有 `@Preview` 注解 | ✅ |

## cross-platform-ui-previews.md 追溯

| Spec ID | 规范 | 测试/验证 | 实现/文档 | 状态 |
|---------|------|-----------|-----------|------|
| `UI-PREVIEW-001` | common 提供确定性健康 Preview fixture | `HealthPreviewFixturesTest.normalPreviewStateContainsEveryCardWithDeterministicVisualData`；`./gradlew :common:check` | `HealthPreviewFixtures.normalState()` | ✅ |
| `UI-PREVIEW-002` | Android 直连、iOS typed mapping、HarmonyOS KNOI JSON 映射 | Android/iOS/HarmonyOS 平台构建通过；`./tools/check-ui-previews.sh` | `HealthDashboardScreen`、`HealthDashboardViewModel.init(previewState:)`、`HarmonyLoginService.previewHealthSnapshot()`、ArkTS `loadPreview()` | ✅ |
| `UI-PREVIEW-003` | 三端生产导航页面均有可发现 Preview | 门禁检查 Android 19、iOS 20、HarmonyOS 16 个生产页面；三端平台构建通过 | 三端页面文件中的 `@Preview` / `#Preview` | ✅ |
| `UI-PREVIEW-004` | 独立复用组件可预览有数据/预填状态 | 组件目录经门禁且三端构建通过；IDE Canvas 人工视觉检视待执行 | Android/iOS 既有命名 Preview、HarmonyOS `ComponentPreviewCatalog.ets` | ⚠️ |
| `UI-PREVIEW-005` | 显式清单门禁防止覆盖回退 | `./tools/check-ui-previews.sh`（实现前 24 项失败，实现后通过） | `tools/check-ui-previews.sh` | ✅ |
| `UI-PREVIEW-006` | 带 `@Prop/@Link/@ObjectLink/@Consume` 的 ArkUI 子组件只通过无外部依赖父 Host 预览 | 门禁实现前定位 2 个直接预览违规，实施后 `./tools/check-ui-previews.sh` 与 HarmonyOS `assembleApp` 通过；Catalog 无 service/lifecycle 调用 | `HealthComponentPreviewCatalog`、`CardEditorPreviewHost`、`HealthDetailPreviewHost`；子组件移除直接 `@Preview` | ✅ |
| `UI-PREVIEW-007` | 每个生产 SwiftUI View 文件至少有一个 `#Preview` | 门禁实现前定位 16 个缺失文件，实施后 40/40 文件覆盖且 iOS Simulator `xcodebuild` 通过 | 13 个健康 Visual 文件、`AuthCoordinator.swift`、`AuthComponents.swift`、`AppResources.swift`；`previewHealthVisual()` | ✅ |
| `UI-PREVIEW-008` | ArkUI Preview 静态 import 图不得加载 KNOI native module | 用户 Previewer 日志复现 `knoi.setup` 导出错误；专项门禁实现前 7 项失败，实施后通过；HarmonyOS `assembleApp` 通过 | `HarmonyLoginServiceContract`、`PreviewLoginAdapter`、惰性 `LoginViewModelProvider`、`KnoiHarmonyServiceAdapter`、`EntryAbility` 安装边界 | ✅ |
| `UI-PREVIEW-009` | Android/HarmonyOS 每个健康 Visual 模块有专项 Preview；ArkTS 单文件不超过 10 个 Preview 且对象数组显式类型化 | 用户 DevEco Previewer 报告 2 项设计态错误；专项门禁红灯复现后通过，HarmonyOS `assembleApp` 通过 | Android 文件内命名 Preview 与 `previewHealthVisual()`；HarmonyOS 10+2 拆分纯父 `VisualPreviewCatalog*.ets`/显式契约数组 `VisualPreviewData` | ✅ |
