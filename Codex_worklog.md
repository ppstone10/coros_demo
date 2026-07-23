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

<!-- 新记录从这里开始追加 -->

# 2026-07-17（时间未记录）— SDD 开发框架搭建

## 采纳内容
- [SDD-001][SDD-009] 2026-07-17：新增根级 `AGENTS.md`，将“读上下文 → Spec → TRACE 预留 → 测试红灯 → 最小实现 → 验证 → 记录”设为 AI 强制开发顺序与完成门禁。
- [SDD-002][SDD-003][SDD-006] 2026-07-17：新增 `spec/sdd-workflow.md`、`spec/README.md`、`spec/TEMPLATE.md`，统一 Spec 稳定 ID、TRACE 状态、预留规则和追溯字段。
- [SDD-007][SDD-008] 2026-07-17：统一日志文件名为 `Codex_worklog.md`，明确 Worklog 保存本轮事实、`LEARNINGS.md` 只沉淀跨会话有效结论。
- [SDD-004][SDD-009] 2026-07-17：新增 `tools/check-sdd.sh`，校验 SDD 核心入口、模板章节、规范 ID、日志结构和文件名一致性。

## 人工审查点
- [SDD-009] 是否将 `./tools/check-sdd.sh` 接入后续 CI 仍需项目负责人确认；本轮只建立本地门禁，避免在未明确 CI 平台和触发策略时扩展交付范围。

## 验证结果
- [SDD-004] 红灯验证：执行 `bash ./tools/check-sdd.sh`，首次因入口、模板、日志和命名等 30 项缺口失败；结果符合“测试先捕获缺失框架行为”的预期，红灯阶段通过。
- [SDD-004] 实现后检查：再次执行 `bash ./tools/check-sdd.sh`，仅剩 Worklog 四个固定章节缺失，共 4 项失败；证明其余框架收敛项已被脚本识别，本轮日志补齐后需执行最终绿灯。
- [SDD-009] 绿灯验证：执行 `bash -n ./tools/check-sdd.sh && ./tools/check-sdd.sh`，脚本语法检查通过，全部 SDD 框架检查通过。

## 人工修正点
- 暂无明确人工修正点。

# 2026-07-17（时间未记录）— 项目文档与辅助目录治理

## 采纳内容
- [DOC-001][DOC-005] 2026-07-17：将五个实现目录、两组设计源资源、`contract/analytics`、构建基础设施和 `docs/worklog/` 明确列为保护内容；既有完整历史日志保持未修改。
- [DOC-002][DOC-003][DOC-004] 2026-07-17：重写根 README 并新增 `docs/README.md`，把 `docs/` 收敛为架构、开发流程、资源管理、Proto/Domain 说明和完整历史归档；删除已被吸收的重复教程、旧阶段计划、旧技能副本和空文档。
- [DOC-006][DOC-007] 2026-07-17：保留实际埋点契约，清理空 OpenAPI 与无生成行为的占位脚本；将 iOS、HarmonyOS、KNOI bridge 的专属说明归还对应实现目录 README。
- [DOC-008][DOC-009] 2026-07-17：按当前源码将 `LoginUseCaseTest` 从 28 修正为 29 条、共享业务测试总数从 54 修正为 55 条；新增 `tools/check-docs.sh` 持续校验文档结构、历史哈希、旧引用和测试计数。

## 人工审查点
- 暂无需要人工确认的审查点；本轮只删除已有明确权威替代、空占位或误建的内容，资源源文件和历史资料均采取保守保留策略。

## 验证结果
- [DOC-009] 红灯验证：执行 `bash ./tools/check-docs.sh`，清理前准确检出缺失权威文档、冗余路径、旧引用和过时测试计数等 31 项问题，红灯阶段通过。
- [DOC-001][DOC-009] 绿灯验证：执行 `bash -n ./tools/check-docs.sh && bash -n ./tools/check-sdd.sh && ./tools/check-docs.sh && ./tools/check-sdd.sh && git diff --check`，两个脚本语法、文档治理、SDD 门禁和差异格式全部通过。
- [DOC-001] 历史保护验证：`docs/worklog/2026-06-30-to-2026-07-17.md` 的 SHA-256 为 `eb13d20f0d1d79b53976eed725671b8827ecabc2748943de269166b49973f530`，与清理前单文件基线一致。
- [DOC-007] 实现范围检查：执行 `git diff --name-only -- common androidApp iosApp harmony-kmp-bridge harmonyApp`，只列出三个实现目录的 README；未修改业务源码、平台资源或构建配置。未运行 Gradle/平台构建，原因是本轮没有业务实现变更。

## 人工修正点
- 暂无明确人工修正点。

# 2026-07-17 11:41 — Worklog 时间与内容概要格式完善

## 采纳内容
- [SDD-007] Worklog 每轮记录新增真实写入时间和内容概要一级标题，标题之后继续保留“采纳内容、人工审查点、验证结果、人工修正点”固定四段。
- [SDD-007] 两条既有记录已补充可检索概要；因无法确认原始写入分钟，明确标记“时间未记录”，未伪造历史时间。
- [SDD-007] `AGENTS.md`、`spec/sdd-workflow.md`、`spec/SESSION_START.md`、`LEARNINGS.md` 与 `tools/check-sdd.sh` 已同步新格式和自动门禁。

## 人工审查点
- 暂无需要人工确认的审查点；时间格式已按项目时区 Asia/Shanghai 和 24 小时制固定。

## 验证结果
- [SDD-007] 红灯验证：执行 `bash -n ./tools/check-sdd.sh && ./tools/check-sdd.sh`，脚本语法通过，现有 Worklog 因缺少时间概要标题和轮次边界校验失败 2 项，符合预期。
- [SDD-007] 绿灯验证：修正历史标题识别后执行 `bash -n ./tools/check-sdd.sh && ./tools/check-sdd.sh`，真实时间标题、两条“时间未记录”历史标题及三轮固定四段顺序检查全部通过。

## 人工修正点
- 暂无明确人工修正点。

# 2026-07-17 13:46 — 有价值文档完整恢复与分层归档

## 采纳内容
- [DOC-010] 从 Git `HEAD` 完整恢复9份误删文档，从 Git 索引完整恢复1份新增资源指南；恢复后10份正文均与可信来源逐字节一致。
- [DOC-011] 当前权威文档保持 `docs/` 根目录现有排布；5份长期资料归入 `docs/reference/`，5份 HarmonyOS 阶段计划、实验说明和检查清单归入 `docs/archive/harmonyos-kmp/`。
- [DOC-011] 新增参考、归档和 HarmonyOS KMP 归档三级导航 README，明确当前文档优先级，同时保留参考资料和历史内容的完整价值。
- [DOC-012] 更新 `tools/check-docs.sh`，以后持续检查10份恢复文档存在且 SHA-256 不变，并保护 reference/archive 分类入口。

## 人工审查点
- 暂无需要人工确认的审查点；用户已明确指定“当前文档 / 参考资料 / 历史归档”的分类原则，本轮按该原则执行。

## 验证结果
- [DOC-012] 红灯验证：恢复前执行 `bash -n ./tools/check-docs.sh && ./tools/check-docs.sh`，准确报告缺失分类目录、导航和恢复文档等17项问题，符合预期。
- [DOC-010] 完整性验证：10份恢复文档在原路径恢复后和移动到分类目录后均执行 SHA-256，比对结果逐份一致；未用摘要或重新生成内容替代原文。
- [DOC-001] 历史日志验证：`docs/worklog/2026-06-30-to-2026-07-17.md` SHA-256 仍为 `eb13d20f0d1d79b53976eed725671b8827ecabc2748943de269166b49973f530`，未修改。
- [DOC-012] 绿灯验证：执行 `./tools/check-docs.sh`、`./tools/check-sdd.sh` 与 `git diff --check`，文档治理、SDD 框架和差异格式均通过。未运行 Gradle/平台构建，因为本轮只恢复和分类文档。

## 人工修正点
- 提交前需要按新目录重新审查并暂存文档移动；`docs/ios_harmonyos_app_resource_management_guide.md` 在本轮前已处于暂存新增状态，本轮未擅自修改用户的 Git 暂存区，因此当前索引仍记录旧路径。

# 2026-07-17 14:40 — 三端认证资源本地化基础迁移

## 采纳内容
- [RES-LOC-001] 新增共享 `AuthMessageKeys`，将认证校验、MockError、UseCase 和 Store 的最终中文消息替换为 23 个稳定 `auth_*` 语义键；保留既有跨语言 `errorMessage`/`message` 字段名称和未知消息原样回退行为。
- [RES-LOC-002][RES-LOC-003][RES-LOC-004] Android 使用 `values`/`values-en`，iOS 使用 `Localizable.xcstrings`，HarmonyOS 使用 `base`/`en_US`；三端认证错误组件及 Snackbar/Toast 展示入口统一在平台边界解析共享语义键。
- [RES-LOC-005] 新增 `tools/check-resources.sh`，校验共享键、三端默认中文/英文键集合、平台解析入口和目标共享中文硬编码，当前 23 个认证键保持一致。
- [RES-LOC-006] 更新当前资源管理说明，明确设计源与平台运行资源继续分层，健康摘要、日期、单位、复数和全量静态页面文案不属于本轮迁移范围。

## 人工审查点
- [RES-LOC-002][RES-LOC-003][RES-LOC-004] 本轮已验证三端构建，但未在三端运行环境切换系统语言进行视觉验收；需人工检查长英文截断、换行、Toast/Snackbar 和错误组件布局。
- [RES-LOC-006] 后续需确认是否增加繁体中文、默认回退是否继续为简体中文，以及健康摘要采用领域内容变体还是类型化 `messageKey + args` 契约。
- [RES-LOC-006] `docs/ios_harmonyos_app_resource_management_guide.md` 的暂存新增后工作区删除状态是本轮开始前已有状态；本轮未修改暂存区，也未把该旧路径纳入资源迁移。

## 验证结果
- [RES-LOC-001][RES-LOC-005] 红灯验证：实现前执行 `bash ./tools/check-resources.sh`，因共享键、Android 英文、iOS Catalog、HarmonyOS 英文资源缺失而失败；执行 `./gradlew :common:testAndroidHostTest --tests com.example.demo.common.login.LoginRulesTest`，因 `AuthMessageKeys` 尚不存在而编译失败。
- [RES-LOC-001][RES-LOC-002] 绿灯验证：执行 `./gradlew :common:check :androidApp:assembleDebug`，共享 56 条测试及 Android Debug 构建通过。
- [RES-LOC-003] 执行 `xcodebuild -project iosApp/iosApp.xcodeproj -scheme IOSDemo -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`，iOS 模拟器构建及 String Catalog 编译通过；保留既有 KMP Framework Run Script 无输出声明警告。
- [RES-LOC-004] 执行 DevEco 环境下的 `hvigorw assembleApp --no-daemon`，HarmonyOS 构建通过；保留 KNOI 生成代码、弃用 API 以及未配置签名的既有警告。
- [RES-LOC-005][RES-LOC-006] 执行 `./tools/check-resources.sh` 和 `./tools/check-docs.sh` 均通过；23 个认证键在三端默认中文和英文资源中一致，两组设计源与既有图片、视频、Lottie 路径未发生迁移。

## 人工修正点
- 暂无明确人工修正点。

# 2026-07-17 15:19 — 全资源盘点门禁与三端导航资源迁移

## 采纳内容
- [RES-MAINT-001][RES-MAINT-002][RES-MAINT-003] 建立 `tools/resource-inventory.json` 与人工盘点文档，确认37个三端共享图片语义名，以及 `home.mp4`、`watch_status.json` 两个三端内容一致的 Raw 资源；AppIcon 和启动资源明确保留平台专属。
- [RES-MAINT-004] 建立四组中文字符串字面量和三组直接颜色值的只降不升基线；导航迁移后上限收敛为 Android 259、iOS 283、HarmonyOS 319、common 122，颜色上限保持 Android 74、iOS 84、HarmonyOS 153。
- [RES-MAINT-005] 将体能、记录、探索、我和“功能后续开放”五个 `nav_*` 语义文案从三端硬编码 `AppText` 迁入 Android strings、iOS String Catalog 和 HarmonyOS string.json；三端导航页面改用原生资源入口。
- [RES-MAINT-006] 新增 `tools/check-resource-maintainability.sh`，统一校验清单格式、共享图片、共享 Raw 哈希、共享文字键和债务上限，并将使用方法写入资源文档与工具索引。

## 人工审查点
- [RES-MAINT-005] 全量静态文案迁移尚未完成；下一批应继续处理账户/资料标签和认证页面静态文案，法律正文、HarmonyOS 调试页和 `common` 健康结构化句子分别处理。
- [RES-MAINT-005] 语言切换入口和长英文视觉验收按用户要求继续后置，本轮只验证资源格式、参数化字符串和三端构建可用性。
- [RES-MAINT-005] 法律正文后续是进入平台字符串资源还是独立受保护 Bundle 文档，仍需人工决定内容维护方式。

## 验证结果
- [RES-MAINT-006] 红灯验证：实现清单前执行 `./tools/check-resource-maintainability.sh`，因缺少 `tools/resource-inventory.json` 非零失败；首次录入未经校准的去重计数时再次准确报告四组中文字面量高于上限。
- [RES-MAINT-001][RES-MAINT-002][RES-MAINT-003][RES-MAINT-004] 绿灯验证：执行 `./tools/check-resource-maintainability.sh`，37个共享图片、2个共享 Raw、5个共享导航文字键和7组债务上限全部通过。
- [RES-MAINT-005] Android 执行 `./gradlew :androidApp:compileDebugKotlin` 通过；iOS 执行 simulator `xcodebuild` 通过并成功编译 String Catalog。
- [RES-MAINT-005] HarmonyOS 首次使用错误的 SDK 根目录失败；改用项目文档中的 DevEco 环境后准确发现遗漏的 `AppText.NAV_ME` 引用，修正后执行 `hvigorw assembleApp --no-daemon` 构建通过，保留既有弃用 API、KNOI 和未配置签名警告。

## 人工修正点
- [RES-MAINT-005] 根据 HarmonyOS 编译红灯补齐个人页标题的 `nav_me` 原生资源引用；根据门禁实际逐次出现次数将初始盘点上限从“去重字符串数”修正为“源码出现次数”，避免两种统计口径混用。

# 2026-07-17 15:31 — 三端账户模块原生文字资源迁移

