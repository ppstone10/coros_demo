# 健康首页可视化数据卡片 Spec

## 元数据

- Spec ID 前缀：`HLTH-VIS`
- 状态：实施中（2031 视觉精修）
- 设计来源：Figma「首页 PROGRESS Copy」节点 `16:8096`（2031）
- 最后更新：2026-07-22

## 目标

- 将健康首页从统一“图标 + 标题 + 摘要”列表扩充为与 Figma 2031 信息架构一致的类型化数据卡片。
- 在 common 层提供三端一致的可视化数据契约，原生 UI 仅负责布局、绘制和交互。
- 为周计划、训练负荷、能力仪表、趋势、区间、睡眠、健康快测和体型管理提供足够的本地 mock 数据。
- 保留既有风险优先、空态、卡片编辑、场景切换和本地持久化行为。

## 非目标

- 不接入真实健康服务、真实设备数据、真实地图或用户数据。
- 不复制 Figma 生成的 React/Tailwind 代码，不引入跨平台共享 UI 框架。
- 不把图表烘焙为整卡截图、GIF 或视频；标题图标继续复用项目已有原始资源。
- 不声称复原 Figma 动效时间线；节点 `16:8096` 的 motion inventory 为空，本轮只定义原生数据驱动的静态终态和轻量过渡。
- 不改变现有风险判定阈值和优先级业务规则。

## 边界与约束

- `common/src/commonMain` 只包含平台无关数据、规则和 UI 契约，不引入 Compose、SwiftUI、ArkUI 类型。
- 新增 mock 字段必须先出现在 `health_dashboard_mock.proto`，Kotlin 手工镜像与 protobuf 字段保持一一对应。
- 所有文案继续使用 `LocalizedTextSpec`；可视化数据只承载数值、枚举、标签 key 和脱敏 mock 序列。
- 图表颜色、字体、间距和绘制 API 属于原生 UI；三端语义一致，允许因平台字体渲染产生微小差异。
- 旧持久化快照只保存场景和卡片顺序，不保存可视化序列，因此新增字段不得破坏旧快照恢复。

## 数据与状态

| 类型 | 字段 | 用途 |
|------|------|------|
| `HealthChartPoint` | `labelKey/value/level` | 七日负荷、心率、压力等趋势点 |
| `HealthRange` | `minimum/maximum/current/normalMin/normalMax/average` | 静息心率与 HRV 区间尺 |
| `HealthMetric` | `labelKey/value/unitKey` | 训练评估三列、健康快测五项 |
| `SleepStageSegment` | `stage/startMinute/durationMinutes` | 睡眠阶段时序图 |
| `HealthCardVisualData` | `kind/primary/secondary/chart/range/metrics/...` | 三端稳定的卡片可视化 UI 契约 |

### Figma 卡片映射

| 卡片 | 必须展示的数据 |
|------|----------------|
| 今日运动 | 地图缩略图占位、距离、单位、配速、运动类型 |
| 本周计划 | 七日标签、当前日、计划名称、时长、负荷、迷你负荷柱图 |
| 本周负荷 | 当前负荷、推荐范围、七日负荷柱图 |
| 训练量评估 | 评估等级、解释、短期负荷、长期负荷、比值 |
| 体力恢复 | 恢复百分比、预计恢复时间、半圆仪表 |
| 跑步/骑行能力 | 能力分数、能力标签或预测成绩、0-100 仪表 |
| 心率/压力 | 主值、单位/说明、彩色趋势柱图 |
| 静息心率 | 当前值、测量时间、近 30 天平均、范围尺 |
| 睡眠 | 小时/分钟、起止时间、睡眠阶段序列 |
| HRV 评估 | 等级、平均值、正常范围和当前位置 |
| 健康快测 | 测量时间、心率、HRV、压力、呼吸频次、血氧 |
| 体型管理 | 体重、日期、主要训练部位、正反人体示意资产 |

## 行为规范

