//
//  PoolRobot.swift
//  DomainLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

/// 泳池机器人设备模型
public struct PoolRobot: Device, Connectable, BatteryPowered, Controllable, Codable {
    
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
    public let deviceType: DeviceType = .poolRobot
    
    // MARK: - Connectable Properties
    public var connectionState: ConnectionState
    public var rssi: Int?
    public var networkType: NetworkType
    public var ipAddress: String?
    public var macAddress: String?
    public var lastConnectedAt: Date?
    
    // MARK: - BatteryPowered Properties
    public var batteryLevel: Int
    public var isCharging: Bool
    public var batteryStatus: BatteryStatus
    public let batteryCapacity: Int
    public var batteryVoltage: Double?
    public var batteryTemperature: Double?
    public var chargingStartedAt: Date?
    public var batteryCycleCount: Int?
    public var batteryHealth: Int?
    
    // MARK: - Controllable Properties
    public var deviceState: DeviceState
    public var currentCommand: DeviceCommand?
    public var commandExecutionState: CommandExecutionState
    public var lastExecutedCommand: DeviceCommand?
    public var lastCommandExecutedAt: Date?
    
    // MARK: - PoolRobot Specific Properties
    /// 清洁模式
    public var cleaningMode: PoolCleaningMode
    
    /// 清洁周期（分钟）
    public var cleaningCycle: Int
    
    /// 过滤器状态
    public var filterStatus: PoolFilterStatus
    
    /// 刷子状态
    public var brushStatus: PoolBrushStatus
    
    /// 水质传感器数据
    public var waterQuality: WaterQuality?
    
    /// 当前深度（米）
    public var currentDepth: Double?
    
    /// 最大工作深度（米）
    public let maxDepth: Double
    
    /// 泳池尺寸设置
    public var poolSize: PoolSize?
    
    /// 清洁路径类型
    public var pathType: CleaningPathType
    
    /// 清洁历史记录
    public var cleaningHistory: [PoolCleaningRecord]
    
    /// 维护提醒
    public var maintenanceReminders: [PoolMaintenanceReminder]
    
    /// 工作时间统计（小时）
    public var totalWorkingHours: Double
    
    /// 清洁覆盖率（百分比）
    public var coverageRate: Double?
    
    // MARK: - Publishers (非Codable，运行时创建)
    private var _connectionStateSubject = PassthroughSubject<ConnectionState, Never>()
    private var _batteryStatusSubject = PassthroughSubject<BatteryStatus, Never>()
    private var _deviceStateSubject = PassthroughSubject<DeviceState, Never>()
    private var _commandExecutionSubject = PassthroughSubject<CommandExecutionState, Never>()
    
    public var connectionStatePublisher: AnyPublisher<ConnectionState, Never> {
        _connectionStateSubject.eraseToAnyPublisher()
    }
    
    public var batteryStatusPublisher: AnyPublisher<BatteryStatus, Never> {
        _batteryStatusSubject.eraseToAnyPublisher()
    }
    
    public var deviceStatePublisher: AnyPublisher<DeviceState, Never> {
        _deviceStateSubject.eraseToAnyPublisher()
    }
    