## 采纳内容
- [RES-MAINT-004][RES-MAINT-005] 新增10个 `account_*` 共享语义键，覆盖账户页标题、默认用户、资料完成状态、个人信息分区、账户分区、登录账号、退出、注销和注销确认；Android、iOS、HarmonyOS 均补齐默认中文与英文资源。
- [RES-MAINT-005] 三端账户页改为平台原生资源引用，Android/iOS 的 `AppText.Account` 及 HarmonyOS 对应账户常量已删除；HarmonyOS `SectionTitle`/`ValueRow` 接受 `ResourceStr`，同时保留动态资料值为普通字符串。
- [RES-MAINT-004] 迁移后硬编码中文上限再次下调：Android 259→249、iOS 283→273、HarmonyOS 319→312；共享文字键总数由5增至15。

## 人工审查点
- [RES-MAINT-005] 账户页中的资料字段标签、未设置、取消和确认仍来自历史 `AppText.Profile/Common`，将与下一批资料模块一起迁移，避免本批扩大到所有资料编辑交互。
- [RES-MAINT-005] 三端默认中文保持既有平台措辞：Android 账户标题/分区为“我的/账户”，iOS 与 HarmonyOS 为“我/账号”；语义键一致但未擅自统一产品文案。
- [RES-MAINT-005] 语言切换和长英文布局人工验收继续按用户要求后置。

## 验证结果
- [RES-MAINT-004][RES-MAINT-006] 红灯验证：先将10个账户键加入机器清单，执行 `./tools/check-resource-maintainability.sh`，准确报告三端默认/英文资源及 iOS 两种本地化全部缺失。
- [RES-MAINT-005] Android 执行 `./gradlew :androidApp:compileDebugKotlin` 通过；iOS simulator `xcodebuild` 通过并编译两种语言 String Catalog；HarmonyOS 执行 `hvigorw assembleApp --no-daemon` 构建通过。
- [RES-MAINT-004][RES-MAINT-006] 迁移后资源门禁通过：37个共享图片、2个共享 Raw、15个共享文字键及7组债务上限一致。

## 人工修正点
- 暂无明确人工修正点。

# 2026-07-17 15:47 — 三端公共与个人资料静态文案批量资源化

## 采纳内容
- [RES-MAINT-004][RES-MAINT-005] 新增 31 个 `common_*` / `profile_*` 共享语义键，三端均补齐默认中文与英文资源；共享文字键总数由 15 增至 46。
- [RES-MAINT-005] Android 公共操作、资料完善、资料编辑、账户资料字段和相关认证页改用 `stringResource`，并删除 `AppText.Common/Profile`；iOS 账户、健康编辑、资料完善及相关认证入口改用 String Catalog，并删除对应包装。
- [RES-MAINT-005] HarmonyOS 账户展示、资料完善主要可见文案、资料编辑标题、头像操作、公共返回/保存/确认/取消改用 `$r`；可复用资料组件的静态展示参数收敛为 `ResourceStr`，动态用户数据仍保持 `string`。
- [RES-MAINT-004] 文案硬编码上限按实际扫描结果下调：Android 249→220、iOS 273→230、HarmonyOS 312→272；common 与三端颜色基线保持不变。

## 人工审查点
- [RES-MAINT-005] 语言设置、切换机制及长英文换行/截断验证继续按用户要求后置；本轮没有增加应用内语言触发点。
- [RES-MAINT-005] HarmonyOS 资料选择器仍保留少量作为数据选项或旧组件标题的中文 `string`，iOS/HarmonyOS 认证页面也还有静态文案；下一批应继续迁移认证模块，再处理剩余资料字面量。
- [RES-MAINT-005] `common` 健康摘要、日期与原因属于结构化领域内容，未在本轮机械迁入平台字符串资源，仍按独立内容契约批次处理。

## 验证结果
- [RES-MAINT-006] 红灯验证：先把 31 个键加入 `tools/resource-inventory.json`，执行 `./tools/check-resource-maintainability.sh`，准确报告 Android/iOS/HarmonyOS 默认与英文资源全部缺失；补齐资源后门禁转绿。
- [RES-MAINT-005] Android 执行 `./gradlew :androidApp:compileDebugKotlin` 通过；首次编译准确发现 `AuthComponents.kt` 缺少 `stringResource` 导入，补齐后复验成功。
- [RES-MAINT-005] iOS 执行 simulator `xcodebuild` 并使用 `/private/tmp/demo-resource-ios-derived`，String Catalog、Swift 编译和链接通过；保留既有 KMP Run Script 无输出声明与 AccentColor 警告。
- [RES-MAINT-005] HarmonyOS 执行 DevEco 环境下 `hvigorw assembleApp --no-daemon` 构建通过；`ResourceStr` 参数改造经 ArkTS 编译验证，保留既有 KNOI、弃用 API、`app_name` 冲突和未配置签名警告。
- [RES-MAINT-004][RES-MAINT-006] 最终执行资源维护门禁、认证资源门禁、文档治理门禁、SDD 门禁和 `git diff --check` 均通过；资源维护摘要为 37 个共享图片、2 个共享 Raw、46 个共享文字键。

## 人工修正点
- [RES-MAINT-005] 根据 Android 编译红灯补充 `AuthComponents.kt` 的 Compose `stringResource` 导入；未改变界面行为或产品文案。

# 2026-07-17 16:13 — 三端认证静态文案与资料选择器资源化

## 采纳内容
- [RES-MAINT-004][RES-MAINT-005] 新增 64 个共享文字键，覆盖认证入口、登录、注册、验证码、密码设置/重置、会话及成功反馈，以及 iOS/HarmonyOS 资料选择器的国家、单位、日期后缀和操作反馈；共享文字键总数由 46 增至 110，三端均补齐默认中文与英文资源。
- [RES-MAINT-005] Android 认证页面和导航反馈改用 `stringResource`/`getString`，并删除 `AppText.Auth`；iOS 认证页面、协调器及资料选择器改用 String Catalog；HarmonyOS 认证页面、认证组件、消息解析和资料选择器改用 `$r`/资源管理器。动态用户输入、持久化值和领域数据继续保持普通字符串。
- [RES-MAINT-004] 迁移后中文硬编码上限下调为 Android 170、iOS 142、HarmonyOS 142、common 122；颜色上限保持不变。验证码发送提示与倒计时使用共享语义键和平台原生格式参数，不再由页面拼接最终句子。
- [RES-LOC-005] 资源门禁明确区分 23 个 `common` 认证消息语义键与认证页面静态 `auth_*` 键：消息键必须进入平台错误解析器，静态键不建立无意义映射，但三端默认/英文集合仍必须一致并受全资源清单保护。

## 人工审查点
- [RES-MAINT-005] 按用户要求，本轮仍不开发语言设置或切换机制，也未把长英文换行、截断和运行时视觉效果记为已验证；这些在后续多语言功能具备触发点后统一验收。
- [RES-MAINT-005] 法律正文按 Spec 明确排除，只迁移法律页面标题、返回等壳层文案；健康页面、调试页和其他剩余生产静态文案仍属于后续治理批次，因此全模块静态文案阶段尚未整体完成。
- [RES-MAINT-005] HarmonyOS 构建仍报告既有 KNOI 校验、弃用路由/Toast API、`app_name` 冲突和未配置签名警告；iOS 保留既有 KMP Framework Run Script 未声明输出警告，本轮均未扩大范围处理。

## 验证结果
- [RES-MAINT-006] 红灯验证：先将本批 59 个键加入 `tools/resource-inventory.json`，资源维护门禁准确报告三端默认/英文资源缺失；补充 5 个会话与成功反馈键后再次准确报告对应缺失，共验证 64 个新增键的缺失可被捕获。
- [RES-MAINT-005] `./gradlew :common:check` 通过；Android 完整执行 `./gradlew :androidApp:assembleDebug`，英文资源修正后 APK 打包通过；iOS 执行 simulator `xcodebuild` 并使用 `/private/tmp/demo-auth-resource-ios-derived`，String Catalog、Swift 编译和链接通过；HarmonyOS 执行 DevEco 环境下 `hvigorw assembleApp --no-daemon`，ArkTS、资源编译和应用打包通过。
- [RES-MAINT-004][RES-MAINT-006] 最终 `./tools/check-resource-maintainability.sh` 通过：37 个共享图片、2 个共享 Raw、110 个共享文字键，中文字面量计数为 Android 170、iOS 142、HarmonyOS 142、common 122。
- [RES-LOC-005] `./tools/check-resources.sh` 通过，23 个共享认证消息键三端完整，全部 `auth_*` 默认/英文资源集合一致；定向 `rg` 复扫确认 Android 无 `AppText.Auth` 引用，iOS 认证目录除受保护法律正文外、HarmonyOS 认证页和资料选择器范围内均无中文字符串直接字面量。
- [RES-MAINT-005][RES-MAINT-006] `./tools/check-docs.sh`、`./tools/check-sdd.sh` 和 `git diff --check` 均通过。

## 人工修正点
- [RES-LOC-005] 最终门禁首次把新增认证静态 `auth_*` 键误判为未映射错误键；按 Spec 职责边界修正脚本，使其校验共享消息键是全部认证资源的子集，并额外校验三端全部 `auth_*` 资源集合一致，未放宽缺失翻译检查。
- [RES-MAINT-005] Android 完整资源打包首次发现英文 `Didn&apos;t`、`COROS&apos;s` 在 XML 解码后仍不符合 AAPT 撇号转义规则；改为 Android 字符串反斜杠转义后 `assembleDebug` 复验通过。

# 2026-07-17 17:04 — 法律健康生产资源与三端视觉 Token 治理

## 采纳内容
- [RES-MAINT-007] 将隐私政策和服务条款正文迁入三端原生本地化资源；中文正文完整保留，英文按用户确认生成 Demo 翻译，页面通过空行、`## ` 标题和 `**...**` 强调组成的受限轻量结构解析，不再在源码复制正文。
- [RES-MAINT-008] 新增共享 `LocalizedTextSpec(key, arguments)`，健康标题、摘要、日期、原因及业务欢迎语改为稳定资源键和参数；Android、iOS、HarmonyOS 分别在原生资源边界解析，Harmony KNOI JSON 同步传递 key/arguments。
- [RES-MAINT-009] 按用户确认保留 HarmonyOS `DebugStatePage` 原始调试文字，不做多语言；资源门禁仅对该唯一非发布路径精确排除文案和颜色，其他生产页面继续受检。
- [RES-MAINT-010] 三端生产页面直接颜色字面量降为 0；颜色集中到语义 `AppColors`，健康页重复字号与间距使用有限 `AppTypography`/`AppSpacing`，保持原有数值和界面结构。
- [RES-MAINT-004][RES-MAINT-005] 共享文字清单由 110 扩展至 192 个键，覆盖健康、法律和剩余业务提示；三端生产源码中文文案债务降为 0，`common` 仅保留 7 处国家名称/历史快照兼容领域值。

## 人工审查点
- [RES-MAINT-007] 英文法律正文只适用于当前 Demo，正式发布前必须由法律人员重新审校并替换，不能把本轮翻译视为正式条款。
- [RES-MAINT-008] 应用内语言设置、切换机制和长英文换行/截断视觉验收继续按用户要求后置，本轮未新增语言触发点，也未声称完成运行时英文布局验收。
- [RES-MAINT-004] `common` 的 7 处国家名称涉及 `countryRegion` 持久化值和旧 JSON 快照；为避免纯资源迁移破坏现有数据，本轮保留并将后续工作明确为“稳定国家代码 + 旧快照迁移”的独立数据契约批次。
- [RES-MAINT-010] 一次性 Canvas 几何、动画时长和组件特有尺寸仍保留局部值；本轮 Token 治理不进行视觉重设计。

## 验证结果
- [RES-MAINT-008] 红灯验证：新增 `healthUiModelsExposeLocalizationKeysAndTypedArguments` 后，定向 common 测试因 `key/arguments` 尚不存在而编译失败；实现契约后该测试通过，共享健康测试由 15 增至 16，common 总数由 56 增至 57。
- [RES-MAINT-005][RES-MAINT-007] 红灯验证：先将健康、法律等新增键加入机器清单，`./tools/check-resource-maintainability.sh` 准确报告三端缺失资源；补齐后门禁通过，摘要为 37 个共享图片、2 个共享 Raw、192 个共享文字键。
- [RES-MAINT-008] 执行 `./tools/build-shared-harmony.sh`，common 57 条共享测试通过并重新生成 KNOI Debug/Release `libkn.so`；保留既有 KSP 版本提示和 Kotlin/Native 生成代码警告。
- [RES-MAINT-005][RES-MAINT-007][RES-MAINT-008][RES-MAINT-010] Android 执行 `./gradlew :androidApp:assembleDebug` 通过；iOS simulator `xcodebuild` 通过；HarmonyOS DevEco `hvigorw assembleApp --no-daemon` 通过，保留既有弃用 API、KNOI、资源名冲突和未配置签名警告。
- [RES-MAINT-004][RES-MAINT-006][RES-MAINT-009][RES-MAINT-010] 最终资源维护门禁统计为 Android/iOS/HarmonyOS 生产中文 0、直接颜色 0、common 国家领域值 7；`./tools/check-resources.sh` 继续验证 23 个认证消息键一致，`git diff --check` 通过。

## 人工修正点
- [RES-MAINT-005] Android 首次编译发现 4 处页面引用了不存在的认证键短名，修正为既有 `ValidationPhoneInvalid`、`ErrorAccountNotFound` 和 `ErrorAccountExists` 后编译及打包通过。
- [RES-MAINT-010] HarmonyOS 首次 ArkTS 构建发现资料页遗漏的 `COROS_DIALOG_BG` 引用，补入 `AppColors.AUTH_DIALOG` 后再次构建通过。
- [DOC-008] 健康测试新增后文档门禁准确指出 TEST_REPORT/TRACE 仍为 15/56；同步更新为 16/57 后复验。

# 2026-07-17 17:51 — 三端应用内语言切换与国家状态代码化

