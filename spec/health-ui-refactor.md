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

### `HLTH-UI-ARCH-011`：Android 健康首页分层下拉刷新

- Given：Android 健康首页由固定的 `HeroTopRow` 与可滚动健康数据主体组成
- When：用户从列表顶部开始下拉
- Then：页面根节点使用覆盖全页的 `Box`；`HeroTopRow` 保持固定，只有包含 `ArcAndMetricsSection`、全部 `DashboardCard`、编辑入口和空/异常态的 `LazyColumn` 按 `pullOffset` 下移
- And：刷新提示是根 `Box` 的独立覆盖层，不进入 `LazyColumn`、不占普通布局空间；`Dragging`、`Armed`、`Refreshing`、`Resetting` 时提示底部和移动主体顶部始终保持固定 `indicatorBodyGap`，因此主体每移动 1px，提示也同步移动 1px
- And：提示从 Hero 覆盖区域内随主体下滑出现，并按下拉进度改变透明度和轻微缩放；提示最迟在刷新阈值约 40% 的拉动距离达到完整不透明，避免小幅下拉时肉眼不可见
- And：提示的 `Row` 和文字始终保持水平，不得对整行应用 `rotationZ`；若保留拖动旋转反馈，只允许刷新图标自身轻微旋转
- And：未达到阈值显示“下拉刷新”，达到阈值显示“释放刷新”；松手未达阈值时进入复位并在约 300ms 内让主体归零、提示隐藏，不调用刷新
- And：`Dragging`、`Armed`、`Refreshing` 三个可见阶段的提示层级必须始终高于 `HeroTopRow` 的不透明背景；不得只在刷新后提高 `zIndex`，导致松手前的“下拉刷新/释放刷新”被遮挡
- 异常/边界：手势仅在列表已无法继续向下消费且刷新状态空闲时累计；刷新或复位期间忽略新的下拉累计

### `HLTH-UI-ARCH-012`：Android 刷新吸附、Lottie 同步与连续复位

- Given：下拉距离已经达到刷新阈值
- When：用户松手
- Then：状态依次表达 `Idle`、`Dragging`、`Armed`、`Refreshing`、`Resetting`；主体先动画吸附到统一的 `refreshHoldOffset`，不得停在松手时的随机位置
- And：主体吸附过程中提示继续保持固定间距并同步移动；进入 `Refreshing` 后不得再停靠到独立 Hero 坐标，提示在固定间距位置显示“数据同步中”
- And：刷新提示继续使用现有 16dp、2dp 描边的 `CircularProgressIndicator`、8dp 图文间距、`health_data_syncing` 文案及现有颜色字号；右上角 `watch_status` Lottie 与 `Refreshing` 同步播放固定 4460ms，期间进度图标持续旋转，动画结束后调用 `healthViewModel.refresh()`
- When：刷新调用完成
- Then：进入 `Resetting`，提示只按复位进度淡出并与主体等距上移，不得叠加独立向上退出位移；主体以约 300ms 连续动画回到原位，最后回到 `Idle`
- 异常/边界：若“数据同步中”在当前吸附高度内空间不足，只增大统一 `indicatorBodyGap`，不得为刷新态建立另一套位置；Android 本轮先行，iOS/HarmonyOS 等价自定义分层与五态动画记为跨端债务，不宣称三端同步完成

### `HLTH-UI-ARCH-013`：iOS/HarmonyOS 对齐 Android 分层下拉刷新

