//
//  DeviceControlServices.swift
//  DeviceControlModule
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

// MARK: - Command Executor Implementation

/// 命令执行器实现
public class DeviceCommandExecutor: CommandExecutorProtocol {
    public var state: CommandExecutionState = .idle
    public let executionQueue: DispatchQueue
    
    private var cancellables = Set<AnyCancellable>()
    private let stateSubject = CurrentValueSubject<CommandExecutionState, Never>(.idle)
    private let resultSubject = PassthroughSubject<DeviceCommandResult, Never>()
    
    public init(executionQueue: DispatchQueue = DispatchQueue(label: "com.iotclient.command.executor", qos: .userInitiated)) {
        self.executionQueue = executionQueue
        setupStateBinding()
    }
    
    private func setupStateBinding() {
        stateSubject
            .sink { [weak self] newState in
                self?.state = newState
            }
            .store(in: &cancellables)
    }
    
    public func execute(_ command: DeviceCommandProtocol) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        guard state != .executing else {
            return Fail(error: DeviceControlError.executorBusy("Command executor is currently busy"))
                .eraseToAnyPublisher()
        }
        
        stateSubject.send(.executing)
        
        return command.execute()
            .receive(on: executionQueue)
            .handleEvents(
                receiveOutput: { [weak self] result in
                    self?.resultSubject.send(result)
                },
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        self?.stateSubject.send(.idle)
                    case .failure:
                        self?.stateSubject.send(.error)
                    }
                }
            )
            .eraseToAnyPublisher()
    }
    
    public func executeAsync(_ command: DeviceCommandProtocol, completion: @escaping (Result<DeviceCommandResult, DeviceControlError>) -> Void) {
        execute(command)
            .sink(
                receiveCompletion: { completionResult in
                    if case .failure(let error) = completionResult {
                        completion(.failure(error))
                    }
                },
                receiveValue: { result in
                    completion(.success(result))
                }
            )
            .store(in: &cancellables)
    }
    
    public func cancel() {
        stateSubject.send(.cancelled)
        cancellables.removeAll()
    }
    
    public func getExecutionHistory() -> [CommandExecutionRecord] {
        // 实际实现中应该维护执行历史记录
        return []
    }
    
    public func getStatePublisher() -> AnyPublisher<CommandExecutionState, Never> {
        return stateSubject.eraseToAnyPublisher()
    }
    
    public func getResultPublisher() -> AnyPublisher<DeviceCommandResult, Never> {
        return resultSubject.eraseToAnyPublisher()
    }
}

// MARK: - Device Status Monitor Implementation

/// 设备状态监控器实现
public class DeviceStatusMonitor: DeviceStatusMonitorProtocol {
    public var monitoringState: MonitoringState = .stopped
    public let monitoringInterval: TimeInterval
    
    private var cancellables = Set<AnyCancellable>()
    private let stateSubject = CurrentValueSubject<MonitoringState, Never>(.stopped)
    private let statusSubject = PassthroughSubject<DeviceStatus, Never>()
    private let eventSubject = PassthroughSubject<DeviceEvent, Never>()
    
    private var monitoringTimer: Timer?
    private var monitoredDevices: Set<String> = []
    
    public init(monitoringInterval: TimeInterval = 5.0) {
        self.monitoringInterval = monitoringInterval
        setupStateBinding()
    }
    
    private func setupStateBinding() {
        stateSubject
            .sink { [weak self] newState in
                self?.monitoringState = newState
            }
            .store(in: &cancellables)
    }
    
    public func startMonitoring(deviceId: String) {
        monitoredDevices.insert(deviceId)
        
        if monitoringState == .stopped {
            stateSubject.send(.monitoring)
            startMonitoringTimer()
        }
    }
    
    public func stopMonitoring(deviceId: String) {
        monitoredDevices.remove(deviceId)
        
        if monitoredDevices.isEmpty {
            stateSubject.send(.stopped)
            stopMonitoringTimer()
        }
    }
    
    public func stopAllMonitoring() {
        monitoredDevices.removeAll()
        stateSubject.send(.stopped)
        stopMonitoringTimer()
    }
    