## 采纳内容
- [APP-LANG-001] 新增三端统一的应用语言状态契约，支持简体中文 `zh-Hans` 与英文 `en`，首次启动默认中文，并分别通过 Android SharedPreferences、iOS UserDefaults、HarmonyOS PersistentStorage 持久化用户选择。
- [APP-LANG-002][APP-LANG-003] Android、iOS、HarmonyOS 均在注册登录 Entrance 页右上角及登录后“我”页首行最右侧增加地球图标；点击后显示中文/英文选择界面，并通过各平台原生资源环境即时刷新整个应用。认证反馈、健康动态内容和资料国家展示也接入当前应用语言。
- [APP-LANG-004] `common` 的 `countryRegion` 从可见国家名称收敛为 `CN`、`US`、`GB`、`JP` 稳定代码；读入旧中英文名称时兼容归一化，保存时写入代码，注册区域作为合理回退值。三端选择器只持久化代码，显示名称由当前语言资源解析。
- [APP-LANG-005] 三端补齐语言切换相关 4 个共享资源键，共享文字清单由 192 增至 196；`common` 生产中文字面量由国家兼容值 7 处降至 0，并将语言入口、资源集合和国家代码契约纳入自动门禁。

## 人工审查点
- [APP-LANG-002][APP-LANG-003] 当前无可用 Android 设备，且本轮未连接 iOS/HarmonyOS 运行设备，因此没有把三端实际点击、即时刷新及重启恢复记为已完成；需在设备或模拟器上分别验证 Entrance 与“我”页两个入口。
- [APP-LANG-003] 按既定范围，长英文换行、截断及小屏视觉验收继续保留到后续多语言专项；本轮只验证资源和构建链路，不声称视觉验收通过。
- [APP-LANG-003] HarmonyOS `DebugStatePage` 仍按用户确认排除在正式 Demo 多语言治理之外；首次语言默认值固定为中文，不再隐式跟随三端各自系统语言。

## 验证结果
- [APP-LANG-004] 红灯验证：先新增 `registrationRegionAndLegacyNamesNormalizeToCountryCodes`，定向执行 common 测试时因 `toProfileCountryCode` 尚不存在而编译失败；实现国家代码归一化后，`./gradlew :common:check` 全量通过。
- [APP-LANG-002][APP-LANG-003] Android `./gradlew :androidApp:assembleDebug` 通过；iOS 使用 `IOSDemo` scheme 执行 simulator `xcodebuild`，资源编译、Swift 编译和链接通过；HarmonyOS 执行 `hvigorw assembleApp --no-daemon`，KMP bridge 重建、ArkTS 编译和应用打包通过。
- [APP-LANG-005] `./tools/check-resources.sh` 与 `./tools/check-resource-maintainability.sh` 通过：37 个共享图片、2 个共享 Raw、196 个共享文字键，三端生产中文和直接颜色均为 0，`common` 生产中文为 0。
- [APP-LANG-005] `./tools/check-sdd.sh`、`./tools/check-docs.sh` 与 `git diff --check` 通过；未执行三端运行时人工点击和重启恢复验证。

## 人工修正点
- [APP-LANG-003] Android 导航反馈由 Activity 基础 context 改为当前本地化 `LocalContext`，避免页面已切换语言但 Snackbar 仍读取旧资源。
- [APP-LANG-003] iOS 健康默认卡片改为随语言重新解析的计算值，并统一从选定语言 Bundle 读取 String Catalog；HarmonyOS 在选择语言后重新加载健康数据，避免动态 KMP 文案停留在切换前语言。

# 2026-07-17 18:09 — iOS 语言即时刷新与 Entrance 跨端布局修正

## 采纳内容
- [APP-LANG-006] 修复 iOS 选择语言后必须导航才刷新文案的问题：`EntranceView`、`AccountView` 和 `MainTabsView` 直接观察并读取共享 `AppLanguageStore.current`，语言发布后局部重算当前页面及同屏底部导航，不重建 `AuthCoordinator`、导航路径或底部 Tab 状态。
- [APP-LANG-007] iOS Entrance 将 Logo 与地球按钮合入同一个 48pt 全宽顶部栏并纵向对齐，登录/注册按钮组底部留白由 60pt 调整为 36pt，即整体下移 24pt；Android 现有布局保持不变。
- [APP-LANG-007] HarmonyOS Entrance 将 Logo 与地球按钮合入全宽 `EntranceTopBar`，通过 Row 尾部 12vp 内边距稳定放置图标，移除未能锚定全屏右上区域的独立 `.align(Alignment.TopEnd)` 布局。

## 人工审查点
- [APP-LANG-006] iOS simulator 构建和观察契约已通过，但本轮未自动操作模拟器完成 Entrance/“我”页实际切换，因此即时刷新仍需人工各点击一次确认。
- [APP-LANG-007] 两个平台的顶部栏实现与构建已验证；最终视觉高度、按钮下移幅度和 HarmonyOS 右上位置需使用与用户截图相同的设备窗口重新截图对比，避免不同安全区造成主观偏差。
- [APP-LANG-007] Android 是本轮视觉基准且没有修改；长英文换行与截断仍按既定范围留在后续专项。

## 验证结果
- [APP-LANG-006][APP-LANG-007] 红灯验证：扩展 `./tools/check-resources.sh` 后，当前实现准确报告 iOS Entrance/“我”页/底部导航缺少语言观察与顶部栏契约，并报告 HarmonyOS 缺少全宽顶部栏；实施后同一门禁通过。
- [APP-LANG-006] iOS 执行 `xcodebuild -project iosApp/iosApp.xcodeproj -scheme IOSDemo -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO -derivedDataPath /private/tmp/demo-language-fix-derived build`，String Catalog、Swift 编译和链接通过。
- [APP-LANG-007] HarmonyOS 执行 DevEco `hvigorw assembleApp --no-daemon`，ArkTS 编译及 App/HAP 打包通过；保留既有 API 弃用、资源名冲突和未配置签名警告。

## 人工修正点
- [APP-LANG-006] 没有使用根视图 `.id(language)` 强制重建方案，避免语言切换导致导航路径、页面局部状态或当前底部 Tab 被重置；改为三个实际同屏消费者局部订阅。
- [APP-LANG-007] 根据用户提供的三端截图，将 iOS 两套独立顶部偏移收敛为一个顶部容器，并将 HarmonyOS 图标从独立 Stack 子项移入 Logo 顶部栏。

# 2026-07-17 18:37 — Android Compose 响应式资源 Lint 修复

## 采纳内容
- [APP-LANG-008] `ProvideAppLanguage` 改为从 `LocalConfiguration.current` 获取基础配置，再复制并设置应用语言，避免通过 `LocalContext.current.resources.configuration` 读取不可观察配置。
- [APP-LANG-008] `AuthNavGraph` 的 Snackbar 文案全部改由 `LocalResources.current` 查询，并将 Resources 纳入 `LaunchedEffect` key；认证消息解析器由 `Context` 扩展收敛为 `Resources` 扩展。
- [APP-LANG-008] `ErrorText` 同步通过 `LocalResources.current` 解析共享认证消息键，不使用 Lint baseline 或 `@SuppressLint` 绕过检查。

## 人工审查点
- [APP-LANG-008] 本轮只修复用户上传时遇到的两类 Compose Lint Error，没有处理同一报告中的既有普通 Warning/Hint；这些不会阻断当前 `lintDebug`。
- [APP-LANG-008] 应用内语言切换运行时视觉验收仍沿用前轮待验项；本轮验证覆盖响应式读取静态分析、Kotlin 编译和 APK 打包。

## 验证结果
- [APP-LANG-008] 实施前 `./gradlew :androidApp:lintDebug` 失败，准确报告 1 个 `LocalContextConfigurationRead` 和 8 个 `LocalContextGetResourceValueCall`；实施后同一命令 `BUILD SUCCESSFUL`。
- [APP-LANG-008] `./gradlew :androidApp:assembleDebug` 通过，Kotlin 编译、Dex 与 APK 打包成功。
- [APP-LANG-008] `./tools/check-resources.sh` 与 `./tools/check-resource-maintainability.sh` 通过，196 个共享文字键及三端文案/颜色债务基线未回退。

## 人工修正点
- [APP-LANG-008] 发现用户已先在 `AppLanguage.kt` 加入 `LocalConfiguration.current`，本轮保留该并行修改，仅统一 `remember` 参数格式并补齐其余 Resources 调用链。

# 2026-07-21 13:36 — Android 资料编辑页 Activity Result owner 闪退修复

## 采纳内容
- [ANDROID-PROFILE-AR-001][ANDROID-PROFILE-AR-002] `ProvideAppLanguage` 在用 `ConfigurationContext` 覆盖 `LocalContext` 前捕获宿主 `LocalActivityResultRegistryOwner`，并在本地化子树显式继续提供；无 owner 的预览宿主仍可正常组合。
- [ANDROID-PROFILE-AR-003] 保持“我”页、个人资料编辑页、头像相册/相机入口及 KMP 资料模型现有行为，不修改 iOS、HarmonyOS 或共享业务实现。
- [ANDROID-PROFILE-AR-002] 实测确认升级 `activity-compose` 至 `1.13.0` 仍无法解决该 Context owner 丢失问题，因此撤回试验性版本改动，最终依赖版本保持原样，避免扩大 Android 依赖图风险。

## 人工审查点
- [ANDROID-PROFILE-AR-003] 自动化覆盖两个 launcher 的注册与真实资料编辑入口；相册选择器和相机应用的最终拍摄/返回结果未在本轮自动提交媒体，后续发布验收可各执行一次系统应用往返。
- [ANDROID-PROFILE-AR-002] 本轮只处理已复现的 Activity Result owner；若未来本地化层新增其他依赖 Activity Context 查找的 Compose API，应按同一宿主边界补充定向测试，不应假设 `ConfigurationContext` 等价于 Activity。

## 验证结果
- [ANDROID-PROFILE-AR-001] 红灯验证：当前实现下在 `ProvideAppLanguage` 子树注册 `GetContent` 与 `TakePicturePreview` launcher，两台 API 36.1 模拟器均精确抛出 `No ActivityResultRegistryOwner was provided via LocalActivityResultRegistryOwner`；实施后同一 `connectedDebugAndroidTest` 在两台模拟器均通过。
- [ANDROID-PROFILE-AR-002] `./gradlew :common:check :androidApp:assembleDebug` 通过，共享层 57 条测试通过且 Android Debug APK 构建成功。
- [ANDROID-PROFILE-AR-003] emulator-5556 安装修复 APK 后，使用项目内置 mock 账号完成资料，点击“我”页“资料已完善”区域成功显示个人信息编辑页；`com.example.demo` 进程存活，清空后的 `AndroidRuntime` 日志无新崩溃。

## 人工修正点
- [ANDROID-PROFILE-AR-001] 首版测试使用 Compose Rule 时先暴露旧 Espresso 与当前模拟器 API 的 `InputManager.getInstance` 不兼容，改用不依赖 Espresso 的 `ActivityScenario` 后才获得目标异常红灯。
- [ANDROID-PROFILE-AR-002] 最初按依赖失配方向试升 `activity-compose 1.13.0`，同一回归测试仍精确失败；据源码与测试证据修正规格和实现方向，并撤回版本升级，最终以 owner 透传完成最小修复。

# 2026-07-21 18:00 — 健康仪表盘维护性提升 P0+P1+P2

## 采纳内容
- [HLTH-MAINT-001] `HealthDashboardStore.saveCardConfiguration` 对 `types.size < 3` 返回 `MockResult.Failure(MinimumCardsRequired)` 而非静默回退。
- [HLTH-MAINT-001] 新增 `MockError.MinimumCardsRequired` 枚举项及对应 `AuthMessageKeys.ErrorMinimumCardsRequired` 键。
- [HLTH-MAINT-002] `LoginFacade` 新增 `healthCardSaveError()` 方法，iOS `SharedLoginAdapterProtocol` 和 HarmonyOS `KnoiLoginAdapter` 同步暴露。
- [HLTH-MAINT-003] 新增 `HealthScenarios` 对象（`names` + `displayKeys`）到 `HealthDashboardModels.kt`。
- [HLTH-MAINT-004] iOS 移除 `defaultHealthCards` 全局变量和 `HealthCard` 的 `Codable` 实现；`HealthDashboardViewModel.load()` 直接从 `PersistedDashboard.uiState.cards` 映射；`remove()` 改为通过 `saveCardConfiguration` 让 common 验证。
- [HLTH-MAINT-005] HarmonyOS 提取 `health/HealthDashboardTypes.ets`（CardEntry、HealthSnapshot、HealthCardModel、`createDefaultHealthCards`、`cardIconIndex`、`localizedHealthText`、`resourceText`）；`SignedInPage.ets` 精简约 50 行类型定义。
- [HLTH-MAINT-006] 新增 `PostLoginRoute` 枚举（`SignedIn` / `ProfileCompletion`）；`LoginEffect.AuthSucceeded` 新增 `nextRoute` 字段；三端导航文件（`AuthNavGraph.kt`、`AuthCoordinator.swift`、`AuthEffectHandler.ets`）从检查 `isProfileComplete` 改为消费 `nextRoute`。
- [HLTH-MAINT-006] HarmonyOS KNOI 桥接 `HarmonyLoginJson.kt` 和 `KnoiLoginAdapter.ets` 同步携带 `nextRoute` 字段。

## 人工审查点
- [HLTH-MAINT-004] iOS `HealthDashboardViewModel.swift` 重构后需人工用 Xcode 构建验证健康仪表盘展示与之前一致。
- [HLTH-MAINT-005] HarmonyOS `SignedInPage.ets` 拆分后需 `hvigorw assembleHap` 构建通过，验证仪表盘、卡片编辑器、账户页交互无差异。
- [HLTH-MAINT-002] 三端最少卡片数错误提示文案需业务确认：当前 `MockError.MinimumCardsRequired.message` 使用 `health_error_minimum_cards_required` 键，三端需确保该字符串资源存在。
- iOS `PostLoginRoute` 枚举在 Swift 中的导出名称需人工确认（KMP 导出规则可能加尾随下划线）。

## 验证结果
- [HLTH-MAINT-001][HLTH-MAINT-003][HLTH-MAINT-006] `./gradlew :common:check` 通过：62 条测试全部通过（新增 5 条：`cardSaveRejectsMinimumConfig`、`cardSaveAcceptsSufficientConfig`、`healthScenariosMatchMockEntries`、`loginSuccessCarriesSignedInRouteWhenProfileComplete`、`loginSuccessCarriesProfileCompletionRouteWhenProfileIncomplete`）。
- `bash ./tools/check-sdd.sh` 通过：SDD 框架校验全部 PASS。