    public var commandExecutionPublisher: AnyPublisher<CommandExecutionState, Never> {
        _commandExecutionSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Supported Commands
    public let supportedCommands: [DeviceCommand] = [
        .start, .stop, .pause, .resume, .reset,
        .startPoolCleaning, .waterOnlyMode, .floorOnlyMode, .fullCleaningMode
    ]
    
    // MARK: - Computed Properties
    public var estimatedChargingTime: TimeInterval? {
        guard isCharging, batteryLevel < 100 else { return nil }
        let remainingCapacity = Double(100 - batteryLevel) / 100.0 * Double(batteryCapacity)
        return remainingCapacity / 1500.0 * 3600 // 假设1.5A充电电流
    }
    
    /// 预计清洁时间（基于泳池大小和清洁模式）
    public var estimatedCleaningTime: TimeInterval? {
        guard let poolSize = poolSize else { return nil }
        
        let baseTime: TimeInterval
        switch poolSize.type {
        case .small:
            baseTime = 1800 // 30分钟
        case .medium:
            baseTime = 3600 // 60分钟
        case .large:
            baseTime = 5400 // 90分钟
        case .extraLarge:
            baseTime = 7200 // 120分钟
        }
        
        let modeMultiplier: Double
        switch cleaningMode {
        case .quick:
            modeMultiplier = 0.5
        case .standard:
            modeMultiplier = 1.0
        case .deep:
            modeMultiplier = 1.5
        case .eco:
            modeMultiplier = 1.2
        }
        
        return baseTime * modeMultiplier
    }
    
    // MARK: - Initializer
    public init(
        id: String,
        name: String,
        modelName: String,
        firmwareVersion: String,
        manufacturer: String,
        serialNumber: String,
        batteryCapacity: Int = 5000,
        maxDepth: Double = 3.0
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
        self.maxDepth = maxDepth
        
        // 默认连接状态
        self.connectionState = .disconnected
        self.networkType = .wifi
        
        // 默认电池状态
        self.batteryLevel = 100
        self.isCharging = false
        self.batteryStatus = .normal
        self.batteryCapacity = batteryCapacity
        
        // 默认设备状态
        self.deviceState = .idle
        self.commandExecutionState = .idle
        
        // 默认泳池机器人状态
        self.cleaningMode = .standard
        self.cleaningCycle = 120 // 2小时
        self.filterStatus = .clean
        self.brushStatus = .normal
        self.pathType = .smart
        self.totalWorkingHours = 0.0
        
        self.cleaningHistory = []
        self.maintenanceReminders = []
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
            if command == .startPoolCleaning && self.batteryLevel < 20 {
                promise(.failure(.deviceError("电量不足，无法开始清洁")))
                return
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

// MARK: - PoolRobot Enums

/// 泳池清洁模式
public enum PoolCleaningMode: String, CaseIterable, Codable {
    case quick = "quick"
    case standard = "standard"
    case deep = "deep"
    case eco = "eco"
    
    public var displayName: String {
        switch self {
        case .quick: return "快速清洁"
        case .standard: return "标准清洁"
        case .deep: return "深度清洁"
        case .eco: return "节能清洁"
        }
    }
    
    public var description: String {
        switch self {
        case .quick: return "快速清洁表面污垢"
        case .standard: return "全面清洁池底和池壁"
        case .deep: return "深度清洁，包括细小颗粒"
        case .eco: return "节能模式，延长电池续航"
        }
    }
}

/// 泳池过滤器状态
public enum PoolFilterStatus: String, CaseIterable, Codable {
    case clean = "clean"
    case dirty = "dirty"
    case clogged = "clogged"
    case needsReplacement = "needs_replacement"
    case missing = "missing"
    
    public var displayName: String {
        switch self {
        case .clean: return "清洁"
        case .dirty: return "脏污"
        case .clogged: return "堵塞"
        case .needsReplacement: return "需要更换"
        case .missing: return "未安装"
        }
    }
}

/// 泳池刷子状态
public enum PoolBrushStatus: String, CaseIterable, Codable {
    case normal = "normal"
    case worn = "worn"
    case damaged = "damaged"
    case needsReplacement = "needs_replacement"
    case missing = "missing"
    
    public var displayName: String {
        switch self {
        case .normal: return "正常"
        case .worn: return "磨损"
        case .damaged: return "损坏"
        case .needsReplacement: return "需要更换"
        case .missing: return "未安装"
        }
    }
}

/// 清洁路径类型
public enum CleaningPathType: String, CaseIterable, Codable {
    case smart = "smart"
    case systematic = "systematic"
    case random = "random"
    case custom = "custom"
    
    public var displayName: String {
        switch self {
        case .smart: return "智能路径"
        case .systematic: return "系统路径"
        case .random: return "随机路径"
        case .custom: return "自定义路径"
        }
    }
}

// MARK: - Supporting Structures

/// 水质数据
public struct WaterQuality: Codable {
    /// pH值
    public let pH: Double
    
    /// 氯含量（ppm）
    public let chlorine: Double
    
    /// 水温（摄氏度）
    public let temperature: Double
    
    /// 浊度（NTU）
    public let turbidity: Double
    
    /// 测量时间
    public let measuredAt: Date
    
    public init(pH: Double, chlorine: Double, temperature: Double, turbidity: Double, measuredAt: Date = Date()) {
        self.pH = pH
        self.chlorine = chlorine
        self.temperature = temperature
        self.turbidity = turbidity
        self.measuredAt = measuredAt
    }
    
    /// 水质等级
    public var qualityLevel: WaterQualityLevel {
        let pHGood = (7.0...7.8).contains(pH)
        let chlorineGood = (1.0...3.0).contains(chlorine)
        let turbidityGood = turbidity < 1.0
        
        let goodCount = [pHGood, chlorineGood, turbidityGood].filter { $0 }.count
        
        switch goodCount {
        case 3: return .excellent
        case 2: return .good
        case 1: return .fair
        default: return .poor
        }
    }
}

/// 水质等级
public enum WaterQualityLevel: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    
    public var displayName: String {
        switch self {
        case .excellent: return "优秀"
        case .good: return "良好"
        case .fair: return "一般"
        case .poor: return "较差"
        }
    }
    
    public var colorName: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "yellow"
        case .poor: return "red"
        }
    }
}

/// 泳池尺寸
public struct PoolSize: Codable {
    /// 长度（米）
    public let length: Double
    
    /// 宽度（米）
    public let width: Double
    
    /// 深度（米）
    public let depth: Double
    
    /// 形状
    public let shape: PoolShape
    
    public init(length: Double, width: Double, depth: Double, shape: PoolShape) {
        self.length = length
        self.width = width
        self.depth = depth
        self.shape = shape
    }
    
