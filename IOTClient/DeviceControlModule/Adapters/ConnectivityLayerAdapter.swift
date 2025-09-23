//
//  ConnectivityLayerAdapter.swift
//  DeviceControlModule
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

/// ConnectivityLayer设备适配器 - 将现有ConnectivityLayer功能整合到DeviceControlModule架构中
public class ConnectivityLayerAdapter: NSObject, DeviceAdapterProtocol {
    
    // MARK: - Properties
    
    public let adapterType: DeviceAdapterType = .connectivityLayer
    public let supportedDeviceTypes: [DeviceType] = [.light, .sensor, .switch, .thermostat, .camera, .gateway, .hub]
    
    private let connectivityManager: ConnectivityLayerManager
    private var connectedDevices: Set<String> = []
    private var deviceProtocolMap: [String: ConnectivityProtocol] = [:]
    
    private let connectionStateSubject = PassthroughSubject<(String, DeviceConnectionState), Never>()
    private let deviceEventSubject = PassthroughSubject<DeviceEvent, Never>()
    private let discoveredDeviceSubject = PassthroughSubject<DiscoveredDevice, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    private var discoveryActive = false
    
    // MARK: - Initialization
    
    public override init() {
        self.connectivityManager = ConnectivityLayerManager.shared
        super.init()
        
        setupConnectivityEventHandling()
    }
    
    // MARK: - DeviceAdapterProtocol Implementation
    
