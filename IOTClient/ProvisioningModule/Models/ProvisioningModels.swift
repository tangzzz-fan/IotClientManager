//
//  ProvisioningModels.swift
//  ProvisioningModule
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import CoreLocation

// MARK: - Device Type

/// 设备类型
enum DeviceType: String, CaseIterable, Codable {
    case wifiDevice = "wifi"
    case bluetoothDevice = "bluetooth"
    case zigbeeDevice = "zigbee"
    case matterDevice = "matter"
    case customDevice = "custom"
    
    var displayName: String {
        switch self {
        case .wifiDevice:
            return "WiFi设备"
        case .bluetoothDevice:
            return "蓝牙设备"
        case .zigbeeDevice:
            return "Zigbee设备"
        case .matterDevice:
            return "Matter设备"
        case .customDevice:
            return "自定义设备"
        }
    }
    
    var iconName: String {
        switch self {
        case .wifiDevice:
            return "wifi"
        case .bluetoothDevice:
            return "bluetooth"
        case .zigbeeDevice:
            return "antenna.radiowaves.left.and.right"
        case .matterDevice:
            return "network"
        case .customDevice:
            return "cube.box"
        }
    }
}

// MARK: - Device Category

/// 设备类别
enum DeviceCategory: String, CaseIterable, Codable {
    case light = "light"
    case switch = "switch"
    case sensor = "sensor"
    case camera = "camera"
    case lock = "lock"
    case thermostat = "thermostat"
    case speaker = "speaker"
    case display = "display"
    case appliance = "appliance"
    case security = "security"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .light:
            return "灯具"
        case .switch:
            return "开关"
        case .sensor:
            return "传感器"
        case .camera:
            return "摄像头"
        case .lock:
            return "门锁"
        case .thermostat:
            return "温控器"
        case .speaker:
            return "音响"
        case .display:
            return "显示器"
        case .appliance:
            return "家电"
        case .security:
            return "安防"
        case .other:
            return "其他"
        }
    }
    
    var iconName: String {
        switch self {
        case .light:
            return "lightbulb"
        case .switch:
            return "switch.2"
        case .sensor:
            return "sensor"
        case .camera:
            return "camera"
        case .lock:
            return "lock"
        case .thermostat:
            return "thermometer"
        case .speaker:
            return "speaker"
        case .display:
            return "display"
        case .appliance:
            return "washer"
        case .security:
            return "shield"
        case .other:
            return "cube.box"
        }
    }
}

// MARK: - Connection Status

/// 连接状态
enum ConnectionStatus: String, Codable {
    case disconnected = "disconnected"
    case connecting = "connecting"
    case connected = "connected"
    case authenticating = "authenticating"
    case authenticated = "authenticated"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .disconnected:
            return "未连接"
        case .connecting:
            return "连接中"
        case .connected:
            return "已连接"
        case .authenticating:
            return "认证中"
        case .authenticated:
            return "已认证"
        case .failed:
            return "连接失败"
        }
    }
}

// MARK: - Provisionable Device

