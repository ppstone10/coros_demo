# 应用内语言切换与国家代码化 Spec

## 元数据

- Spec ID 前缀：`APP-LANG`
- 状态：Android 响应式资源读取缺陷已修复，跨端运行时人工复验待执行
- 负责人：项目维护者
- 关联需求：`spec/resource-localization.md`、`spec/resource-maintainability.md`
- 最后更新：2026-07-17

## 目标

- 三端不再各自被设备语言隐式控制，而是由应用内统一的语言状态选择简体中文或英文。
- 未做过选择的新安装统一使用简体中文，用户选择后持久化，后续启动保持所选语言。
- 在认证 Entrance 页右上角和登录后“我”页首行最右侧提供地球图标入口；选择语言后当前页面及后续页面立即刷新。
- 将资料中的国家与地区从最终展示名称迁移为稳定代码，展示时再按当前应用语言解析。

## 非目标

- 本轮不增加繁体中文、跟随系统选项、远程语言包或第三方翻译平台。
- 本轮不处理长英文视觉回归；换行、截断和极端动态字号继续作为后续人工验收项。
- HarmonyOS `DebugStatePage` 继续作为不发布的调试页，不要求随应用语言完整切换。
- 本轮不改变认证、健康、资料和账户的业务流程或真实数据边界。

## 数据与兼容性

| 名称 | 合法值 | 默认值 | 持久化 | 兼容规则 |
|------|--------|--------|--------|----------|
| 应用语言 | `zh-Hans`、`en` | `zh-Hans` | 各端原生轻量偏好存储 | 未知值回退 `zh-Hans` |
| 国家与地区 | `CN`、`US`、`GB`、`JP` | `CN` | 既有 profile `countryRegion` 字段 | 读取旧的中英文名称时归一为代码 |

- `common` 只保存国家代码，不保存“中文/English”或“中国/China”等最终展示文案。
- 既有 `.proto` 字段类型仍为字符串，不改变字段编号与 JSON 字段名；这是字段值契约迁移，不是结构迁移。
- 三端使用原生资源系统解析语言和国家名称；应用语言不进入 KMP 业务模型。

## 行为规范

### `APP-LANG-001`：应用语言状态统一且持久化

- Given：用户首次启动或已有语言选择。
- When：应用创建根 UI。
- Then：首次使用 `zh-Hans`；已有选择恢复 `zh-Hans` 或 `en`，三端不再因设备 Locale 不同而展示不同默认语言。
- 异常/边界：偏好缺失或非法时回退 `zh-Hans`。

### `APP-LANG-002`：两个语言入口共享选择行为

- Given：用户位于 Entrance 页，或登录后“我”页。
- When：点击右上角/首行最右侧地球图标。
- Then：显示包含“简体中文”和“English”的单选对话框，当前语言有选中标识；选择后关闭对话框。
- 异常/边界：图标使用平台系统图标或平台原生矢量资源，不复制位图；按钮具有本地化无障碍说明。

### `APP-LANG-003`：选择后全应用即时刷新

- Given：语言选择对话框已显示。
- When：用户选择与当前不同的语言。
- Then：当前可见页面、底部导航、弹窗、后续导航页面和动态消息均使用目标语言，同时写入持久化偏好。
- 异常/边界：不要求保留已展开的瞬态 Dialog/Sheet；认证与资料业务状态不得因语言切换丢失。

### `APP-LANG-004`：国家与地区持久化稳定代码

- Given：注册区域、资料选择器或旧持久化快照提供国家与地区。
- When：共享层保存或恢复 profile。
- Then：`countryRegion` 归一为 `CN/US/GB/JP`，空值与未知值回退注册区域或 `CN`；UI 按当前应用语言显示国家名称。
- 异常/边界：兼容旧值“中国/美国/英国/日本”与 `China/United States/United Kingdom/Japan`，重新保存后写回代码。

### `APP-LANG-005`：三端资源集合继续一致

- Given：新增语言选择文案和国家展示入口。
- When：运行资源门禁和三端构建。
- Then：Android 默认/英文、iOS `zh-Hans/en`、HarmonyOS base/en_US 的共享键集合一致，既有 192 个键不回退。
- 异常/边界：HarmonyOS Debug 页精确排除规则保持不变。

### `APP-LANG-006`：iOS 当前页面即时响应语言状态

