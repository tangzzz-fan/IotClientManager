//
//  DeviceControlModels.swift
//  DeviceControlModule
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

// MARK: - Device Models

/// 设备类型
public enum DeviceType: String, CaseIterable, Codable {
    case light = "light"
    case switch = "switch"
    case dimmer = "dimmer"
    case colorLight = "color_light"
    case thermostat = "thermostat"
    case sensor = "sensor"
    case camera = "camera"
    case lock = "lock"
    case curtain = "curtain"
    case fan = "fan"
    case airConditioner = "air_conditioner"
    case heater = "heater"
    case speaker = "speaker"
    case tv = "tv"
    case gateway = "gateway"
    case unknown = "unknown"
    
    public var displayName: String {
        switch self {
        case .light: return "灯光"
        case .switch: return "开关"
        case .dimmer: return "调光器"
        case .colorLight: return "彩色灯"
        case .thermostat: return "温控器"
        case .sensor: return "传感器"
        case .camera: return "摄像头"
        case .lock: return "门锁"
        case .curtain: return "窗帘"
        case .fan: return "风扇"
        case .airConditioner: return "空调"
        case .heater: return "加热器"
        case .speaker: return "音响"
        case .tv: return "电视"
        case .gateway: return "网关"
        case .unknown: return "未知设备"
        }
    }
}

/// 设备连接状态
public enum DeviceConnectionState: String, CaseIterable, Codable {
    case disconnected = "disconnected"
    case connecting = "connecting"
    case connected = "connected"
    case reconnecting = "reconnecting"
    case failed = "failed"
    case timeout = "timeout"
    
    public var isConnected: Bool {
        return self == .connected
    }
    
    public var canExecuteCommands: Bool {
        return self == .connected
    }
}

/// 设备控制状态
public enum DeviceControlState: String, CaseIterable, Codable {
    case idle = "idle"
    case executing = "executing"
    case busy = "busy"
    case error = "error"
    case maintenance = "maintenance"
    case offline = "offline"
    
    public var canAcceptCommands: Bool {
        switch self {
        case .idle:
            return true
        case .executing, .busy, .error, .maintenance, .offline:
            return false
        }
    }
}

