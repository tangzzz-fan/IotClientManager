# ConnectivityLayer Framework

## 概述

ConnectivityLayer 是一个统一的通信框架，为智能家居 iOS 应用提供多协议通信支持。该框架采用策略模式和工厂模式，支持 MQTT、BLE、Zigbee、Matter、阿里云 IoT SDK 等多种通信协议，并能根据设备特性、网络环境和用户偏好智能选择最佳通信策略。

## 核心特性

### 🚀 多协议支持
- **MQTT**: 轻量级消息队列协议，适用于 WiFi 环境
- **BLE**: 蓝牙低功耗，适用于近距离低功耗设备
- **Zigbee**: 低功耗网状网络协议
- **Matter**: 智能家居互操作性标准
- **阿里云 IoT SDK**: 阿里云物联网平台集成
- **HTTP/WebSocket**: 标准 Web 协议支持

### 🧠 智能策略选择
- **自动策略**: 根据上下文自动选择最佳协议
- **可靠性优先**: 优先选择最稳定的连接方式
- **速度优先**: 最小化延迟，优化响应时间
- **省电策略**: 延长电池设备使用时间
- **安全优先**: 确保数据传输安全
- **专用策略**: BLE 专用、WiFi 专用等特定场景策略
- **混合策略**: 动态切换多种协议

### 🏗️ 模块化架构
- **协议适配器**: 统一的通信服务接口
- **策略工厂**: 动态策略创建和管理
- **连接工厂**: 服务实例创建和配置
- **设备通信器**: 高级通信管理
- **连接池**: 连接资源管理
- **重连策略**: 智能重连机制

### 📊 监控和诊断
- **连接质量评估**: 信号强度、稳定性、延迟等指标
- **统计信息收集**: 连接次数、消息量、错误率等
- **健康状态监控**: 实时系统健康检查
- **性能指标**: 吞吐量、响应时间等性能数据

## 快速开始

### 1. 基本使用

```swift
import ConnectivityLayer

// 创建连接管理器
let configuration = ConnectivityLayerConfiguration.default
let manager = ConnectivityLayerManager(configuration: configuration)

// 创建通信上下文
let context = CommunicationContext(
    deviceId: "smart-light-001",
    deviceType: "smart_light",
    deviceModel: "SmartLight-v2.0",
    preferredProtocols: ["MQTT", "BLE"],
    networkEnvironment: networkInfo,
    userPreferences: preferences,
    connectionHistory: [],
    deviceCapabilities: capabilities,
    timestamp: Date()
)

// 创建设备通信器
let strategyFactory = CommunicationStrategyFactory()
let communicator = DeviceCommunicator(context: context, strategyFactory: strategyFactory)

// 连接设备
try await communicator.connect()

// 发送消息
let message = MQTTMessage(
    topic: "device/smart-light-001/command",
    payload: "turn_on".data(using: .utf8)!,
    qos: .atLeastOnce
)
try await communicator.sendMessage(message)
```

### 2. 自定义策略

```swift
// 创建自定义策略
struct CustomStrategy: CommunicationStrategy {
    let strategyName = "Custom"
    let strategyDescription = "自定义通信策略"
    let supportedProtocols = ["MQTT", "BLE"]
    let priority = 75
    
    func evaluate(context: CommunicationContext) -> StrategyEvaluation {
        // 自定义评估逻辑
        return StrategyEvaluation(
            suitabilityScore: 80,
            isApplicable: true,
            reasons: ["自定义策略评估"]
        )
    }
    
    func selectProtocol(context: CommunicationContext) -> ProtocolSelection {
        // 自定义协议选择逻辑
        return ProtocolSelection(
            selectedProtocol: "MQTT",
            alternativeProtocols: ["BLE"],
            selectionReason: "自定义协议选择"
        )
    }
    
    func createCommunicationService(
        protocol: String,
        context: CommunicationContext,
        factory: ConnectionFactory
    ) throws -> any CommunicationService {
        return try factory.createCommunicationService(type: protocol, configuration: nil)
    }
}

// 注册自定义策略
strategyFactory.registerStrategy(CustomStrategy())
```

