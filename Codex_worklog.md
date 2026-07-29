## SDD 记录规范：
> - 每次对话结束后追加一轮记录
> - 每轮以 `# YYYY-MM-DD HH:mm — 内容概要` 开始，时间使用 Asia/Shanghai 实际写入时间并精确到分钟
> - 历史记录无法确认具体时间时使用 `# YYYY-MM-DD（时间未记录）— 内容概要`，不得伪造时间
> - 每条「采纳内容 / 人工审查点 / 验证结果 / 人工修正点」引用稳定 Spec ID；历史 Spec 尚无 ID 时可引用章节号，如 `[auth-mock-spec §8]`
> - **每轮末尾必须有 `## 下轮交接`**，说明：
>   - **已完成**：本轮完成的交付物和关键决策
>   - **未完成 / 阻塞项**：本轮没做完的事项、原因、阻塞条件
>   - **下轮起步建议**：下一个人/AI 从哪里开始、要先读什么文件
> - 本轮的持久决策和坑同时提炼到 `LEARNINGS.md`
> - 历史归档文件在 `docs/worklog/`
---

> 历史条目已归档至 `docs/worklog/2026-07-17-to-2026-07-27.md`。
<!-- 新记录从这里开始追加 -->

# 2026-07-27 14:50 — 鸿蒙个人资料编辑页固定标题栏与顶部布局修复

## 采纳内容
- [PROFILE-EDIT-001] 对照 Android `PersonalProfileEditContent` 与 iOS `PersonalProfileEditView`，确认两端均已把返回、标题和保存栏放在资料滚动区外；HarmonyOS 提取 `ProfileEditHeader` 并作为 `Scroll` 的前置兄弟节点，修复三端结构偏差。
- [PROFILE-EDIT-002] 保留 HarmonyOS 资料滚动内容的 `Alignment.TopStart`，头像和资料字段在短内容场景从滚动视口顶部起排；未通过固定负偏移或全高 `Blank` 针对单一设备补偿。
- [PROFILE-EDIT-001][PROFILE-EDIT-002] 新增 `spec/profile-edit-layout.md`、TRACE 映射和 `tools/check-profile-edit-layout.sh` 三端源结构回归门禁。

## 人工审查点
- [PROFILE-EDIT-001][PROFILE-EDIT-002] `hdc list targets` 未发现已连接的 HarmonyOS 设备，因此标题固定、滚动手势与最终截图位置仍需在 DevEco 模拟器或真机进入“我 → 个人信息”复验。

## 验证结果
- [PROFILE-EDIT-001][PROFILE-EDIT-002] 实现前执行 `./tools/check-profile-edit-layout.sh`，精确失败于 HarmonyOS 编辑标题未提取到 `Scroll` 外；实施后再次执行，三端固定标题结构与 HarmonyOS 顶部对齐检查全部通过。
- [PROFILE-EDIT-001][PROFILE-EDIT-002] 使用项目文档规定的 DevEco 环境执行 `hvigorw assembleApp --no-daemon`，ArkTS 编译、HAP/App 打包通过；保留既有 API 弃用、资源名冲突和未配置签名警告。
- [SDD-009] `./tools/check-sdd.sh` 与 `./tools/check-docs.sh` 通过；首次缺少 `DEVECO_SDK_HOME` 的构建在配置阶段失败，补齐文档规定环境后成功。

## 人工修正点
- [PROFILE-EDIT-001] 将鸿蒙标题栏移出原先带 `18vp` 外层内边距的滚动 `Column` 后，在 `ProfileEditHeader` 自身补回左右 `18vp` 内边距，保持原有返回、标题和保存按钮的横向几何不变。

# 2026-07-27 16:44 — Android 健康首页分层下拉刷新与五态吸附动画

## 采纳内容
- [HLTH-UI-ARCH-011] Android 健康首页改为全页根 `Box`：`HeroTopRow` 固定在顶层，包含摘要、全部健康卡、编辑入口及异常态的 `LazyColumn` 单独按 `pullOffset` 平移；刷新提示作为根 Box 覆盖层，不再占列表布局空间。
- [HLTH-UI-ARCH-011] 新增“下拉刷新”与“释放刷新”中英文资源；保留既有 `CircularProgressIndicator` 尺寸、描边、颜色、图文间距和字号，并按拉动进度应用透明度、轻微缩放与旋转。
- [HLTH-UI-ARCH-012] `PullToRefreshState` 明确拆分 `Idle`、`Dragging`、`Armed`、`Refreshing`、`Resetting`，未达阈值松手约 300ms 归零，达阈值松手先吸附到固定 `RefreshHoldOffset`。
- [HLTH-UI-ARCH-012] 刷新期间提示脱离主体固定间距，通过 Hero/提示实测高度、中央最大宽度、Hero 边界重叠参数和显式 `zIndex` 停靠在顶部中间交界区；右上角现有 Lottie 与固定 4460ms 等待同步，结束后调用 `healthViewModel.refresh()`，再淡出并复位主体。
- [HLTH-UI-ARCH-011][HLTH-UI-ARCH-012] 本轮按用户指定先实现 Android；iOS/HarmonyOS 等价分层和五态动画已在 Spec/TRACE 明确记为跨端债务。

