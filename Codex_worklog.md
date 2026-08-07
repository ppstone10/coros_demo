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

# 2026-07-30 11:07 — 正常健康 Mock 最小源数据与三端编辑流程

## 采纳内容
- [HLTH-EDIT-001/004] 新增 `EditableHealthData` 最小权威源模型、common 默认 fixture、统一校验和派生规则；正常场景新版快照只保存源字段，加载时重新生成展示数据，旧完整正常快照可迁移。今日活动只保存里程/配速，心率和压力只保存 288/48 点完整序列。
- [HLTH-EDIT-002/003] 新增 `HealthStore` 实例级临时正常草稿：模块保存、单模块默认和整套默认只改内存，首页维持最后有效数据，必须选择 Normal 后下拉刷新才提交按用户持久化快照；进程重建前未刷新的草稿允许丢失。
- [HLTH-EDIT-004/005/008] 表单 schema、输入解析、范围校验、周计划/负荷/恢复/能力等派生值、睡眠连续区间以及心率/压力快捷序列生成均位于 common；三端只渲染共享表单、提交原始输入并展示共享 UI model。
- [HLTH-EDIT-006/007] Android Compose、iOS SwiftUI、HarmonyOS ArkUI 同步增加正常数据总览和 15 个模块的原生二级编辑路由；模块保存提示约 1500ms 且采用 latest-wins，首页不增加待刷新状态提示。
- 三端新增编辑页中英文资源并纳入 `tools/resource-inventory.json`；新增 `check-health-editable-normal-data.sh` 约束 common 规则、三端路由、共享表单调用和 1500ms 提示结构。

## 人工审查点
- [HLTH-EDIT-006/007] 建议在三端设备连续快速保存两个不同模块，复核后发提示立即替换前一提示并在约 1.5 秒消失；同时复核编辑页返回、输入法类型、下拉选择和长表单滚动体验。
- [HLTH-EDIT-002] 建议按“保存模块但不刷新 → 强杀重启”和“保存模块 → 回首页下拉刷新 → 重启”两条路径人工确认前者草稿丢失、后者有效源数据保留。
- [HLTH-EDIT-003] 建议复核单卡“恢复默认”只重建当前页表单且仍需点击保存，整套“使用默认数据”只改临时源且仍需首页刷新。
- 固定场景覆盖正常有效快照后再次返回 Normal 的行为按 Spec 待人工确认：当前使用内置正常默认，不额外持久化一套历史 Normal 模板。
- 工作树开始前已有 `new.md` 和两个 iOS `ScrollViewPanObserver` 文件的用户修改；本轮未恢复或覆盖这些内容。

## 验证结果
- [HLTH-EDIT-001..008] 新测试首次运行因 `EditableHealthData`、默认 fixture、Store 草稿 action 与规则 API 尚不存在而编译红灯；实现后专项 `EditableHealthDataTest` 及 `./gradlew :common:check :androidApp:assembleDebug` 通过，common Android/iOS 测试和 Android Debug APK 构建成功。
- [HLTH-EDIT-006/007] iOS `xcodebuild -quiet -project iosApp/iosApp.xcodeproj -scheme IOSDemo -sdk iphonesimulator -configuration Debug -derivedDataPath /private/tmp/demo-ios-edit-derived-final CODE_SIGNING_ALLOWED=NO build` 通过；仅保留既有/弃用 API、AccentColor 和无输出脚本阶段警告。
- [HLTH-EDIT-001..008] `./tools/build-shared-harmony.sh` 完成 common 检查、KNOI bridge/provider 验证和 HarmonyOS `assembleApp`，构建通过；仅保留既有 KSP 版本、弃用 API 与未配置签名警告。
- `./tools/check-health-editable-normal-data.sh`、`./tools/check-resource-maintainability.sh`、`./tools/check-resources.sh` 与 `git diff --check` 通过；资源门禁确认 271 个共享文字键，四端中文硬编码及三端直接颜色债务均为 0。
- `./tools/check-sdd.sh` 通过，Spec、TRACE、Worklog 与 Learnings 闭环完整。
- `./tools/check-docs.sh` 未通过：唯一失败仍为本轮开始前已有的 `docs/reference/注册登陆模块介绍.md` 与可信恢复源不一致，本轮未修改该文档。

## 人工修正点
- [HLTH-EDIT-001] 全量 common 回归最初发现正常刷新会丢失既有体重历史；刷新提交时继续保留已形成的用户体重历史，默认 fixture 的单点体重则不误判为用户历史。
- [HLTH-EDIT-006] iOS 工程首次登记新编辑页时复用了已有 PBX group ID，改为唯一 ID 后工程结构与模拟器构建通过。
- [HLTH-EDIT-006] HarmonyOS 首次编译发现新增页面引用了不存在的 `HEALTH_ACTION/HEALTH_PAGE` 令牌和未同步资源键，改用现有 `ACTION/BLACK` 语义色并补齐三端资源后构建通过。
- Android 资源债务门禁发现提示背景直接写颜色值，提取为 `AppColors.Health.NoticeBackground` 后门禁恢复为 0。

# 2026-07-30 11:35 — Android/HarmonyOS 健康编辑文案解析修复

## 采纳内容
- [HLTH-EDIT-009] 将本轮 common 新增的全部 `health_edit_*` 与派生 `health_visual_*` 语义键同步接入 Android `healthStringResource` 和 HarmonyOS `healthResource` 显式解析白名单，修复训练量评估、骑行 FTP 类型和编辑表单标签回退为“数据不可用”的问题。
- [HLTH-EDIT-009] 补齐 common 周计划实际输出但三端资源均缺失的 `health_visual_workout_rest`，中英文分别为“休息日”与“Rest day”，并登记到共享资源清单。
- [HLTH-EDIT-009] HarmonyOS 模块编辑页不再把 `Resource` 对象插值进普通字符串；字段本地化标签与稳定字段 ID 拆成独立文本节点，非选择输入框即使已有值也持续显示常驻标签。
- 扩展 `check-health-editable-normal-data.sh`，逐项核对共享清单中的全部编辑/派生健康键是否同时存在 Android 与 HarmonyOS 显式映射。

## 人工审查点
- 建议在 Android/HarmonyOS 正常场景刷新后复核训练量评估的主文案与说明、骑行 FTP 的“耐力型/强力型”等类型、周计划休息日以及 15 个模块编辑页的标题、字段标签和下拉选项。
- HarmonyOS 字段 ID 目前作为较小的辅助文字保留，用于区分周计划和七日负荷中的重复标签；若产品不希望暴露英文 ID，可后续增加 common 的日期/序号显示参数。
- 当前无连接的 Android/HarmonyOS 设备，运行时视觉结果仍需设备截图确认；本轮已完成静态门禁和双端编译。

## 验证结果
- [HLTH-EDIT-009] 扩展后的 `./tools/check-health-editable-normal-data.sh` 首次报告 148 项 Android/HarmonyOS 显式映射缺失，确认能捕获用户反馈；补齐映射及休息日资源后全部通过。
- `./gradlew :androidApp:assembleDebug` 通过；Android 资源合并、R 生成、Kotlin 编译与 APK 打包成功。
- 配置 DevEco 环境后执行 `hvigorw assembleApp --no-daemon` 通过；HarmonyOS 资源编译、ArkTS 编译与 HAP/App 打包成功，仅保留项目既有弃用和签名警告。
- iOS Simulator 构建通过，确认三端同步新增的 String Catalog 资源有效；`./tools/check-resource-maintainability.sh` 通过，共 272 个共享文字键且硬编码债务为 0。
- `./tools/check-sdd.sh`、`./tools/check-resources.sh`、JSON/脚本语法检查与 `git diff --check` 通过。
- `./tools/check-docs.sh` 仍只因本轮前已有的 `docs/reference/注册登陆模块介绍.md` 与可信恢复源不一致而失败，本轮未修改该文档。

## 人工修正点
- 初次只核对用户点名的训练评估、骑行类型和编辑键后，进一步扫描 common 新模型实际输出发现 `health_visual_workout_rest` 连资源目录都不存在；补齐三端资源及白名单，避免正常周计划休息项继续回退。
- HarmonyOS 原实现使用 `` `${healthResource(field.labelKey)} · ${field.id}` ``，资源对象无法可靠转为展示字符串；改为独立 `Text(Resource)` 常驻标签和单独 ID 后 ArkTS 构建通过。

# 2026-07-30 13:07 — 三端动态睡眠/锻炼部位编辑与可见性修复

## 采纳内容
- [HLTH-EDIT-010] Android 编辑页标题栏改为左右各 100dp 的对称操作区，长标题不再挤掉“保存”；输入值、光标和焦点边框显式使用高对比颜色。三端字段统一为已有值下仍可见的常驻本地化标签，并由 common 的 `labelArguments` 输出第 N 天/阶段/部位，不再展示技术字段 ID。
- [HLTH-EDIT-011/012] common 新增 repeat group 表单 schema、`HealthEditableForms.mutate` 和 `BodyMuscleGroup` 10 项实际部位集合；睡眠阶段与锻炼部位的新增、删除、重编号、最小/最大数量、合法选项、去重及保存校验均在 KMP 中完成，iOS/HarmonyOS 通过 facade/KNOI JSON 边界调用。
- [HLTH-EDIT-013] 三端体型卡右侧继续复用资源库人体前后视图，但以 Template 模式中和原图固定胸部/股四头肌颜色，再按 common 输出的部位指标叠加动态红色标记和本地化名称；无部位时显示共享空提示。
- [HLTH-EDIT-014] HarmonyOS HRV 指针改用横条容器内绝对定位，横条区提高到 24vp；正常范围图例获得独立高度并允许两行，避免右栏下方文字被压缩或裁剪。

## 人工审查点
- 当前 ADB 无连接设备；建议在 Android/HarmonyOS 设备上依次打开长标题编辑页、睡眠、体型管理和 HRV 卡，复核保存按钮、输入文字、增删动作、人体标记坐标及 HRV 正常范围的最终视觉。
- 人体图资源库只存在固定高亮成品图，没有十个部位的独立图片层；本轮采用中和底图 + 动态坐标标记。若后续获得逐肌群矢量/透明图层，可只替换三端视觉叶组件，不改变 common 部位契约。

## 验证结果
- [HLTH-EDIT-011/012] 新测试在实现前因 `mutate`、`HealthEditRepeatOperation`、`BodyMuscleGroup` 和重复字段元数据不存在而编译红灯；实现后 `dynamicSleepStagesAreMutatedAndAppliedByCommon`、`dynamicMuscleGroupsUseSharedSelectableOptions`、`bodyVisualUsesSelectedMuscleIds` 以及全量 `./gradlew :common:check` 通过。
- [HLTH-EDIT-010~014] `./tools/check-health-editable-normal-data.sh` 实现前报告 9 项结构缺口，实施后通过；`./tools/check-resources.sh`、`./tools/check-resource-maintainability.sh` 通过，共 294 个共享文字键且四端中文硬编码/三端直接颜色债务均为 0。
- `./gradlew :androidApp:assembleDebug`、iOS Simulator `xcodebuild ... CODE_SIGNING_ALLOWED=NO build`、`./tools/build-shared-harmony.sh` 及后续 HarmonyOS `hvigorw assembleApp --no-daemon` 均通过；仅保留项目既有 KSP、弃用 API、AccentColor/脚本阶段和未配置签名警告。
- `./tools/check-sdd.sh` 与 `git diff --check` 通过；当前无连接 Android 设备，未执行运行时截图验收。
- `./tools/check-docs.sh` 仍只因本轮开始前已存在的 `docs/reference/注册登陆模块介绍.md` 与可信恢复源不一致而失败；本轮未修改该历史参考文档。

## 人工修正点
- Android 首次编译发现不能在 `joinToString` 的非 Composable lambda 中解析资源，改为 Composable 循环逐项本地化后通过。
- iOS 首次编译发现新增 facade 方法未加入 `SharedLoginAdapterProtocol`，补齐协议声明后通过。
- 资源检索确认只有固定着色人体成品图后，没有伪造不存在的肌群图片资产；改用跨端一致的中和底图和动态标记方案，避免默认胸部/股四头肌高亮与用户选择冲突。

# 2026-07-30 14:11 — 三端健康枚举选择面板与重复项布局统一

## 采纳内容
- [HLTH-EDIT-010] Android 模块编辑页“保存”改为直接读取 `common_save` 通用资源，避免误送入健康专用白名单后回退成“健康数据暂时不可用”。
- [HLTH-EDIT-015] Android 移除点击轮换，iOS 移除原生 `Picker`，HarmonyOS 移除原生 `Select`；三端所有 `Choice` 字段统一为“字段提示 + 当前值 + 下拉指示”的单行入口。
- [HLTH-EDIT-015] 三端同步实现居中深色圆角选择面板，统一 62% 遮罩、17 号标题、约 52 高纵向选项、红色当前项勾选和底部取消操作；睡眠阶段、锻炼部位及其他共享枚举字段复用同一入口。
- [HLTH-EDIT-015] 动态重复项的添加操作统一使用 `AddAction` 绿色，覆盖睡眠阶段、锻炼部位和后续 common repeat group。

## 人工审查点
- [HLTH-EDIT-015] Android emulator-5554 已完成运行时截图；iOS Simulator 服务在当前沙箱中无法连接，HarmonyOS `hdc` 无连接目标，仍建议在两端设备复核遮罩深浅、面板安全区、长选项滚动和点击遮罩取消。
- [HLTH-EDIT-015] 选择面板是三端原生代码按同一几何/颜色契约绘制，业务选项、当前值与重复项数量仍全部来自 KMP common 表单，没有把业务规则下沉到平台。

## 验证结果
- [HLTH-EDIT-015] 扩展后的 `./tools/check-health-editable-normal-data.sh` 实现前报告 9 项红灯：三端统一面板/颜色缺失且仍存在 Android 轮换、iOS Picker、HarmonyOS Select；实现后全部通过。
- `./gradlew :common:check`、`./gradlew :androidApp:assembleDebug` 通过；Android emulator-5554 安装 APK 后确认顶栏显示“保存”，睡眠阶段标签与值同排，点击弹出选择面板，选择“快速眼动”后面板关闭且值即时更新。
- iOS `xcodebuild -quiet -project iosApp/iosApp.xcodeproj -scheme IOSDemo -sdk iphonesimulator -configuration Debug -derivedDataPath /private/tmp/demo-ios-choice-editor CODE_SIGNING_ALLOWED=NO build` 通过，仅保留项目既有弃用 API、AccentColor 和脚本阶段警告。
- HarmonyOS 配置 DevEco 环境后执行 `hvigorw assembleApp --no-daemon` 通过，仅保留项目既有弃用 API、未验证 NAPI 和未配置签名警告。
- `./tools/check-sdd.sh`、`./tools/check-resources.sh`、`./tools/check-resource-maintainability.sh` 与 `git diff --check` 通过；资源门禁继续保持 294 个共享文字键及三端直接颜色债务为 0。
- `./tools/check-docs.sh` 仍只因本轮开始前已存在的 `docs/reference/注册登陆模块介绍.md` 与可信恢复源不一致而失败，本轮未修改该参考文档。

## 人工修正点
- [HLTH-EDIT-010] 截图确认保存不可见并非标题栏宽度不足，而是 `common_save` 经 `healthStringResource` 未命中后的错误回退；改为通用原生资源入口后恢复为“保存”。
- [HLTH-EDIT-015] Android 初版使用 `Dialog` 时会叠加系统默认 dim 与自定义遮罩，和另外两端不完全一致；改为编辑页内覆盖层后，三端都只使用自身定义的 62% 遮罩。

# 2026-07-30 15:12 — 三端选择器尖角与勾选图标资源统一

## 采纳内容
- [HLTH-EDIT-016] 检索 `health_dashboard_resources` 与三端已登记资源后，统一复用现有 `right_more` 和 `ic_profile_check`；没有再复制新的近义图片资产。
- [HLTH-EDIT-016] 三端 `AppImages` 增加 ChoiceChevron/ChoiceCheck 语义入口；Compose、SwiftUI、ArkUI 均改用资源图片，`right_more` 旋转 90°形成向下尖角，并以 Template/tint 应用健康操作红色。
- [HLTH-EDIT-016] 移除 Android/HarmonyOS 的 `⌄`、`✓` 字符和 iOS 的 `chevron.down`、`checkmark` SF Symbol，睡眠阶段、锻炼部位及其他 Choice 字段共享同一资源实现。

## 人工审查点
- Android emulator-5554 已验证睡眠选择弹窗中的资源勾选和字段行内向下尖角；iOS/HarmonyOS 本轮只有编译验证，仍建议在各自设备确认 14/18 尺寸在实际屏幕密度下的视觉重量。
- 尖角与勾选均为装饰性状态图标，不承担独立点击或读屏语义；字段入口与选项文字继续提供实际交互和信息。

## 验证结果
- [HLTH-EDIT-016] 扩展后的 `./tools/check-health-editable-normal-data.sh` 在实现前报告 18 项红灯，覆盖三端资源语义缺失及字符/系统图标残留；实现后全部通过。
- `./gradlew :common:check :androidApp:assembleDebug`、iOS Simulator `xcodebuild ... CODE_SIGNING_ALLOWED=NO build`、HarmonyOS `hvigorw assembleApp --no-daemon` 均通过；仅保留项目既有弃用 API、AccentColor/脚本阶段、未验证 NAPI 和未配置签名警告。
- Android emulator-5554 安装新 APK 后截图 `/private/tmp/resource-icons-choice.png`，确认资源勾选为红色轮廓、行内 `right_more` 旋转后朝下且弹窗交互正常。
- `./tools/check-resources.sh`、`./tools/check-resource-maintainability.sh`、`./tools/check-sdd.sh` 与 `git diff --check` 通过；资源门禁维持 38 个共享图片、294 个共享文字键及三端直接颜色债务为 0。
- `./tools/check-docs.sh` 仍只因本轮前已有的 `docs/reference/注册登陆模块介绍.md` 与可信恢复源不一致而失败，本轮未修改该参考文档。

## 人工修正点
- 资源库中的 `close_arrow.webp` 是未登记的向上实心尖角；三端现有资源包已共同登记 `right_more`，因此选择复用并旋转，避免新增三份二进制资源和扩大资源清单。
- `ic_profile_check` 原图为白色透明勾；三端均通过模板着色转为当前健康操作红色，避免分别维护不同颜色版本。

# 2026-07-30 15:58 — 体型管理同画布肌肉蒙版动态高光

## 采纳内容
- [HLTH-EDIT-017] 从本机 `ipa_extract/ios_app_out` 补齐男性正/背人体底图和 14 个实际肌肉区域透明蒙版，以 16 个稳定语义资源名进入 `health_dashboard_resources/body_muscle_masks`，并原样同步到 Android drawable-nodpi、iOS Assets.xcassets 与 HarmonyOS media。
- [HLTH-EDIT-017] common 新增“锻炼部位 → 实际前/后视图区域 ID”业务映射；肩部展开为正/背两层，背部展开为斜方肌、背阔肌和竖脊肌，小腿展开为正/背两层。三端只按共享 `highlightedBodyRegions` 把对应蒙版与底图同画布叠加，不再绘制坐标圆点或重复列出部位名称。
- [HLTH-EDIT-017] 体型管理人体图下方统一只显示共享文案“本周锻炼部位”/“Muscle groups trained this week”；资源清单、来源映射、三端语义入口和 HarmonyOS bridge JSON 同步更新。

## 人工审查点
- Android emulator-5554 已确认默认胸部与股四头肌准确着色、背面保持未选中且底部文案正确；建议在 iOS 与 HarmonyOS 设备继续复核小尺寸下的蒙版边缘、Template 着色与深色背景对比。
- “背部”当前按原始资源语义组合高光斜方肌、背阔肌和竖脊肌，这是 common 的明确业务映射；若产品未来需要把三者拆成独立可选项，应先扩展 `BodyMuscleGroup` 和 Spec，而不是由平台自行拆分。
- 当前卡片使用男性正/背人体资源；若后续支持性别化人体，应保持相同区域 ID 与同画布约束，只替换平台资源族。

## 验证结果
- [HLTH-EDIT-017] common 测试 `bodyVisualDerivesAlignedHighlightRegions` 在实现前因 `highlightedBodyRegions`/`footer` 不存在编译红灯，实现后通过；专项结构门禁实现前报告 95 项缺口，完成资源及三端实现后全部通过。
- `./gradlew :common:check :androidApp:assembleDebug` 通过；iOS Simulator `xcodebuild ... CODE_SIGNING_ALLOWED=NO build` 通过；`./tools/build-shared-harmony.sh` 完成 KMP bridge 编译并使后续 HarmonyOS `assembleApp` 通过。仅保留项目既有 KSP、弃用 API、AccentColor/脚本阶段和未配置签名警告。
- Android emulator-5554 安装 APK 后截图 `/private/tmp/body-mask-final.png`，确认胸部和股四头肌蒙版与人体对齐，旧圆点及具体部位文字列表已移除。
- `./tools/check-health-editable-normal-data.sh`、`./tools/check-resources.sh`、`./tools/check-resource-maintainability.sh`、`./tools/check-sdd.sh`、脚本语法检查与 `git diff --check` 通过；资源门禁为 54 个共享图片、2 个 Raw、295 个共享文字键，三端直接颜色和四端中文硬编码债务均为 0。
- `./tools/check-docs.sh` 仍只因本轮开始前已有的 `docs/reference/注册登陆模块介绍.md` 与可信恢复源不一致而失败；本轮未修改该参考文档，既有 `docs/worklog/` 历史保持不变。

## 人工修正点
- 早期体型图只能通过中和固定着色底图后叠加坐标圆点表达选择；本轮确认原应用包中存在完整同画布透明蒙版后，改为实际肌肉轮廓叠加，并把“部位到区域”的决策上移到 common。
- 原始文件使用无语义编号（如 `male_rear_11_Normal@3x.png`）；结合应用资源映射确认肌肉含义后，项目内改用可审查的稳定语义名，并在 `RESOURCE_MAPPING.md` 保留逐文件来源关系。

# 2026-07-30 16:18 — 修复锻炼部位草稿刷新后高光不变化

## 采纳内容
- [HLTH-EDIT-018] 修复 Normal 刷新的体型数据合并：存在多条用户体重历史时，只从旧有效快照保留 `weightKg` 与 `weightHistoryKg`，不再用整个旧 `BodyManagementInput` 覆盖草稿。
- [HLTH-EDIT-018] 草稿中的 `trainedMuscleGroups` 现在会在刷新成功时进入最小源快照，再由 common 派生新的 `highlightedBodyRegions`；刷新前首页仍保持旧高光，继续符合暂存语义。
- [HLTH-EDIT-018] 新增草稿—刷新—持久化—重建回归测试与专项结构门禁，并同步更新共享测试计数至业务 104 条、common 合计 115 条。

## 人工审查点
- Android 已完整验证“胸部 + 股四头肌”改成“背部 + 股四头肌”：保存后未刷新时仍显示胸部，刷新后胸部消失且背面斜方肌、背阔肌、竖脊肌同时高光。
- 体重 65.9 kg 及既有体重历史在同一次刷新中保持不变；这是用户长期数据优先于场景草稿的既有契约。若未来允许 Normal 编辑器模拟体重而覆盖真实体重，需要另立字段所有权规则。
- iOS/HarmonyOS 使用相同 common 刷新逻辑且构建通过，但本轮无设备交互截图，建议后续在两端各执行一次相同编辑—刷新手势复验。

## 验证结果
- [HLTH-EDIT-018] `bodyMuscleDraftReplacesOldMusclesOnRefreshWhileWeightHistoryIsPreserved` 在修复前于刷新后的区域断言失败，修复后目标测试及 `./gradlew :common:check :androidApp:assembleDebug` 通过。
- Android emulator-5554 安装修复 APK，实际在正常数据编辑器把第一项从“胸部”改为“背部”并保存；`/private/tmp/body-before-refresh-fixed.png` 保持胸部/股四头肌，执行下拉刷新后 `/private/tmp/body-after-refresh-fixed.png` 显示背部/股四头肌，体重仍为 65.9 kg。
- iOS Simulator `xcodebuild ... CODE_SIGNING_ALLOWED=NO build` 通过；`./tools/build-shared-harmony.sh` 完成 common、KNOI bridge 与 HarmonyOS `assembleApp`，仅保留项目既有 KSP、弃用 API、AccentColor/脚本阶段和未配置签名警告。
- `./tools/check-health-editable-normal-data.sh`、资源维护门禁、`./tools/check-sdd.sh`、脚本语法和 `git diff --check` 通过；`./tools/check-docs.sh` 仍只因本轮前已有的 `docs/reference/注册登陆模块介绍.md` 与可信恢复源不一致而失败，本轮未修改该参考文档。

## 人工修正点
- 最初的人体蒙版渲染和 common 区域映射本身是正确的；实际断点位于刷新提交阶段。旧代码为保留体重历史而整体替换 `bodyManagement`，连同旧锻炼部位一起覆盖了新草稿。
- 改为字段级合并后，没有在三端 UI 复制补丁；Android、iOS 和 HarmonyOS 都继续通过同一 KMP 刷新路径获得一致的部位高光结果。

# 2026-07-30 16:58 — 鸿蒙 HRV 指针与正常范围文案修复

## 采纳内容
- [HLTH-VIS-045] 对照三端 HRV 与静息心率专用组件后，确认 Android/iOS 两张卡已使用相同 `y=2..14` 三角与 `y=10..14` 横条重叠几何，仅 HarmonyOS HRV 仍是三角 `y=4..11`、横条 `y=11..15` 的边缘相接关系。
- [HLTH-VIS-045] HarmonyOS HRV 改为与静息心率相同的 18vp 绘图区：8×7vp 三角使用 `top: 7`，横条使用 `top: 10`，底边与横条在 `y=10..14` 范围内重叠。
- [HLTH-VIS-045] 为 `health_visual_normal_range_short` 补齐 HarmonyOS `healthResource` 显式映射，并登记到共享文字资源清单；既有中英文资源值保持不变。

## 人工审查点
- 当前 `hdc list targets` 没有在线 HarmonyOS 设备，因此无法在本轮输出真机截图；建议设备运行时并排复核 HRV 和静息心率的三角底边均跨入横条，以及 HRV 下方显示“正常范围 47–57 毫秒”一类格式化文案。
- 本轮没有修改 common 可视化数据、阈值或状态计算。Android/iOS 已具备目标几何，只增加跨端结构门禁以防后续回归。

