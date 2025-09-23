//
//  DomainLayer.swift
//  DomainLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

// MARK: - Module Information

/// DomainLayer 框架版本信息
public struct DomainLayerInfo {
    /// 框架版本
    public static let version = "1.0.0"
    
    /// 框架名称
    public static let name = "DomainLayer"
    
    /// 框架描述
    public static let description = "智能家居设备领域层框架，提供设备协议、模型和工厂模式实现"
    
    /// 支持的设备类型
    public static let supportedDeviceTypes: [DeviceType] = [
        .sweepingRobot,
        .poolRobot,
        .energyStorage,
        .smartPlug,
        .smartLight,
        .smartCamera,
        .smartSpeaker,
        .smartThermostat,
        .smartLock,
        .smartSensor
    ]
    
    /// 框架特性
    public static let features = [
        "协议导向编程",
        "工厂模式设备创建",
        "类型安全的设备模型",
        "丰富的设备扩展方法",
        "Combine框架集成",
        "完整的错误处理"
    ]
}

// MARK: - Public Exports

// 导出核心协议
@_exported import Foundation
@_exported import Combine

// 协议导出
public typealias DeviceProtocol = Device
public typealias ConnectableProtocol = Connectable
public typealias BatteryPoweredProtocol = BatteryPowered
public typealias ControllableProtocol = Controllable

// 工厂导出
public typealias DeviceFactoryType = DeviceFactory
public typealias DeviceCreatorType = DeviceCreatorProtocol

// 模型导出
public typealias SweepingRobotModel = SweepingRobot
public typealias PoolRobotModel = PoolRobot
public typealias EnergyStorageModel = EnergyStorage

// MARK: - Module Initialization

/// DomainLayer 模块管理器
public class DomainLayerManager {
    
    /// 单例实例
    public static let shared = DomainLayerManager()
    
    /// 设备工厂实例
    public let deviceFactory: DeviceFactory
    
    /// 模块初始化状态
    private var isInitialized = false
    
    /// 私有初始化器
    private init() {
        self.deviceFactory = DeviceFactory.shared
    }
    
    /// 初始化模块
    /// - Parameter configuration: 模块配置
    public func initialize(with configuration: DomainLayerConfiguration = .default) {
        guard !isInitialized else {
            print("⚠️ DomainLayer 已经初始化")
            return
        }
        
        print("🚀 正在初始化 DomainLayer v\(DomainLayerInfo.version)")
        
        // 应用配置
        applyConfiguration(configuration)
        
        // 验证工厂设置
        validateFactorySetup()
        
        isInitialized = true
        
        print("✅ DomainLayer 初始化完成")
        print("📋 支持的设备类型: \(deviceFactory.supportedDeviceTypes().map { $0.displayName }.joined(separator: ", "))")
    }
    
    /// 应用配置
    private func applyConfiguration(_ configuration: DomainLayerConfiguration) {
        // 注册自定义设备创建器
        for (deviceType, creator) in configuration.customCreators {
            deviceFactory.registerCreator(creator, for: deviceType)
            print("📝 注册自定义创建器: \(deviceType.displayName)")
        }
        
        // 应用其他配置
        if configuration.enableDebugLogging {
            print("🐛 启用调试日志")
        }
    }
    
    /// 验证工厂设置
    private func validateFactorySetup() {
        let supportedTypes = deviceFactory.supportedDeviceTypes()
        let expectedTypes = DomainLayerInfo.supportedDeviceTypes
        
        for expectedType in expectedTypes {
            if !supportedTypes.contains(expectedType) {
                print("⚠️ 缺少设备类型支持: \(expectedType.displayName)")
            }
        }
    }
    
    /// 获取模块状态信息
    public func getModuleStatus() -> DomainLayerStatus {
        return DomainLayerStatus(
            isInitialized: isInitialized,
            version: DomainLayerInfo.version,
            supportedDeviceCount: deviceFactory.supportedDeviceTypes().count,
            supportedDeviceTypes: deviceFactory.supportedDeviceTypes()
        )
    }
}

// MARK: - Configuration

/// DomainLayer 配置
public struct DomainLayerConfiguration {
    /// 自定义设备创建器
    public let customCreators: [DeviceType: DeviceCreatorProtocol]
    
    /// 是否启用调试日志
    public let enableDebugLogging: Bool
    
    /// 设备缓存策略
    public let cacheStrategy: DeviceCacheStrategy
    
