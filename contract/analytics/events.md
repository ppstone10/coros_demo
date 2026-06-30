# 埋点事件

| 事件 | 触发时机 | 属性 |
| --- | --- | --- |
| `login_submit` | 用户点击登录按钮。 | `source`、`has_username`、`has_password` |
| `login_success` | 登录成功返回。 | `source`、`user_id` |
| `login_failure` | 登录失败返回。 | `source`、`error_code` |

事件名称三端共享。平台埋点 SDK 的具体调用只放在 Android、iOS、HarmonyOS 应用层。
