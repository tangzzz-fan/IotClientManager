//
//  PersistenceModels.swift
//  PersistenceLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation

// MARK: - Base Models

/// 基础实体协议
protocol BaseEntity: Identifiable, Codable {
    var id: String { get }
    var createdAt: Date { get }
    var updatedAt: Date { get set }
    var version: Int { get set }
    
    mutating func updateTimestamp()
    mutating func incrementVersion()
}

extension BaseEntity {
    mutating func updateTimestamp() {
        updatedAt = Date()
    }
    
    mutating func incrementVersion() {
        version += 1
        updateTimestamp()
    }
}

/// 可同步实体协议
protocol SyncableEntity: BaseEntity {
    var syncStatus: SyncStatus { get set }
    var lastSyncAt: Date? { get set }
    var remoteId: String? { get set }
    var conflictResolution: ConflictResolution { get set }
    
    mutating func markForSync()
    mutating func markAsSynced()
    mutating func markAsConflicted()
}

extension SyncableEntity {
    mutating func markForSync() {
        syncStatus = .pending
        updateTimestamp()
    }
    
    mutating func markAsSynced() {
        syncStatus = .synced
        lastSyncAt = Date()
    }
    
    mutating func markAsConflicted() {
        syncStatus = .conflicted
    }
}

// MARK: - Device Models

/// 持久化设备模型
struct PersistedDevice: SyncableEntity {
    let id: String
    var name: String
    var type: String
    var model: String
    var manufacturer: String
    var firmwareVersion: String?
    var hardwareVersion: String?
    var serialNumber: String?
    var macAddress: String?
    var ipAddress: String?
    var status: DeviceStatus
    var capabilities: [String]
    var metadata: [String: String]
    var roomId: String?
    var groupIds: [String]
    var tags: [String]
    var isOnline: Bool
    var lastSeenAt: Date?
    var batteryLevel: Int?
    var signalStrength: Int?
    var connectionType: String?
    var protocolVersion: String?
    let createdAt: Date
    var updatedAt: Date
    var version: Int
    var syncStatus: SyncStatus
    var lastSyncAt: Date?
    var remoteId: String?
    var conflictResolution: ConflictResolution
    
    init(
        id: String = UUID().uuidString,
        name: String,
        type: String,
        model: String,
        manufacturer: String
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.model = model
        self.manufacturer = manufacturer
        self.firmwareVersion = nil
        self.hardwareVersion = nil
        self.serialNumber = nil
        self.macAddress = nil
        self.ipAddress = nil
        self.status = .unknown
        self.capabilities = []
        self.metadata = [:]
        self.roomId = nil
        self.groupIds = []
        self.tags = []
        self.isOnline = false
        self.lastSeenAt = nil
        self.batteryLevel = nil
        self.signalStrength = nil
        self.connectionType = nil
        self.protocolVersion = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.version = 1
        self.syncStatus = .pending
        self.lastSyncAt = nil
        self.remoteId = nil
        self.conflictResolution = .serverWins
    }
}

/// 设备状态
enum DeviceStatus: String, Codable, CaseIterable {
    case unknown = "unknown"
    case online = "online"
    case offline = "offline"
    case error = "error"
    case updating = "updating"
    case configuring = "configuring"
    case maintenance = "maintenance"
    
    var displayName: String {
        switch self {
        case .unknown: return "未知"
        case .online: return "在线"
        case .offline: return "离线"
        case .error: return "错误"
        case .updating: return "更新中"
        case .configuring: return "配置中"
        case .maintenance: return "维护中"
        }
    }
    
    var isHealthy: Bool {
        return self == .online
    }
}

// MARK: - User Models

/// 持久化用户模型
struct PersistedUser: SyncableEntity {
    let id: String
    var username: String
    var email: String
    var displayName: String
    var avatar: String?
    var phoneNumber: String?
    var preferences: UserPreferences
    var permissions: [String]
    var roles: [String]
    var isActive: Bool
    var lastLoginAt: Date?
    var loginCount: Int
    var twoFactorEnabled: Bool
    var notificationSettings: NotificationSettings
    let createdAt: Date
    var updatedAt: Date
    var version: Int
    var syncStatus: SyncStatus
    var lastSyncAt: Date?
    var remoteId: String?
    var conflictResolution: ConflictResolution
    
    init(
        id: String = UUID().uuidString,
        username: String,
        email: String,
        displayName: String
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.displayName = displayName
        self.avatar = nil
        self.phoneNumber = nil
        self.preferences = UserPreferences()
        self.permissions = []
        self.roles = ["user"]
        self.isActive = true
        self.lastLoginAt = nil
        self.loginCount = 0
        self.twoFactorEnabled = false
        self.notificationSettings = NotificationSettings()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.version = 1
        self.syncStatus = .pending
        self.lastSyncAt = nil
        self.remoteId = nil
        self.conflictResolution = .serverWins
    }
}