### `HLTH-VIS-001`：protobuf 与 domain 提供完整可视化字段契约

- Given：加载任一非空健康 mock 场景
- When：数据源构造 `HealthDashboardData`
- Then：对应卡片获得绘制 Figma 信息所需的趋势、范围、分项或阶段数据
- 异常/边界：部分缺失场景允许列表为空或字段为 null；不得用 UI 层随机数补图

### `HLTH-VIS-002`：common 输出类型化可视化 UI 数据

- Given：`HealthDashboardUseCase.toUiState` 聚合领域数据
- When：生成每张 `HealthCardUiModel`
- Then：`visual.kind` 与卡片类型稳定对应，且正常场景的必填值和列表完整
- 异常/边界：空卡仍返回对应 `kind`，但数值可为空，以便三端保持同一种布局并显示空态

### `HLTH-VIS-003`：默认首页包含 Figma 的今日运动卡

- Given：新用户没有保存过卡片配置
- When：加载默认健康首页
- Then：默认顺序包含 `TodayActivity`，并位于 `WeeklyPlan` 之前
- 异常/边界：已有用户保存的合法卡片顺序继续按快照恢复

### `HLTH-VIS-004`：三端按 visual kind 渲染专用数据卡

- Given：卡片具有 `HealthCardVisualData`
- When：Android、iOS 或 HarmonyOS 渲染首页
- Then：不再把所有卡片压缩为 76dp 摘要行；按类型展示 114/122/178/180/188/206 级别的内容密度、主数值和图表
- 异常/边界：图表没有点时显示摘要空态，不崩溃、不绘制伪造数据

### `HLTH-VIS-005`：HarmonyOS 桥接完整传递可视化数据

- Given：KMP 生成 `PersistedDashboard`
- When：`HarmonyLoginService.healthSnapshotJson` 序列化卡片
- Then：ArkTS 可读取 visual kind、主值、图表点、范围、分项、睡眠阶段及辅助字段
- 异常/边界：未知 kind 回退为摘要卡；JSON 字符串字段必须正确转义

### `HLTH-VIS-006`：人体示意图使用 Figma 原始导出资产

- Given：渲染体型管理卡
- When：展示正面和背面人体训练部位
- Then：三端使用从 Figma 节点 `16:8245`、`16:8294` 导出的原始资产，不手绘替代图
- 异常/边界：资产加载失败时仍显示体重与日期，布局不崩溃

### `HLTH-VIS-007`：无 Figma 动效稿时保持静态终态

- Given：Figma 节点 `16:8096` 的 motion inventory 为空
- When：页面首次加载、滚动复用或 mock 场景刷新
- Then：卡片图表直接绘制数据终态，不臆造循环、逐帧或入场动画；保留页面既有下拉刷新反馈
- 异常/边界：未来若补充产品动效稿，须另立 Spec 定义时间线、缓动和 Reduce Motion 降级

### `HLTH-VIS-008`：Android 无参数文案不得进入格式化路径

- Given：视觉单位或标签是不带参数的本地化资源，例如单独的 `%`
- When：Compose 卡片解析 `LocalizedTextSpec.arguments` 为空的文案
- Then：使用 `Resources.getString(id)` 非格式化重载，原样返回资源内容，不触发 `Formatter`
- 异常/边界：只有参数非空时才调用格式化重载；有参数文案继续按 Android 占位符规则解析

### `HLTH-VIS-009`：卡片采用 Figma 2031 分状态几何与安全区

- Given：页面按 375pt 设计宽度或任意等比手机宽度渲染
- When：三端展示 14 类健康卡片
- Then：卡片左右页边距为 16、圆角为 8；有数据卡按类型以 114/122/178/180/188/206 为最小视觉高度；标题基线、主值区与右侧概览区映射 Figma 节点 `16:8097`、`16:8866`、`16:8837`、`16:8810`、`16:8771`、`16:8742`、`16:8712`、`16:8651`、`16:8627`、`16:8482`、`16:8408`、`16:8389`、`16:8354`、`16:8192`
- And：周计划七个日期标签通过共享键渲染为一至日（英文为 M/T/W/T/F/S/S），不得显示资源键或通用回退文案
- 异常/边界：窄屏可压缩左右分栏之间空白，但不得改变卡片外边距或让内容越过圆角边界

