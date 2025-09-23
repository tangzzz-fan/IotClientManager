//
//  MQTTDeviceAdapter.swift
//  DeviceControlModule
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine
import MQTTClient

/// MQTT设备适配器 - 将现有MQTT功能整合到DeviceControlModule架构中
public class MQTTDeviceAdapter: NSObject, DeviceAdapterProtocol {
    
    // MARK: - Properties
    
    public let adapterType: DeviceAdapterType = .mqtt
    public let supportedDeviceTypes: [DeviceType] = [.light, .sensor, .switch, .thermostat, .camera, .gateway]
    
    private let mqttManager: MQTTClientManager
    private var deviceTopics: [String: String] = [:] // deviceId -> topic
    private var topicToDeviceId: [String: String] = [:] // topic -> deviceId
    private var subscribedTopics: Set<String> = []
    
    private let connectionStateSubject = PassthroughSubject<(String, DeviceConnectionState), Never>()
    private let deviceEventSubject = PassthroughSubject<DeviceEvent, Never>()
    private let discoveredDeviceSubject = PassthroughSubject<DiscoveredDevice, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    private var pendingCommands: [String: (Result<DeviceCommandResult, DeviceControlError>) -> Void] = [:]
    
    // MARK: - MQTT Topics Configuration
    
    private struct MQTTTopics {
        static let deviceDiscovery = "devices/discovery"
        static let deviceStatus = "devices/+/status"
        static let deviceControl = "devices/+/control"
        static let deviceResponse = "devices/+/response"
        static let deviceEvents = "devices/+/events"
        
        static func controlTopic(for deviceId: String) -> String {
            return "devices/\(deviceId)/control"
        }
        
        static func statusTopic(for deviceId: String) -> String {
            return "devices/\(deviceId)/status"
        }
        
        static func responseTopic(for deviceId: String) -> String {
            return "devices/\(deviceId)/response"
        }
        
        static func eventsTopic(for deviceId: String) -> String {
            return "devices/\(deviceId)/events"
        }
    }
    
    // MARK: - Initialization
    
    public override init() {
        self.mqttManager = MQTTClientManager.shared
        super.init()
        
        setupMQTTMessageHandling()
    }
    
    // MARK: - DeviceAdapterProtocol Implementation
    
