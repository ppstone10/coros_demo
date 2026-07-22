# 健康模块完整数据持久化 Spec

## 元数据

- Spec ID 前缀：`HLTH-PERSIST`
- 状态：实施中
- 适用范围：common 健康领域快照、Android/iOS/HarmonyOS 应用私有存储
- 最后更新：2026-07-22

## 目标

- 按认证 `userId` 保存每位 Demo 用户最新一份完整 `HealthDashboardData`，覆盖首页摘要与 14 类健康模块数据。
- 模拟场景仅作为生成测试数据的模板；加载时以已持久化的模块数据为权威，不再依赖场景重新生成健康值。
- 保留卡片启用状态和顺序，并保证更新配置时不会覆盖健康模块数据。
- 统一三端的快照 JSON 契约，修正 HarmonyOS 全局卡片顺序和仅保存当前场景造成的跨用户复用风险。

## 非目标

- 不保存 `HealthCardUiModel`、最终本地化文案、风险状态、优先级或其他可由领域数据重新计算的 UI 派生值。
- 不保存长期、秒级传感器历史，不引入数据库或真实健康服务。
- 不改变现有 mock 数值、风险阈值、卡片视觉绘制或至少三张卡片的配置规则。
- 不在本轮接入真实账号、服务地址、token、设备数据或用户健康数据。

## 数据与边界

`HealthDashboardSnapshot` 是单用户权威快照，至少包含：

- `schemaVersion`：快照版本，用于后续迁移。
- `userId`：认证用户稳定 ID。
- `sourceScenario`：仅用于 Demo 场景选择器展示和旧快照迁移的来源元数据；不得用于覆盖已保存的 `dashboardData`。
- `enabledCardTypes`：启用卡片类型和顺序。
- `dashboardData`：首页摘要和全部健康模块领域数据。

`health_dashboard_mock.proto` 继续作为字段契约；JSON 由 common 唯一编解码，三端只负责应用私有字符串读写。快照允许 20 个本地 Demo 用户共存，不把任何用户数据放入 UI 全局状态作为权威来源。

## 行为规范

### `HLTH-PERSIST-001`：快照保存完整健康领域数据

- Given：某用户已有任一非空健康数据集
- When：保存并重新加载 `HealthDashboardSnapshot`
- Then：首页摘要、14 类模块、趋势点、范围、睡眠阶段和模块元数据逐字段一致
- 异常/边界：可空模块继续保存为 null；空列表与非空列表不得混淆

### `HLTH-PERSIST-002`：加载以模块数据为权威

- Given：快照同时包含 `sourceScenario` 和 `dashboardData`
- When：进程重建后加载健康首页
- Then：直接由 `dashboardData` 生成 UI，不重新调用场景模板覆盖数值
- 异常/边界：场景来源未知时仍可恢复完整模块数据

### `HLTH-PERSIST-003`：场景选择覆盖并保存模块数据

- Given：用户在 Demo 场景选择器选择一个场景
- When：场景模板生成 `HealthDashboardData`
- Then：用该数据替换当前用户快照中的 `dashboardData` 并持久化，同时更新 `sourceScenario`
- And：三端页面立即重新读取返回的完整快照，不能只改变场景勾选而继续展示旧卡片值
- 异常/边界：`ReadFailure` 继续返回读取失败，不覆盖最后一份有效快照

### `HLTH-PERSIST-004`：卡片配置更新保留健康数据

- Given：用户已有完整健康快照
- When：调整启用卡片和顺序并保存
- Then：只更新 `enabledCardTypes`，`dashboardData` 逐字段保持不变
- 异常/边界：少于三张时保存失败，原快照不变

### `HLTH-PERSIST-005`：旧配置快照安全迁移

- Given：旧 JSON 只有 `userId/scenario/enabledCardTypes`
- When：新版加载该快照
- Then：使用旧场景生成一次完整领域数据，并以新版格式保存；以后加载不再依赖场景生成
- 异常/边界：未知旧场景回退 Normal；损坏 JSON 返回 null，不崩溃

### `HLTH-PERSIST-006`：多用户数据隔离

- Given：本地存在最多 20 个 Demo 用户
- When：不同用户保存不同模块数据和卡片顺序
- Then：按 `userId` 加载各自快照，不复用其他用户的场景、顺序或健康值
- 异常/边界：清除一个用户只删除该用户健康快照

### `HLTH-PERSIST-007`：HarmonyOS 使用单一健康快照集合

- Given：HarmonyOS bridge 内存中包含多个用户快照
- When：ArkTS 导出、写入、重启并恢复健康存储
- Then：`health_json` 恢复全部用户完整快照，KMP 根据当前登录 `userId` 读取对应数据
- And：页面不再以全局 `health_card_order` 或认证 JSON 内 `_health` 作为权威健康状态
- 异常/边界：旧 `_health`/`health_card_order` 只允许迁移，不得覆盖新版完整快照

## 测试要求

| Spec ID | 自动化测试/验证 | 预期结果 |
|---|---|---|
| `HLTH-PERSIST-001` | `fullDashboardSnapshotRoundTripsAllModuleData` | 全模块完整往返 |
| `HLTH-PERSIST-002` | `storedDashboardDataWinsOverScenarioTemplate` | 保存数据不被场景重建覆盖 |
| `HLTH-PERSIST-003` | `scenarioSelectionPersistsGeneratedModuleData` | 场景生成的数据进入快照 |
| `HLTH-PERSIST-004` | `cardConfigurationUpdatePreservesDashboardData` | 配置更新不丢数据 |
| `HLTH-PERSIST-005` | `legacyScenarioSnapshotMigratesToFullData`、损坏 JSON 测试 | 旧格式迁移且损坏安全 |
| `HLTH-PERSIST-006` | `fullDashboardSnapshotsAreIsolatedByUserId`、`twentyFullDashboardSnapshotsRoundTripWithinPreferencesBudget` | 多用户隔离且 20 用户集合小于 1 MB |
| `HLTH-PERSIST-007` | common 集合 codec 测试、HarmonyOS bridge/ArkTS 构建与结构检查 | 全用户恢复且无重复权威状态 |

## 验收标准

- [x] common 快照 JSON 包含完整 `HealthDashboardData` 并可逐字段往返。
- [x] 已保存数据的加载不依赖 mock 场景重建。
- [x] Android、iOS 使用现有按用户私有 Key 保存新版完整快照。
- [x] HarmonyOS 的 `health_json` 可恢复多个用户，页面不再维护全局卡片顺序副本。
- [x] 相关 common 测试、三端构建、SDD 与文档门禁通过。

## 待人工确认

- 当前使用 Preferences/JSON 适用于 20 个用户、每人一份小型最新 mock 快照；若未来引入长期或高频真实采样，应另立 Spec 迁移到数据库。
- `sourceScenario` 仅是 Demo 来源元数据，不是健康数据的恢复依据；正式产品移除场景选择器时可随迁移删除。
