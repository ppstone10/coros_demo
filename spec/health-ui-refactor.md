# 健康仪表盘 UI 架构重构 Spec

## 元数据

- Spec ID 前缀：`HLTH-UI-ARCH`
- 状态：草案
- 负责人：待定
- 关联需求：解决健康首页模块 UI 层单文件膨胀、导航模式不一致、无独立 ViewModel、状态管理松散、三端架构不一致问题
- 最后更新：2026-07-24

## 目标

- 解决各端 DashboardCard 单文件膨胀问题（Android 798 行、iOS 827 行、HarmonyOS 600+429 行），按视觉种类拆分为独立文件
- 消除各端健康 Screen 中用 `if {} return` 或 `if/else` 条件渲染模拟页面跳转的脆弱模式，改为密封类/枚举状态驱动
- 将内嵌的下拉刷新手势逻辑抽取为可复用组件
- 创建独立 `HealthDashboardViewModel`，从 `LoginViewModel` 中拆分健康模块职责
- 引入 `HealthDashboardEffect` 密封类，统一管理副作用（提示、刷新完成、配置保存）
- 将 Screen 的松散状态归约为单一状态对象
- 将 `selectedWeeklyDay` 状态下放到 `WeeklyVisual` 内部
- 三端逐步对齐，最终使健康模块架构模式与登录模块一致（MVI 风格）

## 非目标

- 不改变 KMP 共享层（`common/.../health/`）的任何代码或数据契约
- 不改变平台导航框架（Android NavHost、iOS NavigationStack、HarmonyOS router）
- 不改变卡片视觉渲染结果（拆分后视觉内容不变）
- 不引入第三方依赖或 DI 框架
- 不改变认证模块的 `LoginEffect` / `LoginStore` / `AuthRepository` 现有接口
- 不改动卡片编辑器 `CardEditor` / `CardEditorComp` / `HealthCardEditor` 的内部交互逻辑
- 不处理 iOS/HarmonyOS 登录模块与健康模块的架构对齐（本 spec 只处理健康模块自身）

## 边界与约束

- 架构边界：所有改动限于各端 UI 层（`androidApp/.../health/`、`iosApp/.../Health/`、`harmonyApp/.../health/`），不波及 common 共享层
- 安全与数据边界：`HealthDashboardViewModel` 必须继续通过 `HealthDashboardStore` 的 `verifyBusinessAccess()` 鉴权门禁，不在 ViewModel 中绕过
- 兼容性边界：`LoginViewModel` 移除健康方法后，现有调用方（`MainTabsScreen` / `MainTabsView` / `SignedInPage`）必须同步更新
- 失败边界：阶段性实施时未完成项在 TRACE 标记 `⏳`，不可标记为 `✅`
- 回退策略：每个原子改动可独立回退，回退后执行 `./gradlew :androidApp:assembleDebug` 或平台对应命令确认通过

## 数据与状态

| 名称 | 类型/结构 | 来源 | 生命周期 | 约束 |
|------|-----------|------|----------|------|
| `DashboardPage`（各端自定） | 密封类/枚举：`Main`、`Detail(card)`、`Editor`、`ScenarioPicker` | 各端 UI 层 | 随 Screen 组合周期 | 不跨出 Screen 范围 |
| `DashboardScreenState`（各端自定） | data class/struct：`page`、`isRefreshing`、`pullOffset` | 各端 UI 层 | 随 Screen 组合周期 | 替代当前多个独立状态变量 |
| `HealthDashboardEffect`（各端自定） | 密封类/枚举：`ShowMessage`、`ScenarioChanged`、`ConfigSaved` | 各端 UI 层 | 一次性消费 | 与 `LoginEffect` 模式一致 |
| `HealthDashboardUiState` | `StateFlow<DashboardUiState>` | `HealthDashboardViewModel` | ViewModel 生命周期 | 替代当前 `MockResult<PersistedDashboard>` 直接持有 |

## 行为规范

### `HLTH-UI-ARCH-001`：DashboardCard 按视觉种类拆为独立文件