## 人工审查点
- [HLTH-UI-ARCH-011] 需在 Android 模拟器或真机从列表顶部实测：中段滚动不触发、阈值前显示“下拉刷新”、阈值后切为“释放刷新”，且只有主体移动。
- [HLTH-UI-ARCH-012] 需按目标设备状态栏高度和中英文文案复验提示最终停靠区，确认其位于日期/标题与日历/手表之间且仅局部跨越 Hero 底部；必要时只微调集中参数，不改卡片布局。
- [HLTH-UI-ARCH-012] 需人工计时观察 4460ms 手表 Lottie、持续旋转的刷新图标、数据提交时刻及约 300ms 复位是否感知连续。

## 验证结果
- [HLTH-UI-ARCH-011] 新增 `PullToRefreshStateTest` 后首次运行因 `PullRefreshPhase`、`phaseForPullOffset` 不存在而编译红灯；实现后 `./gradlew :androidApp:testDebugUnitTest --tests 'com.example.demo.health.PullToRefreshStateTest'` 通过。
- [HLTH-UI-ARCH-011][HLTH-UI-ARCH-012] `./gradlew :androidApp:assembleDebug` 通过。
- [HLTH-UI-ARCH-011][HLTH-UI-ARCH-012] `./gradlew :androidApp:lintDebug` 通过。
- [HLTH-UI-ARCH-011][HLTH-UI-ARCH-012] `./tools/check-sdd.sh`、`./tools/check-docs.sh`、`./tools/check-resources.sh` 与 `git diff --check` 通过。
- 本轮未执行 Android 设备手势验收；未把运行时视觉标记为已验证。

## 人工修正点
- [HLTH-UI-ARCH-012] 复位阶段会把 `isRefreshing` 从 true 切为 false；若直接在以该值为 key 的 `LaunchedEffect` 中动画，重组可能取消自身。收尾的有限 300ms 复位改为不可中断段，防止状态卡在 `Resetting`，而 4460ms 等待仍可在离开页面时取消。

## 下轮交接
- **已完成**：Android 分层布局、五态状态机、阈值/吸附/停靠集中参数、提示文案、单元测试、Android 构建与文档闭环。
- **未完成 / 阻塞项**：Android 设备运行时手势和最终停靠视觉待人工复验；iOS/HarmonyOS 等价动效为明确跨端债务，不属于本轮用户指定的 Android 文件范围。
- **下轮起步建议**：先读 `HLTH-UI-ARCH-011/012` 与 `PullRefreshDefaults`，在设备上录制一次未达阈值、一次达阈值的完整流程；若只需调视觉，优先调整 `RefreshThreshold`、`RefreshHoldOffset`、`IndicatorBodyGap`、`IndicatorHeroOverlap` 和 `IndicatorMaxWidth`。

# 2026-07-27 16:58 — Android 下拉刷新提示横排稳定与 Hero 顶部定位修正

## 采纳内容
- [HLTH-UI-ARCH-011] 根据用户模拟器截图定位到刷新提示整行被 `rotationZ` 旋转的问题；父 `Row` 现在只负责淡入和 0.94→1.0 的轻微缩放，文字始终保持水平，旋转反馈仅作用于 16dp 刷新图标且最大 45°。
- [HLTH-UI-ARCH-011] 拖动提示不再随主体大幅下沉；位置改由系统状态栏 safe inset、`IndicatorHeroTopGap` 和 8dp 短显现距离计算，主体仍独立按 `pullOffset` 移动。
- [HLTH-UI-ARCH-012] 刷新中的图标和“数据同步中”统一停靠在状态栏安全区下方的 Hero 顶部中央边界，并继续通过提示/Hero 测量、168dp 中央安全宽度与显式 `zIndex` 避开左侧日期标题和右侧操作。

## 人工审查点
- [HLTH-UI-ARCH-011][HLTH-UI-ARCH-012] 已在当前 emulator-5554 复验中文横排和顶部位置；仍建议在带不同刘海/挖孔 inset 的真机确认中央提示与物理开孔之间的视觉余量。

## 验证结果
- [HLTH-UI-ARCH-011] 新增顶部位置和图标旋转测试后，首次因 `indicatorTopForPullProgress`、`pullIndicatorIconRotation` 不存在而编译红灯；实现后 `PullToRefreshStateTest` 全部通过。
- [HLTH-UI-ARCH-011][HLTH-UI-ARCH-012] `./gradlew :androidApp:assembleDebug` 与 `./gradlew :androidApp:lintDebug` 通过。
- [HLTH-UI-ARCH-011][HLTH-UI-ARCH-012] APK 保留数据安装到 emulator-5554，慢速下拉截图 `/private/tmp/health-refresh-drag-horizontal-top-2.png` 确认“数据同步中”保持横排并位于 Hero 顶部中央，主体单独下移。
- `git diff --check` 通过。

## 人工修正点
- [HLTH-UI-ARCH-011] 用户截图证明上一版把旋转放在提示父 Row 的判断错误；本轮将旋转作用域缩小到图标，并用纯函数测试锁定顶部定位与最大旋转角。

## 下轮交接
- **已完成**：Android 刷新提示横排稳定、顶部安全区定位、轻量显现、模拟器运行截图和自动化验证。
- **未完成 / 阻塞项**：不同真机开孔形态待人工复验；iOS/HarmonyOS 等价分层动画仍为既有跨端债务。
- **下轮起步建议**：如需细调高度，只修改 `PullRefreshDefaults.IndicatorHeroTopGap`；如需调整出现幅度，只修改 `IndicatorRevealTravel`，不要再给提示父 Row 增加旋转。