    public func getCurrentStatus(deviceId: String) -> AnyPublisher<DeviceStatus, DeviceControlError> {
        return Future { promise in
            // 模拟获取设备状态
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                let status = DeviceStatus(
                    deviceId: deviceId,
                    connectionState: .connected,
                    controlState: .idle,
                    batteryLevel: Int.random(in: 20...100),
                    signalStrength: Int.random(in: 50...100),
                    lastUpdateTime: Date(),
                    properties: [
                        "temperature": Double.random(in: 18...25),
                        "humidity": Double.random(in: 40...60)
                    ]
                )
                promise(.success(status))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func getStatusHistory(deviceId: String, timeRange: TimeInterval) -> [DeviceStatus] {
        // 实际实现中应该从数据库或缓存中获取历史状态
        return []
    }
    
    public func getStatusPublisher() -> AnyPublisher<DeviceStatus, Never> {
        return statusSubject.eraseToAnyPublisher()
    }
    
    public func getEventPublisher() -> AnyPublisher<DeviceEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }
    
    private func startMonitoringTimer() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            self?.performMonitoringCheck()
        }
    }
    
    private func stopMonitoringTimer() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    private func performMonitoringCheck() {
        for deviceId in monitoredDevices {
            getCurrentStatus(deviceId: deviceId)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            let event = DeviceEvent(
                                eventId: UUID().uuidString,
                                deviceId: deviceId,
                                eventType: .error,
                                timestamp: Date(),
                                data: ["error": error.localizedDescription],
                                severity: .high
                            )
                            self.eventSubject.send(event)
                        }
                    },
                    receiveValue: { [weak self] status in
                        self?.statusSubject.send(status)
                        
                        // 检查状态变化并生成事件
                        self?.checkForStatusEvents(status)
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    private func checkForStatusEvents(_ status: DeviceStatus) {
        // 检查电池电量低
        if let batteryLevel = status.batteryLevel, batteryLevel < 20 {
            let event = DeviceEvent(
                eventId: UUID().uuidString,
                deviceId: status.deviceId,
                eventType: .batteryLow,
                timestamp: Date(),
                data: ["batteryLevel": batteryLevel],
                severity: .medium
            )
            eventSubject.send(event)
        }
        
        // 检查信号强度低
        if let signalStrength = status.signalStrength, signalStrength < 30 {
            let event = DeviceEvent(
                eventId: UUID().uuidString,
                deviceId: status.deviceId,
                eventType: .signalWeak,
                timestamp: Date(),
                data: ["signalStrength": signalStrength],
                severity: .low
            )
            eventSubject.send(event)
        }
        
        // 检查连接状态
        if status.connectionState == .disconnected {
            let event = DeviceEvent(
                eventId: UUID().uuidString,
                deviceId: status.deviceId,
                eventType: .disconnected,
                timestamp: Date(),
                data: [:],
                severity: .high
            )
            eventSubject.send(event)
        }
    }
    
    deinit {
        stopAllMonitoring()
    }
}

// MARK: - Device Event Handler Implementation

/// 设备事件处理器实现
public class DeviceEventHandler: DeviceEventHandlerProtocol {
    private var eventListeners: [String: DeviceEventListener] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let eventQueue = DispatchQueue(label: "com.iotclient.event.handler", qos: .userInitiated)
    
    public init() {}
    
    public func handleEvent(_ event: DeviceEvent) {
        eventQueue.async { [weak self] in
            self?.processEvent(event)
        }
    }
    
    public func registerEventListener(_ listener: DeviceEventListener, for eventType: DeviceEventType) {
        let key = "\(eventType.rawValue)_\(UUID().uuidString)"
        eventListeners[key] = listener
    }
    
    public func unregisterEventListener(for eventType: DeviceEventType) {
        let keysToRemove = eventListeners.keys.filter { $0.hasPrefix(eventType.rawValue) }
        keysToRemove.forEach { eventListeners.removeValue(forKey: $0) }
    }
    
    public func getEventHistory(deviceId: String, eventType: DeviceEventType?, timeRange: TimeInterval) -> [DeviceEvent] {
        // 实际实现中应该从数据库中获取事件历史
        return []
    }
    
    private func processEvent(_ event: DeviceEvent) {
        // 通知相关的事件监听器
        let relevantListeners = eventListeners.values.filter { listener in
            // 这里可以添加更复杂的匹配逻辑
            return true
        }
        
        for listener in relevantListeners {
            listener.onEventReceived(event)
        }
        
        // 根据事件严重程度进行不同处理
        switch event.severity {
        case .critical:
            handleCriticalEvent(event)
        case .high:
            handleHighSeverityEvent(event)
        case .medium:
            handleMediumSeverityEvent(event)
        case .low:
            handleLowSeverityEvent(event)
        }
    }
    