- Given：当前 `DashboardCard.kt` 包含 11 种视觉 + 辅助函数 + 映射 + 预览
- When：完成拆分后
- Then：`components/visuals/` 目录下每种 `HealthCardVisualKind` 一个独立文件，`DashboardCard.kt` 只保留 `CardHeader` + 分发 `when(visual.kind)` 骨架 + 共用工具（`ValueText`、`UnitText`、`MiniBars`、`OverviewRow`、`iconOf`、`resourceName`）
- 异常/边界：`OverviewRow` 被 6 种视觉复用，保留在 DashboardCard.kt 或独立 `OverviewRow.kt`；`MiniBars` 被 2 种视觉复用，独立文件；`ValueText`/`UnitText` 被所有视觉使用，留在 DashboardCard.kt 底部或独立的 `CardTypography.kt`
- 回退：恢复 `git checkout` 原 DashboardCard.kt，删 visuals/ 目录

### `HLTH-UI-ARCH-002`：页面子模式改为密封类状态驱动

- Given：当前 `HealthDashboardScreen` 用 `if (showScenarioPicker) { ...; return }` 等三个早期返回模拟子页面
- When：完成修改后
- Then：定义 `DashboardPage` 密封类，Screen 用一个 `when(page)` 表达式替代三个 `if {} return`；不再手动 `BackHandler`
- 异常/边界：`DashboardPage.Detail` 携带 `card: HealthCardUiModel`；`DashboardPage.Editor` 携带 `initial: List<HealthCardType>` 和 `onSave` 回调；各端平台使用等价构造（Android 密封类、iOS 枚举 + associated values、HarmonyOS 联合模式）
- 回退：恢复为独立 `remember` 变量 + `if {} return`

### `HLTH-UI-ARCH-003`：下拉刷新抽取为独立组件

- Given：`NestedScrollConnection` + 两个 `LaunchedEffect` 动画 + `pullOffset` 状态直接写在 `HealthDashboardScreen` 中
- When：完成修改后
- Then：Android 抽取为 `Modifier.pullToRefresh(isRefreshing, onRefresh, onOffsetChanged)` 扩展，iOS 将 `ScrollViewPanObserver` 抽取为独立 `PullToRefreshModifier.swift` 文件，HarmonyOS 保持已有原生 `Refresh` 不变
- 回退：恢复内联实现

### `HLTH-UI-ARCH-004`：创建独立 HealthDashboardViewModel

- Given：健康模块数据加载挂在 `LoginViewModel` 上（`loadHealthDashboard()`、`refreshHealthDashboard()`、`saveHealthCardConfiguration()`）
- When：完成修改后
- Then：
  - Android 创建 `HealthDashboardViewModel`，持有 `HealthDashboardStore`，暴露 `val uiState: StateFlow<DashboardUiState>`、`fun refresh()`、`fun selectScenario()`、`fun saveCardConfiguration()`、`val effect: SharedFlow<HealthDashboardEffect>`
  - `LoginViewModel` 移除 `loadHealthDashboard()`、`refreshHealthDashboard()`、`selectHealthScenario()`、`saveHealthCardConfiguration()` 四个方法
  - `MainTabsScreen` 同时持有 `LoginViewModel` 和 `HealthDashboardViewModel`
  - iOS `HealthDashboardViewModel` 已有，增加 `HealthDashboardEffect` 支持
  - HarmonyOS 创建 `HealthDashboardViewModel.ets`，使用 `@Observed` + `@ObjectLink` 模式
- 异常/边界：`HealthDashboardViewModel` 通过构造器接收 `HealthDashboardStore` 实例，该实例由 `LoginStore.create()` 中已有 `HealthDashboardStore` 传入
- 回退：在 `LoginViewModel` 恢复代理方法，删除新 ViewModel

### `HLTH-UI-ARCH-005`：引入 HealthDashboardEffect

- Given：当前健康模块无副作用管理系统，Toast、导航、刷新完成都是就地处理
- When：完成修改后
- Then：
  - 定义 `sealed interface HealthDashboardEffect`，包含 `ShowMessage(String)`、`ScenarioChanged`、`ConfigSaved`
  - ViewModel 暴露 `SharedFlow<HealthDashboardEffect>`（Android）或等效（iOS 回调闭包、HarmonyOS `consumeEffect()`）
  - Screen 在 `LaunchedEffect` 中消费 effect，执行 Toast 展示、场景刷新等副作用