/// 可配网设备
struct ProvisionableDevice: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let type: DeviceType
    let category: DeviceCategory
    let manufacturer: String
    let model: String
    let firmwareVersion: String?
    let hardwareVersion: String?
    let serialNumber: String?
    let macAddress: String?
    let rssi: Int?
    let advertisementData: [String: Any]?
    let capabilities: [DeviceCapability]
    let securityLevel: SecurityLevel
    let discoveredAt: Date
    let lastSeen: Date
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, category, manufacturer, model
        case firmwareVersion, hardwareVersion, serialNumber, macAddress
        case rssi, capabilities, securityLevel, discoveredAt, lastSeen
    }
    
    // MARK: - Initialization
    
    init(
        id: String,
        name: String,
        type: DeviceType,
        category: DeviceCategory,
        manufacturer: String,
        model: String,
        firmwareVersion: String? = nil,
        hardwareVersion: String? = nil,
        serialNumber: String? = nil,
        macAddress: String? = nil,
        rssi: Int? = nil,
        advertisementData: [String: Any]? = nil,
        capabilities: [DeviceCapability] = [],
        securityLevel: SecurityLevel = .standard,
        discoveredAt: Date = Date(),
        lastSeen: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.category = category
        self.manufacturer = manufacturer
        self.model = model
        self.firmwareVersion = firmwareVersion
        self.hardwareVersion = hardwareVersion
        self.serialNumber = serialNumber
        self.macAddress = macAddress
        self.rssi = rssi
        self.advertisementData = advertisementData
        self.capabilities = capabilities
        self.securityLevel = securityLevel
        self.discoveredAt = discoveredAt
        self.lastSeen = lastSeen
    }
    
    // MARK: - Custom Coding
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(DeviceType.self, forKey: .type)
        category = try container.decode(DeviceCategory.self, forKey: .category)
        manufacturer = try container.decode(String.self, forKey: .manufacturer)
        model = try container.decode(String.self, forKey: .model)
        firmwareVersion = try container.decodeIfPresent(String.self, forKey: .firmwareVersion)
        hardwareVersion = try container.decodeIfPresent(String.self, forKey: .hardwareVersion)
        serialNumber = try container.decodeIfPresent(String.self, forKey: .serialNumber)
        macAddress = try container.decodeIfPresent(String.self, forKey: .macAddress)
        rssi = try container.decodeIfPresent(Int.self, forKey: .rssi)
        capabilities = try container.decode([DeviceCapability].self, forKey: .capabilities)
        securityLevel = try container.decode(SecurityLevel.self, forKey: .securityLevel)
        discoveredAt = try container.decode(Date.self, forKey: .discoveredAt)
        lastSeen = try container.decode(Date.self, forKey: .lastSeen)
        
        // advertisementData 不参与编码，因为包含 Any 类型
        advertisementData = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(category, forKey: .category)
        try container.encode(manufacturer, forKey: .manufacturer)
        try container.encode(model, forKey: .model)
        try container.encodeIfPresent(firmwareVersion, forKey: .firmwareVersion)
        try container.encodeIfPresent(hardwareVersion, forKey: .hardwareVersion)
        try container.encodeIfPresent(serialNumber, forKey: .serialNumber)
        try container.encodeIfPresent(macAddress, forKey: .macAddress)
        try container.encodeIfPresent(rssi, forKey: .rssi)
        try container.encode(capabilities, forKey: .capabilities)
        try container.encode(securityLevel, forKey: .securityLevel)
        try container.encode(discoveredAt, forKey: .discoveredAt)
        try container.encode(lastSeen, forKey: .lastSeen)
    }
    
    // MARK: - Computed Properties
    
    var displayName: String {
        return name.isEmpty ? "\(manufacturer) \(model)" : name
    }
    
    var signalStrength: Float {
        guard let rssi = rssi else { return 0.0 }
        // 将 RSSI 转换为 0-1 的信号强度
        let normalizedRSSI = max(-100, min(-30, rssi))
        return Float(normalizedRSSI + 100) / 70.0
    }
    
    var isRecentlyDiscovered: Bool {
        return Date().timeIntervalSince(discoveredAt) < 300 // 5分钟内
    }
    
    var hasSecureConnection: Bool {
        return securityLevel != .none
    }
}

// MARK: - Device Capability

/// 设备能力
enum DeviceCapability: String, CaseIterable, Codable {
    case onOff = "on_off"
    case dimming = "dimming"
    case colorControl = "color_control"
    case temperatureControl = "temperature_control"
    case motionDetection = "motion_detection"
    case doorSensor = "door_sensor"
    case smokeSensor = "smoke_sensor"
    case audioPlayback = "audio_playback"
    case videoStreaming = "video_streaming"
    case remoteControl = "remote_control"
    case scheduling = "scheduling"
    case groupControl = "group_control"
    case sceneControl = "scene_control"
    case energyMonitoring = "energy_monitoring"
    case firmwareUpdate = "firmware_update"
    
    var displayName: String {
        switch self {
        case .onOff:
            return "开关控制"
        case .dimming:
            return "调光"
        case .colorControl:
            return "颜色控制"
        case .temperatureControl:
            return "温度控制"
        case .motionDetection:
            return "运动检测"
        case .doorSensor:
            return "门窗传感器"
        case .smokeSensor:
            return "烟雾传感器"
        case .audioPlayback:
            return "音频播放"
        case .videoStreaming:
            return "视频流"
        case .remoteControl:
            return "远程控制"
        case .scheduling:
            return "定时功能"
        case .groupControl:
            return "群组控制"
        case .sceneControl:
            return "场景控制"
        case .energyMonitoring:
            return "能耗监控"
        case .firmwareUpdate:
            return "固件升级"
        }
    }
}

