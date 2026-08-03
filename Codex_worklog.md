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