## 人工修正点
- [HLTH-MAINT-004] iOS 需要 Xcode 运行验证健康仪表盘展示。
- [HLTH-MAINT-005] HarmonyOS 需要 DevEco 构建验证。
- 三端本地化资源文件 (`strings.xml` / `xcstrings` / `string.json`) 需增加 `health_error_minimum_cards_required` 键的文案。
- 后续新建健康相关功能时，规则优先放入 `common` 而非三端 UI 各写一套。

## 下轮交接
- **已完成**：`spec/health-maintainability.md` 规范创建 → TRACE 映射 → 测试先行红灯 → common 实现绿灯 → 三端 UI 代码更新 → SDD 门禁通过。
- **未完成 / 阻塞项**：iOS/HarmonyOS 的构建验证需人工执行（无对应 CI 环境）。
- **下轮起步建议**：阅读 `spec/health-maintainability.md` 和 `spec/TRACE.md` 中 `HLTH-MAINT-*` 条目；优先在 Xcode/DevEco 中验证 iOS/HarmonyOS 构建。

# 2026-07-21 18:30 — 三端主页 Tab 子页面解耦与 iOS 编译修复

## 采纳内容
- **Android**：`health/` 目录从单文件 657 行拆分为 7 个独立文件：`HeroTopRow.kt`、`ArcAndMetrics.kt`、`DashboardCard.kt`、`CardEditor.kt`、`ScenarioPickerDialog.kt`、`DetailPlaceholder.kt`，每文件附带 `@Preview`；`MainTabsScreen.kt` 的 Records/Explore 占位页提取为独立 `RecordsPlaceholderScreen.kt` / `ExplorePlaceholderScreen.kt`。
- **iOS**：`Health/` 目录拆分为 9 个文件：`HealthCard.swift`、`HeroTopRow.swift`、`HeroArcView.swift`、`HealthCardEditor.swift`、`ScenarioPickerView.swift`、`HealthDetailView.swift`、`ScrollViewAccessor.swift`、`HealthDashboardViewModel.swift`、`HealthDashboardView.swift`（主编排）；`Home/` 新增 `RecordsPlaceholderView.swift` / `ExplorePlaceholderView.swift`。
- **HarmonyOS**：`SignedInPage.ets` 中 `HeroTopRow`、`ScenarioPicker`、`HealthDetail` 提取为独立 `@Component` 文件（`health/HeroTopRowComp.ets`、`health/ScenarioPickerComp.ets`、`health/HealthDetailComp.ets`）；底部导航提取为 `pages/BottomNavBarComp.ets`；Lottie 管理移至 `HeroTopRowComp` 内，清理 SignedInPage 中失效的 lottie 状态。SignedInPage 从 912 行降至约 580 行。
- **iOS 编译修复**：`HealthCard` 结构体移入独立 `HealthCard.swift`；`HealthDashboardView.swift` 中子视图改为 `import` 方式而非 `private struct` 内联；`AppLanguageStore()` 因 `private init` 改为 `AppLanguageStore.shared`；key path 表达式 `\.id` 改为 `{ $0.id }` 以修复类型推断失败。

## 人工审查点
- iOS 新建的 9 个 `.swift` 文件需人工拖入 Xcode Project Navigator 并加入 Compile Sources，否则编译时找不到类型。
- HarmonyOS `account/AccountOverviewComp.ets` 通过 `@Prop` 接收父组件的 10+ 参数，若后续新增字段需同步更新调用方。
- Android `HeroTopRow.kt` 的 Lottie 相关 import 需确认无重复或缺失（此前曾因重复 import 导致编译失败）。

## 验证结果
- `./gradlew :common:check` 通过：62 条测试全部通过。
- `./gradlew :androidApp:assembleDebug` 通过：Android Debug APK 构建成功。
- `bash ./tools/check-sdd.sh` 通过：SDD 框架校验全部 PASS。

## 人工修正点
- iOS 需在 Xcode 中将新增文件加入 Compile Sources 后验证健康仪表盘展示与编辑器拖拽功能。
- HarmonyOS 需在 DevEco 中构建验证 `SignedInPage.ets` 精简后页面交互无差异。
- 三端本地化资源文件需增加 `health_error_minimum_cards_required` 键的文案。
- iOS 提取的子视图文件（`HealthCardEditor.swift`、`HeroTopRow.swift` 等）目前引用同一模块类型无需 import，若后续迁移到独立 framework 则需补充 import。

# 2026-07-21 17:02 — Figma 2031 健康数据卡三端扩充

## 采纳内容
- 新增 `spec/health-dashboard-visual-cards.md` 与 `HLTH-VIS-001~007` 追溯；先扩充 `health_dashboard_mock.proto`，再同步 domain/mock mapper 和 `HealthCardVisualData` 类型化 UI 契约。
- 正常场景补齐今日运动、七日计划/负荷、训练评估、恢复/能力仪表、心率/压力趋势、睡眠阶段、HRV/静息心率区间、健康快测及体型管理数据；默认目录把 `TodayActivity` 放在 `WeeklyPlan` 前。
- Android Compose、iOS SwiftUI、HarmonyOS ArkUI 按 visual kind 原生渲染 11 类卡片模板；HarmonyOS KNOI JSON bridge 同步传递图表、范围、指标和睡眠阶段。
- 从 Figma 节点 `16:8245`、`16:8294` 下载人体正反面 SVG，并以相同 PNG 资产写入三端资源；新增视觉文案的中英文资源与解析入口。

## 人工审查点
- Figma 使用的 `COROSAPP` / `COROS-number` 字体未随设计提供授权文件，本轮沿用三端平台字体；需设计人工核对字宽、数值基线和 114/122/178/180/188/206 级卡片高度。
- Figma 节点 motion inventory 为空，因此图表直接渲染终态，没有臆造入场或循环动画；若后续提供正式动效稿，需要另立 Spec 校准时间线、缓动与 Reduce Motion。
- 当前活动卡地图区域使用本地 mock 色块与已有运动图标，不声称为真实地图；业务若需要轨迹图，需另补脱敏本地矢量数据契约。

## 验证结果
- 测试先行红灯：首次运行 `./gradlew :common:testAndroidHostTest --tests '*HealthDashboardUseCaseTest*'` 因 `visual` / `HealthCardVisualKind` 缺失编译失败；实现后同命令通过 22 条测试。
- `./gradlew :common:check :androidApp:assembleDebug` 通过；`xcodebuild -quiet -project iosApp/iosApp.xcodeproj -scheme IOSDemo -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build` 通过；`hvigorw assembleApp --no-daemon` 通过（未配置签名，仅生成未签名包）。
- `./tools/check-sdd.sh` 与 `git diff --check` 通过；三端人体正面 PNG SHA-256 均为 `651396...e23e4b`，背面均为 `ce1814...b2ded2`。
- `./tools/check-resources.sh` 未通过，唯一报告为既存 `HarmonyOS Me is missing the language selector entry point`；`./tools/check-docs.sh` 初次因测试统计陈旧失败，更新为 Login 31、Health 22、common 65 后复跑通过。
- 图表颜色收口到三端 `AppColors` 后，`./tools/check-resource-maintainability.sh` 通过：三端新增直写颜色债务均为 0；收口后 Android、iOS、HarmonyOS 再次构建通过。

## 人工修正点
- ArkUI 初次编译发现 `RowAttribute` 不支持 `.fontSize/.fontColor`，已把样式下沉到两个 `Text` 节点并复跑通过。
- Android `HealthCardUiModel` 预览补齐必填 `visual`；iOS `HealthCard` 以 id 自定义 Hashable，视觉对象不参与编辑器排序相等性。
- 资源门禁的 HarmonyOS 语言入口属于本轮外既存问题，未越权修改账户/语言入口；需后续按应用语言 Spec 单独处理。

# 2026-07-21 17:28 — Android 健康首页裸百分号启动闪退修复

## 采纳内容
- [HLTH-VIS-008] 定位到健康首页恢复卡片渲染百分比单位时，`stringResource(id, *emptyArray())` 仍进入 Android 格式化重载，裸 `%` 被解释为未完成的格式符并抛出 `UnknownFormatConversionException`。
- [HLTH-VIS-008] `HealthLocalization.kt` 改为通过 `LocalResources` 获取资源，并由 `Resources.localizedHealthText` 按参数是否为空选择非格式化或格式化 `getString` 重载；资源值仍保持字面量 `%`。
- [HLTH-VIS-008] 新增 `HealthLocalizationTest.percentUnitWithoutArgumentsDoesNotEnterFormatter` Android 插桩回归测试。

## 人工审查点
- [HLTH-VIS-008] 本次只调整 Android 健康文案的资源解析路径，不改变卡片数据、五种 mock 场景、iOS/HarmonyOS 展示或百分比资源语义。
- 后续新增无参数单位文案时无需写成 `%%`；同一解析器会统一走非格式化路径。

## 验证结果
- 红灯验证：实现前运行 `./gradlew :androidApp:compileDebugAndroidTestKotlin`，新增测试因 `Resources.localizedHealthText` 尚不存在而编译失败，确认缺失行为被捕获。
- `ANDROID_SERIAL=emulator-5556 ./gradlew :androidApp:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.example.demo.health.HealthLocalizationTest` 通过，设备端 1 条定向测试通过。
- `./gradlew :common:check :androidApp:assembleDebug` 通过；最终 APK 安装到 emulator-5556 后冷启动成功，`com.example.demo/.MainActivity` 为前台 Activity，进程存活且 `AndroidRuntime` 无异常。
- `./tools/check-sdd.sh`、`./tools/check-docs.sh`、`./tools/check-resource-maintainability.sh` 与 `git diff --check` 均通过。

## 人工修正点
- Android 插桩测试最初引用当前 source set 未提供的 `kotlin.test.assertEquals`，修正为项目已具备的 JUnit 4 `org.junit.Assert.assertEquals` 后再完成绿灯验证。
- 最终实现使用项目既有约定的 `LocalResources`，避免以 `LocalContext.current.resources` 引入 Compose 资源配置更新与 Lint 风险。

# 2026-07-21 18:12 — Figma 2031 健康卡片三端精细对齐

## 采纳内容
- [HLTH-VIS-009] 按 Figma `16:8096` 及 14 个子卡节点，把三端卡片收口为 343 宽设计基准、16 页边距、8 圆角和 114/122/178/180/188/206 类型高度；标题、主值、评估指标和周计划布局逐类对齐。
- [HLTH-VIS-010] 仪表、趋势、范围、睡眠阶段及人体图改为右侧 130/166 安全区，三端父卡与图形叶节点启用裁剪；HarmonyOS 移除会把图形推出版面的弹性满宽组合。
- [HLTH-VIS-011] 从用户本地 `app_out/assets/fonts` 提取 `COROS-APP-Bold.ttf` / `COROS-APP-Regular.ttf`，以相同哈希打包 Android、iOS、HarmonyOS，并用于主数值与单位。
- [HLTH-VIS-012] 从 Figma 今日活动节点接入原始地图缩略图、绿色日历完成标题图标与橙色跑步图标，三端文件哈希一致；其他卡片继续复用已入库的 COROS 图标和 Figma 人体资产。
- [HLTH-VIS-009] 补齐周计划一至日及英文 M/T/W/T/F/S/S 的三端资源和解析映射；公里单位按 Figma 显示为 `km`，训练负荷概览统一为青色。

## 人工审查点
- [HLTH-VIS-011] 字体来自用户提供的本地应用提取目录，技术上已完成三端同源校验；正式发布前仍需产品/法务确认字体使用许可。
- [HLTH-VIS-010] Android emulator-5556 已覆盖顶部、中部和底部滚动截图；当前没有可连接的 HDC 设备，HarmonyOS 仅完成 ArkTS 构建与结构门禁，建议目标设备再复核大字号模式。
- [HLTH-VIS-007] Figma 目标节点仍无 motion inventory，卡片保持数据终态直绘，没有新增未经设计确认的入场或循环动画。

## 验证结果
- 红灯：实现前首次运行 `./tools/check-health-card-fidelity.sh`，三端字体、固定高度与裁剪共 13 项全部失败；实现后扩充为字体/地图哈希、几何、裁剪及周标签检查并全部通过。
- `./gradlew :common:check :androidApp:assembleDebug` 通过；`xcodebuild -quiet -project iosApp/iosApp.xcodeproj -scheme IOSDemo -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build` 通过；`hvigorw assembleApp --no-daemon` 通过（未配置签名）。
- Android 最终 APK 安装到 emulator-5556，冷启动后进程 `27573` 存活且 `MainActivity` 为当前焦点，日志未发现本应用 `FATAL EXCEPTION`；截图确认周标签、COROS 数字、地图及所有右侧概览均位于卡片内。
- `./tools/check-resource-maintainability.sh`、`./tools/check-sdd.sh`、`./tools/check-docs.sh`、`git diff --check` 通过；`./tools/check-resources.sh` 仍仅报告本轮外既存的 `HarmonyOS Me is missing the language selector entry point`。

## 人工修正点
- Android 首轮截图发现周标签键缺少三端资源映射而统一回退成“健康”，已补齐资源与解析入口并在最终截图中确认显示“一二三四五六日”。
- Android 首轮训练负荷使用中性灰柱，与 Figma 青色不符；三端 renderer 已按该卡类型统一覆盖为青色。
- HarmonyOS 首次构建发现新分隔线引用了不存在的 `HEALTH_EDITOR_DIVIDER`，修正为既有 `AppColors.DIVIDER` 后构建通过。
- iOS 首次验证命令误用了不存在的 `iosApp` scheme；通过 `xcodebuild -list` 确认实际 scheme 为 `IOSDemo`，改用正确命令后构建通过。

# 2026-07-22 09:39 — HarmonyOS 恢复默认与 iOS 编辑器标题修复

## 采纳内容
- [HLTH-VIS-013] HarmonyOS“恢复默认数据”改为直接把编辑器草稿 `editingHealthCards` 重建为 `createDefaultHealthCards()`，同时清理告警和拖拽状态；不再重新加载当前持久化的删减顺序。
- [HLTH-VIS-013] `SignedInPage.ets` 移除失效的 `onRestoreDefaults` 回读回调；恢复后仍停留编辑页，只有点击保存才通过 KMP 写入默认顺序。
- [HLTH-VIS-014] iOS 新增卡片类型到本地化标题键的完整映射和统一 `editorCard` 构造器，删除卡片进入“更多每日数据”或恢复默认时不再生成空标题。
- [HLTH-VIS-014] iOS 编辑器卡片目录补齐 `TodayActivity`，确保完整 14 类卡片均可删除、重新添加和恢复。

