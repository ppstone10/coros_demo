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
| `DOC-008` | 测试事实同步 | `tools/check-docs.sh` 动态核对 `@Test`：29/7/4/15，合计 55 | `TEST_REPORT.md`、本文件 | ✅ |
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
| **测试要求 - 12 条以上** | `HealthDashboardUseCaseTest.kt` → **15 条测试** | ✅ |
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

## 测试总览

| 测试类 | 测试数 | 所属 Spec |
|--------|--------|-----------|
| `LoginRulesTest.kt` | 7 | auth-mock-spec §7, §8, §9 |
| `LoginUseCaseTest.kt` | 29 | auth-mock-spec §14 |
| `BusinessMockDataSourceTest.kt` | 4 | auth-mock-spec §10, §11, §14 |
| `HealthDashboardUseCaseTest.kt` | 15 | health-dashboard-cards 测试要求 |
| **合计** | **55** | |

---

## 使用约定

1. **新加功能**：先在 `spec/` 下写 .md 或追加章节 → 在本文件预留映射行（状态标为 ⏳）→ 写测试 → 写实现 → 改状态为 ✅
2. **Codex 协作**：`Codex_worklog.md` 的每一条“采纳/审查/验证/修正”必须引用稳定 Spec ID；历史 Spec 尚无稳定 ID 时可引用章节号，例如 `[auth-mock-spec §8]`
3. **评审验收**：按 TRACE.md 逐条核对 Spec 落地情况
