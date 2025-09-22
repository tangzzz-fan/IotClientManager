# IOTClientManager 架构设计说明

## 1. 整体架构概述

IOTClientManager采用模块化设计，主要分为以下几个核心模块：

1. **MQTT通信模块** - 负责与MQTT Broker的通信
2. **BLE连接模块** - 负责蓝牙设备的发现、连接和控制
3. **Socket通信模块** - 提供TCP/UDP直接通信能力
4. **设备管理模块** - 管理用户信息和区域配置
5. **环境配置模块** - 管理不同环境的配置参数

## 2. 模块详细设计

### 2.1 MQTT通信模块

#### 核心组件
- `MQTTClientManager`: MQTT客户端核心管理器，实现单例模式
- `MQTTClientAdapter`: 适配器层，封装MQTTSessionManager的具体实现
- `MQTTConfiguration`: 配置管理，支持不同环境的配置构建
- `MessageHandlerChain`: 消息处理链，采用责任链模式处理不同类型的消息
- `MQTTConnectionMemento`: 连接状态管理，使用备忘录模式保存和恢复连接状态
- `MQTTSecurityPolicyFactory`: 安全策略工厂，创建SSL安全策略

#### 设计模式应用
- **单例模式**: MQTTClientManager采用单例模式确保全局唯一实例
- **适配器模式**: MQTTClientAdapter解耦了具体MQTT库的实现
- **责任链模式**: MessageHandlerChain处理不同类型的消息
- **备忘录模式**: MQTTConnectionMemento保存和恢复连接状态
- **建造者模式**: MQTTConfigurationBuilder用于构建复杂的配置对象

#### 功能特性
- 连接管理（连接、断开、状态检查）
- 消息订阅与发布
- 自动重连机制
- 消息处理链
- 连接状态持久化
- SSL安全策略

### 2.2 BLE连接模块

#### 核心组件
- `BLEManager`: BLE核心管理器，负责蓝牙设备的扫描、连接和数据传输
- `BLEDevice`: BLE设备模型，封装设备信息
- `BLEServiceManager`: BLE服务管理器，提供针对特定设备的控制命令

#### 设计模式应用
- **单例模式**: BLEManager采用单例模式确保全局唯一实例
- **委托模式**: 通过委托回调通知上层应用蓝牙状态变化

#### 功能特性
- 设备扫描与发现
- 设备连接管理
- 服务和特征发现
- 数据读写操作
- 通知订阅
- 针对不同类型设备的专用控制命令

### 2.3 Socket通信模块

#### 核心组件
- `SocketManager`: Socket通信管理器，提供TCP和UDP通信功能

#### 设计模式应用
- **单例模式**: SocketManager采用单例模式确保全局唯一实例
- **委托模式**: 通过委托回调通知上层应用Socket状态变化

#### 功能特性
- TCP客户端连接管理
- UDP套接字设置
- 数据发送与接收
- 连接状态监控

### 2.4 设备管理模块

#### 核心组件
- `UserManager`: 用户管理器，管理当前用户信息
- `RegionManager`: 区域管理器，管理当前区域配置

#### 设计模式应用
- **单例模式**: UserManager和RegionManager均采用单例模式

### 2.5 环境配置模块

#### 核心组件
- `AppEnvironment`: 应用环境枚举，定义不同环境配置
- `Configuration`: 配置常量，存储各环境的MQTT配置

#### 功能特性
- 支持Development、Staging、Production和Test四种环境
- 自动根据编译配置选择环境
- 灵活的MQTT配置管理

## 3. 数据流向

### 3.1 MQTT通信数据流
```
[MQTT Broker] ←→ [MQTTClientAdapter] ←→ [MQTTClientManager] ←→ [MessageHandlerChain] ←→ [应用层]
```

### 3.2 BLE通信数据流
```
[BLE设备] ←→ [BLEManager] ←→ [BLEServiceManager] ←→ [应用层]
```

### 3.3 Socket通信数据流
```
[Socket服务器] ←→ [SocketManager] ←→ [应用层]
```

## 4. 项目目录结构

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

## 5. 设计原则

### 5.1 高内聚低耦合
各模块职责明确，通过协议和委托进行交互，降低模块间的耦合度。

### 5.2 可扩展性
采用设计模式和协议抽象，便于后续功能扩展和维护。

### 5.3 可测试性
核心功能通过协议抽象，便于编写单元测试和模拟测试。

### 5.4 安全性
MQTT通信支持SSL加密，保护数据传输安全。

## 6. 依赖关系

- **MQTTClient**: MQTT通信库
- **CoreBluetooth**: 系统蓝牙框架
- **CocoaAsyncSocket**: Socket通信库

## 7. 环境配置

项目支持四种环境配置：
- Development: 开发环境
- Staging: 测试环境
- Production: 生产环境
- Test: 使用公共MQTT Broker的测试环境

## 8. 测试配置

- MQTT测试使用HiveMQ公共Broker: broker.hivemq.com:1883
- BLE测试需要真实支持BLE的设备
- Socket测试需要配置本地网络环境