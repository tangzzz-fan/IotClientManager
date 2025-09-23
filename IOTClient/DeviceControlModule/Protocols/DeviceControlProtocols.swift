//
//  DeviceControlProtocols.swift
//  DeviceControlModule
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

// MARK: - Device Control Core Protocols

/// 设备控制器协议
public protocol DeviceControllerProtocol: AnyObject {
    /// 设备标识符
    var deviceId: String { get }
    
    /// 设备类型
    var deviceType: DeviceType { get }
    
    /// 连接状态
    var connectionState: DeviceConnectionState { get }
    
    /// 控制状态
    var controlState: DeviceControlState { get }
    
    /// 设备属性
    var deviceProperties: [String: Any] { get }
    
    /// 支持的命令类型
    var supportedCommands: [DeviceCommandType] { get }
    
    /// 连接状态发布者
    var connectionStatePublisher: AnyPublisher<DeviceConnectionState, Never> { get }
    
    /// 控制状态发布者
    var controlStatePublisher: AnyPublisher<DeviceControlState, Never> { get }
    
    /// 设备属性更新发布者
    var propertyUpdatePublisher: AnyPublisher<DevicePropertyUpdate, Never> { get }
    
    /// 连接到设备
    func connect() -> AnyPublisher<Void, DeviceControlError>
    
    /// 断开设备连接
    func disconnect() -> AnyPublisher<Void, DeviceControlError>
    
    /// 执行命令
    func executeCommand(_ command: DeviceCommand) -> AnyPublisher<DeviceCommandResult, DeviceControlError>
    
    /// 批量执行命令
    func executeCommands(_ commands: [DeviceCommand]) -> AnyPublisher<[DeviceCommandResult], DeviceControlError>
    
    /// 获取设备状态
    func getDeviceStatus() -> AnyPublisher<DeviceStatus, DeviceControlError>
    
    /// 更新设备属性
    func updateProperty(key: String, value: Any) -> AnyPublisher<Void, DeviceControlError>
    
    /// 订阅设备事件
    func subscribeToEvents() -> AnyPublisher<DeviceEvent, DeviceControlError>
    
    /// 取消事件订阅
    func unsubscribeFromEvents()
}

/// 设备命令协议
public protocol DeviceCommandProtocol {
    /// 命令标识符
    var commandId: String { get }
    
    /// 命令类型
    var commandType: DeviceCommandType { get }
    
    /// 目标设备ID
    var targetDeviceId: String { get }
    
    /// 命令参数
    var parameters: [String: Any] { get }
    
    /// 命令优先级
    var priority: CommandPriority { get }
    
    /// 超时时间
    var timeout: TimeInterval { get }
    
    /// 重试次数
    var retryCount: Int { get }
    
    /// 创建时间
    var createdAt: Date { get }
    
    /// 执行命令
    func execute() -> AnyPublisher<DeviceCommandResult, DeviceControlError>
    
    /// 取消命令
    func cancel()
    
    /// 验证命令参数
    func validateParameters() -> Bool
    
    /// 获取命令描述
    func getDescription() -> String
}

/// 命令执行器协议
public protocol CommandExecutorProtocol {
    /// 执行器标识符
    var executorId: String { get }
    
    /// 支持的命令类型
    var supportedCommandTypes: [DeviceCommandType] { get }
    
    /// 当前执行状态
    var executionState: CommandExecutionState { get }
    
    /// 执行队列
    var executionQueue: CommandQueue { get }
    
    /// 执行命令
    func execute(_ command: DeviceCommand) -> AnyPublisher<DeviceCommandResult, DeviceControlError>
    
    /// 批量执行命令
    func executeBatch(_ commands: [DeviceCommand]) -> AnyPublisher<[DeviceCommandResult], DeviceControlError>
    
    /// 取消命令执行
    func cancelCommand(_ commandId: String) -> Bool
    
    /// 取消所有命令
    func cancelAllCommands()
    
    /// 获取执行历史
    func getExecutionHistory() -> [CommandExecutionRecord]
    
    /// 清理执行历史
    func clearExecutionHistory()
}

/// 命令队列协议
public protocol CommandQueueProtocol {
    /// 队列标识符
    var queueId: String { get }
    
    /// 队列类型
    var queueType: CommandQueueType { get }
    
    /// 最大队列大小
    var maxQueueSize: Int { get }
    
    /// 当前队列大小
    var currentQueueSize: Int { get }
    
    /// 队列状态
    var queueState: CommandQueueState { get }
    