## 人工审查点
- [HLTH-VIS-013] HarmonyOS 的恢复行为与 Android/iOS 一致：先改变未保存草稿，点击返回会放弃，点击保存才持久化。
- [HLTH-VIS-014] iOS 标题在重建当下按当前应用语言解析；编辑页本身没有语言切换入口，因此不会在编辑过程中产生语言与草稿不同步。
- 当前无可连接 HDC 设备，HarmonyOS 交互由状态路径审查、专项门禁和完整 ArkTS 构建验证；建议真机点击删除→恢复→保存再做一次验收。

## 验证结果
- 红灯：实现前 `./tools/check-health-card-editor-regressions.sh` 四项全部失败，准确检出 HarmonyOS 未重置草稿/仍调用错误回调，以及 iOS 缺少标题构造/仍使用空标题。
- 绿灯：修复后专项门禁通过，并新增 iOS `TodayActivity` 完整目录检查。
- `xcodebuild -quiet -project iosApp/iosApp.xcodeproj -scheme IOSDemo -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build` 通过。
- `hvigorw assembleApp --no-daemon` 通过；仅保留项目既有弃用 API 与未配置签名警告。

## 人工修正点
- HarmonyOS 原实现把“恢复默认”误解为重新调用 `loadHealthDataFromKMP()`，该方法读取的仍是用户已保存顺序，因此视觉上完全无变化；修正为编辑器内部草稿赋值。
- iOS 原 `inactive` 和恢复按钮都使用 `title: ""` 创建卡片，导致图标存在但标题消失；修正为稳定类型键映射。
- 排查 iOS 元数据目录时发现其只有 13 类卡片，补入此前新增的“今日活动”，避免单独删除该卡后无法找回。

# 2026-07-22 09:54 — 健康卡片 iOS/HarmonyOS 资源语义补齐

## 采纳内容
- [HLTH-VIS-015] 以 Android `AppImages.Health` 为语义基线，三端资源目录补齐活动地图、今日运动标题图、跑步图和人体正反面图入口；三端卡片 renderer 改为只通过语义资源入口访问。
- [HLTH-VIS-016] iOS 增加 `todayActivity` 及 `iconForCardType` 显式映射；HarmonyOS 增加按类型 ID 解析的 `healthCardIcon(typeName)`，编辑、添加和详情场景不再用整数索引回退。
- [HLTH-VIS-016] 今日运动的通用图标三端统一为 Android 基线 `icon_small_training_effect`，主页卡片标题仍保留 Figma 专用 `health_today_header`。
- [HLTH-VIS-015] 将 HarmonyOS 步数、卡路里、活动时长 PNG 规范化为与 Android 解码像素一致的 iOS PNG 副本，并在专项门禁中要求 20 组 iOS/HarmonyOS 健康 PNG 逐文件同哈希。

## 人工审查点
- 对 25 组健康图像做了解码像素核对：22 组 RGBA 尺寸与像素完全一致；HarmonyOS 的步数、卡路里、活动时长 3 组仅透明像素 RGB 值不同，alpha 和可见内容一致；未二次转码，而是直接使用已与 Android 解码像素一致的 iOS PNG 规范化透明像素数据。
- 本轮只收口健康首页/编辑/详情的图像资源语义，没有改动账户、认证或导航资源。
- HarmonyOS 无可连接 HDC 设备，已用完整 ArkTS 构建验证；仍建议在目标设备上人工点开“今日运动”详情和编辑页核对图标。

## 验证结果
- 红灯：扩充 `./tools/check-health-card-fidelity.sh` 后首次运行报告 23 项失败，覆盖三端概览图语义入口、renderer 直接资源引用、iOS 今日运动映射和 HarmonyOS 编辑/详情映射；追加 PNG 同哈希检查后又精确红灯检出 3 组透明像素未规范化资源。
- 绿灯：`./tools/check-health-card-fidelity.sh` 与 `./tools/check-health-card-editor-regressions.sh` 均通过；`./tools/check-resource-maintainability.sh` 通过（37 组共享图片、2 个 Raw、196 个共享文字键）。
- `./gradlew :androidApp:assembleDebug` 通过；`xcodebuild -project iosApp/iosApp.xcodeproj -scheme IOSDemo -sdk iphonesimulator ... build` 通过；`hvigorw assembleApp --no-daemon` 通过（未配置签名）。
- `./tools/check-sdd.sh` 与 `./tools/check-docs.sh` 通过；`./tools/check-resources.sh` 仍只报告本轮外已知的 `HarmonyOS Me is missing the language selector entry point`。

## 人工修正点
- 原始文件 SHA 不同的原因是 Android 使用 WebP、iOS/HarmonyOS 使用 PNG，以及透明像素的非可见 RGB 差异；修正了“哈希不同就是资源内容不同”的误判，同时把同为 PNG 的 iOS/HarmonyOS 副本收口为字节一致。
- iOS 原未显式处理 `TodayActivity`，初始卡片会回退为心率图标，而恢复后又变为专用头图；现已统一为通用训练效果图标。
- HarmonyOS `TodayActivity` 原与 `HeartRate` 共用索引 6，现改为类型映射，并将保留的整数元数据修正为与训练效果对应的索引 2。

# 2026-07-22 10:57 — 健康模块完整数据与多用户快照持久化

## 采纳内容
- [HLTH-PERSIST-001][HLTH-PERSIST-002] `HealthDashboardSnapshot` 升级为 schema v2，按 `userId` 保存完整 `HealthDashboardData` 和卡片配置；加载已有完整快照时直接重建 UI，不再用场景模板覆盖模块值。
- [HLTH-PERSIST-003][HLTH-PERSIST-004] Demo 场景选择改为生成并持久化一份完整模块数据，卡片顺序保存只修改配置、不丢健康数据；`ReadFailure` 不覆盖最后一份有效快照。
- [HLTH-PERSIST-003] Android、iOS、HarmonyOS 场景选择后都立即回读新版快照，避免只更新勾选状态而卡片仍显示旧数据。
- [HLTH-PERSIST-005] common 新增无平台依赖的完整 JSON codec，支持 14 类模块、趋势点、睡眠阶段、旧场景配置快照迁移、损坏数据安全忽略与未知字段兼容。
- [HLTH-PERSIST-006] 内存数据源支持导出/替换多用户集合，账户删除同步清理对应健康快照；20 个完整用户快照集合往返并保持在 1 MB Preferences 预算内。
- [HLTH-PERSIST-007] HarmonyOS `health_json` 改为保存全部用户领域快照集合；认证 JSON 不再导出 `_health`，页面移除全局 `health_card_order`，仅保留旧 `_health` 的一次性迁移路径。

## 人工审查点
- [HLTH-PERSIST-003] `sourceScenario` 只用于 Demo 选择器与迁移来源展示，完整 `dashboardData` 才是恢复权威；正式产品移除场景选择器时可删除该元数据。
- [HLTH-PERSIST-006] 当前 Preferences/JSON 方案只面向约 20 位 Demo 用户和每人一份最新小型快照；如果以后引入长期、高频真实健康采样，应另立 Spec 迁移数据库并补充真实健康数据的加密与备份策略。
- [HLTH-PERSIST-007] HarmonyOS 无连接设备，本轮完成 native bridge 与 ArkTS 构建、快照集合自动测试和结构审查；建议在目标设备上执行用户 A/B 切换、改场景、重启后复核。

## 验证结果
- 红灯：实现前 `./gradlew :common:testAndroidHostTest` 因 `sourceScenario/dashboardData/schemaVersion` 与集合 codec 尚不存在而编译失败，准确捕获缺失行为。
- 绿灯：`./gradlew :common:check` 通过，`HealthDashboardUseCaseTest` 增至 31 条，覆盖完整往返、模块数据优先、场景覆盖、配置保留、旧快照迁移、损坏数据、账户删除和 20 用户集合。
- `./gradlew :androidApp:assembleDebug`、`xcodebuild -project iosApp/iosApp.xcodeproj -scheme IOSDemo -sdk iphonesimulator -configuration Debug -derivedDataPath /private/tmp/demo-ios-derived CODE_SIGNING_ALLOWED=NO build` 通过。
- HarmonyOS `./gradlew ohosArm64Binaries` 成功生成并链接 `libkn.so`；`hvigorw assembleApp --no-daemon` 生成更新后的 HAP。`check-health-card-editor-regressions.sh`、`check-health-card-fidelity.sh`、`check-docs.sh` 与 `git diff --check` 通过。

## 人工修正点
- 首版实现尝试复用 `kotlinx-serialization-json`，Android/iOS 通过但 HarmonyOS bridge 红灯报告该库没有 `ohos_arm64` variant；已撤回依赖，改为 common 自包含递归 JSON parser/encoder，并重新通过三端构建。
- HarmonyOS 原来同时依赖认证快照 `_health`、单用户 `health_json` 和页面 `health_card_order`，多用户会互相复用；现统一为按 `userId` 索引的领域快照集合，旧 `_health` 仅作迁移输入。
# 2026-07-22 11:25 — 场景选择与健康刷新持久化解耦

## 采纳内容

- [HLTH-PERSIST-003] 将场景选择改为仅记录当前用户的运行期待刷新场景，不立即生成模块数据、不更新健康首页、不写持久化快照。
- [HLTH-PERSIST-003] 新增共享层 `refresh` 提交边界：刷新成功后才生成并保存完整 `HealthDashboardData` 与 `sourceScenario`；Android、iOS、HarmonyOS 均改由刷新入口调用。
- [HLTH-PERSIST-003] HarmonyOS 选择场景时不再调用 `loadHealthDataFromKMP` 或 `saveStoreSnapshot`，刷新成功后才回读 KMP 数据并导出全用户 `health_json`。

## 人工审查点

- [HLTH-PERSIST-003] 待刷新场景属于 Demo 运行期交互状态，不跨进程保存；应用在刷新前退出后，重新进入仍以最后一次成功刷新快照为准。
- [HLTH-PERSIST-003] `ReadFailure` 刷新失败时首页与持久化快照保持旧值，当前页面不切换到空白或损坏状态。

## 验证结果

- 红灯：新增刷新语义测试后首次执行 `./gradlew :common:testAndroidHostTest`，因 `HealthDashboardStore.refresh` 尚不存在而编译失败。
- 绿灯：`./gradlew :common:testAndroidHostTest`、`./gradlew :common:check :androidApp:assembleDebug`、`:common:linkDebugFrameworkIosSimulatorArm64` 均通过；`HealthDashboardUseCaseTest` 增至 33 条，共享测试合计 76 条。
- iOS：`xcodebuild -quiet -project iosApp/iosApp.xcodeproj -scheme IOSDemo -sdk iphonesimulator -configuration Debug -derivedDataPath /private/tmp/demo-ios-derived CODE_SIGNING_ALLOWED=NO build` 通过。
- HarmonyOS：bridge `ohosArm64Binaries` 与 `hvigorw assembleApp --no-daemon` 通过；仅保留既有 KSP、弃用 API 和未签名构建警告。

## 人工修正点

- [HLTH-PERSIST-003] 根据反馈纠正上一轮“选择场景立即覆盖并持久化”的语义，将刷新恢复为唯一的数据获取和提交动作。
- [HLTH-PERSIST-005] 旧 `_health` 迁移仍在 bridge 内显式执行一次选择加刷新，避免迁移路径被新的延迟提交语义中断。

## 下轮交接

- 已完成：场景选择、刷新生成、首页更新和完整快照持久化已拆分，并完成三端构建与共享层自动测试。
- 未完成 / 阻塞项：没有可连接的 HarmonyOS 设备，尚未做真机下拉刷新与重启恢复验收。
- 下轮起步建议：先读 `spec/health-dashboard-persistence.md` 的 `HLTH-PERSIST-003`，再在三端分别验证“选择后旧卡片不变、刷新后新卡片出现、重启后仍为刷新成功的数据”。

# 2026-07-22 11:51 — 健康首页空态卡片自适应高度

## 采纳内容

- [HLTH-VIS-009][HLTH-VIS-017] 将卡片几何从“按 visual kind 强制固定高度”调整为“空态按显式状态自适应、有数据卡按 kind 保持设计最小高度”；Figma 单行空态的 82 作为最小高度，多行或放大字体可继续撑高。
- Android 使用 `HealthCardStatus.Empty`、`heightIn(min = ...)` 和不截断的 14sp 空态说明；iOS 在平台模型中保留 `status/isEmpty` 并移除固定 `maxHeight`；HarmonyOS bridge JSON 新增 `status`，ArkUI 使用 `constraintSize(minHeight)`。
- 新增 `tools/check-health-card-adaptive-layout.sh`，覆盖三端状态桥接、自适应容器和旧固定高度写法回归；同步修订既有视觉门禁与 `HLTH-VIS-009` 规范表述。

## 人工审查点

- 空态判定以 common 的 `HealthCardStatus.Empty` 为唯一权威，不能以 `primaryValue/chartPoints/metrics` 是否为空推断，因为部分数据卡可能具有值但仍采用特殊状态布局。
- 右侧图表的 130/166 安全区和父级圆角裁剪保持不变；自适应的是卡片外壳与说明文字，不是任意拉伸图表。
- 当前没有连接的 Android/HarmonyOS 设备，尚未执行 320/375/430 宽度、中文/英文与放大字体下的 AllEmpty/PartialMissing 截图；建议设备可用时按该矩阵人工复核。

## 验证结果

- 红灯：实现前 `./tools/check-health-card-adaptive-layout.sh` 报告 12 项失败，准确检出三端固定高度、iOS/HarmonyOS 状态丢失及 Harmony bridge 未输出状态。
- 绿灯：实现后自适应布局门禁、`check-health-card-fidelity.sh`、`check-health-card-editor-regressions.sh` 和 `git diff --check` 均通过。
- `./gradlew :common:check :androidApp:assembleDebug` 与 iOS 模拟器 `xcodebuild` 通过；iOS 仅保留既有弃用 API、未使用返回值和脚本输出声明警告。
- `harmony-kmp-bridge/gradlew ohosArm64Binaries` 与 HarmonyOS `hvigorw assembleApp --no-daemon` 通过；仅保留既有 KSP/编译器、弃用 API、资源重名和未签名警告。
- `check-resource-maintainability.sh`、`check-sdd.sh`、`check-docs.sh` 通过；全量 `check-resources.sh` 仍只报告本轮外既有的 HarmonyOS“我”页缺少语言选择入口。

