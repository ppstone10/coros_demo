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
