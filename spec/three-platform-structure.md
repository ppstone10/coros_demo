# 三端目录结构与文件拆分 Spec

## 元数据

- Spec ID 前缀：`STRUCT`
- 状态：已采纳
- 负责人：shiliangcan
- 关联需求：三端目录对齐（auth/health/home/core）已完成 Phase 0-1，本轮为 Phase 2「结构收敛」
- 最后更新：2026-08-04

## 目标

- 将超过行数阈值的大文件按职责拆分，使每个文件只承载一个清晰职责。
- 将寄生在 auth 导航中的 health 路由按域拆出，health 域拥有自己的导航位置，三端结构对称。
- 全程保证公共 API、稳定消息键、proto 契约与可观察行为不变；三端文件在拆分后仍能一一对应。

## 非目标

- 不重命名 common 包（`login`→`auth`、抽取 `core/`），该工作属 Phase 3。
- 不拆分适配层混合文件（`HarmonyLoginService`/`KnoiLoginAdapter`/`SharedLoginAdapter` 按域拆分），属 Phase 4。
- 不引入组合根 DI（`AppContainer`），属 Phase 3/4。
- 不改变任何业务规则、本地化键、proto 字段或持久化格式。
- 不删除文档历史；`docs/worklog/`、`docs/archive/` 只追加。

## 边界与约束

- 架构边界：拆分只发生在各端平台目录与 `common/src/commonMain` 内部；不改变跨语言门面签名。
- 兼容性边界：所有 public 符号（类、函数、枚举名、消息键）保持原名与签名；拆出的文件内声明保持不变。
- 失败边界：任何拆分必须通过既有测试与对应端构建；否则视为行为回归，立即回滚该批。
- 平台边界：iOS 拆文件后需同步 Xcode 工程引用；HarmonyOS 拆 .ets 需同步相对 import；Android 拆 .kt 需同步 package 声明（同一包内拆分不需要）。

## 数据与状态

| 名称 | 类型/结构 | 来源 | 生命周期 | 约束 |
|------|-----------|------|----------|------|
| 迁移映射表 | `spec/three-platform-structure.md` + 本 Spec 追溯 | 现状代码 | 本轮 | 每个拆分文件对应一行，改动前确认无遗漏 |
| 既有测试 | commonTest / androidTest / JVM test | 现状 | 永久 | 拆分后必须全绿，作为行为不回归的证据 |
| 三端门禁脚本 | `tools/check-*.sh` | 现状 | 永久 | 结构门禁可能引用旧文件路径，拆分后同步更新 |

## 行为规范

### `STRUCT-001`：common 大文件按职责拆分且公共 API 不变

- Given：`HealthEditableForms.kt`(748)、`EditableHealthData.kt`(716)、`MockHealthDashboardStoreJson.kt`(681)、`AuthRepository.kt`(534)、`MockAuthStoreJson.kt`(518)
- When：按「模型 / 规则 / 编解码 / 默认值」拆分为独立文件（同一包 `com.example.demo.common.health` / `.login`）
- Then：所有 public 类型与函数签名保持不变，仅文件落点变化；`./gradlew :common:check` 全绿
- 异常/边界：拆分中如发现私有依赖交叉，保持同一对象内的私有成员不动，只按 public 类型边界切分

### `STRUCT-002`：health 导航按域从 auth 导航拆出，路由行为不变

- Given：Android `AuthNavGraph.kt` 内嵌 health 路由；iOS `AuthCoordinator.swift` 内嵌 health case；HarmonyOS `AuthRoutes.ets` 混合 auth/health 常量
- When：Android 将 health 的 composable 组合抽到 `health/navigation/HealthNavGraph.kt`（`NavGraphBuilder` 扩展）；iOS 抽 `HealthRouter`；HarmonyOS `AuthRoutes` 常量按 `auth`/`health`/`home` 分组
- Then：页面可达性与二级路由 Push/Pop 行为与拆分前完全一致；三端构建通过
- 异常/边界：HarmonyOS `main_pages.json` 与 URL 常量字符串不得改变；Android `NavHost` 容器保持单一

### `STRUCT-003`：平台大文件按组件拆分，三端保持一一对应