- Given：Android 已由用户验收当前刷新参数和视觉效果，最终视觉基准为刷新阈值 `80`、主体刷新停留高度 `34`、提示与主体固定间距 `80`、阻尼系数 `0.4`、吸附/复位时长约 `300ms`
- When：iOS 与 HarmonyOS 健康首页同步实现
- Then：三端都使用覆盖整个健康页面的根层，固定 `HeroTopRow`，只有包含顶部圆弧指标、全部健康卡片和编辑入口的滚动主体随下拉偏移移动
- And：三端状态语义一致为 `Idle/Dragging/Armed/Refreshing/Resetting`；未达 `80` 显示“下拉刷新”，达到阈值未松手显示“释放刷新”，触发后显示“数据同步中”
- And：提示为滚动主体之外的独立水平覆盖层；所有非空闲阶段的位置都由 `bodyTop - indicatorHeight - 80` 计算，吸附到 `34` 和复位到 `0` 时仍与主体同步移动，不得建立刷新态独立停靠坐标
- And：提示使用平台原生圆形进度图标、现有健康页颜色与 Supporting 字号、16 尺寸和 8 图文间距；拖动阶段可以只旋转图标，不得旋转整行文字；透明度在阈值 40% 前完成淡入
- And：达到阈值松手后，主体约 `300ms` 吸附到 `34`；刷新状态持续 `4460ms` 并同步播放右上角手表 Lottie，随后调用平台现有 `refresh`，再进入约 `300ms` 的等距复位
- And：未达到阈值松手不刷新，主体和提示连续复位；刷新/复位期间忽略新的下拉手势
- 异常/边界：iOS 继续观察原生 `UIScrollView.panGestureRecognizer`，不得叠加冲突手势；HarmonyOS 使用原生 `Refresh` 的状态、偏移回调和自定义覆盖提示，不恢复默认刷新提示。项目兼容 API 12，不能调用 API 20 才提供的 `maxPullDownDistance`；HarmonyOS 极限拉距沿用原生安全边界，但阈值、阻尼、停留位置和提示等距规则必须与 Android 一致

### `HLTH-UI-ARCH-014`：HarmonyOS 刷新阈值与停留高度独立可调

- Given：HarmonyOS API 12 的废弃 `RefreshOptions.offset` 不再控制实际刷新停留位置，而 `.refreshOffset` 同时参与原生触发和停留
- When：产品修改 `PULL_REFRESH_HOLD_OFFSET`
- Then：HarmonyOS 必须把有效 `.refreshOffset` 绑定到 `PULL_REFRESH_HOLD_OFFSET`，修改 `34 → 4` 时刷新主体停留高度应同步改变
- And：`PULL_REFRESH_THRESHOLD = 80` 继续独立决定是否刷新；原生自动触发关闭，由 `onOffsetChange` 记录当前释放资格，并在本次下拉结束时决定触发刷新或复位
- And：未达到阈值不得刷新；达到阈值后再回推到阈值以下并松手也不得刷新；刷新与复位期间提示继续使用真实主体偏移保持固定间距
- 异常/边界：程序化进入 `refreshing` 后只启动一次 4460ms 定时刷新，不得与 `onRefreshing` 重复调度

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
| `HLTH-UI-ARCH-011` | `PullToRefreshStateTest`；Android 构建；人工拖动验收 | 阈值前显示“下拉刷新”、阈值后未松手显示“释放刷新”，三阶段提示均位于 Hero 之上 |
| `HLTH-UI-ARCH-012` | `PullToRefreshStateTest`；Android 构建；人工观察 4460ms Lottie/提示随主体吸附/复位 | 达阈值后主体固定吸附，提示全程保持统一间距，同步刷新并约 300ms 连续复位 |
| `HLTH-UI-ARCH-013` | iOS/HarmonyOS 构建；跨端刷新状态与参数静态门禁；人工拖动验收 | 两端与 Android 使用 `80/34/80/0.4/300/4460` 视觉基准，Hero 固定、主体独立移动、三态提示全程等距 |
| `HLTH-UI-ARCH-014` | HarmonyOS 静态门禁；`hvigorw assembleApp`；人工修改 `PULL_REFRESH_HOLD_OFFSET` 对比 | `.refreshOffset` 使用停留高度，阈值由页面独立判断，修改停留参数能直接改变刷新主体位置 |

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