- 异常/边界：effect 只暴露给 Screen 消费，不在 ViewModel 外部手动触发
- 回退：删除 effect 定义，回到就地处理

### `HLTH-UI-ARCH-006`：Screen 状态归约为单一对象

- Given：`HealthDashboardScreen` 有 6 个独立 `remember` 变量（`result`、`editing`、`detail`、`showScenarioPicker`、`isRefreshing`、`selectedScenario`）
- When：完成修改后
- Then：定义 `data class DashboardScreenState(page, isRefreshing, pullOffset)`，用一个 `var screenState by remember { mutableStateOf(DashboardScreenState()) }` 替代
- 异常/边界：`selectedScenario` 提升为 ViewModel 状态（属于业务状态而非 UI 状态）；`result` 由 ViewModel 的 `uiState: StateFlow` 替代
- 回退：恢复为独立变量

### `HLTH-UI-ARCH-007`：selectedWeeklyDay 下放到 WeeklyVisual

- Given：`selectedWeeklyDay` 定义在 `DashboardCard` 层（第 103-109 行），但只对 `WeeklyPlan` 有意义
- When：完成修改后
- Then：`selectedWeeklyDay` 移到 `WeeklyVisual` 内部管理，`DashboardCard` 不再感知星期状态；`weeklyVisualForSelectedDay` 也随之移入
- 异常/边界：`onWeeklyDaySelected` 回调由 `DashboardCard` 透传给 `HealthCardVisualContent` 再透传给 `WeeklyVisual`，不再在 Card 层存储
- 回退：恢复为 DashboardCard 层持有

### `HLTH-UI-ARCH-008`：三端同一子模式状态驱动对齐

- Given：Android、iOS、HarmonyOS 三端健康模块都在用 `if {} return` / `if {} else` 条件渲染 + 状态变量模式管理子页面
- When：完成修改后
- Then：三端都不再使用早期返回或条件截断
- 异常/边界：各端使用平台允许的构造，不要求语法完全一致，只保证语义等价
- 回退：恢复各端原有条件渲染模式

### `HLTH-UI-ARCH-009`：iOS `HealthDashboardView.swift` 按视觉种类拆分

- Given：`HealthDashboardView.swift` 当前 827 行，包含 10 个视觉分支 + 8 个私有 helper struct + `UIViewRepresentable`
- When：完成拆分后
- Then：
  - 参照 Android 端拆分模式，将每个 `HealthCardVisualKind` 对应的私有 visual struct 移到 `Health/Components/Visuals/` 目录下的独立 `.swift` 文件
  - `HealthDashboardView.swift` 只保留主 Screen 编排 + 分发 `switch(visual.kind.name)` 骨架
  - 共用工具（`OverviewRow`、`MiniBars`、`MetricValue`、`ValueText`、`UnitText`）独立为文件或保持与分发器同文件
- 异常/边界：保留原有 `ScrollViewPanObserver` 在 HealthDashboardView.swift 中（待 Phase 4 处理）
- 回退：恢复 `HealthDashboardView.swift` 原文件，删除 `Visuals/` 目录

### `HLTH-UI-ARCH-010`：HarmonyOS `DashboardCardComp.ets` + `SignedInPage.ets` 按视觉种类拆分

- Given：`DashboardCardComp.ets` 600 行 + `SignedInPage.ets` 429 行，分别包含 11 种视觉 `if/else-if` 链和页面编排
- When：完成拆分后
- Then：
  - 参照 Android 端拆分模式，将 `DashboardCardComp.ets` 的 `VisualContent()` 中每个视觉分支移到 `health/components/visuals/` 目录下的独立 `.ets` 文件
  - `DashboardCardComp.ets` 只保留 `@Component struct DashboardCardComp` 骨架 + `if/else-if` 分发
  - `SignedInPage.ets` 中的圆弧绘制逻辑保留在该文件（属于页面级编排，不属卡片视觉）
- 异常/边界：ArkUI `@Component struct` 拆分需确保 `@Prop` 和 `@State` 正确传递，不改变现有交互
- 回退：恢复原 `DashboardCardComp.ets`，删除 `visuals/` 目录下新增文件