    public func initialize() -> AnyPublisher<Void, DeviceControlError> {
        return Future<Void, DeviceControlError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown("Adapter deallocated")))
                return
            }
            
            do {
                try self.connectivityManager.initialize()
                promise(.success(()))
            } catch {
                promise(.failure(.initializationFailed("ConnectivityLayer initialization failed: \(error.localizedDescription)")))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func shutdown() -> AnyPublisher<Void, DeviceControlError> {
        connectivityManager.shutdown()
        connectedDevices.removeAll()
        deviceProtocolMap.removeAll()
        discoveryActive = false
        
        return Just(())
            .setFailureType(to: DeviceControlError.self)
            .eraseToAnyPublisher()
    }
    
    public func discoverDevices() -> AnyPublisher<DiscoveredDevice, DeviceControlError> {
        guard !discoveryActive else {
            return discoveredDeviceSubject
                .setFailureType(to: DeviceControlError.self)
                .eraseToAnyPublisher()
        }
        
        discoveryActive = true
        
        // 启动多协议设备发现
        let protocols: [ConnectivityProtocol] = [.mqtt, .ble, .zigbee, .matter, .wifi]
        
        for protocol in protocols {
            connectivityManager.startDiscovery(for: protocol) { [weak self] result in
                switch result {
                case .success(let devices):
                    self?.handleDiscoveredDevices(devices, protocol: protocol)
                case .failure(let error):
                    DeviceControlLogger.log("Discovery failed for \(protocol): \(error)", level: .warning)
                }
            }
        }
        
        return discoveredDeviceSubject
            .setFailureType(to: DeviceControlError.self)
            .eraseToAnyPublisher()
    }
    
    public func stopDiscovery() {
        guard discoveryActive else { return }
        
        discoveryActive = false
        connectivityManager.stopDiscovery()
    }
    
    public func connectToDevice(_ deviceInfo: DeviceInfo) -> AnyPublisher<DeviceConnectionState, DeviceControlError> {
        let deviceId = deviceInfo.deviceId
        
        // 确定设备协议
        let protocol = determineProtocol(from: deviceInfo)
        deviceProtocolMap[deviceId] = protocol
        
        return Future<DeviceConnectionState, DeviceControlError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown("Adapter deallocated")))
                return
            }
            
            self.connectivityManager.connect(
                to: deviceId,
                using: protocol,
                configuration: self.createConnectionConfiguration(deviceInfo)
            ) { result in
                switch result {
                case .success:
                    self.connectedDevices.insert(deviceId)
                    self.connectionStateSubject.send((deviceId, .connected))
                    promise(.success(.connected))
                case .failure(let error):
                    promise(.failure(.connectionFailed("Failed to connect to \(deviceId): \(error.localizedDescription)")))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func disconnectFromDevice(_ deviceId: String) -> AnyPublisher<Void, DeviceControlError> {
        return Future<Void, DeviceControlError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown("Adapter deallocated")))
                return
            }
            
            self.connectivityManager.disconnect(from: deviceId) { result in
                switch result {
                case .success:
                    self.connectedDevices.remove(deviceId)
                    self.deviceProtocolMap.removeValue(forKey: deviceId)
                    self.connectionStateSubject.send((deviceId, .disconnected))
                    promise(.success(()))
                case .failure(let error):
                    promise(.failure(.disconnectionFailed("Failed to disconnect from \(deviceId): \(error.localizedDescription)")))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func executeCommand(_ command: DeviceCommandProtocol) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let deviceId = command.targetDeviceId
        
        guard connectedDevices.contains(deviceId),
              let protocol = deviceProtocolMap[deviceId] else {
            return Fail(error: DeviceControlError.deviceNotFound("Device not connected: \(deviceId)"))
                .eraseToAnyPublisher()
        }
        
        return executeConnectivityCommand(command, protocol: protocol)
    }
    
    public func getDeviceStatus(_ deviceId: String) -> AnyPublisher<DeviceStatus, DeviceControlError> {
        guard connectedDevices.contains(deviceId),
              let protocol = deviceProtocolMap[deviceId] else {
            return Fail(error: DeviceControlError.deviceNotFound("Device not connected: \(deviceId)"))
                .eraseToAnyPublisher()
        }
        
        return requestConnectivityDeviceStatus(deviceId: deviceId, protocol: protocol)
    }
    
    public var connectionStatePublisher: AnyPublisher<(String, DeviceConnectionState), Never> {
        return connectionStateSubject.eraseToAnyPublisher()
    }
    
    public var deviceEventPublisher: AnyPublisher<DeviceEvent, Never> {
        return deviceEventSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Command Execution
    
    private func executeConnectivityCommand(_ command: DeviceCommandProtocol, protocol: ConnectivityProtocol) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        return Future<DeviceCommandResult, DeviceControlError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown("Adapter deallocated")))
                return
            }
            
            let startTime = Date()
            let connectivityCommand = self.convertToConnectivityCommand(command, protocol: protocol)
            
            self.connectivityManager.sendCommand(
                connectivityCommand,
                to: command.targetDeviceId,
                using: protocol
            ) { result in
                let executionTime = Date().timeIntervalSince(startTime)
                
                switch result {
                case .success(let response):
                    let commandResult = DeviceCommandResult(
                        commandId: command.commandId,
                        status: .completed,
                        result: response,
                        error: nil,
                        executionTime: executionTime,
                        timestamp: Date()
                    )
                    promise(.success(commandResult))
                    
                case .failure(let error):
                    let commandResult = DeviceCommandResult(
                        commandId: command.commandId,
                        status: .failed,
                        result: nil,
                        error: DeviceControlError.executionFailed(error.localizedDescription),
                        executionTime: executionTime,
                        timestamp: Date()
                    )
                    promise(.success(commandResult))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func convertToConnectivityCommand(_ command: DeviceCommandProtocol, protocol: ConnectivityProtocol) -> ConnectivityCommand {
        var commandData: [String: Any] = [
            "commandId": command.commandId,
            "commandType": command.commandType.rawValue,
            "parameters": command.parameters,
            "priority": command.priority.rawValue,
            "timeout": command.timeout
        ]
        
        // 根据协议调整命令格式
        switch protocol {
        case .mqtt:
            commandData["topic"] = "devices/\(command.targetDeviceId)/control"
            commandData["qos"] = 1
            
        case .ble:
            commandData["serviceUUID"] = determineServiceUUID(for: command.commandType)
            commandData["characteristicUUID"] = determineCharacteristicUUID(for: command.commandType)
            
        case .zigbee:
            commandData["clusterId"] = determineClusterId(for: command.commandType)
            commandData["attributeId"] = determineAttributeId(for: command.commandType)
            
        case .matter:
            commandData["endpointId"] = 1
            commandData["clusterId"] = determineMatterClusterId(for: command.commandType)
            
        case .wifi:
            commandData["endpoint"] = "/api/v1/devices/\(command.targetDeviceId)/control"
            commandData["method"] = "POST"
            
        default:
            break
        }
        
        return ConnectivityCommand(
            id: command.commandId,
            type: command.commandType.rawValue,
            data: commandData,
            protocol: protocol
        )
    }
    
    // MARK: - Device Status
    
    private func requestConnectivityDeviceStatus(deviceId: String, protocol: ConnectivityProtocol) -> AnyPublisher<DeviceStatus, DeviceControlError> {
        return Future<DeviceStatus, DeviceControlError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown("Adapter deallocated")))
                return
            }
            
            self.connectivityManager.getDeviceStatus(deviceId, using: protocol) { result in
                switch result {
                case .success(let statusData):
                    let deviceStatus = self.parseDeviceStatus(statusData, deviceId: deviceId)
                    promise(.success(deviceStatus))
                    
                case .failure(let error):
                    promise(.failure(.communicationError("Failed to get status for \(deviceId): \(error.localizedDescription)")))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func parseDeviceStatus(_ statusData: [String: Any], deviceId: String) -> DeviceStatus {
        let connectionState: DeviceConnectionState
        if let isOnline = statusData["online"] as? Bool {
            connectionState = isOnline ? .connected : .disconnected
        } else {
            connectionState = .connected
        }
        
        return DeviceStatus(
            deviceId: deviceId,
            connectionState: connectionState,
            batteryLevel: statusData["batteryLevel"] as? Int,
            signalStrength: statusData["signalStrength"] as? Int,
            lastSeen: Date(),
            properties: statusData
        )
    }
    
    // MARK: - Event Handling
    
    private func setupConnectivityEventHandling() {
        // 监听ConnectivityLayer事件
        connectivityManager.eventPublisher
            .sink { [weak self] event in
                self?.handleConnectivityEvent(event)
            }
            .store(in: &cancellables)
    }
    
    private func handleConnectivityEvent(_ event: ConnectivityEvent) {
        switch event.type {
        case .deviceConnected:
            if let deviceId = event.data["deviceId"] as? String {
                connectionStateSubject.send((deviceId, .connected))
            }
            
        case .deviceDisconnected:
            if let deviceId = event.data["deviceId"] as? String {
                connectionStateSubject.send((deviceId, .disconnected))
                connectedDevices.remove(deviceId)
                deviceProtocolMap.removeValue(forKey: deviceId)
            }
            
        case .deviceStatusChanged:
            if let deviceId = event.data["deviceId"] as? String {
                let deviceEvent = DeviceEvent(
                    deviceId: deviceId,
                    eventType: .statusUpdated,
                    data: event.data,
                    timestamp: event.timestamp
                )
                deviceEventSubject.send(deviceEvent)
            }
            
        case .protocolError:
            if let deviceId = event.data["deviceId"] as? String {
                let deviceEvent = DeviceEvent(
                    deviceId: deviceId,
                    eventType: .error,
                    data: event.data,
                    timestamp: event.timestamp
                )
                deviceEventSubject.send(deviceEvent)
            }
            
        default:
            break
        }
    }
    
    private func handleDiscoveredDevices(_ devices: [ConnectivityDevice], protocol: ConnectivityProtocol) {
        for device in devices {
            guard let deviceInfo = convertToDeviceInfo(device, protocol: protocol) else {
                continue
            }
            
            let discoveredDevice = DiscoveredDevice(
                deviceInfo: deviceInfo,
                discoveryMethod: "ConnectivityLayer (\(protocol.rawValue))",
                discoveryTime: Date(),
                signalStrength: device.signalStrength
            )
            
            discoveredDeviceSubject.send(discoveredDevice)
        }
    }
    
    // MARK: - Helper Methods
    
    private func determineProtocol(from deviceInfo: DeviceInfo) -> ConnectivityProtocol {
        if let protocolString = deviceInfo.connectionInfo["protocol"] as? String {
            return ConnectivityProtocol(rawValue: protocolString) ?? .wifi
        }
        
        // 根据设备类型和制造商推断协议
        switch deviceInfo.deviceType {
        case .light:
            return deviceInfo.manufacturer.lowercased().contains("philips") ? .zigbee : .wifi
        case .sensor:
            return .zigbee
        case .thermostat:
            return .wifi
        case .camera:
            return .wifi
        case .gateway, .hub:
            return .wifi
        default:
            return .wifi
        }
    }
    
    private func createConnectionConfiguration(_ deviceInfo: DeviceInfo) -> ConnectivityConfiguration {
        var config = ConnectivityConfiguration()
        
        config.deviceId = deviceInfo.deviceId
        config.deviceType = deviceInfo.deviceType.rawValue
        config.timeout = 30.0
        config.retryCount = 3
        config.keepAlive = true
        
        // 从deviceInfo中提取连接信息
        if let host = deviceInfo.connectionInfo["host"] as? String {
            config.host = host
        }
        
        if let port = deviceInfo.connectionInfo["port"] as? Int {
            config.port = port
        }
        
        if let username = deviceInfo.connectionInfo["username"] as? String {
            config.username = username
        }
        
        if let password = deviceInfo.connectionInfo["password"] as? String {
            config.password = password
        }
        
        return config
    }
    
    private func convertToDeviceInfo(_ device: ConnectivityDevice, protocol: ConnectivityProtocol) -> DeviceInfo? {
        guard let deviceType = DeviceType(rawValue: device.type) else {
            return nil
        }
        
        let capabilities = device.capabilities.compactMap { DeviceCapability(rawValue: $0) }
        
        var connectionInfo: [String: Any] = [
            "protocol": protocol.rawValue
        ]
        
        // 添加协议特定的连接信息
        switch protocol {
        case .mqtt:
            connectionInfo["topic"] = "devices/\(device.id)/control"
        case .ble:
            connectionInfo["serviceUUID"] = device.serviceUUID
        case .zigbee:
            connectionInfo["networkId"] = device.networkId
        case .matter:
            connectionInfo["nodeId"] = device.nodeId
        case .wifi:
            connectionInfo["ipAddress"] = device.ipAddress
            connectionInfo["port"] = device.port
        default:
            break
        }
        
        return DeviceInfo(
            deviceId: device.id,
            deviceName: device.name,
            deviceType: deviceType,
            manufacturer: device.manufacturer,
            modelNumber: device.modelNumber,
            firmwareVersion: device.firmwareVersion,
            capabilities: capabilities,
            connectionInfo: connectionInfo
        )
    }
    
    // MARK: - Protocol-Specific Helpers
    
    private func determineServiceUUID(for commandType: CommandType) -> String {
        switch commandType {
        case .switch, .dimming, .color:
            return "12345678-1234-1234-1234-123456789abc" // Light service
        case .temperature:
            return "87654321-4321-4321-4321-cba987654321" // Thermostat service
        default:
            return "00000000-0000-0000-0000-000000000000" // Generic service
        }
    }
    
    private func determineCharacteristicUUID(for commandType: CommandType) -> String {
        switch commandType {
        case .switch:
            return "11111111-1111-1111-1111-111111111111" // Switch characteristic
        case .dimming:
            return "22222222-2222-2222-2222-222222222222" // Brightness characteristic
        case .color:
            return "33333333-3333-3333-3333-333333333333" // Color characteristic
        case .temperature:
            return "44444444-4444-4444-4444-444444444444" // Temperature characteristic
        default:
            return "00000000-0000-0000-0000-000000000000" // Generic characteristic
        }
    }
    
    private func determineClusterId(for commandType: CommandType) -> UInt16 {
        switch commandType {
        case .switch:
            return 0x0006 // On/Off cluster
        case .dimming:
            return 0x0008 // Level Control cluster
        case .color:
            return 0x0300 // Color Control cluster
        case .temperature:
            return 0x0201 // Thermostat cluster
        default:
            return 0x0000 // Basic cluster
        }
    }
    
    private func determineAttributeId(for commandType: CommandType) -> UInt16 {
        switch commandType {
        case .switch:
            return 0x0000 // OnOff attribute
        case .dimming:
            return 0x0000 // CurrentLevel attribute
        case .color:
            return 0x0003 // CurrentX attribute
        case .temperature:
            return 0x0000 // LocalTemperature attribute
        default:
            return 0x0000 // Default attribute
        }
    }
    
    private func determineMatterClusterId(for commandType: CommandType) -> UInt32 {
        switch commandType {
        case .switch:
            return 0x0006 // On/Off cluster
        case .dimming:
            return 0x0008 // Level Control cluster
        case .color:
            return 0x0300 // Color Control cluster
        case .temperature:
            return 0x0201 // Thermostat cluster
        default:
            return 0x001D // Descriptor cluster
        }
    }
}

// MARK: - DeviceAdapterType Extension

extension DeviceAdapterType {
    static let connectivityLayer = DeviceAdapterType(rawValue: "connectivityLayer")!
}

// MARK: - ConnectivityLayer Types (Mock definitions for compilation)

// 这些类型定义应该来自实际的ConnectivityLayer模块
// 这里提供基本定义以确保编译通过

public enum ConnectivityProtocol: String, CaseIterable {
    case mqtt = "mqtt"
    case ble = "ble"
    case zigbee = "zigbee"
    case matter = "matter"
    case wifi = "wifi"
    case zwave = "zwave"
}

public struct ConnectivityDevice {
    let id: String
    let name: String
    let type: String
    let manufacturer: String
    let modelNumber: String
    let firmwareVersion: String
    let capabilities: [String]
    let signalStrength: Int?
    let serviceUUID: String?
    let networkId: String?
    let nodeId: String?
    let ipAddress: String?
    let port: Int?
}

public struct ConnectivityCommand {
    let id: String
    let type: String
    let data: [String: Any]
    let protocol: ConnectivityProtocol
}

public struct ConnectivityConfiguration {
    var deviceId: String = ""
    var deviceType: String = ""
    var host: String = ""
    var port: Int = 0
    var username: String = ""
    var password: String = ""
    var timeout: TimeInterval = 30.0
    var retryCount: Int = 3
    var keepAlive: Bool = true
}

public struct ConnectivityEvent {
    let type: ConnectivityEventType
    let data: [String: Any]
    let timestamp: Date
}

public enum ConnectivityEventType {
    case deviceConnected
    case deviceDisconnected
    case deviceStatusChanged
    case protocolError
    case discoveryStarted
    case discoveryCompleted
}