- Given：用户在 Entrance 页或登录后的“我”页打开语言选择界面。
- When：选择与当前不同的语言。
- Then：发起选择的当前页面及同屏底部导航立即重算本地化文案，不依赖跳转、返回或重启触发刷新。
- 异常/边界：刷新不得重建认证协调器、清空导航路径、切换底部 Tab 或丢失登录/资料状态；页面通过观察同一个 `AppLanguageStore` 触发局部重算。

### `APP-LANG-007`：Entrance 语言入口跨端位置对齐

- Given：三端显示 Entrance 页面。
- When：页面完成安全区布局。
- Then：Android 现有布局作为基准；iOS Logo 与地球按钮位于同一顶部容器并纵向居中，登录/注册按钮组较现状下移；HarmonyOS 地球按钮位于 Logo 所在顶部区域的最右侧，不得落在画面中部。
- 异常/边界：使用安全区或全宽顶部容器及尾部内边距适配不同屏宽，不使用设备专属绝对横坐标；背景视频、Logo 尺寸与按钮业务行为保持不变。

### `APP-LANG-008`：Android Compose 资源读取响应配置变化

- Given：Android 应用语言或系统 Configuration 发生变化。
- When：语言 Provider 复制基础 Configuration，或认证导航展示 Snackbar/错误消息。
- Then：Composable 分别从 `LocalConfiguration.current` 与 `LocalResources.current` 获取响应式配置和资源，避免通过 `LocalContext.current.resources`/`Context.getString()` 留下旧值。
- 异常/边界：业务层消息键、语言持久化方式和 Snackbar 时序不变；不得用 Lint baseline 或 `@SuppressLint` 隐藏 Compose 响应式资源错误。

## 测试要求

| Spec ID | 自动化/人工验证 | 预期结果 |
|---------|-----------------|----------|
| `APP-LANG-001` | 三端语言存储单元/静态契约检查；三端构建 | 默认中文、合法值恢复、非法值回退 |
| `APP-LANG-002` | 入口代码与资源门禁；人工点击两个位置 | 两处均显示同一语言选择内容 |
| `APP-LANG-003` | 三端构建；人工在认证页和“我”页切换 | 当前页面立即切换，重启后保持 |
| `APP-LANG-004` | `LoginRulesTest`、JSON 兼容测试、`:common:check` | 新值保存代码，旧名称恢复为代码 |
| `APP-LANG-005` | `check-resources.sh`、`check-resource-maintainability.sh` | 新键三端齐全、债务不回升 |
| `APP-LANG-006` | `check-resources.sh` 静态契约、iOS simulator 构建；人工在两个入口切换 | 当前页面和底部导航无需跳转即刷新，页面状态不丢失 |
| `APP-LANG-007` | `check-resources.sh` 静态契约、iOS/HarmonyOS 构建；三端截图人工对比 | iOS 顶部同高且按钮组下移，HarmonyOS 图标稳定处于右上方 |
| `APP-LANG-008` | `./gradlew :androidApp:lintDebug`、`assembleDebug` | `LocalContextConfigurationRead` 与 `LocalContextGetResourceValueCall` 均为 0，Android 构建通过 |

## 验收标准

- [x] 国家代码测试先红后绿，旧快照兼容测试通过。
- [x] Entrance 和“我”页均有地球图标及语言选择对话框。
- [x] 三端代码统一首次默认中文，切换后刷新资源并持久化；因当前没有可用 Android 设备，本轮未把三端运行时点击与重启验收记为已执行。
- [x] common、Android、iOS、HarmonyOS 构建及 SDD/资源/文档门禁通过；未执行的人工验收如实记录。
- [x] TRACE、`Codex_worklog.md` 与必要的 `LEARNINGS.md` 完成闭环。
- [x] iOS Entrance、“我”页和底部导航直接观察同一语言状态，选择后无需导航触发代码刷新；iOS simulator 构建通过，实际点击仍待人工复验。
- [x] iOS Entrance 顶部 Logo/语言按钮已合入同一顶部容器且按钮组下移 24pt；HarmonyOS Logo/语言按钮已合入全宽顶部栏，两个平台构建通过，最终截图对比待人工复验。
- [x] Android Configuration、Snackbar 和认证错误消息全部通过 Compose 响应式资源入口读取；`lintDebug` 从 9 个相关 Error 转为通过，`assembleDebug` 通过。
