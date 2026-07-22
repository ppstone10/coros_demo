# 离线运动路线创建模块 Spec

## 1. 模块目标

本模块用于模拟用户在本地地图中创建运动路线，并展示路线距离与预计时间。

支持平台：

- Android
- iOS
- HarmonyOS

三端要求：

- 三端复用同一套 KMP `common` 业务逻辑。
- 三端 UI 不共享，分别使用各平台 Native UI 实现。
- 平台层只负责 UI、资源加载和必要的平台能力适配。
- 不允许在任一平台重复实现一套独立业务逻辑。

---

## 2. 功能范围

模块需要支持：

- 展示本地虚构地图。
- 地图平移、缩放和旋转。
- 用户选择起点和终点。
- 根据本地数据生成一条可行路线。
- 展示路线距离和预计时间。
- 提供“开始运动”和“取消运动”操作。
- 一期中，点击“开始运动”即视为本次模拟运动完成。
- 完成后向“记录”模块写入一条本地跑步记录。
- App 重启后可恢复未完成路线和已完成记录。
- 为后续“体能”模块读取运动数据保留本地能力。

一期不包含：

- 真实地图服务。
- 真实 GPS。
- 在线路线规划。
- 地址搜索。
- 导航。
- 后台轨迹采集。
- 服务端同步。
- 硬件或外设能力。

---

## 3. 安全边界

- 开发必须在隔离训练仓库完成。
- 不得接触或引用正式项目源码、真实接口、真实协议、真实密钥、真实用户数据、内部包名、接口域名或业务代号。
- 所有数据必须来自本地 mock、fixture 或本地 mock repository。
- 不得接入生产、测试、内测或其他真实服务。
- 不得保留真实 URL、真实 path、真实请求头、真实参数、真实响应结构或签名逻辑。
- 不得引入在线地图 SDK、网络请求库、真实定位 SDK 或远程配置能力。
- 地图、道路、障碍、坐标和运动记录必须全部为虚构数据。
- 不得使用真实经纬度、真实地图瓦片或真实道路数据。
- mock 数据、状态数据、记录数据和错误场景数据必须使用 Protocol Buffers 定义。
- 不得使用临时 JSON 代替业务数据结构。
- 本地状态需要可恢复。
- 训练代码不得依赖正式仓库。

建议在 CI 中检查：

- URL 字面量。
- 网络权限。
- 密钥特征。
- 非允许依赖。
- 真实包名或业务代号。
- 非虚构 fixture。
- 未定义 `.proto` 的业务数据。

---

## 4. 技术架构

### 4.1 KMP 共享范围

KMP `common` 负责：

- 业务模型。
- 页面状态。
- 业务规则。
- 路线计算。
- Protobuf 转换。
- 本地数据访问抽象。
- 状态持久化逻辑。
- 记录生成与去重。
- 核心单元测试。

平台层负责：

- Native UI。
- 地图绘制。
- 手势处理。
- 平台资源加载。
- 应用生命周期。
- 本地文件目录或 KeyValue 能力适配。
- 将 common 输出的状态展示到页面。

HarmonyOS 必须复用同一套 common，不单独使用 ArkTS 重写业务逻辑。

### 4.2 页面架构

页面可采用 MVI 或 MVVM，不使用 MVP。

无论采用哪种方式，都应满足：

```text
用户操作
  ↓
common 处理业务
  ↓
输出页面状态
  ↓
Native UI 渲染
```

Native UI 不负责路线计算、记录生成或业务状态迁移。

---

## 5. 核心能力抽象

建议至少保留以下抽象，具体命名可根据工程调整：

```kotlin
interface RoutePlanner {
    suspend fun planRoute(
        start: MapPoint,
        end: MapPoint
    ): RouteResult
}

interface MapFixtureRepository {
    suspend fun loadFixture(): MapFixture
}

interface RouteStateRepository {
    suspend fun load(): RouteSession?
    suspend fun save(session: RouteSession)
    suspend fun clear()
}

interface WorkoutRecordRepository {
    suspend fun saveIfAbsent(record: WorkoutRecord)
    suspend fun loadAll(): List<WorkoutRecord>
}
```

不要求 common 主动控制 Native 地图 UI。

Native UI 只消费 common 输出的页面状态，例如：

```kotlin
data class RouteUiState(
    val phase: RoutePhase,
    val mapAssetId: String?,
    val startPoint: MapPoint?,
    val endPoint: MapPoint?,
    val route: MapRoute?,
    val distanceText: String?,
    val durationText: String?,
    val isLoading: Boolean,
    val error: RouteError?
)
```