/// 用户偏好设置
struct UserPreferences: Codable {
    var language: String
    var theme: String
    var temperatureUnit: TemperatureUnit
    var timeFormat: TimeFormat
    var autoSync: Bool
    var offlineMode: Bool
    var dataUsageOptimization: Bool
    var analyticsEnabled: Bool
    var crashReportingEnabled: Bool
    
    init() {
        self.language = "zh-CN"
        self.theme = "system"
        self.temperatureUnit = .celsius
        self.timeFormat = .twentyFourHour
        self.autoSync = true
        self.offlineMode = false
        self.dataUsageOptimization = true
        self.analyticsEnabled = true
        self.crashReportingEnabled = true
    }
}

/// 温度单位
enum TemperatureUnit: String, Codable, CaseIterable {
    case celsius = "celsius"
    case fahrenheit = "fahrenheit"
    
    var symbol: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }
}

/// 时间格式
enum TimeFormat: String, Codable, CaseIterable {
    case twelveHour = "12h"
    case twentyFourHour = "24h"
}

/// 通知设置
struct NotificationSettings: Codable {
    var pushEnabled: Bool
    var emailEnabled: Bool
    var smsEnabled: Bool
    var deviceAlerts: Bool
    var systemUpdates: Bool
    var securityAlerts: Bool
    var marketingMessages: Bool
    var quietHours: QuietHours?
    
    init() {
        self.pushEnabled = true
        self.emailEnabled = true
        self.smsEnabled = false
        self.deviceAlerts = true
        self.systemUpdates = true
        self.securityAlerts = true
        self.marketingMessages = false
        self.quietHours = nil
    }
}

/// 免打扰时间
struct QuietHours: Codable {
    let startTime: String // HH:mm format
    let endTime: String   // HH:mm format
    let enabled: Bool
    
    init(startTime: String = "22:00", endTime: String = "08:00", enabled: Bool = false) {
        self.startTime = startTime
        self.endTime = endTime
        self.enabled = enabled
    }
}

// MARK: - Settings Models

/// 应用设置模型
struct AppSettings: SyncableEntity {
    let id: String
    var category: String
    var key: String
    var value: String
    var type: SettingType
    var isSecure: Bool
    var description: String?
    var defaultValue: String?
    var validationRules: [ValidationRule]
    let createdAt: Date
    var updatedAt: Date
    var version: Int
    var syncStatus: SyncStatus
    var lastSyncAt: Date?
    var remoteId: String?
    var conflictResolution: ConflictResolution
    
    init(
        id: String = UUID().uuidString,
        category: String,
        key: String,
        value: String,
        type: SettingType = .string,
        isSecure: Bool = false
    ) {
        self.id = id
        self.category = category
        self.key = key
        self.value = value
        self.type = type
        self.isSecure = isSecure
        self.description = nil
        self.defaultValue = nil
        self.validationRules = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.version = 1
        self.syncStatus = .pending
        self.lastSyncAt = nil
        self.remoteId = nil
        self.conflictResolution = .clientWins
    }
}

/// 设置类型
enum SettingType: String, Codable, CaseIterable {
    case string = "string"
    case integer = "integer"
    case double = "double"
    case boolean = "boolean"
    case json = "json"
    case encrypted = "encrypted"
    
    func validate(_ value: String) -> Bool {
        switch self {
        case .string:
            return true
        case .integer:
            return Int(value) != nil
        case .double:
            return Double(value) != nil
        case .boolean:
            return ["true", "false", "1", "0"].contains(value.lowercased())
        case .json:
            return (try? JSONSerialization.jsonObject(with: value.data(using: .utf8) ?? Data())) != nil
        case .encrypted:
            return true
        }
    }
}

/// 验证规则
struct ValidationRule: Codable {
    let type: ValidationType
    let value: String
    let message: String
    
    func validate(_ input: String) -> Bool {
        switch type {
        case .required:
            return !input.isEmpty
        case .minLength:
            return input.count >= (Int(value) ?? 0)
        case .maxLength:
            return input.count <= (Int(value) ?? Int.max)
        case .regex:
            return input.range(of: value, options: .regularExpression) != nil
        case .range:
            let components = value.split(separator: ",")
            guard components.count == 2,
                  let min = Double(components[0]),
                  let max = Double(components[1]),
                  let inputValue = Double(input) else {
                return false
            }
            return inputValue >= min && inputValue <= max
        }
    }
}

/// 验证类型
enum ValidationType: String, Codable, CaseIterable {
    case required = "required"
    case minLength = "minLength"
    case maxLength = "maxLength"
    case regex = "regex"
    case range = "range"
}

// MARK: - Room and Group Models