- Given：HarmonyOS `ProfileCompletionPage.ets`(1557)、Android `ProfileCompletionScreen.kt`(883)、三端 `AuthComponents.*`（.kt 785 / .swift 608 / .ets 474）、`NormalDataEditor` 三端、HarmonyOS `SignedInPage.ets`(563)、iOS `HealthDashboardView.swift`(491)
- When：按页面骨架与区块组件拆分；`AuthComponents` 按组件拆分独立文件
- Then：每端拆分后文件仍能在另两端找到同语义对应物；三端构建通过
- 异常/边界：`AuthComponents` 为三端同步拆分，避免单端拆后结构失衡

### `STRUCT-004`：拆分可追溯，不留孤儿代码

- Given：任一拆分文件
- When：拆分完成
- Then：`spec/TRACE.md` 对应行记录拆前→拆后文件落点与验证命令；旧文件不再残留重复声明；`git diff --check` 无冲突标记
- 异常/边界：拆分中被移动的私有常量/扩展函数必须一并迁移，不得在源文件留下悬空引用

## 测试要求

| Spec ID | 自动化测试/人工验收 | 预期结果 |
|---------|---------------------|----------|
| `STRUCT-001` | `./gradlew :common:check`（既有 commonTest 全量回归） | 全部通过；无 public API 变化 |
| `STRUCT-002` | Android `./gradlew :androidApp:assembleDebug`；iOS `xcodebuild`；HarmonyOS `hvigorw assembleApp` | 三端构建通过；导航行为人工抽查 |
| `STRUCT-003` | Android `assembleDebug`；iOS `xcodebuild`；HarmonyOS `assembleApp` | 三端构建通过 |
| `STRUCT-004` | `./tools/check-sdd.sh`；`./tools/check-docs.sh`；`git diff --check` | 门禁通过；无冲突标记 |

> 说明：本轮全部为「行为零变化的文件拆分」，不新增业务测试；既有测试（commonTest 合计 123 条 + 平台构建）即回归网。无法自动化的人工验收为各端构建与页面交互抽查，原因：文件拆分不改变行为，且跨语言桥接需真实构建验证。

## 验收标准

- [ ] 所有 `STRUCT-*` 规范 ID 已在 `spec/TRACE.md` 建立映射（含 `⏳` → `✅` 过程）。
- [ ] common 五个大文件拆分后 `./gradlew :common:check` 全绿。
- [ ] health 导航按域拆出后，三端构建通过且页面可达性不变。
- [ ] 平台大文件拆分后，三端构建通过，文件仍可一一对应。
- [ ] `tools/check-*.sh` 中引用旧文件路径的脚本已同步更新。
- [ ] 没有引入「非目标」中的行为（无包重命名、无桥接拆分、无 DI、无业务变更）。
- [ ] TRACE、`Codex_worklog.md` 和必要的 `LEARNINGS.md` 已更新。

## 待人工确认

- 无（本轮为纯结构拆分；包重命名与桥接拆分属后续 Phase，将另立 Spec）

---

# 阶段 5 增补：common 内部子包划分

## 目标（阶段 5 增量）

- 在 `com.example.demo.common.auth` 与 `.health` 内部按职责划分子包，使每个文件落点能一眼看出职责层。
- 三端目录（auth/health 的 data/viewmodel/screens/...）与 common 子包（model/rules/store/usecase/repository/mock/facade）形成语义映射。
- 保持公共类型名与跨语言导出（Swift/KNOI）不变，仅改变包路径。

## 非目标（阶段 5）

- 不拆分文件内部内容（如 `HealthDashboardStore.kt` 内的接口/实现同文件保留）。
- 不移动 `MockResult`/`MockError`（auth 域错误聚合，见 STRUCT-006）。
- 不改变任何行为、消息键、proto 字段或方法签名。

## 子包划分

### auth（7 个子包）

| 子包 | 文件 |
|------|------|
| `model` | `LoginModels.kt`、`AuthMessageKeys.kt` |
| `rules` | `LoginRules.kt` |
| `store` | `LoginStore.kt` |
| `usecase` | `LoginUseCase.kt` |
| `repository` | `AuthRepository.kt`、`AuthStoreDataSource.kt`、`BusinessMockDataSource.kt` |
| `mock` | `LocalMockAuthRepository.kt`、`MockAuthStoreJson.kt`、`AuthJson.kt`、`JsonAuthStoreDataSource.kt` |
| `facade` | `LoginFacade.kt` |