### `HLTH-VIS-010`：右侧概览图使用受约束分栏并裁剪

- Given：卡片包含仪表盘、趋势柱图、范围尺、睡眠阶段或人体概览
- When：Android Compose、iOS SwiftUI、HarmonyOS ArkUI 计算布局
- Then：主信息固定在左侧，概览图固定在右侧 130/166pt 安全区；父卡片启用裁剪，图形叶节点显式限制宽高
- 异常/边界：HarmonyOS 不得把 `layoutWeight` 与 `width('100%')` 叠加在右侧概览组件上；文字变长时先截断/换行，不推动图表越界

### `HLTH-VIS-011`：三端使用同源 COROS 数值字体

- Given：桌面 `app_out` 与 `ipa_extract` 中存在应用随包字体
- When：展示卡片主值、单位与指标值
- Then：三端打包同源 `COROS-APP-Bold.ttf` / `COROS-APP-Regular.ttf`，主数值使用 Bold，普通拉丁数字可使用 Regular；中文标题继续使用平台中文系统字体以保证缺字回退
- 异常/边界：字体加载失败时回退系统字体，不阻止页面启动；字体只从用户提供的本地应用资源提取目录复制，不从未知第三方下载

### `HLTH-VIS-012`：卡片图标与缩略图使用可追溯原始资源

- Given：Figma 或用户提供的 `app_out` / `ipa_extract` 有语义匹配的原始图标与缩略图
- When：实现标题图标、今日运动地图及人体概览
- Then：优先复用已进入三端资源清单的原始 COROS 资产；新增资源记录来源并在三端保持同名、同内容，不手绘近似图标
- 异常/边界：不能确认语义的资源不得仅凭文件名接入；图表仍由数据原生绘制，不以整卡截图替代

### `HLTH-VIS-013`：HarmonyOS 编辑器恢复默认只重置编辑草稿

- Given：用户在 HarmonyOS 卡片编辑页删除或调整了卡片，但尚未点击保存
- When：点击“恢复默认数据”
- Then：编辑器内 `editingHealthCards` 立即恢复为完整默认卡片目录和默认顺序；只有随后点击“保存”才写入 KMP 持久化状态
- 异常/边界：恢复操作不得重新读取当前已持久化的删减顺序，也不得自动退出编辑页

### `HLTH-VIS-014`：iOS 编辑器重建卡片时保留本地化标题

- Given：iOS 编辑器把卡片从启用区移入“更多每日数据”，或执行恢复默认
- When：编辑器依据卡片类型重建 `HealthCard`
- Then：每张卡片同时获得稳定图标和本地化标题，图标后的文字不得为空
- 异常/边界：标题由类型到本地化键的稳定映射产生，不复用空字符串占位；保存仍只提交卡片类型 ID

### `HLTH-VIS-015`：三端健康图像通过完整的语义资源目录访问

- Given：安卓端 `AppImages.Health` 已定义健康页顶部指标、14 类卡片图标、编辑动作和 Figma 概览图
- When：iOS 与 HarmonyOS 渲染健康首页、编辑页或详情页
- Then：两端资源目录提供对应语义项，UI 不再直接散落引用 `health_activity_map` / `health_today_*` / `health_body_*` 字面名
- 异常/边界：平台资源格式可不同，但语义名、像素尺寸与可见内容必须与安卓基线一致

### `HLTH-VIS-016`：今日运动在列表、编辑与详情场景保持图标身份稳定

