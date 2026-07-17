# demo

Kotlin Multiplatform + 三端原生 UI 示例项目。Android、iOS 和 HarmonyOS 共享 `common` 中的平台无关业务规则，各端保留自己的原生界面与平台适配。

## 当前能力

- 本地 mock 注册、登录、验证码、会话、资料、改密和账号删除。
- protobuf 字段契约约束下的本地 JSON 状态保存与恢复。
- 健康首页 14 类卡片、正常/缺失/异常/读取失败场景、排序与卡片配置持久化。
- Android Compose、iOS SwiftUI、HarmonyOS ArkUI 三端原生实现。
- HarmonyOS 通过独立 KuiklyBase-Kotlin + KNOI bridge 复用 `commonMain` 业务，不维护 ArkTS 业务 fallback。

## 目录结构

```text
demo/
├── common/                       # KMP 共享业务、模型、Proto 镜像和测试
├── androidApp/                   # Android Compose 原生应用
├── iosApp/                       # iOS SwiftUI 原生应用
├── harmony-kmp-bridge/           # 独立 KNOI/Kotlin → HarmonyOS bridge
├── harmonyApp/                   # HarmonyOS ArkTS + ArkUI 原生应用
├── spec/                         # SDD 规格、模板和 TRACE
├── docs/                         # 当前文档、参考资料、历史归档与完整 worklog
├── contract/analytics/           # 三端埋点事件契约
├── login_register_resources/     # 登录/注册设计与导入源资源
├── health_dashboard_resources/   # 健康首页设计与导入源资源
├── tools/                        # 构建和文档门禁脚本
├── gradle/                       # 根 KMP/Android 构建基础设施
├── AGENTS.md                     # AI 自动读取的项目与 SDD 约束
├── LEARNINGS.md                  # 跨会话持久决策和踩坑
├── Codex_worklog.md              # 当前轮次审计日志
├── REQUIREMENT_NOTES.md          # 需求拆解
├── DESIGN.md                     # 当前模块设计
└── TEST_REPORT.md                # 当前测试报告
```

五个实现目录是：`common/`、`androidApp/`、`iosApp/`、`harmony-kmp-bridge/`、`harmonyApp/`。其余目录分别承担规格、文档、契约、设计源或构建职责，不参与业务实现。

## SDD 开发入口

修改前依次阅读 `AGENTS.md`、`LEARNINGS.md`、`spec/TRACE.md` 和相关 Spec。行为变化必须先更新 Spec、预留 TRACE，再写测试与实现。

```bash
./tools/check-sdd.sh
./tools/check-docs.sh
```

完整规则见 [`spec/README.md`](spec/README.md)，项目文档地图见 [`docs/README.md`](docs/README.md)。

## 常用构建

共享业务与测试：

```bash
./gradlew :common:check
```

Android Debug：

```bash
./gradlew :androidApp:assembleDebug
```

iOS：用 Xcode 打开 `iosApp/iosApp.xcodeproj`；构建前会生成当前架构的 `Shared.framework`。详情见 [`iosApp/README.md`](iosApp/README.md)。

HarmonyOS：用 DevEco Studio 打开 `harmonyApp/`。更新共享业务或 bridge 后先构建 KNOI 产物，详情见 [`harmony-kmp-bridge/README.md`](harmony-kmp-bridge/README.md) 与 [`harmonyApp/README.md`](harmonyApp/README.md)。

## 关键边界

- `common/src/commonMain` 不使用 Android、Apple、HarmonyOS SDK 或 UI 类型。
- 所有账号、健康和状态数据均为本地 mock，不接入真实服务器或真实协议。
- mock 与持久化字段先由 `common/src/commonMain/proto/` 下的 `.proto` 定义。
- 平台 UI 只负责展示、交互、导航和平台能力；共享业务规则放在 `common`。
- `docs/worklog/` 是完整历史归档：只允许新增归档文件，不修改或删除既有文件。
