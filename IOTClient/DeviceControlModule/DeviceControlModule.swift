//
//  DeviceControlModule.swift
//  DeviceControlModule
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine
import UIKit

/// DeviceControlModule - 设备控制模块主入口
/// 提供统一的设备控制接口，整合所有设备控制相关功能
public class DeviceControlModule {
    
    // MARK: - Singleton
    
    public static let shared = DeviceControlModule()
    
    // MARK: - Properties
    
    private let controlService: DeviceControlServiceProtocol
    private let discoveryService: DeviceDiscoveryServiceProtocol
    private let authenticationService: DeviceAuthenticationServiceProtocol
    private let commandFactory: CommandFactoryProtocol
    private let multiDeviceController: MultiDeviceController
    private let adapterManager: DeviceAdapterManager
    
    private var isInitialized = false
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Publishers
    
    private let moduleStateSubject = CurrentValueSubject<DeviceControlModuleState, Never>(.idle)
    private let deviceStatusSubject = PassthroughSubject<DeviceStatus, Never>()
    private let deviceEventSubject = PassthroughSubject<DeviceEvent, Never>()
    private let discoveredDeviceSubject = PassthroughSubject<DiscoveredDevice, Never>()
    
    // MARK: - Initialization
    
    private init() {
        // 初始化核心服务
        self.commandFactory = DeviceCommandFactory()
        self.controlService = DeviceControlService(
            commandExecutor: DeviceCommandExecutor(),
            statusMonitor: DeviceStatusMonitor(),
            eventHandler: DeviceEventHandler(),
            commandQueue: CommandQueue(type: .priority, maxSize: 100)
        )
        self.discoveryService = DeviceDiscoveryService()
        self.authenticationService = DeviceAuthenticationService()
        self.multiDeviceController = MultiDeviceController(
            controlService: controlService,
            commandFactory: commandFactory
        )
        self.adapterManager = DeviceAdapterManager.shared
        
        setupEventHandling()
    }
    
    // MARK: - Public Interface
    