- Given：今日运动在安卓通用卡片目录中使用 `icon_small_training_effect`，主页标题单独使用 Figma `health_today_header`
- When：iOS 或 HarmonyOS 初始加载、删除后添加、恢复默认或打开详情
- Then：今日运动的通用图标始终映射到 `icon_small_training_effect`，不回退为心率图标；仅首页标题使用专用头图
- 异常/边界：未知卡片类型仍可使用安全回退，但 `TodayActivity` 不得进入未知分支

### `HLTH-VIS-017`：空态卡片按显式状态和说明内容自适应高度

- Given：卡片状态为 `Empty`，对应 Figma「首页_空状态」节点 `16:2313`
- When：三端在任意受支持语言、手机宽度或系统字体缩放下渲染标题和空态说明
- Then：平台必须以显式 `HealthCardStatus.Empty` 选择空态布局，不得通过主值或图表是否为空猜测；卡片以 82pt/dp/vp 为单行设计最小高度，说明换为两行时自然增长至约 102，更多换行继续撑高且不裁剪
- And：有数据或风险卡继续使用 `visual.kind` 对应的最小视觉高度；三端列表允许相邻卡片具有不同实际高度，并保持 12 的垂直间距
- 异常/边界：iOS 与 HarmonyOS 平台适配模型必须完整保留 common 的状态；空态说明不得使用固定最大高度或省略号截断，父卡片仍保留圆角裁剪

### `HLTH-VIS-018`：HarmonyOS 有数据卡不得撑开列表视口

- Given：HarmonyOS 在任意有数据场景渲染负荷、评估、恢复、能力、趋势、范围、睡眠、健康检查或体型管理卡
- When：卡片内部包含固定宽度图表、仪表或人体图
- Then：全宽外层先扣除左右各 16vp 页面边距，卡片本体仅占剩余可用宽度；内部视觉只能使用内容固有高度和卡片最小高度测量，不得以 `height('100%')` 取得 Scroll/Refresh 视口高度
- And：普通有数据卡保持约 122vp 的设计高度，训练评估等复杂类型使用其类型最小高度；不得出现单张卡占满整屏的空白区域，也不得扩大卡片或横向滚动页面
- 异常/边界：空态与有数据态使用同一外层宽度契约；320vp 等窄屏允许内部安全区压缩或裁剪，不允许突破卡片圆角边界

### `HLTH-VIS-019`：HarmonyOS 手表 Lottie 跟随同步状态播放

- Given：右上角手表 Lottie 已加载
- When：首页进入刷新状态
- Then：动画从首帧播放一次；刷新结束回到首帧静止，行为与 Android/iOS 一致
- 异常/边界：组件销毁时释放动画实例；未刷新时不得自行循环播放

### `HLTH-VIS-020`：iOS 下拉刷新必须从列表顶部开始

- Given：iOS 健康列表当前不在顶部
- When：用户向下拖动任意距离
- Then：不累计下拉位移、不显示刷新提示且不触发刷新；底层观察器必须只给现有 `UIScrollView.panGestureRecognizer` 增加 target，在手势 `.began` 时以 `contentOffset.y <= -adjustedContentInset.top + tolerance` 锁定本次手势资格，不得再叠加独立 SwiftUI `DragGesture`
- When：一次新手势开始时列表位于顶部并向下拖动超过阈值
- Then：才触发一次自定义刷新；同一手势开始后不得因滚动位置变化临时取得刷新资格，阈值应比系统 `refreshable` 更容易稳定触发

### `HLTH-VIS-021`：iOS 自定义刷新与手表 Lottie 命令式同步

- Given：iOS 自定义顶部下拉确认触发，右上角手表 Lottie 当前静止在首帧
- When：ViewModel 递增 `syncCycle` 并进入 `isLoading`
- Then：UIKit `LottieAnimationView` 包装器必须归零后直接调用 `play()`，不得依赖 SwiftUI `LottieView.playbackMode` 或视图 ID 重建推断播放
- When：数据刷新成功或失败并结束等待
- Then：`isLoading` 退出后包装器直接调用 `stop()` 并把 `currentProgress` 设为 0；下一次刷新使用新的周期，不能因 SwiftUI 复用旧实例而漏播
- 异常/边界：中段起手不进入 `refresh()`，因此不递增周期、不播放 Lottie；下拉位移、同步文案和手表动画共享同一个刷新生命周期