    /// 默认配置
    public static let `default` = DomainLayerConfiguration(
        customCreators: [:],
        enableDebugLogging: false,
        cacheStrategy: .memory
    )
    
    public init(
        customCreators: [DeviceType: DeviceCreatorProtocol] = [:],
        enableDebugLogging: Bool = false,
        cacheStrategy: DeviceCacheStrategy = .memory
    ) {
        self.customCreators = customCreators
        self.enableDebugLogging = enableDebugLogging
        self.cacheStrategy = cacheStrategy
    }
}

/// 设备缓存策略
public enum DeviceCacheStrategy {
    case none       // 不缓存
    case memory     // 内存缓存
    case disk       // 磁盘缓存
    case hybrid     // 混合缓存
}

// MARK: - Status

/// DomainLayer 状态信息
public struct DomainLayerStatus {
    /// 是否已初始化
    public let isInitialized: Bool
    
    /// 版本号
    public let version: String
    
    /// 支持的设备数量
    public let supportedDeviceCount: Int
    
    /// 支持的设备类型
    public let supportedDeviceTypes: [DeviceType]
    
    /// 状态描述
    public var description: String {
        return """
        DomainLayer 状态:
        - 初始化状态: \(isInitialized ? "已初始化" : "未初始化")
        - 版本: \(version)
        - 支持设备数量: \(supportedDeviceCount)
        - 支持设备类型: \(supportedDeviceTypes.map { $0.displayName }.joined(separator: ", "))
        """
    }
}

// MARK: - Utility Functions

/// DomainLayer 工具函数
public enum DomainLayerUtils {
    
    /// 创建设备配置
    /// - Parameters:
    ///   - id: 设备ID
    ///   - name: 设备名称
    ///   - modelName: 设备型号
    ///   - deviceType: 设备类型
    ///   - customProperties: 自定义属性
    /// - Returns: 设备配置
    public static func createDeviceConfiguration(
        id: String,
        name: String,
        modelName: String,
        deviceType: DeviceType,
        firmwareVersion: String = "1.0.0",
        manufacturer: String = "Unknown",
        serialNumber: String? = nil,
        customProperties: [String: Any] = [:]
    ) -> DeviceConfiguration {
        let finalSerialNumber = serialNumber ?? UUID().uuidString
        
        return DeviceConfiguration(
            id: id,
            name: name,
            modelName: modelName,
            firmwareVersion: firmwareVersion,
            manufacturer: manufacturer,
            serialNumber: finalSerialNumber,
            deviceType: deviceType,
            customProperties: customProperties
        )
    }
    
    /// 验证设备配置
    /// - Parameter configuration: 设备配置
    /// - Returns: 验证结果
    public static func validateDeviceConfiguration(_ configuration: DeviceConfiguration) -> ValidationResult {
        var errors: [String] = []
        
        // 基本字段验证
        if configuration.id.isEmpty {
            errors.append("设备ID不能为空")
        }
        
        if configuration.name.isEmpty {
            errors.append("设备名称不能为空")
        }
        
        if configuration.modelName.isEmpty {
            errors.append("设备型号不能为空")
        }
        
        if configuration.serialNumber.isEmpty {
            errors.append("设备序列号不能为空")
        }
        
        // 设备类型特定验证
        let typeSpecificErrors = validateDeviceTypeSpecificProperties(configuration)
        errors.append(contentsOf: typeSpecificErrors)
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors
        )
    }
    
    /// 验证设备类型特定属性
    private static func validateDeviceTypeSpecificProperties(_ configuration: DeviceConfiguration) -> [String] {
        var errors: [String] = []
        
        switch configuration.deviceType {
        case .sweepingRobot, .poolRobot:
            if let batteryCapacity = configuration.customProperties["batteryCapacity"] as? Int,
               batteryCapacity <= 0 {
                errors.append("电池容量必须大于0")
            }
            
        case .energyStorage:
            if let capacity = configuration.customProperties["batteryCapacity"] as? Double,
               capacity <= 0 {
                errors.append("储能容量必须大于0")
            }
            
            if let chargingPower = configuration.customProperties["maxChargingPower"] as? Double,
               chargingPower <= 0 {
                errors.append("最大充电功率必须大于0")
            }
            
        default:
            break
        }
        
        return errors
    }
    
    /// 生成设备摘要信息
    /// - Parameter device: 设备实例
    /// - Returns: 设备摘要
    public static func generateDeviceSummary(_ device: any Device) -> DeviceSummary {
        var capabilities: [String] = []
        
        // 检查设备能力
        if device is Connectable {
            capabilities.append("网络连接")
        }
        
        if device is BatteryPowered {
            capabilities.append("电池供电")
        }
        
        if device is Controllable {
            capabilities.append("远程控制")
        }
        
        return DeviceSummary(
            id: device.id,
            name: device.name,
            type: device.deviceType,
            manufacturer: device.manufacturer,
            modelName: device.modelName,
            isOnline: device.isConnected,
            capabilities: capabilities,
            lastUpdated: device.lastUpdated
        )
    }
}