## 人工修正点

- 初次 bridge 验证误用了根 Gradle wrapper 的 `-p harmony-kmp-bridge`，触发 Kuikly/Kotlin 插件环境错误；按项目文档改用 bridge 自带 wrapper 后构建通过。
- 初次 HarmonyOS 应用命令未设置 DevEco 内置 Node 环境而失败；补齐 `NODE_HOME/DEVECO_SDK_HOME/PATH` 后完整 ArkTS 构建通过。
- Harmony JSON 首版补丁在 `status` 字段前多写了一个引号，代码审查时在运行前修正为合法的 `,\"status\":\"...\"` 字段拼接。

# 2026-07-22 13:57 — 健康损坏态、鸿蒙宽度与动画、iOS 顶部刷新修复

## 采纳内容

- [HLTH-PERSIST-008] common 跨语言门面新增一次性健康错误读取；Android 直接接收刷新失败结果，iOS/HarmonyOS 显式传递 `CorruptedData`，三端在失败时隐藏旧摘要与卡片并展示独立损坏态，成功刷新后自动恢复。
- [HLTH-VIS-018] HarmonyOS 卡片改为全宽 Row 统一扣除左右 16vp 页边距，卡片 Column 仅占剩余宽度，避免负荷、评估、恢复、能力、趋势、睡眠和体型等有数据子树反向撑宽页面。
- [HLTH-VIS-019] HarmonyOS 手表 Lottie 接入 `refreshing` 状态：刷新开始从首帧播放一次，结束复位，未刷新时保持静止。
- [HLTH-VIS-020] iOS 下拉手势在第一次位移时锁定是否从列表顶部开始；非顶部起手的整次手势不再显示提示或触发刷新。

## 人工审查点

- 损坏态只覆盖本次前台读取结果，不删除或覆盖最后一份有效持久化快照；这是错误反馈与数据恢复能力的分离。
- HarmonyOS 卡片宽度已通过 ArkTS 编译和结构门禁，但当前没有可连接的 HarmonyOS 设备，仍建议在 320/375/430vp 真机或预览上复核全部有数据卡边界。
- iOS 顶部资格按单次手势锁定；阈值仍等价于原 80pt 原始拖动距离，不改变刷新等待时长。

## 验证结果

- 红灯：新增 `./tools/check-health-dashboard-runtime-states.sh` 后首次运行报告 11 项失败，覆盖三端损坏态、iOS 顶部手势锁、HarmonyOS 卡片外壳和 Lottie 状态驱动。
- 绿灯：专项门禁、`check-health-card-adaptive-layout.sh`、`check-health-card-fidelity.sh`、`check-health-card-editor-regressions.sh` 与 `git diff --check` 均通过。
- `./gradlew :common:check :androidApp:assembleDebug` 通过；iOS 模拟器 `xcodebuild` 通过，仅保留既有弃用 API、未使用返回值和脚本输出声明警告。
- Harmony bridge `linkDebugSharedOhosArm64` 与 `hvigorw assembleApp --no-daemon` 通过；仅保留既有 KSP、生成 C++、弃用 API、资源重名和未签名警告。
- `./tools/check-sdd.sh` 与 `./tools/check-docs.sh` 通过。

## 人工修正点

- 原实现把跨语言失败压缩成 null/`{}`，平台无法区分损坏和无数据；现改为消费一次的稳定错误名，避免错误长期残留又不暴露平台 UI 类型到 common。
- HarmonyOS 原卡片同时使用百分比宽度、内外边距和固定宽子图；现把页面边距所有权上移到 Row，卡片本体不再自行计算 `calc(100% - 32vp)`。
- HarmonyOS Lottie 原配置 `autoplay: false` 且加载后从未调用 `play`；现由刷新状态显式调用播放，并保留完成/结束复位。

# 2026-07-22 14:11 — 按实机反馈修正鸿蒙整屏卡片与 iOS 中段误刷新

## 采纳内容

- [HLTH-VIS-018] 根据用户实机截图重新定位：鸿蒙不是外壳横向边距未生效，而是 6 个有数据 Visual 分支的 `height('100%')` 在 Scroll/Refresh 中取得了视口高度；现全部改为内容固有高度，并继续由卡片类型最小高度控制设计尺寸。
- [HLTH-VIS-020] 删除 iOS 的顶部 Preference、自定义位移、`simultaneousGesture` 和 `DragGesture`，改用 SwiftUI `ScrollView.refreshable`，由系统滚动容器保证只有到达内容顶部后继续下拉才进入刷新。
- 强化 `check-health-dashboard-runtime-states.sh`：明确禁止 Harmony renderer 的 `height('100%')`，要求 iOS 存在 `refreshable` 且不存在自定义拖拽手势。

## 人工审查点

- 截图中的鸿蒙“本周负荷”宽度本身仍在左右 16vp 边距内，异常是卡片高度占满屏幕；本轮按可见证据修正纵向测量根因。
- iOS 使用系统刷新控件后会保留系统刷新指示，同时顶部手表 Lottie 仍由 `viewModel.isLoading` 驱动；不再维护一套容易与 ScrollView 冲突的手势状态机。
- 当前工作环境仍无可控制的 HarmonyOS 输入设备；ArkTS 构建能验证类型和组件语法，最终实机尺寸需使用用户同一设备再次复核。

## 验证结果

- 红灯：强化后的专项门禁首次报告 4 类失败：缺少 `refreshable`、残留 `DragGesture`、残留 `simultaneousGesture`、Harmony renderer 残留 `height('100%')`。
- 绿灯：实现后专项门禁全部通过，确认 iOS 自定义拖拽代码和 Harmony 数据 renderer 的 100% 高度均已清零。
- iOS 模拟器 `xcodebuild` 通过，仅保留既有弃用 API、未使用返回值与脚本输出声明警告。
- HarmonyOS `hvigorw assembleApp --no-daemon` 通过，仅保留既有弃用 API、资源重名和未签名警告。

## 人工修正点

- 上一轮误把鸿蒙问题归因于横向宽度外壳，结构门禁虽然转绿，但没有覆盖截图中的纵向百分比高度；本轮将实机失败证据写回同一 Spec/TRACE，并把遗漏模式加入回归门禁。
- 上一轮试图在 SwiftUI 手势层缓存 `isAtScrollTop`，仍会与 ScrollView 自身手势竞争；本轮撤销该方案，改用平台原生刷新边界。

# 2026-07-22 14:21 — iOS 原生刷新与右上角手表 Lottie 显式同步

## 采纳内容

- [HLTH-VIS-021] `HealthDashboardViewModel` 新增单调递增的 `syncCycle`，每次系统 `refreshable` 真正进入刷新时先递增周期，再设置 `isLoading`。
- `HeroTopRow` 接收刷新周期，并以 `syncCycle-isSyncing` 作为 Lottie 实例 ID：开始刷新时强制创建播放实例，刷新结束时强制创建首帧暂停实例。
- 保留 iOS 原生顶部刷新语义；中段下滑不会调用 `refresh()`，因此不会改变周期、同步文案或手表动画。

## 人工审查点

- 三端卡片高度策略一致：空态采用 82 最小高度并由文案撑高；有数据卡采用类型最小高度并允许固有内容撑高。HarmonyOS 删除的是滚动视口级 100% 高度，并未恢复固定高度。
- iOS 系统刷新指示、顶部同步文案和手表动画现在共享 `refresh()` 的同一个 `isLoading` 生命周期；`syncCycle` 只用于突破 Lottie SwiftUI 实例复用。
- 当前仅完成模拟器构建和结构门禁，仍建议在同一 iPhone 模拟器上连续刷新两次，确认两次动画都从首帧开始并在约 4.46 秒后复位。

## 验证结果

- 红灯：扩充专项门禁后首次报告 5 项失败，覆盖 View 未传周期、ViewModel 无周期状态/递增、Hero 无复合 ID及仍依赖 `animationDidFinish` 自行换 ID。
- 绿灯：实现后 `check-health-dashboard-runtime-states.sh` 全部通过；确认周期从原生刷新链路传到 Lottie，旧完成回调已删除。
- iOS 模拟器 `xcodebuild` 通过；仅保留既有弃用 API、未使用返回值和脚本输出声明警告。

## 人工修正点

- 原 Hero 仅依赖 `isSyncing` 与 `animationDidFinish` 内部随机 UUID，动画完成时间和数据刷新生命周期彼此独立；现由外部刷新周期统一控制开始与结束，避免首次能播、后续复用漏播或完成后自行重启。

# 2026-07-22 14:33 — iOS 单一原生 pan 链与命令式手表 Lottie

## 采纳内容

- [HLTH-VIS-020] 撤回系统 `refreshable`，恢复原自定义下拉位移、同步提示和回弹视觉；触发阈值调整为 64pt，改善系统刷新难触发的问题。
- 新增 `ScrollViewPanObserver`，只给 SwiftUI ScrollView 底层已有的 `panGestureRecognizer` 增加 target；在 `.began` 使用真实 `contentOffset/adjustedContentInset` 锁定顶部资格，`.changed/.ended` 使用同一识别器的 translation。
- [HLTH-VIS-021] 手表改为 `UIViewRepresentable + LottieAnimationView`：刷新开始直接 `stop → currentProgress=0 → play`，刷新结束直接 `stop → currentProgress=0`。
- 保留 `syncCycle` 防止重复刷新周期被合并；中段起手不会调用 `refresh()`，因此不会显示同步态或播放 Lottie。

## 人工审查点

- Observer 没有创建新的手势识别器，不会阻止 ScrollView 正常滚动；它只监听系统 pan 的状态和位移。
- 顶部资格只在 `.began` 计算一次；从中段开始、同一次拖动途中到达顶部仍保持无资格，必须松手后从顶部发起新手势。
- 当前阈值 64pt，比原 80pt 和系统刷新更易触发；视觉位移仍按 0.4 比例、最多 250pt，触发后保持 55pt 直到约 4.46 秒刷新结束。

## 验证结果

- 红灯：最终专项门禁先检出缺少单一 pan 回调链、仍存在独立 DragGesture/simultaneousGesture，以及 Lottie 未直接 play/stop/归零。
- 绿灯：`check-health-dashboard-runtime-states.sh` 通过，确认没有 `.refreshable`、SwiftUI DragGesture 或 simultaneousGesture，顶部锁定和命令式 Lottie 标记完整。
- iOS 模拟器 `xcodebuild` 通过；仅保留既有弃用 API、未使用返回值和脚本输出声明警告。

## 人工修正点

- 原生 `refreshable` 虽能保证顶部边界，但触发阈值和系统 spinner 与计划视觉不一致；本轮按用户选择恢复自定义体验，同时保留 UIKit 的真实滚动边界。
- 上一版通过 SwiftUI ID 重建尝试驱动 Lottie，运行时仍未播放；现不再依赖视图 diff，直接控制同一个动画实例。

# 2026-07-22 14:39 — iOS 手表 Lottie 收口到正常 30pt 尺寸

## 采纳内容

- [HLTH-VIS-022] `WatchSyncLottieView` 不再直接返回具有大固有尺寸的 `LottieAnimationView`，改为返回裁剪的透明 UIView 容器。
- 内部动画关闭 autoresizing mask，以 leading/trailing/top/bottom 四条 Auto Layout 约束填满容器；动画和容器均开启 `clipsToBounds`，SwiftUI 外层继续使用 30×30pt 并二次裁剪。
- 命令式刷新同步逻辑保持不变，长按场景选择手势仍绑定在外部 30pt 区域。

## 人工审查点

- 30×30pt 与 Android/HarmonyOS 手表语义尺寸一致，略大于旁边 23×23pt 日历，但不会覆盖状态栏、日期或活动时长指标。
- 本轮只修复 UIKit Lottie 的测量和溢出，没有缩放动画资源文件，也没有改动播放周期与刷新逻辑。

## 验证结果

- 红灯：扩充专项门禁后首次报告 6 项失败，覆盖缺少裁剪容器、autoresizing mask 和四边约束。
- 绿灯：`check-health-dashboard-runtime-states.sh` 通过；iOS 模拟器 `xcodebuild` 通过，仅保留既有警告。
- 已将新构建安装到已启动的 iPhone 17 模拟器并启动，`simctl` 截图 `/private/tmp/demo-ios-watch-size.png` 人工核对通过：手表位于右上角 30pt 区域，没有溢出。

## 人工修正点

- 仅设置 SwiftUI `.frame(width: 30, height: 30)` 对直接桥接的 UIKit Lottie 不足，截图中动画仍按 composition 固有尺寸绘制；现由 UIKit 容器承担真实尺寸约束，SwiftUI frame 只负责顶部栏布局。

# 2026-07-22 17:15 — 三端健康卡片改为内容固有高度

## 采纳内容

- [HLTH-VIS-023] 删除 Android `FigmaCardHeight/heightIn`、iOS `cardMinimumHeight/figmaCardHeight` 和 HarmonyOS `minimumCardHeight/constraintSize`，三端公共卡片外壳不再维护按 visual kind 区分的最低高度表。
- Android 视觉根节点由垂直 `fillMaxSize` 改为 `fillMaxWidth`；训练量评估的垂直 `weight` 改为明确 16dp 间距。iOS 与 HarmonyOS 同步采用 16pt/vp 的说明到指标间距。
- 三端分发入口统一为可检索的 `HealthCardVisualContent/VisualContent` 命名，review 时按“列表入口 → 卡片外壳 → visual kind 分发器 → 类型视觉 → 图形原语”定位。
- 更新 [HLTH-VIS-004/009/017/018/023] Spec、TRACE、专项门禁和持久 Learnings，明确 Figma 高度只作设计对照。

## 人工审查点

- 水平方向的 `Spacer/weight/layoutWeight` 仍用于左右分栏，不属于本次禁止范围；本轮只移除了滚动方向依赖不确定剩余高度的填充。
- 地图、柱图、仪表、睡眠阶段和人体图片继续保留明确宽高，因此取消外层最小高度不会取消图表安全区；长文案和指标会自然增高卡片。
- KMP `HealthCardVisualData` 协议本轮保持不变，正常态必填数据继续由既有 common 测试约束；强类型 sealed visual 如需实施应单独进行跨端协议迁移。

## 验证结果

