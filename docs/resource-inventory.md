# 三端资源盘点与迁移基线

本文记录全模块资源治理的机器清单口径和当前迁移债务。权威可执行数据位于 `tools/resource-inventory.json`，本文用于人工评审，不手工复制每个平台的完整文件树。

## 当前运行资源

| 类别 | Android | iOS | HarmonyOS | 跨端规则 |
|------|---------|-----|-----------|----------|
| 共享业务图片 | drawable/mipmap | imageset | media | 37 个语义名必须三端同时存在 |
| 视频 | `raw/home.mp4` | `Resources/home.mp4` | `rawfile/home.mp4` | 三端 SHA-256 一致 |
| Lottie | `raw/watch_status.json` | `Resources/watch_status.json` | `rawfile/watch_status.json` | 三端 SHA-256 一致 |
| 认证错误/校验文字 | values/values-en | Localizable.xcstrings | base/en_US | 23 个认证语义键由 `common` 输出、三端解析 |
| 认证页面静态文字 | values/values-en | Localizable.xcstrings | base/en_US | 51 个 `auth_*` 键保持一致，认证页不再直接承载可见中文文案 |
| 导航文字 | values/values-en | Localizable.xcstrings | base/en_US | 5 个 `nav_*` 键保持一致，页面使用原生资源 |
| 账户文字 | values/values-en | Localizable.xcstrings | base/en_US | 12 个 `account_*` 键保持一致，账户页不再使用 `AppText.Account` |
| 公共/资料文字 | values/values-en | Localizable.xcstrings | base/en_US | 42 个 `common_*` / `profile_*` 键保持一致，iOS/HarmonyOS 资料选择器可见文案已使用原生资源 |
| 健康与法律文字 | values/values-en | Localizable.xcstrings | base/en_US | 健康标题/摘要使用语义键与参数；法律正文以轻量结构资源保存中文及 Demo 英文 |
| 应用语言 | SharedPreferences + CompositionLocal | UserDefaults + selected Bundle | PersistentStorage + i18n preferred language | 首次简体中文，支持应用内中英文切换与持久化 |
| AppIcon/启动资源 | Android launcher/mipmap | AppIcon/LaunchLogo | app_icon/logo_splash | 平台专属，不强制同名 |

37 个共享图片名称覆盖健康卡片、导航、资料编辑和认证输入状态。添加、重命名或删除共享图片时，先更新机器清单，再同步三端调用和运行资源；不得只为目录对称复制平台专属资源。

## 设计源与运行资源

- `login_register_resources/`：认证设计与导入来源，只用于追溯。
- `health_dashboard_resources/`：健康首页设计与导入来源，只用于追溯。
- `androidApp/src/main/res/`、`iosApp/iosApp/Assets.xcassets/` 与 `Resources/`、`harmonyApp/entry/src/main/resources/`：实际运行资源。

设计源不参与应用构建。运行资源替换完成后仍保留设计来源，删除前必须证明追溯内容已有其他完整落点。

## 当前硬编码债务基线

| 类别 | 当前上限 | 迁移方向 |
|------|---------:|----------|
| Android 中文字符串字面量 | 0 | 生产页面已迁入 `strings.xml` |
| iOS 中文字符串字面量 | 0 | 生产页面已迁入 String Catalog |
| HarmonyOS 中文字符串字面量 | 0 | 生产页面已迁入 `element/string.json`；`DebugStatePage` 精确排除 |
| common 中文字符串字面量 | 0 | 国家持久化已代码化；旧中文名称通过 Unicode 兼容映射读取 |
| Android 直接颜色表达 | 0 | 颜色定义文件排除后，生产页面全部使用语义 Token |
| iOS 直接颜色表达 | 0 | 颜色定义文件排除后，生产页面全部使用语义 Token |
| HarmonyOS 直接十六进制颜色 | 0 | Token 定义与非发布调试页排除后，生产页面全部使用语义 Token |

这些数字不是质量目标，而是历史债务上限。门禁只允许数字下降；新增用户文案或视觉值必须直接使用平台资源，不允许通过提高上限维持绿灯。

## 分批迁移顺序

1. 审计图片密度、透明边缘、重复文件和未引用资源；不在引用不清时删除。
2. 建立 Resource Gallery 和语言/主题视觉验收入口；应用内中英文切换已实现，长英文布局仍按后续页面开发节奏人工验收。

## 验证

```bash
./tools/check-resource-maintainability.sh
./tools/check-resources.sh
```

第一个命令保护全资源清单、共享图片/Raw 和债务上限；第二个命令同时负责认证语义键、应用语言持久化契约、两处语言入口与三端中英文资源完整性。