# 2026-07-27 17:08 — Android 下拉刷新三态提示可见性修复

## 采纳内容
- [HLTH-UI-ARCH-011] 修复拖动阶段提示被 `HeroTopRow` 不透明背景遮挡：`Dragging`、`Armed`、`Refreshing`、`Resetting` 的覆盖提示统一使用高于 Hero 的 4f 层级。
- [HLTH-UI-ARCH-011] 提取 `PullRefreshPrompt` 与 `promptForPullRefreshPhase`，明确 `Dragging → 下拉刷新`、`Armed → 释放刷新`、`Refreshing/Resetting → 数据同步中`、`Idle → 隐藏`。
- [HLTH-UI-ARCH-011] 小幅下拉提示改为提前淡入，在刷新阈值 40% 的拉动距离达到完整不透明；位置、轻微缩放和仅图标旋转反馈保持不变。
- [HLTH-UI-ARCH-012] 未修改 80dp 阈值、104dp 主体吸附高度、4460ms Lottie 等待、`healthViewModel.refresh()` 调用及约 300ms 复位逻辑。

## 人工审查点
- [HLTH-UI-ARCH-011] emulator-5554 已验证中文三态；英文资源已有对应文字，但不同语言宽度仍可在真机切换英文后补一次视觉确认。

## 验证结果
- [HLTH-UI-ARCH-011] 三态映射和可见层级测试首次因对应纯函数不存在而编译红灯；实现后新增提前淡入测试再次红灯，最终 `PullToRefreshStateTest` 全部通过。
- [HLTH-UI-ARCH-011][HLTH-UI-ARCH-012] `./gradlew :androidApp:testDebugUnitTest --tests 'com.example.demo.health.PullToRefreshStateTest' :androidApp:assembleDebug :androidApp:lintDebug` 通过。
- [HLTH-UI-ARCH-011] emulator-5554 保持手势截图验证：`/private/tmp/health-refresh-below-threshold-visible-final.png` 显示“下拉刷新”；`/private/tmp/health-refresh-armed-release-prompt-final.png` 显示“释放刷新”；松手后的 `/private/tmp/health-refresh-syncing-prompt-final.png` 显示“数据同步中”并保持主体吸附。

## 人工修正点
- [HLTH-UI-ARCH-011] 上一轮只提高刷新后的提示层级，遗漏拖动/已达阈值阶段；本轮将所有非空闲阶段统一置于 Hero 之上，并提高小幅下拉时的可读性。

## 下轮交接
- **已完成**：Android 下拉刷新三态文案、覆盖层级、提前淡入、自动化测试和模拟器三阶段截图。
- **未完成 / 阻塞项**：英文真机宽度可选复验；iOS/HarmonyOS 等价分层动画仍为既有跨端债务。
- **下轮起步建议**：如后续调整三态行为，先修改 `promptForPullRefreshPhase` 及对应测试；不要按刷新/拖动阶段分别设置低于 Hero 的层级。

# 2026-07-27 17:18 — Android 刷新提示与主体固定间距联动

## 采纳内容
- [HLTH-UI-ARCH-011] `Dragging/Armed` 阶段刷新提示改为通过 `bodyTop - indicatorHeight - fixedGap` 定位，主体每下移 1px，提示同步下移 1px。
- [HLTH-UI-ARCH-011] 新增 `IndicatorBodyGap = 60.dp` 集中参数，使提示在拉动过程中从 Hero 区域逐渐下滑出现，并在接近阈值时位于 Hero 与主体之间。
- [HLTH-UI-ARCH-011] 拖动与已达阈值阶段直接使用随动位置，不经过刷新停靠动画，避免上一轮 dock 动画残值破坏固定距离。
- [HLTH-UI-ARCH-011][HLTH-UI-ARCH-012] 保留三态文案、提前淡入、横排、图标独立旋转和高于 Hero 的层级；主体完成固定高度吸附并进入 `Refreshing` 后，提示才动画停靠到既有刷新位置并显示“数据同步中”。

## 人工审查点
- [HLTH-UI-ARCH-011] 当前 60dp 固定间距已在 emulator-5554 验证；如产品希望提示更靠近主体或更靠近 Hero，只调整 `IndicatorBodyGap`，不改随动公式。

## 验证结果
- [HLTH-UI-ARCH-011] 新增 `draggingIndicatorKeepsFixedGapAndMovesWithBody` 后首次因 `indicatorTopAttachedToBody` 不存在而编译红灯；实现后验证两组主体位置的提示位移相等且底部间距均为 60。
- [HLTH-UI-ARCH-011][HLTH-UI-ARCH-012] `PullToRefreshStateTest`、`:androidApp:assembleDebug`、`:androidApp:lintDebug` 通过。
- [HLTH-UI-ARCH-011] emulator-5554 同一次保持手势截图：`/private/tmp/health-refresh-follow-before-threshold-final.png` 为较短下拉的“下拉刷新”；继续下移后的 `/private/tmp/health-refresh-follow-armed-final.png` 中提示和主体同步下移并切换为“释放刷新”。