    /// 泳池面积（平方米）
    public var area: Double {
        switch shape {
        case .rectangular:
            return length * width
        case .circular:
            let radius = length / 2
            return Double.pi * radius * radius
        case .oval:
            return Double.pi * (length / 2) * (width / 2)
        case .irregular:
            return length * width * 0.8 // 估算值
        }
    }
    
    /// 泳池体积（立方米）
    public var volume: Double {
        return area * depth
    }
    
    /// 泳池类型（基于面积）
    public var type: PoolSizeType {
        switch area {
        case 0..<25:
            return .small
        case 25..<50:
            return .medium
        case 50..<100:
            return .large
        default:
            return .extraLarge
        }
    }
}

/// 泳池形状
public enum PoolShape: String, CaseIterable, Codable {
    case rectangular = "rectangular"
    case circular = "circular"
    case oval = "oval"
    case irregular = "irregular"
    
    public var displayName: String {
        switch self {
        case .rectangular: return "矩形"
        case .circular: return "圆形"
        case .oval: return "椭圆形"
        case .irregular: return "不规则形"
        }
    }
}

/// 泳池大小类型
public enum PoolSizeType: String, CaseIterable, Codable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extra_large"
    
    public var displayName: String {
        switch self {
        case .small: return "小型"
        case .medium: return "中型"
        case .large: return "大型"
        case .extraLarge: return "超大型"
        }
    }
}

/// 泳池清洁记录
public struct PoolCleaningRecord: Codable, Identifiable {
    public let id: String
    public let startTime: Date
    public let endTime: Date?
    public let cleaningMode: PoolCleaningMode
    public let pathType: CleaningPathType
    public let coverageRate: Double? // 覆盖率百分比
    public let batteryUsed: Int // 消耗的电量百分比
    public let waterQualityBefore: WaterQuality?
    public let waterQualityAfter: WaterQuality?
    public let status: PoolCleaningStatus
    public let notes: String?
    
    public init(
        id: String = UUID().uuidString,
        startTime: Date,
        endTime: Date? = nil,
        cleaningMode: PoolCleaningMode,
        pathType: CleaningPathType,
        coverageRate: Double? = nil,
        batteryUsed: Int = 0,
        waterQualityBefore: WaterQuality? = nil,
        waterQualityAfter: WaterQuality? = nil,
        status: PoolCleaningStatus = .inProgress,
        notes: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.cleaningMode = cleaningMode
        self.pathType = pathType
        self.coverageRate = coverageRate
        self.batteryUsed = batteryUsed
        self.waterQualityBefore = waterQualityBefore
        self.waterQualityAfter = waterQualityAfter
        self.status = status
        self.notes = notes
    }
    
    /// 清洁持续时间
    public var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    /// 清洁效果评分（1-5分）
    public var effectivenessScore: Int? {
        guard let before = waterQualityBefore,
              let after = waterQualityAfter else { return nil }
        
        let beforeScore = before.qualityLevel.rawValue
        let afterScore = after.qualityLevel.rawValue
        
        // 简单的评分逻辑
        if afterScore == "excellent" { return 5 }
        if afterScore == "good" { return 4 }
        if afterScore == "fair" { return 3 }
        if afterScore == "poor" { return 2 }
        return 1
    }
}

/// 泳池清洁状态
public enum PoolCleaningStatus: String, CaseIterable, Codable {
    case inProgress = "in_progress"
    case completed = "completed"
    case paused = "paused"
    case cancelled = "cancelled"
    case error = "error"
    case interrupted = "interrupted" // 因为电量不足等原因中断
    
    public var displayName: String {
        switch self {
        case .inProgress: return "进行中"
        case .completed: return "已完成"
        case .paused: return "已暂停"
        case .cancelled: return "已取消"
        case .error: return "错误"
        case .interrupted: return "中断"
        }
    }
}

/// 泳池维护提醒
public struct PoolMaintenanceReminder: Codable, Identifiable {
    public let id: String
    public let type: PoolMaintenanceType
    public let message: String
    public let priority: MaintenancePriority
    public let createdAt: Date
    public var isCompleted: Bool
    public var completedAt: Date?
    public let dueDate: Date?
    
    public init(
        id: String = UUID().uuidString,
        type: PoolMaintenanceType,
        message: String,
        priority: MaintenancePriority,
        createdAt: Date = Date(),
        dueDate: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.message = message
        self.priority = priority
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.isCompleted = false
    }
    
    /// 是否过期
    public var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return !isCompleted && Date() > dueDate
    }
}

/// 泳池维护类型
public enum PoolMaintenanceType: String, CaseIterable, Codable {
    case filter = "filter"
    case brush = "brush"
    case sensors = "sensors"
    case battery = "battery"
    case wheels = "wheels"
    case waterQualityCheck = "water_quality_check"
    case generalInspection = "general_inspection"
    
    public var displayName: String {
        switch self {
        case .filter: return "过滤器"
        case .brush: return "刷子"
        case .sensors: return "传感器"
        case .battery: return "电池"
        case .wheels: return "轮子"
        case .waterQualityCheck: return "水质检测"
        case .generalInspection: return "常规检查"
        }
    }
}