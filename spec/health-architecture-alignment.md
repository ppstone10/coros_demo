# Health 模块架构对齐 Spec

## 元数据

- Spec ID 前缀：`HLTH-MVI`
- 状态：已采纳
- 负责人：S04
- 关联需求：`health-dashboard-cards.md`、`health-ui-refactor.md`、`health-maintainability.md`
- 最后更新：2026-07-24

## 目标

将 Health 模块的 common 层架构从 UseCase-heavy 的 MVVM 改造为与 Login 一致的 MVI 模式，并同步三端（Android/iOS/HarmonyOS）的平台层适配，实现：

1. common 层输出 `HealthAction → HealthStore.dispatch() → HealthState + HealthEffect` 的完整 MVI 闭环
2. 独立 `HealthFacade` 跨语言门面，不再耦合在 `LoginFacade` 中
3. `HealthRules` 纯规则函数从 UseCase 中拆分
4. `HealthDashboardVisuals` 从 UseCase 中拆分
5. 三端 ViewModel 统一为薄包装模式（仅调用 `dispatch()` + `consumeEffect()`）
6. 三端平台层各自定义的 `HealthDashboardEffect` 删除，统一使用 common `HealthEffect`

## 非目标

- 不改动现有卡片 UI 视觉渲染逻辑
- 不改动 `HealthDashboardMock.kt` / `MockHealthDashboardStoreJson.kt` / `JsonHealthDashboardStateDataSource.kt` / `SimulatedHeartRateSamples.kt` 的内容
- 不改动 iOS Shared.xcframework / HarmonyOS KNOI bridge 的底层导出机制
- 不重构 `LoginStore` / `LoginFacade` 本身的架构
- 不涉及业务规则变更（卡片排序、状态判定、mock 场景行为等保持原样）

## 边界与约束

- 架构边界：Health MVI 闭环完全在 `common/.../health/`；Android/iOS/HarmonyOS 平台层只做薄适配
- 安全与数据边界：不改动 proto 定义，不改动 mock 数据内容，不改动认证门禁
- 兼容性边界：已有 `HealthDashboardUseCaseTest.kt` 的 39 条测试必须全部保持通过（不能因架构重组而改变测试语义）
- 失败边界：重构未完成时不得进入 `common:check` 或平台构建失败；允许中间状态工作区但必须在同一轮最终修复

## 数据与状态

| 名称 | 类型/结构 | 来源 | 生命周期 | 约束 |
|------|-----------|------|----------|------|
| `HealthAction` | sealed interface | 新建 | 入参，消费即弃 | 与 `LoginAction` 结构一致 |
| `HealthState` | data class | 新建 | `HealthStore` 持有，平台只读 | 与 `LoginState` 结构一致 |
| `HealthEffect` | sealed interface | 从平台移至 common | `HealthStore` 生产，平台消费即弃 | 与 `LoginEffect` 结构一致 |
| `HealthStore` | class(docspatch/consumeEffect) | 新建 | common 单次会话 | 与 `LoginStore` 结构一致 |
| `HealthFacade` | class | 新建 | 跨语言门面 | 与 `LoginFacade` 结构一致 |
| `HealthRules` | object | 新建 | 纯函数 | 与 `LoginRules` 结构一致 |
| `HealthMessageKeys` | object | 从 `AuthMessageKeys` 拆分 | common | 与 `AuthMessageKeys` 结构一致 |

## 行为规范

### `HLTH-MVI-001`：HealthAction 定义

- Given：Health MVI 架构
- When：平台层触发用户交互
- Then：平台层构建 `HealthAction` 并调用 `HealthStore.dispatch(action)`
- 异常/边界：所有 Action 继承 `sealed interface HealthAction`；include：`Load`、`ScenarioSelected(HealthMockScenario)`、`Refresh`、`CardConfigurationChanged(List<HealthCardType>)`、`EffectConsumed`、`AuthSessionExpired`

### `HLTH-MVI-002`：HealthState 定义

- Given：HealthStore 持有状态
- When：任意 `dispatch(action)` 执行后
- Then：`HealthStore.state` 更新为新的 `HealthState` 实例
- 异常/边界：`HealthState` 包含 `uiState: DashboardUiState?`、`isRefreshing: Boolean`、`currentScenario: HealthMockScenario`、`enabledCardTypes: List<HealthCardType>`、`error: HealthError?`