---

## 6. Protobuf 数据要求

建议至少提供：

```text
map_contract.proto
map_state.proto
map_fixture.proto
workout_record.proto
```

### 6.1 基础地图结构

```protobuf
syntax = "proto3";

package training.route.v1;

message MapPoint {
  sint32 x_milli = 1;
  sint32 y_milli = 2;
}

message MapViewport {
  sint32 center_x_milli = 1;
  sint32 center_y_milli = 2;
  uint32 scale_milli = 3;
  sint32 rotation_millidegrees = 4;
}

message MapRoute {
  string local_route_id = 1;
  repeated MapPoint points = 2;
  uint64 distance_millimeters = 3;
  uint64 estimated_duration_milliseconds = 4;
}
```

### 6.2 页面和持久化状态

```protobuf
syntax = "proto3";

package training.route.v1;

import "map_contract.proto";

enum RoutePhase {
  ROUTE_PHASE_UNSPECIFIED = 0;
  ROUTE_PHASE_IDLE = 1;
  ROUTE_PHASE_SELECTING_START = 2;
  ROUTE_PHASE_SELECTING_END = 3;
  ROUTE_PHASE_CALCULATING = 4;
  ROUTE_PHASE_READY = 5;
  ROUTE_PHASE_SAVING_RECORD = 6;
}

message RouteSession {
  uint32 schema_version = 1;
  string local_session_id = 2;
  RoutePhase phase = 3;
  MapViewport viewport = 4;
  optional MapPoint start_point = 5;
  optional MapPoint end_point = 6;
  optional MapRoute route = 7;
  int64 updated_at_epoch_millis = 8;
}
```

临时 UI 状态，例如 Snackbar、页面跳转和按钮按压状态，不需要持久化。

### 6.3 本地地图 fixture

```protobuf
syntax = "proto3";

package training.route.v1;

import "map_contract.proto";

message RoadNode {
  string local_id = 1;
  MapPoint point = 2;
}

message RoadEdge {
  string from_node_id = 1;
  string to_node_id = 2;
  uint64 distance_millimeters = 3;
  uint64 duration_milliseconds = 4;
  repeated MapPoint shape_points = 5;
  bool bidirectional = 6;
}

message MapFixture {
  uint32 fixture_version = 1;
  string fixture_id = 2;
  bool synthetic_coordinates = 3;
  string map_asset_id = 4;
  repeated RoadNode road_nodes = 5;
  repeated RoadEdge road_edges = 6;
}
```

`synthetic_coordinates` 必须为 `true`。

### 6.4 运动记录

```protobuf
syntax = "proto3";

package training.workout.v1;

enum SportType {
  SPORT_TYPE_UNSPECIFIED = 0;
  SPORT_TYPE_RUNNING = 1;
}

message WorkoutRecord {
  uint32 schema_version = 1;
  string local_record_id = 2;
  string source_route_id = 3;
  SportType sport_type = 4;
  uint64 distance_millimeters = 5;
  uint64 duration_milliseconds = 6;
  int64 completed_at_epoch_millis = 7;
}
```

同一个 `source_route_id` 最多生成一条记录。

字段可以根据实际实现增减，但必须保持：

- 有明确 `.proto` 定义。
- 三端使用同一数据契约。
- 能支持状态恢复和记录去重。
- 不包含真实业务字段或真实服务信息。

---

## 7. 路线创建流程

建议流程：

```text
进入页面
→ 加载本地地图
→ 点击“创建路线”
→ 选择起点
→ 选择终点
→ 本地计算路线
→ 显示距离和预计时间
→ 开始运动或取消运动
```

基本规则：

- 用户点击位置可以吸附到附近道路。
- 点击位置距离道路过远时，应提示重新选择。
- 路线只能基于本地 fixture 中的可通行道路生成。
- 路线不能明显穿越障碍区域。
- 路线不存在时，应允许重试或重新选点。
- 计算过程中应避免重复提交。

路线规划可以使用 Dijkstra、A* 或其他适合本地道路图的算法。

Spec 不限制具体算法，只要求：

- 完全本地执行。
- 三端通过 common 得到一致结果。
- 结果可测试。
- 路线符合 fixture 定义的道路约束。
- 距离和时间计算规则明确。

---

## 8. 开始运动与记录同步

用户点击“开始运动”后：

