//
//  EnergyStorage.swift
//  DomainLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

/// 储能设备模型
public struct EnergyStorage: Device, Connectable, Controllable, Codable {
    
    // MARK: - Device Properties
    public let id: String
    public var name: String
    public let modelName: String
    public let firmwareVersion: String
    public let manufacturer: String
    public let serialNumber: String
    public let dateAdded: Date
    public var lastUpdated: Date
    public var isOnline: Bool
    public let deviceType: DeviceType = .energyStorage
    
    // MARK: - Connectable Properties
    public var connectionState: ConnectionState
    public var rssi: Int?
    public var networkType: NetworkType
    public var ipAddress: String?
    public var macAddress: String?
    public var lastConnectedAt: Date?
    
    // MARK: - Controllable Properties
    public var deviceState: DeviceState
    public var currentCommand: DeviceCommand?
    public var commandExecutionState: CommandExecutionState
    public var lastExecutedCommand: DeviceCommand?
    public var lastCommandExecutedAt: Date?
    
    // MARK: - EnergyStorage Specific Properties
    /// 电池容量（kWh）
    public let batteryCapacity: Double
    
    /// 当前电量（kWh）
    public var currentEnergy: Double
    
    /// 电量百分比（0-100）
    public var chargeLevel: Int {
        return Int((currentEnergy / batteryCapacity) * 100)
    }
    
    /// 充电状态
    public var chargingState: ChargingState
    
    /// 放电状态
    public var dischargingState: DischargingState
    
    /// 当前功率（kW，正值为充电，负值为放电）
    public var currentPower: Double
    
    /// 最大充电功率（kW）
    public let maxChargingPower: Double
    
    /// 最大放电功率（kW）
    public let maxDischargingPower: Double
    
    /// 电池电压（V）
    public var batteryVoltage: Double?
    
    /// 电池电流（A）
    public var batteryCurrent: Double?
    
    /// 电池温度（摄氏度）
    public var batteryTemperature: Double?
    
    /// 电池健康度（0-100%）
    public var batteryHealth: Int
    
    /// 电池循环次数
    public var batteryCycles: Int
    
    /// 工作模式
    public var operatingMode: OperatingMode
    
    /// 能源管理策略
    public var energyStrategy: EnergyStrategy
    
    /// 充电开始时间
    public var chargingStartedAt: Date?
    
    /// 放电开始时间
    public var dischargingStartedAt: Date?
    
    /// 预计充满时间
    public var estimatedFullChargeTime: TimeInterval?
    
    /// 预计放电完成时间
    public var estimatedEmptyTime: TimeInterval?
    
    /// 能源使用历史
    public var energyHistory: [EnergyRecord]
    
    /// 性能统计
    public var performanceStats: PerformanceStats
    
    /// 告警信息
    public var alerts: [EnergyAlert]
    
    /// 维护信息
    public var maintenanceInfo: MaintenanceInfo
    
    // MARK: - Publishers (非Codable，运行时创建)
    private var _connectionStateSubject = PassthroughSubject<ConnectionState, Never>()
    private var _deviceStateSubject = PassthroughSubject<DeviceState, Never>()
    private var _commandExecutionSubject = PassthroughSubject<CommandExecutionState, Never>()
    private var _energyDataSubject = PassthroughSubject<EnergyData, Never>()
    
    public var connectionStatePublisher: AnyPublisher<ConnectionState, Never> {
        _connectionStateSubject.eraseToAnyPublisher()
    }
    
    public var deviceStatePublisher: AnyPublisher<DeviceState, Never> {
        _deviceStateSubject.eraseToAnyPublisher()
    }
    
    public var commandExecutionPublisher: AnyPublisher<CommandExecutionState, Never> {
        _commandExecutionSubject.eraseToAnyPublisher()
    }
    