### `HLTH-VIS-022`：iOS 手表 Lottie 必须受 30pt 容器约束

- Given：iOS 使用 UIKit `LottieAnimationView` 命令式播放手表动画
- When：SwiftUI 顶部栏以 30×30pt 渲染手表
- Then：`UIViewRepresentable` 必须返回裁剪的容器 UIView，内部动画关闭 autoresizing mask 并以四边 Auto Layout 约束填满容器；动画不得按 composition 固有尺寸溢出顶部栏
- 异常/边界：长按手势继续绑定外部 30×30pt 区域；日历保持 23×23pt，手表与 Android/HarmonyOS 均保持 30×30 的同一语义尺寸

## 新增资源来源与一致性

| 资源 | 来源 | 三端 SHA-256 |
|------|------|--------------|
| `COROS-APP-Bold.ttf` | 用户提供的桌面 `app_out/assets/fonts/COROS-APP-Bold.ttf` | `b21993c61fddba1d5237fb60b012285344ebf7ba62f98e7fee3cc57c2e6fc633` |
| `COROS-APP-Regular.ttf` | 用户提供的桌面 `app_out/assets/fonts/COROS-APP-Regular.ttf` | `ea7b9703b7bc4f29093236021e6fbe4dcaa796b6485b2f57a42c6d7f697765d5` |
| `health_activity_map.png` | Figma 节点 `16:8097` 中活动地图原始图片资产 | `87b98b5d4ac3b1c098b24102ec61a8d87e051cd25d49019a5d68e5f41c8123f9` |
| `health_today_header.png` | Figma 节点 `16:8100` 标题日历完成图标导出 | `0c03fe8e8637454a417de0d3608277bea4a3e5efdf55e8ec4b5eacb712bba476` |
| `health_today_runner.png` | Figma 节点 `16:8120` 右侧跑步图标导出 | `27c9f18ad60239a63ac6f5b033080564c557554ad44a13813f3a29c8fe4a69d3` |

## 测试要求