## 人工修正点
- [HLTH-UI-ARCH-011] 初版把提示固定在 Hero 顶部，未满足用户强调的“提示和整体平移主体之间距离固定”；本轮恢复拖动联动，同时将刷新后的停靠行为限制在 `Refreshing/Resetting`。

## 下轮交接
- **已完成**：Android 拖动提示与主体固定 60dp 间距、一对一位移、阈值文案切换、刷新停靠隔离、自动化与模拟器验证。
- **未完成 / 阻塞项**：iOS/HarmonyOS 等价分层动画仍为既有跨端债务。
- **下轮起步建议**：视觉距离仅调 `PullRefreshDefaults.IndicatorBodyGap`；拖动路径必须继续直接使用 `indicatorTopAttachedToBody`，不要引入 dock 插值。

# 2026-07-27 17:30 — Android 刷新全阶段固定间距修正

## 采纳内容
- [HLTH-UI-ARCH-011][HLTH-UI-ARCH-012] 删除提示在 `Refreshing/Resetting` 阶段向 Hero 独立停靠的插值；`Idle/Dragging/Armed/Refreshing/Resetting` 统一使用 `bodyTop - indicatorHeight - fixedGap` 定位。
- [HLTH-UI-ARCH-012] 删除复位阶段额外的 12dp 向上退出位移，提示只随主体约 300ms 上移并同步淡出，因此固定间距在松手吸附、4460ms 同步和复位期间都不被破坏。
- [HLTH-UI-ARCH-011] 保持 `IndicatorBodyGap = 60.dp`、80dp 阈值、104dp 主体停留高度、三态文案、现有图标文字视觉与 Lottie/刷新业务时序不变。

## 人工审查点
- [HLTH-UI-ARCH-011][HLTH-UI-ARCH-012] emulator-5554 中 60dp 统一间距已能容纳“数据同步中”；若后续视觉希望扩大距离，只调整 `PullRefreshDefaults.IndicatorBodyGap`，不得再增加刷新阶段专属坐标。

## 验证结果
- [HLTH-UI-ARCH-012] `refreshAndResetKeepTheSameBodyAttachment` 首次因 `indicatorTopForPhase` 不存在而编译红灯；实现后验证 `Refreshing` 与 `Resetting` 在不同主体位置仍保持相同固定间距。
- [HLTH-UI-ARCH-011][HLTH-UI-ARCH-012] `./gradlew :androidApp:testDebugUnitTest --tests 'com.example.demo.health.PullToRefreshStateTest' :androidApp:assembleDebug :androidApp:lintDebug` 通过。
- [HLTH-UI-ARCH-012] emulator-5554 截图 `/private/tmp/health-refresh-fixed-gap-armed.png` 与 `/private/tmp/health-refresh-fixed-gap-syncing.png` 验证：松手后提示与主体同步回吸，文案切换为“数据同步中”，二者间距保持一致。

## 人工修正点
- [HLTH-UI-ARCH-012] 上一轮只保证 `Dragging/Armed` 固定间距，保留了 `Refreshing/Resetting` 独立停靠；本轮按用户反馈将等距约束扩展到整个非空闲生命周期。

## 下轮交接
- **已完成**：Android 下拉、达阈值、松手吸附、数据同步和复位全阶段统一 60dp 间距，并完成单测、构建、Lint 与模拟器截图验证。
- **未完成 / 阻塞项**：iOS/HarmonyOS 等价分层动画仍为明确跨端债务。
- **下轮起步建议**：视觉距离只改 `PullRefreshDefaults.IndicatorBodyGap`；所有阶段继续经 `indicatorTopForPhase` 定位，禁止恢复 Hero 独立停靠或复位额外位移。

# 2026-07-27 17:47 — iOS 与 HarmonyOS 同步 Android 分层下拉刷新

## 采纳内容
- [HLTH-UI-ARCH-013] iOS 新增 `Idle/Dragging/Armed/Refreshing/Resetting` 五态与 `80/34/80/0.4/300/4460` 配置；健康页改为根 `ZStack`，Hero 固定，滚动主体单独平移，提示使用测量后的 Hero/自身高度按 `bodyTop - indicatorHeight - 80` 定位。
- [HLTH-UI-ARCH-013] iOS 继续复用 `UIScrollView.panGestureRecognizer` 观察器，并关闭原生 bounce，避免系统橡皮筋和自定义 offset 重复位移；刷新过程驱动既有 Lottie，4460ms 后执行现有共享刷新，再等距复位。
- [HLTH-UI-ARCH-013] HarmonyOS 健康页改为根 `Stack` 分层；原生 `Refresh` 提供真实偏移与五态事件，默认提示由空 Builder 抑制，独立 `LoadingProgress + Text` 覆盖层按相同固定间距公式移动。
- [HLTH-UI-ARCH-013] iOS/HarmonyOS 新增“下拉刷新”“释放刷新”中英文资源，并加入三端共享资源清单。

## 人工审查点
- [HLTH-UI-ARCH-013] iOS 与 HarmonyOS 均已编译，但本轮没有可交互的双端设备手势截图；建议分别在真机/模拟器保持一次阈值前、阈值后和松手同步态，重点核对 34 停留高度与 80 固定间距。
- [HLTH-UI-ARCH-013] HarmonyOS 项目兼容 API 12，无法安全调用 API 20 的 `maxPullDownDistance`；极限拉距沿用原生边界，普通下拉区间的阈值、阻尼、停留位置和等距规则已对齐 Android。