    private func handleCriticalEvent(_ event: DeviceEvent) {
        // 处理关键事件，可能需要立即通知用户或采取紧急措施
        print("Critical event detected: \(event.eventType) for device \(event.deviceId)")
    }
    
    private func handleHighSeverityEvent(_ event: DeviceEvent) {
        // 处理高严重性事件
        print("High severity event: \(event.eventType) for device \(event.deviceId)")
    }
    
    private func handleMediumSeverityEvent(_ event: DeviceEvent) {
        // 处理中等严重性事件
        print("Medium severity event: \(event.eventType) for device \(event.deviceId)")
    }
    
    private func handleLowSeverityEvent(_ event: DeviceEvent) {
        // 处理低严重性事件
        print("Low severity event: \(event.eventType) for device \(event.deviceId)")
    }
}

// MARK: - Device Control Service Implementation

/// 设备控制服务实现
public class DeviceControlService: DeviceControlServiceProtocol {
    public var serviceState: ServiceState = .stopped
    
    private let commandExecutor: CommandExecutorProtocol
    private let statusMonitor: DeviceStatusMonitorProtocol
    private let eventHandler: DeviceEventHandlerProtocol
    private let commandQueue: CommandQueueProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private let stateSubject = CurrentValueSubject<ServiceState, Never>(.stopped)
    
    public init(
        commandExecutor: CommandExecutorProtocol = DeviceCommandExecutor(),
        statusMonitor: DeviceStatusMonitorProtocol = DeviceStatusMonitor(),
        eventHandler: DeviceEventHandlerProtocol = DeviceEventHandler(),
        commandQueue: CommandQueueProtocol = CommandQueue(type: .priority)
    ) {
        self.commandExecutor = commandExecutor
        self.statusMonitor = statusMonitor
        self.eventHandler = eventHandler
        self.commandQueue = commandQueue
        
        setupStateBinding()
        setupEventHandling()
    }
    
    private func setupStateBinding() {
        stateSubject
            .sink { [weak self] newState in
                self?.serviceState = newState
            }
            .store(in: &cancellables)
    }
    
    private func setupEventHandling() {
        // 监听状态变化事件
        statusMonitor.getEventPublisher()
            .sink { [weak self] event in
                self?.eventHandler.handleEvent(event)
            }
            .store(in: &cancellables)
    }
    
    public func startService() {
        guard serviceState == .stopped else { return }
        
        stateSubject.send(.starting)
        
        // 启动各个组件
        DispatchQueue.global().async { [weak self] in
            // 模拟启动过程
            Thread.sleep(forTimeInterval: 0.5)
            
            DispatchQueue.main.async {
                self?.stateSubject.send(.running)
            }
        }
    }
    
    public func stopService() {
        guard serviceState == .running else { return }
        
        stateSubject.send(.stopping)
        
        // 停止监控
        statusMonitor.stopAllMonitoring()
        
        // 取消执行器
        commandExecutor.cancel()
        
        // 清空命令队列
        commandQueue.clear()
        
        stateSubject.send(.stopped)
    }
    
    public func executeCommand(_ command: DeviceCommandProtocol) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        guard serviceState == .running else {
            return Fail(error: DeviceControlError.serviceNotRunning("Device control service is not running"))
                .eraseToAnyPublisher()
        }
        
        return commandExecutor.execute(command)
    }
    
    public func queueCommand(_ command: DeviceCommandProtocol) {
        commandQueue.enqueue(command)
        processCommandQueue()
    }
    
    public func getDeviceStatus(_ deviceId: String) -> AnyPublisher<DeviceStatus, DeviceControlError> {
        return statusMonitor.getCurrentStatus(deviceId: deviceId)
    }
    
    public func startMonitoring(_ deviceId: String) {
        statusMonitor.startMonitoring(deviceId: deviceId)
    }
    
    public func stopMonitoring(_ deviceId: String) {
        statusMonitor.stopMonitoring(deviceId: deviceId)
    }
    
    public func registerEventListener(_ listener: DeviceEventListener, for eventType: DeviceEventType) {
        eventHandler.registerEventListener(listener, for: eventType)
    }
    
    public func getServiceStatePublisher() -> AnyPublisher<ServiceState, Never> {
        return stateSubject.eraseToAnyPublisher()
    }
    
    private func processCommandQueue() {
        guard commandExecutor.state == .idle else { return }
        
        if let nextCommand = commandQueue.dequeue() {
            executeCommand(nextCommand)
                .sink(
                    receiveCompletion: { [weak self] _ in
                        // 处理完成后继续处理队列中的下一个命令
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self?.processCommandQueue()
                        }
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }
    }
}