- 红灯：更新 `check-health-card-adaptive-layout.sh` 后首次报告 10 项失败，准确覆盖三端类型高度表、外层最小高度和训练评估垂直剩余空间填充。
- 绿灯：`check-health-card-adaptive-layout.sh`、`check-health-card-fidelity.sh`、`./gradlew :common:check`、`./gradlew :androidApp:assembleDebug` 全部通过。
- iOS 模拟器 `xcodebuild ... IOSDemo ... build` 通过，仅保留既有脚本输出声明和未使用返回值 warning；HarmonyOS `hvigorw assembleApp --no-daemon` 通过，仅保留既有弃用、未签名等 warning。

## 人工修正点

- 初版专项门禁误把横向 `Spacer(weight)` 和活动卡的横向 `Spacer(minLength:)` 也列为禁止项；已改为检查训练量评估的明确垂直间距，避免阻止合法的横向自适应分栏。
- 没有直接把所有高度常量改为 0；而是删除整套外层高度策略，避免留下看似可配置但实际失效的尺寸入口。

# 2026-07-23 11:45 — Android 健康首页按 Figma 2031 精修数据图形

## 采纳内容

- [HLTH-VIS-024] Android 将原通用仪表拆分为体力恢复与跑步/骑行能力两套绘制器：恢复使用数据弧、Figma 原始白色人体和状态文案且无指针；能力使用分段半圆、0/100 端点与夹紧后的数据指针。
- [HLTH-VIS-024] 心率改为约 1dp 细线波形，压力改为蓝/绿/黄/橙分类密集细柱；本周负荷补齐暗色轨道和日期；静息心率与 HRV 分别使用单色范围尺和四色分段带；睡眠保留四阶段数据序列。
- [HLTH-VIS-025] 顶部卡路里圆弧改为 0–800 动态比例：暗色轨道始终完整，数值弧按 `clamp(calories, 0, 800) / 800` 绘制，颜色随占比由亮黄加深到橙黄，超限仍显示真实数值。
- 恢复状态人物取自 Figma 2031 节点 `16:8771` 返回 SVG 的原始路径，Android 以 VectorDrawable 接入；iOS/HarmonyOS 本轮未修改。

## 人工审查点

- 卡路里 769 对应 96.125% 弧长，模拟器画面保留短暗色余量；310 对应 38.75%，800/900 均满弧，900 文本仍显示 900。
- common/protobuf 数据契约没有变化：已有 `progress/chartPoints/range/sleepStages` 足以驱动全部图形；800 是顶部 Android 展示刻度常量，不被错误写成健康业务规则。
- 工作区原有 iOS、HarmonyOS 和文档未提交变更未被覆盖；后续两端应按 Spec 参数独立移植，不直接复制 Compose 类型。

## 验证结果

- 红灯：`./gradlew :androidApp:testDebugUnitTest --tests com.example.demo.health.DashboardVisualMathTest` 首次因 `calorieArcProgress/clampedVisualProgress/abilityNeedleAngleDegrees` 缺失而编译失败，证明测试可捕获未实现行为。
- 绿灯：同一专项单测通过；`./gradlew :common:check`、`./gradlew :androidApp:assembleDebug`、`./tools/check-health-card-fidelity.sh`、`./tools/check-resource-maintainability.sh`、`./tools/check-sdd.sh` 全部通过。
- 已把 APK 安装到 emulator-5554 并人工核对 `/private/tmp/health-2031-top.png`、`health-2031-recovery.png`、`health-2031-middle.png`、`health-2031-bottom.png`：顶部弧、恢复/能力仪表、心率/压力、睡眠、HRV/静息心率均无越界或裁剪异常。

## 人工修正点

- 原恢复卡错误复用了能力仪表并带有指针；现按 2031 改为恢复弧和中央人体。原能力盘是连续弧且缺少 0/100；现改为分段盘并由数据决定指针。
- 原心率与压力共用粗胶囊柱，原 HRV 与静息心率共用通用范围尺；现按卡片类型二次分发，避免 `visual.kind` 相同就错误复用同一图形。
- 初次沙箱内下载 Figma 资产因 DNS 受限失败，经批准后只下载指定节点资产；解析为 20.3779×29.9058 SVG 路径并转换为 Android 矢量资源，没有引入整卡截图。

# 2026-07-23 13:52 — 修正 Android 卡路里正圆弧与半小时心率区间柱

## 采纳内容

- [HLTH-VIS-026] 顶部卡路里弧的 Canvas 从 142×116dp 椭圆包围盒改为 116×116dp 正方形，保留 135° 起始、270° 总扫角、5dp 线宽、暗色轨道和 0–800 动态占比。
- [HLTH-VIS-027] proto/domain/mock 新增 `HeartRateInterval(startMinute, minimum, maximum, average)`；正常场景提供从 00:00 到 23:30 的 48 个半小时时间片。
- [HLTH-VIS-027] `HealthChartPoint` 增加可选 minimum/maximum/average；Android 心率图不再插值，也不再从统一基线画线，而是每个时间片直接连接自己的最低与最高心率。
- 保留旧 `HeartRateMock.samples` tag 4；JSON 与 mock 转换在 intervals 缺失时把旧样本迁移为 min=avg=max 的退化半小时区间。Harmony bridge 同步透传新增可选字段，但本轮未修改 iOS/HarmonyOS 图形 renderer。

## 人工审查点

- Figma 节点 `16:8651` 仍使用 166×44 图表安全区；用户补充的业务含义已落实到数据契约，区间柱端点不再是无法解释的视觉波形。
- 心率纵轴以当前 48 个区间的全局最低/最高值归一化，并保留 3dp 上下安全边距；average 不参与柱端点，只用于卡片主值和统计。
- schema 版本由 2 提升到 3，新 proto 字段使用 tag 5，不复用或删除历史 samples tag。

## 验证结果

- 红灯：common 专项测试首次因 `HealthChartPoint.minimum/maximum/average`、`HeartRate.intervals` 和 `HeartRateInterval` 缺失而编译失败；Android 专项测试首次因正圆直径和区间归一化函数缺失而失败。
- 绿灯：两组专项测试通过；`./gradlew :common:check`、`./gradlew :androidApp:assembleDebug`、健康视觉/资源维护/文档/SDD 门禁均通过。
- Harmony bridge 首次误用根 Gradle 9 wrapper，在 KNOI 插件配置阶段因 `DefaultArtifactPublicationSet` 不兼容失败；改用 `harmony-kmp-bridge/gradlew ohosArm64Binaries` 后构建成功，仅有既存 KSP、Xcode 版本和生成 C++ return-path warnings。
- emulator-5554 安装刷新后，`/private/tmp/health-round-arc-fixed.png` 确认卡路里弧为正圆，`/private/tmp/health-half-hour-heart-rate.png` 确认 48 根心率柱分别连接自身最低与最高值且不再依赖统一基线。

## 人工修正点

- 上一轮直接把 Figma 外部 142×116 占位用作 `drawArc` 包围盒，导致圆弧横向拉宽；本轮把外部占位和圆形绘制区域分离。
- 上一轮把单值样本插值到约 2dp 间隔并围绕固定基线绘制，只能表达视觉起伏，不能说明每根柱的统计意义；本轮删除插值路径，柱数与半小时时间片严格一一对应。

# 2026-07-23 14:34 — 接入四组五分钟心率数据与 Android 七日计划切换

## 采纳内容

- [HLTH-VIS-028] 将 `heart.md` 的正常 1、正常 2、正常 3、异常四组各 288 个 5 分钟采样接入 common，分别映射 `Normal`、`PartialMissing`、新增 `Normal3` 和 `Abnormal`；每 6 点聚合为半小时 minimum/maximum/四舍五入 average，共 48 根区间柱。
- [HLTH-VIS-028] `HeartRate`、proto、手工 mock 与 JSON 快照增加 `fiveMinuteSamples`，schema 提升到 4；旧 `samples` 与退化区间迁移逻辑继续保留。
- [HLTH-VIS-029] 新增七日 `WeeklyDayPlan` 共享契约及快照字段，Android 周计划日期圆点独立消费点击并在卡内切换名称、时长和训练负荷；卡片日期外区域仍进入详情。
- 新增 `Normal3` 场景和三端本地化资源/选择入口；Harmony bridge 透传 `weeklyDayPlans`，为 iOS/HarmonyOS 后续实现同一交互保留共享数据。

## 人工审查点

- `PartialMissing` 继续保留“部分其他卡片缺失”的场景语义，但其心率使用用户提供的正常数据 2；`AllEmpty` 和 `ReadFailure` 不承载心率，因此新增 `Normal3` 而没有破坏空态/失败态。
- 正常场景七日计划当前为周一/三/五休息，周二 45 分钟负荷 35、周四 102 分钟负荷 78、周六 60 分钟负荷 90、周日 93 分钟负荷 110，总计划时长 300 分钟；这些计划内容仍可由产品按卡片数据继续调整。
- Android 已完成日期点击交互；iOS 可直接读取 KMP `weeklyDayPlans`，HarmonyOS 已获得桥接字段，但两端卡片 renderer 尚未增加日期点击状态，需后续按同一规则实现。

## 验证结果

- 红灯：新增 common 测试首次因 `aggregateFiveMinuteHeartSamples`、`Normal3`、`fiveMinuteSamples`、`dayPlans` 缺失而编译失败。
- 绿灯：`./gradlew :common:check`、`./gradlew :androidApp:testDebugUnitTest --tests com.example.demo.health.DashboardVisualMathTest`、`./gradlew :androidApp:assembleDebug`、`check-resource-maintainability.sh`、`check-health-card-fidelity.sh`、`check-sdd.sh`、`check-docs.sh` 和 `git diff --check` 通过。
- Harmony KMP bridge 使用自身 wrapper 执行 `./gradlew ohosArm64Binaries` 通过；保留既有 KSP 版本和生成 C++ return-path warnings。
- 全量 `./tools/check-resources.sh` 仍因本轮外既存的 HarmonyOS“我”页缺少语言选择入口失败；本轮涉及的三端新增文案已通过 `check-resource-maintainability.sh` 的 196 个共享键一致性检查。
- emulator-5554 验证：场景选择器显示“正常数据 3”；该场景心率卡显示由 288 点计算出的日平均 66；周二日期点击后仍停留健康首页，并从周四 102/78 切换为周二 45/35；旧快照的非训练日显示“休息日”。

## 人工修正点

- 首次模拟器点击旧快照的周二显示通用“健康数据暂时不可用”，原因是新增休息日语义键未进入 Android 解析映射且旧快照没有七日字段；已补齐三端资源、Android/Harmony 解析映射，并为旧快照生成七天兼容数据。
- 初始心率 mock 通过时间索引余数人为制造最低/最高振幅；本轮删除该生成路径，柱端点完全来自对应 6 个原始采样的真实最小值和最大值。

# 2026-07-23 14:53 — 调整 Android 范围指针、快测标题与手表导航

## 采纳内容

- [HLTH-VIS-028] 从 `HealthMockScenario`、运行时 fixture、三端场景选择入口和本地化资源移除 `Normal3`；当前心率场景只启用正常 1、正常 2 和异常，空态与读取失败保持不变。
- [HLTH-VIS-030] HRV 与静息心率右侧范围图的三角指针移到指标线下方，尖端朝上指向线条；横向位置继续按当前值夹紧计算。
- [HLTH-VIS-031] 健康快测的测量时间从内容区独立行移到 `CardHeader` 右侧；common 仅在 `measuredTime` 非空时生成 caption，不再显示 `---`。
- [HLTH-VIS-032] 手表 `combinedClickable` 增加短按回调，`MainTabsScreen` 收到短按后切换 `HomeTab.Me`；长按继续打开场景选择器。

## 人工审查点

- `heart.md` 仍保留用户提供的正常数据 3 原始文本作为输入资料，但生产 Kotlin fixture 和可选场景均已移除该组。
- 健康快测标题采用左侧标题弹性占位、右侧时间单行显示；无时间时右侧不占用可见内容。
- 本轮按用户要求只完成 Android 的指针、标题和手表交互；移除 `Normal3` 属于共享场景目录变化，因此同步清理了 iOS/HarmonyOS 场景入口与资源，未改两端卡片视觉。

## 验证结果

- 红灯：`enabledHeartDataScenariosUseThreeProvidedFiveMinuteSamples` 因多余 `Normal3` 失败；`healthCheckWithoutMeasuredTimeDoesNotExposeHeaderPlaceholder` 因旧 `---` caption 失败；Android 指针测试因 `rangeMarkerVerticalBounds` 缺失而无法编译。
- 绿灯：`./gradlew :common:check`、Android `DashboardVisualMathTest`、`:androidApp:assembleDebug` 通过；`check-resource-maintainability.sh`、`check-health-card-fidelity.sh`、`check-docs.sh`、`check-sdd.sh`、三端本地化 JSON 语法和 `git diff --check` 通过。
- emulator-5554：长按手表只显示正常/部分缺失/全空/异常/损坏五个场景；短按手表进入显示“我的、个人信息、账户”的“我”页。
- `/private/tmp/health-range-header-adjusted.png` 确认 HRV 与静息心率三角均在线下，健康快测的 `15:04 测量` 与标题位于同一行；UI 节点二者 y 坐标均为 1081..1144。

## 人工修正点

- 首次模拟器短按紧跟在弹窗关闭命令后，被关闭动画吞掉；等待弹窗完全消失后单独短按，稳定进入“我”页，代码仍由同一个 `combinedClickable` 保证长短按互斥。
- 初次全量 Gradle 验证受沙箱无法创建 Gradle wrapper lock 文件影响；按批准权限重跑同一命令后构建与测试成功。

# 2026-07-23 15:16 — 将 Android 已验收健康卡片效果同步到 iOS 与 HarmonyOS

## 采纳内容

- [HLTH-VIS-024][HLTH-VIS-027] iOS 使用 SwiftUI Canvas/Shape、HarmonyOS 使用 ArkUI Canvas/Path，分别实现恢复/能力仪表、心率半小时 min–max 柱、压力趋势、静息心率/HRV 范围和睡眠阶段等专用概览图；两端新增与 Android 同源的恢复人体资源。
- [HLTH-VIS-025][HLTH-VIS-026] iOS 与 HarmonyOS 顶部卡路里弧统一改为 116×116 正圆绘制区，按 `clamp(calories, 0, 800) / 800` 渲染 135° 起始、270° 总扫角的动态弧。
- [HLTH-VIS-029] iOS 与 HarmonyOS 周计划增加卡内选中日状态，点击七日日期只切换共享 `weeklyDayPlans` 对应的名称、时长和训练负荷；日期外的卡片点击仍沿用详情入口。
- [HLTH-VIS-030][HLTH-VIS-031][HLTH-VIS-032] 两端范围三角均移到指标线下方；健康快测时间条件显示在标题同行；手表短按进入“我”、长按打开场景切换，并使用平台原生互斥手势避免一次操作触发两个行为。