// MARK: - Supporting Types

/// 验证结果
public struct ValidationResult {
    /// 是否有效
    public let isValid: Bool
    
    /// 错误信息
    public let errors: [String]
    
    /// 错误描述
    public var errorDescription: String? {
        return errors.isEmpty ? nil : errors.joined(separator: "; ")
    }
}

/// 设备摘要信息
public struct DeviceSummary {
    /// 设备ID
    public let id: String
    
    /// 设备名称
    public let name: String
    
    /// 设备类型
    public let type: DeviceType
    
    /// 制造商
    public let manufacturer: String
    
    /// 型号
    public let modelName: String
    
    /// 是否在线
    public let isOnline: Bool
    
    /// 设备能力
    public let capabilities: [String]
    
    /// 最后更新时间
    public let lastUpdated: Date
    
    /// 摘要描述
    public var description: String {
        let status = isOnline ? "在线" : "离线"
        let capabilityText = capabilities.isEmpty ? "无特殊能力" : capabilities.joined(separator: ", ")
        
        return """
        \(name) (\(type.displayName))
        制造商: \(manufacturer)
        型号: \(modelName)
        状态: \(status)
        能力: \(capabilityText)
        """
    }
}

// MARK: - Module Export

/// 模块导出函数
public func initializeDomainLayer(with configuration: DomainLayerConfiguration = .default) {
    DomainLayerManager.shared.initialize(with: configuration)
}

/// 获取设备工厂实例
public func getDeviceFactory() -> DeviceFactory {
    return DomainLayerManager.shared.deviceFactory
}

/// 获取模块状态
public func getDomainLayerStatus() -> DomainLayerStatus {
    return DomainLayerManager.shared.getModuleStatus()
}

// MARK: - Debug Support

#if DEBUG
/// 调试工具
public enum DomainLayerDebug {
    
    /// 打印所有支持的设备类型
    public static func printSupportedDeviceTypes() {
        let factory = getDeviceFactory()
        let types = factory.supportedDeviceTypes()
        
        print("=== 支持的设备类型 ===")
        for type in types {
            print("- \(type.displayName) (\(type.rawValue))")
        }
        print("总计: \(types.count) 种设备类型")
    }
    
    /// 创建测试设备
    public static func createTestDevices() -> [any Device] {
        let factory = getDeviceFactory()
        var devices: [any Device] = []
        
        do {
            // 创建测试扫地机器人
            let sweepingRobot = try factory.createSweepingRobot(
                id: "test-sweeping-001",
                name: "测试扫地机器人",
                modelName: "TestBot-2024",
                serialNumber: "SN001"
            )
            devices.append(sweepingRobot)
            
            // 创建测试泳池机器人
            let poolRobot = try factory.createPoolRobot(
                id: "test-pool-001",
                name: "测试泳池机器人",
                modelName: "PoolBot-2024",
                serialNumber: "SN002"
            )
            devices.append(poolRobot)
            
            // 创建测试储能设备
            let energyStorage = try factory.createEnergyStorage(
                id: "test-energy-001",
                name: "测试储能设备",
                modelName: "EnergyBox-2024",
                serialNumber: "SN003"
            )
            devices.append(energyStorage)
            
            print("✅ 成功创建 \(devices.count) 个测试设备")
            
        } catch {
            print("❌ 创建测试设备失败: \(error.localizedDescription)")
        }
        
        return devices
    }
    
    /// 测试设备工厂功能
    public static func testDeviceFactory() {
        print("=== 测试设备工厂 ===")
        
        let factory = getDeviceFactory()
        
        // 测试支持的设备类型
        let supportedTypes = factory.supportedDeviceTypes()
        print("支持的设备类型数量: \(supportedTypes.count)")
        
        // 测试设备创建
        let testDevices = createTestDevices()
        
        for device in testDevices {
            let summary = DomainLayerUtils.generateDeviceSummary(device)
            print("设备摘要: \(summary.description)")
        }
    }
}
#endif