/// 设备信息
public struct DeviceInfo: Codable, Equatable {
    public let deviceId: String
    public let name: String
    public let deviceType: DeviceType
    public let manufacturer: String
    public let model: String
    public let firmwareVersion: String
    public let hardwareVersion: String
    public let serialNumber: String
    public let macAddress: String?
    public let ipAddress: String?
    public let capabilities: [DeviceCapability]
    public let metadata: [String: String]
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(deviceId: String, name: String, deviceType: DeviceType, manufacturer: String, model: String, firmwareVersion: String, hardwareVersion: String, serialNumber: String, macAddress: String? = nil, ipAddress: String? = nil, capabilities: [DeviceCapability] = [], metadata: [String: String] = [:], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.deviceId = deviceId
        self.name = name
        self.deviceType = deviceType
        self.manufacturer = manufacturer
        self.model = model
        self.firmwareVersion = firmwareVersion
        self.hardwareVersion = hardwareVersion
        self.serialNumber = serialNumber
        self.macAddress = macAddress
        self.ipAddress = ipAddress
        self.capabilities = capabilities
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// 设备能力
public struct DeviceCapability: Codable, Equatable {
    public let capabilityId: String
    public let name: String
    public let type: CapabilityType
    public let parameters: [String: Any]
    public let isSupported: Bool
    
    public init(capabilityId: String, name: String, type: CapabilityType, parameters: [String: Any] = [:], isSupported: Bool = true) {
        self.capabilityId = capabilityId
        self.name = name
        self.type = type
        self.parameters = parameters
        self.isSupported = isSupported
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        capabilityId = try container.decode(String.self, forKey: .capabilityId)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(CapabilityType.self, forKey: .type)
        isSupported = try container.decode(Bool.self, forKey: .isSupported)
        
        if let parametersData = try container.decodeIfPresent(Data.self, forKey: .parameters) {
            parameters = (try? JSONSerialization.jsonObject(with: parametersData) as? [String: Any]) ?? [:]
        } else {
            parameters = [:]
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(capabilityId, forKey: .capabilityId)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(isSupported, forKey: .isSupported)
        
        if let parametersData = try? JSONSerialization.data(withJSONObject: parameters) {
            try container.encode(parametersData, forKey: .parameters)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case capabilityId, name, type, parameters, isSupported
    }
}

/// 能力类型
public enum CapabilityType: String, CaseIterable, Codable {
    case switch = "switch"
    case dimming = "dimming"
    case colorControl = "color_control"
    case temperatureControl = "temperature_control"
    case motionDetection = "motion_detection"
    case lightSensing = "light_sensing"
    case soundDetection = "sound_detection"
    case doorLock = "door_lock"
    case curtainControl = "curtain_control"
    case fanControl = "fan_control"
    case timerControl = "timer_control"
    case sceneControl = "scene_control"
    case groupControl = "group_control"
    case statusReporting = "status_reporting"
    case firmwareUpdate = "firmware_update"
}

/// 设备状态
public struct DeviceStatus: Codable, Equatable {
    public let deviceId: String
    public let connectionState: DeviceConnectionState
    public let controlState: DeviceControlState
    public let properties: [String: Any]
    public let lastUpdateTime: Date
    public let batteryLevel: Int?
    public let signalStrength: Int?
    public let errorCode: String?
    public let errorMessage: String?
    
    public init(deviceId: String, connectionState: DeviceConnectionState, controlState: DeviceControlState, properties: [String: Any] = [:], lastUpdateTime: Date = Date(), batteryLevel: Int? = nil, signalStrength: Int? = nil, errorCode: String? = nil, errorMessage: String? = nil) {
        self.deviceId = deviceId
        self.connectionState = connectionState
        self.controlState = controlState
        self.properties = properties
        self.lastUpdateTime = lastUpdateTime
        self.batteryLevel = batteryLevel
        self.signalStrength = signalStrength
        self.errorCode = errorCode
        self.errorMessage = errorMessage
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        deviceId = try container.decode(String.self, forKey: .deviceId)
        connectionState = try container.decode(DeviceConnectionState.self, forKey: .connectionState)
        controlState = try container.decode(DeviceControlState.self, forKey: .controlState)
        lastUpdateTime = try container.decode(Date.self, forKey: .lastUpdateTime)
        batteryLevel = try container.decodeIfPresent(Int.self, forKey: .batteryLevel)
        signalStrength = try container.decodeIfPresent(Int.self, forKey: .signalStrength)
        errorCode = try container.decodeIfPresent(String.self, forKey: .errorCode)
        errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        
        if let propertiesData = try container.decodeIfPresent(Data.self, forKey: .properties) {
            properties = (try? JSONSerialization.jsonObject(with: propertiesData) as? [String: Any]) ?? [:]
        } else {
            properties = [:]
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encode(connectionState, forKey: .connectionState)
        try container.encode(controlState, forKey: .controlState)
        try container.encode(lastUpdateTime, forKey: .lastUpdateTime)
        try container.encodeIfPresent(batteryLevel, forKey: .batteryLevel)
        try container.encodeIfPresent(signalStrength, forKey: .signalStrength)
        try container.encodeIfPresent(errorCode, forKey: .errorCode)
        try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
        
        if let propertiesData = try? JSONSerialization.data(withJSONObject: properties) {
            try container.encode(propertiesData, forKey: .properties)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case deviceId, connectionState, controlState, properties, lastUpdateTime, batteryLevel, signalStrength, errorCode, errorMessage
    }
}

// MARK: - Command Models

/// 设备命令类型
public enum DeviceCommandType: String, CaseIterable, Codable {
    case switchOn = "switch_on"
    case switchOff = "switch_off"
    case toggle = "toggle"
    case setBrightness = "set_brightness"
    case setColor = "set_color"
    case setTemperature = "set_temperature"
    case setScene = "set_scene"
    case setTimer = "set_timer"
    case getStatus = "get_status"
    case reset = "reset"
    case reboot = "reboot"
    case updateFirmware = "update_firmware"
    case lock = "lock"
    case unlock = "unlock"
    case open = "open"
    case close = "close"
    case stop = "stop"
    case pause = "pause"
    case resume = "resume"
    case custom = "custom"
    
    public var displayName: String {
        switch self {
        case .switchOn: return "开启"
        case .switchOff: return "关闭"
        case .toggle: return "切换"
        case .setBrightness: return "设置亮度"
        case .setColor: return "设置颜色"
        case .setTemperature: return "设置温度"
        case .setScene: return "设置场景"
        case .setTimer: return "设置定时"
        case .getStatus: return "获取状态"
        case .reset: return "重置"
        case .reboot: return "重启"
        case .updateFirmware: return "固件更新"
        case .lock: return "锁定"
        case .unlock: return "解锁"
        case .open: return "打开"
        case .close: return "关闭"
        case .stop: return "停止"
        case .pause: return "暂停"
        case .resume: return "恢复"
        case .custom: return "自定义"
        }
    }
}

/// 命令优先级
public enum CommandPriority: Int, CaseIterable, Codable {
    case low = 0
    case normal = 1
    case high = 2
    case urgent = 3
    case critical = 4
    
    public var displayName: String {
        switch self {
        case .low: return "低"
        case .normal: return "普通"
        case .high: return "高"
        case .urgent: return "紧急"
        case .critical: return "关键"
        }
    }
}

/// 设备命令
public struct DeviceCommand: DeviceCommandProtocol, Codable, Equatable {
    public let commandId: String
    public let commandType: DeviceCommandType
    public let targetDeviceId: String
    public let parameters: [String: Any]
    public let priority: CommandPriority
    public let timeout: TimeInterval
    public let retryCount: Int
    public let createdAt: Date
    public private(set) var executedAt: Date?
    public private(set) var completedAt: Date?
    public private(set) var status: CommandStatus
    
    public init(commandId: String = UUID().uuidString, commandType: DeviceCommandType, targetDeviceId: String, parameters: [String: Any] = [:], priority: CommandPriority = .normal, timeout: TimeInterval = 30.0, retryCount: Int = 3) {
        self.commandId = commandId
        self.commandType = commandType
        self.targetDeviceId = targetDeviceId
        self.parameters = parameters
        self.priority = priority
        self.timeout = timeout
        self.retryCount = retryCount
        self.createdAt = Date()
        self.status = .pending
    }
    
    public func execute() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        // 实际执行逻辑将在具体的命令执行器中实现
        return Fail(error: DeviceControlError.commandExecutionFailed("Command execution not implemented"))
            .eraseToAnyPublisher()
    }
    
    public func cancel() {
        // 取消命令逻辑
    }
    
    public func validateParameters() -> Bool {
        // 验证命令参数
        switch commandType {
        case .setBrightness:
            guard let brightness = parameters["brightness"] as? Int,
                  brightness >= 0 && brightness <= 100 else {
                return false
            }
        case .setColor:
            guard parameters["color"] != nil else {
                return false
            }
        case .setTemperature:
            guard let temperature = parameters["temperature"] as? Double else {
                return false
            }
        default:
            break
        }
        return true
    }
    
    public func getDescription() -> String {
        return "\(commandType.displayName) - 设备: \(targetDeviceId)"
    }
    
    public mutating func markAsExecuting() {
        status = .executing
        executedAt = Date()
    }
    
    public mutating func markAsCompleted() {
        status = .completed
        completedAt = Date()
    }
    
    public mutating func markAsFailed() {
        status = .failed
        completedAt = Date()
    }
    
    // Codable implementation
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        commandId = try container.decode(String.self, forKey: .commandId)
        commandType = try container.decode(DeviceCommandType.self, forKey: .commandType)
        targetDeviceId = try container.decode(String.self, forKey: .targetDeviceId)
        priority = try container.decode(CommandPriority.self, forKey: .priority)
        timeout = try container.decode(TimeInterval.self, forKey: .timeout)
        retryCount = try container.decode(Int.self, forKey: .retryCount)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        executedAt = try container.decodeIfPresent(Date.self, forKey: .executedAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        status = try container.decode(CommandStatus.self, forKey: .status)
        
        if let parametersData = try container.decodeIfPresent(Data.self, forKey: .parameters) {
            parameters = (try? JSONSerialization.jsonObject(with: parametersData) as? [String: Any]) ?? [:]
        } else {
            parameters = [:]
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(commandId, forKey: .commandId)
        try container.encode(commandType, forKey: .commandType)
        try container.encode(targetDeviceId, forKey: .targetDeviceId)
        try container.encode(priority, forKey: .priority)
        try container.encode(timeout, forKey: .timeout)
        try container.encode(retryCount, forKey: .retryCount)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(executedAt, forKey: .executedAt)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encode(status, forKey: .status)
        
        if let parametersData = try? JSONSerialization.data(withJSONObject: parameters) {
            try container.encode(parametersData, forKey: .parameters)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case commandId, commandType, targetDeviceId, parameters, priority, timeout, retryCount, createdAt, executedAt, completedAt, status
    }
}

/// 命令状态
public enum CommandStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case executing = "executing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    case timeout = "timeout"
}

/// 批量命令
public struct BatchCommand: Codable, Equatable {
    public let batchId: String
    public let commands: [DeviceCommand]
    public let executionMode: BatchExecutionMode
    public let createdAt: Date
    public private(set) var status: BatchCommandStatus
    public private(set) var results: [DeviceCommandResult]
    
    public init(batchId: String = UUID().uuidString, commands: [DeviceCommand], executionMode: BatchExecutionMode = .sequential) {
        self.batchId = batchId
        self.commands = commands
        self.executionMode = executionMode
        self.createdAt = Date()
        self.status = .pending
        self.results = []
    }
}

/// 批量执行模式
public enum BatchExecutionMode: String, CaseIterable, Codable {
    case sequential = "sequential"  // 顺序执行
    case parallel = "parallel"      // 并行执行
    case conditional = "conditional" // 条件执行
}

/// 批量命令状态
public enum BatchCommandStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case executing = "executing"
    case completed = "completed"
    case partiallyCompleted = "partially_completed"
    case failed = "failed"
    case cancelled = "cancelled"
}

/// 设备命令结果
public struct DeviceCommandResult: Codable, Equatable {
    public let commandId: String
    public let deviceId: String
    public let success: Bool
    public let resultData: [String: Any]?
    public let errorCode: String?
    public let errorMessage: String?
    public let executionTime: TimeInterval
    public let timestamp: Date
    
    public init(commandId: String, deviceId: String, success: Bool, resultData: [String: Any]? = nil, errorCode: String? = nil, errorMessage: String? = nil, executionTime: TimeInterval = 0, timestamp: Date = Date()) {
        self.commandId = commandId
        self.deviceId = deviceId
        self.success = success
        self.resultData = resultData
        self.errorCode = errorCode
        self.errorMessage = errorMessage
        self.executionTime = executionTime
        self.timestamp = timestamp
    }
    
    // Codable implementation
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        commandId = try container.decode(String.self, forKey: .commandId)
        deviceId = try container.decode(String.self, forKey: .deviceId)
        success = try container.decode(Bool.self, forKey: .success)
        errorCode = try container.decodeIfPresent(String.self, forKey: .errorCode)
        errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        executionTime = try container.decode(TimeInterval.self, forKey: .executionTime)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        if let resultDataEncoded = try container.decodeIfPresent(Data.self, forKey: .resultData) {
            resultData = try? JSONSerialization.jsonObject(with: resultDataEncoded) as? [String: Any]
        } else {
            resultData = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(commandId, forKey: .commandId)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encode(success, forKey: .success)
        try container.encodeIfPresent(errorCode, forKey: .errorCode)
        try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
        try container.encode(executionTime, forKey: .executionTime)
        try container.encode(timestamp, forKey: .timestamp)
        
        if let resultData = resultData,
           let resultDataEncoded = try? JSONSerialization.data(withJSONObject: resultData) {
            try container.encode(resultDataEncoded, forKey: .resultData)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case commandId, deviceId, success, resultData, errorCode, errorMessage, executionTime, timestamp
    }
}

// MARK: - Queue Models

/// 命令队列类型
public enum CommandQueueType: String, CaseIterable, Codable {
    case fifo = "fifo"           // 先进先出
    case lifo = "lifo"           // 后进先出
    case priority = "priority"   // 优先级队列
    case custom = "custom"       // 自定义排序
}

/// 命令队列状态
public enum CommandQueueState: String, CaseIterable, Codable {
    case idle = "idle"
    case processing = "processing"
    case paused = "paused"
    case error = "error"
    case full = "full"
}

/// 命令队列
public class CommandQueue: CommandQueueProtocol, ObservableObject {
    public let queueId: String
    public let queueType: CommandQueueType
    public let maxQueueSize: Int
    
    @Published public private(set) var currentQueueSize: Int = 0
    @Published public private(set) var queueState: CommandQueueState = .idle
    
    private var commands: [DeviceCommand] = []
    private let queue = DispatchQueue(label: "command.queue", qos: .userInitiated)
    
    public var queueStatePublisher: AnyPublisher<CommandQueueState, Never> {
        $queueState.eraseToAnyPublisher()
    }
    
    public init(queueId: String = UUID().uuidString, queueType: CommandQueueType = .fifo, maxQueueSize: Int = 100) {
        self.queueId = queueId
        self.queueType = queueType
        self.maxQueueSize = maxQueueSize
    }
    
    public func enqueue(_ command: DeviceCommand) -> Bool {
        return queue.sync {
            guard currentQueueSize < maxQueueSize else {
                queueState = .full
                return false
            }
            
            commands.append(command)
            currentQueueSize = commands.count
            
            if queueType == .priority {
                sortByPriority()
            }
            
            if queueState == .idle {
                queueState = .processing
            }
            
            return true
        }
    }
    
    public func dequeue() -> DeviceCommand? {
        return queue.sync {
            guard !commands.isEmpty else {
                queueState = .idle
                return nil
            }
            
            let command: DeviceCommand
            switch queueType {
            case .fifo, .priority, .custom:
                command = commands.removeFirst()
            case .lifo:
                command = commands.removeLast()
            }
            
            currentQueueSize = commands.count
            
            if commands.isEmpty {
                queueState = .idle
            }
            
            return command
        }
    }
    
    public func peek() -> DeviceCommand? {
        return queue.sync {
            guard !commands.isEmpty else { return nil }
            
            switch queueType {
            case .fifo, .priority, .custom:
                return commands.first
            case .lifo:
                return commands.last
            }
        }
    }
    
    public func remove(_ commandId: String) -> Bool {
        return queue.sync {
            if let index = commands.firstIndex(where: { $0.commandId == commandId }) {
                commands.remove(at: index)
                currentQueueSize = commands.count
                
                if commands.isEmpty {
                    queueState = .idle
                }
                
                return true
            }
            return false
        }
    }
    
    public func clear() {
        queue.sync {
            commands.removeAll()
            currentQueueSize = 0
            queueState = .idle
        }
    }
    
    public func getAllCommands() -> [DeviceCommand] {
        return queue.sync {
            return Array(commands)
        }
    }
    
    public func sortByPriority() {
        queue.sync {
            commands.sort { $0.priority.rawValue > $1.priority.rawValue }
        }
    }
}

// MARK: - Event Models

/// 设备事件类型
public enum DeviceEventType: String, CaseIterable, Codable {
    case statusChanged = "status_changed"
    case propertyUpdated = "property_updated"
    case connectionChanged = "connection_changed"
    case errorOccurred = "error_occurred"
    case commandExecuted = "command_executed"
    case firmwareUpdated = "firmware_updated"
    case batteryLow = "battery_low"
    case motionDetected = "motion_detected"
    case doorOpened = "door_opened"
    case doorClosed = "door_closed"
    case temperatureChanged = "temperature_changed"
    case lightLevelChanged = "light_level_changed"
    case soundDetected = "sound_detected"
    case alarmTriggered = "alarm_triggered"
    case maintenanceRequired = "maintenance_required"
    case custom = "custom"
}

/// 设备事件
public struct DeviceEvent: Codable, Equatable {
    public let eventId: String
    public let deviceId: String
    public let eventType: DeviceEventType
    public let eventData: [String: Any]
    public let timestamp: Date
    public let severity: EventSeverity
    
    public init(eventId: String = UUID().uuidString, deviceId: String, eventType: DeviceEventType, eventData: [String: Any] = [:], timestamp: Date = Date(), severity: EventSeverity = .info) {
        self.eventId = eventId
        self.deviceId = deviceId
        self.eventType = eventType
        self.eventData = eventData
        self.timestamp = timestamp
        self.severity = severity
    }
    
    // Codable implementation
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        eventId = try container.decode(String.self, forKey: .eventId)
        deviceId = try container.decode(String.self, forKey: .deviceId)
        eventType = try container.decode(DeviceEventType.self, forKey: .eventType)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        severity = try container.decode(EventSeverity.self, forKey: .severity)
        
        if let eventDataEncoded = try container.decodeIfPresent(Data.self, forKey: .eventData) {
            eventData = (try? JSONSerialization.jsonObject(with: eventDataEncoded) as? [String: Any]) ?? [:]
        } else {
            eventData = [:]
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventId, forKey: .eventId)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encode(eventType, forKey: .eventType)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(severity, forKey: .severity)
        
        if let eventDataEncoded = try? JSONSerialization.data(withJSONObject: eventData) {
            try container.encode(eventDataEncoded, forKey: .eventData)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case eventId, deviceId, eventType, eventData, timestamp, severity
    }
}

/// 事件严重程度
public enum EventSeverity: String, CaseIterable, Codable {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    case critical = "critical"
}

// MARK: - Property Models

/// 设备属性更新
public struct DevicePropertyUpdate: Codable, Equatable {
    public let deviceId: String
    public let propertyKey: String
    public let oldValue: Any?
    public let newValue: Any
    public let timestamp: Date
    
    public init(deviceId: String, propertyKey: String, oldValue: Any?, newValue: Any, timestamp: Date = Date()) {
        self.deviceId = deviceId
        self.propertyKey = propertyKey
        self.oldValue = oldValue
        self.newValue = newValue
        self.timestamp = timestamp
    }
    
    // Codable implementation
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        deviceId = try container.decode(String.self, forKey: .deviceId)
        propertyKey = try container.decode(String.self, forKey: .propertyKey)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        if let oldValueData = try container.decodeIfPresent(Data.self, forKey: .oldValue) {
            oldValue = try? JSONSerialization.jsonObject(with: oldValueData)
        } else {
            oldValue = nil
        }
        
        if let newValueData = try container.decode(Data?.self, forKey: .newValue) {
            newValue = (try? JSONSerialization.jsonObject(with: newValueData)) ?? NSNull()
        } else {
            newValue = NSNull()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encode(propertyKey, forKey: .propertyKey)
        try container.encode(timestamp, forKey: .timestamp)
        
        if let oldValue = oldValue,
           let oldValueData = try? JSONSerialization.data(withJSONObject: oldValue) {
            try container.encode(oldValueData, forKey: .oldValue)
        }
        
        if let newValueData = try? JSONSerialization.data(withJSONObject: newValue) {
            try container.encode(newValueData, forKey: .newValue)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case deviceId, propertyKey, oldValue, newValue, timestamp
    }
}

/// 设备颜色
public struct DeviceColor: Codable, Equatable {
    public let red: Int
    public let green: Int
    public let blue: Int
    public let alpha: Int
    
    public init(red: Int, green: Int, blue: Int, alpha: Int = 255) {
        self.red = max(0, min(255, red))
        self.green = max(0, min(255, green))
        self.blue = max(0, min(255, blue))
        self.alpha = max(0, min(255, alpha))
    }
    
    public var hexString: String {
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
    
    public static let white = DeviceColor(red: 255, green: 255, blue: 255)
    public static let black = DeviceColor(red: 0, green: 0, blue: 0)
    public static let red = DeviceColor(red: 255, green: 0, blue: 0)
    public static let green = DeviceColor(red: 0, green: 255, blue: 0)
    public static let blue = DeviceColor(red: 0, green: 0, blue: 255)
}

/// 定时器配置
public struct TimerConfiguration: Codable, Equatable {
    public let timerId: String
    public let name: String
    public let triggerTime: Date
    public let repeatMode: TimerRepeatMode
    public let command: DeviceCommand
    public let isEnabled: Bool
    
    public init(timerId: String = UUID().uuidString, name: String, triggerTime: Date, repeatMode: TimerRepeatMode = .once, command: DeviceCommand, isEnabled: Bool = true) {
        self.timerId = timerId
        self.name = name
        self.triggerTime = triggerTime
        self.repeatMode = repeatMode
        self.command = command
        self.isEnabled = isEnabled
    }
}

/// 定时器重复模式
public enum TimerRepeatMode: String, CaseIterable, Codable {
    case once = "once"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case custom = "custom"
}

// MARK: - Error Models

/// 设备控制错误
public enum DeviceControlError: Error, LocalizedError, Equatable {
    case deviceNotFound(String)
    case deviceNotConnected(String)
    case deviceBusy(String)
    case commandNotSupported(String)
    case commandExecutionFailed(String)
    case commandTimeout(String)
    case invalidParameters(String)
    case authenticationFailed(String)
    case permissionDenied(String)
    case networkError(String)
    case protocolError(String)
    case firmwareError(String)
    case hardwareError(String)
    case configurationError(String)
    case serviceUnavailable(String)
    case queueFull(String)
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .deviceNotFound(let message): return "设备未找到: \(message)"
        case .deviceNotConnected(let message): return "设备未连接: \(message)"
        case .deviceBusy(let message): return "设备忙碌: \(message)"
        case .commandNotSupported(let message): return "命令不支持: \(message)"
        case .commandExecutionFailed(let message): return "命令执行失败: \(message)"
        case .commandTimeout(let message): return "命令超时: \(message)"
        case .invalidParameters(let message): return "参数无效: \(message)"
        case .authenticationFailed(let message): return "认证失败: \(message)"
        case .permissionDenied(let message): return "权限被拒绝: \(message)"
        case .networkError(let message): return "网络错误: \(message)"
        case .protocolError(let message): return "协议错误: \(message)"
        case .firmwareError(let message): return "固件错误: \(message)"
        case .hardwareError(let message): return "硬件错误: \(message)"
        case .configurationError(let message): return "配置错误: \(message)"
        case .serviceUnavailable(let message): return "服务不可用: \(message)"
        case .queueFull(let message): return "队列已满: \(message)"
        case .unknown(let message): return "未知错误: \(message)"
        }
    }
    
    public var errorCode: String {
        switch self {
        case .deviceNotFound: return "DCE001"
        case .deviceNotConnected: return "DCE002"
        case .deviceBusy: return "DCE003"
        case .commandNotSupported: return "DCE004"
        case .commandExecutionFailed: return "DCE005"
        case .commandTimeout: return "DCE006"
        case .invalidParameters: return "DCE007"
        case .authenticationFailed: return "DCE008"
        case .permissionDenied: return "DCE009"
        case .networkError: return "DCE010"
        case .protocolError: return "DCE011"
        case .firmwareError: return "DCE012"
        case .hardwareError: return "DCE013"
        case .configurationError: return "DCE014"
        case .serviceUnavailable: return "DCE015"
        case .queueFull: return "DCE016"
        case .unknown: return "DCE999"
        }
    }
}

// MARK: - State Models

/// 命令执行状态
public enum CommandExecutionState: String, CaseIterable, Codable {
    case idle = "idle"
    case executing = "executing"
    case paused = "paused"
    case error = "error"
}

/// 监控状态
public enum MonitoringState: String, CaseIterable, Codable {
    case stopped = "stopped"
    case starting = "starting"
    case running = "running"
    case paused = "paused"
    case error = "error"
}

/// 服务状态
public enum ServiceState: String, CaseIterable, Codable {
    case stopped = "stopped"
    case starting = "starting"
    case running = "running"
    case stopping = "stopping"
    case error = "error"
}

/// 管理器状态
public enum ManagerState: String, CaseIterable, Codable {
    case uninitialized = "uninitialized"
    case initializing = "initializing"
    case initialized = "initialized"
    case starting = "starting"
    case running = "running"
    case stopping = "stopping"
    case stopped = "stopped"
    case error = "error"
}

/// 发现状态
public enum DiscoveryState: String, CaseIterable, Codable {
    case idle = "idle"
    case discovering = "discovering"
    case completed = "completed"
    case error = "error"
}

/// 认证状态
public enum AuthenticationState: String, CaseIterable, Codable {
    case unauthenticated = "unauthenticated"
    case authenticating = "authenticating"
    case authenticated = "authenticated"
    case failed = "failed"
    case expired = "expired"
}

// MARK: - Additional Models

/// 命令执行记录
public struct CommandExecutionRecord: Codable, Equatable {
    public let recordId: String
    public let command: DeviceCommand
    public let result: DeviceCommandResult
    public let executionStartTime: Date
    public let executionEndTime: Date
    public let executorId: String
    
    public init(recordId: String = UUID().uuidString, command: DeviceCommand, result: DeviceCommandResult, executionStartTime: Date, executionEndTime: Date, executorId: String) {
        self.recordId = recordId
        self.command = command
        self.result = result
        self.executionStartTime = executionStartTime
        self.executionEndTime = executionEndTime
        self.executorId = executorId
    }
    
    public var executionDuration: TimeInterval {
        return executionEndTime.timeIntervalSince(executionStartTime)
    }
}

/// 发现的设备
public struct DiscoveredDevice: Codable, Equatable {
    public let deviceId: String
    public let name: String
    public let deviceType: DeviceType
    public let manufacturer: String?
    public let model: String?
    public let signalStrength: Int?
    public let discoveryMethod: String
    public let discoveredAt: Date
    public let metadata: [String: String]
    
    public init(deviceId: String, name: String, deviceType: DeviceType, manufacturer: String? = nil, model: String? = nil, signalStrength: Int? = nil, discoveryMethod: String, discoveredAt: Date = Date(), metadata: [String: String] = [:]) {
        self.deviceId = deviceId
        self.name = name
        self.deviceType = deviceType
        self.manufacturer = manufacturer
        self.model = model
        self.signalStrength = signalStrength
        self.discoveryMethod = discoveryMethod
        self.discoveredAt = discoveredAt
        self.metadata = metadata
    }
}

/// 设备凭据
public struct DeviceCredentials: Codable, Equatable {
    public let deviceId: String
    public let credentialType: CredentialType
    public let credentialData: [String: String]
    public let expiresAt: Date?
    
    public init(deviceId: String, credentialType: CredentialType, credentialData: [String: String], expiresAt: Date? = nil) {
        self.deviceId = deviceId
        self.credentialType = credentialType
        self.credentialData = credentialData
        self.expiresAt = expiresAt
    }
}

/// 凭据类型
public enum CredentialType: String, CaseIterable, Codable {
    case password = "password"
    case token = "token"
    case certificate = "certificate"
    case biometric = "biometric"
    case pin = "pin"
}

/// 认证结果
public struct AuthenticationResult: Codable, Equatable {
    public let deviceId: String
    public let success: Bool
    public let token: String?
    public let expiresAt: Date?
    public let permissions: [DevicePermission]
    public let errorMessage: String?
    
    public init(deviceId: String, success: Bool, token: String? = nil, expiresAt: Date? = nil, permissions: [DevicePermission] = [], errorMessage: String? = nil) {
        self.deviceId = deviceId
        self.success = success
        self.token = token
        self.expiresAt = expiresAt
        self.permissions = permissions
        self.errorMessage = errorMessage
    }
}

/// 设备权限
public struct DevicePermission: Codable, Equatable {
    public let permissionId: String
    public let name: String
    public let description: String
    public let level: PermissionLevel
    
    public init(permissionId: String, name: String, description: String, level: PermissionLevel) {
        self.permissionId = permissionId
        self.name = name
        self.description = description
        self.level = level
    }
}

/// 权限级别
public enum PermissionLevel: String, CaseIterable, Codable {
    case read = "read"
    case write = "write"
    case admin = "admin"
    case owner = "owner"
}

/// 连接类型
public enum ConnectionType: String, CaseIterable, Codable {
    case bluetooth = "bluetooth"
    case wifi = "wifi"
    case zigbee = "zigbee"
    case zwave = "zwave"
    case mqtt = "mqtt"
    case http = "http"
    case tcp = "tcp"
    case udp = "udp"
    case serial = "serial"
}

/// 控制策略类型
public enum ControlStrategyType: String, CaseIterable, Codable {
    case direct = "direct"
    case queued = "queued"
    case batched = "batched"
    case scheduled = "scheduled"
    case conditional = "conditional"
    case adaptive = "adaptive"
}

/// 命令模板
public struct CommandTemplate: Codable, Equatable {
    public let templateId: String
    public let commandType: DeviceCommandType
    public let name: String
    public let description: String
    public let parameterSchema: [String: ParameterDefinition]
    public let defaultValues: [String: Any]
    
    public init(templateId: String, commandType: DeviceCommandType, name: String, description: String, parameterSchema: [String: ParameterDefinition], defaultValues: [String: Any] = [:]) {
        self.templateId = templateId
        self.commandType = commandType
        self.name = name
        self.description = description
        self.parameterSchema = parameterSchema
        self.defaultValues = defaultValues
    }
    
    // Codable implementation
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        templateId = try container.decode(String.self, forKey: .templateId)
        commandType = try container.decode(DeviceCommandType.self, forKey: .commandType)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        parameterSchema = try container.decode([String: ParameterDefinition].self, forKey: .parameterSchema)
        
        if let defaultValuesData = try container.decodeIfPresent(Data.self, forKey: .defaultValues) {
            defaultValues = (try? JSONSerialization.jsonObject(with: defaultValuesData) as? [String: Any]) ?? [:]
        } else {
            defaultValues = [:]
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(templateId, forKey: .templateId)
        try container.encode(commandType, forKey: .commandType)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(parameterSchema, forKey: .parameterSchema)
        
        if let defaultValuesData = try? JSONSerialization.data(withJSONObject: defaultValues) {
            try container.encode(defaultValuesData, forKey: .defaultValues)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case templateId, commandType, name, description, parameterSchema, defaultValues
    }
}

/// 参数定义
public struct ParameterDefinition: Codable, Equatable {
    public let name: String
    public let type: ParameterType
    public let required: Bool
    public let defaultValue: Any?
    public let validation: ParameterValidation?
    public let description: String
    
    public init(name: String, type: ParameterType, required: Bool = false, defaultValue: Any? = nil, validation: ParameterValidation? = nil, description: String = "") {
        self.name = name
        self.type = type
        self.required = required
        self.defaultValue = defaultValue
        self.validation = validation
        self.description = description
    }
    
    // Codable implementation
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(ParameterType.self, forKey: .type)
        required = try container.decode(Bool.self, forKey: .required)
        description = try container.decode(String.self, forKey: .description)
        validation = try container.decodeIfPresent(ParameterValidation.self, forKey: .validation)
        
        if let defaultValueData = try container.decodeIfPresent(Data.self, forKey: .defaultValue) {
            defaultValue = try? JSONSerialization.jsonObject(with: defaultValueData)
        } else {
            defaultValue = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(required, forKey: .required)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(validation, forKey: .validation)
        
        if let defaultValue = defaultValue,
           let defaultValueData = try? JSONSerialization.data(withJSONObject: defaultValue) {
            try container.encode(defaultValueData, forKey: .defaultValue)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, type, required, defaultValue, validation, description
    }
}

/// 参数类型
public enum ParameterType: String, CaseIterable, Codable {
    case string = "string"
    case integer = "integer"
    case double = "double"
    case boolean = "boolean"
    case array = "array"
    case object = "object"
    case color = "color"
    case date = "date"
}

/// 参数验证
public struct ParameterValidation: Codable, Equatable {
    public let minValue: Double?
    public let maxValue: Double?
    public let minLength: Int?
    public let maxLength: Int?
    public let pattern: String?
    public let allowedValues: [String]?
    
    public init(minValue: Double? = nil, maxValue: Double? = nil, minLength: Int? = nil, maxLength: Int? = nil, pattern: String? = nil, allowedValues: [String]? = nil) {
        self.minValue = minValue
        self.maxValue = maxValue
        self.minLength = minLength
        self.maxLength = maxLength
        self.pattern = pattern
        self.allowedValues = allowedValues
    }
}