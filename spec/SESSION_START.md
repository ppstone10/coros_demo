# SDD 会话启动说明

当使用的 AI 工具不能自动读取根目录 `AGENTS.md` 时，将本文件作为会话开场上下文。权威规则以 `AGENTS.md` 和 `spec/sdd-workflow.md` 为准。

## 启动预检

1. 读取 `LEARNINGS.md`，了解持久架构决策、边界和已验证踩坑。
2. 读取 `spec/TRACE.md`，定位已有 Spec、测试与实现。
3. 读取本次任务相关的 `spec/*.md`。
4. 必要时读取 `DESIGN.md`、`REQUIREMENT_NOTES.md`；只有追溯细节时才读 `docs/worklog/`。

## 必须执行的开发顺序

```text
读 LEARNINGS + TRACE + 相关 Spec
  → 先写/更新 Spec（边界、数据、行为、异常、测试、稳定 ID）
  → TRACE 预留 ⏳ 映射
  → 先写测试并运行红灯
  → 写最小实现并运行绿灯
  → TRACE 填入测试、实现、验证证据和真实状态
  → Codex_worklog.md 追加时间/概要标题和四段记录
  → LEARNINGS.md 提炼持久结论（如有）
```

纯文案、注释和机械格式调整可以引用既有 Spec；行为、接口、数据或验收口径变化必须先更新 Spec。测试无法自动化时，必须在 Spec 和 TRACE 中写明人工验收方法，不能假装通过。

## 项目红线

- 所有数据使用本地 mock，不接入真实服务器。
- 不写真实 URL、path、token、账号、密钥、加密逻辑或真实请求/响应结构。
- mock 与持久化数据结构先由 `common/src/commonMain/proto/` 下的 `.proto` 定义。
- Android 使用 Compose，iOS 使用 SwiftUI，HarmonyOS 使用 ArkUI；平台 UI 不承载共享业务规则。
- 业务规则放在 `common`，跨语言调用通过既有 facade/bridge 边界完成。

## 结束门禁

1. 相关测试与 `./tools/check-sdd.sh` 已实际运行并如实记录。
2. TRACE 不保留无说明的 `⏳`，只有证据完整才标记 `✅`。
3. `Codex_worklog.md` 先写 `# YYYY-MM-DD HH:mm — 内容概要`（Asia/Shanghai 实际写入时间），再追加“采纳内容、人工审查点、验证结果、人工修正点”，每条引用稳定 Spec ID。
4. 只把跨会话仍然有效的决策、坑和方法追加到 `LEARNINGS.md`；一次性过程留在 Worklog。