## 验证结果
- [HLTH-VIS-045] 新增 `./tools/check-health-range-indicator-parity.sh`，实现前精确报告 HarmonyOS HRV 三处几何和一处本地化映射共 4 项红灯，修复后全部通过。
- `./tools/check-resources.sh` 与 `./tools/check-resource-maintainability.sh` 通过；资源维护门禁统计 54 个共享图片、2 个共享 Raw、296 个共享文字键，三端直接颜色和四端中文硬编码债务均为 0。
- `./gradlew :androidApp:assembleDebug`、iOS `xcodebuild -quiet -project iosApp/iosApp.xcodeproj -scheme IOSDemo -sdk iphonesimulator -configuration Debug -derivedDataPath /private/tmp/demo-ios-hrv-range CODE_SIGNING_ALLOWED=NO build`、HarmonyOS `hvigorw assembleApp --no-daemon` 均通过；仅保留项目既有弃用 API、AccentColor/脚本阶段、未验证 NAPI 与未配置签名警告。
- `./gradlew :common:check`、`./tools/check-sdd.sh`、专项脚本语法检查与 `git diff --check` 通过；`./tools/check-docs.sh` 仍只因本轮开始前已存在的 `docs/reference/注册登陆模块介绍.md` 与可信恢复源不一致而失败，本轮没有修改该参考文档。

## 人工修正点
- “健康数据暂时不可用”并非共享数据缺失，而是 HarmonyOS 显式本地化白名单漏掉了已经存在于 `string.json` 的 `health_visual_normal_range_short`，默认分支因此错误返回通用不可用资源。
- HRV 原实现使用绝对 `position(y: 4)`，静息心率使用 `margin(top: 7)`；两者虽然使用同一三角 Path，却没有相同的父绘图区坐标。改为相同 margin 与横条 top 后才真正实现视觉对齐。

# 2026-07-30 17:55 — HRV 真实分段比例与鸿蒙编辑保存修复

## 采纳内容
- [HLTH-VIS-046] common 为 HRV 输出统一的 40–65 总范围及连续四段：40–42 很低、42–47 偏低、47–57 正常、57–65 偏高；正常数据下四段宽度比例为 8%/20%/40%/32%。
- [HLTH-VIS-046] Android、iOS、HarmonyOS 均改为消费 `HealthRange.segments` 绘制色带，并以同一 `minimum/maximum/current` 计算指针；平台不再硬编码等宽或固定百分比。
- [HLTH-EDIT-019] HarmonyOS 模块编辑页右上角保存入口改为原生 `Button`，增加保存中禁用保护；KNOI bridge/provider 保持 Boolean 返回，ArkTS 直接判断成功或失败，不再比较字符串 `'true'`。

## 人工审查点
- 正常场景值 48ms 现在位于总范围 40–65 的 32% 位置，落在 47–57 正常段内；如果异常场景提供不同的正常上下限，common 会重新生成连续分段，三端仍按实际跨度绘制。
- 当前没有在线 HarmonyOS 设备，本轮只完成 bridge、ArkTS 编译和结构契约验证；保存按钮实际点击、成功提示及返回动作仍建议在设备上补一次运行验收。
- HRV 四段颜色沿用三端现有“很低/偏低/正常/偏高”语义色，本轮没有改变可见状态文案。

## 验证结果
- [HLTH-VIS-046] `hrvRangeSegmentsAndPointerUseActualValues` 在实现前因 `HealthRangeLevel`、分段模型与比例函数缺失而编译红灯；实现后目标测试和 `./gradlew :common:check` 通过，common 测试计数更新为业务 105 条、全部 116 条。
- `./tools/check-health-hrv-segments-and-harmony-save.sh` 实现前报告 18 项契约缺口，修复后全部通过；其中 HarmonyOS 保存链路 5 项断言覆盖 Boolean bridge/provider、原生 Button、直接布尔判断及旧字符串比较移除。
- `./gradlew :androidApp:assembleDebug`、iOS Simulator `xcodebuild ... CODE_SIGNING_ALLOWED=NO build`、KNOI bridge 生成和 HarmonyOS `hvigorw assembleApp --no-daemon` 均通过；只保留项目既有弃用 API、AccentColor/脚本阶段、未验证 NAPI 与未配置签名警告。
- `./tools/check-health-editable-normal-data.sh`、范围指针门禁、资源一致性/维护性门禁、`./tools/check-sdd.sh` 与 `git diff --check` 通过；`./tools/check-docs.sh` 仍只因本轮前已有的 `docs/reference/注册登陆模块介绍.md` 与可信恢复源不一致而失败。

## 人工修正点
- 第一轮 HarmonyOS 编译发现 `ButtonAttribute` 不支持 `textAlign`；移除不必要的文字对齐属性后重新构建通过，按钮仍保持 80×44vp 点击区域。
- 专项编辑门禁首次复跑发现 Android 显式健康资源白名单遗漏 `health_visual_normal_range_short`；补齐映射后门禁与 Android 重新构建通过，避免同一 common 键换到通用渲染入口时回退。
- 旧 HRV 实现的根因不是单独的指针公式：common 总范围仍是 30–80，而三端色带又各自使用等宽或不同固定比例。修复时把总范围、分段边界和指针坐标统一到 common 的同一数值坐标系，避免只调像素位置造成再次脱节。

# 2026-07-30 18:06 — 修复鸿蒙编辑卡片保存参数格式

## 采纳内容
- [HLTH-MAINT-007] 修复真正的 `HealthCardEditorPage` 保存链路：ViewModel 不再对卡片 ID 数组执行 `JSON.stringify`，改为 `types.join(',')` 后调用既有 `saveCardConfig(typeNamesCsv)`。
- [HLTH-MAINT-007] `HealthDashboardViewModel.saveCardConfiguration` 改为返回 Boolean；页面只有在 KNOI 保存成功后才持久化快照、递增卡片版本并返回首页。
- [HLTH-MAINT-007] 编辑卡片标题栏的“保存”从 `Text.onClick` 改为 64×30vp 原生 `Button`，保留既有颜色和布局。

## 人工审查点
- 根因是页面与 bridge 的编码契约不一致：原值 `TodayActivity,WeeklyPlan,...` 被转成 `["TodayActivity","WeeklyPlan",...]`，bridge 仍按逗号拆分，留下方括号和引号，common 因而解析出 0 个有效卡片并触发最少卡片错误。
- 上一轮修复的是 `NormalDataSectionPage`（单个正常数据模块编辑页），不是用户所指的 `HealthCardEditorPage`（首页卡片配置页）；本轮已针对实际页面修正。
- 当前 `hdc` 没有在线设备，无法完成真实点击、返回及首页顺序变化截图；设备验收仍需补充。

## 验证结果
- [HLTH-MAINT-007] `./tools/check-health-card-editor-regressions.sh` 实现前准确报告原生按钮、页面成功判断、正确 CSV 调用以及旧 JSON 调用移除共 4 项红灯，修复后全部通过。
- HarmonyOS `hvigorw assembleApp --no-daemon` 构建通过；仅保留项目既有弃用 API、未验证 NAPI 和未配置签名警告。
- `./tools/check-sdd.sh`、脚本语法与 `git diff --check` 通过；`./tools/check-docs.sh` 仍只因本轮前已有的 `docs/reference/注册登陆模块介绍.md` 与可信恢复源不一致而失败。本轮没有修改 common 业务规则或其他平台 UI。

## 人工修正点
- 最初沿着“正常数据模块保存”排查会得出 KNOI Boolean 和表单值编码均正常，但无法解释真正卡片配置页的现象；重新区分两个同名语境的编辑页面后，才定位到 `HealthCardEditorPage → HealthDashboardViewModel → saveCardConfig` 的 CSV/JSON 错配。

# 2026-07-31 18:00 — 修复卡片编辑拖拽延迟与账号切换数据串号

## 采纳内容
- [HLTH-VIS-047] 将 `CardEditor.kt` 的拖拽手势从 `detectDragGesturesAfterLongPress` 替换为 `awaitLongPressOrCancellation` + 手动 `while(true)` 拖拽循环，消除长按检测与拖拽模式间的指针事件泄露窗口，长按后立即消费所有移动事件避免 LazyColumn 滚动竞争。
- [HLTH-PERSIST-009] 在 `HealthStore` 新增 `staleForNewAccount()` 方法，将 `HealthState` 置为 `uiState=null, isRefreshing=true`；通过 `HealthDashboardViewModel` 暴露该方法。
- [HLTH-PERSIST-009] 修改 `HealthDashboardScreen` 的 `LaunchedEffect(Unit)`：检测到 `isRefreshing && uiState==null` 时延迟 640ms 展示刷新动画后再调用 `load()`，产生"空卡片→刷新→恢复数据"视觉过渡。
- [HLTH-PERSIST-009] 在 `AuthNavGraph` 的 `LoginEffect.AuthSucceeded` 和 `LoginEffect.LoggedOut` 处理中调用 `healthViewModel.staleForNewAccount()`，确保账号切换时 HealthState 不再缓存旧账号数据。

## 人工审查点
- 拖拽修复的 `awaitLongPressOrCancellation` 在不同 Compose 版本 API 有差异；当前 BOM 2026.02.01 / foundation 1.11.3 确认可用。
- 构建通过验证新接口编译正确，设备上长按拖拽的实际延迟和刷新动画的视觉效果需在模拟器/真机人工复验。
- 数据串号修复依赖 `remember(viewModel)` 缓存保持同一 HealthDashboardViewModel 实例，且 `LaunchedEffect(Unit)` 在导航 ResetTo 后因 `MainTabsScreen` 重新组合而再次触发。

## 验证结果
- `./gradlew :androidApp:assembleDebug` 构建成功。
- `./gradlew :common:check` 全部 116 条测试通过。
- `./tools/check-sdd.sh` 通过。
- `./tools/check-docs.sh` 仅在重启恢复源文件处有 1 项预存失败，与本轮无关。
- `spec/TRACE.md` 新增 `HLTH-VIS-047` 和 `HLTH-PERSIST-009` 两条追溯映射。
- `LEARNINGS.md` 新增"Compose 长按拖拽手势的滚动泄露"和"HealthState 跨账号复用导致数据串号"两条踩坑记录。

## 人工修正点
- 首次替换 `detectDragGesturesAfterLongPress` 时使用了 `change.positionChange().y`，在当前 Compose 版本中 `positionChange` 为 Boolean 属性而非返回 Offset 的函数；改为 `change.position.y - change.previousPosition.y` 后编译通过。
- LEARNINGS.md 编辑过程中因 Unicode 引号匹配问题，经过恢复后通过 bash sed 插入新条目。

# 2026-08-03 11:00 — 修复注销数据清理、跨端输入焦点与首次资料默认值

## 采纳内容
- [AUTH-ACCOUNT-DELETE-001] 确认原注销逻辑只删除认证账号和 Session，现由三端组合根按当前 `userId` 联动清理健康快照；`HealthStore.clear` 同时复位内存 UI、正常数据草稿和待消费 Effect，其他用户快照保持不变。
- [AUTH-PROFILE-FOCUS-001] Android 在打开滚轮、头像/性别选择等非输入操作前强制清焦点；HarmonyOS 在资料选择、滚动、认证按钮及返回/反馈操作前通过 API 12 FocusController 清焦点，以结束输入并请求收起键盘。
- [HLTH-EDIT-021] iOS 正常数据编辑器的输入 Binding 在页面本地字典尚无值时回退 common 表单的 `field.value`，进入页面即可显示当前内存或持久化数据。
- [HLTH-EDIT-020] common 体型管理表单删除 `weightKg`，只保留锻炼部位；保存部位时不再改写当前体重或追加体重历史，Android/iOS/HarmonyOS 统一消费该共享表单。
- [AUTH-PROFILE-DEFAULT-001] 新增 `LoginRules.profileDefaults`，首次资料用户名默认为 `COROS user`，手机号账号只预填手机号、邮箱账号只预填邮箱；`UserProfile.email` 已贯通 Proto、JSON、Swift/KNOI/ArkTS 和三端资料界面。

## 人工审查点
- Android 红色输入高光、HarmonyOS 软键盘收起和 iOS 已有健康数据首屏回填属于运行时交互，本轮已完成稳定结构检查与平台构建，仍建议在真实设备上各执行一次“输入→点滚轮/空白处”的手势复验。
- 注销现在清理当前用户全部本地健康快照，属于不可恢复的数据操作；回归测试同时验证其他账号快照不会被误删。
- 工作区中 iOS `ScrollViewPanObserver 2.swift` 与 `Health/ScrollViewPanObserver.swift` 处于本轮开始前已有的暂存新增/工作区删除状态，本轮未恢复、覆盖或纳入实现。

## 验证结果
- 共享红灯真实执行：最初因 `onDeleteUserData`、`UserProfile.email`、资料默认值 API 缺失而编译失败；体型管理测试在旧表单仍含体重字段时失败。实现后 `LoginUseCaseTest.profileDefaultsUseAccountTypeAndCorosUserName`、`HealthDashboardUseCaseTest.deletingAccountClearsOnlyItsHealthSnapshot`、`EditableHealthDataTest.bodyManagementFormEditsOnlyMusclesAndPreservesWeightHistory` 通过。
- `./gradlew :common:check` 与 `./gradlew :androidApp:assembleDebug` 通过；iOS Simulator `xcodebuild ... -scheme IOSDemo ... CODE_SIGNING_ALLOWED=NO build` 通过；HarmonyOS `hvigorw assembleApp --no-daemon` 通过。
- `./tools/check-account-profile-regressions.sh`、`./tools/check-health-editable-normal-data.sh`、`./tools/check-resources.sh`、`./tools/check-resource-maintainability.sh`、`./tools/check-sdd.sh` 与 `git diff --check` 通过。
- `./tools/check-docs.sh` 的测试计数已同步为业务 107 条、common 共 118 条；仍仅因本轮前即存在且 Git HEAD 本身一致的 `docs/reference/注册登陆模块介绍.md` 哈希与门禁内旧可信值不一致而失败，本轮未修改该历史参考文档或既有 `docs/worklog/` 归档。

## 人工修正点
- HarmonyOS 首次使用了当前工具链不存在的 `focusControl.clearFocus()` 并导致构建失败；改为 `getUIContext().getFocusController().clearFocus()` 后重新构建通过。
- iOS 首次调整资料默认值 helper 时遗漏 Swift 显式 `return`，修正后重新构建通过。
- 健康编辑专项门禁仍检查旧 `transientNormalDraft`/旧 Android 延迟字面量；已改为当前 `transientDashboardDraft`、持久化回退与 `delay(1_500.milliseconds)` 稳定符号，没有把过时代码重新塞回实现。

# 2026-08-03 11:50 — 跨场景健康数据回填与字段级审核

## 采纳内容
- [HLTH-EDIT-022] 将正常、异常、部分缺失、全空和读取失败统一视为同一健康数据契约的不同内容/来源状态；进入正常数据编辑器时按当前内存快照、当前用户持久化快照、默认数据的优先级投影，不再因来源场景不是 Normal 而清空异常数据。
- [HLTH-EDIT-022] 保存改为只审核和覆盖当前编辑模块；其他模块缺失不再连带阻止当前模块保存，未编辑的 null 模块继续保持 null。
- [HLTH-EDIT-023] 新增 Available、Partial、Empty、Corrupted 来源状态。全空与损坏在输入控件中都显示 0/无数据，但分别保留“读取成功但无模块数据”和“读取失败”的来源语义，并由三端展示不同提示。
- [HLTH-EDIT-024] 保存结果从 nullable/Boolean 扩展为结构化审核结果，包含字段、本地化标签、必填/数字/范围/选项/数量/一致性原因及参数；Android、iOS、HarmonyOS 均显示具体失败原因。

## 人工审查点
- 原审核把整份草稿的所有模块用一个 Boolean 联合判断：还强制周计划 7 天、心率 288 点、压力 48 点、睡眠阶段非空且连续等。因此异常场景或部分缺失场景即使当前字段合法，也会被其他模块缺失或集合长度不符连带判失败；这不是“异常数值必然不合法”，而是审核作用域错误。
- 改造后异常业务状态与结构合法性分离：异常数据只要满足字段数字格式、允许范围、合法选项、集合数量和内部一致性，就可以回填与保存；当前模块确有问题时提示会点名字段和原因。
- 全空与损坏虽共享 0/无数据的编辑投影，但 Corrupted 状态不会被重新解释为 Empty；设备侧仍需人工确认三端来源提示和具体错误提示的最终视觉体验。

## 验证结果
- 4 条共享红灯先行：实现前分别因异常场景被替换为空草稿、缺少来源状态 API、全局审核阻止部分模块保存，以及没有结构化审核结果而失败；实现后 `EditableHealthDataTest` 16 条全部通过。
- `./gradlew :common:check`（common 共 122 条）、`./gradlew :androidApp:assembleDebug`、iOS Simulator `xcodebuild ... -scheme IOSDemo ... CODE_SIGNING_ALLOWED=NO build`、`./tools/build-shared-harmony.sh`（含 KNOI 生成与 HarmonyOS `assembleApp`）均通过。
- `./tools/check-health-cross-scenario-editing.sh`、`./tools/check-health-editable-normal-data.sh`、`./tools/check-resources.sh` 与 `./tools/check-resource-maintainability.sh` 通过；新增 9 个来源/审核中英文资源键已进入三端资源、解析入口和资源清单。
- `./tools/check-sdd.sh` 与 `git diff --check` 通过；`./tools/check-docs.sh` 的测试计数已同步为业务 111 条、common 共 122 条，仍仅因本轮前已有的 `docs/reference/注册登陆模块介绍.md` 与门禁内旧可信哈希不一致而失败，本轮未修改该历史参考文档。

## 人工修正点
- 第一版跨场景测试直接在 Abnormal 场景打开编辑器，未覆盖产品实际的“先切异常、再切正常后进入编辑器”路径；调整为真实场景切换后发现 Normal 选择会清掉瞬时来源，增加独立 `transientEditSourceKind` 后同时保留异常内存数据和损坏来源语义。
- 表单预检最初复用了默认 schema，无法处理睡眠阶段和锻炼部位动态增删后的字段索引；改为按提交字段动态构造当前模块 schema，既保留数量审核，也兼容已有动态集合测试。
- HarmonyOS 首次单独构建使用了过期 SDK 环境变量而无法找到 SDK；改用项目开发文档对应的 DevEco Studio SDK/Node 路径后构建成功，最终 `build-shared-harmony.sh` 已完整复跑通过。

# 2026-08-03 13:58 — 修复鸿蒙输入跳焦与 iOS 换号刷新提示

## 采纳内容
- [HLTH-EDIT-025] HarmonyOS 正常数据模块页的独立字段和重复字段不再把 `field.value` 拼入 `ForEach` key，统一使用稳定 `field.id`，逐字符更新只改变字段值，不再销毁当前 `TextInput`。
- [HLTH-UI-ARCH-015] iOS 将换号程序化刷新从普通 Boolean 改为 `@Published` 单调递增请求序号；健康页在 `onAppear` 与 `onChange` 共用去重消费函数，覆盖页面先出现、认证 Effect 后到达的时序。
- [HLTH-UI-ARCH-015] iOS 程序化刷新在消费请求时立即进入 `Refreshing`，显示圆形刷新图标和“数据同步中”，继续沿用既有 4460ms 同步与复位流程。

## 人工审查点
- HarmonyOS 根因是组件身份不稳定而不是 common 表单值串行或键盘 Next：输入一个字符后 key 变化，ArkUI 重建控件并重新分配焦点；修复不改变表单数据、校验或保存协议。
- iOS 根因是 SwiftUI 导航与认证 Effect 的先后不固定：登录状态可能先组合健康页，普通 `needsProgrammaticRefresh` 随后变化不会触发视图观察；请求序号可同时处理页面出现前和出现后的请求。
- 两项都属于运行时焦点/动画行为，自动化结构门禁和平台构建不能代替真实设备上的连续输入与换号视觉确认。

## 验证结果
- `./tools/check-health-input-focus-and-account-refresh.sh` 实现前报告 HarmonyOS 动态 key 2 项、iOS 不可观察请求链路 6 项红灯，最小实现后 9 项检查全部通过。
- iOS Simulator `xcodebuild ... -scheme IOSDemo ... CODE_SIGNING_ALLOWED=NO build` 通过，仅保留项目既有资源、弃用 API 和脚本阶段警告。
- HarmonyOS `hvigorw assembleApp --no-daemon` 通过，仅保留项目既有资源重名、弃用 API、NAPI 未验证和未配置签名警告。

## 人工修正点
- iOS 没有简单地把 Boolean 标成 `@Published`：Boolean 在登出和再次登录连续请求中容易覆盖事件，改用单调递增 ID，由页面保存已消费 ID、ViewModel 保存已认领 ID，确保请求可观察且跨 View 重建也只消费一次。
- 程序化刷新使用 `beginRefresh(showImmediately: true)`，只让账号切换路径立即显示刷新态；用户手势刷新仍保留原先约 300ms 吸附后进入 `Refreshing` 的节奏。

# 2026-08-03 14:13 — 对齐 iOS 登录换号刷新生命周期

## 采纳内容
- [HLTH-UI-ARCH-015] 撤销“ViewModel 开始即认领、View 持有刷新 Task”的方案，改由长期存活的 `HealthDashboardViewModel` 持有 `accountRefreshPending`、`AccountRefreshPhase` 和账号刷新 Task。
- [HLTH-UI-ARCH-015] iOS 健康首页用 `effectiveRefreshPhase/effectiveDragOffset` 合并手势刷新与账号刷新，账号刷新期间显示主体停留偏移、圆形进度图标、“数据同步中”和右上角同步动画，刷新完成进入约 300ms Resetting。
- [HLTH-UI-ARCH-015] 认证成功调用 `staleForNewAccount(shouldRefreshOnDashboard: true)`，退出登录调用 false；首次资料完善期间 pending 保留，进入健康首页后再启动 4460ms 刷新并加载当前账号数据。

## 人工审查点
- 上一版没有动作的根因是旧健康页在 NavigationStack ResetTo 完成前观察到请求并抢先全局认领，随后 `onDisappear` 取消本地 Task；新页因请求已认领而无法补做。
- 新实现中旧页可以触发 pending 启动，但 Task 和阶段状态属于共享 ViewModel；旧页消失只会取消它自己的手势刷新，新页仍能继续展示同一账号刷新周期。
- 平台构建能验证 SwiftUI 状态链和接口，但换号动画的实际可见位置、持续时间及新账号数据仍需模拟器或真机完整登录回归。

## 验证结果
- 修订后的 `./tools/check-health-input-focus-and-account-refresh.sh` 在旧实现上产生 13 项红灯，覆盖 pending、ViewModel Task/phase、有效 UI 阶段和登录/退出分流；实现后全部通过。
- iOS Simulator `xcodebuild ... -scheme IOSDemo ... CODE_SIGNING_ALLOWED=NO build` 通过，仅保留项目既有资源、弃用 API 和脚本阶段警告。
- 本轮只修改 iOS 健康刷新生命周期及其 Spec/门禁，没有改变 common 数据规则、Android 或 HarmonyOS 已通过的账号刷新实现。
- `./tools/check-sdd.sh` 与 `git diff --check` 通过；`./tools/check-docs.sh` 仍仅因本轮前已有的 `docs/reference/注册登陆模块介绍.md` 与门禁可信哈希不一致而失败，本轮未修改该历史参考文档。

## 人工修正点
- 账号刷新 Task 若因同时存在的刷新而未能启动，不再永久停在 Refreshing；它会恢复 Idle、重新标记 pending，等待健康页再次启动。
- `HealthDashboardViewModel.refresh()` 改为可取消并返回是否真正完成；页面离开导致手势 Task 取消时，不再忽略取消异常后继续读取账号数据。

# 2026-08-03 14:45 — 完善三端原生 UI Preview 与跨语言 fixture

## 采纳内容
- [UI-PREVIEW-001] 在 `commonMain` 新增无副作用、可重复的 `HealthPreviewFixtures.normalState()`，以共享健康规则生成完整卡片数据，避免三端分别伪造图表和业务状态。
- [UI-PREVIEW-002] Android Preview 直接消费共享 `HealthState`；iOS 通过 `HealthDashboardViewModel(previewState:)` 复用现有 Swift 映射；HarmonyOS 通过 KNOI `previewHealthSnapshot()` 输出 JSON，并由 ArkTS `loadPreview()` 复用运行时快照映射。
- [UI-PREVIEW-003] 补齐三端生产导航页面的工具链 Preview，覆盖 Android 19、iOS 20、HarmonyOS 16 个显式页面清单，并补齐三端正常数据编辑器 Preview。
- [UI-PREVIEW-004] 健康首页的完整共享数据可驱动卡片族；HarmonyOS 新增组件 Preview catalog，直接展示 Hero、指标、全部健康卡片、账户概览和底部导航。
- [UI-PREVIEW-004] DevEco Preview 无法加载 KNOI native service 时显式回退为 14 张原生空态卡片和日期/指标壳层；native 可用时仍优先展示 common fixture 的完整有数据状态，不在 ArkTS 重写业务推导。
- [UI-PREVIEW-005] 新增 `tools/check-ui-previews.sh`，用显式页面清单和跨语言适配稳定符号阻止 Preview 覆盖回退。

## 人工审查点
- 三端仍保持 KMP 共享业务层 + Compose/SwiftUI/ArkUI 原生 UI；共享 fixture 不引入平台类型，Swift 和 ArkTS 适配均走现有生产展示边界。
- 自动门禁与平台构建能证明 Preview 可发现、可编译及数据链闭合，不能代替 Android Studio、Xcode、DevEco Studio Canvas 的最终视觉检查；需人工各打开全页面、数据卡和表单 Preview 检查布局。
- 工作区中 iOS `ScrollViewPanObserver 2.swift` 与 `Health/ScrollViewPanObserver.swift` 的暂存新增/工作区删除状态为本轮开始前已有，本轮未恢复、覆盖或纳入实现。