### health（7 个子包）

| 子包 | 文件 |
|------|------|
| `model` | `HealthModels.kt`、`HealthDashboardModels.kt`、`HealthDashboardVisuals.kt`、`EditableHealthData.kt`、`HealthEditFormModels.kt`、`HealthMessageKeys.kt`、`HealthMockContracts.kt` |
| `rules` | `HealthRules.kt`、`HealthEditableRules.kt`、`HealthEditableForms.kt` |
| `store` | `HealthStore.kt`、`HealthDashboardStore.kt`（含 `HealthDashboardStateDataSource`/`InMemoryHealthDashboardStateDataSource`/`PersistedDashboard` 同文件保留） |
| `usecase` | `HealthDashboardUseCase.kt` |
| `repository` | `HealthDashboardDataSource.kt`、`LocalHealthDashboardDataSource.kt`、`JsonHealthDashboardStateDataSource.kt` |
| `mock` | `HealthDashboardMock.kt`、`MockHealthDashboardStoreJson.kt`、`HealthJson.kt`、`HealthEditFormJson.kt`、`HealthPreviewFixtures.kt`、`SimulatedHeartRateSamples.kt`、`DefaultEditableHealthData.kt` |
| `facade` | `HealthFacade.kt` |

## 行为规范

### `STRUCT-010`：common 两个域按职责子包划分

- Given：`auth`/`health` 下平铺 13+24 个文件
- When：`git mv` 到子目录并同步 `package` 声明；更新 common 内部与三端全部 import
- Then：`./gradlew :common:check` 全绿；Android `assembleDebug`、iOS framework+xcodebuild、HarmonyOS KNOI+hvigorw 全部通过
- 异常/边界：同子包内类型不加 import；跨子包/跨域引用由编译器错误清单逐一补齐；Swift/KNOI 类名不变

## 测试要求

| Spec ID | 自动化测试/人工验收 | 预期结果 |
|---------|---------------------|----------|
| `STRUCT-010` | `./gradlew :common:check`；Android `assembleDebug`；iOS `build-shared-xcframework.sh`+`xcodebuild`；HarmonyOS `build-shared-harmony.sh`+`hvigorw assembleApp` | 全部通过 |

> 纯包路径调整不新增业务测试；既有 commonTest 与三端构建即回归网。

---

# 阶段 4 增补：适配层文件拆分（契约稳定）

## 目标（阶段 4 增量）

- 拆分桥接/适配大文件，使每个文件只承载一个清晰职责。
- **保持跨语言契约不变**：KNOI `@ServiceProvider` 类与方法签名、Swift 适配类与协议、ArkTS provider 接口均不改变。

## 非目标（阶段 4）

- 不拆分为两个 KNOI `@ServiceProvider`（`HarmonyLoginService` + `HarmonyHealthService` 两个服务），那会改变 `provider.ets` 契约并需改 ArkTS 组合根；本轮以内部委托类拆分。
- 不改变任何业务行为、方法签名或快照 JSON 结构。

## 行为规范

### `STRUCT-007`：`HarmonyLoginService.kt`(558) 文件拆分，契约不变

- Given：单文件混合 login 转发 + health 转发 + 快照序列化
- When：抽取 `HarmonyHealthBridge`（内部类，持有 healthFacade，承载全部 health 方法）与 `HarmonyHealthSnapshotJson`（快照序列化 `healthSnapshotFromState`/`esc`）；`HarmonyLoginService` 保持单一 `@ServiceProvider`，health 方法委托给 bridge
- Then：`provider.ets` 不变；`hvigorw assembleApp` 通过；行为与拆分前一致
- 异常/边界：`MemoryAuthStoreDataSource`/`createFacade`/`createHealthFacade`/`syncClock` 保持 service 内，bridge 由 service 构造

### `STRUCT-008`：iOS `SharedLoginAdapter.swift`(419) 按域拆分为扩展文件，契约不变

- Given：单文件混合 auth 与 health 桥接方法
- When：保留 `SharedLoginAdapter` 类与 `SharedLoginAdapterProtocol`，health 方法抽到 `SharedLoginAdapter+Health.swift`（`extension SharedLoginAdapter`）
- Then：Swift 协议与调用方不变；`xcodebuild` 通过
- 异常/边界：跨扩展共享的 `syncClock`/facade 属性保持类内；新增文件需登记 pbxproj