### `HLTH-MVI-003`：HealthEffect 迁移至 common

- Given：需要一次性效果（消息提示、场景切换、配置保存）
- When：`HealthStore.dispatch()` 处理后
- Then：`HealthStore.consumeEffect()` 返回 `HealthEffect?`
- 异常/边界：三端平台层的 `HealthDashboardEffect.kt` / `.swift` / `.ets` 删除，统一使用 common `HealthEffect`

### `HLTH-MVI-004`：HealthStore MVI 实现

- Given：HealthStore 持有 AuthRepository 和 HealthDashboardStateDataSource
- When：`dispatch(action)` 被调用
- Then：Store 内部执行业务逻辑（认证检查、数据加载、UI 转换），更新 `state` 和 `pendingEffect`
- 异常/边界：与 `LoginStore` API 一致（`var state`、`fun dispatch(action)`、`fun consumeEffect()`）

### `HLTH-MVI-005`：HealthFacade 独立门面

- Given：iOS/HarmonyOS 调用 Health 功能
- When：平台层调用 `HealthFacade` 方法
- Then：Facade 包装 `HealthStore.dispatch()` 和 `HealthStore.state`
- 异常/边界：`LoginFacade` 不再持有或代理任何 health 方法；`LoginStore` 不再持有 `healthDashboardStore`

### `HLTH-MVI-006`：HealthRules 纯函数提取

- Given：卡片排序和最小卡片验证逻辑
- When：`HealthDashboardUseCase.toUiState()` 需要排序
- Then：调用 `HealthRules.computeCardPriority()` / `HealthRules.validateMinimumCards()`
- 异常/边界：`HealthRules` 与 `LoginRules` 结构一致，纯 object 无副作用

### `HLTH-MVI-007`：HealthMessageKeys 独立

- Given：`AuthMessageKeys.ErrorMinimumCardsRequired` 当前在认证层
- When：重构后
- Then：该 key 迁移到 `HealthMessageKeys.ErrorMinimumCardsRequired`
- 异常/边界：`AuthMessageKeys` 不再包含 `health_*` 键

### `HLTH-MVI-008`：HealthDashboardUseCase 拆分

- Given：`HealthDashboardUseCase.kt` 当前 625 行
- When：重构后
- Then：拆分为 `HealthDashboardDataSource.kt`(接口)、`LocalHealthDashboardDataSource.kt`(mock 生成)、`HealthDashboardUseCase.kt`(仅 toUiState)、`HealthDashboardVisuals.kt`(card visual 构建器)
- 异常/边界：`HealthDashboardUseCase.toUiState()` 的输入输出签名不变

### `HLTH-MVI-009`：HealthDashboardVisuals 独立

- Given：14 个 card visual 构建器当前在 `HealthDashboardUseCase.kt` 中
- When：重构后
- Then：迁移至 `HealthDashboardVisuals.kt`
- 异常/边界：visual 构建器保持 `internal` 可见性

### `HLTH-MVI-010`：Android ViewModel 薄包装

- Given：Android `HealthDashboardViewModel` 当前使用 `StateFlow`
- When：重构后
- Then：改为 `mutableStateOf` + `consumeEffect()`，与 `LoginViewModel` 结构一致
- 异常/边界：`HealthDashboardViewModel` 不再定义 effect；三端页面依赖的 `effect: SharedFlow` 改为 `effect: HealthEffect?`

### `HLTH-MVI-011`：iOS ViewModel 薄包装

- Given：iOS `HealthDashboardViewModel` 当前直接调用 `adapter`（SharedLoginAdapter）
- When：重构后
- Then：改为调用 `HealthFacade` 或对应 `HealthStore` wrapper
- 异常/边界：`HealthDashboardEffect.swift` 删除，统一使用 common `HealthEffect`

### `HLTH-MVI-012`：HarmonyOS ViewModel + 桥接更新

- Given：HarmonyOS 当前通过 `HarmonyLoginService` JSON 桥接访问 health
- When：重构后
- Then：`HarmonyLoginService` 添加 `HealthFacade` 桥接方法；`HealthDashboardViewModel.ets` 调用新桥接
- 异常/边界：`HealthDashboardEffect.ets` 删除；桥接 JSON 字段不变

### `HLTH-MVI-013`：LoginStore/LoginFacade 不再代理 health

