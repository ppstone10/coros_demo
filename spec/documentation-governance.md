# 项目文档与辅助目录治理 Spec

## 元数据

- Spec ID 前缀：`DOC`
- 状态：已采纳
- 负责人：项目维护者
- 关联需求：2026-07-17 项目说明文档更新与清理
- 最后更新：2026-07-17

## 目标

- 让根目录和 `docs/` 只保留当前项目仍需要且职责明确的内容。
- 保留重复教程与阶段性说明中的完整知识内容，把当前权威入口、长期参考资料和历史归档明确分层。
- 用可执行检查保护关键实现目录、当前文档入口与完整历史日志。

## 非目标

- 不修改五个实现目录中的业务代码或资源实现。
- 不删除登录/健康设计源资源、真实埋点契约、构建脚本或 SDD 文件。
- 不改写、截断、重排或删除 `docs/worklog/` 中的任何历史日志。
- 不为了减少文件数量而把职责不同的需求、设计、测试、Spec 和历史记录合并成单一大文档。

## 边界与约束

### DOC-001：实现与历史保护

以下五个目录是实现主体，文档清理不得删除：`common/`、`androidApp/`、`iosApp/`、`harmony-kmp-bridge/`、`harmonyApp/`。

`docs/worklog/` 是只追加的完整历史归档。清理前后必须对已有文件执行 SHA-256 校验；本轮已有归档 `docs/worklog/2026-06-30-to-2026-07-17.md` 的单文件 SHA-256 为 `eb13d20f0d1d79b53976eed725671b8827ecabc2748943de269166b49973f530`，内容不得变化。

### DOC-002：根目录信息架构

根目录保留：

- 项目入口：`README.md`。
- SDD 与跨会话上下文：`AGENTS.md`、`LEARNINGS.md`、`Codex_worklog.md`、`spec/`。
- 当前交付文档：`REQUIREMENT_NOTES.md`、`DESIGN.md`、`TEST_REPORT.md`。
- 构建与契约：`gradle/`、`tools/`、`contract/`。
- 设计源资源：`login_register_resources/`、`health_dashboard_resources/`。

已被正式入口替代的 `skill.md`、空的 `test.md` 和误建的字面量 `~/` 不保留。

### DOC-003：docs 三层集合

`docs/` 分为三层：

1. 根目录当前文档：继续按现有排布放置，作为当前实现的权威说明。
2. `docs/reference/`：仍有长期知识价值，但可能包含通用知识或旧路径，阅读时需要结合当前文档复核。
3. `docs/archive/` 与 `docs/worklog/`：保存阶段计划、实验过程、检查清单和完整日志，不作为当前实现入口。

当前文档包括：

- `README.md`：文档地图、职责和维护规则。
- `architecture.md`：整体模块、KMP 边界和跨端接入。
- `development-workflow.md`：SDD 之后的具体构建、修改与验证命令。
- `resource-management.md`：当前三端资源位置、命名、复制和验证规则。
- `proto与domain model之间的关系.md`：字段契约、存储镜像与 domain 边界。
- `worklog/`：不可变历史归档。

### DOC-004：参考与归档分类

- 两份完整资源管理指南、独立 KMP 边界、iOS 接入说明和注册登录模块介绍放入 `docs/reference/`，正文完整保留。
- HarmonyOS 阶段计划、KMP 实验路线以及原 `experimental/harmony-kmp/` 的 README/CHECKLIST 放入 `docs/archive/harmonyos-kmp/`，正文完整保留。
- 根目录当前文档继续提供精简且与当前实现一致的入口；参考和归档内容不与当前入口争夺权威性。

### DOC-005：资源源文件保护

`login_register_resources/` 和 `health_dashboard_resources/` 是设计/导入源，不是说明性垃圾目录。即使平台工程已复制资源，也保留原始来源与映射说明；本轮不删除其中资源。

### DOC-006：契约与工具去占位

`contract/analytics/` 是实际埋点契约，保留。认证和健康字段契约以 `common/src/commonMain/proto/` 为准；空的 `contract/openapi/` 与无生成行为的 `tools/generate-contracts.sh` 不继续作为未来占位。

### DOC-007：平台说明就近维护

