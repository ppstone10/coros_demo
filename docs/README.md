# 项目文档地图

这里按“当前文档 / 参考资料 / 历史归档”组织项目知识。平台专属当前接入细节仍放在对应实现目录的 `README.md`。

## 当前文档

| 文档 | 权威职责 |
|------|----------|
| [`architecture.md`](architecture.md) | 五个实现目录的职责、KMP 边界和跨端调用关系 |
| [`development-workflow.md`](development-workflow.md) | SDD 之后的构建、修改和平台验证命令 |
| [`resource-management.md`](resource-management.md) | 当前三端资源位置、设计源、导入与验收规则 |
| [`proto与domain model之间的关系.md`](proto与domain%20model之间的关系.md) | Proto 字段契约、存储镜像、JSON 与 domain model 的边界 |

## 参考资料

[`reference/`](reference/) 保存完整教程、独立边界清单和模块介绍。这些内容仍有知识价值，但可能包含通用示例或旧路径；当前实现发生冲突时，以当前文档和实现目录 README 为准。

## 历史归档

- [`archive/`](archive/)：阶段计划、技术实验和验证清单。
- [`worklog/`](worklog/)：完整开发日志，只追加，不修改或删除既有日志。

## 根目录交付文档

| 文档 | 职责 |
|------|------|
| [`../REQUIREMENT_NOTES.md`](../REQUIREMENT_NOTES.md) | 需求拆解、已确认规则和待确认项 |
| [`../DESIGN.md`](../DESIGN.md) | 当前认证与健康模块设计 |
| [`../TEST_REPORT.md`](../TEST_REPORT.md) | 当前测试范围、命令、结果和风险 |
| [`../spec/README.md`](../spec/README.md) | Spec 模板、生命周期和 TRACE 规则 |
| [`../LEARNINGS.md`](../LEARNINGS.md) | 跨会话仍有效的决策与踩坑 |

## 平台说明

- Android：根 README、`androidApp/` 源码和本工作流中的 Android 命令。
- iOS：[`../iosApp/README.md`](../iosApp/README.md)。
- HarmonyOS：[`../harmonyApp/README.md`](../harmonyApp/README.md)。
- HarmonyOS KMP bridge：[`../harmony-kmp-bridge/README.md`](../harmony-kmp-bridge/README.md)。

## 维护规则

1. 当前实现规则更新 `docs/` 根目录文档或对应实现目录 README。
2. 有长期知识价值但不是当前唯一事实来源的内容放入 `docs/reference/`，不因重复而直接删除。
3. 阶段计划、实验路线和验证清单放入 `docs/archive/`，原则上保持原文。
4. 一次性排查过程写入 `Codex_worklog.md`，归档后进入 `docs/worklog/`。
5. `docs/worklog/` 是只追加历史：允许新增归档文件，不允许修改、覆盖或删除既有文件。
6. 文档变更后运行 `./tools/check-docs.sh` 和 `./tools/check-sdd.sh`。
