# 运动路线创建

## 1. 模块定位

模拟用户创建运动路线，并计算距离以及时间。

运动路线创建模块只允许使用本地地图，不接入任何真实服务器、测试服务器、内测服务器或外部认证服务。

运动路线创建模块负责：

- 渲染显示本地地图（可放大、缩小、旋转地图）。
- 进行地图中始终点的选取渲染。
- 计算始终点的距离即预计时间。
- 提供开始运动和取消运动两个选项，因当前是虚拟模块，开始运动即完成运动，取消运动即不进行本次运动。
- 完成一次运动后，与“记录”模块保持数据的同步。
- 保留与“体能”模块接入的能力。

## 2. 安全边界

- 开发必须在隔离训练仓库完成，不得接触或引用正式项目源码、真实接口、真实协议、真实密钥、真实用户数据、内部包名、类名、接口域名或业务代号。
- 所有业务数据必须使用本地 mock 数据、本地 fixture 或本地 mock repository 生成，不得接入生产环境、测试环境、内测环境或任何真实服务端。
- mock 数据结构必须使用 Protocol Buffers 定义：每个业务项目至少提供对应的 `.proto` 文件，说明本项目 mock 数据、状态数据和错误场景数据的字段结构。KMP 共享业务层可以把 protobuf message 转换为 domain model，但不得用无结构约束的临时 JSON 替代数据结构定义。
- 不保留服务器 API 说明，不编写真实 URL、真实 path、真实请求头、真实请求参数、真实响应结构或加密签名逻辑。
- mock 数据必须能保存状态：新增、编辑、删除、已读、收藏、草稿、任务进度、登录态等操作需要在 App 本地可恢复。状态结构也必须有对应 protobuf message 定义。持久化可使用 protobuf binary、protobuf JSON、SQLite、DataStore、UserDefaults、KeyValue 存储或等价本地方案。
- 训练代码不依赖当前正式仓库。
- 不设计硬件端、外设协议、外设 SDK 或固件；涉及状态、任务、资源等能力时，只做 App 侧状态消费、任务编排和异常处理模拟。

## 3. 技术栈与架构
- 使用KMP共享业务层 + Nativie UI。
- 页面架构选择MVVM或MVI，不实用MVP。
- KMP 共享业务层承载业务模型、业务规则、protobuf 数据结构、本地 mock 数据访问、数据访问抽象、状态持久化和核心单元测试。
- Native UI 只消费 KMP 输出的页面状态、错误状态和一次性效果，只负责页面展示、交互和平台能力适配。

## 4. 地图接口能力
建议定义四个能力接口：
```kotlin
interface MapSurfacePort {
fun setMarkers(markers: List<MapMarker>)
fun setRoute(points: List<MapPoint>)
fun moveCamera(viewport: MapViewport)
fun clear()
}

interface RoutePlanner {
suspend fun planRoute(
start: MapPoint,
end: MapPoint
): RouteResult
}

interface LocationFeed {
fun start(observer: (MapPoint) -> Unit)
fun stop()
}

interface MapStateStore {
suspend fun load(): PersistedMapSession?
suspend fun save(session: PersistedMapSession)
}
```
训练仓库中的实现全部是本地的：
```
MapSurfacePort
└── LocalCanvasMapSurface

RoutePlanner
└── FixtureGraphRoutePlanner

LocationFeed
└── FixtureLocationFeed

MapStateStore
└── ProtobufFileStateStore
```
三端 UI 不共享，但应消费一致的 MapRenderModel：
```kotlin
data class MapRenderModel(
val backgroundAsset: String,
val viewport: MapViewport,
val markers: List<MapMarker>,
val routePoints: List<MapPoint>,
val currentLocation: MapPoint?,
val selectionPhase: SelectionPhase
)
```

## 5. Protobuf 结构定义

建议至少拆成三个文件。

```map_contract.proto
syntax = "proto3";

package training.map.v1;

message MapPoint {
sint32 x_milli = 1;
sint32 y_milli = 2;
}

enum MarkerType {
MARKER_TYPE_UNSPECIFIED = 0;
MARKER_TYPE_START = 1;
MARKER_TYPE_END = 2;
MARKER_TYPE_CURRENT_LOCATION = 3;
MARKER_TYPE_WAYPOINT = 4;
}

message MapMarker {
string local_id = 1;
MarkerType type = 2;
MapPoint point = 3;
string display_label = 4;
}

message MapViewport {
sint32 center_x_milli = 1;
sint32 center_y_milli = 2;
uint32 scale_milli = 3;
}

message MapRoute {
string local_id = 1;
repeated MapPoint points = 2;
uint32 distance_milli = 3;
uint32 estimated_duration_seconds = 4;
}
```

