//
//  DeviceAdapterManager.swift
//  DeviceControlModule
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

/// 设备适配器管理器 - 统一管理所有设备适配器
public class DeviceAdapterManager: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = DeviceAdapterManager()
    
    // MARK: - Properties
    
    private var adapters: [DeviceAdapterType: DeviceAdapterProtocol] = [:]
    private var deviceAdapterMap: [String: DeviceAdapterType] = [:] // deviceId -> adapterType
    private var adapterInitializationStatus: [DeviceAdapterType: Bool] = [:]
    
    private let connectionStateSubject = PassthroughSubject<(String, DeviceConnectionState), Never>()
    private let deviceEventSubject = PassthroughSubject<DeviceEvent, Never>()
    private let discoveredDeviceSubject = PassthroughSubject<DiscoveredDevice, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    private let queue = DispatchQueue(label: "com.iotclient.deviceadaptermanager", qos: .userInitiated)
    
    @Published public private(set) var isInitialized = false
    @Published public private(set) var availableAdapters: [DeviceAdapterType] = []
    @Published public private(set) var activeDiscoveryAdapters: Set<DeviceAdapterType> = []
    
    // MARK: - Initialization
    
    private init() {
        setupDefaultAdapters()
    }
    
    // MARK: - Public Methods
    
    /// 初始化所有适配器
    public func initialize() -> AnyPublisher<Void, DeviceControlError> {
        guard !isInitialized else {
            return Just(())
                .setFailureType(to: DeviceControlError.self)
                .eraseToAnyPublisher()
        }
        
        let initPublishers = adapters.map { (type, adapter) in
            adapter.initialize()
                .handleEvents(
                    receiveOutput: { [weak self] _ in
                        self?.adapterInitializationStatus[type] = true
                        DeviceControlLogger.log("Adapter \(type.rawValue) initialized successfully", level: .info)
                    },
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            self?.adapterInitializationStatus[type] = false
                            DeviceControlLogger.log("Adapter \(type.rawValue) initialization failed: \(error)", level: .error)
                        }
                    }
                )
                .catch { error -> AnyPublisher<Void, DeviceControlError> in
                    DeviceControlLogger.log("Adapter \(type.rawValue) initialization failed: \(error)", level: .error)
                    // 继续初始化其他适配器，即使某个适配器失败
                    return Just(()).setFailureType(to: DeviceControlError.self).eraseToAnyPublisher()
                }
        }
        
        return Publishers.MergeMany(initPublishers)
            .collect()
            .map { [weak self] _ in
                self?.isInitialized = true
                self?.updateAvailableAdapters()
                self?.setupAdapterEventHandling()
            }
            .eraseToAnyPublisher()
    }
    
    /// 关闭所有适配器
    public func shutdown() -> AnyPublisher<Void, DeviceControlError> {
        let shutdownPublishers = adapters.map { (type, adapter) in
            adapter.shutdown()
                .catch { error -> AnyPublisher<Void, DeviceControlError> in
                    DeviceControlLogger.log("Adapter \(type.rawValue) shutdown failed: \(error)", level: .warning)
                    return Just(()).setFailureType(to: DeviceControlError.self).eraseToAnyPublisher()
                }
        }
        
        return Publishers.MergeMany(shutdownPublishers)
            .collect()
            .map { [weak self] _ in
                self?.isInitialized = false
                self?.deviceAdapterMap.removeAll()
                self?.adapterInitializationStatus.removeAll()
                self?.activeDiscoveryAdapters.removeAll()
                self?.availableAdapters.removeAll()
            }
            .eraseToAnyPublisher()
    }
    
    /// 注册设备适配器
    public func registerAdapter(_ adapter: DeviceAdapterProtocol, type: DeviceAdapterType) {
        queue.async { [weak self] in
            self?.adapters[type] = adapter
            self?.adapterInitializationStatus[type] = false
            
            DispatchQueue.main.async {
                self?.updateAvailableAdapters()
            }
        }
    }
    
    /// 注销设备适配器
    public func unregisterAdapter(type: DeviceAdapterType) {
        queue.async { [weak self] in
            self?.adapters.removeValue(forKey: type)
            self?.adapterInitializationStatus.removeValue(forKey: type)
            
            // 清理使用该适配器的设备映射
            let devicesToRemove = self?.deviceAdapterMap.compactMap { (deviceId, adapterType) in
                adapterType == type ? deviceId : nil
            } ?? []
            
            for deviceId in devicesToRemove {
                self?.deviceAdapterMap.removeValue(forKey: deviceId)
            }
            
            DispatchQueue.main.async {
                self?.updateAvailableAdapters()
                self?.activeDiscoveryAdapters.remove(type)
            }
        }
    }
    
    /// 获取适配器
    public func getAdapter(type: DeviceAdapterType) -> DeviceAdapterProtocol? {
        return adapters[type]
    }
    
    /// 获取设备的适配器
    public func getAdapterForDevice(_ deviceId: String) -> DeviceAdapterProtocol? {
        guard let adapterType = deviceAdapterMap[deviceId] else {
            return nil
        }
        return adapters[adapterType]
    }
    
    /// 设备发现
    public func discoverDevices(using adapterTypes: [DeviceAdapterType]? = nil) -> AnyPublisher<DiscoveredDevice, DeviceControlError> {
        let targetAdapters = adapterTypes ?? Array(adapters.keys)
        let availableTargetAdapters = targetAdapters.filter { adapters[$0] != nil && adapterInitializationStatus[$0] == true }
        
        guard !availableTargetAdapters.isEmpty else {
            return Fail(error: DeviceControlError.noAdaptersAvailable("No initialized adapters available for discovery"))
                .eraseToAnyPublisher()
        }
        
        // 更新活跃发现适配器
        DispatchQueue.main.async { [weak self] in
            self?.activeDiscoveryAdapters.formUnion(availableTargetAdapters)
        }
        
        let discoveryPublishers = availableTargetAdapters.compactMap { adapterType -> AnyPublisher<DiscoveredDevice, DeviceControlError>? in
            guard let adapter = adapters[adapterType] else { return nil }
            
            return adapter.discoverDevices()
                .handleEvents(
                    receiveOutput: { [weak self] discoveredDevice in
                        // 记录设备与适配器的映射
                        self?.deviceAdapterMap[discoveredDevice.deviceInfo.deviceId] = adapterType
                    }
                )
                .catch { error -> AnyPublisher<DiscoveredDevice, DeviceControlError> in
                    DeviceControlLogger.log("Discovery failed for adapter \(adapterType.rawValue): \(error)", level: .warning)
                    return Empty().eraseToAnyPublisher()
                }
        }
        
        return Publishers.MergeMany(discoveryPublishers)
            .eraseToAnyPublisher()
    }
    
    /// 停止设备发现
    public func stopDiscovery(for adapterTypes: [DeviceAdapterType]? = nil) {
        let targetAdapters = adapterTypes ?? Array(activeDiscoveryAdapters)
        
        for adapterType in targetAdapters {
            adapters[adapterType]?.stopDiscovery()
        }
        
        DispatchQueue.main.async { [weak self] in
            if let adapterTypes = adapterTypes {
                for type in adapterTypes {
                    self?.activeDiscoveryAdapters.remove(type)
                }
            } else {
                self?.activeDiscoveryAdapters.removeAll()
            }
        }
    }
    
    /// 连接到设备
    public func connectToDevice(_ deviceInfo: DeviceInfo, preferredAdapterType: DeviceAdapterType? = nil) -> AnyPublisher<DeviceConnectionState, DeviceControlError> {
        let adapterType = preferredAdapterType ?? determineOptimalAdapter(for: deviceInfo)
        
        guard let adapter = adapters[adapterType],
              adapterInitializationStatus[adapterType] == true else {
            return Fail(error: DeviceControlError.adapterNotAvailable("Adapter \(adapterType.rawValue) not available"))
                .eraseToAnyPublisher()
        }
        
        // 记录设备与适配器的映射
        deviceAdapterMap[deviceInfo.deviceId] = adapterType
        
        return adapter.connectToDevice(deviceInfo)
            .handleEvents(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        // 连接失败时清理映射
                        self?.deviceAdapterMap.removeValue(forKey: deviceInfo.deviceId)
                    }
                }
            )
            .eraseToAnyPublisher()
    }
    
    /// 断开设备连接
    public func disconnectFromDevice(_ deviceId: String) -> AnyPublisher<Void, DeviceControlError> {
        guard let adapter = getAdapterForDevice(deviceId) else {
            return Fail(error: DeviceControlError.deviceNotFound("No adapter found for device: \(deviceId)"))
                .eraseToAnyPublisher()
        }
        
        return adapter.disconnectFromDevice(deviceId)
            .handleEvents(
                receiveOutput: { [weak self] _ in
                    self?.deviceAdapterMap.removeValue(forKey: deviceId)
                }
            )
            .eraseToAnyPublisher()
    }
    
    /// 执行设备命令
    public func executeCommand(_ command: DeviceCommandProtocol) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        guard let adapter = getAdapterForDevice(command.targetDeviceId) else {
            return Fail(error: DeviceControlError.deviceNotFound("No adapter found for device: \(command.targetDeviceId)"))
                .eraseToAnyPublisher()
        }
        
        return adapter.executeCommand(command)
    }
    
    /// 获取设备状态
    public func getDeviceStatus(_ deviceId: String) -> AnyPublisher<DeviceStatus, DeviceControlError> {
        guard let adapter = getAdapterForDevice(deviceId) else {
            return Fail(error: DeviceControlError.deviceNotFound("No adapter found for device: \(deviceId)"))
                .eraseToAnyPublisher()
        }
        
        return adapter.getDeviceStatus(deviceId)
    }
    
    /// 批量执行命令
    public func executeBatchCommands(_ commands: [DeviceCommandProtocol]) -> AnyPublisher<[DeviceCommandResult], DeviceControlError> {
        let commandPublishers = commands.map { command in
            executeCommand(command)
                .catch { error -> AnyPublisher<DeviceCommandResult, DeviceControlError> in
                    // 为失败的命令创建错误结果
                    let errorResult = DeviceCommandResult(
                        commandId: command.commandId,
                        status: .failed,
                        result: nil,
                        error: error,
                        executionTime: 0,
                        timestamp: Date()
                    )
                    return Just(errorResult).setFailureType(to: DeviceControlError.self).eraseToAnyPublisher()
                }
        }
        
        return Publishers.MergeMany(commandPublishers)
            .collect()
            .eraseToAnyPublisher()
    }
    
    // MARK: - Publishers
    
    public var connectionStatePublisher: AnyPublisher<(String, DeviceConnectionState), Never> {
        return connectionStateSubject.eraseToAnyPublisher()
    }
    
    public var deviceEventPublisher: AnyPublisher<DeviceEvent, Never> {
        return deviceEventSubject.eraseToAnyPublisher()
    }
    
    public var discoveredDevicePublisher: AnyPublisher<DiscoveredDevice, Never> {
        return discoveredDeviceSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Statistics and Health
    
    public func getAdapterStatistics() -> [DeviceAdapterType: DeviceAdapterStatistics] {
        var statistics: [DeviceAdapterType: DeviceAdapterStatistics] = [:]
        
        for (type, adapter) in adapters {
            let connectedDevices = deviceAdapterMap.values.filter { $0 == type }.count
            let isInitialized = adapterInitializationStatus[type] ?? false
            let isDiscovering = activeDiscoveryAdapters.contains(type)
            
            statistics[type] = DeviceAdapterStatistics(
                adapterType: type,
                isInitialized: isInitialized,
                isDiscovering: isDiscovering,
                connectedDevicesCount: connectedDevices,
                supportedDeviceTypes: adapter.supportedDeviceTypes,
                lastActivity: Date() // 这里应该跟踪实际的最后活动时间
            )
        }
        
        return statistics
    }
    
    public func getHealthStatus() -> DeviceAdapterManagerHealth {
        let totalAdapters = adapters.count
        let initializedAdapters = adapterInitializationStatus.values.filter { $0 }.count
        let totalConnectedDevices = deviceAdapterMap.count
        let activeDiscoveries = activeDiscoveryAdapters.count
        
        let healthScore = totalAdapters > 0 ? Double(initializedAdapters) / Double(totalAdapters) : 0.0
        
        let status: DeviceAdapterManagerHealth.Status
        if healthScore >= 0.8 {
            status = .healthy
        } else if healthScore >= 0.5 {
            status = .degraded
        } else {
            status = .unhealthy
        }
        
        return DeviceAdapterManagerHealth(
            status: status,
            healthScore: healthScore,
            totalAdapters: totalAdapters,
            initializedAdapters: initializedAdapters,
            connectedDevices: totalConnectedDevices,
            activeDiscoveries: activeDiscoveries,
            lastHealthCheck: Date()
        )
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultAdapters() {
        // 注册默认适配器
        registerAdapter(BLEDeviceAdapter(), type: .ble)
        registerAdapter(MQTTDeviceAdapter(), type: .mqtt)
        registerAdapter(ConnectivityLayerAdapter(), type: .connectivityLayer)
    }
    
    private func updateAvailableAdapters() {
        availableAdapters = Array(adapters.keys).sorted { $0.rawValue < $1.rawValue }
    }
    
    private func setupAdapterEventHandling() {
        // 设置所有适配器的事件处理
        for (_, adapter) in adapters {
            // 连接状态事件
            adapter.connectionStatePublisher
                .sink { [weak self] (deviceId, state) in
                    self?.connectionStateSubject.send((deviceId, state))
                }
                .store(in: &cancellables)
            
            // 设备事件
            adapter.deviceEventPublisher
                .sink { [weak self] event in
                    self?.deviceEventSubject.send(event)
                }
                .store(in: &cancellables)
        }
    }
    
    private func determineOptimalAdapter(for deviceInfo: DeviceInfo) -> DeviceAdapterType {
        // 根据设备信息确定最优适配器
        if let protocol = deviceInfo.connectionInfo["protocol"] as? String {
            switch protocol.lowercased() {
            case "ble", "bluetooth":
                return .ble
            case "mqtt":
                return .mqtt
            case "wifi", "http", "https":
                return .connectivityLayer
            default:
                break
            }
        }
        
        // 根据设备类型推断
        switch deviceInfo.deviceType {
        case .sensor:
            return adapters[.ble] != nil ? .ble : .mqtt
        case .light:
            return adapters[.mqtt] != nil ? .mqtt : .connectivityLayer
        case .thermostat, .camera:
            return .connectivityLayer
        default:
            // 返回第一个可用的适配器
            return availableAdapters.first ?? .connectivityLayer
        }
    }
}

// MARK: - Supporting Types

public struct DeviceAdapterStatistics {
    public let adapterType: DeviceAdapterType
    public let isInitialized: Bool
    public let isDiscovering: Bool
    public let connectedDevicesCount: Int
    public let supportedDeviceTypes: [DeviceType]
    public let lastActivity: Date
}

public struct DeviceAdapterManagerHealth {
    public enum Status {
        case healthy
        case degraded
        case unhealthy
    }
    
    public let status: Status
    public let healthScore: Double // 0.0 - 1.0
    public let totalAdapters: Int
    public let initializedAdapters: Int
    public let connectedDevices: Int
    public let activeDiscoveries: Int
    public let lastHealthCheck: Date
}

// MARK: - Error Extensions

extension DeviceControlError {
    static func noAdaptersAvailable(_ message: String) -> DeviceControlError {
        return .unknown(message)
    }
    
    static func adapterNotAvailable(_ message: String) -> DeviceControlError {
        return .unknown(message)
    }
}