// MARK: - Security Level

/// 安全级别
enum SecurityLevel: String, CaseIterable, Codable {
    case none = "none"
    case basic = "basic"
    case standard = "standard"
    case high = "high"
    case enterprise = "enterprise"
    
    var displayName: String {
        switch self {
        case .none:
            return "无加密"
        case .basic:
            return "基础加密"
        case .standard:
            return "标准加密"
        case .high:
            return "高级加密"
        case .enterprise:
            return "企业级加密"
        }
    }
    
    var iconName: String {
        switch self {
        case .none:
            return "lock.open"
        case .basic:
            return "lock.circle"
        case .standard:
            return "lock"
        case .high:
            return "lock.shield"
        case .enterprise:
            return "lock.shield.fill"
        }
    }
}

// MARK: - Network Configuration

/// 网络配置
struct NetworkConfiguration: Codable {
    let ssid: String
    let password: String?
    let securityType: WiFiSecurityType
    let isHidden: Bool
    let priority: Int
    let autoConnect: Bool
    let staticIP: StaticIPConfiguration?
    let proxyConfiguration: ProxyConfiguration?
    let dnsServers: [String]?
    
    init(
        ssid: String,
        password: String? = nil,
        securityType: WiFiSecurityType = .wpa2,
        isHidden: Bool = false,
        priority: Int = 0,
        autoConnect: Bool = true,
        staticIP: StaticIPConfiguration? = nil,
        proxyConfiguration: ProxyConfiguration? = nil,
        dnsServers: [String]? = nil
    ) {
        self.ssid = ssid
        self.password = password
        self.securityType = securityType
        self.isHidden = isHidden
        self.priority = priority
        self.autoConnect = autoConnect
        self.staticIP = staticIP
        self.proxyConfiguration = proxyConfiguration
        self.dnsServers = dnsServers
    }
}

// MARK: - WiFi Security Type

/// WiFi安全类型
enum WiFiSecurityType: String, CaseIterable, Codable {
    case open = "open"
    case wep = "wep"
    case wpa = "wpa"
    case wpa2 = "wpa2"
    case wpa3 = "wpa3"
    case wpaEnterprise = "wpa_enterprise"
    case wpa2Enterprise = "wpa2_enterprise"
    case wpa3Enterprise = "wpa3_enterprise"
    
    var displayName: String {
        switch self {
        case .open:
            return "开放网络"
        case .wep:
            return "WEP"
        case .wpa:
            return "WPA"
        case .wpa2:
            return "WPA2"
        case .wpa3:
            return "WPA3"
        case .wpaEnterprise:
            return "WPA企业版"
        case .wpa2Enterprise:
            return "WPA2企业版"
        case .wpa3Enterprise:
            return "WPA3企业版"
        }
    }
    
    var requiresPassword: Bool {
        return self != .open
    }
}

// MARK: - Static IP Configuration

/// 静态IP配置
struct StaticIPConfiguration: Codable {
    let ipAddress: String
    let subnetMask: String
    let gateway: String
    let primaryDNS: String
    let secondaryDNS: String?
    
    var isValid: Bool {
        return isValidIPAddress(ipAddress) &&
               isValidIPAddress(subnetMask) &&
               isValidIPAddress(gateway) &&
               isValidIPAddress(primaryDNS)
    }
    
    private func isValidIPAddress(_ ip: String) -> Bool {
        let parts = ip.split(separator: ".").compactMap { Int($0) }
        return parts.count == 4 && parts.allSatisfy { $0 >= 0 && $0 <= 255 }
    }
}

// MARK: - Proxy Configuration

/// 代理配置
struct ProxyConfiguration: Codable {
    let type: ProxyType
    let host: String
    let port: Int
    let username: String?
    let password: String?
    let bypassList: [String]?
    
    enum ProxyType: String, CaseIterable, Codable {
        case http = "http"
        case https = "https"
        case socks4 = "socks4"
        case socks5 = "socks5"
        
        var displayName: String {
            return rawValue.uppercased()
        }
    }
}

// MARK: - Device Configuration