    /// 添加命令到队列
    func enqueue(_ command: DeviceCommand) -> Bool
    
    /// 从队列中取出命令
    func dequeue() -> DeviceCommand?
    
    /// 查看队列头部命令
    func peek() -> DeviceCommand?
    
    /// 移除指定命令
    func remove(_ commandId: String) -> Bool
    
    /// 清空队列
    func clear()
    
    /// 获取队列中的所有命令
    func getAllCommands() -> [DeviceCommand]
    
    /// 按优先级排序
    func sortByPriority()
    
    /// 队列状态发布者
    var queueStatePublisher: AnyPublisher<CommandQueueState, Never> { get }
}

/// 设备状态监控协议
public protocol DeviceStatusMonitorProtocol {
    /// 监控器标识符
    var monitorId: String { get }
    
    /// 监控的设备列表
    var monitoredDevices: [String] { get }
    
    /// 监控状态
    var monitoringState: MonitoringState { get }
    
    /// 监控间隔
    var monitoringInterval: TimeInterval { get set }
    
    /// 开始监控
    func startMonitoring()
    
    /// 停止监控
    func stopMonitoring()
    
    /// 添加设备到监控列表
    func addDevice(_ deviceId: String)
    
    /// 从监控列表移除设备
    func removeDevice(_ deviceId: String)
    
    /// 获取设备状态
    func getDeviceStatus(_ deviceId: String) -> DeviceStatus?
    
    /// 设备状态更新发布者
    var statusUpdatePublisher: AnyPublisher<DeviceStatusUpdate, Never> { get }
    
    /// 设备连接状态变化发布者
    var connectionChangePublisher: AnyPublisher<DeviceConnectionChange, Never> { get }
}

/// 设备事件处理器协议
public protocol DeviceEventHandlerProtocol {
    /// 处理器标识符
    var handlerId: String { get }
    
    /// 支持的事件类型
    var supportedEventTypes: [DeviceEventType] { get }
    
    /// 处理设备事件
    func handleEvent(_ event: DeviceEvent) -> AnyPublisher<Void, DeviceControlError>
    
    /// 批量处理事件
    func handleEvents(_ events: [DeviceEvent]) -> AnyPublisher<Void, DeviceControlError>
    
    /// 注册事件监听器
    func registerEventListener(_ listener: DeviceEventListener)
    
    /// 取消注册事件监听器
    func unregisterEventListener(_ listenerId: String)
    
    /// 事件处理结果发布者
    var eventHandlingResultPublisher: AnyPublisher<EventHandlingResult, Never> { get }
}

/// 设备事件监听器协议
public protocol DeviceEventListener {
    /// 监听器标识符
    var listenerId: String { get }
    
    /// 感兴趣的事件类型
    var interestedEventTypes: [DeviceEventType] { get }
    
    /// 事件回调
    func onEvent(_ event: DeviceEvent)
    
    /// 错误回调
    func onError(_ error: DeviceControlError)
}

/// 设备控制服务协议
public protocol DeviceControlServiceProtocol {
    /// 服务标识符
    var serviceId: String { get }
    
    /// 服务状态
    var serviceState: ServiceState { get }
    
    /// 管理的设备控制器
    var deviceControllers: [String: DeviceControllerProtocol] { get }
    
    /// 命令执行器
    var commandExecutor: CommandExecutorProtocol { get }
    
    /// 状态监控器
    var statusMonitor: DeviceStatusMonitorProtocol { get }
    
    /// 事件处理器
    var eventHandler: DeviceEventHandlerProtocol { get }
    
    /// 启动服务
    func startService() -> AnyPublisher<Void, DeviceControlError>
    
    /// 停止服务
    func stopService() -> AnyPublisher<Void, DeviceControlError>
    
    /// 注册设备控制器
    func registerDeviceController(_ controller: DeviceControllerProtocol)
    
    /// 取消注册设备控制器
    func unregisterDeviceController(_ deviceId: String)
    
    /// 获取设备控制器
    func getDeviceController(_ deviceId: String) -> DeviceControllerProtocol?
    
    /// 执行设备命令
    func executeDeviceCommand(_ command: DeviceCommand) -> AnyPublisher<DeviceCommandResult, DeviceControlError>
    
    /// 获取所有设备状态
    func getAllDeviceStatuses() -> AnyPublisher<[DeviceStatus], DeviceControlError>
    
    /// 服务状态发布者
    var serviceStatePublisher: AnyPublisher<ServiceState, Never> { get }
}