## 验证结果
- [HLTH-UI-ARCH-013] 实现前跨端刷新五态和 `34/80` 参数静态搜索无匹配，形成红灯；实现后 iOS 与 HarmonyOS 均匹配五态、停留高度和固定间距定义。
- [HLTH-UI-ARCH-013] `xcodebuild -project iosApp/iosApp.xcodeproj -scheme IOSDemo -sdk iphonesimulator -configuration Debug -derivedDataPath /private/tmp/demo-ios-derived CODE_SIGNING_ALLOWED=NO build` 通过。
- [HLTH-UI-ARCH-013] 配置 `NODE_HOME/DEVECO_SDK_HOME/PATH` 后，HarmonyOS `hvigorw assembleApp --no-daemon` 通过。
- [HLTH-UI-ARCH-011][HLTH-UI-ARCH-012] Android `PullToRefreshStateTest`、`:androidApp:assembleDebug`、`:androidApp:lintDebug` 回归通过。
- [HLTH-UI-ARCH-013] `jq empty` 验证 iOS xcstrings 与 HarmonyOS 两份 string.json 格式正确；`check-resources.sh` 通过。`check-resource-maintainability.sh` 仍因 HEAD 已存在的 7 处 iOS 预览中文硬编码失败，本轮新增的 2 处 `Color.clear` 已改用 Token，未新增该债务。
- [HLTH-UI-ARCH-013] `check-sdd.sh` 与 `git diff --check` 通过；`check-docs.sh` 因用户工作区内另行修改的 `docs/reference/注册登陆模块介绍.md` 与可信来源不一致而失败，本轮未覆盖该文件。

## 人工修正点
- [HLTH-UI-ARCH-013] HarmonyOS 首次编译发现页面缺少长度转换函数、颜色 Token 名称错误，并提示 API 20 的最大拉距接口不兼容当前 API 12；修正后 ArkTS 与打包通过。
- [HLTH-UI-ARCH-013] iOS 首次命令使用了不存在的 `iosApp` Scheme；通过 `xcodebuild -list` 确认实际 Scheme 为 `IOSDemo` 后完成构建。

## 下轮交接
- **已完成**：iOS/HarmonyOS 五态、固定 Hero、主体单独移动、三态提示、全阶段 80 固定间距、34 刷新停留高度、4460ms Lottie/刷新时序及三端资源同步。
- **未完成 / 阻塞项**：双端交互截图需有可操作设备后补；资源债务门禁被 HEAD 既有 7 处 iOS 预览中文硬编码阻塞。
- **下轮起步建议**：真机复核优先看阈值前/后和松手后提示底部到主体顶部是否恒为 80；参数分别集中在 iOS `HealthPullRefreshConfiguration`、HarmonyOS `PullToRefreshState.ets`。

# 2026-07-27 18:00 — 补充认证测试、归档 worklog、修复文档门禁

## 采纳内容
- [auth-mock-spec §9][auth-mock-spec §14] 新增 `loginWithNonExistentAccountFails` 测试，验证登录未注册账号时返回 `AccountNotFound`，填补认证覆盖缺口。
- [auth-mock-spec §12] 历史 Codex_worklog 归档至 `docs/worklog/2026-07-17-to-2026-07-27.md`，根日志重置为模板头部。
- [DOC-006] `tools/check-docs.sh` 将 `docs/ios_harmonyos_app_resource_management_guide.md` 从 `obsolete_paths` 和 `stale_references` 移出，该文件用户要求保留不删除。
- [DOC-008] `TEST_REPORT.md` 和 `spec/TRACE.md` 的测试计数更新：LoginUseCaseTest 34→35，业务合计 88→89，common 合计 98→99。
- `spec/TRACE.md` 测试总览表中 `LoginUseCaseTest.kt` 行修复了不匹配的反斜杠转义格式。

## 人工审查点
- 暂无需要人工确认的审查点；本轮为纯补充测试和文档维护，未改动业务逻辑或 UI。

## 验证结果
- `./gradlew :common:testAndroidHostTest --tests '*loginWithNonExistentAccountFails'` 绿灯。
- `./gradlew :common:check` 通过 — 99 条 common 测试全部通过。
- `bash ./tools/check-docs.sh` 通过 — 文档治理全部 PASS。
- `bash ./tools/check-sdd.sh` 通过 — SDD 框架校验全部 PASS。

## 人工修正点
- 无。

# 2026-07-27 18:02 — 修复 HarmonyOS 刷新停留高度参数不生效

## 采纳内容
- [HLTH-UI-ARCH-014] 移除不生效的废弃 `RefreshOptions.offset`，将原生有效 `.refreshOffset` 从刷新阈值改为 `PULL_REFRESH_HOLD_OFFSET`；现在修改 `34 → 4` 会直接改变主体刷新停留高度。
- [HLTH-UI-ARCH-014] 关闭 HarmonyOS 原生自动刷新，由 `onOffsetChange` 和 `RefreshStatus` 记录手势结束时是否仍达到独立的 `PULL_REFRESH_THRESHOLD = 80`，达到才程序化进入刷新。
- [HLTH-UI-ARCH-014] 未达阈值进入 300ms 复位；达到阈值只调度一次 4460ms 刷新，刷新结束后继续使用真实主体偏移保持提示固定间距。