// MARK: - Device Discovery Service Implementation

/// 设备发现服务实现
public class DeviceDiscoveryService: DeviceDiscoveryServiceProtocol {
    public var discoveryState: DiscoveryState = .stopped
    
    private var cancellables = Set<AnyCancellable>()
    private let stateSubject = CurrentValueSubject<DiscoveryState, Never>(.stopped)
    private let deviceSubject = PassthroughSubject<DiscoveredDevice, Never>()
    
    private var discoveryTimer: Timer?
    private var discoveredDevices: [String: DiscoveredDevice] = [:]
    
    public init() {
        setupStateBinding()
    }
    
    private func setupStateBinding() {
        stateSubject
            .sink { [weak self] newState in
                self?.discoveryState = newState
            }
            .store(in: &cancellables)
    }
    
    public func startDiscovery() {
        guard discoveryState == .stopped else { return }
        
        stateSubject.send(.discovering)
        startDiscoveryProcess()
    }
    
    public func stopDiscovery() {
        guard discoveryState == .discovering else { return }
        
        stateSubject.send(.stopped)
        stopDiscoveryProcess()
    }
    
    public func getDiscoveredDevices() -> [DiscoveredDevice] {
        return Array(discoveredDevices.values)
    }
    
    public func getDevicePublisher() -> AnyPublisher<DiscoveredDevice, Never> {
        return deviceSubject.eraseToAnyPublisher()
    }
    
    public func refreshDiscovery() {
        if discoveryState == .discovering {
            stopDiscovery()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.startDiscovery()
            }
        }
    }
    
    private func startDiscoveryProcess() {
        // 模拟设备发现过程
        discoveryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.simulateDeviceDiscovery()
        }
    }
    
    private func stopDiscoveryProcess() {
        discoveryTimer?.invalidate()
        discoveryTimer = nil
    }
    
    private func simulateDeviceDiscovery() {
        // 模拟发现新设备
        let deviceTypes: [DeviceType] = [.light, .switch, .sensor, .thermostat, .camera]
        let randomType = deviceTypes.randomElement() ?? .light
        
        let device = DiscoveredDevice(
            deviceId: UUID().uuidString,
            name: "\(randomType.displayName) \(Int.random(in: 1...100))",
            deviceType: randomType,
            connectionType: .wifi,
            signalStrength: Int.random(in: 30...100),
            discoveredAt: Date(),
            isConnectable: true,
            metadata: [
                "manufacturer": "IOTClient",
                "model": "\(randomType.rawValue.uppercased())-001",
                "version": "1.0.0"
            ]
        )
        
        // 避免重复添加相同设备
        if discoveredDevices[device.deviceId] == nil {
            discoveredDevices[device.deviceId] = device
            deviceSubject.send(device)
        }
    }
    
    deinit {
        stopDiscovery()
    }
}

// MARK: - Device Authentication Service Implementation

/// 设备认证服务实现
public class DeviceAuthenticationService: DeviceAuthenticationServiceProtocol {
    public var authenticationState: AuthenticationState = .idle
    
    private var cancellables = Set<AnyCancellable>()
    private let stateSubject = CurrentValueSubject<AuthenticationState, Never>(.idle)
    private var authenticatedDevices: [String: AuthenticationResult] = [:]
    
    public init() {
        setupStateBinding()
    }
    
    private func setupStateBinding() {
        stateSubject
            .sink { [weak self] newState in
                self?.authenticationState = newState
            }
            .store(in: &cancellables)
    }
    