/// 设备配置
struct DeviceConfiguration: Codable {
    let deviceName: String
    let location: String?
    let room: String?
    let timezone: String
    let language: String
    let parameters: [String: ConfigurationParameter]
    let features: [String: Bool]
    let schedules: [DeviceSchedule]?
    
    init(
        deviceName: String,
        location: String? = nil,
        room: String? = nil,
        timezone: String = TimeZone.current.identifier,
        language: String = Locale.current.languageCode ?? "en",
        parameters: [String: ConfigurationParameter] = [:],
        features: [String: Bool] = [:],
        schedules: [DeviceSchedule]? = nil
    ) {
        self.deviceName = deviceName
        self.location = location
        self.room = room
        self.timezone = timezone
        self.language = language
        self.parameters = parameters
        self.features = features
        self.schedules = schedules
    }
}

// MARK: - Configuration Parameter

/// 配置参数
struct ConfigurationParameter: Codable {
    let value: ConfigurationValue
    let type: ParameterType
    let range: ParameterRange?
    let unit: String?
    let description: String?
    
    enum ParameterType: String, Codable {
        case boolean = "boolean"
        case integer = "integer"
        case float = "float"
        case string = "string"
        case enum = "enum"
        case array = "array"
        case object = "object"
    }
    
    enum ConfigurationValue: Codable {
        case boolean(Bool)
        case integer(Int)
        case float(Double)
        case string(String)
        case array([ConfigurationValue])
        case object([String: ConfigurationValue])
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            
            if let boolValue = try? container.decode(Bool.self) {
                self = .boolean(boolValue)
            } else if let intValue = try? container.decode(Int.self) {
                self = .integer(intValue)
            } else if let doubleValue = try? container.decode(Double.self) {
                self = .float(doubleValue)
            } else if let stringValue = try? container.decode(String.self) {
                self = .string(stringValue)
            } else if let arrayValue = try? container.decode([ConfigurationValue].self) {
                self = .array(arrayValue)
            } else if let objectValue = try? container.decode([String: ConfigurationValue].self) {
                self = .object(objectValue)
            } else {
                throw DecodingError.typeMismatch(ConfigurationValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid configuration value"))
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            
            switch self {
            case .boolean(let value):
                try container.encode(value)
            case .integer(let value):
                try container.encode(value)
            case .float(let value):
                try container.encode(value)
            case .string(let value):
                try container.encode(value)
            case .array(let value):
                try container.encode(value)
            case .object(let value):
                try container.encode(value)
            }
        }
    }
}

// MARK: - Parameter Range

/// 参数范围
struct ParameterRange: Codable {
    let min: Double?
    let max: Double?
    let step: Double?
    let allowedValues: [String]?
    
    func isValid(_ value: Double) -> Bool {
        if let min = min, value < min { return false }
        if let max = max, value > max { return false }
        return true
    }
}

// MARK: - Device Schedule

/// 设备定时
struct DeviceSchedule: Codable, Identifiable {
    let id: String
    let name: String
    let isEnabled: Bool
    let trigger: ScheduleTrigger
    let action: ScheduleAction
    let conditions: [ScheduleCondition]?
    
    enum ScheduleTrigger: Codable {
        case time(hour: Int, minute: Int, weekdays: [Int])
        case sunrise(offset: Int) // 分钟偏移
        case sunset(offset: Int)
        case interval(seconds: Int)
        case event(String)
    }
    
    enum ScheduleAction: Codable {
        case turnOn
        case turnOff
        case setValue(parameter: String, value: ConfigurationParameter.ConfigurationValue)
        case runScene(String)
        case sendNotification(String)
    }
    
    struct ScheduleCondition: Codable {
        let parameter: String
        let operator: ConditionOperator
        let value: ConfigurationParameter.ConfigurationValue
        
        enum ConditionOperator: String, Codable {
            case equal = "=="
            case notEqual = "!="
            case greaterThan = ">"
            case lessThan = "<"
            case greaterThanOrEqual = ">="
            case lessThanOrEqual = "<="
            case contains = "contains"
        }
    }
}

// MARK: - Authentication Info

/// 认证信息
struct AuthenticationInfo: Codable {
    let method: AuthenticationMethod
    let token: String?
    let certificate: Data?
    let publicKey: Data?
    let expiresAt: Date?
    let permissions: [String]
    