- Given：`LoginStore` 当前持有 `healthDashboardStore`
- When：重构后
- Then：移除 `healthDashboardStore` 字段及相关方法；`LoginFacade` 移除 `loadHealthDashboard()` / `selectHealthScenario()` / `refreshHealthDashboard()` / `saveHealthCardConfiguration()` / `healthDashboardError()` / `healthCardSaveError()`
- 异常/边界：`LoginStore.create()` / `LoginStore.createFake()` 签名不变，health 依赖通过外部注入解耦

### `HLTH-MVI-014`：三端平台 Effect 文件删除

- Given：三端各有一个 `HealthDashboardEffect`
- When：重构后
- Then：Android `HealthDashboardEffect.kt`、iOS `HealthDashboardEffect.swift`、HarmonyOS `HealthDashboardEffect.ets` 均删除
- 异常/边界：common `HealthEffect` 覆盖原三层全部 case：`ShowMessage`、`ScenarioChanged`、`ConfigSaved`

## 测试要求

| Spec ID | 自动化测试/人工验收 | 预期结果 |
|---------|---------------------|----------|
| `HLTH-MVI-001` | 新测试 `HealthStoreTest.healthActionDispatchProducesExpectedState` | dispatch Load 后 state 非 null |
| `HLTH-MVI-002` | 新测试 `HealthStoreTest.healthStateReflectsScenarioSelection` | dispatch ScenarioSelected 后 state 同步更新 |
| `HLTH-MVI-003` | 新测试 `HealthStoreTest.healthEffectIsProducedAndConsumed` | load 后 effect 产生，consumeEffect 后清零 |
| `HLTH-MVI-004` | 新测试 `HealthStoreTest.healthStoreRejectsUnauthenticatedAccess` | 未登录时 state.error 为 AuthRequired |
| `HLTH-MVI-005` | 代码评审 `LoginFacade` 不再包含 health 方法 | 编译通过 |
| `HLTH-MVI-006` | 已有 `HealthDashboardUseCaseTest.cardsUseStablePriorityOrder` 保持通过 | priority 排序与重构前一致 |
| `HLTH-MVI-007` | 代码评审 `AuthMessageKeys` 无 `health_` 键 | 编译通过 |
| `HLTH-MVI-008` | `./gradlew :common:check` 全部通过 | 39 条既有测试 + 新增测试均绿灯 |
| `HLTH-MVI-009` | 代码评审 visual 构建器在 `HealthDashboardVisuals.kt` 中 | 编译通过 |
| `HLTH-MVI-010` | `./gradlew :androidApp:assembleDebug` 通过 | 编译通过 |
| `HLTH-MVI-011` | `xcodebuild` 通过（若环境可用）；否则人工代码审查 iOS 侧 | iOS 编译通过 |
| `HLTH-MVI-012` | `hvigorw assembleApp --no-daemon` 通过（若环境可用）；否则人工代码审查 | HarmonyOS 编译通过 |
| `HLTH-MVI-013` | 代码评审 + `./gradlew :common:check` | `LoginStore` 无 `healthDashboardStore` 字段 |
| `HLTH-MVI-014` | 文件系统确认三端 `HealthDashboardEffect` 文件已删除 | 三个文件均不存在 |

## 验收标准

- [x] `HealthAction` / `HealthState` / `HealthEffect` 在 common 定义完毕
- [x] `HealthStore` 实现 MVI dispatch/consumeEffect 闭环
- [x] `HealthFacade` 独立并覆盖所有 health 操作
- [x] `HealthDashboardUseCase.kt` 拆分为 4 个文件（DataSource 接口、Local 实现、UseCase、Visuals）
- [x] `HealthRules` 纯函数提取
- [x] `HealthMessageKeys` 从认证层拆分
- [x] `LoginStore` / `LoginFacade` 不再持有或代理 health 逻辑
- [x] Android ViewModel 改为薄包装，删除平台 `HealthDashboardEffect.kt`
- [x] iOS ViewModel 改为调用 `HealthFacade`，删除平台 `HealthDashboardEffect.swift`
- [x] HarmonyOS 桥接 + ViewModel 更新，删除平台 `HealthDashboardEffect.ets`
- [x] 所有既有 39 条 `HealthDashboardUseCaseTest` 保持通过
- [x] TRACE.md 映射完整

## 待人工确认

- iOS `xcodebuild` 和 HarmonyOS `hvigorw assembleApp` 需要对应 IDE/工具链环境，非当前会话可用时以代码审查替代编译验证
