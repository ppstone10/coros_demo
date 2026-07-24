# 项目 AI 开发约束

本项目采用 SDD（Spec-Driven Development）。任何 AI 或自动化代理开始修改前，都必须遵循本文件；完整规范见 `spec/sdd-workflow.md`。

## 项目边界

- 架构为 KMP 共享业务层 + Android Compose / iOS SwiftUI / HarmonyOS ArkUI 原生 UI。
- `common/src/commonMain` 只放平台无关模型、规则、状态与数据访问抽象，不放平台 API 或 UI 类型。
- 所有业务与认证数据只使用本地 mock；禁止写入真实服务地址、协议、token、密钥、账号或用户数据。
- mock 和持久化数据结构先由 `.proto` 定义；JSON 只能作为受 protobuf 字段契约约束的存储映射。
- `docs/worklog/` 是只追加历史归档；不得修改、覆盖或删除既有日志文件。
- `docs/reference/` 和 `docs/archive/` 保存完整知识与阶段历史；不得仅因内容重复或阶段过时而直接删除，调整前先建立迁移映射并确认正文已保留。
- 先遵守 `LEARNINGS.md` 中已有的架构决策和已验证踩坑；发现它与代码事实冲突时，记录冲突并请求人工审查。
- **三端同步原则**：所有影响 UI 结构、行为或架构模式的变更必须在 Android/iOS/HarmonyOS 三端同步实施，或在本轮 Spec/TRACE 中明确标记为单平台并跟踪为债务。不得在 Spec 写"三端同步"却只做一端。

## 强制 SDD 顺序

1. **读取 LEARNINGS.md 和 spec/TRACE.md**，再读本次任务对应的 Spec；需要历史证据时才查 `docs/worklog/`。
2. **先写或更新 Spec**：行为、接口、数据或验收口径变化时，在 `spec/` 中定义目标、非目标、边界、数据、行为、异常、测试和稳定规范 ID。
3. **在 TRACE 中预留映射**：写测试或实现前，在 `spec/TRACE.md` 添加 `⏳` 行，可暂写“待补”。
4. **先写测试并确认测试能捕获缺失行为**：至少运行一次红灯；无法自动化时写明人工验收方法和原因。
5. **编写最小实现让测试通过**：若发现 Spec 缺口，先修订 Spec 与 TRACE，再继续实现。
6. **更新 TRACE、Worklog 和 Learnings**：填入稳定符号/测试名和真实验证命令；按实际状态更新 TRACE，在 `Codex_worklog.md` 以 `# YYYY-MM-DD HH:mm — 内容概要` 开始一轮记录，再按顺序追加四段内容；只把持久有效结论提炼到 `LEARNINGS.md`。

不得先写实现、事后用 Spec 合理化既有代码。紧急修复可以压缩文档，但必须在本轮结束前补齐整个闭环。

## 变更分级

- 功能、缺陷修复、重构、数据/接口/配置行为变化：执行完整 SDD 流程。
- 测试本身的行为变化：更新测试所表达的 Spec 与 TRACE。
- 纯文案、注释、机械格式调整：可以引用已有 Spec，不强制新建；仍需验证并记录 Worklog。
- 仅分析或答疑且没有文件修改：只读相关上下文，不制造空 Spec、空 TRACE 或空 Learnings。

## 测试与验证

- 共享业务逻辑：`./gradlew :common:check`
- Android：`./gradlew :androidApp:assembleDebug`
- SDD 文档门禁：`./tools/check-sdd.sh`
- 文档治理门禁：`./tools/check-docs.sh`
- iOS 与 HarmonyOS 按 `docs/development-workflow.md` 中的平台命令验证。

只记录实际执行过的验证。测试失败、未执行或依赖环境时，必须如实写入 Worklog 与 TRACE，不得标记为通过。

## 完成定义

提交结果前确认：Spec 与实现一致、TRACE 不再保留无说明的 `⏳`、相关测试通过、`./tools/check-sdd.sh` 通过、`Codex_worklog.md` 已记录真实写入时间、内容概要和本轮四段事实；仅在产生跨会话价值时更新 `LEARNINGS.md`。