### 3. 协议配置

```swift
// MQTT 配置
let mqttConfig = MQTTConfiguration(
    brokerHost: "mqtt.example.com",
    brokerPort: 1883,
    clientId: "ios-client-001",
    qos: .exactlyOnce,
    cleanSession: false,
    keepAlive: 60,
    username: "user",
    password: "password",
    useTLS: true
)

// 阿里云 IoT 配置
let aliyunConfig = AliyunConfiguration(
    productKey: "your-product-key",
    deviceName: "your-device-name",
    deviceSecret: "your-device-secret",
    region: "cn-shanghai",
    logLevel: .info
)

// 创建服务
let connectionFactory = ConnectionFactory()
let mqttService = try connectionFactory.createCommunicationService(
    type: "MQTT",
    configuration: mqttConfig
)
let aliyunService = try connectionFactory.createCommunicationService(
    type: "AliyunSDK",
    configuration: aliyunConfig
)
```

## 架构设计

### 核心组件

```
┌─────────────────────────────────────────────────────────────┐
│                    ConnectivityLayer                        │
├─────────────────────────────────────────────────────────────┤
│  ConnectivityLayerManager (主管理器)                        │
├─────────────────────────────────────────────────────────────┤
│  DeviceCommunicator (设备通信器)                            │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │ StrategyFactory │  │ ConnectionFactory│                  │
│  │   (策略工厂)    │  │   (连接工厂)     │                  │
│  └─────────────────┘  └─────────────────┘                  │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │   Strategies│ │  Adapters   │ │   Models    │           │
│  │   (策略)    │ │  (适配器)   │ │   (模型)    │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

### 设计模式

1. **策略模式 (Strategy Pattern)**
   - `CommunicationStrategy` 协议定义策略接口
   - 具体策略类实现不同的通信选择逻辑
   - `DeviceCommunicator` 作为上下文使用策略

2. **工厂模式 (Factory Pattern)**
   - `ConnectionFactory` 创建通信服务实例
   - `CommunicationStrategyFactory` 创建策略实例
   - 支持动态注册和创建

3. **适配器模式 (Adapter Pattern)**
   - 各协议适配器实现统一的 `CommunicationService` 接口
   - 屏蔽不同协议的实现细节

4. **观察者模式 (Observer Pattern)**
   - 连接状态变化通知
   - 消息接收事件处理

## API 参考

### 核心协议

#### CommunicationService
```swift
protocol CommunicationService {
    var isConnected: Bool { get }
    var connectionState: ConnectionState { get }
    var lastError: (any Error)? { get }
    
    func connect() async throws
    func disconnect() async
    func sendMessage(_ message: any CommunicationMessage) async throws
    func subscribe(to topic: String) async throws
    func unsubscribe(from topic: String) async throws
    func updateConfiguration(_ configuration: Any) throws
    func getDiagnosticInfo() -> [String: Any]
}
```

#### CommunicationStrategy
```swift
protocol CommunicationStrategy {
    var strategyName: String { get }
    var strategyDescription: String { get }
    var supportedProtocols: [String] { get }
    var priority: Int { get }
    
    func evaluate(context: CommunicationContext) -> StrategyEvaluation
    func selectProtocol(context: CommunicationContext) -> ProtocolSelection
    func createCommunicationService(
        protocol: String,
        context: CommunicationContext,
        factory: ConnectionFactory
    ) throws -> any CommunicationService
}
```

### 主要类

#### DeviceCommunicator
```swift
class DeviceCommunicator {
    func connect() async throws
    func disconnect() async
    func sendMessage(_ message: any CommunicationMessage) async throws
    func subscribe(to topic: String) async throws
    func unsubscribe(from topic: String) async throws
    func updateContext(_ context: CommunicationContext)
    func switchStrategy(_ strategyName: String) throws
    func getAvailableStrategies() -> [StrategyInfo]
    func getConnectionInfo() -> ConnectionInfo?
    func getCurrentContext() -> CommunicationContext
}
```

#### ConnectionFactory
```swift
class ConnectionFactory {
    func createCommunicationService(
        type: String,
        configuration: Any?
    ) throws -> any CommunicationService
    
