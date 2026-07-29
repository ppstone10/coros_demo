# 健康模块原生导航与返回状态 Spec

## 元数据

- Spec ID 前缀：`HLTH-NAV`
- 状态：已实现（Android 已完成运行时验收，iOS/HarmonyOS 运行时待设备复验）
- 适用范围：Android Compose、iOS SwiftUI、HarmonyOS ArkUI 登录后主导航
- 关联需求：四个底部根页面、健康详情/编辑及个人资料编辑的二级路由、返回位置恢复、体力恢复标题图标
- 最后更新：2026-07-29

## 目标

- 以注册登录模块的 Push/Pop/Replace/Reset 导航语义为模板，将健康详情和卡片编辑从页面内条件渲染迁移为三端原生二级路由。
- 明确“体能、记录、探索、我”是登录后的同一根层级，根层返回不回到认证流程或其他 Tab。
- 二级页面的顶部返回和平台系统返回均返回实际来源页面。
- 从健康卡片详情返回后保留进入前的健康列表位置。
- 将体力恢复标题图标替换为设计源中的回转箭头时钟图标。
- 保持业务逻辑、规则、数据和持久化继续以 `common` 为唯一权威，平台端只管理导航和 UI 状态。

## 非目标

- 不改变健康数据、卡片排序、场景、持久化或认证业务规则。
- 不向 `common` 引入 Android、SwiftUI、ArkUI 或任何平台导航类型。
- 不改变详情页当前“功能开发中”的业务内容。
- 不把底部 Tab 切换记录为可逐项回退的历史栈。
- 场景选择继续作为健康首页的临时弹层，不升级为全屏二级路由。

## 边界与禁止事项

- `HealthStore`、`HealthDashboardUseCase`、`HealthRules`、`HealthFacade` 继续位于 `common`；三端不得复制业务判断。
- 路由参数只传稳定卡片类型 ID，不传整份业务对象或平台 UI 类型；详情页通过共享健康状态按 ID 解析当前卡片。
- Android 使用 Navigation Compose，iOS 使用 `NavigationStack/NavigationPath`，HarmonyOS 使用现有 `AuthNavigator` 对 `router` 的语义封装。
- 旧规范 `HLTH-UI-ARCH-002`、`HLTH-UI-ARCH-008` 中将 Detail/Editor 作为 `DashboardPage` 页面内子模式的约束，被本 Spec 的 `HLTH-NAV-002` 取代；场景选择的局部状态不受影响。
- 根页面退出只适用于提供系统返回退出语义的平台。iOS 根页面表现为没有上一层可返回，不主动终止 App。

## 状态与接口

| 状态/接口 | 所属层 | 生命周期 | 约束 |
|---|---|---|---|
| 健康卡片数据与配置 | `common` HealthStore | 用户会话/持久化 | 唯一业务权威 |
| 当前底部 Tab | 各端主导航 UI | 登录后根页面 | Tab 切换不 Push |
| 健康详情路由参数 | 各端路由 | 单个二级页面 | 只携带稳定卡片类型 ID |
| 健康列表滚动状态 | 各端 UI | 根页面返回栈条目 | Push 二级页时保留，Pop 后恢复 |
| 场景选择可见状态 | 各端健康首页 UI | 临时弹层 | 返回先关闭弹层 |

## 行为规范

### `HLTH-NAV-001`：四个底部页面属于同一根层级

- Given：用户已登录并处于“体能、记录、探索、我”任一底部页面
- When：切换底部 Tab
- Then：只更新当前 Tab，不向页面返回栈压入新的根页面。
- When：在没有弹层或二级页面的根层触发平台返回
- Then：Android/HarmonyOS 允许系统退出当前 App；iOS 没有可返回的上一层。
- And：不得返回登录、注册页面或另一个历史 Tab。

### `HLTH-NAV-002`：健康详情与卡片编辑使用原生二级路由