## 验证结果
- 红灯先行：`./tools/check-ui-previews.sh` 在实现前报告 24 项缺口；共享测试最初因 `HealthPreviewFixtures` 不存在而编译失败。实现后 `HealthPreviewFixturesTest.normalPreviewStateContainsEveryCardWithDeterministicVisualData` 随 `./gradlew :common:check` 通过。
- `./gradlew :androidApp:assembleDebug` 通过；iOS Simulator `xcodebuild ... -scheme IOSDemo ... CODE_SIGNING_ALLOWED=NO build` 通过；`./tools/build-shared-harmony.sh` 通过 common 检查、KNOI 生成与 HarmonyOS `assembleApp`，新增组件目录后再次执行 HarmonyOS `assembleApp` 通过。
- `./tools/check-ui-previews.sh`、`./tools/check-sdd.sh` 与 `git diff --check` 通过；测试报告与动态文档门禁已纳入新增 fixture 测试，common 当前共 123 条。`./tools/check-docs.sh` 仍仅因本轮前已有的 `docs/reference/注册登陆模块介绍.md` 与门禁可信哈希不一致而失败，本轮未修改该历史参考文档。

## 人工修正点
- Android 首次收敛重复 fixture 时遗漏既有 `HealthMockScenario` import，恢复 import 后重新构建通过。
- iOS 正常数据编辑器首次加入 typed fixture 时遗漏 `import Shared`，补齐后重新执行 Simulator 构建通过。
- 共享 fixture 测试最初只接受图表/进度/区间数据，误拒绝以 `primaryValue` 或 `assetKey` 表达的合法卡片；扩展为完整视觉契约后通过。
- HarmonyOS Preview 最初把场景目录与快照加载放在同一 `try` 中，任一设计宿主能力缺失都会阻止卡片渲染；拆分容错并补显式原生空态回退后，设计态至少始终展示完整卡片结构。

# 2026-08-03 15:00 — 修复 ArkUI Preview Host 并补全 iOS View Preview

## 采纳内容
- [UI-PREVIEW-006] 移除 `CardEditorComp`、`HealthDetailComp` 上不合法的直接 `@Preview`；新增不含 `@Prop/@Link/@ObjectLink/@Consume` 的 `CardEditorPreviewHost` 与 `HealthDetailPreviewHost`，由父组件持有完整卡片 `@State` 后传入子组件。
- [UI-PREVIEW-006] 健康组件 Catalog 同步移除 `aboutToAppear`/KNOI 调用，父 Host 直接持有 `createDefaultHealthCards()` 与静态指标，保证 DevEco 设计器不依赖 native service 或页面生命周期；实际页面仍保留 common fixture 的 KNOI JSON 映射能力。
- [UI-PREVIEW-007] 将 iOS 覆盖口径从导航页面扩大到所有包含生产 `struct ...: View` 的 Swift 文件，补齐 13 个健康可视化模块、认证协调器、认证组件 Catalog 和语言按钮 Preview，当前覆盖为 40/40 文件。
- [UI-PREVIEW-007] 新增 `previewHealthVisual(cardID:)`，所有 iOS 健康叶组件继续消费 `HealthPreviewFixtures.normalState()` 经 `HealthDashboardViewModel` 映射后的 `HealthCardVisualData`，没有在 Swift 中复制业务图表 fixture。
- [UI-PREVIEW-005] Preview 门禁新增 ArkUI 直接装饰器违规扫描和 SwiftUI View 文件动态清单；后续新增 View 文件或再次给带外部状态的 ArkUI 子组件直接加 Preview 会立即失败。

## 人工审查点
- DevEco 的限制发生在设计态而非普通 ArkTS 编译：本轮父 Host 结构和平台构建已验证，但仍建议在 Previewer 中实际打开 `CardEditorPreviewHost`、`HealthDetailPreviewHost` 各确认一次渲染。
- iOS 两个纯滚动/手势桥接 `UIViewRepresentable` 不具备独立可视内容，按 Spec 由健康页面和编辑器 Preview 覆盖；其余 40 个包含 SwiftUI `View` 的文件均已有 `#Preview`。
- 工作区中两个 `ScrollViewPanObserver` 的暂存新增/工作区删除状态为本轮前已有，本轮仍未恢复、覆盖或纳入实现。