    func createDeviceDiscovery(
        type: String,
        configuration: Any?
    ) throws -> any DeviceDiscovery
    
    func createConnectionStrategy(
        type: String,
        parameters: Any?
    ) throws -> any ConnectionStrategy
}
```

## 测试

框架包含完整的测试套件：

### 运行测试
```bash
# 运行所有测试
xcodebuild test -scheme ConnectivityLayer

# 运行特定测试
xcodebuild test -scheme ConnectivityLayer -only-testing:ConnectivityLayerTests

# 运行性能测试
xcodebuild test -scheme ConnectivityLayer -only-testing:ConnectivityLayerPerformanceTests
```

### 测试覆盖
- **单元测试**: 所有核心组件和功能
- **集成测试**: 组件间交互和完整流程
- **性能测试**: 高负载和并发场景
- **内存测试**: 内存泄漏和资源管理

## 性能优化

### 连接池管理
```swift
let poolConfig = ConnectionPoolConfiguration(
    maxConnections: 10,
    minConnections: 2,
    idleTimeout: 300,
    acquisitionTimeout: 30
)
```

### 缓存策略
- 策略实例缓存，避免重复创建
- 连接信息缓存，提高查询性能
- 配置缓存，减少重复解析

### 异步处理
- 所有网络操作使用 async/await
- 并发安全的状态管理
- 非阻塞的消息处理

## 错误处理

### 错误类型
```swift
enum CommunicationError: Error {
    case notConnected
    case connectionTimeout
    case authenticationFailed
    case networkUnavailable
    case protocolNotSupported
    case messageDeliveryFailed
    case configurationInvalid
    case serviceUnavailable
    case custom(String)
}
```

### 错误恢复
- 自动重连机制
- 协议切换策略
- 降级处理方案

## 最佳实践

### 1. 策略选择
- 根据设备特性选择合适的策略
- 考虑网络环境和用户偏好
- 定期重新评估策略适用性

### 2. 连接管理
- 合理设置连接超时时间
- 及时释放不需要的连接
- 监控连接质量和性能

### 3. 消息处理
- 使用合适的 QoS 级别
- 实现消息重试机制
- 处理消息顺序和去重

### 4. 资源管理
- 避免内存泄漏
- 合理使用连接池
- 监控系统资源使用

## 故障排除

### 常见问题

1. **连接失败**
   - 检查网络连接
   - 验证配置参数
   - 查看错误日志

2. **消息发送失败**
   - 确认连接状态
   - 检查消息格式
   - 验证权限设置

3. **性能问题**
   - 检查连接池配置
   - 监控内存使用
   - 分析网络延迟

### 调试工具

```swift
// 启用调试模式
#if DEBUG
ConnectivityLayerManager.enableDebugMode()
#endif

// 获取诊断信息
let diagnostics = communicator.getDiagnosticInfo()
print("Connection diagnostics: \(diagnostics)")

// 监控连接质量
let quality = connectionInfo.quality
print("Signal strength: \(quality.signalStrength)")
print("Latency: \(quality.latency)ms")
print("Quality score: \(quality.calculateQualityScore())")
```

## 版本历史

### v1.0.0
- 初始版本发布
- 支持 MQTT、BLE、阿里云 IoT SDK
- 实现基本策略模式
- 提供连接管理功能

## 许可证

Copyright © 2024 IOTClient. All rights reserved.

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个框架。

## 联系方式

如有问题或建议，请联系开发团队。