| Spec ID | 自动化测试/人工验收 | 预期结果 |
|---------|---------------------|----------|
| `HLTH-VIS-001` | `normalScenarioProvidesFigmaVisualData` | 正常场景各类可视化数据非空且数值合法 |
| `HLTH-VIS-002` | `cardsExposeStableVisualKinds` | 14 类卡片 visual kind 与类型稳定对应 |
| `HLTH-VIS-003` | `defaultOrderIncludesTodayActivityBeforeWeeklyPlan` | 默认顺序包含今日运动且排在周计划前 |
| `HLTH-VIS-004` | Android 构建 + 三端人工截图核对 | 专用卡片显示主值和图表，不再是统一摘要行 |
| `HLTH-VIS-005` | HarmonyOS bridge 编译与应用构建 | ArkTS 能解析并渲染完整 visual 数据 |
| `HLTH-VIS-006` | 三端资源门禁与截图核对 | 正反人体资产存在并用于体型管理卡 |
| `HLTH-VIS-007` | 三端代码审查与构建 | 图表无自启动/循环动效，滚动复用直接显示终态 |
| `HLTH-VIS-008` | `HealthLocalizationTest.percentUnitWithoutArgumentsDoesNotEnterFormatter` | 裸百分号解析为 `%` 且应用启动不崩溃 |
| `HLTH-VIS-009` | `tools/check-health-card-fidelity.sh` + 三端截图 | 卡片高度、边距、圆角与内部基线匹配 2031 |
| `HLTH-VIS-010` | HarmonyOS 构建 + 真机/预览截图 | 右侧概览图全部位于卡片圆角边界内 |
| `HLTH-VIS-011` | 资源门禁 + 三端构建 | COROS 两种字体随三端产物打包并用于数值 |
| `HLTH-VIS-012` | 资源哈希与截图核对 | 标题图标、地图缩略图、人体图来源可追溯且三端一致 |
| `HLTH-VIS-013` | `tools/check-health-card-editor-regressions.sh` + HarmonyOS 构建 | 恢复默认直接重置编辑草稿，不重读已保存删减顺序 |
| `HLTH-VIS-014` | `tools/check-health-card-editor-regressions.sh` + iOS 构建 | 删除/恢复生成的卡片标题均来自本地化键且非空 |
| `HLTH-VIS-015` | `tools/check-health-card-fidelity.sh` + 三端构建 | 资源目录覆盖全部健康图像，UI 通过语义入口访问 |
| `HLTH-VIS-016` | `tools/check-health-card-fidelity.sh` + 编辑/详情人工验收 | 今日运动的通用图标三端一致，首页专用头图不受影响 |
| `HLTH-VIS-017` | `tools/check-health-card-adaptive-layout.sh` + 三端构建 | 空态按显式状态使用 82 最小高度并允许内容继续撑高；有数据卡保留类型最小高度 |
| `HLTH-VIS-018` | `tools/check-health-dashboard-runtime-states.sh` + HarmonyOS 构建 | 有数据与空态使用同一受限外壳，数据子视图不含视口级 `height('100%')` |
| `HLTH-VIS-019` | `tools/check-health-dashboard-runtime-states.sh` + HarmonyOS 构建 | Lottie 仅在刷新时播放一次并复位 |
| `HLTH-VIS-020` | `tools/check-health-dashboard-runtime-states.sh` + iOS 构建 | UIScrollView 在 pan began 锁定顶部资格，中段起手永不刷新 |
| `HLTH-VIS-021` | `tools/check-health-dashboard-runtime-states.sh` + iOS 构建 | 每次自定义刷新直接 play，结束直接 stop 并归零 |
| `HLTH-VIS-022` | `tools/check-health-dashboard-runtime-states.sh` + iOS 构建 | Lottie 四边约束在裁剪的 30pt 容器内，不按固有尺寸溢出 |

## 验收标准

- [x] 正常场景 14 类卡片均有稳定 visual kind 和绘制数据。
- [x] 默认卡片目录包含今日运动。
- [x] Android、iOS、HarmonyOS 使用类型化专用卡片组件。
- [x] Figma 人体正反面原始资产进入三端资源目录。
- [x] common 测试、Android 构建、iOS 构建、HarmonyOS 构建通过。
- [x] 专项资源一致性、资源维护性、SDD、文档门禁通过，TRACE 与 Worklog 记录真实结果。
- [x] 空态卡片以显式状态选择自适应布局，单行/多行说明不再继承有数据卡固定高度。
- [x] HarmonyOS 有数据卡使用受限全宽外壳，手表 Lottie 跟随刷新状态播放；iOS 仅允许从顶部开始的手势刷新。
- [ ] 全量 `check-resources.sh` 通过；当前仅剩本轮外既存 HarmonyOS “我”页语言选择入口缺失。

## 待人工确认

- 本轮按用户明确授权，从其本地 `app_out` / `ipa_extract` 提取同源 COROS 字体并打包三端；字体的最终发布许可仍应由产品/法务确认。
- Figma 节点没有 motion 时间线；当前保持静态终态，后续若提供真实产品动效稿应另立规范校准。
- HarmonyOS 当前没有可连接 HDC 设备；已完成 ArkTS 构建和结构门禁，仍建议在目标鸿蒙设备上复核不同系统字号下的右侧安全区。
- 本轮没有可连接的 Android/HarmonyOS 设备；建议在 320/375/430 宽度、中文/英文及放大字体下分别截图 AllEmpty/PartialMissing，确认空态说明完整且单行/多行卡片高度自然分化。