```map_state.proto
syntax = "proto3";

package training.map.v1;

import "map_contract.proto";

enum SelectionPhase {
SELECTION_PHASE_UNSPECIFIED = 0;
SELECTION_PHASE_SELECTING_START = 1;
SELECTION_PHASE_SELECTING_END = 2;
SELECTION_PHASE_ROUTE_READY = 3;
SELECTION_PHASE_TRACKING = 4;
}

enum MockErrorCode {
MOCK_ERROR_CODE_UNSPECIFIED = 0;
MOCK_ERROR_CODE_ROUTE_NOT_FOUND = 1;
MOCK_ERROR_CODE_LOCATION_PERMISSION_DENIED = 2;
MOCK_ERROR_CODE_STORAGE_FAILURE = 3;
MOCK_ERROR_CODE_FIXTURE_CORRUPTED = 4;
MOCK_ERROR_CODE_SIMULATED_TIMEOUT = 5;
}

message MockError {
MockErrorCode code = 1;
string safe_message = 2;
bool recoverable = 3;
}

message MapScreenState {
uint32 schema_version = 1;
uint64 revision = 2;

SelectionPhase phase = 3;
MapViewport viewport = 4;

optional MapPoint start_point = 5;
optional MapPoint end_point = 6;
optional MapRoute route = 7;

repeated MapMarker markers = 8;
repeated MapPoint tracked_points = 9;

optional MockError error = 10;
}

message PersistedMapSession {
uint32 schema_version = 1;
string local_session_id = 2;
MapScreenState screen_state = 3;
int64 updated_at_epoch_millis = 4;
}
```

```map_fixture.proto
syntax = "proto3";

package training.map.v1;

import "map_contract.proto";
import "map_state.proto";

message RoadNode {
string local_id = 1;
MapPoint point = 2;
}

message RoadEdge {
string from_node_id = 1;
string to_node_id = 2;
uint32 cost = 3;
repeated MapPoint shape_points = 4;
}

message MockLocationFrame {
uint32 offset_millis = 1;
MapPoint point = 2;
}

message MapFixture {
uint32 fixture_version = 1;
string fixture_id = 2;
bool synthetic_coordinates = 3;

string background_asset_name = 4;
repeated RoadNode road_nodes = 5;
repeated RoadEdge road_edges = 6;
repeated MockLocationFrame location_frames = 7;

optional MockErrorCode injected_error = 8;
}
```

## 6. 路径规划
有关距离和时间的计算需要通过路径规划算法来计算得到，这里采用本地的算法。

且当前内容只做简单展示和功能体现，不考虑复杂的旅行商问题，所以只有起点和终点两个节点，计算两点之间的距离和时间即可。

这里需要根据用户提供的起点和终点，来规划出一条在地图中可行的路径，路线要合乎常理，不得穿越障碍物、频繁转向换道。

用户点击后：
- 找到距离点击位置最近的道路节点。
- 将起点和终点吸附到道路节点。
- 使用本地 Dijkstra 或 A* 算法寻找路径。
- 合并边上的 shape_points。
- 生成 MapRoute。
- 将路线保存到 MapScreenState。

## 7. 验收标准
- 用户点击“探索”后，可以显示当前的本地地图，地图可放大、缩小、旋转，但对应指北针和比例尺要同步变化。
- 用户可点击“创建路线”按钮，点击按钮完之后可在地图上进行起点和终点的选取。
- 起点和终点都选取完成之后显示“开始运动”和“取消运动”两个按钮（最下方，两个按钮排布在一行，权重均为1）
- 点击“开始运动”之后即为运动完成，在“记录”页面中要保存当前的运动记录。“记录”页面中记录均为“跑步”运动，需要保留距离和时间二者内容，以卡片的形式呈现。

## 8. 单元测试要求
根据代码完成对应的代码测试，要测量到所有业务内容。