    public func authenticate(deviceId: String, credentials: DeviceCredentials) -> AnyPublisher<AuthenticationResult, DeviceControlError> {
        stateSubject.send(.authenticating)
        
        return Future { [weak self] promise in
            // 模拟认证过程
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                let success = self?.validateCredentials(credentials) ?? false
                
                if success {
                    let result = AuthenticationResult(
                        deviceId: deviceId,
                        success: true,
                        token: "auth_token_\(UUID().uuidString)",
                        expiresAt: Date().addingTimeInterval(3600), // 1小时后过期
                        permissions: [.read, .write, .control],
                        permissionLevel: .full
                    )
                    
                    self?.authenticatedDevices[deviceId] = result
                    self?.stateSubject.send(.authenticated)
                    promise(.success(result))
                } else {
                    self?.stateSubject.send(.failed)
                    promise(.failure(DeviceControlError.authenticationFailed("Invalid credentials")))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func validateToken(deviceId: String, token: String) -> Bool {
        guard let authResult = authenticatedDevices[deviceId] else {
            return false
        }
        
        return authResult.token == token && authResult.expiresAt > Date()
    }
    
    public func refreshToken(deviceId: String) -> AnyPublisher<String, DeviceControlError> {
        guard let authResult = authenticatedDevices[deviceId] else {
            return Fail(error: DeviceControlError.authenticationFailed("Device not authenticated"))
                .eraseToAnyPublisher()
        }
        
        return Future { [weak self] promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                let newToken = "refresh_token_\(UUID().uuidString)"
                let newExpiresAt = Date().addingTimeInterval(3600)
                
                var updatedResult = authResult
                updatedResult.token = newToken
                updatedResult.expiresAt = newExpiresAt
                
                self?.authenticatedDevices[deviceId] = updatedResult
                promise(.success(newToken))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func revokeAuthentication(deviceId: String) {
        authenticatedDevices.removeValue(forKey: deviceId)
        stateSubject.send(.idle)
    }
    
    public func getAuthenticationResult(deviceId: String) -> AuthenticationResult? {
        return authenticatedDevices[deviceId]
    }
    
    public func isDeviceAuthenticated(deviceId: String) -> Bool {
        guard let authResult = authenticatedDevices[deviceId] else {
            return false
        }
        return authResult.success && authResult.expiresAt > Date()
    }
    
    private func validateCredentials(_ credentials: DeviceCredentials) -> Bool {
        // 模拟凭据验证逻辑
        switch credentials.type {
        case .password:
            return !credentials.value.isEmpty && credentials.value.count >= 6
        case .token:
            return !credentials.value.isEmpty && credentials.value.hasPrefix("token_")
        case .certificate:
            return !credentials.value.isEmpty && credentials.value.contains("-----BEGIN CERTIFICATE-----")
        case .biometric:
            return !credentials.value.isEmpty
        }
    }
}

// MARK: - Device Control Manager Implementation

/// 设备控制管理器实现
public class DeviceControlManager: DeviceControlManagerProtocol {
    public var managerState: ManagerState = .stopped
    
    private let controlService: DeviceControlServiceProtocol
    private let discoveryService: DeviceDiscoveryServiceProtocol
    private let authenticationService: DeviceAuthenticationServiceProtocol
    private let commandFactory: CommandFactoryProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private let stateSubject = CurrentValueSubject<ManagerState, Never>(.stopped)
    private var managedDevices: [String: DeviceInfo] = [:]
    
    public init(
        controlService: DeviceControlServiceProtocol = DeviceControlService(),
        discoveryService: DeviceDiscoveryServiceProtocol = DeviceDiscoveryService(),
        authenticationService: DeviceAuthenticationServiceProtocol = DeviceAuthenticationService(),
        commandFactory: CommandFactoryProtocol = DeviceCommandFactory()
    ) {
        self.controlService = controlService
        self.discoveryService = discoveryService
        self.authenticationService = authenticationService
        self.commandFactory = commandFactory
        
        setupStateBinding()
        setupServiceIntegration()
    }
    
    private func setupStateBinding() {
        stateSubject
            .sink { [weak self] newState in
                self?.managerState = newState
            }
            .store(in: &cancellables)
    }
    
    private func setupServiceIntegration() {
        // 监听发现的设备
        discoveryService.getDevicePublisher()
            .sink { [weak self] discoveredDevice in
                self?.handleDiscoveredDevice(discoveredDevice)
            }
            .store(in: &cancellables)
    }
    
    public func startManager() {
        guard managerState == .stopped else { return }
        
        stateSubject.send(.starting)
        
        // 启动各个服务
        controlService.startService()
        discoveryService.startDiscovery()
        
        stateSubject.send(.running)
    }
    
    public func stopManager() {
        guard managerState == .running else { return }
        
        stateSubject.send(.stopping)
        
        // 停止各个服务
        controlService.stopService()
        discoveryService.stopDiscovery()
        
        stateSubject.send(.stopped)
    }
    
    public func addDevice(_ deviceInfo: DeviceInfo) -> AnyPublisher<Bool, DeviceControlError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(DeviceControlError.managerNotInitialized("Manager not initialized")))
                return
            }
            
            // 检查设备是否已存在
            if self.managedDevices[deviceInfo.deviceId] != nil {
                promise(.failure(DeviceControlError.deviceAlreadyExists("Device already exists")))
                return
            }
            
            // 添加设备
            self.managedDevices[deviceInfo.deviceId] = deviceInfo
            
            // 开始监控设备
            self.controlService.startMonitoring(deviceInfo.deviceId)
            
            promise(.success(true))
        }
        .eraseToAnyPublisher()
    }
    
    public func removeDevice(_ deviceId: String) -> AnyPublisher<Bool, DeviceControlError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(DeviceControlError.managerNotInitialized("Manager not initialized")))
                return
            }
            
            // 检查设备是否存在
            guard self.managedDevices[deviceId] != nil else {
                promise(.failure(DeviceControlError.deviceNotFound("Device not found")))
                return
            }
            
            // 停止监控
            self.controlService.stopMonitoring(deviceId)
            
            // 撤销认证
            self.authenticationService.revokeAuthentication(deviceId: deviceId)
            
            // 移除设备
            self.managedDevices.removeValue(forKey: deviceId)
            
            promise(.success(true))
        }
        .eraseToAnyPublisher()
    }
    
    public func getDevice(_ deviceId: String) -> DeviceInfo? {
        return managedDevices[deviceId]
    }
    
    public func getAllDevices() -> [DeviceInfo] {
        return Array(managedDevices.values)
    }
    
    public func controlDevice(_ deviceId: String, command: DeviceCommandProtocol) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        // 检查设备是否存在
        guard managedDevices[deviceId] != nil else {
            return Fail(error: DeviceControlError.deviceNotFound("Device not found"))
                .eraseToAnyPublisher()
        }
        
        // 检查设备是否已认证
        guard authenticationService.isDeviceAuthenticated(deviceId: deviceId) else {
            return Fail(error: DeviceControlError.authenticationRequired("Device authentication required"))
                .eraseToAnyPublisher()
        }
        
        return controlService.executeCommand(command)
    }
    
    public func getDeviceStatus(_ deviceId: String) -> AnyPublisher<DeviceStatus, DeviceControlError> {
        guard managedDevices[deviceId] != nil else {
            return Fail(error: DeviceControlError.deviceNotFound("Device not found"))
                .eraseToAnyPublisher()
        }
        
        return controlService.getDeviceStatus(deviceId)
    }
    
    public func authenticateDevice(_ deviceId: String, credentials: DeviceCredentials) -> AnyPublisher<AuthenticationResult, DeviceControlError> {
        return authenticationService.authenticate(deviceId: deviceId, credentials: credentials)
    }
    
    public func getManagerStatePublisher() -> AnyPublisher<ManagerState, Never> {
        return stateSubject.eraseToAnyPublisher()
    }
    
    private func handleDiscoveredDevice(_ discoveredDevice: DiscoveredDevice) {
        // 将发现的设备转换为设备信息
        let deviceInfo = DeviceInfo(
            deviceId: discoveredDevice.deviceId,
            name: discoveredDevice.name,
            deviceType: discoveredDevice.deviceType,
            manufacturer: discoveredDevice.metadata["manufacturer"] as? String ?? "Unknown",
            model: discoveredDevice.metadata["model"] as? String ?? "Unknown",
            firmwareVersion: discoveredDevice.metadata["version"] as? String ?? "Unknown",
            capabilities: [], // 实际实现中应该根据设备类型确定能力
            connectionInfo: [:],
            lastSeenAt: discoveredDevice.discoveredAt
        )
        
        // 自动添加发现的设备（可选）
        addDevice(deviceInfo)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to add discovered device: \(error.localizedDescription)")
                    }
                },
                receiveValue: { success in
                    if success {
                        print("Successfully added discovered device: \(deviceInfo.name)")
                    }
                }
            )
            .store(in: &cancellables)
    }
}