/// 房间模型
struct Room: SyncableEntity {
    let id: String
    var name: String
    var type: RoomType
    var floor: Int?
    var area: Double? // 平方米
    var deviceIds: [String]
    var metadata: [String: String]
    let createdAt: Date
    var updatedAt: Date
    var version: Int
    var syncStatus: SyncStatus
    var lastSyncAt: Date?
    var remoteId: String?
    var conflictResolution: ConflictResolution
    
    init(
        id: String = UUID().uuidString,
        name: String,
        type: RoomType = .other
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.floor = nil
        self.area = nil
        self.deviceIds = []
        self.metadata = [:]
        self.createdAt = Date()
        self.updatedAt = Date()
        self.version = 1
        self.syncStatus = .pending
        self.lastSyncAt = nil
        self.remoteId = nil
        self.conflictResolution = .serverWins
    }
}

/// 房间类型
enum RoomType: String, Codable, CaseIterable {
    case livingRoom = "living_room"
    case bedroom = "bedroom"
    case kitchen = "kitchen"
    case bathroom = "bathroom"
    case diningRoom = "dining_room"
    case study = "study"
    case garage = "garage"
    case garden = "garden"
    case balcony = "balcony"
    case basement = "basement"
    case attic = "attic"
    case hallway = "hallway"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .livingRoom: return "客厅"
        case .bedroom: return "卧室"
        case .kitchen: return "厨房"
        case .bathroom: return "浴室"
        case .diningRoom: return "餐厅"
        case .study: return "书房"
        case .garage: return "车库"
        case .garden: return "花园"
        case .balcony: return "阳台"
        case .basement: return "地下室"
        case .attic: return "阁楼"
        case .hallway: return "走廊"
        case .other: return "其他"
        }
    }
}

/// 设备组模型
struct DeviceGroup: SyncableEntity {
    let id: String
    var name: String
    var description: String?
    var deviceIds: [String]
    var groupType: GroupType
    var automationRules: [String] // 自动化规则ID
    var metadata: [String: String]
    let createdAt: Date
    var updatedAt: Date
    var version: Int
    var syncStatus: SyncStatus
    var lastSyncAt: Date?
    var remoteId: String?
    var conflictResolution: ConflictResolution
    
    init(
        id: String = UUID().uuidString,
        name: String,
        groupType: GroupType = .custom
    ) {
        self.id = id
        self.name = name
        self.description = nil
        self.deviceIds = []
        self.groupType = groupType
        self.automationRules = []
        self.metadata = [:]
        self.createdAt = Date()
        self.updatedAt = Date()
        self.version = 1
        self.syncStatus = .pending
        self.lastSyncAt = nil
        self.remoteId = nil
        self.conflictResolution = .serverWins
    }
}

/// 组类型
enum GroupType: String, Codable, CaseIterable {
    case room = "room"
    case function = "function"
    case scene = "scene"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .room: return "房间组"
        case .function: return "功能组"
        case .scene: return "场景组"
        case .custom: return "自定义组"
        }
    }
}

// MARK: - Supporting Types

/// 同步状态
enum SyncStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case syncing = "syncing"
    case synced = "synced"
    case failed = "failed"
    case conflicted = "conflicted"
    
    var displayName: String {
        switch self {
        case .pending: return "待同步"
        case .syncing: return "同步中"
        case .synced: return "已同步"
        case .failed: return "同步失败"
        case .conflicted: return "冲突"
        }
    }
    
    var needsSync: Bool {
        return self == .pending || self == .failed
    }
}

/// 冲突解决策略
enum ConflictResolution: String, Codable, CaseIterable {
    case clientWins = "client_wins"
    case serverWins = "server_wins"
    case manual = "manual"
    case merge = "merge"
    
    var displayName: String {
        switch self {
        case .clientWins: return "本地优先"
        case .serverWins: return "服务器优先"
        case .manual: return "手动解决"
        case .merge: return "智能合并"
        }
    }
}

// MARK: - Cache Models

/// 缓存项
struct CacheItem<T: Codable>: Codable {
    let key: String
    let value: T
    let createdAt: Date
    let expiresAt: Date?
    let accessCount: Int
    let lastAccessAt: Date
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    init(key: String, value: T, ttl: TimeInterval? = nil) {
        self.key = key
        self.value = value
        self.createdAt = Date()
        self.expiresAt = ttl.map { Date().addingTimeInterval($0) }
        self.accessCount = 0
        self.lastAccessAt = Date()
    }
}

/// 缓存统计
struct CacheStatistics: Codable {
    let totalItems: Int
    let totalSize: Int64
    let hitCount: Int64
    let missCount: Int64
    let evictionCount: Int64
    let lastCleanupAt: Date?
    
    var hitRate: Double {
        let total = hitCount + missCount
        return total > 0 ? Double(hitCount) / Double(total) : 0.0
    }
    
    init() {
        self.totalItems = 0
        self.totalSize = 0
        self.hitCount = 0
        self.missCount = 0
        self.evictionCount = 0
        self.lastCleanupAt = nil
    }
}