/// 设备控制管理器协议
public protocol DeviceControlManagerProtocol {
    /// 管理器标识符
    var managerId: String { get }
    
    /// 管理器状态
    var managerState: ManagerState { get }
    
    /// 设备控制服务
    var controlService: DeviceControlServiceProtocol { get }
    
    /// 设备发现服务
    var discoveryService: DeviceDiscoveryServiceProtocol? { get }
    
    /// 设备认证服务
    var authenticationService: DeviceAuthenticationServiceProtocol? { get }
    
    /// 初始化管理器
    func initialize() -> AnyPublisher<Void, DeviceControlError>
    
    /// 启动管理器
    func start() -> AnyPublisher<Void, DeviceControlError>
    
    /// 停止管理器
    func stop() -> AnyPublisher<Void, DeviceControlError>
    
    /// 发现设备
    func discoverDevices() -> AnyPublisher<[DiscoveredDevice], DeviceControlError>
    
    /// 连接设备
    func connectDevice(_ deviceId: String) -> AnyPublisher<Void, DeviceControlError>
    
    /// 断开设备
    func disconnectDevice(_ deviceId: String) -> AnyPublisher<Void, DeviceControlError>
    
    /// 控制设备
    func controlDevice(_ deviceId: String, command: DeviceCommand) -> AnyPublisher<DeviceCommandResult, DeviceControlError>
    
    /// 获取已连接设备列表
    func getConnectedDevices() -> [String]
    
    /// 获取设备信息
    func getDeviceInfo(_ deviceId: String) -> DeviceInfo?
    
    /// 管理器状态发布者
    var managerStatePublisher: AnyPublisher<ManagerState, Never> { get }
    
    /// 设备连接状态发布者
    var deviceConnectionPublisher: AnyPublisher<DeviceConnectionEvent, Never> { get }
}

/// 设备发现服务协议
public protocol DeviceDiscoveryServiceProtocol {
    /// 服务标识符
    var serviceId: String { get }
    
    /// 发现状态
    var discoveryState: DiscoveryState { get }
    
    /// 发现的设备
    var discoveredDevices: [DiscoveredDevice] { get }
    
    /// 开始发现
    func startDiscovery() -> AnyPublisher<Void, DeviceControlError>
    
    /// 停止发现
    func stopDiscovery() -> AnyPublisher<Void, DeviceControlError>
    
    /// 刷新设备列表
    func refreshDevices() -> AnyPublisher<[DiscoveredDevice], DeviceControlError>
    
    /// 设备发现发布者
    var deviceDiscoveryPublisher: AnyPublisher<DiscoveredDevice, Never> { get }
    
    /// 设备丢失发布者
    var deviceLostPublisher: AnyPublisher<String, Never> { get }
}

/// 设备认证服务协议
public protocol DeviceAuthenticationServiceProtocol {
    /// 服务标识符
    var serviceId: String { get }
    
    /// 认证状态
    var authenticationState: AuthenticationState { get }
    
    /// 认证设备
    func authenticateDevice(_ deviceId: String, credentials: DeviceCredentials) -> AnyPublisher<AuthenticationResult, DeviceControlError>
    
    /// 验证设备令牌
    func validateDeviceToken(_ deviceId: String, token: String) -> AnyPublisher<Bool, DeviceControlError>
    
    /// 刷新设备令牌
    func refreshDeviceToken(_ deviceId: String) -> AnyPublisher<String, DeviceControlError>
    
    /// 撤销设备认证
    func revokeDeviceAuthentication(_ deviceId: String) -> AnyPublisher<Void, DeviceControlError>
    
    /// 获取设备权限
    func getDevicePermissions(_ deviceId: String) -> AnyPublisher<[DevicePermission], DeviceControlError>
    
    /// 认证结果发布者
    var authenticationResultPublisher: AnyPublisher<AuthenticationResult, Never> { get }
}

/// 设备控制代理协议
public protocol DeviceControlDelegate: AnyObject {
    /// 设备连接成功
    func deviceDidConnect(_ deviceId: String)
    
    /// 设备连接失败
    func deviceDidFailToConnect(_ deviceId: String, error: DeviceControlError)
    
    /// 设备断开连接
    func deviceDidDisconnect(_ deviceId: String)
    
    /// 命令执行成功
    func commandDidExecute(_ command: DeviceCommand, result: DeviceCommandResult)
    
    /// 命令执行失败
    func commandDidFail(_ command: DeviceCommand, error: DeviceControlError)
    
    /// 设备状态更新
    func deviceStatusDidUpdate(_ deviceId: String, status: DeviceStatus)
    