- Given：Android、iOS、HarmonyOS 三端健康模块都在用 `if {} return` / `if {} else` 条件渲染 + 状态变量模式管理子页面
- When：完成修改后
- Then：
  - Android 用 sealed class `DashboardPage` + `when`
  - iOS 用 enum `DashboardPage` + `switch` + `@State`
  - HarmonyOS 用 union + `@State` + `if/else if`
  - 三端都不再使用早期返回或条件截断
- 异常/边界：各端使用平台允许的构造，不要求语法完全一致，只保证语义等价
- 回退：恢复各端原有条件渲染模式

## 实施阶段

本 spec 按依赖关系分为 4 个阶段，每个阶段可独立验证和交付：

| 阶段 | 包含 Spec | 依赖 | 验证方式 |
|------|----------|------|---------|
| **Phase 1**：文件拆分 + 状态下放 | `HLTH-UI-ARCH-001`、`HLTH-UI-ARCH-007` | 无 | 各端构建通过，视觉渲染截面对比无差异 |
| **Phase 1a**：iOS 端文件拆分 + 状态下放 | `HLTH-UI-ARCH-009` | `HLTH-UI-ARCH-001` Android 端完成可参考 | `xcodebuild` 构建通过，`HealthDashboardView.swift` 按视觉种类拆分 |
| **Phase 1b**：HarmonyOS 端文件拆分 + 状态下放 | `HLTH-UI-ARCH-010` | `HLTH-UI-ARCH-001` Android 端完成可参考 | `hvigorw assembleApp` 构建通过，`DashboardCardComp.ets` + `SignedInPage.ets` 按视觉种类拆分 |
| **Phase 2**：ViewModel + Effect | `HLTH-UI-ARCH-004`、`HLTH-UI-ARCH-005` | Phase 1 | `./gradlew :androidApp:assembleDebug`、`xcodebuild`、`hvigorw assembleApp` 通过；运行时健康数据加载和刷新与修改前一致 |
| **Phase 3**：页面模式 + 状态归约 | `HLTH-UI-ARCH-002`、`HLTH-UI-ARCH-006`、`HLTH-UI-ARCH-008` | Phase 2 | 三个子页面（编辑、详情、场景选择）行为与修改前一致，系统返回键正常 |
| **Phase 4**：下拉刷新抽取 | `HLTH-UI-ARCH-003` | Phase 3 | 下拉刷新手势行为与修改前一致 |

## 测试要求

| Spec ID | 自动化测试/人工验收 | 预期结果 |
|---------|---------------------|----------|
| `HLTH-UI-ARCH-001` | `:androidApp:assembleDebug`；`xcodebuild`；`hvigorw assembleApp` | 构建通过 |
| `HLTH-UI-ARCH-001` | 人工验收：三端 14 张卡片渲染与截图中拆分前一致 | 每张卡片的标题、图标、视觉内容、布局位置与拆分前相同 |
| `HLTH-UI-ARCH-002` | 人工验收：点击卡片进入详情、长按手表弹出场景选择、点击编辑按钮进入编辑器 | 三个子页面正确显示，系统返回键正确退出子页面回到主列表 |
| `HLTH-UI-ARCH-003` | 人工验收：下拉手势触发刷新、刷新中显示 loading、刷新完成回到初始状态 | 下拉刷新行为与修改前完全一致 |
| `HLTH-UI-ARCH-004` | `:androidApp:assembleDebug` | Android 构建通过，无 `LoginViewModel` 残留的健康方法 |
| `HLTH-UI-ARCH-004` | `HealthDashboardViewModelTest`（新建） | `load()` 返回正确 `DashboardUiState`，`refresh()` 正确更新状态，数据变化触发 `StateFlow` 更新 |
| `HLTH-UI-ARCH-005` | 人工验收：刷新完成时无崩溃 | 刷新成功/失败后页面状态正确，无残留 loading |
| `HLTH-UI-ARCH-006` | 代码审查：`DashboardScreenState` 封装完整 | Screen 不再有超过 2 个的独立 `remember` 状态变量 |
| `HLTH-UI-ARCH-007` | 代码审查：`selectedWeeklyDay` 定义在 `WeeklyVisual`/`WeeklyVisual.kt` 内部 | `DashboardCard`/`DashboardCard.kt` 中无 `selectedWeeklyDay` 相关状态 |
| `HLTH-UI-ARCH-008` | 代码审查：三端都不再使用早期返回截断主页面渲染 | 各端主 Screen 文件顶部无 `if (condition) { subPage; return }` 模式 |
| `HLTH-UI-ARCH-009` | `xcodebuild` 构建通过；截图人工对比视觉无差异 | iOS 构建成功，卡片渲染与拆分前一致 |
| `HLTH-UI-ARCH-010` | `hvigorw assembleApp` 构建通过；截图人工对比视觉无差异 | HarmonyOS 构建成功，卡片渲染与拆分前一致 |