## 人工审查点
- [HLTH-UI-ARCH-014] 建议在 HarmonyOS 设备分别把 `PULL_REFRESH_HOLD_OFFSET` 设置为 `34` 和 `4` 各触发一次刷新，确认主体停留高度明显变化；阈值应始终保持 80，不应随停留高度改变。

## 验证结果
- [HLTH-UI-ARCH-014] 实现前静态检查找不到 `.refreshOffset(PULL_REFRESH_HOLD_OFFSET)`、`.pullToRefresh(false)` 和手动阈值方法，形成红灯；实现后全部匹配。
- [HLTH-UI-ARCH-014] 配置 DevEco 环境后执行 `hvigorw assembleApp --no-daemon`，ArkTS 编译及 App 打包通过。
- [HLTH-UI-ARCH-014] `git diff --check` 通过。

## 人工修正点
- [HLTH-UI-ARCH-014] 上一版误以为废弃 `offset` 仍可控制停留位置，同时把 `.refreshOffset` 绑定到 80 阈值，导致 `PULL_REFRESH_HOLD_OFFSET` 只改常量而不改变运行界面；本轮已将二者从原生配置层彻底解耦。

## 下轮交接
- **已完成**：HarmonyOS 停留高度参数真实生效、80 阈值独立、单次 4460ms 调度、未达阈值复位和构建验证。
- **未完成 / 阻塞项**：需要 HarmonyOS 可交互设备补一组 `34/4` 对比截图。
- **下轮起步建议**：主体停留高度只改 `PullToRefreshState.ets` 的 `PULL_REFRESH_HOLD_OFFSET`；不要再把 `.refreshOffset` 改回 `PULL_REFRESH_THRESHOLD`。

# 2026-07-27 18:07 — Codex_worklog 时间顺序治理

## 采纳内容
- [SDD-009] 保留模板说明、历史归档提示和各轮记录原文，将根 `Codex_worklog.md` 的完整记录块按时间从旧到新排序，最新记录位于文件最下面。
- [SDD-009] 本轮记录继续追加在文件末尾，明确后续日志采用顺序追加方式。

## 人工审查点
- [SDD-009] 暂无需要人工确认的审查点；本轮只调整日志块顺序，不改写历史记录内容。

## 验证结果
- [SDD-009] 时间戳脚本校验通过：10 轮记录从 `2026-07-27 14:50` 递增至 `2026-07-27 18:07`；首次使用当前 Ruby 2.6 不支持的 `filter_map` 而失败，改用 `map + compact` 后通过。
- [SDD-009] `./tools/check-sdd.sh` 通过。
- [SDD-009] `git diff --check` 通过。

## 人工修正点
- 暂无明确人工修正点。

## 下轮交接
- **已完成**：根工作日志已按时间从旧到新排列，并恢复最新记录位于文件末尾的追加语义。
- **未完成 / 阻塞项**：暂无。
- **下轮起步建议**：后续每轮直接在 `Codex_worklog.md` 末尾追加新记录，不要插入到归档提示之后。

# 2026-07-29 10:35 — 健康模块原生导航与返回位置改造

## 采纳内容
- [HLTH-NAV-001/002] 以注册登录模块的导航语义为模板，三端将“体能、记录、探索、我”保持为根层 Tab 状态，将健康详情和卡片编辑迁移为原生 Push/Pop 二级路由；二级页面不再通过健康首页内部条件渲染模拟导航。
- [HLTH-NAV-003] Android/iOS 个人资料编辑迁移到导航栈；HarmonyOS 继续复用既有 `ProfileCompletionPage(editMode=true)` 二级路由。
- [HLTH-NAV-004] Android 提升 `LazyListState`，iOS 保留同一根 View/共享健康 ViewModel，HarmonyOS 普通详情 Pop 不重载根页面，避免返回后回到首卡。
- [HLTH-NAV-005] 健康业务模型、规则、Store 和持久化继续留在 common；三端只新增路由、UI 状态和稳定卡片 ID 桥接。
- [HLTH-NAV-006] 新增三端 `health_recovery_time` 回转箭头时钟语义资源，替换 Recovery 卡片旧图标并登记共享资源清单。

## 人工审查点
- [HLTH-NAV-001/002/004] Android emulator-5554 已完成根层返回、详情系统返回和滚动位置验收；iOS 与 HarmonyOS 仍建议在可交互设备补验根层返回、顶部/系统返回和滚动位置。
- [HLTH-NAV-003] 三端资料编辑的返回、取消和保存成功路径仍建议做一次运行时联调。
- [HLTH-NAV-006] iOS/HarmonyOS 建议在设备上对照设计源复核图标尺寸和着色；三端资源语义与映射已通过静态门禁和构建。

