# 开发工作流

## 日常开发

Android/iOS 共享逻辑：

```bash
./gradlew :common:check
```

Android 应用：

```bash
./gradlew :androidApp:assembleDebug
```

iOS 框架：

```bash
./tools/build-shared-xcframework.sh
```

HarmonyOS：

用 DevEco Studio 打开 `harmonyApp`，当前不走 Gradle 主线。ArkUI 页面保持原生实现；KNOI bridge 通过独立 `harmony-kmp-bridge` 生成 `libkn.so` 和 `entry/src/main/ets/knoi/provider.ets`，ArkTS 侧通过生成的 `getHarmonyLoginService()` 调用 Kotlin `HarmonyLoginService`，再复用 `common/src/commonMain` 的 `LoginFacade`。命令行验证时可临时设置 DevEco 内置工具环境变量：

```bash
env NODE_HOME=/Applications/DevEco-Studio.app/Contents/tools/node \
  DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
  PATH=/Applications/DevEco-Studio.app/Contents/tools/node/bin:/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin:/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin:$PATH \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleApp --no-daemon
```

## 修改共享逻辑

1. 先改 `common/src/commonMain`。
2. 补 `common/src/commonTest`。
3. Android 通过 `LoginStore` 或 `LoginFacade` 调用。
4. iOS 通过 `SharedLoginAdapter` 调用。
5. HarmonyOS 优先扩展 `harmony-kmp-bridge` 中的 KNOI service；登录、注册、验证码和登出逻辑已接入 `common/src/commonMain`，新增业务应继续放回 shared，再由 ArkTS 做原生 UI 映射。
6. 若涉及认证数据字段，先更新 `common/src/commonMain/proto/auth_mock.proto`，再同步更新 Kotlin `Mock*` 模型、Mapper、`MockAuthStoreJson` 与测试；`contract` 不维护认证接口契约。

### HarmonyOS bridge 修改规则

- 新增 state/effect/store 字段时，先改 `common` 模型；认证 Store 字段同步更新 `MockAuthStoreJson`，bridge State/Effect 字段同步更新 `HarmonyLoginJson` 与 ArkTS 映射。
- 不在 `HarmonyLoginService` 中直接新增零散的认证 Store JSON 解析逻辑；service 只负责暴露 KNOI 方法、调用 `LoginFacade` 和转发集中编解码器。
- 任何会改变 Kotlin store 的 ArkTS adapter 方法，成功后必须调用 `saveStoreSnapshot()`。
- `DebugStatePage` 不应出现在正式入口或常规导航中。
- Android 可以直接调用 `common` Kotlin API；iOS/HarmonyOS 使用 facade/bridge 是跨语言边界适配，不要求 Android 也套同一层。

## 修改平台 UI

- Android UI 只改 `androidApp`。
- iOS UI 只改 `iosApp`。
- HarmonyOS UI 只改 `harmonyApp`。
- 不把 UI 类型、平台生命周期、SDK 对象放入 `commonMain`。

### HarmonyOS ArkUI 状态规范

- 页面级数据必须落在 ArkUI 可追踪的状态上，例如 `@State`、`@StorageLink` 或 `@LocalStorageLink`。
- 页面不要在 `build()` 中直接深读普通 ViewModel 对象字段；先把展示字段同步到页面 `@State`，或通过组件 `@Link` 明确回写。
- 弹窗、Picker、Sheet、表单行、输入框组合等动态 UI 必须拆成 `@Component`；展示值用 `@Prop`，需要父子同步的值用 `@Link`。
- 子组件回调命名避开 ArkUI 内置事件名，优先使用 `tapRequested`、`valueChanged`、`dismissRequested`、`confirmRequested`、`photoRequested` 等业务语义名。
- 对对象或数组状态优先整体替换引用；不要依赖修改普通对象的嵌套字段触发刷新。
- Picker 兼容当前 SDK 时优先用 `onChange` 同步选中值，避免使用高版本才支持的事件导致兼容警告。

## 实验规则

HarmonyOS KMP/KNOI 工具链相关实验只能放在 `experimental/harmony-kmp`，并记录到 `docs/harmonyos-kmp-experiment.md`。实验目录不加入根 Gradle 主线，不影响 Android/iOS 交付。不要引入 KuiklyUI 共享 UI 路线。
