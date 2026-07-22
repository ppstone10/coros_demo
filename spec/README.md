# Spec 目录说明

`spec/` 是本项目行为和验收口径的权威来源。代码说明“现在怎么做”，Spec 说明“必须做什么”，测试是 Spec 的可执行表达，`TRACE.md` 负责把三者连接起来。

## 文件职责

| 文件 | 职责 | 何时更新 |
|------|------|----------|
| `sdd-workflow.md` | SDD 流程本身的权威规范 | 流程、状态或门禁变化时 |
| `TEMPLATE.md` | 新功能 Spec 模板 | Spec 字段标准变化时 |
| `TRACE.md` | Spec → 测试 → 实现 → 验证的索引 | 开发前预留，开发后完成 |
| `SESSION_START.md` | 无法自动读取 `AGENTS.md` 时的手动会话提示 | 权威流程变化后同步摘要 |
| `<feature>.md` | 某个功能域的目标、边界、行为和验收 | 对应行为变化之前 |

当前 Android 资料编辑页的 Activity Result 宿主与依赖兼容性规范见 `android-profile-activity-result.md`。

Figma 2031 健康首页的数据可视化与三端专用卡片规范见 `health-dashboard-visual-cards.md`。

健康模块完整领域数据、多用户快照与三端私有存储规范见 `health-dashboard-persistence.md`。

`AGENTS.md` 是 AI 自动入口，`spec/sdd-workflow.md` 是完整流程规范；`SESSION_START.md` 仅是便携摘要，不单独发明规则。

## 生命周期

```text
提炼需求
  → 新增/更新 Spec 和稳定 ID
  → TRACE 预留 ⏳
  → 测试红灯
  → 最小实现
  → 测试绿灯
  → TRACE 填证据并更新状态
  → Worklog 记录本轮事实
  → Learnings 提炼持久结论（如有）
```

## 命名与稳定 ID

- 文件名使用小写 kebab-case，例如 `session-expiry.md`。
- 每个可独立验收的要求使用稳定 ID：`<DOMAIN>-<TOPIC>-<NNN>`，例如 `AUTH-LOGIN-001`。
- ID 一经进入 TRACE 不应因标题改写而变更；废弃时标记 `🚫` 并保留原因，不复用旧 ID。
- 新 TRACE 映射优先引用类型、函数、测试名称；行号只能作为辅助信息。

## 状态

- `⏳`：已定义，测试、实现或验证尚未完成。
- `✅`：测试、实现和真实验证证据完整。
- `⚠️`：部分完成或有风险，必须写明缺口。
- `🚫`：人工决定不实现，必须保留原因。

复制 `TEMPLATE.md` 创建新 Spec，并删除不适用的提示文字。不要复制历史功能 Spec 后保留无关约束。
