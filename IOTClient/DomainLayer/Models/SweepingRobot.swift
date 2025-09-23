//
//  SweepingRobot.swift
//  DomainLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

/// 扫地机器人设备模型
public struct SweepingRobot: Device, Connectable, BatteryPowered, Controllable, Codable {
    
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
    public let deviceType: DeviceType = .sweepingRobot
    
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
    
    // MARK: - SweepingRobot Specific Properties
    /// 清扫模式
    public var cleaningMode: CleaningMode
    
    /// 吸力等级
    public var suctionLevel: SuctionLevel
    
    /// 水箱水量（毫升）
    public var waterTankLevel: Int?
    
    /// 尘盒状态
    public var dustBinStatus: DustBinStatus
    
    /// 滤网状态
    public var filterStatus: FilterStatus
    
    /// 主刷状态
    public var mainBrushStatus: BrushStatus
    
    /// 边刷状态
    public var sideBrushStatus: BrushStatus
    
    /// 拖布状态
    public var mopStatus: MopStatus?
    
    /// 当前位置（x, y坐标）
    public var currentPosition: Position?
    
    /// 充电桩位置
    public var dockPosition: Position?
    
    /// 清扫面积（平方米）
    public var cleanedArea: Double?
    
    /// 清扫时间（秒）
    public var cleaningTime: TimeInterval?
    
    /// 地图数据
    public var mapData: MapData?
    
    /// 清扫历史记录
    public var cleaningHistory: [CleaningRecord]
    
    /// 维护提醒
    public var maintenanceReminders: [MaintenanceReminder]
    
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
        .startCleaning, .returnToBase, .spotCleaning, .edgeCleaning
    ]
    
    // MARK: - Computed Properties
    public var estimatedChargingTime: TimeInterval? {
        guard isCharging, batteryLevel < 100 else { return nil }
        let remainingCapacity = Double(100 - batteryLevel) / 100.0 * Double(batteryCapacity)
        return remainingCapacity / 1000.0 * 3600 // 假设1A充电电流
    }
    
    // MARK: - Initializer
    public init(
        id: String,
        name: String,
        modelName: String,
        firmwareVersion: String,
        manufacturer: String,
        serialNumber: String,
        batteryCapacity: Int = 3200
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
        
        // 默认扫地机器人状态
        self.cleaningMode = .auto
        self.suctionLevel = .standard
        self.dustBinStatus = .normal
        self.filterStatus = .normal
        self.mainBrushStatus = .normal
        self.sideBrushStatus = .normal
        
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

// MARK: - SweepingRobot Enums

/// 清扫模式
public enum CleaningMode: String, CaseIterable, Codable {
    case auto = "auto"
    case spot = "spot"
    case edge = "edge"
    case zigzag = "zigzag"
    case random = "random"
    
    public var displayName: String {
        switch self {
        case .auto: return "自动清扫"
        case .spot: return "定点清扫"
        case .edge: return "沿边清扫"
        case .zigzag: return "弓字形清扫"
        case .random: return "随机清扫"
        }
    }
}

/// 吸力等级
public enum SuctionLevel: String, CaseIterable, Codable {
    case quiet = "quiet"
    case standard = "standard"
    case medium = "medium"
    case high = "high"
    
    public var displayName: String {
        switch self {
        case .quiet: return "安静"
        case .standard: return "标准"
        case .medium: return "中档"
        case .high: return "强力"
        }
    }
    
    public var powerLevel: Int {
        switch self {
        case .quiet: return 25
        case .standard: return 50
        case .medium: return 75
        case .high: return 100
        }
    }
}

/// 尘盒状态
public enum DustBinStatus: String, CaseIterable, Codable {
    case normal = "normal"
    case full = "full"
    case missing = "missing"
    case error = "error"
    
    public var displayName: String {
        switch self {
        case .normal: return "正常"
        case .full: return "已满"
        case .missing: return "未安装"
        case .error: return "异常"
        }
    }
}

/// 滤网状态
public enum FilterStatus: String, CaseIterable, Codable {
    case normal = "normal"
    case dirty = "dirty"
    case needsReplacement = "needs_replacement"
    case missing = "missing"
    
    public var displayName: String {
        switch self {
        case .normal: return "正常"
        case .dirty: return "需要清洁"
        case .needsReplacement: return "需要更换"
        case .missing: return "未安装"
        }
    }
}

/// 刷子状态
public enum BrushStatus: String, CaseIterable, Codable {
    case normal = "normal"
    case worn = "worn"
    case tangled = "tangled"
    case needsReplacement = "needs_replacement"
    case missing = "missing"
    
    public var displayName: String {
        switch self {
        case .normal: return "正常"
        case .worn: return "磨损"
        case .tangled: return "缠绕"
        case .needsReplacement: return "需要更换"
        case .missing: return "未安装"
        }
    }
}

/// 拖布状态
public enum MopStatus: String, CaseIterable, Codable {
    case normal = "normal"
    case dirty = "dirty"
    case dry = "dry"
    case needsReplacement = "needs_replacement"
    case missing = "missing"
    
    public var displayName: String {
        switch self {
        case .normal: return "正常"
        case .dirty: return "脏污"
        case .dry: return "干燥"
        case .needsReplacement: return "需要更换"
        case .missing: return "未安装"
        }
    }
}

// MARK: - Supporting Structures

/// 位置坐标
public struct Position: Codable, Equatable {
    public let x: Double
    public let y: Double
    public let angle: Double? // 角度（弧度）
    
    public init(x: Double, y: Double, angle: Double? = nil) {
        self.x = x
        self.y = y
        self.angle = angle
    }
}

/// 地图数据
public struct MapData: Codable {
    public let width: Int
    public let height: Int
    public let resolution: Double // 米/像素
    public let data: Data // 地图像素数据
    public let obstacles: [Position] // 障碍物位置
    public let cleanedAreas: [CleanedArea] // 已清扫区域
    
    public init(width: Int, height: Int, resolution: Double, data: Data, obstacles: [Position] = [], cleanedAreas: [CleanedArea] = []) {
        self.width = width
        self.height = height
        self.resolution = resolution
        self.data = data
        self.obstacles = obstacles
        self.cleanedAreas = cleanedAreas
    }
}

/// 已清扫区域
public struct CleanedArea: Codable {
    public let polygon: [Position] // 多边形顶点
    public let cleanedAt: Date
    public let cleaningMode: CleaningMode
    
    public init(polygon: [Position], cleanedAt: Date, cleaningMode: CleaningMode) {
        self.polygon = polygon
        self.cleanedAt = cleanedAt
        self.cleaningMode = cleaningMode
    }
}

/// 清扫记录
public struct CleaningRecord: Codable, Identifiable {
    public let id: String
    public let startTime: Date
    public let endTime: Date?
    public let cleaningMode: CleaningMode
    public let suctionLevel: SuctionLevel
    public let cleanedArea: Double? // 平方米
    public let batteryUsed: Int // 消耗的电量百分比
    public let status: CleaningStatus
    
    public init(id: String = UUID().uuidString, startTime: Date, endTime: Date? = nil, cleaningMode: CleaningMode, suctionLevel: SuctionLevel, cleanedArea: Double? = nil, batteryUsed: Int = 0, status: CleaningStatus = .inProgress) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.cleaningMode = cleaningMode
        self.suctionLevel = suctionLevel
        self.cleanedArea = cleanedArea
        self.batteryUsed = batteryUsed
        self.status = status
    }
    
    /// 清扫持续时间
    public var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
}