## 人工审查点

- [HLTH-VIS-024] 共享层继续只提供卡片类型和绘图数据，不引入 SwiftUI、ArkUI 或平台坐标类型；视觉一致性由各端按同一数据语义和尺寸契约原生绘制。
- [HLTH-VIS-025] iPhone 17 模拟器中的 769 Kcal 显示约 96% 橙色弧并保留短暗色余量，验证超限前不是固定满弧；大于等于 800 时按规范夹紧为全满。
- [HLTH-VIS-029][HLTH-VIS-032] iOS 已进行模拟器顶屏视觉核对；当前没有在线 HarmonyOS 设备，因此鸿蒙只完成结构门禁和编译验证，日期点击、短按/长按仍需下一次真机回归。

## 验证结果

- 红灯：[HLTH-VIS-030][HLTH-VIS-031][HLTH-VIS-032] 首轮 `check-health-card-fidelity.sh` 报 8 个 iOS/HarmonyOS 缺失标记；扩大到完整 2031 对齐范围后，[HLTH-VIS-024][HLTH-VIS-025][HLTH-VIS-027][HLTH-VIS-029] 再报 6 个缺失标记，均在实现后转绿。
- iOS：`xcodebuild -project iosApp/iosApp.xcodeproj -scheme IOSDemo -configuration Debug -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build` 通过；最终应用安装并启动于 iPhone 17 模拟器，截图 `/private/tmp/ios-health-final.png` 验证正圆动态卡路里弧、周计划和列表首屏布局。
- HarmonyOS：`hvigorw assembleApp --no-daemon` 通过，仅保留项目既有弃用/KNOI warning；没有在线设备，未声明真机视觉或手势通过。
- `check-health-card-fidelity.sh`、`check-health-card-adaptive-layout.sh`、`check-resource-maintainability.sh`、新增 iOS Asset JSON 校验、`check-docs.sh`、`check-sdd.sh` 与 `git diff --check` 均通过。

## 人工修正点

- iOS 周计划计算属性加入选中日和计划局部推导后，Swift 编译器无法从多语句 opaque return type 自动推断；补充显式 `return` 后完整构建通过。
- HarmonyOS 初版日期按钮尝试调用 ArkUI `ClickEvent.stopPropagation()`，当前 SDK 不提供该 API；移除不兼容调用并依赖子节点点击消费，重新构建通过。
- 自适应布局门禁仍匹配扩展参数前的单行调用形式，虽打印 FAIL 却未返回非零；将断言改为稳定的组件定义符号后重新执行，所有项目明确 PASS。

## 下轮交接

- **已完成**：iOS 与 HarmonyOS 已按 Android 已验收口径完成健康页视觉、动态卡路里弧、半小时心率区间、七日计划切换、范围指针、快测标题和手表复合交互；Spec、TRACE、Learnings 和门禁已同步。
- **未完成 / 阻塞项**：无在线 HarmonyOS 设备，尚未做鸿蒙真机滚动截图、日期点击与手表短按/长按人工验收。
- **下轮起步建议**：连接鸿蒙设备后先安装最新 hap，按 [HLTH-VIS-024] 至 [HLTH-VIS-032] 依次核对首屏、心率卡、周计划、快测卡和手表两种手势；若出现像素差异，只调整平台绘制参数，不改共享数据语义。

# 2026-07-23 16:06 — 修正 iOS 与 HarmonyOS 健康卡片尺寸和逐卡视觉偏差

## 采纳内容

- [HLTH-VIS-033] 以 Android 当前已验收代码和 emulator-5554 截图为运行时基准，iOS 与 HarmonyOS 为有数据视觉组件增加类型级内容安全高度；公共卡片外壳仍不固定整卡高度，空态继续由说明文字自然测量。
- [HLTH-VIS-034] iOS 周计划柱图显式消费卡内 `selectedIndex`；HarmonyOS `Bars` 显式消费 `weeklySelectedIndex()`，点击日期后日期圆点、计划文案/数值和对应青色高亮柱同步变化。
- [HLTH-VIS-035] 两端新增本周负荷完整轨道与七日标签、Android 阈值一致的压力密集细柱、按时间坐标绘制的四阶段睡眠条；心率/压力/睡眠左侧统一使用 141 宽、至少 60 高安全区。训练量评估指标改为三个 82 宽指标与 42 高分隔线。
- [HLTH-VIS-036] iOS 恢复弧改用与 Android 同坐标的 114×58 Canvas，HarmonyOS 放宽 114×78/121×71 仪表安全区；两端补齐恢复状态和 HRV 正常范围的中英文资源，避免显示资源键。
- [HLTH-VIS-037] HarmonyOS 卡路里弧进入独立居中的 116×116 容器；顶部三图标增加绿/黄/紫模板着色；范围指针增加填充和描边并取消内部裁剪；健康快测改为两行三列、92 宽指标和 18 间距。

## 人工审查点

- [HLTH-VIS-033] 上轮“任何类型最小高度表都禁止”的规则与本轮用户实际截图冲突；修订为“公共外壳不固定整卡，但有数据视觉组件保留 Android 等价安全高度”，避免再次让平台测量压缩固定尺寸图形。
- [HLTH-VIS-035] iOS 原睡眠实现把 `durationMinutes` 放进 `layoutPriority`，HarmonyOS 原实现使用 `layoutWeight`，二者都不是时间轴坐标；现按 `startMinute/total` 和 `durationMinutes/total` 显式计算 x 与宽度。
- [HLTH-VIS-037] 当前没有在线 HarmonyOS 设备；ArkUI Path/布局已通过编译和结构门禁，但卡路里弧、仪表和范围指针仍应在目标鸿蒙设备上做最终截图回归。

## 验证结果

- 红灯：新增 `check-health-cross-platform-parity.sh` 首次报告 19 项缺失，覆盖两端安全高度、周计划高亮、负荷/压力/睡眠专用绘制器、恢复资源、鸿蒙图标着色、范围指针和快测网格；实现后全部转绿。
- iOS：最终 `xcodebuild ... -destination 'platform=iOS Simulator,name=iPhone 17' build` 通过；安装启动后 `/private/tmp/ios-health-parity-top.png` 确认周四与第 4 根柱同步高亮、本周负荷完整显示轨道和星期、训练量评估卡不再被自身边界压扁。
- HarmonyOS：使用项目文档规定的 DevEco Node/SDK 环境执行 `hvigorw assembleApp --no-daemon`，最终 `BUILD SUCCESSFUL`；仅保留既有 KNOI、弃用 API、签名和 `app_name` warning。
- `check-health-cross-platform-parity.sh`、`check-health-card-fidelity.sh`、`check-health-card-adaptive-layout.sh`、`check-resource-maintainability.sh`、三份本地化 JSON、`check-docs.sh`、`check-sdd.sh` 与 `git diff --check` 最终通过。

## 人工修正点

- [HLTH-VIS-035] HarmonyOS 本周负荷原先在 36 高容器中继续按 58 计算柱高，直接造成截断；`barHeight` 改为接收真实容器高度，并用 Stack 分层绘制完整轨道和有效柱。
- [HLTH-VIS-035] 新增压力阈值颜色时最初在 Swift/ArkTS 内写入两个直接颜色，资源债务门禁正确失败；将其提升到两端 `AppColors` 后门禁恢复为零债务。
- [HLTH-VIS-036] iOS 首次安全高度代码把 `width` 与 `minHeight` 放入不存在的 SwiftUI `frame` 重载，编译失败；拆分为两个 `frame` 修饰器后通过。
- 模拟器下半屏自动翻页尝试被 macOS 辅助功能权限拒绝，未把结构检查冒充为完整人工截图；鸿蒙 `hdc list targets` 无可用设备并被终止。

## 下轮交接

- **已完成**：用户点名的 iOS/HarmonyOS 卡片高度、周计划柱高亮、负荷/训练评估、恢复/能力仪表、心率/压力、睡眠、范围指针、顶部图标与快测网格均已按 Android 基准修正并通过两端构建。
- **未完成 / 阻塞项**：iOS 下半屏缺少自动滚动截图；HarmonyOS 缺少在线设备，尚未完成真机逐卡截图和日期点击人工验收。
- **下轮起步建议**：人工在 iOS 滚动到恢复—快测区、在鸿蒙连接设备后从顶部到快测区分段截图；若仍有像素差异，优先调整 `contentMinimumHeight`、右栏 114/121/130/166 安全区和 ArkUI Path 坐标，不修改 common 数据模型。

# 2026-07-23 16:26 — 修正 HarmonyOS 圆弧密度错位与顶部图标颜色

## 采纳内容

- [HLTH-VIS-038] 顶部卡路里、体力恢复、跑步能力和骑行能力的 ArkUI Path 在生成命令前统一把设计 vp 中心、半径、端点及指针长度换算为物理像素；116×116、114×58、121×60 的外层 vp 安全区保持不变。
- [HLTH-VIS-038] 同类的 HRV/静息心率三角 Path 也改为换算坐标，避免组件存在但在高密度设备上过小。
- [HLTH-VIS-039] `MetricComp` 的 PNG 图标启用 `ImageRenderMode.Template`，继续由语义颜色输出步数绿 `#00DF7B`、卡路里黄 `#FFC928`、运动时长紫 `#D72BCC`。

## 人工审查点

- 用户提供的鸿蒙设备截图明确显示：116 vp 容器中的圆弧仅以约 58 物理像素半径绘制，且落在容器左侧；这与 Path 命令坐标没有随设备密度换算一致，不是共享 progress 数据或卡片高度问题。
- `vp2px` 当前 SDK 标记为 deprecated，但仍是项目目标 SDK 可编译的全局换算入口；后续整体升级 ArkUI API 时可迁移到 `UIContext` 对应换算方法，本轮不扩大平台架构范围。
- 当前仍无可连接的 HarmonyOS 设备；编译与结构证据能验证单位和渲染模式接入，修正后的最终像素效果仍需用户在同一设备安装最新产物后截图确认。

## 验证结果

- 红灯：`check-health-cross-platform-parity.sh` 新增 8 项 Path 坐标换算断言和 1 项图片模板模式断言，首次全部失败；用户截图同时作为高密度设备视觉红灯。
- 绿灯：实现后 `check-health-cross-platform-parity.sh` 全部通过；使用 DevEco Studio Node/SDK 环境执行 `hvigorw assembleApp --no-daemon`，结果 `BUILD SUCCESSFUL`。
- 构建仅出现既有 KNOI、弃用 API、未配置签名和重复 `app_name` warning；新增 `vp2px` 有弃用提示但无编译错误。

## 人工修正点

- 初次从 `harmonyApp` 子目录调用仓库根专项脚本路径错误，随后在仓库根重新执行并确认所有断言通过；鸿蒙构建本身在该次命令中已正常完成。
- 没有通过增大卡片高度或硬编码设备倍率掩盖问题；只在 Path 数值坐标边界进行密度换算，避免普通 vp 布局尺寸被二次放大。

# 2026-07-23 17:53 — 全平台补齐 @Preview / #Preview 注解

## 采纳内容

- [health-dashboard-cards.md] **iOS**：23 个 SwiftUI View 文件全部添加 `#Preview` 块，覆盖 Login(Entrance/LoginPage/PhoneRegister/EmailRegister/VerifyCode/PasswordSetup/ForgotPassword/ResetPassword/SignedIn/ProfileCompletion/LegalDocument)、Home(Records/Explore/MainTabs)、Account、Health(Dashboard/Detail/CardEditor/HeroArc/HeroTopRow/ScenarioPicker/HealthCard)、ContentView、SnackbarView；其中 LegalDocumentView 含 PrivacyPolicyView 和 ServiceTermsView 两个 Preview。
- [health-dashboard-cards.md] **HarmonyOS**：为全部 6 个纯 `@Component` 结构添加 `@Preview` 装饰器（DashboardCardComp/HeroTopRowComp/MetricComp/ScenarioPickerComp/HealthDetailComp/CardEditorComp）。
- [health-dashboard-cards.md] **Android**：原有 21 个 Compose 屏幕/组件已全量具备 `@Preview` 注解，本次无需修改。
- 预览风格统一为 `.preferredColorScheme(.dark)`（iOS）和 `showBackground = true, backgroundColor = 0xFF000000`（Android）；HarmonyOS 无参数纯装饰器。

## 人工审查点

- iOS HealthCardEditor 的 Preview 使用了4张模拟卡片（TodayActivity/WeeklyPlan/TrainingLoad/HeartRate），图标字符串为猜测值；布局预览正常，但图标具体渲染需在 Xcode 中确认资源名准确性。
- ScenarioPickerView 的 Preview 直接实例化 `HealthDashboardViewModel()`（有默认 init），`@Environment(\.dismiss)` 在无 NavigationStack 包裹时不会导致崩溃，但预览区域会缺少 dismiss 交互。
- HealthCard.swift 是纯模型 struct（非 View），不添加 `#Preview`。
- HarmonyOS 的 `AuthComponents.ets` 在 `@Entry` 页面中以 `@Builder` 函数存在，非独立 `@Component`，不可使用 `@Preview`。

## 验证结果

- iOS `rg -c "#Preview"` 确认 23 个文件全覆盖，无遗漏 View/Component 文件。
- HarmonyOS `rg -c "@Preview"` 确认 6 个纯 `@Component` 文件全覆盖。
- Android `rg -c "@Preview"` 确认 21 个 Compose 文件全覆盖。
- `./tools/check-sdd.sh` 和 `./tools/check-docs.sh` 均通过。

## 人工修正点

- 无。本次为纯注解添加，未修改业务逻辑或 UI 结构。

## 下轮交接

- **已完成**：三平台所有 View/Component/Composable 文件均具备 IDE 预览能力（iOS #Preview 23 个、HarmonyOS @Preview 6 个、Android @Preview 21 个）。
- **未完成 / 阻塞项**：无。
- **下轮起步建议**：可进入各平台 IDE 逐一预览并截图，核对每张卡片的布局像素。若发现 SwiftUI/ArkUI 预览与真机不一致，优先检查 `@Environment` 依赖、`@ObservedObject` 初始化和资源名映射。