    public var energyDataPublisher: AnyPublisher<EnergyData, Never> {
        _energyDataSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Supported Commands
    public let supportedCommands: [DeviceCommand] = [
        .start, .stop, .pause, .resume, .reset,
        .startCharging, .stopCharging, .startDischarging, .stopDischarging
    ]
    
    // MARK: - Computed Properties
    /// 剩余充电时间（小时）
    public var remainingChargeTime: TimeInterval? {
        guard chargingState == .charging, currentPower > 0 else { return nil }
        let remainingEnergy = batteryCapacity - currentEnergy
        return (remainingEnergy / currentPower) * 3600
    }
    
    /// 剩余放电时间（小时）
    public var remainingDischargeTime: TimeInterval? {
        guard dischargingState == .discharging, currentPower < 0 else { return nil }
        return (currentEnergy / abs(currentPower)) * 3600
    }
    
    /// 能效比（%）
    public var efficiency: Double {
        return performanceStats.averageEfficiency
    }
    
    // MARK: - Initializer
    public init(
        id: String,
        name: String,
        modelName: String,
        firmwareVersion: String,
        manufacturer: String,
        serialNumber: String,
        batteryCapacity: Double,
        maxChargingPower: Double,
        maxDischargingPower: Double
    ) {
        self.id = id
        self.name = name
        self.modelName = modelName
        self.firmwareVersion = firmwareVersion
        self.manufacturer = manufacturer
        self.serialNumber = serialNumber
        self.dateAdded = Date()
        self.lastUpdated = Date()
        self.isOnline = false
        
        // 储能设备特定属性
        self.batteryCapacity = batteryCapacity
        self.maxChargingPower = maxChargingPower
        self.maxDischargingPower = maxDischargingPower
        self.currentEnergy = batteryCapacity * 0.5 // 默认50%电量
        
        // 默认连接状态
        self.connectionState = .disconnected
        self.networkType = .wifi
        
        // 默认设备状态
        self.deviceState = .idle
        self.commandExecutionState = .idle
        
        // 默认储能状态
        self.chargingState = .idle
        self.dischargingState = .idle
        self.currentPower = 0.0
        self.batteryHealth = 100
        self.batteryCycles = 0
        self.operatingMode = .auto
        self.energyStrategy = .balanced
        
        self.energyHistory = []
        self.performanceStats = PerformanceStats()
        self.alerts = []
        self.maintenanceInfo = MaintenanceInfo()
    }
    
    // MARK: - Controllable Implementation
    public func executeCommand(_ command: DeviceCommand) -> AnyPublisher<CommandResult, DeviceError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown("设备实例已释放")))
                return
            }
            
            guard self.supportsCommand(command) else {
                promise(.failure(.commandNotSupported(command)))
                return
            }
            
            guard self.canExecuteCommand else {
                promise(.failure(.deviceBusy))
                return
            }
            
            // 检查特殊条件
            switch command {
            case .startCharging:
                if self.chargeLevel >= 100 {
                    promise(.failure(.deviceError("电池已满，无需充电")))
                    return
                }
            case .startDischarging:
                if self.chargeLevel <= 10 {
                    promise(.failure(.deviceError("电量过低，无法放电")))
                    return
                }
            default:
                break
            }
            
            // 模拟命令执行
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                let result = CommandResult(
                    command: command,
                    success: true,
                    message: "命令执行成功"
                )
                promise(.success(result))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func cancelCurrentCommand() -> AnyPublisher<Void, DeviceError> {
        return Future { promise in
            // 模拟取消命令
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - EnergyStorage Enums

/// 充电状态
public enum ChargingState: String, CaseIterable, Codable {
    case idle = "idle"
    case charging = "charging"
    case completed = "completed"
    case error = "error"
    case paused = "paused"
    
    public var displayName: String {
        switch self {
        case .idle: return "空闲"
        case .charging: return "充电中"
        case .completed: return "充电完成"
        case .error: return "充电错误"
        case .paused: return "充电暂停"
        }
    }
}

/// 放电状态
public enum DischargingState: String, CaseIterable, Codable {
    case idle = "idle"
    case discharging = "discharging"
    case completed = "completed"
    case error = "error"
    case paused = "paused"
    
    public var displayName: String {
        switch self {
        case .idle: return "空闲"
        case .discharging: return "放电中"
        case .completed: return "放电完成"
        case .error: return "放电错误"
        case .paused: return "放电暂停"
        }
    }
}

/// 工作模式
public enum OperatingMode: String, CaseIterable, Codable {
    case auto = "auto"
    case manual = "manual"
    case scheduled = "scheduled"
    case emergency = "emergency"
    case maintenance = "maintenance"
    
    public var displayName: String {
        switch self {
        case .auto: return "自动模式"
        case .manual: return "手动模式"
        case .scheduled: return "定时模式"
        case .emergency: return "应急模式"
        case .maintenance: return "维护模式"
        }
    }
}

/// 能源管理策略
public enum EnergyStrategy: String, CaseIterable, Codable {
    case balanced = "balanced"
    case performance = "performance"
    case economy = "economy"
    case longevity = "longevity"
    case custom = "custom"
    
    public var displayName: String {
        switch self {
        case .balanced: return "平衡模式"
        case .performance: return "性能模式"
        case .economy: return "经济模式"
        case .longevity: return "长寿命模式"
        case .custom: return "自定义模式"
        }
    }
    
    public var description: String {
        switch self {
        case .balanced: return "平衡充放电效率和电池寿命"
        case .performance: return "优先考虑充放电性能"
        case .economy: return "优先考虑经济效益"
        case .longevity: return "优先考虑电池寿命"
        case .custom: return "用户自定义策略"
        }
    }
}

// MARK: - Supporting Structures

/// 能源数据
public struct EnergyData: Codable {
    public let timestamp: Date
    public let energy: Double // kWh
    public let power: Double // kW
    public let voltage: Double? // V
    public let current: Double? // A
    public let temperature: Double? // °C
    public let efficiency: Double? // %
    
    public init(energy: Double, power: Double, voltage: Double? = nil, current: Double? = nil, temperature: Double? = nil, efficiency: Double? = nil) {
        self.timestamp = Date()
        self.energy = energy
        self.power = power
        self.voltage = voltage
        self.current = current
        self.temperature = temperature
        self.efficiency = efficiency
    }
}

/// 能源记录
public struct EnergyRecord: Codable, Identifiable {
    public let id: String
    public let startTime: Date
    public let endTime: Date?
    public let type: EnergyRecordType
    public let startEnergy: Double
    public let endEnergy: Double?
    public let averagePower: Double?
    public let peakPower: Double?
    public let efficiency: Double?
    public let cost: Double? // 成本或收益
    public let notes: String?
    
    public init(
        id: String = UUID().uuidString,
        startTime: Date,
        endTime: Date? = nil,
        type: EnergyRecordType,
        startEnergy: Double,
        endEnergy: Double? = nil,
        averagePower: Double? = nil,
        peakPower: Double? = nil,
        efficiency: Double? = nil,
        cost: Double? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.type = type
        self.startEnergy = startEnergy
        self.endEnergy = endEnergy
        self.averagePower = averagePower
        self.peakPower = peakPower
        self.efficiency = efficiency
        self.cost = cost
        self.notes = notes
    }
    
    /// 持续时间
    public var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    /// 能源变化量
    public var energyChange: Double? {
        guard let endEnergy = endEnergy else { return nil }
        return endEnergy - startEnergy
    }
}

/// 能源记录类型
public enum EnergyRecordType: String, CaseIterable, Codable {
    case charging = "charging"
    case discharging = "discharging"
    case idle = "idle"
    case maintenance = "maintenance"
    
    public var displayName: String {
        switch self {
        case .charging: return "充电"
        case .discharging: return "放电"
        case .idle: return "待机"
        case .maintenance: return "维护"
        }
    }
}

/// 性能统计
public struct PerformanceStats: Codable {
    /// 总充电次数
    public var totalChargeCycles: Int
    
    /// 总放电次数
    public var totalDischargeCycles: Int
    
    /// 总充电量（kWh）
    public var totalChargedEnergy: Double
    
    /// 总放电量（kWh）
    public var totalDischargedEnergy: Double
    
    /// 平均效率（%）
    public var averageEfficiency: Double
    
    /// 最大充电功率记录（kW）
    public var maxChargingPowerRecord: Double
    
    /// 最大放电功率记录（kW）
    public var maxDischargingPowerRecord: Double
    
    /// 运行时间（小时）
    public var totalOperatingHours: Double
    
    /// 最后更新时间
    public var lastUpdated: Date
    
    public init() {
        self.totalChargeCycles = 0
        self.totalDischargeCycles = 0
        self.totalChargedEnergy = 0.0
        self.totalDischargedEnergy = 0.0
        self.averageEfficiency = 95.0
        self.maxChargingPowerRecord = 0.0
        self.maxDischargingPowerRecord = 0.0
        self.totalOperatingHours = 0.0
        self.lastUpdated = Date()
    }
}

/// 能源告警
public struct EnergyAlert: Codable, Identifiable {
    public let id: String
    public let type: AlertType
    public let severity: AlertSeverity
    public let message: String
    public let timestamp: Date
    public var isAcknowledged: Bool
    public var acknowledgedAt: Date?
    public let data: [String: Double]? // 相关数据
    
    public init(
        id: String = UUID().uuidString,
        type: AlertType,
        severity: AlertSeverity,
        message: String,
        data: [String: Double]? = nil
    ) {
        self.id = id
        self.type = type
        self.severity = severity
        self.message = message
        self.timestamp = Date()
        self.isAcknowledged = false
        self.data = data
    }
}

/// 告警类型
public enum AlertType: String, CaseIterable, Codable {
    case lowBattery = "low_battery"
    case highTemperature = "high_temperature"
    case overCurrent = "over_current"
    case underVoltage = "under_voltage"
    case overVoltage = "over_voltage"
    case chargingError = "charging_error"
    case dischargingError = "discharging_error"
    case communicationError = "communication_error"
    case maintenanceRequired = "maintenance_required"
    
    public var displayName: String {
        switch self {
        case .lowBattery: return "电量低"
        case .highTemperature: return "温度过高"
        case .overCurrent: return "电流过大"
        case .underVoltage: return "电压过低"
        case .overVoltage: return "电压过高"
        case .chargingError: return "充电错误"
        case .dischargingError: return "放电错误"
        case .communicationError: return "通信错误"
        case .maintenanceRequired: return "需要维护"
        }
    }
}

/// 告警严重程度
public enum AlertSeverity: String, CaseIterable, Codable {
    case info = "info"
    case warning = "warning"
    case error = "error"
    case critical = "critical"
    
    public var displayName: String {
        switch self {
        case .info: return "信息"
        case .warning: return "警告"
        case .error: return "错误"
        case .critical: return "严重"
        }
    }
    
    public var colorName: String {
        switch self {
        case .info: return "blue"
        case .warning: return "yellow"
        case .error: return "orange"
        case .critical: return "red"
        }
    }
}

/// 维护信息
public struct MaintenanceInfo: Codable {
    /// 下次维护日期
    public var nextMaintenanceDate: Date?
    
    /// 维护间隔（天）
    public var maintenanceInterval: Int
    
    /// 最后维护日期
    public var lastMaintenanceDate: Date?
    
    /// 维护记录
    public var maintenanceRecords: [MaintenanceRecord]
    
    /// 维护提醒
    public var reminders: [MaintenanceReminder]
    
    public init() {
        self.maintenanceInterval = 90 // 默认90天
        self.maintenanceRecords = []
        self.reminders = []
    }
    
    /// 是否需要维护
    public var needsMaintenance: Bool {
        guard let nextDate = nextMaintenanceDate else { return true }
        return Date() >= nextDate
    }
    
    /// 距离下次维护的天数
    public var daysUntilMaintenance: Int? {
        guard let nextDate = nextMaintenanceDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day
        return days
    }
}

/// 维护记录
public struct MaintenanceRecord: Codable, Identifiable {
    public let id: String
    public let date: Date
    public let type: MaintenanceType
    public let description: String
    public let technician: String?
    public let cost: Double?
    public let partsReplaced: [String]?
    public let notes: String?
    
    public init(
        id: String = UUID().uuidString,
        date: Date,
        type: MaintenanceType,
        description: String,
        technician: String? = nil,
        cost: Double? = nil,
        partsReplaced: [String]? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.description = description
        self.technician = technician
        self.cost = cost
        self.partsReplaced = partsReplaced
        self.notes = notes
    }
}

/// 维护类型
public enum MaintenanceType: String, CaseIterable, Codable {
    case routine = "routine"
    case preventive = "preventive"
    case corrective = "corrective"
    case emergency = "emergency"
    case upgrade = "upgrade"
    
    public var displayName: String {
        switch self {
        case .routine: return "常规维护"
        case .preventive: return "预防性维护"
        case .corrective: return "纠正性维护"
        case .emergency: return "紧急维护"
        case .upgrade: return "升级维护"
        }
    }
}

/// 维护提醒
public struct MaintenanceReminder: Codable, Identifiable {
    public let id: String
    public let type: MaintenanceType
    public let message: String
    public let dueDate: Date
    public let priority: MaintenancePriority
    public var isCompleted: Bool
    public var completedAt: Date?
    
    public init(
        id: String = UUID().uuidString,
        type: MaintenanceType,
        message: String,
        dueDate: Date,
        priority: MaintenancePriority
    ) {
        self.id = id
        self.type = type
        self.message = message
        self.dueDate = dueDate
        self.priority = priority
        self.isCompleted = false
    }
    
    /// 是否过期
    public var isOverdue: Bool {
        return !isCompleted && Date() > dueDate
    }
}

/// 维护优先级
public enum MaintenancePriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    public var displayName: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        case .urgent: return "紧急"
        }
    }
}