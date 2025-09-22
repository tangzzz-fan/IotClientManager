# IOTClientManager

一个用于智能家居设备管理的iOS客户端，支持MQTT通信、BLE连接以及TCP/UDP Socket通信。

## 功能特性

- MQTT客户端通信
- BLE（低功耗蓝牙）设备连接
- TCP/UDP Socket直接通信
- 设备控制与状态管理

## 项目结构

```
IOTClient/
├── AppDelegate.swift             # 应用程序入口点
├── SceneDelegate.swift           # 场景代理
├── ViewController.swift          # 主视图控制器
├── Environment/                  # 环境配置
│   └── AppEnvironment.swift      # 应用环境配置
├── Extensions/                   # 扩展
│   └── Notification+MQTT.swift   # 通知扩展
├── Managers/                     # 管理器
│   ├── UserManager.swift         # 用户管理
│   └── RegionManager.swift       # 区域管理
├── BLE/                          # BLE相关实现
│   ├── BLEManager.swift          # BLE管理器
│   ├── BLEDevice.swift           # BLE设备模型
│   └── BLEServiceManager.swift   # BLE服务管理器
├── Socket/                       # Socket通信实现
│   └── SocketManager.swift       # Socket管理器
├── MQTT/                         # MQTT相关实现
│   ├── MQTTClientManager.swift   # MQTT客户端管理器
│   ├── Adapters/                 # 适配器
│   │   └── MQTTClientAdapter.swift
│   ├── Handlers/                 # 消息处理器
│   │   └── MessageHandlerChain.swift
│   ├── Memento/                  # 连接状态管理
│   │   └── MQTTConnectionMemento.swift
│   ├── Models/                   # 数据模型
│   │   ├── MQTTConfiguration.swift
│   │   └── MQTTConfigurationBuilder.swift
│   └── Security/                 # 安全策略
│       └── MQTTSecurityPolicyFactory.swift
└── Assets.xcassets/              # 资源文件
```

## 架构设计

详细的架构设计说明请参考 [ARCHITECTURE.md](ARCHITECTURE.md) 文档。

## 技术栈

- Swift 5+
- iOS 16.0+
- MQTTClient (CocoaPods)
- CoreBluetooth (系统框架)
- CocoaAsyncSocket (CocoaPods，用于Socket通信)

## 环境配置

项目支持四种环境配置：
- Development (开发环境)
- Staging (测试环境)
- Production (生产环境)
- Test (测试环境，使用公共MQTT Broker)

## MQTT配置

MQTT客户端已实现以下功能：
- 连接管理
- 消息订阅/发布
- 自动重连机制
- 消息处理链
- 连接状态持久化
- SSL安全策略

默认测试环境使用HiveMQ公共Broker：
- Host: broker.hivemq.com
- Port: 1883
- 协议: MQTT 3.1.1

## BLE连接

支持连接智能家居设备，如：
- 扫地机器人
- 泳池清洁机器人
- 具身机器人
- 其他支持BLE的智能设备

### BLE功能特性
- 设备扫描与发现
- 设备连接管理
- 服务和特征发现
- 数据读写
- 通知订阅
- 针对不同类型设备的专用控制命令

## Socket通信

支持TCP/UDP Socket直接通信，用于设备间的数据交换。

### TCP Socket
- 客户端连接管理
- 数据发送与接收
- 连接状态监控

### UDP Socket
- 端口绑定与数据收发
- 广播和单播通信
- 轻量级数据传输

## 安装与运行

1. 克隆项目
2. 运行 `pod install`
3. 打开 `IOTClient.xcworkspace`
4. 配置证书并运行

## 测试

### MQTT测试
使用公共MQTT Broker进行测试：
- Host: broker.hivemq.com
- Port: 1883

### BLE测试
使用支持BLE的智能家居设备进行测试。

### Socket测试
配置本地网络环境进行TCP/UDP通信测试。