## 验收标准

- [ ] 所有规范 ID 已在 `spec/TRACE.md` 建立映射，状态标记符合实际进度
- [ ] Phase 1-4 按顺序完成，每个阶段验证通过后再进入下一阶段
- [ ] 修改前和修改后的三端健康首页截图对比无视觉差异
- [ ] Android `./gradlew :androidApp:assembleDebug` 通过
- [ ] iOS `xcodebuild` 通过
- [ ] HarmonyOS `hvigorw assembleApp` 通过
- [ ] `LoginViewModel` 不再包含健康模块方法
- [ ] `HealthDashboardViewModel` 承担所有健康数据加载职责
- [ ] 三端子页面管理方式一致（密封类/枚举 + `when`/`switch` 模式）
- [ ] `./tools/check-sdd.sh` 通过
- [ ] `Codex_worklog.md` 已记录本轮实施事实
- [ ] 如果本 spec 未完全实施，TRACE 中未完成项标记 `⏳`，Worklog 写明中断位置和后续入口

## 不兼容时的回退流程

1. **构建失败**：`git diff --name-only` 确认本次变更文件列表，`git checkout -- <files>` 回退具体文件，运行构建命令确认恢复
2. **运行时行为差异**：优先调整实现（如拆分后的视觉布局偏移），调整无效则回退该 spec 条目对应的变更
3. **阶段内回退**：只回退该阶段文件，不影响已完成的上一阶段
4. **跨阶段冲突**：如果 Phase 2 发现 Phase 1 拆分不合理，先修正 Phase 1 再继续

## 未完成任务交接

本 spec 如果在一轮中未能完全实施，按以下方式交接：

1. **TRACE 标记**：已完成的 spec ID 标记 `✅`，未完成的标记 `⏳`，并注明中断原因（如"Phase 3 因导航模式争议暂停"）
2. **Worklog 记录**：在 `Codex_worklog.md` 的四段记录中写明：
   - 采纳内容：已完成的 spec 条目和对应的 commit/文件
   - 人工审查点：实施过程中发现的决策点或分歧
   - 验证结果：已执行的验证命令和结果
   - 人工修正点：未完成条目的入口文件、预期实现位置、需要后续注意的问题
3. **后续入口**：下一轮从 TRACE 中第一个 `⏳` 开始，先读取本 spec 和 `LEARNINGS.md` 中提炼的决策
4. **增量验证**：每完成一个 Phase 即运行验证命令，确保已完成部分不退化

## 待人工确认

- `HealthDashboardViewModel` 在 Android 中的创建时机：在 `MainTabsScreen` 中创建还是通过 `LoginViewModel` 透传？推荐在 `MainTabsScreen` 中创建，`HealthDashboardStore` 从 `LoginViewModel` 获取
- `HealthDashboardEffect` 在各端的实现细节：iOS 是否有必要引入 Combine `PassthroughSubject` 还是沿用回调闭包
- HarmonyOS `DashboardPage` 等价实现：是否用 `@State currentPage: string` + `if/else` 即可，还是需要更复杂的路由状态管理
- iOS 下拉刷新抽取：目前使用 `UIScrollView.panGestureRecognizer` 监听，是否需要替换为 SwiftUI 原生 `.refreshable`（需 iOS 15+，可能影响兼容性）
