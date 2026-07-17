## SDD 记录规范：
> - 每次对话结束后追加一轮记录
> - 每轮以 `# YYYY-MM-DD HH:mm — 内容概要` 开始，时间使用 Asia/Shanghai 实际写入时间并精确到分钟
> - 历史记录无法确认具体时间时使用 `# YYYY-MM-DD（时间未记录）— 内容概要`，不得伪造时间
> - 每条「采纳内容 / 人工审查点 / 验证结果 / 人工修正点」引用稳定 Spec ID；历史 Spec 尚无 ID 时可引用章节号，如 `[auth-mock-spec §8]`
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