## 验证结果
- [HLTH-NAV-001..006] `./tools/check-health-navigation.sh` 实现前 40 项失败，确认能够捕获缺失行为；实现后 40 项全部通过。
- [HLTH-NAV-005] `./gradlew :common:check :androidApp:assembleDebug` 通过；共享测试及 Android Debug APK 构建成功。
- [HLTH-NAV-001..006] `xcodebuild -project iosApp/iosApp.xcodeproj -scheme IOSDemo -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build` 通过。
- [HLTH-NAV-001..006] 配置 DevEco 环境后执行 `hvigorw assembleApp --no-daemon` 通过；首次因新增 `@Entry` 页根节点不是单一容器失败，修正后构建成功。
- [HLTH-NAV-006] `./tools/check-resource-maintainability.sh` 通过：38 个共享图片资源、2 个 Raw、198 个共享文字键，四端中文硬编码与三端直接颜色债务均为 0；`./tools/check-resources.sh` 通过。
- [HLTH-NAV-001/002/004] Android emulator-5554：Recovery 详情进入前后标题 bounds 均为 `[150,1417][996,1480]`；详情系统返回回到健康首页，根层系统返回后 Launcher 可见。
- `./tools/check-sdd.sh` 与 `git diff --check` 通过。
- `./tools/check-docs.sh` 未通过：仅因本轮开始前已存在的用户修改 `docs/reference/注册登陆模块介绍.md` 与可信恢复源不一致；本轮未修改或覆盖该文件。

## 人工修正点
- [HLTH-NAV-002] Android 首次构建发现详情路由缺少 `HealthCardType` 导入，补齐后构建通过。
- [HLTH-NAV-002] HarmonyOS 首次构建发现新增 `@Entry` 页面必须以单一容器为根，改为 `Stack` 根节点后打包通过。
- [HLTH-NAV-004] iOS 导航图级健康 ViewModel 移除构造期抢先加载，改由已登录健康页首次出现时按空状态加载，避免在用户会话建立前读取健康数据。
- [HLTH-NAV-006] iOS 资源债务门禁发现既有 Preview 中文字面量，改为已有本地化键后门禁归零。

# 2026-07-29 14:52 — 健康卡片 12 类样式解耦与对齐

## 采纳内容
- [HLTH-VIS-040] 依据 Figma「首页 PROGRESS Copy」节点 `16:8096`（2031），将三端健康首页 14 张卡片从 10 类顶层样式解耦为 12 类：仅跑步/骑行能力继续共用 Ability，心率/压力继续共用 Trend。
- [HLTH-VIS-040] Android、iOS、HarmonyOS 分别新增体力恢复、能力、静息心率、HRV 四个独立顶层组件，删除原先按类型切换布局的通用 Gauge/Range 顶层组件。
- [HLTH-VIS-040] 三端分发器改按稳定卡片类型/ID 选择样式；体力恢复 114×78、能力 121×71、静息心率与 HRV 130 宽安全区内分别完成左右内容居中对齐。
- 公共卡片外壳、空态、点击、共享数据契约与其余卡片内容未改；iOS 工程文件只同步登记新增/移除的视觉组件。

## 人工审查点
- Android emulator-5554 已截图核对骑行能力、心率、压力、睡眠、HRV、静息心率、健康快测和体型管理；建议后续在 iOS/HarmonyOS 可交互设备上复核系统字体放大时四张解耦卡的左右安全区。
- 工作树开始前已有两个 iOS `ScrollViewPanObserver` 文件处于 `AD` 状态；本轮未修改、恢复或覆盖这些用户变更。

## 验证结果
- [HLTH-VIS-040] `tools/check-health-card-style-decoupling.sh` 实施前 30 项失败，能够捕获 12 个缺失文件和三端旧复合分发；实现后全部通过。
- `./gradlew :common:check` 与 `./gradlew :androidApp:assembleDebug` 通过。
- `xcodebuild -project iosApp/iosApp.xcodeproj -scheme IOSDemo -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build` 通过。
- 配置 DevEco 环境后执行 `hvigorw assembleApp --no-daemon` 通过；仅保留项目既有弃用与签名配置警告。
- Android emulator-5554 安装 Debug APK 后，中下段截图确认四张解耦卡及保留复用卡未越过圆角边界，主值、说明与右侧图形对齐。
- `./tools/check-sdd.sh` 与 `git diff --check` 通过。
- 既有 `check-health-card-adaptive-layout.sh`、`check-health-cross-platform-parity.sh`、`check-health-card-fidelity.sh` 仍因历史硬编码路径/符号及既存三项资源哈希差异失败；`check-docs.sh` 仍仅因本轮前已有的 `docs/reference/注册登陆模块介绍.md` 与可信恢复源不一致失败，本轮未修改这些无关内容。

## 人工修正点
- iOS 新增组件首次书写时将固定宽度与最小高度合并到不存在的 SwiftUI `frame` 重载，构建前已改为两个连续 `frame` 修饰器；最终 iOS 双架构模拟器构建通过。
- 旧通用 Range 在静息心率右侧也绘制了 HRV 的绿色范围图例；解耦后静息心率只保留 30 天平均、单色范围线、指针和端点，HRV 独立保留正常范围图例与四色分段，恢复 Figma 2031 的各自信息层级。

# 2026-07-29 17:03 — HRV/静息心率紧凑布局与体重历史编辑

## 采纳内容
- [HLTH-VIS-030/041] 三端 HRV 左栏首行改为状态、次行保留均值，右栏删除冗余第三行并把指针主体叠到指标线上方；静息心率缩小端点与横条间距，增加“近 30 天平均”文字竖虚线及横条平均值竖虚线。
- [HLTH-VIS-042] common 为体型管理增加有序 `weightHistoryKg`，每次确认按发生顺序追加并允许重复；proto/JSON schema 升至 v6，旧快照缺字段时以原体重补首条，场景刷新保留已有用户历史。
- [HLTH-VIS-043] Android、iOS、HarmonyOS 体重值旁增加资料编辑同款图标，点击体重或图标打开 30.0–200.0 kg、0.1 kg 步进的滑轮并经 common 保存；右侧说明统一为“本周主要锻炼部位”。