    enum AuthenticationMethod: String, Codable {
        case none = "none"
        case password = "password"
        case certificate = "certificate"
        case token = "token"
        case biometric = "biometric"
        case oauth = "oauth"
    }
}

// MARK: - Authentication Configuration

/// 认证配置
struct AuthenticationConfiguration: Codable {
    let method: AuthenticationInfo.AuthenticationMethod
    let credentials: [String: String]
    let timeout: TimeInterval
    let retryCount: Int
    let certificatePath: String?
    let keyPath: String?
}

// MARK: - Result Types

/// 认证结果
struct AuthenticationResult: Codable {
    let isSuccessful: Bool
    let authInfo: AuthenticationInfo?
    let error: String?
    let timestamp: Date
}

/// 配置结果
struct ConfigurationResult: Codable {
    let isSuccessful: Bool
    let appliedParameters: [String: ConfigurationParameter.ConfigurationValue]
    let failedParameters: [String: String]?
    let deviceInfo: DeviceInfo?
    let timestamp: Date
}

/// 验证结果
struct VerificationResult: Codable {
    let isSuccessful: Bool
    let networkConnected: Bool
    let deviceResponding: Bool
    let functionalityTests: [String: Bool]
    let error: String?
    let timestamp: Date
}

/// 网络测试结果
struct NetworkTestResult: Codable {
    let isConnected: Bool
    let ipAddress: String?
    let gateway: String?
    let dnsServers: [String]?
    let internetAccess: Bool
    let latency: TimeInterval?
    let bandwidth: NetworkBandwidth?
    let timestamp: Date
    
    struct NetworkBandwidth: Codable {
        let download: Double // Mbps
        let upload: Double   // Mbps
    }
}

/// 功能测试结果
struct FunctionalityTestResult: Codable {
    let deviceResponding: Bool
    let capabilityTests: [DeviceCapability: Bool]
    let performanceMetrics: [String: Double]
    let error: String?
    let timestamp: Date
}

/// 配网结果
struct ProvisioningResult: Codable {
    let isSuccessful: Bool
    let device: ProvisionableDevice
    let networkConfiguration: NetworkConfiguration
    let deviceConfiguration: DeviceConfiguration?
    let duration: TimeInterval
    let steps: [ProvisioningStep]
    let error: ProvisioningError?
    let timestamp: Date
    
    struct ProvisioningStep: Codable {
        let name: String
        let isSuccessful: Bool
        let duration: TimeInterval
        let error: String?
        let timestamp: Date
    }
}

/// 配网进度
struct ProvisioningProgress: Codable {
    let currentStep: String
    let currentStepProgress: Float // 0.0 - 1.0
    let overallProgress: Float     // 0.0 - 1.0
    let estimatedTimeRemaining: TimeInterval?
    let message: String?
    let timestamp: Date
    
    init(
        currentStep: String,
        currentStepProgress: Float = 0.0,
        overallProgress: Float = 0.0,
        estimatedTimeRemaining: TimeInterval? = nil,
        message: String? = nil
    ) {
        self.currentStep = currentStep
        self.currentStepProgress = max(0.0, min(1.0, currentStepProgress))
        self.overallProgress = max(0.0, min(1.0, overallProgress))
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.message = message
        self.timestamp = Date()
    }
}

// MARK: - Device Info

/// 设备信息
struct DeviceInfo: Codable {
    let id: String
    let name: String
    let type: DeviceType
    let category: DeviceCategory
    let manufacturer: String
    let model: String
    let firmwareVersion: String
    let hardwareVersion: String
    let serialNumber: String
    let macAddress: String
    let ipAddress: String?
    let capabilities: [DeviceCapability]
    let status: DeviceStatus
    let lastSeen: Date
    let location: CLLocation?
    let metadata: [String: String]
    
    enum DeviceStatus: String, Codable {
        case online = "online"
        case offline = "offline"
        case updating = "updating"
        case error = "error"
        case unknown = "unknown"
        
        var displayName: String {
            switch self {
            case .online:
                return "在线"
            case .offline:
                return "离线"
            case .updating:
                return "更新中"
            case .error:
                return "错误"
            case .unknown:
                return "未知"
            }
        }
    }
}