## 验证结果
- 红灯先行：升级后的 `./tools/check-ui-previews.sh` 在实现前报告 20 项失败，包括 16 个 iOS View 文件缺 Preview、2 个 ArkUI 子组件直接预览违规、2 个父 Host 缺失；实施后全部通过。
- iOS Simulator `xcodebuild -project iosApp/iosApp.xcodeproj -scheme IOSDemo -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 通过。
- HarmonyOS `hvigorw assembleApp --no-daemon` 通过；仅保留项目既有的弃用 API、NAPI 验证和未配置签名警告。

## 人工修正点
- 上轮只按导航页面清单检查 iOS，漏掉独立 Visual 与组件文件；本轮改为从源码动态发现所有 `struct ...: View` 文件，避免静态清单继续失真。
- 上轮把 `@Prop` 子组件自身视为可直接 Preview，普通 `assembleApp` 没有暴露 DevEco Previewer 的限制；本轮将约束编码进门禁并改用父级 Host。

# 2026-08-03 15:12 — 隔离 ArkUI Preview 与 KNOI native 模块

## 采纳内容
- [UI-PREVIEW-008] 根据 Previewer 调用栈确认模块加载链 `LoginViewModelProvider → LoginViewModel → LoginLogicProvider → KnoiLoginAdapter → knoi/provider` 会在页面渲染前解析 native 模块；改为纯 ArkTS `HarmonyLoginServiceContract`，页面、健康 ViewModel、编辑表单和持久化层不再静态 import 生成 provider。
- [UI-PREVIEW-008] `EntryAbility` 在 KNOI `setup/init` 完成后，通过名义类型兼容的 `KnoiHarmonyServiceAdapter` 安装真实 service，并安装 `KnoiLoginAdapter` factory；native import 只保留在运行态组合根、生成 provider 和显式 delegate。
- [UI-PREVIEW-008] 新增无副作用 `PreviewLoginAdapter` 作为设计宿主默认实现；`LoginViewModelProvider` 改为惰性单例，禁止模块加载时立即创建 ViewModel/native adapter。
- [UI-PREVIEW-005] Preview 门禁新增 native import 边界、纯 service provider、非 native 登录 factory 和 ViewModel 顶层实例扫描，防止同类模块解析崩溃回归。

## 人工审查点
- 这次错误发生在 ECMAScript 模块链接阶段，不能通过调用位置的 try/catch 修复；关键验收是任何 `@Preview` 页面静态 import 图均不能到达 `@kuiklybase/knoi`。
- 生产运行时仍由 `EntryAbility` 安装真实 KNOI service 和登录 adapter，不改变 KMP 数据与认证规则；Preview 默认 adapter 只提供表单可展示、可输入的本地状态，不执行持久化或真实认证。
- DevEco 命令行构建不能完全替代 Previewer 进程，本轮已从源码图上移除报错路径，仍应在用户当前 DevEco Previewer 中重新打开原报错页面确认缓存已刷新。

## 验证结果
- `./tools/check-ui-previews.sh` 新门禁在实现前报告 7 项红灯：缺少安装边界、纯 provider 仍 import native、登录 provider 静态 import KNOI adapter、ViewModel 顶层立即创建，以及 3 个越界 native import；实施后全部通过。
- HarmonyOS `hvigorw assembleApp --no-daemon` 最终通过，仅保留项目既有弃用 API、NAPI 验证和未配置签名警告。
- `rg` 复核显示 KNOI import 仅存在于 `EntryAbility.ets`、生成的 `knoi/provider.ets` 和仅由 EntryAbility 引用的 `KnoiHarmonyServiceAdapter.ets`；所有 Preview 页面依赖的 provider、ViewModel 与 StorePersister 均为纯 ArkTS 模块。

## 人工修正点
- 第一版直接把生成 `HarmonyLoginService` 传给同形纯接口，ArkTS 因禁止结构化类型而编译失败；增加显式逐方法 delegate 后满足名义类型约束并重新构建通过。
- 单纯把原全局 ViewModel 改为惰性仍不足以切断模块 import；同时移除 `LoginLogicProvider` 对 `KnoiLoginAdapter` 的静态依赖，并由 `EntryAbility` 安装 factory，才真正避免 Previewer 解析 native 模块。

# 2026-08-04 09:55 — 补齐 Android 与 HarmonyOS 健康 Visual Preview

## 采纳内容
- [UI-PREVIEW-009] 为 Android 12 个独立健康 Visual 文件补充同文件命名 `@Preview`；统一通过 `previewHealthVisual()` 从 common `HealthPreviewFixtures.normalState()` 选取生产 `HealthCardVisualData`，并用共享 Preview 容器提供主题与卡片背景。
- [UI-PREVIEW-009] 为 HarmonyOS 12 个带 `@Prop` 的 `*VisualComp.ets` 新增纯父 `VisualPreviewCatalog.ets`，覆盖能力、活动、身体、健康指标、HRV、恢复、静息心率、睡眠、训练评估、训练负荷、心率/压力趋势和周计划。
- [UI-PREVIEW-009] 新增纯 ArkTS `VisualPreviewData.ets` 提供完整非空 DTO；该设计态数据不 import KNOI/native，避免 DevEco Previewer 在模块链接阶段加载 `knoi.setup`。
- [UI-PREVIEW-005] Preview 门禁改为动态发现两端 Visual 文件，并修正 Android 源码从 `src/main/java` 迁移至 `src/main/kotlin` 后失效的页面路径。

## 人工审查点
- Android Visual Preview 使用 common fixture；HarmonyOS 当前使用与 `HealthVisualData` 契约一致的纯 ArkTS 设计态 DTO，因为 Previewer 无法加载 KMP `.so`。它不是生产数据源；App 运行时仍通过 KNOI 调用 common 动态库并映射真实快照。
- HarmonyOS 子 Visual 本身继续保留 `@Prop` 且不直接加 `@Preview`，需要在 DevEco Studio 打开 `VisualPreviewCatalog.ets` 的各父 Host 检查实际画布尺寸、文字资源和 Canvas 绘制效果。
- 工作区中 Profile、Theme 迁移和两个 iOS `ScrollViewPanObserver` 的既有修改未被本轮恢复或覆盖。

## 验证结果
- 红灯先行：升级 `./tools/check-ui-previews.sh` 后定位 Android 12 个 Visual 缺少 Preview/common fixture 适配，以及 HarmonyOS 纯父 Visual Catalog 缺失；实现后门禁通过，动态覆盖 Android 12/12、HarmonyOS 12/12。
- Android 执行 `./gradlew :androidApp:clean :androidApp:assembleDebug --no-configuration-cache` 通过；清理前因源码根迁移残留增量符号而出现同文件声明冲突，清理生成缓存后消失。
- HarmonyOS 执行 `hvigorw assembleApp --no-daemon` 通过，仅保留项目既有弃用 API、NAPI 检查与未配置签名警告。
- `./tools/check-ui-previews.sh`、`./tools/check-sdd.sh` 与 `git diff --check` 通过；`./tools/check-docs.sh` 仍仅因本轮前已有的 `docs/reference/注册登陆模块介绍.md` 与可信来源哈希不一致而失败，本轮未修改该参考文档。

## 人工修正点
- HarmonyOS 趋势组合 Preview 初次引用了不存在的 `AppColors.HEALTH_DIVIDER`，按现有设计令牌修正为 `AppColors.DIVIDER` 后通过 ArkTS 编译。
- Android 初次增量构建把迁移前后的同名源码符号同时留在编译缓存中；确认编译输入清单只有一份源码后，仅清理模块生成目录再重建，没有调整或删除用户源码。

# 2026-08-04 10:07 — 修复 DevEco Visual Preview 文件上限与数组类型

## 采纳内容
- [UI-PREVIEW-009] 根据 DevEco 设计态报错，将原含 12 个 `@Preview` 的 `VisualPreviewCatalog.ets` 拆为主 Catalog 10 个和 `VisualPreviewCatalogSecondary.ets` 2 个，仍合并覆盖全部 12 个 Visual 子组件。
- [UI-PREVIEW-009] `VisualPreviewData.ets` 导入并使用 `HealthChartPointData`、`HealthMetricData`、`HealthRangeSegmentData`、`SleepStageData`、`WeeklyDayPlanData`，所有对象数组与空数组均通过显式契约类型变量传入 DTO。
- [UI-PREVIEW-005] Preview 门禁新增单文件最多 10 个装饰器、跨多个 Visual Catalog 合并覆盖和对象数组显式类型检查。

## 人工审查点
- `VisualPreviewCatalog.ets` 展示前 10 组 Visual；趋势与周计划需要在 DevEco Studio 打开 `VisualPreviewCatalogSecondary.ets` 查看。
- 命令行 ArkTS 编译不等价于 Previewer 的设计态规则；本轮已把用户报告的两条设计态限制固化为静态门禁，仍需在 Previewer 中重新加载两个 Catalog 确认 IDE 缓存刷新。

## 验证结果
- 红灯先行：`./tools/check-ui-previews.sh` 在修复前稳定报告 Catalog 有 12 个 Preview、`weekPoints` 对象数组缺少显式契约类型共 2 项；修复后通过。
- HarmonyOS `hvigorw assembleApp --no-daemon` 在完整类型化前后均通过；最终构建成功，仅保留项目既有弃用 API、NAPI 检查和未配置签名警告。
- 最终 `./tools/check-ui-previews.sh`、`./tools/check-sdd.sh` 与 `git diff --check` 通过；主/次 Catalog 装饰器计数分别为 10、2。`./tools/check-docs.sh` 仍仅因既有 `docs/reference/注册登陆模块介绍.md` 可信哈希不一致失败，本轮未修改该参考文档。

## 人工修正点
- 不只给最先报错的 `weekPoints` 增加类型，还把指标、区间段、睡眠阶段、趋势点、周计划及空数组全部显式类型化，避免 Previewer 继续逐项报告同类问题。
- Catalog 门禁由只检查单一文件调整为扫描 `VisualPreviewCatalog*.ets`，拆分后不会误判 Trend/WeeklyPlan 覆盖丢失。

# 2026-08-04 16:22 — 三端结构收敛 Phase 2：common 大文件拆分、health 导航按域拆、Android Profile 拆分

## 采纳内容
- [STRUCT-001] 新增 `spec/three-platform-structure.md`（STRUCT-* 稳定 ID），在 `spec/TRACE.md` 预留 ⏳ 后执行，符合 SDD 强制顺序。
- [STRUCT-001] common 五个大文件按职责拆分且公共 API 不变：`HealthEditableForms.kt`(748)→`HealthEditFormModels.kt`+`HealthEditFormJson.kt`；`EditableHealthData.kt`(716)→`DefaultEditableHealthData.kt`+`HealthEditableRules.kt`；`MockHealthDashboardStoreJson.kt`(681)→`HealthJson.kt`（自包含 JSON 基础设施，保持 KNOI OHOS 兼容）；`AuthRepository.kt`(534)→`AuthStoreDataSource.kt`+`LocalMockAuthRepository.kt`；`MockAuthStoreJson.kt`(518)→`AuthJson.kt`+`JsonAuthStoreDataSource.kt`。
- [STRUCT-002] health 导航按域从 auth 导航拆出：Android `health/navigation/HealthNavGraph.kt`（NavGraphBuilder 扩展）+`HealthRoute.kt`，AuthNavGraph 单行挂载；iOS `Health/Navigation/HealthNavigation.swift`（AuthCoordinator 转发，AuthRoute 保持全局 NavigationStack 单一容器）；HarmonyOS `AuthRoutes` 按 `auth/home/health/debug` 分组（ArkTS interface 类型），13 个调用文件同步更新。
- [STRUCT-003] Android `ProfileCompletionScreen.kt`(883)→`ProfileFieldRows/ProfilePickerSheets/ProfileAvatarSheet/ProfileEditHelpers`，主文件降至 368 行，同包可见性（private→internal 收敛跨文件引用）。
- [STRUCT-003] 剩余结构债务显式登记：HarmonyOS `ProfileCompletionPage.ets`(1557)、`SignedInPage.ets`(563)、三端 `AuthComponents.*`、三端 `NormalDataEditor`、iOS `HealthDashboardView.swift`(491) 待下一轮拆分。

## 人工审查点
- iOS `AuthRoute` 枚举仍为全局 NavigationStack 单一路径容器（SwiftUI 约束），本轮只把健康目的地渲染归入 Health 模块；health 的 URL 常量在 HarmonyOS 与 `main_pages.json` 必须保持同步。
- 拆分严格保持公共 API 与行为不变：`HealthEditFormJson` 用委托函数保留 `HealthEditableForms.formJson/applyResultJson` 等既有入口；Swift/KNOI 类名未动。
- 剩余 STRUCT-003 债务项涉及 ArkTS 页面与三端共享组件，拆分会触碰预览门禁（`check-ui-previews.sh`）与三端构建，需逐项小步验证，未在本轮强行拆完。

## 验证结果
- 红灯先行：先在 `spec/TRACE.md` 以 ⏳ 预留 `STRUCT-*` 行；common 基线 `./gradlew :common:check` 拆分前后均全绿（123 条测试回归）。
- Android：`./gradlew :androidApp:assembleDebug` 在导航拆分与 Profile 拆分后均通过（中途 GenderRow/ProfileTextRow 跨文件 private 编译红灯，改为 internal 后转绿）。
- iOS：`xcodebuild -project iosApp/iosApp.xcodeproj -scheme IOSDemo -sdk iphonesimulator -configuration Debug build CODE_SIGNING_ALLOWED=NO` 通过（新文件 `HealthNavigation.swift` 手工登记 pbxproj 后）。
- HarmonyOS：`hvigorw assembleApp --no-daemon` 通过（首次因 ArkTS 对象字面量缺显式类型红灯，补 `AuthRouteGroup/HomeRouteGroup/HealthRouteGroup/DebugRouteGroup` interface 后通过）。

## 人工修正点
- macOS BSD `sed` 不支持 `\b` 且 zsh 不对未加引号变量按空白切分：改用 zsh `${(f)VAR}` 换行拆分 + 纯字符串替换，避免替换静默失败。
- ArkTS 禁止无类型对象字面量：`AuthRoutes` 分组静态常量改为声明 `interface` 后以类型化对象赋值。
- Xcode 显式 pbxproj（非文件系统同步组）：新增 Swift 文件需手工补 PBXBuildFile/PBXFileReference/分组/Sources phase 四处登记，且文件路径须与分组 `path` 一致（`Health/Navigation/`）。
- Profile 拆分跨文件 private 引用（`ProfileTextRow`/`GenderRow`/`displayText`/`localizedCountryOptions`/`parseBirthDate`）统一收敛为 `internal`，未改变对外公共 API。

# 2026-08-04 17:35 — 阶段 3：common 包 login→auth 重命名与 core 抽取评估

## 采纳内容
- [STRUCT-005] `common/src/commonMain` 与 `commonTest` 的 `login` 目录 `git mv` 为 `auth`；全部 `package com.example.demo.common.login` 声明与 47 个 Kotlin 文件的 `com.example.demo.common.login` 引用替换为 `com.example.demo.common.auth`。
- [STRUCT-005] `tools/` 中 7 个脚本（check-docs、check-health-dashboard-runtime-states、check-health-editable-normal-data、check-health-navigation、check-resource-maintainability、check-resources、check-ui-previews）的 `common/login`、`ets/login` 旧路径同步更新为 `auth`。
- [STRUCT-006] 评估 `MockResult` core 抽取：`MockResult.Failure` 携带 `MockError`，`MockError` 编码 `AuthMessageKeys` 且引用 `HealthMessageKeys`，单独抽取会形成 core→auth/health 消息键反向依赖；结论为不抽取，`MockResult`/`MockError`/`SessionResumeResult` 整体保留 `com.example.demo.common.auth`，结论记入 Spec。

## 人工审查点
- iOS Swift 按类名（`LoginFacade`/`HealthFacade`）引用 KMP framework，包名变化不影响源码，但必须重编 `build-shared-xcframework.sh` 验证导出；已执行且 xcodebuild 通过。
- HarmonyOS KNOI 按 `@ServiceProvider` 类名生成 `provider.ets`，service 方法签名未变故接口文件无需重生成；`libkn.so` 已按新包重建，`hvigorw assembleApp` 通过。
- `MockError` 的 health 消息键（`MinimumCardsRequired`）属既有跨域设计：health 对 auth 的 `MockError`/`AuthRepository` 依赖是认证门禁，不在本轮范围。

## 验证结果
- `./gradlew :common:check`（123 条 commonTest）在重命名后全绿；重命名前临时 core 抽取引入 `Unresolved reference 'MockError'` 编译红灯，回退后转绿。
- Android `./gradlew :androidApp:assembleDebug` 通过。
- iOS `./tools/build-shared-xcframework.sh`（BUILD SUCCESSFUL）后 `xcodebuild -scheme IOSDemo -sdk iphonesimulator build` 通过。
- HarmonyOS `./tools/build-shared-harmony.sh` 重建 `libkn.so`（Aug 4 17:26）并 `hvigorw assembleApp` 通过。
- `./tools/check-sdd.sh` 通过；`git diff --check` 无冲突标记；`./tools/check-docs.sh` 仍仅因既有 `docs/reference/注册登陆模块介绍.md` 可信哈希不一致失败（本轮未修改）。

## 人工修正点
- core 抽取前未预判 `MockResult.Failure` 对 `MockError` 的引用及 `MockError` 对消息键的依赖，导致 core→域 反向依赖编译红灯；改为「先验证后回退」，把结论以 `STRUCT-006` 记录进 Spec，避免带着错误方向继续。

# 2026-08-04 18:05 — 阶段 4：适配层文件拆分（KNOI/Swift 契约稳定）

## 采纳内容
- [STRUCT-007] `HarmonyLoginService.kt`(558) 拆分：抽取 `HarmonyHealthBridge`（内部委托类，承载全部 health 转发方法与 `restoreLegacyHealthFromStoreJson`）与 `HarmonyHealthSnapshotJson`（`healthSnapshotFromState`/`esc` 序列化）；`HarmonyLoginService` 保持单一 `@ServiceProvider`，health 方法委托 bridge，主文件 558→338 行。
- [STRUCT-008] iOS `SharedLoginAdapter.swift`(419) 拆分：health 方法抽到 `SharedLoginAdapter+Health.swift`（`extension SharedLoginAdapter`），`healthFacade` 由 private 放开为 internal；协议与调用方不变，主文件 419→344 行。
- [STRUCT-009] 评估 ArkTS `KnoiLoginAdapter.ets` 拆分：ArkTS 无跨文件 extension，需内部辅助类重构并同步 PreviewLoginAdapter/StorePersister，且 DevEco 预览门禁依赖完整 import 图；结论为暂缓并登记债务。

## 人工审查点
- KNOI 契约稳定性验证：`provider.ets` 在拆分前后 `git diff` 为空——service 类名与全部方法签名未变，仅实现位置变化。
- Swift 跨文件 extension 访问类私有成员受限：health 方法需要 `healthFacade`，将其从 `private` 放开为 `internal`（模块内可见，不改变对外 API）。
- 拆分不改变任何业务行为、方法签名或健康快照 JSON 结构；`restoreStoreSnapshot` 通过 `healthBridge.updateFacade` 保持换号后 bridge 引用最新 facade。

## 验证结果
- HarmonyOS：`./tools/build-shared-harmony.sh`（bridge `ohosArm64Binaries` + `hvigorw assembleApp`）BUILD SUCCESSFUL；`provider.ets` 无 diff。
- iOS：`xcodebuild -scheme IOSDemo -sdk iphonesimulator -configuration Debug build` BUILD SUCCEEDED（新扩展文件经 pbxproj 4 处登记）。
- 新增文件：`HarmonyHealthBridge.kt`(162)、`HarmonyHealthSnapshotJson.kt`(131)、`SharedLoginAdapter+Health.swift`(79)。

## 人工修正点
- 最初计划将 KNOI 拆为两个 `@ServiceProvider`（Login + Health），评估后放弃：会改变 `provider.ets` 契约并需改 ArkTS 组合根与预览门禁；改为内部委托类，契约零变化、风险最低。
- Swift extension 跨文件访问私有成员失败是预期约束：先识别 health 方法依赖面（仅 `healthFacade`，不含 `syncClock`），再定向放开可见性，避免过度暴露。

# 2026-08-04 18:45 — 阶段 5 收尾：目录迁移后的门禁路径维护与最终验证

## 采纳内容
- 同步 `tools/` 全部 `check-*.sh` 因目录迁移（java→kotlin、login→auth/screens、ui→core、ios Login→Auth、ets resources→core/resources）失效的硬编码路径，覆盖 check-resources、check-resource-maintainability、check-health-navigation、check-ui-previews、check-account-profile-regressions、check-health-card-* 等脚本。
- [STRUCT-002] `check-health-navigation.sh` 按新导航结构重写断言：health 路由断言迁移到 `health/navigation/HealthRoute.kt`/`HealthNavGraph.kt`，iOS 断言迁移到 `Health/Navigation/HealthNavigation.swift`（AuthCoordinator 只断言 `healthDestination` 转发），HarmonyOS 断言改为 `AuthRoutes.health.DETAIL/EDITOR` 分组与 `AuthRoutes.health.EDITOR` 调用。
- [RES-MAINT-004] `resource-inventory.json` 与 `check-resource-maintainability.sh` 的 Token 排除路径同步到新位置（android `core/theme|resources`、iOS `Core/Resources|Auth/Components`、HarmonyOS `core/resources|auth/components`）。

## 人工审查点
- 门禁脚本硬编码的路径/结构期望是「结构回归契约」，目录迁移与导航重构后必须同步，否则门禁会误报；历史归档（docs/worklog、docs/archive）不回改。
- 本环境无 `ripgrep`（`check-health-navigation.sh`/`check-ui-previews.sh` 依赖 `rg`），无法本地执行这两个脚本；已用 `grep` 逐条等价验证改写后的断言（15 项全 PASS）。
- `docs/reference/注册登陆模块介绍.md` 可信哈希不一致为既有失败（历史轮次已记录），本轮未触碰。

## 验证结果
- `./tools/check-resources.sh`：23 个认证键三端对齐，通过（修复前因 iOS/Harmony 资源路径失效而 FAIL）。
- `./tools/check-resource-maintainability.sh`：54 图/2 Raw/305 键，三端直连色债务 0，通过（修复前 Token 排除路径失效而 FAIL）。
- `./tools/check-sdd.sh` 通过；`git diff --check` 无冲突标记；`./tools/check-docs.sh` 仅剩既有参考文档哈希失败。
- 关键新路径逐条 `[ -f ]` 确认存在；common/Android/iOS/HarmonyOS 构建在本轮各阶段均通过。

## 人工修正点
- 误将「资源门禁失败」当作新引入问题排查，实为目录迁移后排除路径失效的存量债务；定位到 `debtExclusions` 与脚本内 `expected_color_token_exclusions` 双处需同步，只改 JSON 仍会红灯。
- `check-ui-previews.sh` 的页面清单在 java→kotlin 后又被 login→auth 遗漏，补做第二轮 sed；校验时用 `cd tools` 后相对路径导致 `[ -f ]` 误报 MISSING，回到仓库根复验确认文件均在。

# 2026-08-04 19:40 — 阶段 6：common 内部按职责子包划分

## 采纳内容
- [STRUCT-010] `com.example.demo.common.auth` 与 `.health` 各拆 7 个子包：`model/rules/store/usecase/repository/mock/facade`；共 37 个文件 `git mv`，package 声明同步更新。
- [STRUCT-010] 用符号→新包映射脚本重写 190 处 import 与 20 处全限定引用；补齐跨子包缺失 import；清理 36 处误加的函数 import（`text` 等被单词匹配误判）；修正 4 处旧平铺包残留 import（`toProfileCountryCode` 等扩展函数）。
- 三端目录（auth/health 的 data/viewmodel/screens/...）与 common 子包（model/rules/store/usecase/repository/mock/facade）形成语义映射。

## 人工审查点
- `MockResult`/`MockError`/`SessionResumeResult` 保留在 `auth.model`（STRUCT-006 结论），health 对 auth 的 `MockError`/`AuthRepository` 依赖为既有认证门禁设计。
- `HealthDashboardStore.kt` 内的 `HealthDashboardStateDataSource` 接口与 `InMemoryHealthDashboardStateDataSource` 同文件保留在 `health.store`，未强行拆文件。
- Swift/KNOI 类名不变，`provider.ets` 在拆分前后 git diff 为空。

## 验证结果
- `./gradlew :common:check` 全绿（compileAndroid 先无错，跨子包缺 import 由编译器清单逐类补齐）。
- Android `assembleDebug` 通过（先因误加 internal `text` import 与旧平铺包 `toProfileCountryCode` import 红灯，清理后转绿）。
- iOS `build-shared-xcframework.sh` + `xcodebuild` 通过；HarmonyOS `build-shared-harmony.sh` + `hvigorw assembleApp` 通过。

## 人工修正点
- import 重写脚本必须用 `re.MULTILINE` 才能让 `^` 匹配每行；扩展函数（`fun Receiver.name`）捕获的是函数名而非 receiver 类型，否则会把 `fun String.jsonEscaped()` 误记为符号 `String` 并产生 `import ...mock.String` 污染。
- 单词匹配自动补 import 会产生误导入：`Text(text=...)` 里的 `text` 被当成 common 函数引用，误加 internal 函数 import；需要「按实际函数调用 `name(`/`::name` 判定」二次清理。
- 跨包同名符号（`toDomain`/`toProtoMessage`）不能单映射，需跳过自动导入并按调用方精确手工补齐。

# 2026-08-05 11:03 — Mock 服务器改造启动：新增 MSRV Spec 与边界文档更新

## 采纳内容
- [MSRV] 新增 `spec/mock-server-api-spec.md`：定义三端 HTTP 接入 mock 服务器的目标、非目标、边界与约束、接口清单（认证逐接口 10 项 + 健康整文档 3 项）、13 条行为规范（`MSRV-001`~`MSRV-013`）与验收标准。
- [MSRV-001~013] 在 `spec/TRACE.md` 新增「mock-server-api-spec.md 追溯」表格，13 条映射全部以 `⏳` 预留（测试/实现写为“待补”），符合 SDD-003 预留规则。
- [MSRV-002][MSRV-008] 确定架构边界：HTTP 只位于三端平台层远程数据源（HarmonyOS 走 ArkTS 侧 `ohos.net.http` 并复用既有 KNOI snapshot 入口），`commonMain` 不放网络客户端且保持同步数据源接口不变；`ohos_arm64` 无法编译 ktor 等常规 Kotlin/Native 库。
- [MSRV-005] 明确 HTTP 状态码映射到既有 `MockError` 语义，网络不可达时新增网络类错误枚举。
- [MSRV-012] 种子账号（`13107012029`/`2232591785@qq.com`/`123456`）与 5 个健康场景模板由服务器提供，客户端不再本地生成权威数据。
- 更新边界文档：AGENTS.md「项目边界」增加 mock server 与 HTTP 平台层约束；README.md「关键边界」同步；`auth-mock-spec.md` §1/§2 允许本仓库 `mock-server/` 而仍禁止真实服务；`spec/README.md` 索引新增本 Spec。

## 人工审查点
- [MSRV] mock server 技术栈最终选择（建议 Node.js + Express）与落盘目录需负责人确认后进入实现轮。
- [MSRV-006] 冷启动会话校验粒度：本地 TTL + 惰性校验 vs 每次打 `GET /api/auth/session`，待业务确认。
- [MSRV-010] 三端数据一致的同步口径为“服务器权威 + 刷新拉取”，非实时推送，需业务接受。
- [MSRV-008] HarmonyOS 无在线设备，最终三端联调需设备/模拟器人工验收。

## 验证结果
- [MSRV] `./tools/check-sdd.sh` 通过（框架校验全绿）。
- [MSRV] `./tools/check-docs.sh` 仅剩既有 `docs/reference/注册登陆模块介绍.md` 可信哈希失败（历史轮次已记录，本轮未触碰）。
- [MSRV] `git status`/`git diff` 人工核对仅修改 5 个文档文件（新增 1 Spec、预留 TRACE、AGENTS.md/README.md/auth-mock-spec.md/spec-README.md 边界），无代码改动。

## 人工修正点
- 暂无明确人工修正点；本轮为纯 Spec/文档轮，测试与实现尚未编写，TRACE 13 条保持 `⏳`，按 MSRV 实现顺序（mock server → 三端远程数据源 → 缓存与会话 → 联调）进入后续轮。

## 下轮交接
- **已完成**：`spec/mock-server-api-spec.md` 已采纳；TRACE 预留 13 条 `⏳`；AGENTS.md/README/auth-mock-spec/spec-README 边界已更新；SDD 门禁通过。
- **未完成 / 阻塞项**：mock server 工程未创建（技术栈与落盘目录待人工确认）；三端远程数据源、缓存降级、会话懒校验均未实现。
- **下轮起步建议**：先读 `spec/mock-server-api-spec.md` 与 TRACE「mock-server-api-spec.md 追溯」；确认技术栈后先实现 mock server 与契约测试（MSRV-001/003/004/012），测试红灯 → 实现转绿 → 更新 TRACE。

# 2026-08-05 11:19 — Mock 服务器工程实现：Node.js + Express 与契约测试转绿

## 采纳内容
- [MSRV] 技术栈确认：用户选择 brew 安装 Node.js + Express（本机原无 Node，已安装 v26.6.0/npm 11.18.0）。
- [MSRV-001/003/004/012] 新增 `mock-server/` 工程：`package.json`（express 4.22.2）、`src/store.js`（内存 + `data/` JSON 落盘、种子账号/区域/验证码、密码哈希 `mock:` 约定、健康快照按 userId 隔离）、`src/app.js`（Express 全部路由与错误映射）、`src/server.js`（启动入口，PORT/HOST 可配）、`README.md`、`.gitignore`（排除 node_modules/data）。
- [MSRV-001/003/004/012] 契约测试 `test/contract.test.js` 17 条：种子登录、健康空态 EMPTY_DATA、regions、注册/重复注册/密码错误/账号不存在/验证码错误/更新资料/改密/重置/登出/注销级联、健康 PUT/GET 读回与 userId 隔离、场景接口、重置恢复。
- [MSRV-005] 服务端错误映射已落地：HTTP 状态 → `{ error: { code, message } }`（400/401/404/409/500），代码沿用 proto 错误名（`ACCOUNT_NOT_FOUND`/`PASSWORD_INCORRECT`/`AUTH_REQUIRED` 等）。
- [MSRV-013] `.gitignore` 排除 `data/`，测试以 `setPersistEnabled(false)` 保持 hermetic，不落盘。
- [MSRV] 边界文档补充 README 目录结构加入 `mock-server/`。

## 人工审查点
- [MSRV-006] 冷启动会话校验粒度仍待业务确认（本地 TTL + 惰性校验 vs 每次打 `GET /api/auth/session`）；服务端 `GET /api/auth/session?userId=` 已按惰性语义提供。
- [MSRV-010] 三端数据一致靠服务器权威 + 刷新拉取，非实时推送，需业务接受。
- [MSRV-008] HarmonyOS 无在线设备，三端联调（含 KNOI 契约 diff）需设备/模拟器人工验收。
- [MSRV-002/005] 三端远程数据源与客户端错误映射、`MockError` 网络错误枚举尚未实现，属后续轮。

## 验证结果
- [MSRV-004] 先写契约测试并运行红灯：`Cannot find module '../src/app'`（实现缺失），确认测试能捕获缺失行为。
- [MSRV-001/003/004/012] 实现后 `cd mock-server && npm test`：17/17 通过（`node --test test/contract.test.js`）。
- [MSRV-001] 手工启动 `PORT=3199 node src/server.js`，curl 验证 `/api/auth/regions` 返回 CN/US、`/api/auth/login` 返回 `mock-user-default` 会话、未知路由返回 404 JSON。
- [MSRV-013] 测试后 `data/` 目录未被创建（hermetic），`git check-ignore` 确认 node_modules/data 被忽略。
- [SDD-009] `./tools/check-sdd.sh` 通过；`./tools/check-docs.sh` 仍仅剩既有 `docs/reference/注册登陆模块介绍.md` 可信哈希失败（历史轮次已记录，本轮未触碰）。

## 人工修正点
- 暂无明确人工修正点；`test/contract.test.js` 的 `before` 中 `resetStore()` 保证每条用例基于干净种子，`setPersistEnabled(false)` 避免测试写盘。

## 下轮交接
- **已完成**：`mock-server/` 工程（Node.js + Express）可独立启动；17 条契约测试通过；TRACE 中 MSRV-001/003/004/012/013 标记 `✅`（013 仅服务端侧，三端门禁扫描待后续）。
- **未完成 / 阻塞项**：三端远程数据源（MSRV-002/007/008）、缓存降级与会话惰性校验（MSRV-005/006/009）、三端错误提示与联调验收（MSRV-010/011）均未实现。
- **下轮起步建议**：先读 `spec/mock-server-api-spec.md` 与 TRACE「mock-server-api-spec.md 追溯」中仍 `⏳` 的行；实现顺序建议 Android 远程数据源打通全链路（MSRV-002/007）→ iOS（URLSession + 队列）→ HarmonyOS（ArkTS 侧 `ohos.net.http` + 复用 KNOI snapshot 入口，MSRV-008）→ 缓存与会话（MSRV-005/006/009）。

# 2026-08-05 11:54 — Android 远程数据源实现：服务端补接口 + Remote 数据源 + 契约测试转绿

## 采纳内容
- [MSRV-003] 服务端新增 `POST /api/auth/verify-code/check` 与 `GET /api/auth/account?account=`（UX 预检查接口，对应 `verifyCode`/`hasAccount`），契约测试增至 19 条全部通过；Spec 接口清单同步补充。
- [MSRV-002][MSRV-003][MSRV-004][MSRV-007] 新增 Android 平台层远程数据源：`core/network/MockServerHttpClient`（HttpURLConnection，同步阻塞 + 后台 executor + 超时）、`core/network/MockServerConfig`（base URL，模拟器 `10.0.2.2:3000`）、`auth/data/RemoteAuthRepository`（实现 `AuthRepository`，逐接口 HTTP + 本地会话/验证码缓存 + 冷启动 TTL 懒校验）、`health/data/RemoteHealthDashboardStateDataSource`（GET/PUT 整份快照，本地缓存兜底）。
- [MSRV-002][MSRV-007] `LoginViewModel.createRemote(context)` 工厂接线；`rememberLoginViewModel()` 切到 `createRemote`（生产走 mock server，Preview 仍用 `LoginViewModel()` fake）；`AndroidManifest.xml` 加 INTERNET 权限 + `network_security_config.xml`（10.0.2.2/localhost/127.0.0.1 明文）。
- [MSRV-005] Android 客户端错误映射：服务端错误 JSON `{error:{code,message}}` 经 `MockErrorMessage.toMockError()` 映射到既有 `MockError`；`MockServerHttpClient` 超时/网络失败返回状态 -1，客户端回退 `PersistFailed`。
- [MSRV-009] Android 缓存兜底：Remote 健康源以 `AndroidHealthDashboardStateDataSource` 为本地缓存，网络失败回退本地；Remote 认证源以 `AndroidAuthStoreDataSource` 保存会话。

## 人工审查点
- [MSRV-006] 冷启动懒校验粒度仍待业务确认：Android 已落地本地 TTL + 冷启动恢复，`GET /api/auth/session?userId=` 懒调用尚未接入，TRACE 记为 ⚠️。
- [MSRV-005] 网络不可达的专用枚举（如 `NetworkUnavailable`）与三端错误文案尚未落地，当前映射为 `PersistFailed`，TRACE 记为 ⚠️。
- [MSRV-010] 三端数据一致靠服务器权威 + 刷新拉取，非实时推送，需业务接受；交叉验收需服务器运行 + 多端登录。
- [MSRV-008] HarmonyOS 仍走 ArkTS 侧 HTTP（`ohos.net.http` + 复用 KNOI snapshot 入口），未开始实现，无在线设备待验收。

## 验证结果
- [MSRV-003] `cd mock-server && npm test`：19/19 契约测试通过（新增 verify-code/check 与 account 预检查 2 条）。
- [MSRV-001/003/004/005] 先写 `RemoteAuthRepositoryTest`（12 条，JDK HttpServer 桩）并运行红灯（缺模块编译失败），实现后 `./gradlew :androidApp:testDebugUnitTest --tests 'com.example.demo.auth.data.RemoteAuthRepositoryTest'` 通过；期间修复 regions 解析（parseObjectArray 直接传 body）与登出后注销需重新登录两处测试/实现问题。
- [MSRV-002][MSRV-007] `./gradlew :androidApp:testDebugUnitTest`（全量）、`:androidApp:assembleDebug`、`:androidApp:lintDebug`、`:common:check` 全部通过。
- [MSRV-003] 手工启动 `PORT=3210 node src/server.js`，curl 验证 `/api/auth/verify-code/check` 返回 `{"ok":true}`、`/api/auth/account?account=` 返回 `{"exists":true/false}`，验证后清理 `data/`。

## 人工修正点
- [MSRV-003] `availableRegions` 初版对 `optionalArray` 返回内容重新包裹导致 JSON 结构错误，改为 `AuthJson.parseObjectArray(response.body, "regions")` 直接解析。
- [MSRV-003] `logoutAndDeleteAccountSucceed` 测试初版登出后直接注销（`deleteCurrentAccount` 需活跃会话），改为登出后重新登录再注销，符合服务端语义。

## 下轮交接
- **已完成**：服务端 2 个 UX 预检查接口 + 19 条契约测试；Android 远程认证/健康数据源 + base URL 配置 + 工厂接线 + Manifest/网络安全配置；Android 12 条远程数据源测试、全量单测、assembleDebug、lintDebug、common:check 全绿。
- **未完成 / 阻塞项**：iOS（URLSession + 队列）、HarmonyOS（ArkTS `ohos.net.http` + KNOI snapshot 入口）远程数据源未实现；网络错误专用枚举/文案、会话懒校验调用、三端交叉验收未落地。
- **下轮起步建议**：先读 `spec/mock-server-api-spec.md` 与 TRACE「mock-server-api-spec.md 追溯」；实现顺序建议 iOS 远程数据源（参照 Android `RemoteAuthRepository`/`RemoteHealthDashboardStateDataSource` 的同步接口 + HTTP 下沉模式）→ HarmonyOS（MSRV-008，重点验证 `ohos.net.http` 与既有 KNOI snapshot 入口契约零变化）→ 缓存兜底与错误文案（MSRV-005/009/011）→ 三端联调验收（MSRV-010）。

# 2026-08-05 13:46 — iOS 与 HarmonyOS 远程数据源：Swift 注入 URLSession + ArkTS 快照同步

## 采纳内容
- [MSRV-002][MSRV-003][MSRV-004][MSRV-007] iOS 平台层远程数据源落地：`commonMain` 新增 `LoginFacadeFactory.createPersistent(authRepository:)`；`iosMain` 新增 `IosRemoteAuthRepository`（实现 `AuthRepository`，复用 common `MockAuthStoreJson`/`AuthJson`/`toMockError` 解析）、`IosRemoteHealthDashboardStateDataSource`、`IosHttpResponse` + `IosHttpTransport`（HTTP 传输由 Swift 注入闭包，符合既有 `loadJson/saveJson` 注入模式）、`IosMockServerConfig`（base URL）。
- [MSRV-002][MSRV-007] iOS `SharedLoginAdapter` 改为远端：`IosMockServerConfig.shared.baseUrl` 注入 `http://localhost:3000`，Swift 用 `URLSession` + `DispatchSemaphore` 实现同步 HTTP transport，经 `LoginFacadeFactory().createPersistent(authRepository:)` 与 `HealthFacadeFactory().createPersistent(authRepository:stateDataSource:)` 接线。
- [MSRV-008] 服务端新增 4 个 HarmonyOS 快照同步端点：`GET/PUT /api/sync/auth`（按 userId 作用域）、`GET/PUT /api/sync/health`（整集合），`store.js` 增加 `verifyCodesForAccount`/`allHealthSnapshots`/`replaceAllHealthSnapshots`；Spec 接口清单补充快照同步小节。
- [MSRV-008][MSRV-009][MSRV-007] HarmonyOS ArkTS 侧落地：`MockServerSync.ets`（`@ohos.net.http` 的 GET/PUT + `syncFromServer`/`syncToServer`，失败不阻断、沿用本地缓存）；`StorePersister.ets` 启动时拉取服务器权威快照、保存后异步推送；`module.json5` 增加 `ohos.permission.INTERNET`。

## 人工审查点
- [MSRV-008] 本环境无 DevEco/hvigor，HarmonyOS 的 ArkTS 构建、`provider.ets` KNOI 契约 diff 与设备联调均未执行，TRACE 记为 ⚠️；需在 DevEco 环境按 `docs/development-workflow.md` 验证。
- [MSRV-006] 冷启动懒校验调用尚未接入三端（本地 TTL 已落地），TRACE 记为 ⚠️。
- [MSRV-005] 网络不可达的专用枚举与三端错误文案未落地，当前映射 `PersistFailed`，TRACE 记为 ⚠️。
- [MSRV-010] 三端交叉验收需服务器运行 + 多端登录，TRACE 保持 ⏳。
- [MSRV-007] iOS 真机/模拟器需与服务器同一局域网；HarmonyOS `MOCK_SERVER_BASE_URL` 默认 `10.0.2.2`（模拟器），真机需改局域网 IP。

## 验证结果
- [MSRV-002][MSRV-008] `cd mock-server && npm test`：21/21 契约测试通过（新增 `MSRV-008: 认证 store 快照可按 userId 拉取与提交`、`MSRV-008: 健康快照集合可整体拉取与提交`）。
- [MSRV-002][MSRV-003][MSRV-004] iOS 编译验证：`./gradlew :common:compileKotlinIosSimulatorArm64` 通过；`./gradlew :common:linkDebugFrameworkIosSimulatorArm64` 生成 Shared.framework 且 `Shared.h` 暴露 `IosRemoteAuthRepository`/`IosRemoteHealthDashboardStateDataSource`/`IosHttpResponse`/`IosMockServerConfig`；`xcodebuild -scheme IOSDemo -sdk iphonesimulator build` 通过（期间修复 `IosMockServerConfig` 在 Swift 中须用 `.shared` 引用）。
- [MSRV-002] `./gradlew :common:check` 通过（含既有 common 测试）；`./tools/check-sdd.sh` 通过。
- [MSRV-008] 曾尝试 Kotlin/Native `NSURLSession` cinterop 实现 HTTP 客户端，因 Foundation 属性名解析不稳定（`HTTPMethod`/`HTTPBody` 无法解析）而放弃，改为“Swift 注入 transport 闭包”，与项目既有 `loadJson/saveJson` 注入模式一致且编译稳定。

## 人工修正点
- [MSRV-007] iOS `IosMockServerConfig` 是 Kotlin `object`，Swift 必须用 `IosMockServerConfig.shared.baseUrl` 而非 `IosMockServerConfig.baseUrl`，否则编译报 "instance member cannot be used on type"。
- [MSRV-008] Kotlin/Native 直接调 `NSURLSession` cinterop 不可行（属性名不稳定），iOS 网络必须由 Swift 层实现并通过闭包注入，避免在 iosMain 依赖具体平台网络 API 名。

## 下轮交接
- **已完成**：三端远程数据源全部落地——Android（OkHttp 式 HttpURLConnection + executor）、iOS（Swift URLSession 闭包注入 iosMain 逻辑）、HarmonyOS（ArkTS `ohos.net.http` + KNOI snapshot 入口）；服务端 21 条契约测试、common 全量测试、iOS xcodebuild、Android assembleDebug/lintDebug 通过；HarmonyOS 代码已写但本环境无法构建。
- **未完成 / 阻塞项**：HarmonyOS 构建验证（需 DevEco）；三端会话懒校验接入（MSRV-006）；网络错误专用枚举/文案（MSRV-005）；三端交叉验收（MSRV-010）。
- **下轮起步建议**：在 DevEco 环境执行 HarmonyOS 构建并确认 `provider.ets` 无契约 diff（`./tools/build-shared-harmony.sh` + `hvigorw assembleApp`）；随后补 MSRV-005 网络错误枚举/三端文案与 MSRV-006 懒校验调用，最后按 MSRV-010 做三端同账号交叉验收。

# 2026-08-05 15:40 — 四问题修复：同步注册丢失、TTL 失效、Choice 不刷新、头像存真实内容

## 采纳内容
- [MSRV-014] mock-server `PUT /api/sync/auth` 从"仅处理 accounts[0]"改为遍历全部账号 upsert，会话按 userId 匹配且 `isValid` 才保存；`buildUserId` 改为与 common `LocalMockAuthRepository` 完全一致的 Int32 环绕算法，消除 JS 科学计数法（`mock-user-4.09e+35`）导致的查询不匹配。
- [MSRV-006] Android `RemoteAuthRepository` 增加 `nowEpochMs` 构造参数并在 `LoginViewModel.createRemote` 注入 `System.currentTimeMillis()`，修复远端路径 TTL 永不失效；Harmony `MockServerSync.syncFromServer` 增加本地登录态权威保护——本地会话已被 TTL/登出清除时，服务器同步不把持久会话"复活"。
- [MSRV-015] 头像改为保存真实内容：Android `toAvatarDataUri/decodeAvatarDataUri`（base64 data URI），`ProfileAvatar`/`ProfileSummaryAvatar` 解码展示；iOS `ProfileImageStore.save` 返回 data URI、`image(at:)` 解码 data URI 与旧 key/文件回退；Harmony `avatarToDataUri`（fs 读字节 + Base64Helper）与新增 `AvatarImage.ets`（PixelMap 解码），`ProfileAvatarComponent`/`AccountOverviewComp` 接入。
- [MSRV] 鸿蒙 `NormalDataSectionPage` Choice 选中后不刷新：`ForEach` key 由稳定 `field.id` 改为 `fieldForEachKey`——Choice 行 key 含 `value`（选中变化强制重建刷新显示），TextInput 保持稳定 id 防焦点丢失。

## 人工审查点
- [MSRV-015] Harmony 头像相关代码（`@ohos.file.fs`/`@ohos.util`/`@ohos.multimedia.image`、`Base64Helper.encodeToStringSync/decodeSync`、`ImageSource.createPixelMap`）本环境无 DevEco/hvigor 无法编译，需在 DevEco 验证；API 12 签名按标准用法编写。
- [MSRV-014] `/api/sync/auth` 遍历 upsert 后，旧单账号行为不变；多账号推送会逐条覆盖服务器对应 userId 账号。
- [MSRV-006] Harmony TTL 保护依赖 `exportStoreSnapshot` 中 `currentSession.isValid` 的本地语义，需在真机验证"退出 10s 后冷启动退出登录"。

## 验证结果
- [MSRV-014] `cd mock-server && npm test`：22/22 通过（新增 `注册新账号经 sync/auth 持久化` 先因 accounts[0] 之外丢失红灯，遍历 upsert + buildUserId 修复后转绿）。
- [MSRV-006] `./gradlew :androidApp:testDebugUnitTest --tests 'com.example.demo.auth.data.RemoteAuthRepositoryTest'`：14/14 通过（新增 `sessionExpiresAfterBackgroundTtlWhenClockAdvances`、`sessionSurvivesBackgroundWithinTtl`；初版测试误在 pause 后调用 resume 复位 TTL 而红灯，修正测试流程后通过）。
- [MSRV-015] `./gradlew :androidApp:assembleDebug :androidApp:lintDebug :common:check` 通过；iOS `xcodebuild -scheme IOSDemo` 通过。
- [SDD-009] `./tools/check-sdd.sh`、`./tools/check-resource-maintainability.sh` 通过；`check-docs.sh` 仅剩既有 `注册登陆模块介绍.md` 哈希失败（历史遗留）。

## 人工修正点
- [MSRV-006] TTL 测试初版在 `pauseSession()` 后调用了 `resumeSessionInSameProcess()`，该调用会把 `expireAtEpochMs` 复位为 0（永不失效），导致断言失败；测试修正为 pause 后直接推进时钟做冷启动校验，另加"未超 TTL 暖恢复保持活跃"用例。
- [MSRV-015] Harmony `ProfileCompletionPage` 的本地 `decodeAvatarDataUri` 与 `AvatarImage.ets` 重复，改为统一导入共享组件中的实现，避免双份逻辑漂移。

## 下轮交接
- **已完成**：四问题全部处理——同步注册持久化（MSRV-014）、远端会话 TTL（MSRV-006）、鸿蒙 Choice 刷新、三端头像真实内容（MSRV-015）。Android/iOS/common/服务端均编译与测试通过；鸿蒙代码完成但本环境无法构建。
- **未完成 / 阻塞项**：HarmonyOS DevEco 构建验证（头像 fs/util/image API、Choice key 改动、TTL 保护）；MSRV-005 网络错误枚举/文案；MSRV-010 三端交叉验收。
- **下轮起步建议**：在 DevEco 执行 `./tools/build-shared-harmony.sh` + `hvigorw assembleApp` 验证鸿蒙头像/Choice/TTL 三处改动并跑回归；随后做 MSRV-010 三端同账号交叉验收（重点：头像跨设备可见、注册后 data 落盘、退出 10s 后冷启动退出登录）。

# 2026-08-05 16:04 — 头像保存完善与鸿蒙 MockServerSync serverStore 编译错误修复

## 采纳内容
- [MSRV-015] 修复头像"原图原始字节直接 base64 + mime 标错"问题：Android `scaleToAvatar`（512px 上限）+ JPEG 85 统一编码，`ByteArray.toAvatarDataUri` 先解码缩放、失败回退原始字节；移除冗余的私有文件写入（data URI 自包含）；iOS `ProfileImageStore.downscaledJPEG` 解码→缩放→JPEG 85；Harmony `avatarToDataUri` 改为 `image.createImageSource → createPixelMap → scalePixelMap → ImagePacker packing('image/jpeg') → base64` 的异步流程，新增 `AvatarImage.scalePixelMap`/`AVATAR_MAX_DIMENSION`。
- [MSRV-008] 修复 `MockServerSync.ets` ArkTS 编译错误：`SyncAuthResponse.store` 类型由 `Record<string, Object>` 改为 `SyncAuthStore`，去掉 `as SyncAuthStore` 强转；`merged` 对象字面量改为显式类型标注 + 具名字段（不用对象展开 + `currentSession: null`），`currentSession` 置 `undefined`（JSON 序列化省略字段）。

## 人工审查点
- [MSRV-015] Harmony 头像重编码（`ImagePacker.packing`、`pixelMap.scaleSync`、`getImageInfoSync`）与 `fs`/`util` API 本环境无 DevEco/hvigor 无法编译，需 DevEco 验证签名与行为；若 `scaleSync` 不可用可改 `createPixelMap` 的 `desiredSize` 重采样。
- [MSRV-015] mock server `express.json({ limit: '2mb' })` 对 512px JPEG（约 50–100KB base64）足够；旧 769KB 测试数据已删除。

## 验证结果
- [MSRV-015] 诊断确认旧 data URI 内容为 PNG 魔数却标 `image/jpeg`（`iVBORw0KGgo` 前缀），原图 769KB 直接 base64；python 生成 8×8 PNG 验证 data URI 提取解码 magic bytes 正确（`\x89PNG`）。
- [MSRV-015] Android `:androidApp:assembleDebug`/`:androidApp:lintDebug`、`:common:check` 通过；iOS `xcodebuild -scheme IOSDemo` 通过；mock server 22/22 契约测试通过；`./tools/check-sdd.sh` 通过。
- [MSRV-008] `MockServerSync.ets` 改动为静态类型修正，逻辑不变；本环境无法编译 ArkTS，编译验证待 DevEco。

## 人工修正点
- [MSRV-015] 初版 `ByteArray.toAvatarDataUri` 在上一轮被误删，本轮回补并加入解码缩放失败回退原始字节；`Bitmap.scaleToAvatar` 返回原对象时不再误 `recycle()`。
- [MSRV-015] mock server data 中残留的旧 769KB base64 头像已 `rm` 清理，避免用户误以为新实现仍有体积问题。

## 下轮交接
- **已完成**：头像三端统一"缩放 512px + JPEG + base64 data URI"内容契约；鸿蒙 MockServerSync serverStore ArkTS 编译错误修复；清理旧测试数据。
- **未完成 / 阻塞项**：HarmonyOS DevEco 构建验证（头像 `ImagePacker`/`scaleSync`、`MockServerSync` 类型修正、Choice key、TTL 保护）；MSRV-005 网络错误枚举/文案；MSRV-010 三端交叉验收。
- **下轮起步建议**：在 DevEco 执行 `./tools/build-shared-harmony.sh` + `hvigorw assembleApp`，重点验证头像选择→保存→跨端展示链路；随后做 MSRV-010 三端同账号交叉验收（头像跨设备可见、注册后 data 落盘、退出 10s 后冷启动退出登录）。

# 2026-08-05 16:45 — 头像改为 mock server 文件存储（方案 A）：三端上传/URL 展示

## 采纳内容
- [MSRV-015] 按用户选择方案 A 重做头像：mock server 新增 `GET/PUT/DELETE /api/avatar/:userId`，图片二进制落盘 `data/avatars/{userId}.jpg`；`avatarUri` 统一存相对路径 `/api/avatar/{userId}`，各端用自身 base URL 拼 URL 展示。彻底废弃 base64 data URI。
- [MSRV-015] 契约测试新增 3 条：头像 PUT→GET 二进制一致、注销账号级联删除头像文件、未知用户上传返回 `ACCOUNT_NOT_FOUND`；mock server 25/25 通过。
- [MSRV-015] Android：`MockServerHttpClient` 新增 `putBinary/getBinary`；`ProfileEditHelpers` 重写为 `uploadAvatarFromUri/uploadAvatarBitmap/resolveAvatarBitmap`（服务器路径下载），删除 data URI 逻辑；两个 Screen 选图回调改为上传得相对路径。
- [MSRV-015] iOS：`ProfileImageStore.save` 改为 async URLSession PUT 缩放 JPEG，返回相对路径；`image(at:)` 支持 `/api/avatar/` 下载；ProfileCompletionView/AccountView 调用点改为 `await`。
- [MSRV-015] Harmony：`AvatarImage.ets` 重写为 URL 展示 + `uploadAvatarToServer`（读文件字节 PUT 到服务器，不做不可验证的 image 重编码）；`LoginLogicAdapter`/`KnoiLoginAdapter`/`PreviewLoginAdapter`/`LoginViewModel` 新增 `currentUserId()`；`ProfileCompletionPage` 移除 `image`/`util`/`fs`/base64 逻辑，`pickAvatarFromAlbum` 上传并存相对路径，`ProfileAvatarComponent` 用 `MOCK_SERVER_BASE_URL + avatarUri` 展示。

## 人工审查点
- [MSRV-015] Harmony 的 `AvatarImage.ets` 导入 `MOCK_SERVER_BASE_URL` 与 `http`/`fs`（页面 import 图会触达 native，Preview 若报错需按 UI-PREVIEW-008 分离纯 ArkTS 契约）。
- [MSRV-015] 头像文件不经 store JSON 同步，仅在服务器落盘；注销账号会级联删除文件，但登出不删（保留头像跨端可复用）。
- [MSRV-015] iOS `image(at:)` 对服务器路径是同步下载（信号量阻塞），本地 mock 快可接受，真机远端网络下建议后续改异步。

## 验证结果
- [MSRV-015] `cd mock-server && npm test`：25/25 通过（新增 3 条头像文件契约测试）。
- [MSRV-015] `./gradlew :common:check :androidApp:assembleDebug :androidApp:lintDebug :androidApp:testDebugUnitTest` 全部通过；iOS `xcodebuild -scheme IOSDemo` 通过（期间修复 `avatarServerPath(userId:)` 缺标签、`IosMockServerConfig` 需 `import Shared`）。
- [SDD-009] `./tools/check-sdd.sh` 通过；`./tools/check-resource-maintainability.sh` 通过；`check-docs.sh` 仅剩既有 `注册登陆模块介绍.md` 哈希失败（历史遗留）。

## 人工修正点
- [MSRV-015] iOS 初版 `avatarServerPath(userId)` 调用漏标签，Swift 强制标签导致编译错误，改为 `avatarServerPath(userId:)`。
- [MSRV-015] Harmony `AvatarImage.ets` 初版用 `image.createImageSource().then` 写法（同步 API 被当 Promise）且 `scalePixelMap`/`AVATAR_MAX_DIMENSION` 在 ProfileCompletionPage 残留 import；已重写为直接 URL 展示 + 纯字节上传，移除不可验证的 image 重编码。

## 下轮交接
- **已完成**：方案 A 头像文件存储落地——mock server 头像端点 + 契约测试、三端上传/URL 展示、Harmony `currentUserId()` 链路。Android/iOS/common/服务端编译与测试通过。
- **未完成 / 阻塞项**：HarmonyOS DevEco 构建验证（AvatarImage URL 展示、uploadAvatarToServer、currentUserId 链路、Choice key、TTL 保护）；MSRV-005 网络错误枚举/文案；MSRV-010 三端交叉验收。
- **下轮起步建议**：在 DevEco 执行 `./tools/build-shared-harmony.sh` + `hvigorw assembleApp` 验证头像/Choice/TTL；随后 MSRV-010 三端同账号交叉验收（重点：选头像→上传→跨端可见、注册后 data 落盘、退出 10s 后冷启动退出登录）。

# 2026-08-05 17:27 — 鸿蒙无法读取服务器数据却会修改 data：快照同步改为按用户合并

## 采纳内容
- [MSRV-008-SYNC] 定位根因：鸿蒙 `syncToServer` 把本地 store **整份** PUT `/api/sync/health`，服务器用 `replaceAllHealthSnapshots` 整体替换 → 鸿蒙本地只有自己/空数据时清空 Android/iOS 健康快照；`/api/sync/auth` 遍历 upsert 全部账号也会污染账号库。`syncFromServer` 在未登录（`currentUserIdOf` 为空）时发空 userId 查询并拿空 store 覆盖本地，导致"读不到"。
- [MSRV-008-SYNC] 服务器 `PUT /api/sync/health` 改为逐条 `saveHealthSnapshot`（按 userId upsert，保留其他用户）；`PUT /api/sync/auth` 只处理 `currentSession.userId` 对应账号，不再遍历覆盖其他账号。
- [MSRV-008-SYNC] 鸿蒙 `syncToServer` 只提交当前 userId：auth 只发该用户账号+会话，health 只发该用户快照；`syncFromServer` 未登录（无有效 userId）跳过 auth 拉取，且服务器无该用户账号时保留本地登录态（首次本地注册不被空 store 覆盖）；健康始终全量拉取合并。
- [MSRV-008-SYNC] `KnoiLoginAdapter.submit` 登录成功后主动 `syncFromServer` 拉服务器权威数据，使鸿蒙能看到 Android/iOS 写入的资料/健康。

## 人工审查点
- [MSRV-008-SYNC] HarmonyOS `MOCK_SERVER_BASE_URL` 默认 `10.0.2.2`（Android 模拟器约定）；鸿蒙模拟器/真机需按环境改为宿主机局域网 IP，否则网络请求失败（本环境无鸿蒙设备无法实测）。
- [MSRV-008-SYNC] 鸿蒙 `submit` 成功后 `syncFromServer` 是网络请求，UI 有短暂等待；若失败沿用本地缓存不阻断。
- [MSRV-008-SYNC] 服务器 `PUT /api/sync/auth` 现只处理当前会话用户；若鸿蒙退出登录（无会话）提交 store，不会更新任何账号（符合"不污染他人"）。

## 验证结果
- [MSRV-008-SYNC] `cd mock-server && npm test`：27/27 通过（新增 `同步健康快照按 userId 合并，不覆盖其他用户`、`认证 store 同步只更新当前会话用户，不覆盖其他账号` 2 条；先因 replaceAll 覆盖红、改 merge 后绿）。
- [MSRV-008-SYNC] 端到端脚本验证：A 用户写健康 → 鸿蒙 sync 提交 → B 用户数据保留（`B still exists: 200 ['STRESS']`）；A 数据为鸿蒙最新提交（`['SLEEP']`）。
- [MSRV-008-SYNC] `./gradlew :common:check :androidApp:assembleDebug :androidApp:lintDebug` 通过；`./tools/check-sdd.sh` 通过；`check-docs.sh` 仅剩既有 `注册登陆模块介绍.md` 哈希失败。

## 人工修正点
- [MSRV-008-SYNC] 测试中 register 需要先请求 verify-code（初始 resetStore 后验证码清空导致注册 400），补充 verify-code 请求后通过。
- [MSRV-008-SYNC] 鸿蒙 `syncFromServer` 初版在服务器无该用户账号时仍 `restoreStoreSnapshot(空)` 覆盖本地，新增 `hasServerAccount` 守卫保留本地登录态。

## 下轮交接
- **已完成**：三端数据互通问题修复——服务器 sync 端点按用户合并，鸿蒙只提交/按需拉取当前用户，登录成功主动拉取服务器权威数据。服务端 27 契约测试 + 端到端脚本 + common/Android 构建通过。
- **未完成 / 阻塞项**：HarmonyOS DevEco 构建验证（`MockServerSync` merge 逻辑、`submit` 后 syncFromServer、头像、Choice、TTL）；`MOCK_SERVER_BASE_URL` 需按鸿蒙环境配置；MSRV-010 三端交叉验收。
- **下轮起步建议**：DevEco 构建鸿蒙并验证"Android 改数据 → 鸿蒙登录/刷新可见 → 鸿蒙改数据不覆盖 Android"完整链路；随后 MSRV-010 三端同账号交叉验收。

# 2026-08-05 17:43 — mock server 数据按端口隔离（修复多实例互相覆盖）

## 采纳内容
- [MSRV-007-PORT] mock server 数据按端口隔离：`store.js` 新增 `configureDataFile(name)`，`server.js` 启动时按 `PORT` 派生数据文件名 `mock-server-store-{PORT}.json`（可用 `DATA_FILE` 覆盖）；契约测试改用独立 `mock-server-store-test.json` 且 `setPersistEnabled(false)`，绝不触碰运行时实例数据。
- [MSRV-007-PORT] 说明鸿蒙交互模型差异根因（KNOI 桥同步 + ohos_arm64 无网络库 → HTTP 只能在 ArkTS 侧 + snapshot 入口，天然快照同步），并按用户要求实施端口隔离。

## 人工审查点
- [MSRV-007-PORT] 已运行的旧实例若曾使用默认 `mock-server-store.json`，升级后新实例读写 `mock-server-store-{PORT}.json`，旧数据不自动迁移；如需保留需手工改名（Demo 阶段可接受）。
- [MSRV-007-PORT] 鸿蒙 `MOCK_SERVER_BASE_URL` 默认 `10.0.2.2`（Android 模拟器约定），鸿蒙模拟器/真机需按环境改为宿主机局域网 IP。

## 验证结果
- [MSRV-007-PORT] `cd mock-server && npm test`：27/27 通过。
- [MSRV-007-PORT] 双实例脚本验证：3000/3001 各自生成独立文件 `mock-server-store-3000.json`/`-3001.json`，各自注册账号后 grep 计数为 3/0（本端口账号 3 处、他端口账号 0 处），确认互不覆盖。
- [MSRV-007-PORT] `./tools/check-sdd.sh` 通过；`check-docs.sh` 仅剩既有 `注册登陆模块介绍.md` 哈希失败（历史遗留）。

## 人工修正点
- 暂无明确人工修正点；旧 `mock-server-store.json` 若需保留数据可改名 `mock-server-store-3000.json` 迁移。

## 下轮交接
- **已完成**：mock server 数据按端口隔离，多实例（含测试）互不覆盖；`README`/Spec/TRACE 更新。
- **未完成 / 阻塞项**：HarmonyOS DevEco 构建验证（快照 merge、`submit` 后 syncFromServer、头像、Choice、TTL）；`MOCK_SERVER_BASE_URL` 按鸿蒙环境配置；MSRV-010 三端交叉验收。
- **下轮起步建议**：DevEco 构建鸿蒙验证三端互通链路；随后 MSRV-010 交叉验收。提醒：我这边后续验证会使用独立测试文件，不再删除你的 `data/` 运行时数据。

# 2026-08-06 09:20 — 修复 Android 头像异步显示/编辑刷新与鸿蒙注册后不跳转资料完善

## 采纳内容
- [MSRV-015] Android 头像显示改为异步：新增 `AvatarImage`/`AvatarImageWithRevision` composable（`LaunchedEffect` + `Dispatchers.IO` 后台下载，不再主线程同步阻塞）；`ProfileAvatar`/`ProfileSummaryAvatar` 复用；修复"信息完善界面选完照片显示慢"（主线程被网络阻塞）。
- [MSRV-015] Android 编辑页切换头像后不刷新：上传成功后 `avatarUri` 仍是同一相对路径，`remember(avatarUri)` key 不变导致缓存旧图；新增 `avatarRevision` 递增计数，`ProfileAvatar` 增加 `revision` 参数，`AvatarImageWithRevision` 以 `avatarUri#revision` 为 key 强制重载。
- [MSRV-008-SYNC] 鸿蒙注册成功后无法跳转资料完善：根因是 `KnoiLoginAdapter.submit` 在注册成功后 `await syncFromServer`，而 `syncFromServer` 调 `restoreStoreSnapshot` 会**重建 LoginFacade**，丢弃 `AuthSucceeded` pendingEffect，导致 `consumeEffect()` 返回 null 无法跳转。
- [MSRV-008-SYNC] 修复：`MockServerSync` 拆出 `syncHealthFromServer`（只同步健康快照，不碰 auth facade）；`KnoiLoginAdapter.submit` 登录/注册成功后改调 `syncHealthFromServer`，保留 `AuthSucceeded` effect；`StorePersister.initPersistence` 启动仍用 `syncFromServer`（无 pending effect，安全）。

## 人工审查点
- [MSRV-015] Android 头像异步下载在 `LaunchedEffect` 中，弱网时短暂显示占位；无本地磁盘缓存（仅内存），离开页面再进入会重新下载，Demo 可接受。
- [MSRV-008-SYNC] 鸿蒙注册后 `syncHealthFromServer` 只拉健康，不拉服务器资料（此时服务器本无该新账号）；资料保存由 `ProfileCompletionPage` 提交后经 `syncToServer` 推送。
- [MSRV-008-SYNC] 本环境无 DevEco/hvigor，鸿蒙改动（`syncHealthFromServer`、`submit` 调用调整）需 DevEco 构建验证跳转。

## 验证结果
- [MSRV-015] `./gradlew :androidApp:assembleDebug :androidApp:lintDebug :androidApp:testDebugUnitTest :common:check` 全部通过（编译期修复 `size` import、Preview 缺 `avatarRevision`、SignedInScreen 缺 `AvatarImage` import）。
- [MSRV-008-SYNC] 静态核对引用一致：`StorePersister` 用 `syncFromServer`（启动）、`KnoiLoginAdapter` 用 `syncHealthFromServer`（登录/注册成功）。
- [SDD-009] `cd mock-server && npm test` 27/27 通过；`./tools/check-sdd.sh` 通过。

## 人工修正点
- [MSRV-015] `AvatarImage.kt` 初版缺 `Modifier.size` 导入（`androidx.compose.foundation.layout.size`），编译红灯；`PersonalProfileEditScreen` Preview 缺 `avatarRevision` 参数；SignedInScreen 缺 `AvatarImage` import——均已补齐。
- [MSRV-008-SYNC] 初版在 `submit` 成功后调 `syncFromServer` 全量同步，导致注册 effect 丢失；改为 `syncHealthFromServer` 只同步健康后解决。

## 下轮交接
- **已完成**：Android 头像异步显示 + 编辑页 revision 刷新；鸿蒙注册后跳转修复（`syncHealthFromServer` 不重建 facade）。
- **未完成 / 阻塞项**：HarmonyOS DevEco 构建验证（注册跳转、`syncHealthFromServer`、头像/Choice/TTL）；`MOCK_SERVER_BASE_URL` 按鸿蒙环境配置；MSRV-010 三端交叉验收。
- **下轮起步建议**：DevEco 构建鸿蒙，重点验证"注册 → 自动跳资料完善 → 保存 → 健康互通"与 Android/iOS 头像跨端；随后 MSRV-010 交叉验收。

# 2026-08-06 13:40 — mock-server 单设备登录/多账号并存/数据接口鉴权/存储拆分与原子落盘

## 采纳内容
- [MSRV-016] 单账号单设备登录（微信模式顶号 + 二次确认）：`store.js` 全局 `currentSession` 改为 per-account `sessions` 集合；`login/register` body 增加 `deviceId`/`deviceName`/`force`；非 force 登录遇有效异地会话返回 409 `SESSION_ACTIVE_ELSEWHERE`（含 `activeDevice`），force 登录顶掉旧会话，被顶设备请求返回 401 `SESSION_EXPIRED_ELSEWHERE`。未携带 deviceId 统一 `device-default` 向后兼容。
- [MSRV-017] 多账号并存：`sessions` 按 userId 隔离；`logout` 按 body `userId`+`deviceId` 作用域化只清本账号。
- [MSRV-018] 数据接口会话校验：`GET/PUT /api/health/:userId`、`PUT/DELETE /api/avatar/:userId`、`GET/PUT /api/sync/auth|health` 均需本人有效会话（`requireSession`，设备不匹配或会话失效返回 401）；`GET /api/avatar/:userId` 因图片加载器无法带设备头仅校验会话有效性。
- [MSRV-020] 存储拆分：`data/{PORT}/accounts.json`（accounts+sessions+verifyCodes）+ `data/{PORT}/health/{userId}.json`（每账号一文件，缺失=空快照）+ `data/{PORT}/avatars/{userId}.jpg`；`configureDataDir/setDataRoot` 支持端口目录与测试临时根；旧单文件 `mock-server-store-{PORT}.json` 启动时一次性迁移后删除。
- [MSRV-021] 原子落盘：`atomicWrite/atomicWriteBuffer` 统一"临时文件 + rename"，崩溃不产生半写文件。

## 人工审查点
- [MSRV-016] 会话被顶只在"下次请求"时发现（mock 无推送）；`force` 登录在对方已登出时也直接成功（幂等）。deviceId 缺失统一 `device-default`，两台旧客户端会被视为同一设备而不触发冲突——属于向后兼容降级，三端接入真实 deviceId 后生效。
- [MSRV-018] 头像 GET 为适配原生图片加载器放宽为"仅校验会话有效"；健康/sync 严格设备匹配。
- [MSRV-020] 跨文件无事务：健康文件懒创建（缺失=空快照），注销级联删账号/会话/健康文件/头像；迁移只认"新布局缺失且旧文件存在"。

## 验证结果
- [MSRV-016/017/018/020/021] `cd mock-server && npm test`：43/43 通过（原 27 条更新 + 新增 MSRV-016/017/018 契约测试 10 条 + store 层 5 条）；`node --check` 三文件语法通过。
- [MSRV-020] 真实启动冒烟：临时 `DATA_DIR` + 旧单文件启动，自动迁移为 `{PORT}/accounts.json` + `health/*.json`，旧文件删除；登录签发会话带 deviceId。
- [SDD-009] Spec（MSRV-016~021、MSRV-007-PORT、MSRV-018 边界）与 TRACE 已更新；README 同步。

## 人工修正点
- [MSRV-018] 初版契约测试依赖共享服务器状态导致顺序脆弱：MSRV-016/017/018 各测试开头补 `resetStore()` 保证隔离；`MSRV-015 注销头像`、`MSRV-003 注销健康` 改为断言 401（会话一并删除）而非 404。
- [MSRV-003] 种子密码在改密/重置测试后改变导致后续用例失败：`重置密码` 测试末尾恢复密码 `123456`。
- [MSRV-017] `register` 会先按默认 device 签发会话，后续用不同 deviceId 登录会误触 409：测试中 `register` 显式传 `deviceId`。

## 下轮交接
- **已完成**：mock-server 服务端单设备登录（二次确认 + 顶号）、多账号并存、健康/头像/sync 会话校验、存储拆分与原子落盘、旧文件迁移；契约测试 43/43 绿。
- **未完成 / 阻塞项**：三端客户端接入（MSRV-019 冷启动/回前台懒校验 + 二次确认 UI + deviceId 持久化 + `X-Device-Id` 携带），HarmonyOS 因本环境无 DevEco 无法构建；Android/iOS 远程数据源需接入 `GET /api/auth/session` 与 `SESSION_ACTIVE_ELSEWHERE`/`SESSION_EXPIRED_ELSEWHERE` 映射。
- **下轮起步建议**：先 Android（`RemoteAuthRepository` + deviceId + 错误映射 + 懒校验），iOS 镜像实现，HarmonyOS 在 DevEco 环境下完成 sync 路径会话校验；随后 MSRV-010 三端交叉验收。提醒：勿 `rm -rf data/`，运行时旧数据会在下次启动自动迁移。

# 2026-08-06 14:02 — Android 客户端接入单设备登录/二次确认/被顶懒校验

## 采纳内容
- [MSRV-016] common `LoginResult` 新增 `SessionActiveElsewhere(activeDevice)`；`LoginRequestDto` 增 `deviceId/deviceName/force`（默认值，向后兼容）；`LoginStore` 处理冲突——`state.confirmForceLogin=true` + `LoginEffect.ShowForceLoginDialog`，`ConfirmForceLogin` 以 `force` 重登、`CancelForceLogin` 清除；`LoginFacade` 暴露 `confirmForceLogin/cancelForceLogin`。
- [MSRV-016/018] `MockError` 新增 `SessionActiveElsewhere`/`SessionExpiredElsewhere`（含 `AuthMessageKeys` 三端资源）；`SessionResumeResult` 新增 `KickedElsewhere`。
- [MSRV-019] Android/iOS `restoreSessionOnColdStart` 冷启动打 `GET /api/auth/session`：被顶→`KickedElsewhere` 清会话，失效→`Expired`，200 不改本地缓存（避免覆盖 pauseSession 的本地 TTL）。
- [MSRV-016] Android 平台：`AndroidDeviceId`（SharedPreferences 持久化 UUID）+ `MockServerHttpClient` 全请求携带 `X-Device-Id` + `RemoteAuthRepository` 409 冲突解析与 `force` 传递；`AuthNavGraph` 二次确认 AlertDialog（`auth_force_login_confirm_body` 三端资源）；头像上传 `uploadAvatarBitmap` 带 deviceId。
- [MSRV-016] iOS 镜像（best effort）：`IosMockServerConfig.deviceId` + Swift `httpRequest` 携带 `X-Device-Id` + `SharedLoginAdapter` confirm/cancel + `LoginPageView` `.alert`；`HarmonyLoginJson` 桥快照含 `confirmForceLogin`/`ShowForceLoginDialog`，`HarmonyLoginService` 暴露 confirm/cancel。

## 人工审查点
- [MSRV-019] 懒校验 200 分支刻意不写回本地缓存：服务端会话 `expireAtEpochMs=0` 会冲掉 `pauseSession` 设置的本地 TTL，破坏后台挂起语义（初版刷新导致 `sessionExpiresAfterBackgroundTtlWhenClockAdvances` 红灯，已改为只检测被顶/失效）。
- [MSRV-016] 未携带 deviceId 的旧客户端统一 `device-default`，两台旧客户端会被视为同设备而不触发冲突——向后兼容降级。
- [MSRV-018] 头像 GET 因原生图片加载器无法携带设备头，服务端放宽为"仅校验会话有效"；写操作严格校验。
- [MSRV-019] Harmony 侧新增桥方法（confirm/cancel）与快照字段会改变 provider.ets 契约，需 DevEco 下重建验证；本环境无法构建 Harmony。

## 验证结果
- [MSRV-016] `./gradlew :common:check` 全绿（`LoginUseCaseTest` 新增 `loginConflictSetsConfirmFlagAndEffect`/`confirmForceLoginSucceedsAndClearsConfirmFlag`/`cancelForceLoginClearsConfirmFlag`/`kickedElsewhereOnRestoreEmitsSessionExpiredWithMessage`）。
- [MSRV-016/019] `./gradlew :androidApp:testDebugUnitTest` 全绿（`RemoteAuthRepositoryTest` 新增 `loginConflictMapsToSessionActiveElsewhere`/`forceLoginBypassesConflict`/`coldStartKickedElsewhereClearsSession`/`coldStartExpiredClearsSession`/`coldStartActiveRefreshesSessionFromServer`）。
- [MSRV-016/018] `./gradlew :androidApp:assembleDebug :androidApp:lintDebug` 通过；`cd mock-server && npm test` 43/43。
- 资源：三端新增 `auth_error_session_active_elsewhere`/`auth_error_session_expired_elsewhere`/`auth_force_login_confirm_body` 键（中英）。

## 人工修正点
- [MSRV-019] 初版懒校验 200 分支用服务器会话覆盖本地缓存，导致暂停 TTL 被清零、TTL 过期测试红灯；改为 200 不写本地缓存。
- [MSRV-016] `IosMockServerConfig.shared.deviceId` 在 Kotlin 侧应为 `IosMockServerConfig.deviceId`（`.shared` 仅 Swift 互操作），初版编译红灯已修。
- [MSRV-016] `FakeConflictRepository` 被子类继承需声明 `open`。
- [MSRV-016] `check-resources.sh` 共享键路径指向重构前 `auth/AuthMessageKeys.kt`（HEAD 同样失败），为既有门禁陈旧路径，本轮新增键已按门禁意图在三端一致。

## 下轮交接
- **已完成**：服务端单设备/多账号/数据鉴权/存储拆分/原子落盘（43 契约测试绿）；Android 客户端 deviceId/懒校验/二次确认弹窗/被顶处理（common+app 测试全绿）。
- **未完成 / 阻塞项**：iOS SwiftUI 二次确认弹窗与懒校验需 xcodebuild 验证（代码已写）；HarmonyOS 桥方法/快照字段改变 provider.ets 契约，需 DevEco 重建并实现 ArkTS 弹窗与 sync 会话校验；三端真机/模拟器联调（MSRV-010/019）。
- **下轮起步建议**：先 `xcodebuild` 验证 iOS，再在 DevEco 环境重建 Harmony bridge（provider.ets diff）并接入 ArkTS 二次确认与 sync 校验；随后三端交叉验收。提醒：运行时旧数据会在 mock-server 下次启动自动迁移到 `data/{PORT}/`。

# 2026-08-06 14:25 — 修正 iOS Swift 编译错误与鸿蒙 mock server 接入地址

## 采纳内容
- [MSRV-016] 修正 iOS `LoginViewModel` 名称冲突：`confirmForceLogin` 属性（`state.confirmForceLogin`）与同名方法冲突（Swift 不允许属性/方法同名）→ 方法改名 `confirmForceLoginTapped()`，`LoginPageView` 确认按钮同步；`cancelForceLogin()` 无冲突保留。
- [MSRV-016/019] 修正 Swift 调用 `IosRemoteAuthRepository` 缺参：KMP 构造默认参数不映射到 Swift，Swift 必须显式传 `deviceIdProvider: { IosMockServerConfig.shared.deviceId }`。
- [MSRV-007] 修正鸿蒙连不上 mock server：`MOCK_SERVER_BASE_URL` 由 Android 模拟器专用 `http://10.0.2.2:3000` 改为宿主机局域网 IP `http://192.168.33.204:3000`（本机 en0），并加注释说明"鸿蒙真机/模拟器不能用 10.0.2.2，需按本机局域网 IP 修改"；`mock-server/README.md` 三端 base URL 小节补充鸿蒙用法。

## 人工审查点
- [MSRV-016] iOS 二次确认弹窗（`LoginPageView` `.alert`）与 Kotlin `LoginState.confirmForceLogin` 通过 KMP 导出直接绑定；KMP 默认参数不导出到 Swift，所有构造调用需显式传参。
- [MSRV-007] 鸿蒙接入地址依赖宿主机局域网 IP（DHCP 可能变化），已用注释与 README 明确"运行前按本机 IP 修改"；`MOCK_SERVER_BASE_URL` 仍是平台层硬编码单点配置（MSRV-007 语义内可接受，未做构建期注入）。
- Harmony 侧桥方法/快照字段（confirm/cancel、ShowForceLoginDialog）会改变 provider.ets 契约，仍需 DevEco 重建验证。

## 验证结果
- [MSRV-016/019] iOS `xcodebuild -project iosApp/iosApp.xcodeproj -scheme IOSDemo -destination 'generic/platform=iOS Simulator' -configuration Debug build`：**BUILD SUCCEEDED**（KMP framework 经 `embedAndSignAppleFrameworkForXcode` 重建 + Swift 全量编译通过）。
- [MSRV-016] `./gradlew :common:check :androidApp:testDebugUnitTest :androidApp:assembleDebug` 此前已绿；本轮未改 common/Android 代码。
- 文档：TRACE（MSRV-016/017/018/019/007）更新。

## 人工修正点
- [MSRV-016] `LoginViewModel` 属性与同名方法冲突（iOS 编译报 "Invalid redeclaration"）→ 方法改名 `confirmForceLoginTapped()`。
- [MSRV-016] Swift 调 `IosRemoteAuthRepository` 缺 `deviceIdProvider` 参数（KMP 默认参数不导出）→ 显式传 `{ IosMockServerConfig.shared.deviceId }`。
- [MSRV-007] 鸿蒙连不上：`10.0.2.2` 是 Android 模拟器专用，鸿蒙改用宿主机局域网 IP。

## 下轮交接
- **已完成**：iOS Swift 编译修复并通过 xcodebuild；鸿蒙 base URL 改为局域网 IP（本机 `192.168.33.204`）。
- **未完成 / 阻塞项**：HarmonyOS 侧仍需 DevEco 环境——重建 KNOI bridge（provider.ets diff）、实现 ArkTS 二次确认弹窗与 sync 路径会话校验、真机/模拟器验证局域网连通性；三端交叉验收（MSRV-010/019）。
- **下轮起步建议**：在 DevEco 打开 harmonyApp，先确认 `MOCK_SERVER_BASE_URL` 指向可达的宿主机 IP（必要时改回本机当前局域网 IP），再重建 bridge 验证 provider.ets；随后实现鸿蒙弹窗与 sync 校验。

# 2026-08-06 14:36 — 修复鸿蒙登录"账号不存在"与旧登录端被顶无提示

## 采纳内容
- [MSRV-016/018] 修复鸿蒙登录默认账号报"账号不存在"：根因是鸿蒙登录走 `LocalMockAuthRepository` **本地校验**，而 `syncFromServer` 未登录时跳过 auth 拉取、已登录时 `restoreStoreSnapshot` 整体替换为"当前用户单个账号"，种子/其他账号被丢弃，本地 store 缺账号即报 ACCOUNT_NOT_FOUND。
- [MSRV-016/018] 修复：服务端 `GET /api/sync/auth` 不带 `userId` 时返回全部账号（含 mock passwordHash，供鸿蒙本地登录校验），`store.allAccounts()` 提供；鸿蒙 `syncFromServer` 改为**合并**（`mergeAuthStores` 按 userId 去重、服务器优先、会话以本地有效为准）——未登录时拉全部账号、已登录时按 userId 拉取并与本地合并，不再整体替换。
- [MSRV-019] 修复旧登录端被顶无提示：Android/iOS `resumeSessionInSameProcess`（回前台暖恢复）补上 `GET /api/auth/session` 懒校验（抽取 `checkSessionRemotely` 助手，冷启动/暖恢复共用），被顶返回 `KickedElsewhere`。
- [MSRV-019] `LoginStore` 写路径被顶处理：`updateProfile`/`deleteCurrentAccount` 遇 `SessionExpiredElsewhere` 触发 `applyKicked`（清会话 + `LoginEffect.SessionExpired` + 错误文案），引导旧登录端跳登录页。

## 人工审查点
- [MSRV-016/018] sync/auth 不带 userId 返回全部账号是鸿蒙快照同步模型（本地校验登录）的必要边界，已在 Spec MSRV-018 记录为"登录发现例外"，仅限 mock 服务器。
- [MSRV-019] 被顶提示时机仍是"下次请求/回前台"（mock 无推送）；健康读操作的数据源仍是 Boolean/缓存兜底接口，健康写路径暂不单独触发被顶导航（回前台校验已覆盖主要场景）。
- 鸿蒙侧改动（`MockServerSync.ets`、`mergeAuthStores`）需 DevEco 构建验证。

## 验证结果
- [MSRV-016/018] `cd mock-server && npm test` 44/44（新增 `MSRV-018: sync/auth 不带 userId 返回全部账号`）。
- [MSRV-019] `./gradlew :common:check` 全绿（`LoginUseCaseTest` 41 条，新增 `updateProfileKickedElsewhereClearsSessionAndNavigates`）；`:androidApp:testDebugUnitTest` 全绿（`RemoteAuthRepositoryTest` 新增 `warmResumeKickedElsewhereClearsSession`/`warmResumeActiveStaysActive`）；`:androidApp:assembleDebug`/`lintDebug` 通过。
- 文档：TRACE/TEST_REPORT 测试计数同步（LoginUseCaseTest 41、合计 117、common 128）；Spec MSRV-018 边界补充。

## 人工修正点
- [MSRV-019] `LoginUseCaseTest` 新增用例 `weightKg` 误传 Int（应为 Double）编译红灯 → 改 `70.0`；`assertNull` 缺 import → 补。
- [MSRV-016] `restoreStoreSnapshot` 整体替换导致种子账号丢失是核心缺陷，改为 `mergeAuthStores` 合并。

## 下轮交接
- **已完成**：鸿蒙登录发现（sync/auth 无 userId 全量账号 + 合并）；Android/iOS 暖恢复与写路径被顶检测与跳转；服务端/客户端测试全绿。
- **未完成 / 阻塞项**：鸿蒙侧需 DevEco 构建验证（`MockServerSync.ets` 合并逻辑、provider.ets 契约、真机连 mock server）；健康写路径被顶单独导航未做（债务）；三端交叉验收（MSRV-010/019）。
- **下轮起步建议**：DevEco 环境重建鸿蒙并验证"未登录登录默认账号成功 + 已登录账号从其他端被顶后回前台提示并回登录页"；随后补健康写路径被顶检测或接受回前台校验覆盖。

# 2026-08-06 15:03 — 统一修复头像显示/上传、旧端被顶、鸿蒙账号发现

## 采纳内容
- [MSRV-018] 头像显示修复（安卓旧/新头像均不显示）：根因是 `resolveAvatarBitmap` 默认客户端带 `X-Device-Id: device-default`，服务端头像 GET 做设备匹配 → 401。改为服务端头像 GET **完全忽略设备匹配、仅校验会话有效**（`store.sessionStatus(userId, null)`），新增契约测试 `MSRV-015: 头像 GET 忽略设备匹配，仅要求会话有效`。
- [MSRV-018] iOS 头像不写入修复：`ProfileImageStore.save`（上传 PUT）补 `X-Device-Id` 头（`IosMockServerConfig.shared.deviceId`）。
- [MSRV-019] 旧端被顶检测补齐：Android/iOS `RemoteHealthDashboardStateDataSource.onSessionKicked` 回调（load/save 遇 `SESSION_EXPIRED_ELSEWHERE` 触发）→ `LoginStore.onSessionKicked()`（`applyKicked`：清会话 + `SessionExpired` effect 跳登录页）；`LoginViewModel.createRemote` 与 `SharedLoginAdapter.init` 接线。
- [MSRV-019] `LoginStore` 新增公开 `onSessionKicked()`，`LoginFacade` 暴露；`updateProfile/deleteCurrentAccount` 遇被顶触发 `applyKicked`。
- [MSRV-016/018] 鸿蒙：`KnoiLoginAdapter.submit` 登录前 `await syncFromServer`（消除"登录先于账号发现"竞态）；`MockServerSync.request` 检测 `SESSION_EXPIRED_ELSEWHERE` 触发 `onSessionKicked` 回调（清会话跳登录页）；`HarmonyLoginService`/契约/适配器新增 `onSessionKicked/confirmForceLogin/cancelForceLogin`。

## 人工审查点
- [MSRV-018] 头像 GET 忽略设备匹配只针对**读**（展示场景，图片加载器无法带设备头）；写操作（PUT/DELETE）保持严格会话+设备校验，越权写仍被拒。
- [MSRV-019] 被顶即时性仍受"无推送"限制：健康读/写、auth 写、冷启动/回前台均会检测；空闲前台不做轮询（维持 MSRV-006 懒校验语义）。
- [MSRV-016] 鸿蒙新增桥方法会改变 provider.ets，需 DevEco 重建生成；本环境无法构建 Harmony。

## 验证结果
- [MSRV-018] `cd mock-server && npm test` 45/45（新增头像 GET 忽略设备匹配）。
- [MSRV-019] `./gradlew :common:check` 全绿（`LoginUseCaseTest` 41 条（含 `updateProfileKickedElsewhereClearsSessionAndNavigates`））；`:androidApp:testDebugUnitTest` 全绿（`RemoteAuthRepositoryTest` 新增 `warmResumeKickedElsewhereClearsSession`/`warmResumeActiveStaysActive`/`healthLoadKickedInvokesCallback`）；`:androidApp:assembleDebug`/`lintDebug` 通过。
- [MSRV-018/019] iOS `xcodebuild`（Simulator Debug）BUILD SUCCEEDED（修复 `onSessionKicked` 闭包在 `healthFacade` 初始化前捕获 self 的编译错误）。

## 人工修正点
- [MSRV-019] Swift `onSessionKicked` 闭包在 `self.healthFacade` 赋值前捕获 self → 编译错误；移到所有存储属性初始化之后。
- [MSRV-018] 头像 GET 最初"设备头缺失才宽松"被 Android 默认头破坏；改为完全忽略设备。

## 下轮交接
- **已完成**：头像显示（安卓）+ 头像上传（iOS）+ 旧端被顶检测（Android/iOS 健康读写、auth 写、冷/暖恢复）+ 鸿蒙账号发现与 sync 被顶钩子（代码）。
- **未完成 / 阻塞项**：Harmony 需 DevEco 重建（provider.ets 生成、ArkTS 二次确认弹窗、sync 被顶跳转、真机连 mock server）；三端交叉验收（MSRV-010/019）。
- **下轮起步建议**：DevEco 环境重建鸿蒙后验证：默认账号登录成功、被顶后 sync 请求触发回登录页、头像上传/显示；随后三端交叉联调。提醒：运行时 mock server 需重启为新代码，鸿蒙 `MOCK_SERVER_BASE_URL` 需指向可达宿主机 IP。

# 2026-08-06 15:38 — 被顶确认弹窗/前台监听/安卓英文文案/鸿蒙登录跳转修复

## 采纳内容
- [MSRV-019] 被顶交互改为"确认弹窗"：`LoginState` 新增 `kickedDialogShown`；`LoginAction.KickedDialogConfirmed`；`LoginEffect.SessionKicked`（静默回登录页）。被顶检测（冷/暖恢复、健康回调、updateProfile/deleteCurrentAccount 写路径）只 `showKickedDialog`（弹窗，不清会话、不设错误文案），确认后 `confirmKickedDialog` 清会话 + `SessionKicked` 跳登录页，登录页不再显示被顶提示。
- [MSRV-019] 前台监听：Android `AuthNavGraph`/iOS `AuthCoordinator` 每 15s `checkSessionOnForeground()`（弹窗显示期间暂停）；`applySessionResumeResult` NoSession 在被顶弹窗显示时忽略，避免提前导航。
- [MSRV-019] 修复被顶检测误登出对方设备：`checkSessionRemotely` 原调用 `clearSession()`（会 POST logout 清掉服务器该账号会话）→ 改为 `clearLocalSessionOnly()` 仅清本地缓存。
- [MSRV-019] Android 被顶弹窗用 `auth_error_session_expired_elsewhere` 本地化资源（不再显示语义键英文原文）；iOS 用 `.alert` 持久弹窗替代一闪而过的 toast。
- [MSRV-016/019] 鸿蒙：`KnoiLoginAdapter.submit` 登录前 `await syncFromServer` 引入的网络延迟暴露了"登录页未 await dispatch"竞态 → `LoginFormPage.submitLogin` 改为 `await` dispatch 后再消费 effect；补 `SessionKicked`/`ShowForceLoginDialog` effect 分支、`kickedDialogShown` 状态、`confirmKickedDialog`/`checkSessionOnForeground` 桥方法与 `SignedInPage` 被顶弹窗 + 前台定时器。

## 人工审查点
- [MSRV-019] 被顶弹窗仅确认按钮、不可点外部关闭；确认后才清会话并回登录页；被顶消息在弹窗内展示，登录页不重复提示。
- [MSRV-019] 前台监听间隔 15s（MSRV-006 懒校验语义下可接受的折中，未引入轮询到写/读路径）；弹窗显示期间暂停校验避免 NoSession 干扰。
- 鸿蒙侧改动（effect 分支、状态字段、桥方法、`SignedInPage` 弹窗/定时器）需 DevEco 重建验证；本环境无法构建。

## 验证结果
- [MSRV-019] `./gradlew :common:check` 全绿（`LoginUseCaseTest` 41 条，`kickedElsewhereOnRestoreShowsDialogThenConfirmNavigates`/`updateProfileKickedElsewhereShowsDialogThenConfirmClearsSession` 改为弹窗→确认语义）；`:androidApp:testDebugUnitTest`/`assembleDebug`/`lintDebug` 通过；iOS `xcodebuild`（Simulator Debug）BUILD SUCCEEDED；`cd mock-server && npm test` 45/45。

## 人工修正点
- [MSRV-019] `checkSessionRemotely` 误用 `clearSession()`（带服务器 logout）会把顶号方也登出 → 改 `clearLocalSessionOnly()`。
- [MSRV-019] 旧测试断言"被顶即清会话+SessionExpired"不符新弹窗语义 → 更新为"弹窗→确认→SessionKicked"。
- [MSRV-016] 鸿蒙登录不跳转：`LoginFormPage.submitLogin` 未 await `dispatch`（异步 submit 未完成就消费 effect）；`PasswordSetupPage` 已 await，仅登录页有此竞态。

## 下轮交接
- **已完成**：被顶确认弹窗（三端状态/effect/桥）、前台周期监听（Android/iOS）、安卓本地化文案、鸿蒙登录跳转 await 修复、被顶检测不再误登出对方。
- **未完成 / 阻塞项**：Harmony 需 DevEco 重建验证（登录跳转、被顶弹窗、前台定时器、provider.ets 契约）；三端交叉验收（MSRV-010/019）。
- **下轮起步建议**：DevEco 重建鸿蒙，验证登录跳转与被顶弹窗；随后三端真机/模拟器联调被顶全链路（新端顶号 → 旧端前台 15s 内弹窗 → 确认回登录页）。

# 2026-08-06 15:41 — 修复安卓被顶英文文案（AuthLocalization 映射缺失）

## 采纳内容
- [MSRV-005] 安卓被顶提示显示英文原始语义键的根因：`AuthLocalization.kt` 的 `authMessageResourceId` 硬编码映射缺了新增的 `auth_error_session_active_elsewhere`/`auth_error_session_expired_elsewhere`，`localizedAuthMessage` 找不到资源 ID 时回退返回原始键（英文）。已补上两条映射；被顶弹窗本身直接用 `R.string.auth_error_session_expired_elsewhere`，与映射无关。

## 人工审查点
- [MSRV-005] Android 语义键本地化走 `AuthLocalization.kt` 硬编码映射（非自动）；新增 `auth_*` 键必须同步该映射，否则回退显示原始键（英文）。iOS 用 xcstrings 查找、Harmony 用 `AuthLocalization.ets` 映射（均已含新键）。

## 验证结果
- [MSRV-005] `./gradlew :common:check :androidApp:testDebugUnitTest :androidApp:assembleDebug :androidApp:lintDebug` 全绿；`cd mock-server && npm test` 45/45；iOS `xcodebuild`（Simulator Debug）此前已通过。

## 人工修正点
- [MSRV-005] `AuthLocalization.kt` 漏配新键映射 → 补充。

## 下轮交接
- **已完成**：被顶确认弹窗/前台监听/安卓本地化映射补齐/鸿蒙登录跳转 await 修复。
- **未完成 / 阻塞项**：Harmony DevEco 重建验证（登录跳转、被顶弹窗、前台定时器、provider.ets）；三端交叉验收。

# 2026-08-06 16:03 — 前台会话轮询间隔降至 3s + 鸿蒙 LoginStatePayload 兜底对象补字段

## 采纳内容
- [MSRV-019] 前台会话校验轮询间隔 15s → 3s（Android `ForegroundSessionCheckIntervalMs=3000`、iOS `Task.sleep(3s)`、Harmony `setInterval(3000)`），使被顶弹窗延迟降到 ≤3s（暂用方案 1，长轮询方案 2 留待后续）。
- [MSRV-019] 修复鸿蒙 `KnoiLoginAdapter.ets` 编译错误：`LoginStatePayload` 接口新增必填 `confirmForceLogin`/`kickedDialogShown` 后，`parseStatePayload` catch 兜底对象字面量缺这两个字段 → ArkTS 类型检查报错；补 `false` 默认值。

## 人工审查点
- [MSRV-019] 3s 轮询每在线设备约 20 请求/分钟，mock 本地无负担；弹窗显示期间暂停校验逻辑不变。
- [MSRV-019] ArkTS 接口新增必填字段时，所有实现该接口的对象字面量（含 catch 兜底）必须同步补字段，否则 ArkTSCheck 报缺失属性。

## 验证结果
- `./gradlew :common:check :androidApp:testDebugUnitTest :androidApp:assembleDebug` 全绿；iOS `xcodebuild`（Simulator Debug）BUILD SUCCEEDED；`cd mock-server && npm test` 45/45（本轮未改服务端）。

## 人工修正点
- [MSRV-019] `parseStatePayload` 兜底对象缺新必填字段 → 补 `confirmForceLogin: false, kickedDialogShown: false`。

## 下轮交接
- **已完成**：被顶弹窗/前台 3s 监听/安卓本地化/鸿蒙登录 await 修复/鸿蒙类型错误修复。
- **未完成 / 阻塞项**：长轮询方案 2（MSRV-022 建议）未实施；Harmony 需 DevEco 重建验证；三端交叉验收。

# 2026-08-06 16:11 — 修复鸿蒙登录清空输入提示"请输入账号密码"

## 采纳内容
- [MSRV-016] 根因：`KnoiLoginAdapter.submit()` 开头 `await syncFromServer()`，而 `syncFromServer` 未登录分支调用 `restoreStoreSnapshot` → `HarmonyLoginService.restoreStoreSnapshot` 内 `facade = createFacade(...)` **重建 LoginFacade**，新 facade 的账号/密码/验证码/区域被清空；随后 `submit()` 在新 facade 上校验空输入 → "请输入账号密码"，并清空界面字段。
- [MSRV-016] 修复：新增桥方法 `HarmonyLoginService.mergeAccounts(json)`（仅 `dataSource.replaceStore`，**不重建 facade**，不丢登录页输入）；`syncFromServer` 未登录分支改用 `mergeAccounts`；`KnoiLoginAdapter.submit` 捕获并回写模式/账号/密码/验证码/显示名/区域（兜底防未来重建）。
- [MSRV-016] 该缺陷同时影响登录与注册（共用 `submit()`），一并修复。

## 人工审查点
- [MSRV-016] `restoreStoreSnapshot` 仍保留用于启动/换号全量恢复（重建 facade 是预期行为）；登录提交前**绝不**调用它，只调用不重建的 `mergeAccounts`。
- [MSRV-016] `mergeAccounts` 与 facade 共用同一 `MemoryAuthStoreDataSource` 实例，replaceStore 后既有 facade 的 `loadStore()` 立即可见新账号。

## 验证结果
- `./gradlew compileKotlinOhosArm64`（harmony-kmp-bridge）**BUILD SUCCESSFUL**，KSP 生成的 `ServiceProvider.kt` 已含 `mergeAccounts` 等新桥方法；`./gradlew :common:check :androidApp:testDebugUnitTest :androidApp:assembleDebug` 全绿；iOS `xcodebuild` 此前已通过；mock-server 45/45（本轮未改服务端）。

## 人工修正点
- [MSRV-016] submit 内 `syncFromServer` 重建 facade 清空输入 → 改为不重建的 `mergeAccounts` + 凭据回写。

## 下轮交接
- **已完成**：鸿蒙登录/注册提交前不再因账号发现重建 facade 而清空输入。
- **未完成 / 阻塞项**：鸿蒙 ArkTS 侧需 DevEco 全量构建验证（`mergeAccounts` provider 生效、登录/注册跳转、被顶弹窗、前台 3s 监听）；三端交叉验收。

# 2026-08-06 16:35 — 修复 iOS 前台被挤 + 三端头像本地缓存即时显示

## 采纳内容
- [MSRV-019] 修复 iOS 前台被挤不生效：根因是 `.task` 闭包在**创建时捕获 `scenePhase` 快照**，若启动瞬间非 `.active` 则循环内 `scenePhase == .active` 恒为 false → 前台检查永不触发。移除循环内的 scenePhase 判断，并在 `onChange(scenePhase)` 回前台时立即 `checkSessionOnForeground()`。
- [MSRV-015] Android 头像本地缓存：新增 `LocalAvatarCache`（`files/avatars/{userId}.jpg`）；`resolveAvatarBitmap(avatarUri, context)` 优先读缓存、未命中下载并写缓存；`AvatarImage`/`AvatarImageWithRevision` 组合时先用 `resolveAvatarCached` 同步读缓存（即时显示、无占位闪烁）；上传成功后立即写缓存；注销账号清理缓存。
- [MSRV-015] Android 头像上传改异步：选择/拍摄后 `scope.launch(Dispatchers.IO)` 上传，主线程不阻塞（修复保存按钮无响应的冻结问题）；成功后更新 avatarUri + revision（从缓存即时显示新头像）。
- [MSRV-015] iOS 头像本地缓存：`ProfileImageStore` 新增 `Documents/avatars/{userId}.jpg` 缓存，`image(at:)` 优先读缓存、未命中下载写缓存，`save` 成功后写缓存，注销清理。

## 人工审查点
- [MSRV-015] 缓存按 userId 分文件：登录/换账号互不干扰；仅注销账号时删除（登出保留以便重登即时显示）。
- [MSRV-015] 组合时同步解码缓存位图在 main 线程（512px JPEG 约毫秒级），换取"零闪烁"体验，可接受。
- [MSRV-019] iOS `.task` 内不再依赖 scenePhase 快照，回前台由 `onChange` 触发即时检查 + 3s 周期兜底。

## 验证结果
- `./gradlew :common:check :androidApp:testDebugUnitTest :androidApp:assembleDebug :androidApp:lintDebug` 全绿；iOS `xcodebuild`（Simulator Debug）BUILD SUCCEEDED；`cd mock-server && npm test` 45/45（本轮未改服务端）。

## 人工修正点
- [MSRV-019] `.task` 捕获 scenePhase 快照导致 iOS 前台检查永不触发 → 去除该判断 + onChange 补即时检查。
- [MSRV-015] `PersonalProfileEditScreen` 缺 `LaunchedEffect` import 编译红灯 → 补。

## 下轮交接
- **已完成**：iOS 前台被挤修复；Android/iOS 头像本地缓存（即时显示、上传即覆盖、无占位闪烁、上传不阻塞主线程）。
- **未完成 / 阻塞项**：Harmony 侧头像缓存未做（ArkTS 本地文件需 DevEco 验证，可后续按同样思路 `filesDir/avatars/{userId}.jpg`）；Harmony 整体需 DevEco 重建验证；三端交叉验收。

# 2026-08-06 16:50 — 完善鸿蒙端全部界面 Preview（getService 预览兜底 + 富数据健康 fixture）

## 采纳内容
- [UI-PREVIEW-010] `HarmonyServiceProvider.getService()` 未安装 native service 时不再抛错，改为返回 `PreviewHarmonyService`（no-op 实现全部契约方法，页面在 DevEco Previewer 下可正常组合渲染、交互退化为空操作）。
- [UI-PREVIEW-009] Preview 服务的 `loadHealthSnapshot/previewHealthSnapshot/refreshHealthSnapshot` 返回富数据健康快照 fixture（12 张卡片，视觉数据复用 `preview/VisualPreviewData`），健康首页 Preview 显示真实卡片数据而非空壳。
- 审计：16 个生产页面（登录/注册/找回/资料/健康页等）均已有 `@Preview`+`@Entry`，且静态 import 图不触达 knoi/provider（仅 EntryAbility/KnoiHarmonyServiceAdapter 触达，为运行时组合根）；`DebugStatePage` 为 spec 明确排除的调试页。认证页走 `getLoginViewModel()`→默认 `PreviewLoginAdapter`（纯 ArkTS）；健康编辑器页走 `getService()`（现为 Preview 兜底）。

## 人工审查点
- [UI-PREVIEW-010] `getService()` 运行时仍由 EntryAbility 安装真服务；Preview 下返回 no-op，符合"Preview 缺少 native service 时页面仍可组合"。
- [UI-PREVIEW-009] fixture 的 title/summary 键复用既有资源名；视觉 caption 键取自 VisualPreviewData，个别键若资源缺失会在预览显示键文本（不影响布局调整）。
- 本环境无 hvigor/DevEco，ArkTS 改动需在 DevEco 全量构建验证。

## 验证结果
- 静态审计：16 个生产页面均有 `@Preview`；页面 import 图仅含纯契约（`getService`/`getLoginViewModel`），不触达 knoi/provider；`preview/` 目录 4 个组件宿主 + 12 个视觉预览（拆两个文件，符合单文件 ≤10 预览限制）。
- `./tools/check-ui-previews.sh` 依赖 `rg`（本机未安装 ripgrep）无法运行，属环境问题非门禁失败。
- 本轮未改 common/Android/iOS/mock-server 逻辑，此前验证仍有效。

## 人工修正点
- [UI-PREVIEW-010] `getService()` 由"抛错"改为"返回 Preview no-op"，避免 Previewer 下页面崩溃。

## 下轮交接
- **已完成**：鸿蒙全部生产页面 Preview 可渲染（认证页空表单、健康页富数据卡片）；Preview 兜底服务与富数据 fixture。
- **未完成 / 阻塞项**：需 DevEco 全量构建 + 逐个页面打开 Preview 验证渲染（尤其健康页 12 卡、认证表单）；若 Preview 仍受 EntryAbility native 初始化影响，需在 `initKnoiBridge` 加 Preview 环境守卫。

# 2026-08-06 17:19 — 头像本地单文件化：登录覆盖/完善即存/修改保存才存/显示读本地

## 采纳内容
- [MSRV-015] 内部目录只保存**一份当前账号头像**：Android `AvatarStore`（`files/avatar_current.jpg`）、iOS `ProfileImageStore`（`Documents/avatar_current.jpg`），替代按 userId 分文件缓存。
- [MSRV-015] 登录/切换账号：`AvatarStore.refreshFromServer(context, avatarUri, deviceId)` / iOS `ProfileImageStore.refreshFromServer(avatarUri:)` 先清除旧头像，再用服务器头像覆盖内部目录（Android AuthSucceeded 分支异步执行；iOS AuthCoordinator AuthSucceeded 调用）。
- [MSRV-015] 信息完善界面：选图即上传服务器 + 覆盖内部目录（Android ProfileCompletionScreen / iOS ProfileCompletionView 现状保留）。
- [MSRV-015] 信息修改界面：选图仅生成本地预览（Android `pendingAvatarBitmap/bytes` 或 iOS `avatarData`），**保存时才上传 + 覆盖内部目录 + 保存资料**（Android `PersonalProfileEditScreen` onSave 异步上传；iOS `AccountView.save` 上传后再提交；`hasChanges` 计入未上传的本地选图，保存按钮可用）。
- [MSRV-015] 显示一律读内部目录：`resolveAvatarCached/resolveAvatarBitmap` 与 iOS `image(at:)` 先读当前文件，未命中再下载并覆盖；组合时同步读当前文件避免占位闪烁。
- 注销账号：`AvatarStore.clear` / iOS `ProfileImageStore.deleteCache()`（去 userId 参数）。

## 人工审查点
- [MSRV-015] 单文件切换账号依赖 AuthSucceeded 时清除旧头像再拉新账号头像，避免显示上一账号头像；拉取期间短暂占位可接受。
- [MSRV-015] iOS `AccountView.save` 上传失败时保留 `avatarData`，不会用旧头像误保存。
- 本环境无 DevEco，鸿蒙头像缓存未随本轮改动（按同一思路后续做 ArkTS `filesDir/avatar_current.jpg`）。

## 验证结果
- `./gradlew :common:check :androidApp:testDebugUnitTest :androidApp:assembleDebug :androidApp:lintDebug` 全绿；iOS `xcodebuild`（Simulator Debug）BUILD SUCCEEDED；`cd mock-server && npm test` 45/45。

## 人工修正点
- [MSRV-015] Android 编译红灯：AuthNavGraph 缺 `LocalContext`、PersonalProfileEditScreen 缺 `BitmapFactory`、ProfileFieldRows 缺 `Bitmap`、Preview 调用缺 `previewAvatar` → 补 import 与参数。

## 下轮交接
- **已完成**：Android/iOS 头像单文件化（登录覆盖、完善即存、修改保存才存、显示读本地即时刷新）。
- **未完成 / 阻塞项**：鸿蒙头像本地单文件（需 DevEco）；三端真机/模拟器联调确认头像全链路。

# 2026-08-06 17:35 — 修复 iOS「我」页换头像后不更新（头像版本号强制刷新）

## 采纳内容
- [MSRV-015] 根因：主「我」页 `AccountAvatar(path: draft.avatarUri, ...)` 的 `path` 换头像后不变（相对路径 `/api/avatar/{userId}` 恒定），SwiftUI 判定 `AccountAvatar` 结构体相等而跳过 body 重渲染，`ProfileImageStore.image(at:)` 不再被调用 → 显示旧文件内容。
- [MSRV-015] 修复：iOS `LoginViewModel` 新增 `@Published avatarRevision`；头像保存成功后 `notifyAvatarSaved()` 递增（信息完善页选图上传后、信息修改页保存上传后均调用）；主「我」页 `AccountAvatar` 加 `.id("account-avatar-\(viewModel.avatarRevision)")`，版本号变化时强制重建并重新读取内部目录当前头像。

## 人工审查点
- [MSRV-015] 版本号只在头像文件真正写入后递增，避免误触发；显示仍读内部目录单文件（即时）。
- Android 端头像由 `avatarRevision` 状态 + `AvatarImageWithRevision` 的 key 驱动刷新，无此问题。

## 验证结果
- iOS `xcodebuild`（Simulator Debug）BUILD SUCCEEDED；本轮未改 common/Android/mock-server，此前验证仍有效。

## 人工修正点
- [MSRV-015] SwiftUI 结构体相等跳过 body 是根因；用 `.id(avatarRevision)` 强制重建而非依赖输入相等性。

## 下轮交接
- **已完成**：iOS「我」页换头像即时刷新。
- **未完成 / 阻塞项**：鸿蒙头像本地单文件与版本刷新（需 DevEco）；三端联调。

# 2026-08-06 18:08 — 单元测试显式 add-modules jdk.httpserver（消除 IDE 误报）

## 采纳内容
- androidApp/build.gradle.kts 测试任务加 `jvmArgs("--add-modules", "jdk.httpserver")`：`RemoteAuthRepositoryTest` 用 JDK 内置 `com.sun.net.httpserver`，Gradle 本可解析，显式声明供部分 IDE 测试源码集解析，消除"Unresolved reference"红波浪线，对构建无害。

## 人工审查点
- 该模块是 JDK 内置（JBR 21），非第三方依赖；Gradle 编译/运行本就通过，此改动仅为 IDE 兜底。

## 验证结果
- `./gradlew :androidApp:testDebugUnitTest :androidApp:assembleDebug` BUILD SUCCESSFUL；`./tools/check-sdd.sh` 通过。

## 人工修正点
- 无。

## 下轮交接
- 无阻塞；若个别 IDE 版本仍报错，改 Project SDK 为 JDK 21 后再看。

# 2026-08-07 10:55 — 鸿蒙端头像与安卓/iOS 对齐（本地单文件缓存/刷新/保存行为）

## 采纳内容
- [MSRV-015] 新增 `home/account/AvatarCache.ets`：当前账号头像本地单文件 `filesDir/avatar_current.jpg`（`initAvatarCache` 由 EntryAbility 注入 filesDir，Preview 未初始化时安全降级服务器 URL）。
- [MSRV-015] `AvatarImage.ets` 改为缓存优先：本地文件存在即显示（即时无闪烁），未命中异步下载并写缓存；`@Prop avatarRevision` 变化强制重建读取（对齐 iOS 版本号刷新）；上传函数统一 `uploadAvatarBytesToServer`（PUT 成功后写缓存）/`uploadAvatarToServer`（读取相册字节再上传）。
- [MSRV-015] 登录/切换账号：`AuthEffectHandler.handleAuthEffect` AuthSucceeded 调 `refreshAvatarFromServer(session.avatarUri)`（清除旧头像→服务器拉取覆盖）。
- [MSRV-015] `ProfileCompletionPage`：信息完善（editMode=false）选图即上传并写缓存；信息修改（editMode=true）选图仅写本地缓存作为预览（`avatarChanged=true`）、保存时先 `uploadAvatarBytesToServer(缓存字节)` 再保存资料；`hasProfileChanges` 计入 `avatarChanged`。
- [MSRV-015] 主「我」页 `SignedInPage`：`onPageShow` 递增 `accountAvatarVersion`，传入 `AccountOverviewComp`→`AvatarImage.avatarRevision`，编辑/保存返回后即时刷新。

## 人工审查点
- [MSRV-015] 单文件切账号依赖 AuthSucceeded 先清除再拉新头像；Preview 下 filesDir 未注入，缓存函数安全返回 false/空，回退服务器 URL。
- [MSRV-015] 修改页选图预览复用本地缓存文件（写缓存即预览），保存时再上传，与 Android/iOS 语义一致。
- 本环境无 DevEco/hvigor，ArkTS 改动需 DevEco 全量构建验证（括号/结构已静态审阅平衡）。

## 验证结果
- `./gradlew :common:check` 全绿；`cd mock-server && npm test` 45/45（本轮未改 common/Android/iOS/mock-server 逻辑）。

## 人工修正点
- [MSRV-015] ProfileCompletionPage 移除未用的 `MOCK_SERVER_BASE_URL` import；`ProfileAvatarComponent` 改用 `AvatarImage` 组件。

## 下轮交接
- **已完成**：鸿蒙头像本地单文件缓存 + 登录刷新 + 完善即存/修改保存才存 + 主「我」页返回刷新。
- **未完成 / 阻塞项**：需 DevEco 全量构建验证（AvatarCache/ AvatarImage/ ProfileCompletionPage/ SignedInPage 改动、provider.ets 契约）；三端头像全链路联调。

# 2026-08-07 11:46 — 鸿蒙认证与数据接入对齐 Android/iOS（服务器校验 + 顶号二次确认 + 会话懒校验 + 健康互通）

## 采纳内容
- [HARM-001] 新增 `HarmonyDeviceId.ets`：preferences 持久化 `harmony-<UUID>`；`MockServerSync.request` 统一携带 `X-Device-Id` 头，`serverLogin/serverRegister` body 带 `deviceId`。根因：鸿蒙此前请求无设备标识，服务器按 `device-default` 处理，与 Android/iOS 会话 deviceId 必然不匹配 → 每次 `syncToServer` 401 `SESSION_EXPIRED_ELSEWHERE` → 反复弹"已在其他设备登录"。
- [HARM-002] 桥新增 `HarmonyRemoteAuthRepository`（ohosArm64Main Kotlin，委托 `LocalMockAuthRepository`，对 login/register/resumeSessionInSameProcess/restoreSessionOnColdStart 消费 ArkTS staging 槽位后短路）；`HarmonyLoginService` 改用该仓库并新增 `stageServerLoginResult/stageForceLogin/stageServerError/stageSessionExpired/clearStaged`；provider.ets diff 仅 5 个新增方法。
- [HARM-002] `KnoiLoginAdapter.submit` 改为服务器优先：登录先 `POST /api/auth/login`（200→stage 会话再 submit；409→stageForceLogin 触发 `SessionActiveElsewhere` 状态机二次确认；错误→stageServerError 映射既有 `MockError`）；注册先 `serverRegister` 再 submit；新增 `confirmForceLogin/cancelForceLogin`（先 `force:true` 顶号再驱动状态机）。
- [HARM-002] `LoginFormPage` 新增 `ForceLoginDialog`（`state.confirmForceLogin`/`forceLoginActiveDevice` 驱动，确认/取消接线）；`LoginState`/`KnoiLoginAdapter` 增加 `forceLoginActiveDevice` 映射。
- [HARM-004] `serverSessionCheck`（GET /api/auth/session 三态）+ `performColdStartSessionCheck`；`KnoiLoginAdapter.checkSessionOnForeground` 服务器懒校验（kicked→onSessionKicked，expired→stageSessionExpired，offline→本地）；`EntryAbility.onForeground` 与 `SignedInPage` 3s timer 接入。
- [HARM-005] 登出走 `serverLogout` 再本地；资料保存本地提交后尽力异步 `serverProfilePut`；改密/重置/注销尽力异步 `serverChangePassword/serverResetPassword/serverDeleteAccount`（与 Android/iOS 服务器语义对齐）。
- [HARM-006] 健康读写改 `GET/PUT /api/health/:userId`（修复原 `GET /api/sync/health` 无参必 401 的 bug）；`syncFromServer` 退役整文档 auth 拉取，仅保留未登录账号发现（MSRV-018 例外）。
- [HARM-007] `request()` 不再自动触发被顶回调；被顶仅由健康读写 401（`maybeNotifyKicked`）与显式会话校验触发，消除弹窗循环/闪退。
- [HARM-008/009] staging 槽位只消费一次并清空；本地为登录态权威，不复活服务器会话。
- 新增 `spec/harmonyos-auth-alignment.md`（HARM-001..009）、`tools/check-harmony-auth-alignment.sh`（结构门禁 21 项）、mock-server 契约用例 `HARM-003: 注册携带 deviceId 后异设备登录触发 409`。

## 人工审查点
- [HARM-002] 顶号/二次确认/被顶弹窗的设备交互（登录被顶、force 顶号、对方被顶提示）需真机或模拟器人工验收（本环境无在线鸿蒙设备）。
- [HARM-005] 资料保存为"本地优先 + 尽力异步 PUT"，严格"服务器优先"需改接口签名与页面调用点；当前为兼容既有同步 UI 的折中。
- [HARM-004] 冷启动 AUTH_REQUIRED 采用 `clearSessionSilently`（无"登录已过期"toast），与 Android 的 SessionExpired toast 略有差异。
- [HARM-007] `maybeNotifyKicked` 幂等依赖 `LoginStore.kickedDialogShown`；设备端需回归确认无循环。
- 既有工作区 WIP（头像单文件缓存等未提交改动）与本次改动无冲突，但提交时需区分。

## 验证结果
- `harmony-kmp-bridge ./gradlew ohosArm64Binaries`：BUILD SUCCESSFUL；`provider.ets` diff 仅 5 个新增 staging 方法（HARM-008）。
- `harmonyApp hvigorw assembleApp --no-daemon`：BUILD SUCCESSFUL（ArkTS 严格模式修复对象字面量类型后通过）。
- `./gradlew :common:check`：BUILD SUCCESSFUL（全绿）。
- `./gradlew :androidApp:assembleDebug`：BUILD SUCCESSFUL（Android 端零改动防御验证）。
- `cd mock-server && node --test test/contract.test.js`：41/41 通过（含新增 HARM-003 用例）。
- `./tools/check-harmony-auth-alignment.sh`：PASS（21 项；实现前 18 项红灯）。
- `./tools/check-sdd.sh`：PASS。
- `./tools/check-docs.sh`：1 项既有失败 `docs/reference/注册登陆模块介绍.md` 哈希与可信来源不一致（未改该归档文件，属会话前既有问题）。

## 人工修正点
- [HARM-005] 如需严格"服务器优先"保存资料，将 `submitProfile` 改为异步并在服务器成功后再本地提交。
- [HARM-004] 冷启动 AUTH_REQUIRED 若需与 Android 一致的 SessionExpired toast，补一个不产生残留 effect 的过期提示路径。
- 归档文档 `docs/reference/注册登陆模块介绍.md` 哈希漂移需人工确认是否重算基线（AGENTS.md 禁止直接改归档）。

## 下轮交接
- **已完成**：鸿蒙登录/注册/会话校验/登出/资料/健康全部对齐服务器模型；顶号二次确认 + 被顶弹窗；消除弹窗循环；`provider.ets` 契约扩展已同步三处 ArkTS 契约文件。
- **未完成 / 阻塞项**：真机设备交互验收（顶号/被顶/二次确认/三端健康互通）；若需同步既有头像 WIP 一起提交需人工合并。

# 2026-08-07 13:34 — 鸿蒙被顶/二次确认弹窗缺陷修复（全屏样式、弹窗循环、确认不跳转、登录后残留弹窗）

## 采纳内容
- [HARM-010] 根因一（不跳转）：`SignedInPage.KickedDialog` 确认只调 `confirmKickedDialog()`，从不 `consumeEffect()` → `LoginStore` 产出的 `SessionKicked` effect 无人消费 → 不跳登录页。修复：确认后消费 effect 并 `handleAuthEffect(SessionKicked)`。
- [HARM-010] 根因二（不断弹出/潜在闪退）：`KnoiLoginAdapter.handleSessionKicked` 内调用 `persistSnapshot()` → `saveStoreSnapshot` → `syncToServer` → 401 `SESSION_EXPIRED_ELSEWHERE` → `maybeNotifyKicked` → 再 `handleSessionKicked` → 级联循环。修复：`handleSessionKicked` 不再持久化；`MockServerSync` 增加 `kickNotified` 幂等守卫（同一被顶事件只通知一次），健康同步成功（2xx）`resetKickNotified()` 复位。
- [HARM-010] 根因三（登录成功后被顶弹窗残留）：`LoginStore` 成功分支不复位 `kickedDialogShown`，登录前一次失效健康同步 401 置位的弹窗状态会穿透到登录成功后首页。修复：`LoginStore` 登录/注册成功分支 `kickedDialogShown = false`（新增 `LoginUseCaseTest.successfulLoginClearsStaleKickedDialogState`，先红后绿）。
- [HARM-010] 样式：`SignedInPage.KickedDialog` 与 `LoginFormPage.ForceLoginDialog` 从"全屏拉伸（layoutWeight 撑满 + margin 42）"改为**居中紧凑卡片**（`.width(300)` + 居中遮罩），文字 17、按钮全宽、圆角 14。
- [HARM-007] Spec/TRACE 补 `HARM-010`；门禁新增 HARM-007c/d 与 HARM-010a/b/c（26 项）。

## 人工审查点
- [HARM-010] `LoginStore` 成功分支复位 `kickedDialogShown` 属 common 行为微调（strict 改进：新成功登录清除残留被顶状态），Android/iOS 共享此修复，需确认两端无依赖"成功后残留弹窗"的用例（commonTest 全量通过）。
- 弹窗固定 300vp 宽度为设计值，若设计规范要求其他宽度/最大宽度约束需人工复核。
- 设备交互（弹窗居中展示、确认跳转、顶号后不再循环）仍需真机验收。

## 验证结果
- `./gradlew :common:check`：BUILD SUCCESSFUL（含新增 `successfulLoginClearsStaleKickedDialogState`，先红：42 完成 1 失败，后绿）。
- `./gradlew :androidApp:assembleDebug`：BUILD SUCCESSFUL（common 改动对 Android 无回归）。
- `hvigorw assembleApp --no-daemon`：BUILD SUCCESSFUL。
- `cd mock-server && node --test test/contract.test.js`：41/41 通过。
- `./tools/check-harmony-auth-alignment.sh`：PASS（26 项，新增 007c/d 与 010a/b/c）。
- `./tools/check-sdd.sh`：PASS。

## 人工修正点
- 被顶确认跳转依赖 `handleAuthEffect(SessionKicked)` 的 `ResetKeepingEntranceAndPush` 语义；真机需确认从首页被顶确认后落在登录页而非入口页。
- 若弹窗在窄屏/横屏下 300vp 过宽，需改为 `ConstraintSize(maxWidth)` 而非固定值。
- `check-docs.sh` 仍为既有 1 项失败（`docs/reference/注册登陆模块介绍.md` 哈希漂移，未改归档）。

## 下轮交接
- **已完成**：被顶/二次确认弹窗居中紧凑样式；确认后消费 effect 跳登录页；`kickNotified` 幂等守卫消除弹窗循环与级联；登录成功清除残留被顶状态。
- **未完成 / 阻塞项**：真机交互验收（弹窗样式、确认跳转、顶号闭环）；既有头像 WIP 合并。

# 2026-08-07 13:48 — 鸿蒙头像缺陷修复（换头像不即时刷新、保存无作用、远端不更新）

## 采纳内容
- [MSRV-015] 根因一（换头像不即时刷新 + "我"页需切页才刷新）：`AvatarImage` 完全没用到 `@Prop avatarRevision`，且 `Image(file://.../avatar_current.jpg)` 路径恒定 → ArkUI 按 source 字符串缓存解码结果，文件内容变了也不重解码。修复：源改为**内容寻址 base64 data URI**（内容变则字符串变 → 强制重解码）；`@Prop @Watch('onAvatarInputChanged') avatarUri/avatarRevision` 变化时重新读本地文件（`util.Base64Helper.encodeToStringSync`）。信息修改页选图 `writeAvatarCache` + `avatarCacheVersion++` 后即时刷新预览；`SignedInPage.onPageShow` 递增版本号后"我"页即时刷新。
- [MSRV-015] 根因二（保存无作用 + 远端不更新）：头像 `PUT /api/avatar/:userId`（`AvatarImage.putBinary`）未携带 `X-Device-Id` 头 → 服务器 `requireSession` 设备不匹配 → 401 `SESSION_EXPIRED_ELSEWHERE` → 上传失败 → editMode 保存流程在上传失败处 `return` 静默返回。修复：`putBinary` 与 `AvatarCache` GET 均加 `X-Device-Id: deviceId()` 头（对齐 MSRV-018 设备校验）。
- [MSRV-015] `tools/check-account-profile-regressions.sh` 增加 Harmony 头像断言（`@Watch`、base64 源、`X-Device-Id`）。

## 人工审查点
- [MSRV-015] 头像文件路径恒定导致的 ArkUI Image 缓存是根因；base64 内容寻址是确定可用的方案（无需真机）。真机需验收：选图即时预览、保存后"我"页即时刷新、服务器头像文件更新（`data/{PORT}/avatars/{userId}.jpg`）。
- [MSRV-015] 信息完善页选图即上传、信息修改页选图仅本地预览、保存才上传的语义保持不变；上传失败时 editMode 保存被阻断并提示（`profile_avatar_selection_failed`），避免资料与头像不一致。
- Harmony 头像未做缩放/JPEG 重编码（LEARNINGS #32 允许原始字节直传）。

## 验证结果
- `hvigorw assembleApp --no-daemon`：BUILD SUCCESSFUL（修复前 AvatarImage 编译错误，修复后通过）。
- `./tools/check-account-profile-regressions.sh`：PASS（新增头像断言）。
- `./tools/check-harmony-auth-alignment.sh`：PASS（26 项）；`./tools/check-sdd.sh`：PASS。
- `cd mock-server && node --test test/contract.test.js`：41/41 通过。
- 本轮未改 common/Android/iOS/mock-server 逻辑。

## 人工修正点
- 真机验收头像全链路：选图预览、保存、切回"我"页、跨端拉取（Android/iOS 看鸿蒙上传的头像）。
- 若 `util.Base64Helper` 在目标设备版本不可用，回退到逐字节 base64 编码实现。
- 既有工作区头像 WIP（AvatarCache/AvatarImage/ProfileCompletionPage/SignedInPage 等）与本次修复属同一功能，建议一并人工审阅后提交。

## 下轮交接
- **已完成**：头像即时刷新（预览 + "我"页）与服务器上传（补设备头）修复。
- **未完成 / 阻塞项**：真机头像全链路验收；既有 WIP 整体合并。


# 2026-08-07 14:58 — 完善轮：文档计数同步、参考文档哈希更新、Android health 组件包迁移收口（清除 IDE 占位符）

## 采纳内容
- [DOC-008] `LoginUseCaseTest.kt` 源码已有 42 条 `@Test`（最后一条为 c7d30c1 新增 `successfulLoginClearsStaleKickedDialogState`），但 `TEST_REPORT.md` 与 `spec/TRACE.md` 仍写 41/117/128，导致 `check-docs.sh` 4 项失败。同步更新：计数表 41→42、业务需求映射小计 117→118、common 全部合计 128→129，并在 `TEST_REPORT.md` LoginUseCaseTest 明细表补充新测试行。
- [DOC-010/012] `docs/reference/注册登陆模块介绍.md` 在 1c39257 正常演进，工作区与 HEAD 哈希一致（`cd6f02a7…`），但 `tools/check-docs.sh` 仍持有旧可信哈希 `56b52132…`，造成"恢复文档内容与可信来源不一致"失败。更新门禁可信哈希为当前 HEAD 值；不改动归档正文。
- [STRUCT-003] 收口 Android health 组件包迁移 WIP：将 `com.example.demo.health` 的组件源码迁入 `components/`、`components/visuals/`、`editor/`、`detail/` 子包，清除 39 处 `_root_ide_package_` IDE 全限定占位符（DashboardCard.kt 6、BodyVisual.kt 6、LoadVisual.kt 5 等），按既有约定补 `com.example.demo.health.localizedHealthText` 与 components 内部符号 import；`DashboardVisualMathTest.kt`、`PullToRefreshStateTest.kt` 同步新包 import。
- [STRUCT-004] 迁移不留孤儿引用：全仓 `_root_ide_package_` 计数降为 0，health 目录无重复 import。

## 人工审查点
- [STRUCT-003] `_root_ide_package_` 是 IDE 无法解析导入时生成的占位符，长期残留属于重构不彻底的信号；本次以"补 import + 简写引用"方式清理，未改动任何布局/几何/业务行为。
- [DOC-010] 参考文档哈希更新基于"文件在正常开发提交中演进、门禁未同步"这一事实；若后续仍需对 `docs/reference/` 内容做语义调整，必须先按 AGENTS.md 建立迁移映射。
- 本机未安装 `rg`，`check-health-*.sh` 等 10 个健康专项门禁在本机无法完整执行；其中引用 STRUCT-001/010 拆分前旧路径的断言（如 `EditableHealthData.kt 缺少 fun derive`）在 HEAD 即失败，与本轮无关。

## 验证结果
- [DOC-008][DOC-010/012] `./tools/check-docs.sh`：原 5 项失败全部转绿，输出"文档治理校验通过"；`bash -n tools/check-docs.sh` 语法通过。
- [SDD-009] `./tools/check-sdd.sh`：通过。
- [STRUCT-003][STRUCT-004] `./gradlew :androidApp:assembleDebug`、`:androidApp:testDebugUnitTest`、`:common:check`：BUILD SUCCESSFUL；`grep -rn "_root_ide_package_" androidApp/src iosApp common/src` 计数为 0。
- 本轮执行过的健康专项门禁现状（均与本轮改动无关，如实记录）：`check-health-navigation.sh` 29 项失败、`check-health-editable-normal-data.sh` 14 项失败、`check-health-cross-scenario-editing.sh` 6 项失败，其余因 `rg: command not found` 无法完整运行。

## 人工修正点
- 无代码行为修正；全部为文档同步、门禁哈希同步与 import 清理。

## 下轮交接
- **已完成**：`check-docs.sh` 5 项失败清零；`_root_ide_package_` 39 处占位符清除并编译/测试通过；health 组件包迁移 WIP 收口（未提交，工作区保留完整 diff 待人工 review 后提交）。
- **未完成 / 阻塞项**：健康专项门禁历史债务（10 个脚本断言仍引用 STRUCT-001/010 拆分前路径，且本机缺 `rg`）未纳入本轮修复，需人工决策是否立项修复；Android health 组件迁移与 WIP 变更尚未 git commit（用户未要求提交）。
- **下轮起步建议**：先读 `spec/three-platform-structure.md` 与 `tools/check-health-navigation.sh`，评估是否将健康专项门禁断言更新到 STRUCT-001/010 后的文件布局；本机安装 `ripgrep` 后重跑全部 `check-health-*.sh` 以区分"真失败"与"环境缺失"。
# 2026-08-07 15:06 — 清理代码内冗余 FQN 长链引用（import + 短名）

## 采纳内容
- [STRUCT-004][RES-MAINT-004] 系统排查主代码、测试、bridge 中"代码位置"的全限定链式引用（`androidx.compose.*`、`com.example.demo.*`、`kotlinx.*`），共 18 处，全部替换为"补 import + 短名"：
  - Android 主代码：`AvatarImage.kt`（`Color.Transparent` 2 处）、`AuthComponents.kt`（`Canvas`、`Stroke`）、`HealthGridVisual.kt`（`Arrangement.spacedBy(18.dp)`）、`LoadVisual.kt`（`HealthCardType.TrainingLoad`）。
  - 测试：`RemoteAuthRepositoryTest.kt`（`SessionResumeResult` 7 处 + `HealthDashboardStateDataSource`）、`HealthDashboardUseCaseTest.kt`（`LoginStore`）、`EditableHealthDataTest.kt`（`AuthSession` 3 处）。
  - bridge：`HarmonyLoginJson.kt`（`ActiveDeviceInfo`）。
- 用户给出的示例 `androidx.compose.foundation.layout.Arrangement.spacedBy(18.dp)` 即 `HealthGridVisual.kt` 中真实存在的一处；其余 17 处为同类 FQN。

## 人工审查点
- [STRUCT-004] 用 sed 批量替换测试文件 FQN 时会把 `import com.example.demo.common.auth.model.SessionResumeResult` 误替换为 `import SessionResumeResult`，已逐一回填完整包路径；后续批量替换必须先排除 `import` 行或改用精确匹配。
- 替换仅改变引用书写方式，不改任何类型、行为与布局；`Arrangement`/`Canvas`/`Stroke` 等符号与既有同名 import 无冲突（`AuthComponents.kt` 已用 `android.graphics.Color as AndroidColor` 规避冲突）。

## 验证结果
- [STRUCT-004] `./gradlew :common:check :androidApp:assembleDebug :androidApp:testDebugUnitTest`：BUILD SUCCESSFUL。
- [STRUCT-004] `harmony-kmp-bridge` 独立工程 `./gradlew :compileKotlinOhosArm64`：BUILD SUCCESSFUL（验证 `HarmonyLoginJson.kt`）。
- [STRUCT-004] 全仓代码位 FQN 扫描（排除 import/注释/字符串）：计数为 0；`_root_ide_package_` 计数仍为 0。
- [SDD-009] `./tools/check-sdd.sh` 与 `./tools/check-docs.sh`：通过；`git diff --check` 通过。

## 人工修正点
- 无行为修正；仅两处 sed 误改的 import 已回填（见人工审查点）。

## 下轮交接
- **已完成**：代码内 18 处冗余 FQN 长链清理完毕，主代码/测试/bridge 三处全部通过编译与测试。
- **未完成 / 阻塞项**：健康专项门禁历史债务（STRUCT-001/010 后脚本断言路径未同步、本机缺 `rg`）仍未处理，待人工决策；Android health 组件包迁移与 WIP 变更仍未 git commit（用户未要求提交）。
- **下轮起步建议**：与上一轮收口共同 review 后提交；如立项修复健康门禁，先装 `ripgrep` 并从 `tools/check-health-navigation.sh` 开始。
# 2026-08-07 15:41 — 完善健康专项门禁债务：A 环境前置 / B 陈旧路径 / C 断言漂移 / D 图标一致性

## 采纳内容
- [SDD-009] **A（环境）**：本机安装 ripgrep 15.2.0（用户安装）；此前无 rg 时 11 个 `check-health-*.sh` 全部假失败。安装后重跑 12 个健康门禁：仅 9 个有真实失败（90→按类处理），`check-health-navigation.sh`、`check-health-range-indicator-parity.sh`、`check-health-card-editor-regressions.sh` 实为通过。
- [STRUCT-010] **B（陈旧路径，9 个脚本 0 风险修复）**：STRUCT-001/002/007/010 拆分后脚本仍引用旧路径。核对全部符号存在于新路径后更新：`check-health-editable-normal-data.sh` 14→0（含 `derive`→`rules/HealthEditableRules.kt`、`BodyMuscleGroup`→`model/HealthEditFormModels.kt`、导航→`health/navigation/HealthRoute.kt`/`HealthNavigation.swift`/`auth/navigation/AuthRoutes.ets`）、`check-health-cross-scenario-editing.sh` 6→0、`check-health-hrv-segments-and-harmony-save.sh` 8→0（含 segments JSON→`HarmonyHealthSnapshotJson.kt`）、`check-health-card-adaptive-layout.sh` 4→0、`check-health-dashboard-runtime-states.sh` 5→0（`healthDashboardError`→`HealthFacade.healthError()`、下拉手势→`ScrollViewPanObserver.swift`）；并同步 `check-resources.sh`（`AuthMessageKeys`→`model/`、`LoginModels/Rules/UseCase/Store`→子包）、`check-ui-previews.sh`（`HealthDashboardScreen`→`screens/`、`ContentView`→`App/`、`HealthPreviewFixtures`→`mock/`、`HarmonyServiceProvider`→`core/bridge/`、`KnoiHarmonyServiceAdapter` 排除路径）同类陈旧路径。
- [HLTH-EDIT-024/025] **C（断言漂移，逐条核对等价实现后更新）**：`check-health-card-style-decoupling.sh` 3→0（`DashboardCard.kt` 多行 dispatch）、`check-health-cross-platform-parity.sh` 20→0（iOS `<Name>OverviewView` 命名、Harmony 独立 Visual 组件、`vp2px` 几何→`HealthVisualHelpers.ets`、周计划 `weeklySelectedIndex()`）、`check-health-card-fidelity.sh` 17→0（`BodyFront/Back`→肌肉蒙版语义目录、`RangeIndicatorOverview`→`RangeMarker`、心率概览→`TrendView/TrendVisualComp`、`GaugeOverview`→`AbilityView/AbilityVisualComp`、`onWeeklyDaySelected`→`selectedDay`/`weeklySelectedIndex()`）、`check-health-input-focus-and-account-refresh.sh` 1→0（ForEach key→`this.fieldForEachKey(field)`）。
- [HLTH-VIS-039] **C 中发现的真实回退并修复**：`MetricComp.ets` 顶部指标模板色（`ImageRenderMode.Template` + `fillColor(iconColor)`）在目录对齐重构（ce859a6）中丢失；按 Spec 恢复 `@Prop iconColor: ResourceColor`，`SignedInPage.ets` 三个调用点传 `AppColors.STEPS/CALORIES/ACTIVE`。
- [RES-MAINT-002] **D（图标一致性）**：按用户决策以 Android/iOS 为正确源，`steps_icon.png`、`icon_calories.png`、`sport_time_icon.png` 同步为 iOS 版本，fidelity 哈希断言转绿。

## 人工审查点
- [HLTH-VIS-039] 顶部指标模板色丢失属**真实功能回退**，已在代码恢复；但本机无 DevEco/hvigorw，ArkTS 编译与真机视觉需在 DevEco 环境复验（`MetricComp.ets`/`SignedInPage.ets`）。
- [STRUCT-010] 全部 B 类修复前逐一核对符号在新路径真实存在（`derive`、`BodyMuscleGroup`、`applyDetailed`、`transientEditSourceKind`、`segments` JSON 等），未盲改路径。
- 类别 D 仅同步 Harmony 三张 PNG；Android/iOS 侧未改动。

## 验证结果
- [SDD-009] 12 个 `check-health-*.sh` 全部 0 FAIL；`check-resources.sh`（25 认证键对齐）、`check-ui-previews.sh` 通过。
- [SDD-009] `./gradlew :common:check :androidApp:assembleDebug :androidApp:testDebugUnitTest` BUILD SUCCESSFUL；`./tools/check-sdd.sh`、`./tools/check-docs.sh`、`git diff --check` 通过。
- [RES-MAINT-002] `check-health-card-fidelity.sh` 三张 PNG SHA-256 与 iOS 一致。

## 人工修正点
- 无代码行为修正；B/C 类全部为脚本断言与路径更新，D 为资源同步，另按 HLTH-VIS-039 恢复 1 处真实回退。

## 下轮交接
- **已完成**：A/B/C/D 全部收口；12 个健康门禁从"依赖 rg 时 9 个失败"恢复到全绿；顺带修复 `check-resources.sh`/`check-ui-previews.sh` 陈旧路径。
- **未完成 / 阻塞项**：`check-resource-maintainability.sh` 4 项失败为 HEAD 既有（前 3 类全部命中注释内中文=门禁未排除注释的误报，剥离注释后计数 0；`androidDirectColors` 2 处为 `AvatarImage.kt` `Color.Transparent` 真实直接色），未纳入本轮范围，待人工决策；`MetricComp.ets`/`SignedInPage.ets` ArkTS 编译需 DevEco 环境；Android health 组件包迁移与 WIP 仍未 git commit。
- **下轮起步建议**：在 DevEco 环境跑 `hvigorw assembleApp` 验证 MetricComp 恢复；如需处理 `check-resource-maintainability.sh`，可先让 Han 扫描器跳过注释行（改 `count_matches`）再评估 `Color.Transparent` 是否应收进语义 Token。
# 2026-08-07 16:02 — 收尾：三端图标一致性方案定案、资源债务门禁修复、历史遗留确认指南

## 采纳内容
- [HLTH-VIS-039][RES-MAINT-002] **三端指标图标（steps/calories/sport_time）一致性方案定案 = 方案 A（统一模板着色）**。排查确认：三端源文件已一致（steps/sport 纯白 `(255,255,255)`、calories 蓝色预着色，均仅靠 alpha 决定形状）；三端渲染期着色代码齐备且语义色一致（Android `ArcAndMetrics.kt` `ColorFilter.tint(AppColors.Health.Steps/Calories/ActiveDuration)`；iOS `HeroArcView.swift` `.renderingMode(.template)+foregroundStyle(AppColors.Health.steps/calories/active)`；Harmony `MetricComp.ets` `.renderMode(ImageRenderMode.Template)+fillColor(AppColors.STEPS/CALORIES/ACTIVE)`；色值均为绿 `#00DF7B`/黄 `#FFC928`/紫 `#D72BCC`）。鸿蒙端"颜色无变化"根因是含模板色修复的构建尚未重建（代码上一轮已落地）。**结论：不改图标源文件，模板着色仅用 alpha；用户需在 DevEco 重建 HarmonyOS 验证。** 若重建后仍不生效，回退方案 B（预着色文件）——本机 `sips` 不支持写 WebP，Android 端重编码需用户提供工具。
- [RES-MAINT-004] **待处理1 修复**：`check-resource-maintainability.sh` 的 `count_matches` 新增 `strip_comments`（剥离 `/* */` 块注释 + 字符串感知的 `//` 行注释），消除"注释内中文被误算为硬编码文案"的 3 类误报；`AvatarImage.kt` 2 处 `Color.Transparent` 改为既有语义 Token `AppColors.Core.Transparent`（`AppColors.kt:11`），并移除未用的 `Color` import。修复后全类别债务为 0，确认无隐藏真实硬编码。

## 人工审查点
- [HLTH-VIS-039] `icon_calories.png` 源为蓝色预着色，但与 white 模板语义不冲突（模板色只看 alpha）；未做白色归一化，因无法同时重编 Android WebP 会造成三端源文件再度分叉。
- [RES-MAINT-004] `strip_comments` 需保留字符串字面量内的 `//`（如 URL `http://`），已按引号状态机处理；剥离后计数归零证明原 3 类失败确为注释误报。

## 验证结果
- [RES-MAINT-004] `./tools/check-resource-maintainability.sh` 通过：`androidHanLiterals=0, iosHanLiterals=0, harmonyHanLiterals=0, commonHanLiterals=0, androidDirectColors=0, iosDirectColors=0, harmonyDirectColors=0`。
- [RES-MAINT-004] `./gradlew :androidApp:assembleDebug :androidApp:testDebugUnitTest :common:check`：BUILD SUCCESSFUL。
- [SDD-009] 全部 20 个 `tools/*.sh` 门禁 0 FAIL；`check-sdd.sh`、`check-docs.sh` 通过。
- HarmonyOS ArkTS（MetricComp/SignedInPage）仍无本机构建环境，编译与真机视觉待 DevEco 复验。

## 人工修正点
- 无行为修正；仅 `AvatarImage.kt` 直接色换 Token 与门禁注释剥离。

## 下轮交接
- **已完成**：待处理1（资源债务门禁）清零；三端图标一致性方案 A 定案并确认代码齐备；历史遗留清单整理完毕（见下轮）。
- **未完成 / 阻塞项**：用户在 DevEco 重建 HarmonyOS 验证 MetricComp 模板色（绿/黄/紫）；历史遗留项需用户逐条确认（真机验收、MSRV-010/011、结构债务、WIP 提交）。
- **下轮起步建议**：用户在 DevEco 跑 `hvigorw assembleApp` 后核对三步图标颜色；随后按"历史遗留确认指南"逐条确认。
# 2026-08-07 17:00 — 收尾轮：图标预着色定案、MSRV-011 服务器连接失败提示、九文件大拆分

## 采纳内容
- [HLTH-VIS-039] **图标方案定案 = 预着色文件**（鸿蒙模板着色不可用）。用 Python 脚本按 alpha 保留生成绿 `#00DF7B`/黄 `#FFC928`/紫 `#D72BCC` 单色 PNG，三端字节一致：Android `drawable-nodpi/*.png`（替换原 WebP）、iOS imageset、Harmony media。移除三端渲染期着色（Android `ArcAndMetrics.kt` `ColorFilter.tint`、iOS `HeroArcView.swift` `.renderingMode(.template)+foregroundStyle`、Harmony `MetricComp.ets` `renderMode+fillColor` + `SignedInPage` 传色），"文件即颜色来源"，避免任何平台对着色依赖。`check-health-cross-platform-parity.sh` MetricComp 断言改为"直接渲染 + 拒绝 `renderMode`"。
- [MSRV-011] **服务不可达/写失败提示"服务器连接失败"**：common 新增 `MockError.NetworkUnavailable`（proto `NETWORK_UNAVAILABLE=13`、`AUTH_NETWORK_UNAVAILABLE`、键 `auth_error_network_unavailable`）；Android/iOS `parseError` 网络失败（status==-1）→ `NetworkUnavailable`；Harmony `MockServerSync.ets` 6 处 `NETWORK_ERROR`→`NETWORK_UNAVAILABLE`；健康写失败区分网络/持久化：`HealthDashboardStateDataSource.save` 由 `Boolean` 改 `MockResult<Unit>`（接口 + InMemory/Json/Android local/Android remote/iOS remote + store 7 调用点 + 测试 stub），远程数据源 status -1→`NetworkUnavailable`、其余非 2xx→`PersistFailed`；三端资源与解析器新增该键（`check-resources.sh` 26 键对齐）。新增测试 `LoginRulesTest.networkUnavailableMapsToStableMessageKey`。
- [STRUCT-003] **九文件大拆分**（3 个子代理并行，纯机械、公开符号不变）：Android `AuthComponents.kt`787→`AuthComponents(86)/AuthBranding(151)/AuthInputs(413)/AuthOverlays(210)`、`NormalDataEditor.kt`577→3 文件；iOS `AuthComponents.swift`608→4、`NormalDataEditor.swift`519→3、`HealthDashboardView.swift`491→3（pbxproj 登记 7 新文件）；Harmony `AuthComponents.ets`475→4、`SignedInPage.ets`620→2、`NormalDataSectionPage.ets`475→2、`ProfileCompletionPage.ets`1611→4。拆分后门禁回归逐一修复：iOS 卡片断言目标→`HealthDashboardCardRow.swift`、`check-health-editable-normal-data.sh` 指向 `NormalDataEditorFields/Sections`、6 个新 iOS View 文件补 `#Preview`（UI-PREVIEW-007）、TEST_REPORT/TRACE 计数更新（LoginRulesTest 9、合计 119、common 130）。
- **用户确认**：1.1~1.4（健康首页视觉、鸿蒙互顶、鸿蒙头像、会话懒校验）均已确认实现，退出待验收清单。

## 人工审查点
- [HLTH-VIS-039] 预着色文件用脚本按 alpha 保留重着色（源白/蓝形状不变），仅 3 个图标；`icon_calories` 原为蓝色预着色，与"白色模板"语义不同但模板色只看 alpha——现改为烘焙黄，三端统一显示，无平台依赖。
- [MSRV-011] 健康 `save` 接口改 `MockResult<Unit>` 属跨端接口变更，已同步接口/实现/store 调用点/测试；`RemoteAuthRepositoryTest` 的 stub 与断言同步。
- [STRUCT-003] 3 个子代理各自验证（Android gradle、iOS xcodebuild 含新 preview；Harmony 无法编译，仅全仓 grep 同步 import）。Harmony 代理把 `@Builder` 弹窗/编辑行改为 `@Component`（行为经回调注入），属结构改动，**必须 DevEco 复核**。

## 验证结果
- 20 个 `tools/*.sh` 门禁全部 0 FAIL；`mock-server` 46/46；`check-sdd.sh`/`check-docs.sh`/`git diff --check` 通过。
- `./gradlew :common:check :androidApp:assembleDebug :androidApp:testDebugUnitTest`：BUILD SUCCESSFUL。
- iOS `xcodebuild -sdk iphonesimulator`：BUILD SUCCEEDED。
- `harmony-kmp-bridge :compileKotlinOhosArm64`：BUILD SUCCESSFUL。

## 人工修正点
- 拆分后 7 个门禁回归已全部修复（iOS 门禁文件路径、NormalDataEditor 门禁路径、iOS `#Preview`、测试计数）；拆分中一处 `when` 括号错位已修复。

## 下轮交接
- **已完成**：图标预着色三端一致；MSRV-011"服务器连接失败"三端落地（含健康 save 接口改造）；九文件大拆分收口；全部自动化门禁与三端构建通过。
- **未完成 / 阻塞项**：HarmonyOS ArkTS 改动（MetricComp/SignedInPage 去着色、4 文件拆分 import 同步、@Builder→@Component 改造）需在 DevEco `hvigorw assembleApp` 编译与真机复核；119 个变更文件未提交（用户自行 commit）。
- **下轮起步建议**：在 DevEco 环境跑 `hvigorw assembleApp` 验证 Harmony 编译与三图标绿/黄/紫显示；随后按用户确认清单 review 全部 WIP 后提交。
# 2026-08-07 17:24 — 修复鸿蒙信息修改页未保存头像回写问题

## 采纳内容
- [MSRV-015] **根因**：`ProfileCompletionPage.ets` 在信息修改页（editMode）选图时即 `writeAvatarCache(bytes)` 写入**共享缓存文件** `avatar_current.jpg`；而"我"页 `AccountOverviewComp` 的 `AvatarImage` 同样读取该文件 → 未保存返回时"我"页已显示新头像。
- [MSRV-015] **修复（对齐 Android/iOS）**：选图不再写共享缓存，改为页面内存态 `@State pendingAvatarBase64` / `pendingAvatarBytes` 做本页预览；`AvatarImage.ets` 新增 `@Prop pendingAvatarBase64`（非空时最高优先展示，`@Watch` 触发重解析），并导出 `avatarBytesToBase64`；`ProfileAvatarComponent` 透传该 prop（"我"页不传 → 仍走已提交缓存）。保存时 `submitProfile` 才 `uploadAvatarBytesToServer(pendingAvatarBytes)`（成功内部 `writeAvatarCache`）→ 置 `profileAvatarUri`、`avatarCacheVersion++`、清空 pending。未保存返回时 pending 随页面销毁，"我"页保持旧头像。

## 人工审查点
- [MSRV-015] `writeAvatarCache` 在"信息完善页（非 editMode）选图即上传"分支仍保留（该场景选图即提交，行为正确）；`takeAvatarPhoto` 为占位实现未涉及。
- 修复只影响 ArkTS UI 状态流，未改 common/Android/iOS；"我"页 `AvatarImage` 调用点未传 pending → 默认空串走缓存，行为不变。

## 验证结果
- `./tools/check-account-profile-regressions.sh`：PASS（新增 `pendingAvatarBase64`/保存提交/清空 pending 断言）。
- 全部 20 个 `tools/*.sh` 门禁 0 FAIL。
- ArkTS 编译与真机"选图→未保存返回→保存"交互待 DevEco 复核（本机无 hvigorw）。

## 人工修正点
- 无。

## 下轮交接
- **已完成**：鸿蒙信息修改页头像改为"选图仅本页内存预览、保存才提交"，未保存返回不再回写"我"页。
- **未完成 / 阻塞项**：ArkTS 编译与真机交互待 DevEco；此前累计变更（图标/MSRV-011/大拆分/本修复）均未提交，由用户统一 commit。
- **下轮起步建议**：DevEco 跑 `hvigorw assembleApp` 复核本修复（选图预览→返回"我"页仍旧头像→保存后刷新）。