### `STRUCT-009`：ArkTS `KnoiLoginAdapter.ets`(461) 拆分记录为债务

- Given：ArkTS 不支持跨文件 extension
- When：评估按域拆分
- Then：**结论为暂缓**——需以内部辅助类重构并同步 PreviewLoginAdapter/StorePersister，且 DevEco 预览门禁依赖完整 import 图，本轮登记为债务，后续专项执行
- 异常/边界：不在本轮强行拆分 ArkTS 类

## 测试要求

| Spec ID | 自动化测试/人工验收 | 预期结果 |
|---------|---------------------|----------|
| `STRUCT-007` | `hvigorw assembleApp --no-daemon`；`provider.ets` 内容对比 | 构建通过；provider 接口无 diff |
| `STRUCT-008` | iOS `xcodebuild` | 构建通过 |
| `STRUCT-009` | —（债务登记） | — |

---

# 阶段 3 增补：common 包重命名与 core 抽取

## 目标（阶段 3 增量）

- 将 `com.example.demo.common.login` 包重命名为 `com.example.demo.common.auth`，与三端目录命名对齐。
- 将纯通用的 `MockResult` 抽取到 `com.example.demo.common.core`，消除 health 对 auth 域通用 Result 类型的依赖。
- 同步更新三端 Kotlin 引用与工具脚本/文档中的旧路径。

## 非目标（阶段 3）

- 不移动 `MockError`/`SessionResumeResult`/`MockErrorMessage` 到 core（详见 `STRUCT-006` 评估结论）：`MockResult.Failure` 携带 `MockError`，而 `MockError` 编码 `AuthMessageKeys` 且引用 `HealthMessageKeys`，部分抽取会形成 core→auth/health 反向依赖；错误类型聚合整体保留在 auth 域。
- 不引入组合根 DI（`AppContainer`）；不拆适配层（Phase 4）。
- 不改变任何 public 类名、方法签名、消息键或 proto 字段；Swift/KNOI 导出的类名不变。

## 行为规范

### `STRUCT-005`：common 包 `login` 重命名为 `auth`

- Given：`common/src/commonMain/kotlin/com/example/demo/common/login/` 与 `commonTest` 对应目录，47 个 Kotlin 文件引用 `com.example.demo.common.login`
- When：`git mv` 目录 + 全部 package 声明与 import 同步替换
- Then：`./gradlew :common:check` 全绿；Android `assembleDebug`、iOS framework+xcodebuild、HarmonyOS KNOI+hvigorw 全部通过
- 异常/边界：Swift 侧按类名引用（`LoginFacade` 等）不受包名影响，仅需重编 framework；KNOI 按 service 类名生成，仅需重跑 `ohosArm64Binaries`

### `STRUCT-006`：错误类型聚合保持 auth 域（已评估，不抽取）

- Given：`MockResult.Failure` 携带 `MockError`；`MockError` 编码 `AuthMessageKeys` 且引用 `HealthMessageKeys`
- When：评估将 `MockResult` 单独抽取到 core
- Then：**结论为不抽取**——`MockResult` 与 `MockError` 是 auth 域错误模型聚合，部分抽取会形成 core→auth/health 消息键反向依赖；`MockResult`/`MockError`/`SessionResumeResult` 整体保留在 `com.example.demo.common.auth`，health 对 auth 的 `MockError`/`AuthRepository` 依赖属既有认证门禁设计
- 异常/边界：完整错误基础设施（含消息键归属）如要重排，需另立 Spec 并评估 `HealthMessageKeys` 的 core 归属，不在本轮范围

## 测试要求

| Spec ID | 自动化测试/人工验收 | 预期结果 |
|---------|---------------------|----------|
| `STRUCT-005` | `./gradlew :common:check`；Android `assembleDebug`；iOS `build-shared-xcframework.sh`+`xcodebuild`；HarmonyOS `build-shared-harmony.sh`+`hvigorw assembleApp` | 全部通过 |
| `STRUCT-006` | `./gradlew :common:check`；三端构建 | 全部通过 |

> 纯重命名不新增业务测试；既有 commonTest（123 条）与三端构建即回归网。工具脚本 `tools/check-*.sh` 中的旧路径随本轮同步更新。