/// 清扫状态
public enum CleaningStatus: String, CaseIterable, Codable {
    case inProgress = "in_progress"
    case completed = "completed"
    case paused = "paused"
    case cancelled = "cancelled"
    case error = "error"
    
    public var displayName: String {
        switch self {
        case .inProgress: return "进行中"
        case .completed: return "已完成"
        case .paused: return "已暂停"
        case .cancelled: return "已取消"
        case .error: return "错误"
        }
    }
}

/// 维护提醒
public struct MaintenanceReminder: Codable, Identifiable {
    public let id: String
    public let type: MaintenanceType
    public let message: String
    public let priority: MaintenancePriority
    public let createdAt: Date
    public var isCompleted: Bool
    public var completedAt: Date?
    
    public init(id: String = UUID().uuidString, type: MaintenanceType, message: String, priority: MaintenancePriority, createdAt: Date = Date()) {
        self.id = id
        self.type = type
        self.message = message
        self.priority = priority
        self.createdAt = createdAt
        self.isCompleted = false
    }
}

/// 维护类型
public enum MaintenanceType: String, CaseIterable, Codable {
    case dustBin = "dust_bin"
    case filter = "filter"
    case mainBrush = "main_brush"
    case sideBrush = "side_brush"
    case mop = "mop"
    case sensors = "sensors"
    case wheels = "wheels"
    
    public var displayName: String {
        switch self {
        case .dustBin: return "尘盒"
        case .filter: return "滤网"
        case .mainBrush: return "主刷"
        case .sideBrush: return "边刷"
        case .mop: return "拖布"
        case .sensors: return "传感器"
        case .wheels: return "轮子"
        }
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