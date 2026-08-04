# 三端目录结构与文件拆分 Spec

## 元数据

- Spec ID 前缀：`STRUCT`
- 状态：已采纳
- 负责人：shiliangcan
- 关联需求：三端目录对齐（auth/health/home/core）已完成 Phase 0-1，本轮为 Phase 2「结构收敛」
- 最后更新：2026-08-04

## 目标

- 将超过行数阈值的大文件按职责拆分，使每个文件只承载一个清晰职责。
- 将寄生在 auth 导航中的 health 路由按域拆出，health 域拥有自己的导航位置，三端结构对称。
- 全程保证公共 API、稳定消息键、proto 契约与可观察行为不变；三端文件在拆分后仍能一一对应。

## 非目标

- 不重命名 common 包（`login`→`auth`、抽取 `core/`），该工作属 Phase 3。
- 不拆分适配层混合文件（`HarmonyLoginService`/`KnoiLoginAdapter`/`SharedLoginAdapter` 按域拆分），属 Phase 4。
- 不引入组合根 DI（`AppContainer`），属 Phase 3/4。
- 不改变任何业务规则、本地化键、proto 字段或持久化格式。
- 不删除文档历史；`docs/worklog/`、`docs/archive/` 只追加。

## 边界与约束

- 架构边界：拆分只发生在各端平台目录与 `common/src/commonMain` 内部；不改变跨语言门面签名。
- 兼容性边界：所有 public 符号（类、函数、枚举名、消息键）保持原名与签名；拆出的文件内声明保持不变。
- 失败边界：任何拆分必须通过既有测试与对应端构建；否则视为行为回归，立即回滚该批。
- 平台边界：iOS 拆文件后需同步 Xcode 工程引用；HarmonyOS 拆 .ets 需同步相对 import；Android 拆 .kt 需同步 package 声明（同一包内拆分不需要）。

## 数据与状态

| 名称 | 类型/结构 | 来源 | 生命周期 | 约束 |
|------|-----------|------|----------|------|
| 迁移映射表 | `spec/three-platform-structure.md` + 本 Spec 追溯 | 现状代码 | 本轮 | 每个拆分文件对应一行，改动前确认无遗漏 |
| 既有测试 | commonTest / androidTest / JVM test | 现状 | 永久 | 拆分后必须全绿，作为行为不回归的证据 |
| 三端门禁脚本 | `tools/check-*.sh` | 现状 | 永久 | 结构门禁可能引用旧文件路径，拆分后同步更新 |

## 行为规范

### `STRUCT-001`：common 大文件按职责拆分且公共 API 不变

- Given：`HealthEditableForms.kt`(748)、`EditableHealthData.kt`(716)、`MockHealthDashboardStoreJson.kt`(681)、`AuthRepository.kt`(534)、`MockAuthStoreJson.kt`(518)
- When：按「模型 / 规则 / 编解码 / 默认值」拆分为独立文件（同一包 `com.example.demo.common.health` / `.login`）
- Then：所有 public 类型与函数签名保持不变，仅文件落点变化；`./gradlew :common:check` 全绿
- 异常/边界：拆分中如发现私有依赖交叉，保持同一对象内的私有成员不动，只按 public 类型边界切分

### `STRUCT-002`：health 导航按域从 auth 导航拆出，路由行为不变

- Given：Android `AuthNavGraph.kt` 内嵌 health 路由；iOS `AuthCoordinator.swift` 内嵌 health case；HarmonyOS `AuthRoutes.ets` 混合 auth/health 常量
- When：Android 将 health 的 composable 组合抽到 `health/navigation/HealthNavGraph.kt`（`NavGraphBuilder` 扩展）；iOS 抽 `HealthRouter`；HarmonyOS `AuthRoutes` 常量按 `auth`/`health`/`home` 分组
- Then：页面可达性与二级路由 Push/Pop 行为与拆分前完全一致；三端构建通过
- 异常/边界：HarmonyOS `main_pages.json` 与 URL 常量字符串不得改变；Android `NavHost` 容器保持单一

### `STRUCT-003`：平台大文件按组件拆分，三端保持一一对应

- Given：HarmonyOS `ProfileCompletionPage.ets`(1557)、Android `ProfileCompletionScreen.kt`(883)、三端 `AuthComponents.*`（.kt 785 / .swift 608 / .ets 474）、`NormalDataEditor` 三端、HarmonyOS `SignedInPage.ets`(563)、iOS `HealthDashboardView.swift`(491)
- When：按页面骨架与区块组件拆分；`AuthComponents` 按组件拆分独立文件
- Then：每端拆分后文件仍能在另两端找到同语义对应物；三端构建通过
- 异常/边界：`AuthComponents` 为三端同步拆分，避免单端拆后结构失衡

### `STRUCT-004`：拆分可追溯，不留孤儿代码

- Given：任一拆分文件
- When：拆分完成
- Then：`spec/TRACE.md` 对应行记录拆前→拆后文件落点与验证命令；旧文件不再残留重复声明；`git diff --check` 无冲突标记
- 异常/边界：拆分中被移动的私有常量/扩展函数必须一并迁移，不得在源文件留下悬空引用

## 测试要求

| Spec ID | 自动化测试/人工验收 | 预期结果 |
|---------|---------------------|----------|
| `STRUCT-001` | `./gradlew :common:check`（既有 commonTest 全量回归） | 全部通过；无 public API 变化 |
| `STRUCT-002` | Android `./gradlew :androidApp:assembleDebug`；iOS `xcodebuild`；HarmonyOS `hvigorw assembleApp` | 三端构建通过；导航行为人工抽查 |
| `STRUCT-003` | Android `assembleDebug`；iOS `xcodebuild`；HarmonyOS `assembleApp` | 三端构建通过 |
| `STRUCT-004` | `./tools/check-sdd.sh`；`./tools/check-docs.sh`；`git diff --check` | 门禁通过；无冲突标记 |

> 说明：本轮全部为「行为零变化的文件拆分」，不新增业务测试；既有测试（commonTest 合计 123 条 + 平台构建）即回归网。无法自动化的人工验收为各端构建与页面交互抽查，原因：文件拆分不改变行为，且跨语言桥接需真实构建验证。

## 验收标准

- [ ] 所有 `STRUCT-*` 规范 ID 已在 `spec/TRACE.md` 建立映射（含 `⏳` → `✅` 过程）。
- [ ] common 五个大文件拆分后 `./gradlew :common:check` 全绿。
- [ ] health 导航按域拆出后，三端构建通过且页面可达性不变。
- [ ] 平台大文件拆分后，三端构建通过，文件仍可一一对应。
- [ ] `tools/check-*.sh` 中引用旧文件路径的脚本已同步更新。
- [ ] 没有引入「非目标」中的行为（无包重命名、无桥接拆分、无 DI、无业务变更）。
- [ ] TRACE、`Codex_worklog.md` 和必要的 `LEARNINGS.md` 已更新。

## 待人工确认

- 无（本轮为纯结构拆分；包重命名与桥接拆分属后续 Phase，将另立 Spec）