- Given：用户从健康首页点击卡片或编辑入口
- When：打开详情页或卡片编辑页
- Then：三端使用各自原生导航栈 Push 二级路由，并隐藏底部导航。
- When：点击页面顶部返回或触发平台系统返回
- Then：Pop 当前二级路由并回到原健康首页，不退出 App。
- And：健康首页不再通过 `DashboardPage.Detail/Editor`、`currentPage=detail/editor` 或等价条件渲染模拟全屏导航。

### `HLTH-NAV-003`：个人资料编辑遵循二级路由语义

- Given：用户从“我”根页面进入个人资料编辑
- When：打开编辑页
- Then：进入二级路由并隐藏底部导航。
- When：取消、保存成功或触发系统返回
- Then：Pop 回“我”页面，不退出 App。
- 异常：HarmonyOS 已有 `ProfileCompletionPage(editMode=true)` Push/Pop 实现，可继续复用。

### `HLTH-NAV-004`：详情返回恢复健康列表位置

- Given：用户在健康列表滚动到任意卡片并打开其详情
- When：从详情页 Pop 返回
- Then：恢复同一健康首页实例及其原滚动状态，进入前可见的卡片仍保持在原位置附近。
- And：详情往返不得重新加载、重排或刷新健康业务数据。
- 异常：用户在详情期间通过其他明确业务动作改变卡片配置时，可按最新配置重新布局；普通详情返回不属于该异常。

### `HLTH-NAV-005`：业务与平台职责保持分离

- Given：三端执行路由改造
- Then：`common` 继续提供健康业务状态、规则、动作和持久化；平台 View/ViewModel 只桥接状态、渲染 UI、执行导航和保存滚动位置。
- And：不得因路由改造新增三端重复的卡片业务规则，也不得让 `common` 依赖平台导航 API。

### `HLTH-NAV-006`：体力恢复使用回转箭头时钟图标

- Given：设计源 `health_dashboard_resources/overview_cards/lap_recovery_time.webp`
- When：三端渲染 Recovery 卡片标题、编辑目录和详情图标
- Then：均通过同一语义资源映射展示回转箭头时钟图标，不再使用当前盒状 `icon_recovery_sports`。
- And：三端资源名称、映射和资源清单保持一致。

## 异常与降级

- 二级详情路由携带的卡片 ID 若已不在当前共享状态中，页面应安全返回上一页或展示可恢复占位，不得崩溃。
- 场景选择弹层可见时，返回优先关闭弹层，不退出根页面。
- 卡片编辑保存失败时保持在编辑页并展示既有错误，不得先 Pop。
- 平台构建环境不可用时，TRACE 必须标记实际未验证端，不得宣称通过。

## 测试与验收

| Spec ID | 自动验证 | 人工验收 |
|---|---|---|
| `HLTH-NAV-001` | 结构门禁确认 Tab 切换不 Push、根返回未被二级状态吞掉 | 四个根 Tab 分别触发返回 |
| `HLTH-NAV-002` | 结构门禁确认三端注册健康详情/编辑路由且页面内 Detail/Editor 状态已移除；三端构建 | 分别用顶部返回和系统返回进入/退出详情、编辑 |
| `HLTH-NAV-003` | 结构门禁确认三端个人资料编辑 Push/Pop；三端构建 | “我”→个人资料→返回/保存 |
| `HLTH-NAV-004` | Android UI 状态结构门禁；iOS/HarmonyOS 原生 Push/Pop 保留根页面结构；三端构建 | 滚动到中部/底部卡片，详情往返后对比位置 |
| `HLTH-NAV-005` | `git diff` 与 common 测试确认无平台 API 进入共享层 | 代码审查平台职责 |
| `HLTH-NAV-006` | 资源门禁与三端构建 | 对照示例确认 Recovery 标题图标 |

## 完成标准

- 三端健康详情、卡片编辑均通过原生二级路由 Push/Pop。
- 三端个人资料编辑保持正确二级返回行为。
- 四个底部根页面不建立 Tab 历史栈。
- 普通详情往返保留健康列表位置。
- Recovery 图标三端一致且资源门禁通过。
- 相关构建、`./tools/check-health-navigation.sh`、`./tools/check-resource-maintainability.sh`、`./tools/check-sdd.sh` 记录真实结果。