    public func initialize() -> AnyPublisher<Void, DeviceControlError> {
        return Future<Void, DeviceControlError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown("Adapter deallocated")))
                return
            }
            
            self.mqttManager.connect { result in
                switch result {
                case .success:
                    self.subscribeToSystemTopics()
                    promise(.success(()))
                case .failure(let error):
                    promise(.failure(.connectionFailed("MQTT connection failed: \(error.localizedDescription)")))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func shutdown() -> AnyPublisher<Void, DeviceControlError> {
        mqttManager.disconnect()
        deviceTopics.removeAll()
        topicToDeviceId.removeAll()
        subscribedTopics.removeAll()
        pendingCommands.removeAll()
        
        return Just(())
            .setFailureType(to: DeviceControlError.self)
            .eraseToAnyPublisher()
    }
    
    public func discoverDevices() -> AnyPublisher<DiscoveredDevice, DeviceControlError> {
        // 发送设备发现请求
        let discoveryMessage = [
            "action": "discover",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        guard let messageData = try? JSONSerialization.data(withJSONObject: discoveryMessage) else {
            return Fail(error: DeviceControlError.invalidParameters("Failed to create discovery message"))
                .eraseToAnyPublisher()
        }
        
        mqttManager.publish(
            message: messageData,
            to: MQTTTopics.deviceDiscovery,
            qos: .atLeastOnce,
            retained: false
        ) { result in
            if case .failure(let error) = result {
                DeviceControlLogger.log("Failed to publish discovery message: \(error)", level: .error)
            }
        }
        
        return discoveredDeviceSubject
            .setFailureType(to: DeviceControlError.self)
            .eraseToAnyPublisher()
    }
    
    public func stopDiscovery() {
        // MQTT设备发现是基于消息的，无需特殊停止操作
    }
    
    public func connectToDevice(_ deviceInfo: DeviceInfo) -> AnyPublisher<DeviceConnectionState, DeviceControlError> {
        let deviceId = deviceInfo.deviceId
        
        // 订阅设备相关主题
        let topics = [
            MQTTTopics.statusTopic(for: deviceId),
            MQTTTopics.responseTopic(for: deviceId),
            MQTTTopics.eventsTopic(for: deviceId)
        ]
        
        mqttManager.subscribe(to: topics)
        
        // 存储设备主题映射
        deviceTopics[deviceId] = MQTTTopics.controlTopic(for: deviceId)
        for topic in topics {
            topicToDeviceId[topic] = deviceId
            subscribedTopics.insert(topic)
        }
        
        // 发送连接请求
        let connectMessage = [
            "action": "connect",
            "deviceId": deviceId,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        guard let messageData = try? JSONSerialization.data(withJSONObject: connectMessage) else {
            return Fail(error: DeviceControlError.invalidParameters("Failed to create connect message"))
                .eraseToAnyPublisher()
        }
        
        mqttManager.publish(
            message: messageData,
            to: MQTTTopics.controlTopic(for: deviceId),
            qos: .atLeastOnce,
            retained: false
        ) { result in
            if case .failure(let error) = result {
                DeviceControlLogger.log("Failed to publish connect message: \(error)", level: .error)
            }
        }
        
        return connectionStateSubject
            .filter { $0.0 == deviceId }
            .map { $0.1 }
            .setFailureType(to: DeviceControlError.self)
            .eraseToAnyPublisher()
    }
    
    public func disconnectFromDevice(_ deviceId: String) -> AnyPublisher<Void, DeviceControlError> {
        // 取消订阅设备主题
        let topics = [
            MQTTTopics.statusTopic(for: deviceId),
            MQTTTopics.responseTopic(for: deviceId),
            MQTTTopics.eventsTopic(for: deviceId)
        ]
        
        mqttManager.unsubscribe(from: topics)
        
        // 清理映射
        deviceTopics.removeValue(forKey: deviceId)
        for topic in topics {
            topicToDeviceId.removeValue(forKey: topic)
            subscribedTopics.remove(topic)
        }
        
        // 发送断开连接消息
        let disconnectMessage = [
            "action": "disconnect",
            "deviceId": deviceId,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        guard let messageData = try? JSONSerialization.data(withJSONObject: disconnectMessage) else {
            return Fail(error: DeviceControlError.invalidParameters("Failed to create disconnect message"))
                .eraseToAnyPublisher()
        }
        
        mqttManager.publish(
            message: messageData,
            to: MQTTTopics.controlTopic(for: deviceId),
            qos: .atLeastOnce,
            retained: false
        ) { _ in }
        
        return Just(())
            .setFailureType(to: DeviceControlError.self)
            .eraseToAnyPublisher()
    }
    
    public func executeCommand(_ command: DeviceCommandProtocol) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        guard let topic = deviceTopics[command.targetDeviceId] else {
            return Fail(error: DeviceControlError.deviceNotFound("Device not connected: \(command.targetDeviceId)"))
                .eraseToAnyPublisher()
        }
        
        return executeMQTTCommand(command, topic: topic)
    }
    
    public func getDeviceStatus(_ deviceId: String) -> AnyPublisher<DeviceStatus, DeviceControlError> {
        guard deviceTopics[deviceId] != nil else {
            return Fail(error: DeviceControlError.deviceNotFound("Device not connected: \(deviceId)"))
                .eraseToAnyPublisher()
        }
        
        return requestMQTTDeviceStatus(deviceId: deviceId)
    }
    
    public var connectionStatePublisher: AnyPublisher<(String, DeviceConnectionState), Never> {
        return connectionStateSubject.eraseToAnyPublisher()
    }
    
    public var deviceEventPublisher: AnyPublisher<DeviceEvent, Never> {
        return deviceEventSubject.eraseToAnyPublisher()
    }
    
    // MARK: - MQTT Command Execution
    
    private func executeMQTTCommand(_ command: DeviceCommandProtocol, topic: String) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        return Future<DeviceCommandResult, DeviceControlError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown("Adapter deallocated")))
                return
            }
            
            let startTime = Date()
            let commandMessage = self.createCommandMessage(command)
            
            guard let messageData = try? JSONSerialization.data(withJSONObject: commandMessage) else {
                promise(.failure(.invalidParameters("Failed to serialize command message")))
                return
            }
            
            // 存储待处理的命令
            self.pendingCommands[command.commandId] = promise
            
            // 设置超时
            DispatchQueue.main.asyncAfter(deadline: .now() + command.timeout) {
                if let pendingPromise = self.pendingCommands.removeValue(forKey: command.commandId) {
                    let result = DeviceCommandResult(
                        commandId: command.commandId,
                        status: .failed,
                        result: nil,
                        error: DeviceControlError.timeout("Command timeout after \(command.timeout) seconds"),
                        executionTime: Date().timeIntervalSince(startTime),
                        timestamp: Date()
                    )
                    pendingPromise(.success(result))
                }
            }
            
            // 发布命令
            self.mqttManager.publish(
                message: messageData,
                to: topic,
                qos: .atLeastOnce,
                retained: false
            ) { result in
                if case .failure(let error) = result {
                    if let pendingPromise = self.pendingCommands.removeValue(forKey: command.commandId) {
                        pendingPromise(.failure(.communicationError("Failed to publish command: \(error.localizedDescription)")))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func createCommandMessage(_ command: DeviceCommandProtocol) -> [String: Any] {
        var message: [String: Any] = [
            "commandId": command.commandId,
            "action": "execute",
            "commandType": command.commandType.rawValue,
            "parameters": command.parameters,
            "priority": command.priority.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        // 根据命令类型添加特定参数
        switch command.commandType {
        case .switch:
            if let isOn = command.parameters["isOn"] as? Bool {
                message["state"] = isOn ? "on" : "off"
            }
            
        case .dimming:
            if let brightness = command.parameters["brightness"] as? Int {
                message["brightness"] = brightness
            }
            
        case .color:
            if let colorDict = command.parameters["color"] as? [String: Any] {
                message["color"] = colorDict
            }
            
        case .temperature:
            if let temperature = command.parameters["temperature"] as? Double {
                message["temperature"] = temperature
            }
            
        case .scene:
            if let sceneId = command.parameters["sceneId"] as? String {
                message["sceneId"] = sceneId
            }
            
        case .timer:
            if let duration = command.parameters["duration"] as? TimeInterval {
                message["duration"] = duration
            }
            
        default:
            break
        }
        
        return message
    }
    
    // MARK: - Device Status
    
    private func requestMQTTDeviceStatus(deviceId: String) -> AnyPublisher<DeviceStatus, DeviceControlError> {
        return Future<DeviceStatus, DeviceControlError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown("Adapter deallocated")))
                return
            }
            
            let statusRequest = [
                "action": "getStatus",
                "deviceId": deviceId,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
            
            guard let messageData = try? JSONSerialization.data(withJSONObject: statusRequest) else {
                promise(.failure(.invalidParameters("Failed to create status request")))
                return
            }
            
            let requestId = UUID().uuidString
            
            // 临时存储状态请求
            let statusPromise: (Result<DeviceStatus, DeviceControlError>) -> Void = { result in
                promise(result)
            }
            
            // 设置超时
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                // 如果10秒内没有收到响应，返回默认状态
                let defaultStatus = DeviceStatus(
                    deviceId: deviceId,
                    connectionState: .connected,
                    batteryLevel: nil,
                    signalStrength: nil,
                    lastSeen: Date(),
                    properties: ["source": "mqtt", "timeout": true]
                )
                statusPromise(.success(defaultStatus))
            }
            
            // 发布状态请求
            self.mqttManager.publish(
                message: messageData,
                to: MQTTTopics.controlTopic(for: deviceId),
                qos: .atLeastOnce,
                retained: false
            ) { result in
                if case .failure(let error) = result {
                    statusPromise(.failure(.communicationError("Failed to request status: \(error.localizedDescription)")))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - MQTT Message Handling
    
    private func setupMQTTMessageHandling() {
        // 这里需要设置MQTT消息处理，但由于MQTTClientManager的接口限制，
        // 我们需要通过通知或其他方式来处理消息
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMQTTMessage(_:)),
            name: .mqttMessageReceived,
            object: nil
        )
    }
    
    @objc private func handleMQTTMessage(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let topic = userInfo["topic"] as? String,
              let data = userInfo["data"] as? Data else {
            return
        }
        
        handleReceivedMessage(data: data, topic: topic)
    }
    
    private func handleReceivedMessage(data: Data, topic: String) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            DeviceControlLogger.log("Failed to parse MQTT message JSON", level: .warning)
            return
        }
        
        // 根据主题类型处理消息
        if topic.contains("/status") {
            handleStatusMessage(json, topic: topic)
        } else if topic.contains("/response") {
            handleResponseMessage(json, topic: topic)
        } else if topic.contains("/events") {
            handleEventMessage(json, topic: topic)
        } else if topic == MQTTTopics.deviceDiscovery {
            handleDiscoveryMessage(json)
        }
    }
    
    private func handleStatusMessage(_ json: [String: Any], topic: String) {
        guard let deviceId = extractDeviceIdFromTopic(topic) else { return }
        
        let connectionState: DeviceConnectionState
        if let status = json["status"] as? String {
            connectionState = status == "online" ? .connected : .disconnected
        } else {
            connectionState = .connected
        }
        
        connectionStateSubject.send((deviceId, connectionState))
        
        // 发送状态更新事件
        let event = DeviceEvent(
            deviceId: deviceId,
            eventType: .statusUpdated,
            data: json,
            timestamp: Date()
        )
        deviceEventSubject.send(event)
    }
    
    private func handleResponseMessage(_ json: [String: Any], topic: String) {
        guard let deviceId = extractDeviceIdFromTopic(topic),
              let commandId = json["commandId"] as? String,
              let promise = pendingCommands.removeValue(forKey: commandId) else {
            return
        }
        
        let success = json["success"] as? Bool ?? false
        let status: CommandStatus = success ? .completed : .failed
        
        let result = DeviceCommandResult(
            commandId: commandId,
            status: status,
            result: json["result"],
            error: success ? nil : DeviceControlError.executionFailed(json["error"] as? String ?? "Unknown error"),
            executionTime: json["executionTime"] as? TimeInterval ?? 0,
            timestamp: Date()
        )
        
        promise(.success(result))
    }
    
    private func handleEventMessage(_ json: [String: Any], topic: String) {
        guard let deviceId = extractDeviceIdFromTopic(topic),
              let eventTypeString = json["eventType"] as? String else {
            return
        }
        
        let eventType = DeviceEventType(rawValue: eventTypeString) ?? .unknown
        
        let event = DeviceEvent(
            deviceId: deviceId,
            eventType: eventType,
            data: json["data"] as? [String: Any] ?? [:],
            timestamp: Date()
        )
        
        deviceEventSubject.send(event)
    }
    
    private func handleDiscoveryMessage(_ json: [String: Any]) {
        guard let deviceInfo = parseDeviceInfoFromDiscovery(json) else {
            return
        }
        
        let discoveredDevice = DiscoveredDevice(
            deviceInfo: deviceInfo,
            discoveryMethod: "MQTT Discovery",
            discoveryTime: Date(),
            signalStrength: json["signalStrength"] as? Int
        )
        
        discoveredDeviceSubject.send(discoveredDevice)
    }
    
    // MARK: - Helper Methods
    
    private func subscribeToSystemTopics() {
        let systemTopics = [
            MQTTTopics.deviceDiscovery,
            MQTTTopics.deviceStatus,
            MQTTTopics.deviceResponse,
            MQTTTopics.deviceEvents
        ]
        
        mqttManager.subscribe(to: systemTopics)
        
        for topic in systemTopics {
            subscribedTopics.insert(topic)
        }
    }
    
    private func extractDeviceIdFromTopic(_ topic: String) -> String? {
        let components = topic.split(separator: "/")
        guard components.count >= 2, components[0] == "devices" else {
            return nil
        }
        return String(components[1])
    }
    
    private func parseDeviceInfoFromDiscovery(_ json: [String: Any]) -> DeviceInfo? {
        guard let deviceId = json["deviceId"] as? String,
              let deviceName = json["deviceName"] as? String,
              let deviceTypeString = json["deviceType"] as? String,
              let deviceType = DeviceType(rawValue: deviceTypeString) else {
            return nil
        }
        
        return DeviceInfo(
            deviceId: deviceId,
            deviceName: deviceName,
            deviceType: deviceType,
            manufacturer: json["manufacturer"] as? String ?? "Unknown",
            modelNumber: json["modelNumber"] as? String ?? "MQTT-\(deviceType.rawValue)",
            firmwareVersion: json["firmwareVersion"] as? String ?? "1.0.0",
            capabilities: parseCapabilities(json["capabilities"] as? [String] ?? []),
            connectionInfo: [
                "protocol": "MQTT",
                "topic": MQTTTopics.controlTopic(for: deviceId)
            ]
        )
    }
    
    private func parseCapabilities(_ capabilityStrings: [String]) -> [DeviceCapability] {
        return capabilityStrings.compactMap { DeviceCapability(rawValue: $0) }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - MQTT Notification Extension

extension Notification.Name {
    static let mqttMessageReceived = Notification.Name("MQTTMessageReceived")
}