- iOS 构建和 KMP framework 接入写入 `iosApp/README.md`。
- HarmonyOS 运行、DevEco 和 native 产物要求写入 `harmonyApp/README.md`。
- KNOI 工具链、产物与兼容约束写入 `harmony-kmp-bridge/README.md`。
- 根 README 与 `docs/README.md` 只做导航，不复制整段平台操作说明。

### DOC-008：测试事实同步

`TEST_REPORT.md` 与 `spec/TRACE.md` 的测试数量必须从当前测试源码核对，不能继续保留过时计数。文档检查脚本应动态读取关键测试文件中的 `@Test` 数量，并检查文档是否同步。

### DOC-009：可执行文档门禁

新增 `tools/check-docs.sh`，至少检查：

- 五个实现目录和权威文档存在。
- 已确认的过时/占位路径不存在。
- 当前文档不再引用已删除路径。
- 既有完整 worklog 文件哈希未变化。
- TRACE 与 TEST_REPORT 的关键测试计数和源码一致。

### DOC-010：误删文档完整恢复

曾被误判为冗余但具有知识价值的10份文档必须从可信 Git 来源逐字节恢复。恢复后的 SHA-256 必须与恢复源一致，不能用摘要或重新生成内容代替原文。

### DOC-011：恢复后的目录归类

- 长期参考：`docs/reference/`。
- 阶段与实验历史：`docs/archive/harmonyos-kmp/`。
- 当前权威文档：保持 `docs/` 根目录现有排布。
- 完整开发日志：保持 `docs/worklog/` 原样。

移动文档时只改变路径，不修改恢复正文；额外说明写在各分类目录的 README 中。

### DOC-012：参考与归档保护门禁

`tools/check-docs.sh` 必须检查10份恢复文档存在且 SHA-256 与可信恢复源一致，同时检查 `docs/reference/README.md`、`docs/archive/README.md` 和 `docs/archive/harmonyos-kmp/README.md` 提供清晰导航。

## 数据与状态

| 名称 | 类型/结构 | 来源 | 生命周期 | 约束 |
|------|-----------|------|----------|------|
| 当前文档 | Markdown | 根目录、`docs/`、实现目录 README | 随实现维护 | 每项职责只有一个权威来源 |
| 历史日志 | Markdown | `docs/worklog/` | 永久、只追加 | 既有文件不可修改或删除 |
| 设计源资源 | 图片、视频、映射说明 | 两个 `*_resources/` 目录 | 设计输入仍有价值时保留 | 不因平台已复制而误删 |
| 文档检查 | Shell | `tools/check-docs.sh` | 随治理规则维护 | 失败不得被记录为通过 |

## 行为规范

- 新增说明前先在 `docs/README.md` 判断其职责是否已有权威文档。
- 平台专属信息优先更新对应实现目录 README；跨平台架构才进入 `docs/architecture.md`。
- 一次性排查过程进入 Worklog，不创建长期顶层说明文件。
- 删除说明文档前必须先迁移仍然有效且唯一的内容，并清理所有当前引用。

## 测试要求

| Spec ID | 自动化测试/人工验收 | 预期结果 |
|---------|---------------------|----------|
| `DOC-001` | worklog SHA-256 前后比对 | 已有历史日志内容完全一致 |
| `DOC-002`～`DOC-007` | `./tools/check-docs.sh` | 权威入口存在，冗余路径和旧引用消失 |
| `DOC-008` | 脚本动态统计 `@Test` 并比对文档 | TRACE、TEST_REPORT 与源码一致 |
| `DOC-009` | 先运行红灯，再在清理后运行绿灯 | 清理前捕获缺口，清理后全部通过 |

## 验收标准

- [ ] `docs/worklog/` 未发生任何内容变化或删除。
- [ ] `docs/` 根目录当前说明保持现有排布，参考资料和历史归档分别进入规定目录。
- [ ] 10份有知识价值的文档完整恢复，内容哈希与 Git 恢复源一致。
- [ ] 根目录不再存在已确认的旧提示、空文档和误建配置目录。
- [ ] 资源源文件、实际埋点契约、构建基础设施和五个实现目录全部保留。
- [ ] README、架构、平台 README 和工具说明不再引用已删除内容。
- [ ] `./tools/check-sdd.sh`、`./tools/check-docs.sh`、脚本语法与 `git diff --check` 通过。

## 待人工确认

- 无。用户已明确要求完整恢复有知识价值的文档，并按“当前文档 / 参考资料 / 历史归档”重新分类。