    /// 设备属性更新
    func devicePropertyDidUpdate(_ deviceId: String, property: DevicePropertyUpdate)
    
    /// 设备事件接收
    func deviceDidReceiveEvent(_ deviceId: String, event: DeviceEvent)
    
    /// 设备错误发生
    func deviceDidEncounterError(_ deviceId: String, error: DeviceControlError)
}

/// 命令工厂协议
public protocol CommandFactoryProtocol {
    /// 创建开关命令
    func createSwitchCommand(deviceId: String, isOn: Bool) -> DeviceCommand
    
    /// 创建调光命令
    func createDimmingCommand(deviceId: String, brightness: Int) -> DeviceCommand
    
    /// 创建颜色控制命令
    func createColorCommand(deviceId: String, color: DeviceColor) -> DeviceCommand
    
    /// 创建温度控制命令
    func createTemperatureCommand(deviceId: String, temperature: Double) -> DeviceCommand
    
    /// 创建场景命令
    func createSceneCommand(deviceId: String, sceneId: String) -> DeviceCommand
    
    /// 创建定时命令
    func createTimerCommand(deviceId: String, timerConfig: TimerConfiguration) -> DeviceCommand
    
    /// 创建自定义命令
    func createCustomCommand(deviceId: String, commandType: DeviceCommandType, parameters: [String: Any]) -> DeviceCommand
    
    /// 创建批量命令
    func createBatchCommand(commands: [DeviceCommand]) -> BatchCommand
    
    /// 验证命令参数
    func validateCommandParameters(_ command: DeviceCommand) -> Bool
    
    /// 获取命令模板
    func getCommandTemplate(for commandType: DeviceCommandType) -> CommandTemplate?
}

/// 设备控制策略协议
public protocol DeviceControlStrategyProtocol {
    /// 策略标识符
    var strategyId: String { get }
    
    /// 策略类型
    var strategyType: ControlStrategyType { get }
    
    /// 适用的设备类型
    var applicableDeviceTypes: [DeviceType] { get }
    
    /// 执行控制策略
    func executeStrategy(for device: DeviceControllerProtocol, command: DeviceCommand) -> AnyPublisher<DeviceCommandResult, DeviceControlError>
    
    /// 验证策略适用性
    func isApplicable(for device: DeviceControllerProtocol) -> Bool
    
    /// 获取策略配置
    func getStrategyConfiguration() -> [String: Any]
    
    /// 更新策略配置
    func updateStrategyConfiguration(_ configuration: [String: Any])
}

/// 设备控制安全协议
public protocol DeviceControlSecurityProtocol {
    /// 验证命令权限
    func validateCommandPermission(_ command: DeviceCommand, for userId: String) -> Bool
    
    /// 验证设备访问权限
    func validateDeviceAccess(_ deviceId: String, for userId: String) -> Bool
    
    /// 加密命令数据
    func encryptCommandData(_ data: Data) -> Data?
    
    /// 解密命令数据
    func decryptCommandData(_ encryptedData: Data) -> Data?
    
    /// 生成命令签名
    func generateCommandSignature(_ command: DeviceCommand) -> String?
    
    /// 验证命令签名
    func validateCommandSignature(_ command: DeviceCommand, signature: String) -> Bool
    
    /// 记录安全事件
    func logSecurityEvent(_ event: SecurityEvent)
    
    /// 获取安全日志
    func getSecurityLogs() -> [SecurityEvent]
}

/// 设备控制分析协议
public protocol DeviceControlAnalyticsProtocol {
    /// 记录命令执行
    func trackCommandExecution(_ command: DeviceCommand, result: DeviceCommandResult, duration: TimeInterval)
    
    /// 记录设备连接事件
    func trackDeviceConnection(_ deviceId: String, connectionType: ConnectionType, success: Bool)
    
    /// 记录设备使用情况
    func trackDeviceUsage(_ deviceId: String, usageData: DeviceUsageData)
    
    /// 记录错误事件
    func trackError(_ error: DeviceControlError, context: [String: Any])
    
    /// 获取设备使用统计
    func getDeviceUsageStatistics(_ deviceId: String) -> DeviceUsageStatistics?
    
    /// 获取命令执行统计
    func getCommandExecutionStatistics() -> CommandExecutionStatistics
    
    /// 获取错误统计
    func getErrorStatistics() -> ErrorStatistics
    
    /// 生成分析报告
    func generateAnalyticsReport(for period: AnalyticsPeriod) -> AnalyticsReport
}