## 人工审查点
- [HLTH-VIS-030/041] 建议在三端设备以正常和异常场景复核 HRV 状态、指针尖端、端点贴合度及近 30 天均值虚线位置。
- [HLTH-VIS-043] 建议在三端设备连续确认 `60.0、61.0、62.0、60.0、59.0`，复核子按钮不会误触卡片详情、滑轮当前值正确回显，并在重启后确认最后体重和完整顺序仍保留。

## 验证结果
- [HLTH-VIS-042] 测试实现前因 `weightHistoryKg`、`saveBodyWeight`、`BodyWeightChanged`/`BodyWeightSaved` 缺失而编译红灯；实现后 `./gradlew :common:check :androidApp:testDebugUnitTest :androidApp:assembleDebug` 通过。
- [HLTH-VIS-030/041/043] `xcodebuild -project iosApp/iosApp.xcodeproj -scheme IOSDemo -sdk iphonesimulator -configuration Debug -destination 'generic/platform=iOS Simulator' build` 通过。
- [HLTH-VIS-030/041/043] `./tools/build-shared-harmony.sh` 完成 KMP bridge/provider 生成；配置 DevEco 环境后执行 `hvigorw assembleApp --no-daemon` 通过。
- `./tools/check-sdd.sh`、`./tools/check-resources.sh`、`./tools/check-resource-maintainability.sh`、`./tools/check-health-card-style-decoupling.sh` 与 `git diff --check` 通过。
- `./tools/check-docs.sh` 仍未通过：仅剩本轮开始前已存在的 `docs/reference/注册登陆模块介绍.md` 与可信恢复源不一致；本轮新增测试计数已同步至 `TEST_REPORT.md` 和 TRACE。

## 人工修正点
- [HLTH-VIS-042] 为区分模板场景数据与用户编辑历史，模型默认历史保持空列表；仅旧持久化 JSON 缺字段时迁移为单条历史，避免场景刷新被误判为用户编辑。
- [HLTH-VIS-043] HarmonyOS 首次构建发现 `ClickEvent` 无 `stopPropagation`，改为子体重入口 `priorityGesture`、卡片父层普通 `gesture` 后构建通过；iOS 体型卡改为独立点击容器，避免整卡 Button 吞掉内部编辑按钮。

# 2026-07-29 17:31 — HRV 短状态高亮与三端指针方向修正

## 采纳内容
- [HLTH-VIS-044] common 将 HRV 状态固定为“很低、偏低、正常、偏高”四档短标签：正常下限以下按图表最小值至正常下限的中点细分，正常区间与高于上限分别映射正常、偏高。
- [HLTH-VIS-044] 三端 HRV 状态统一为 32 号白色粗体主值样式，并在状态与平均值之间保留 4 的间距。
- [HLTH-VIS-030/044] 以用户提供的 HarmonyOS 截图为基准，将 Android/iOS 的 HRV 与静息心率三角改为尖端朝上、底边跨过横条；HarmonyOS 已有方向保持不变。

## 人工审查点
- 用户已反馈体重编辑功能满足需求，并确认一端完整体重数据可持久化；其余平台的重启后历史顺序仍建议继续补验。
- Android 模拟器已核对“偏低”、平均值间距及两张范围卡的上尖三角；iOS 尚未做运行时截图，HarmonyOS 本轮沿用用户截图方向基准。

## 验证结果
- [HLTH-VIS-044] `hrvStatusUsesFourShortRangeLabels` 首次因 `hrvStatusKey` 缺失编译红灯；实现后 `./gradlew :common:testAndroidHostTest --tests '*HealthDashboardUseCaseTest' :androidApp:testDebugUnitTest --tests '*DashboardVisualMathTest' :androidApp:assembleDebug` 通过。
- iOS `xcodebuild -project iosApp/iosApp.xcodeproj -scheme IOSDemo -sdk iphonesimulator -configuration Debug -destination 'generic/platform=iOS Simulator' build` 通过。
- `./tools/build-shared-harmony.sh` 完成 common 检查、KNOI bridge 重新生成及 HarmonyOS `assembleApp`，构建通过；仅保留项目既有 KSP/弃用/签名警告。
- Android emulator-5554 安装新 APK 后截图确认 HRV 显示“偏低”白色粗体，平均值位于其下方，HRV 与静息心率三角均尖端朝上并跨过横条。
- `./tools/check-sdd.sh`、`./tools/check-resources.sh`、`./tools/check-resource-maintainability.sh`、`./tools/check-health-card-style-decoupling.sh` 与 `git diff --check` 通过；`./tools/check-docs.sh` 仅因本轮前已有的 `docs/reference/注册登陆模块介绍.md` 恢复源差异失败。

## 人工修正点
- [HLTH-VIS-030] 旧规范将指针描述为“主体在线上方、尖端贴线”，与用户验收的 HarmonyOS 实际图形方向相反；本轮按截图修订为“尖端朝上、底边跨线”，并同步修正 LEARNINGS，避免后续再次翻转。
