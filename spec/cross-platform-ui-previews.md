# 三端原生 UI Preview 规范

## 元数据

- Spec ID：`UI-PREVIEW`
- 状态：已采纳
- 适用范围：Android Compose、iOS SwiftUI、HarmonyOS ArkUI 的生产可视页面与独立复用组件

## 目标

- Android Studio、Xcode 和 DevEco Studio 能直接发现并渲染全部生产页面的 Preview。
- 健康首页、卡片、编辑器等依赖业务数据的 Preview 使用 `commonMain` 中确定性的本地 fixture，不访问真实服务、账号或持久化。
- Android 直接消费 KMP 模型；iOS 通过 Swift 展示适配器消费 Kotlin/Native 导出模型；HarmonyOS 通过 KNOI 暴露的 JSON 快照映射为 ArkTS DTO。
- Preview 与运行时共用同一展示组件，不复制一套仅用于截图的页面实现。

## 非目标

- 不把 Compose、SwiftUI、ArkUI 或平台 SDK 类型放入 `commonMain`。
- 不要求 Preview 执行相机、相册、导航、持久化、倒计时或网络副作用。
- `DebugStatePage` 是明确不发布的调试页面，不属于生产 Preview 覆盖范围。
- 叶级、无独立视觉语义的布局 helper 不要求单独 Preview，但必须被所属页面或组件 Preview 覆盖。

## 稳定规范

### UI-PREVIEW-001：共享确定性 fixture

`commonMain` 必须提供健康正常场景的确定性 Preview state。它只由共享领域模型、规则和本地 mock 组成；三端不得各自随机生成图表或另写业务推导。

### UI-PREVIEW-002：跨语言适配

- Android Preview 直接读取共享 Preview state。
- iOS Preview 把共享 `HealthState` 送入既有 Swift `HealthDashboardViewModel` 映射边界，最终只把 Swift 展示模型交给 SwiftUI。
- HarmonyOS KNOI service 必须提供共享 Preview state 的 JSON；ArkTS 继续使用运行时相同的 `HealthSnapshot`/`HealthCardModel` 映射边界。
- JSON 失败时 Preview 可以显示显式空态，但不得崩溃或写入持久化。

### UI-PREVIEW-003：页面覆盖

三端每个生产导航页面必须有工具链可发现的 Preview：Compose `@Preview`、SwiftUI `#Preview`、ArkUI `@Preview`。需要路由或 ViewModel 的页面使用无副作用回调和 Preview fixture。

### UI-PREVIEW-004：独立复用组件覆盖

认证组件、健康 Hero/指标/卡片/场景选择器、卡片编辑器、详情组件以及三端各自的独立视觉卡片族，必须能从至少一个命名 Preview 中直接查看有数据状态。表单还应覆盖预填值，弹层应覆盖展开内容。

### UI-PREVIEW-005：静态门禁

仓库提供 `tools/check-ui-previews.sh`：以显式生产 UI 清单检查三端 Preview 注解、共享 fixture、iOS 映射入口与 HarmonyOS JSON bridge。新增生产页面时必须同步更新清单或在 Spec 中说明排除原因。

### UI-PREVIEW-006：ArkUI Preview Host 边界

包含 `@Consume`、`@Link`、`@ObjectLink` 或 `@Prop` 状态入参的 ArkUI 子组件不得直接标注 `@Preview`。必须由无上述外部状态依赖的父级 `@Component` Preview Host 持有完整 `@State`/常量默认值，再在 Host 内实例化子组件。生产页面自身无外部装饰器入参时可以直接预览。

### UI-PREVIEW-007：SwiftUI View 文件覆盖

iOS 每个包含生产 `struct ...: View` 声明的 Swift 文件必须至少有一个 `#Preview`。同文件的叶级 helper 可以由一个命名 Catalog Preview 集中覆盖；健康可视化模块必须使用 common fixture 经 Swift ViewModel 映射得到的 `HealthCardVisualData`，不得在 Swift 中重新构造业务图表数据。

### UI-PREVIEW-008：ArkUI native 模块隔离

任何带 `@Preview` 的 ArkTS 文件，其静态 import 图不得到达 `@kuiklybase/knoi` 或生成的 `knoi/provider.ets`。KNOI 初始化、生成 service 获取和 native adapter 安装只允许从 `EntryAbility` 运行时组合根进入；普通页面依赖纯 ArkTS service contract/provider。登录 ViewModel 在 native factory 尚未安装时使用无副作用 Preview adapter，且不得在模块顶层立即创建 native ViewModel/service。

### UI-PREVIEW-009：Android/HarmonyOS Visual 模块覆盖

- Android 每个生产健康 Visual Kotlin 文件必须包含至少一个命名 `@Preview`，并从 common fixture 按稳定卡片 ID 获取真实 `HealthCardVisualData`。
- HarmonyOS 每个生产 `*VisualComp.ets` 必须被纯 ArkTS `VisualPreviewCatalog` 父 Host 直接实例化覆盖；由于 VisualComp 使用 `@Prop`，不得在子组件文件上直接标注 `@Preview`。
- 单个 ArkTS 文件最多声明 10 个 `@Preview`；超过时必须拆分为多个纯父 Catalog，门禁按全部 `VisualPreviewCatalog*.ets` 合并检查覆盖。
- HarmonyOS Preview 数据中的对象数组必须声明为 `HealthChartPointData[]` 等已知契约类型，不依赖 ArkTS 对对象字面量数组的隐式推断。
- Preview 宿主必须提供非空图表、区间、阶段或指标等完整合法数据，使专项 Preview 展示有数据状态而非只有空壳。

## 异常与边界

- Preview 宿主缺少 Activity、导航栈、相册、KNOI native service 或持久化上下文时，页面仍可组合/构建；交互回调退化为空操作。
- 本地化继续由三端原生资源解析；共享 fixture 只输出稳定 key/arguments。
- Preview 数据不得包含真实 token、服务地址、账号或用户数据。

## 测试与验收

- 先运行 `./tools/check-ui-previews.sh` 并确认能捕获现有缺失覆盖。
- `./gradlew :common:check`
- `./gradlew :androidApp:assembleDebug`
- iOS 按 `docs/development-workflow.md` 执行 `xcodebuild` 验证。
- HarmonyOS 按 `docs/development-workflow.md` 执行 `assembleApp` 验证。
- `./tools/check-sdd.sh`
- 人工在 Android Studio、Xcode、DevEco Studio 各打开至少一个全页面 Preview、一个数据卡 Preview 和一个表单 Preview，确认有数据且无真实副作用。