1. common 验证当前路线可用。
2. 生成一条本地跑步记录。
3. 保存到 `WorkoutRecordRepository`。
4. 保存成功后清除当前路线草稿。
5. Native UI 显示完成结果或进入记录页面。

需要保证：

- 快速连续点击不会生成重复记录。
- 保存失败时不清除当前路线。
- 保存失败后可以重试。
- App 在保存过程中退出后，重新进入仍不会重复生成记录。
- 记录页面只从本地记录仓库读取数据。

记录卡片至少展示：

- 跑步。
- 距离。
- 运动时长。
- 完成时间。

默认按完成时间倒序排列。

---

## 9. 本地持久化

可使用：

- Protobuf binary。
- SQLite。
- DataStore。
- UserDefaults。
- KeyValue。
- 其他等价的本地存储方案。

具体方案不在 Spec 中限制，但必须满足：

- 数据仅保存在 App 私有目录。
- App 重启后可恢复。
- 数据损坏时不崩溃。
- 不支持的 schema 版本可以安全回退。
- 保存过程尽量避免产生半写入数据。
- 已取消路线不恢复。
- 已完成路线不作为草稿恢复。
- 已完成记录不可因重试重复写入。

---

## 10. 错误场景

至少覆盖：

- 地图 fixture 不存在或损坏。
- fixture 不是虚构数据。
- 点击位置不在道路附近。
- 路线不存在。
- 路线计算失败。
- 状态读取失败。
- 状态保存失败。
- 运动记录保存失败。
- Protobuf 数据损坏。
- schema 版本不支持。

错误提示不得展示：

- 文件路径。
- 原始堆栈。
- 内部类名。
- 底层库错误详情。
- 任何真实项目信息。

---

## 11. 验收标准

### 11.1 三端与架构

- Android、iOS、HarmonyOS 均复用同一 KMP common。
- 三端 UI 分别使用 Native UI。
- 平台层没有重复实现路线规划、记录生成和业务状态逻辑。
- 完整流程中不产生网络请求。

### 11.2 地图

- 可以加载本地虚构地图。
- 可以平移、缩放和旋转。
- 指北针随旋转变化。
- 比例尺随缩放变化。
- 未进入路线创建状态时，点击地图不会设置起终点。

### 11.3 路线

- 点击“创建路线”后可以选择起点和终点。
- 选择完成后可以生成本地路线。
- 页面展示起点、终点、路线、距离和预计时间。
- 无法生成路线时有明确的可恢复操作。
- 重新选择后旧路线正确清除。

### 11.4 完成与取消

- 路线完成后显示“开始运动”和“取消运动”两个等宽按钮。
- 点击“开始运动”后生成一条跑步记录。
- 重复点击不会重复生成记录。
- 保存失败时保留当前路线。
- 点击“取消运动”不会生成记录，并清除路线草稿。

### 11.5 状态恢复

- 只选择起点时退出，重新进入可以继续选择终点。
- 路线已生成时退出，重新进入可以恢复路线。
- 已完成记录重新进入后仍存在。
- 数据损坏时 App 不崩溃，并回到安全状态。

### 11.6 记录页面

- 记录以卡片形式展示。
- 卡片显示跑步、距离、时长和完成时间。
- 记录顺序稳定。
- 同一路线不会出现重复记录。

---

## 12. 测试要求

测试应覆盖核心业务内容，包括：

- 起点和终点选择。
- 路线规划成功和失败。
- 无效点击。
- 距离和时间计算。
- 开始运动。
- 取消运动。
- 重复提交。
- 记录保存失败和重试。
- 状态保存和恢复。
- Protobuf 编解码。
- fixture 损坏。
- schema 版本不支持。

三端至少需要验证：

- common 可以正常初始化。
- common 可以加载本地 fixture。
- common 可以完成一次路线计算。
- common 可以保存和恢复路线状态。
- common 可以幂等写入运动记录。

不强制固定具体覆盖率数值，但核心业务分支和主要异常场景必须有自动化测试。

---

## 13. 一期完成定义

满足以下条件即视为一期完成：

- 三端复用同一 KMP common。
- 三端 Native UI 可以完成完整路线创建流程。
- 所有数据均为本地虚构数据。
- 不包含网络和真实地图能力。
- Protobuf 契约完整。
- 路线可以本地生成。
- 距离和预计时间可以正确展示。
- 运动记录可以幂等保存。
- 路线和记录可以恢复。
- 核心业务和异常场景测试通过。
- 安全检查通过。