    /// 初始化设备控制模块
    public func initialize() -> AnyPublisher<Void, DeviceControlError> {
        guard !isInitialized else {
            return Just(())
                .setFailureType(to: DeviceControlError.self)
                .eraseToAnyPublisher()
        }
        
        moduleStateSubject.send(.initializing)
        
        return Publishers.Zip4(
            initializeControlService(),
            initializeDiscoveryService(),
            initializeAuthenticationService(),
            adapterManager.initialize()
        )
        .map { _, _, _, _ in () }
        .handleEvents(
            receiveOutput: { [weak self] _ in
                self?.isInitialized = true
                self?.moduleStateSubject.send(.ready)
                DeviceControlLogger.log("DeviceControlModule initialized successfully", level: .info)
            },
            receiveCompletion: { [weak self] completion in
                if case .failure = completion {
                    self?.moduleStateSubject.send(.error)
                    DeviceControlLogger.log("DeviceControlModule initialization failed", level: .error)
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    /// 关闭设备控制模块
    public func shutdown() {
        guard isInitialized else { return }
        
        moduleStateSubject.send(.shuttingDown)
        
        // 停止所有服务
        controlService.stopService()
        discoveryService.stopDiscovery()
        multiDeviceController.stopMonitoringAllDevices()
        adapterManager.shutdown()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // 清理资源
        cancellables.removeAll()
        isInitialized = false
        
        moduleStateSubject.send(.idle)
        DeviceControlLogger.log("DeviceControlModule shutdown completed", level: .info)
    }
    
    // MARK: - Device Management
    
    /// 添加设备
    public func addDevice(_ deviceInfo: DeviceInfo, preferredAdapterType: DeviceAdapterType? = nil) -> AnyPublisher<BaseDeviceController, DeviceControlError> {
        guard isInitialized else {
            return Fail(error: DeviceControlError.serviceUnavailable("Module not initialized"))
                .eraseToAnyPublisher()
        }
        
        return adapterManager.connectToDevice(deviceInfo, preferredAdapterType: preferredAdapterType)
            .flatMap { [weak self] connectionState -> AnyPublisher<BaseDeviceController, DeviceControlError> in
                guard let self = self, connectionState == .connected else {
                    return Fail(error: DeviceControlError.connectionFailed("Failed to connect to device"))
                        .eraseToAnyPublisher()
                }
                
                return self.authenticateDevice(deviceInfo)
                    .flatMap { _ -> AnyPublisher<BaseDeviceController, DeviceControlError> in
                        guard let controller = self.multiDeviceController.createDeviceController(for: deviceInfo) else {
                            return Fail(error: DeviceControlError.deviceNotSupported("Unsupported device type: \(deviceInfo.deviceType)"))
                                .eraseToAnyPublisher()
                        }
                        
                        self.multiDeviceController.addDeviceController(controller)
                        controller.startMonitoring()
                        
                        DeviceControlLogger.log("Device added successfully", level: .info, deviceId: deviceInfo.deviceId)
                        
                        return Just(controller)
                            .setFailureType(to: DeviceControlError.self)
                            .eraseToAnyPublisher()
                    }
            }
            .eraseToAnyPublisher()
    }
    
    /// 移除设备
    public func removeDevice(_ deviceId: String) -> AnyPublisher<Void, DeviceControlError> {
        guard isInitialized else {
            return Fail(error: DeviceControlError.serviceUnavailable("Module not initialized"))
                .eraseToAnyPublisher()
        }
        
        guard let controller = multiDeviceController.getDeviceController(deviceId: deviceId) else {
            return Fail(error: DeviceControlError.deviceNotFound("Device not found: \(deviceId)"))
                .eraseToAnyPublisher()
        }
        
        return adapterManager.disconnectFromDevice(deviceId)
            .flatMap { [weak self] _ -> AnyPublisher<Void, DeviceControlError> in
                guard let self = self else {
                    return Fail(error: DeviceControlError.unknown("Module deallocated"))
                        .eraseToAnyPublisher()
                }
                
                controller.stopMonitoring()
                self.multiDeviceController.removeDeviceController(deviceId: deviceId)
                
                DeviceControlLogger.log("Device removed successfully", level: .info, deviceId: deviceId)
                
                return Just(())
                    .setFailureType(to: DeviceControlError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    /// 获取设备控制器
    public func getDeviceController<T: BaseDeviceController>(deviceId: String, type: T.Type) -> T? {
        return multiDeviceController.getDeviceController(deviceId: deviceId, type: type)
    }
    
    /// 获取所有设备控制器
    public func getAllDeviceControllers() -> [String: BaseDeviceController] {
        return multiDeviceController.getAllControlStates().compactMapValues { _ in
            return multiDeviceController.getDeviceController(deviceId: "")
        }
    }
    
    // MARK: - Device Control
    
    /// 执行设备命令
    public func executeCommand(_ command: DeviceCommandProtocol) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        guard isInitialized else {
            return Fail(error: DeviceControlError.serviceUnavailable("Module not initialized"))
                .eraseToAnyPublisher()
        }
        
        DeviceControlLogger.log("Executing command: \(command.commandType.displayName)", level: .info, deviceId: command.targetDeviceId, commandId: command.commandId)
        
        return adapterManager.executeCommand(command)
            .handleEvents(
                receiveOutput: { result in
                    DeviceControlLogger.logCommandExecution(command, result: result)
                }
            )
            .eraseToAnyPublisher()
    }
    
    /// 批量执行命令
    public func executeBatchCommands(_ commands: [DeviceCommandProtocol]) -> AnyPublisher<[DeviceCommandResult], DeviceControlError> {
        guard isInitialized else {
            return Fail(error: DeviceControlError.serviceUnavailable("Module not initialized"))
                .eraseToAnyPublisher()
        }
        
        DeviceControlLogger.log("Executing batch commands: \(commands.count) commands", level: .info)
        
        return adapterManager.executeBatchCommands(commands)
            .handleEvents(
                receiveOutput: { results in
                    let stats = DeviceControlUtils.calculateExecutionStats(for: results)
                    DeviceControlLogger.log("Batch execution completed: \(stats.totalCommands) commands, \(String(format: "%.1f", stats.successRate * 100))% success rate", level: .info)
                }
            )
            .eraseToAnyPublisher()
    }
    
    /// 获取设备状态
    public func getDeviceStatus(_ deviceId: String) -> AnyPublisher<DeviceStatus, DeviceControlError> {
        guard isInitialized else {
            return Fail(error: DeviceControlError.serviceUnavailable("Module not initialized"))
                .eraseToAnyPublisher()
        }
        
        return adapterManager.getDeviceStatus(deviceId)
    }
    
    /// 同步所有设备状态
    public func syncAllDeviceStates() -> AnyPublisher<[DeviceStatus], DeviceControlError> {
        guard isInitialized else {
            return Fail(error: DeviceControlError.serviceUnavailable("Module not initialized"))
                .eraseToAnyPublisher()
        }
        
        return multiDeviceController.syncAllDeviceStates()
    }
    
    // MARK: - Device Discovery
    
    /// 开始设备发现
    public func startDeviceDiscovery(using adapterTypes: [DeviceAdapterType]? = nil) -> AnyPublisher<Void, DeviceControlError> {
        guard isInitialized else {
            return Fail(error: DeviceControlError.serviceUnavailable("Module not initialized"))
                .eraseToAnyPublisher()
        }
        
        discoveryService.startDiscovery()
        DeviceControlLogger.log("Device discovery started", level: .info)
        
        return adapterManager.discoverDevices(using: adapterTypes)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    /// 停止设备发现
    public func stopDeviceDiscovery(for adapterTypes: [DeviceAdapterType]? = nil) {
        discoveryService.stopDiscovery()
        adapterManager.stopDiscovery(for: adapterTypes)
        DeviceControlLogger.log("Device discovery stopped", level: .info)
    }
    
    /// 获取已发现的设备
    public func getDiscoveredDevices() -> [DiscoveredDevice] {
        return discoveryService.getDiscoveredDevices()
    }
    
    // MARK: - Convenience Methods
    
    /// 快速开关设备
    public func switchDevice(_ deviceId: String, isOn: Bool) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let command = commandFactory.createSwitchCommand(deviceId: deviceId, isOn: isOn)
        return executeCommand(command)
    }
    
    /// 快速设置灯光亮度
    public func setLightBrightness(_ deviceId: String, brightness: Int) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let command = commandFactory.createDimmingCommand(deviceId: deviceId, brightness: brightness)
        return executeCommand(command)
    }
    
    /// 快速设置灯光颜色
    public func setLightColor(_ deviceId: String, color: DeviceColor) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let command = commandFactory.createColorCommand(deviceId: deviceId, color: color)
        return executeCommand(command)
    }
    
    /// 快速设置温度
    public func setTemperature(_ deviceId: String, temperature: Double) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let command = commandFactory.createTemperatureCommand(deviceId: deviceId, temperature: temperature)
        return executeCommand(command)
    }
    
    /// 快速设置场景
    public func setScene(_ deviceId: String, sceneId: String) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let command = commandFactory.createSceneCommand(deviceId: deviceId, sceneId: sceneId)
        return executeCommand(command)
    }
    
    // MARK: - Publishers
    
    /// 模块状态发布者
    public var moduleStatePublisher: AnyPublisher<DeviceControlModuleState, Never> {
        return moduleStateSubject.eraseToAnyPublisher()
    }
    
    /// 设备状态更新发布者
    public var deviceStatusPublisher: AnyPublisher<DeviceStatus, Never> {
        return deviceStatusSubject.eraseToAnyPublisher()
    }
    
    /// 设备事件发布者
    public var deviceEventPublisher: AnyPublisher<DeviceEvent, Never> {
        return deviceEventSubject.eraseToAnyPublisher()
    }
    
    /// 发现设备发布者
    public var discoveredDevicePublisher: AnyPublisher<DiscoveredDevice, Never> {
        return discoveredDeviceSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func setupEventHandling() {
        // 监听设备发现事件
        discoveryService.getDiscoveredDevicesPublisher()
            .compactMap { $0.last }
            .sink { [weak self] device in
                self?.discoveredDeviceSubject.send(device)
            }
            .store(in: &cancellables)
    }
    
    private func initializeControlService() -> AnyPublisher<Void, DeviceControlError> {
        controlService.startService()
        return Just(())
            .setFailureType(to: DeviceControlError.self)
            .eraseToAnyPublisher()
    }
    
    private func initializeDiscoveryService() -> AnyPublisher<Void, DeviceControlError> {
        // 发现服务初始化逻辑
        return Just(())
            .setFailureType(to: DeviceControlError.self)
            .eraseToAnyPublisher()
    }
    
    private func initializeAuthenticationService() -> AnyPublisher<Void, DeviceControlError> {
        // 认证服务初始化逻辑
        return Just(())
            .setFailureType(to: DeviceControlError.self)
            .eraseToAnyPublisher()
    }
    
    private func authenticateDevice(_ deviceInfo: DeviceInfo) -> AnyPublisher<AuthenticationResult, DeviceControlError> {
        // 简化的认证逻辑，实际应用中需要根据设备类型进行不同的认证
        let credentials = DeviceCredentials(
            deviceId: deviceInfo.deviceId,
            credentialType: .none,
            credentialData: [:]
        )
        
        return authenticationService.authenticateDevice(
            deviceId: deviceInfo.deviceId,
            credentials: credentials
        )
    }
}

// MARK: - Module State

/// 设备控制模块状态
public enum DeviceControlModuleState {
    case idle
    case initializing
    case ready
    case shuttingDown
    case error
    
    public var displayName: String {
        switch self {
        case .idle:
            return "空闲"
        case .initializing:
            return "初始化中"
        case .ready:
            return "就绪"
        case .shuttingDown:
            return "关闭中"
        case .error:
            return "错误"
        }
    }
}

// MARK: - Module Extensions

extension DeviceControlModule {
    /// 获取模块统计信息
    public func getModuleStatistics() -> DeviceControlModuleStatistics {
        let allStates = multiDeviceController.getAllControlStates()
        let connectedDevices = allStates.filter { $0.value == .idle || $0.value == .busy }.count
        let busyDevices = allStates.filter { $0.value == .busy }.count
        let errorDevices = allStates.filter { $0.value == .error }.count
        
        return DeviceControlModuleStatistics(
            totalDevices: allStates.count,
            connectedDevices: connectedDevices,
            busyDevices: busyDevices,
            errorDevices: errorDevices,
            moduleState: moduleStateSubject.value
        )
    }
    
    /// 执行模块健康检查
    public func performHealthCheck() -> AnyPublisher<DeviceControlModuleHealthStatus, DeviceControlError> {
        guard isInitialized else {
            return Just(DeviceControlModuleHealthStatus(
                isHealthy: false,
                issues: ["Module not initialized"],
                timestamp: Date()
            ))
            .setFailureType(to: DeviceControlError.self)
            .eraseToAnyPublisher()
        }
        
        return syncAllDeviceStates()
            .map { deviceStatuses in
                let issues = deviceStatuses.compactMap { status -> String? in
                    switch status.connectionState {
                    case .disconnected, .error:
                        return "Device \(status.deviceId) is not connected"
                    default:
                        return nil
                    }
                }
                
                return DeviceControlModuleHealthStatus(
                    isHealthy: issues.isEmpty,
                    issues: issues,
                    timestamp: Date()
                )
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Supporting Types

/// 模块统计信息
public struct DeviceControlModuleStatistics {
    public let totalDevices: Int
    public let connectedDevices: Int
    public let busyDevices: Int
    public let errorDevices: Int
    public let moduleState: DeviceControlModuleState
}

/// 模块健康状态
public struct DeviceControlModuleHealthStatus {
    public let isHealthy: Bool
    public let issues: [String]
    public let timestamp: Date
}

// MARK: - Error Extensions

extension DeviceControlError {
    static func deviceNotSupported(_ message: String) -> DeviceControlError {
        return .commandNotSupported(message)
    }
}