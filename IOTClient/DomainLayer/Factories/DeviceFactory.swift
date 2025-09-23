//
//  DeviceFactory.swift
//  DomainLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation

/// 设备工厂协议
/// 定义了创建设备的标准接口
public protocol DeviceFactoryProtocol {
    /// 根据设备类型和配置创建设备
    /// - Parameters:
    ///   - type: 设备类型
    ///   - configuration: 设备配置信息
    /// - Returns: 创建的设备实例
    /// - Throws: 设备创建错误
    func createDevice(type: DeviceType, configuration: DeviceConfiguration) throws -> any Device
    
    /// 根据原始数据创建设备
    /// - Parameter data: 设备原始数据
    /// - Returns: 创建的设备实例
    /// - Throws: 设备创建错误
    func createDevice(from data: Data) throws -> any Device
    
    /// 检查是否支持指定设备类型
    /// - Parameter type: 设备类型
    /// - Returns: 是否支持该设备类型
    func supportsDeviceType(_ type: DeviceType) -> Bool
    
    /// 获取支持的设备类型列表
    /// - Returns: 支持的设备类型数组
    func supportedDeviceTypes() -> [DeviceType]
}

/// 设备工厂实现类
public class DeviceFactory: DeviceFactoryProtocol {
    
    /// 单例实例
    public static let shared = DeviceFactory()
    
    /// 设备创建器映射表
    private var deviceCreators: [DeviceType: DeviceCreatorProtocol] = [:]
    
    /// 私有初始化器
    private init() {
        registerDefaultCreators()
    }
    
    /// 注册默认的设备创建器
    private func registerDefaultCreators() {
        deviceCreators[.sweepingRobot] = SweepingRobotCreator()
        deviceCreators[.poolRobot] = PoolRobotCreator()
        deviceCreators[.energyStorage] = EnergyStorageCreator()
        deviceCreators[.smartPlug] = SmartPlugCreator()
        deviceCreators[.smartLight] = SmartLightCreator()
        deviceCreators[.smartCamera] = SmartCameraCreator()
    }
    
    /// 注册自定义设备创建器
    /// - Parameters:
    ///   - type: 设备类型
    ///   - creator: 设备创建器
    public func registerCreator(_ creator: DeviceCreatorProtocol, for type: DeviceType) {
        deviceCreators[type] = creator
    }
    
    /// 注销设备创建器
    /// - Parameter type: 设备类型
    public func unregisterCreator(for type: DeviceType) {
        deviceCreators.removeValue(forKey: type)
    }
    
    // MARK: - DeviceFactoryProtocol Implementation
    
    public func createDevice(type: DeviceType, configuration: DeviceConfiguration) throws -> any Device {
        guard let creator = deviceCreators[type] else {
            throw DeviceFactoryError.unsupportedDeviceType(type)
        }
        
        do {
            let device = try creator.createDevice(configuration: configuration)
            print("✅ 成功创建设备: \(type.displayName) - \(device.name)")
            return device
        } catch {
            print("❌ 创建设备失败: \(type.displayName) - \(error.localizedDescription)")
            throw DeviceFactoryError.creationFailed(type, error)
        }
    }
    
    public func createDevice(from data: Data) throws -> any Device {
        // 首先尝试解析设备类型
        let decoder = JSONDecoder()
        
        do {
            // 先解析基本设备信息以获取设备类型
            let basicInfo = try decoder.decode(BasicDeviceInfo.self, from: data)
            
            guard let creator = deviceCreators[basicInfo.deviceType] else {
                throw DeviceFactoryError.unsupportedDeviceType(basicInfo.deviceType)
            }
            
            let device = try creator.createDevice(from: data)
            print("✅ 从数据成功创建设备: \(basicInfo.deviceType.displayName) - \(device.name)")
            return device
            
        } catch let decodingError as DecodingError {
            print("❌ 解析设备数据失败: \(decodingError.localizedDescription)")
            throw DeviceFactoryError.invalidData(decodingError)
        } catch {
            print("❌ 从数据创建设备失败: \(error.localizedDescription)")
            throw DeviceFactoryError.creationFailed(.unknown, error)
        }
    }
    
    public func supportsDeviceType(_ type: DeviceType) -> Bool {
        return deviceCreators[type] != nil
    }
    
    public func supportedDeviceTypes() -> [DeviceType] {
        return Array(deviceCreators.keys).sorted { $0.rawValue < $1.rawValue }
    }
}

// MARK: - Device Creator Protocol

/// 设备创建器协议
public protocol DeviceCreatorProtocol {
    /// 根据配置创建设备
    /// - Parameter configuration: 设备配置
    /// - Returns: 创建的设备实例
    /// - Throws: 创建错误
    func createDevice(configuration: DeviceConfiguration) throws -> any Device
    
    /// 从数据创建设备
    /// - Parameter data: 设备数据
    /// - Returns: 创建的设备实例
    /// - Throws: 创建错误
    func createDevice(from data: Data) throws -> any Device
    
    /// 验证配置是否有效
    /// - Parameter configuration: 设备配置
    /// - Returns: 配置是否有效
    func validateConfiguration(_ configuration: DeviceConfiguration) -> Bool
}

// MARK: - Device Creators

/// 扫地机器人创建器
public class SweepingRobotCreator: DeviceCreatorProtocol {
    
    public func createDevice(configuration: DeviceConfiguration) throws -> any Device {
        guard validateConfiguration(configuration) else {
            throw DeviceFactoryError.invalidConfiguration("扫地机器人配置无效")
        }
        
        let robot = SweepingRobot(
            id: configuration.id,
            name: configuration.name,
            modelName: configuration.modelName,
            firmwareVersion: configuration.firmwareVersion,
            manufacturer: configuration.manufacturer,
            serialNumber: configuration.serialNumber,
            batteryCapacity: configuration.customProperties["batteryCapacity"] as? Int ?? 3200
        )
        
        return robot
    }
    
    public func createDevice(from data: Data) throws -> any Device {
        let decoder = JSONDecoder()
        return try decoder.decode(SweepingRobot.self, from: data)
    }
    
    public func validateConfiguration(_ configuration: DeviceConfiguration) -> Bool {
        return !configuration.id.isEmpty &&
               !configuration.name.isEmpty &&
               !configuration.modelName.isEmpty &&
               !configuration.serialNumber.isEmpty
    }
}

/// 泳池机器人创建器
public class PoolRobotCreator: DeviceCreatorProtocol {
    
    public func createDevice(configuration: DeviceConfiguration) throws -> any Device {
        guard validateConfiguration(configuration) else {
            throw DeviceFactoryError.invalidConfiguration("泳池机器人配置无效")
        }
        
        let robot = PoolRobot(
            id: configuration.id,
            name: configuration.name,
            modelName: configuration.modelName,
            firmwareVersion: configuration.firmwareVersion,
            manufacturer: configuration.manufacturer,
            serialNumber: configuration.serialNumber,
            batteryCapacity: configuration.customProperties["batteryCapacity"] as? Int ?? 5000,
            maxDepth: configuration.customProperties["maxDepth"] as? Double ?? 3.0
        )
        
        return robot
    }
    
    public func createDevice(from data: Data) throws -> any Device {
        let decoder = JSONDecoder()
        return try decoder.decode(PoolRobot.self, from: data)
    }
    
    public func validateConfiguration(_ configuration: DeviceConfiguration) -> Bool {
        return !configuration.id.isEmpty &&
               !configuration.name.isEmpty &&
               !configuration.modelName.isEmpty &&
               !configuration.serialNumber.isEmpty
    }
}

/// 储能设备创建器
public class EnergyStorageCreator: DeviceCreatorProtocol {
    
    public func createDevice(configuration: DeviceConfiguration) throws -> any Device {
        guard validateConfiguration(configuration) else {
            throw DeviceFactoryError.invalidConfiguration("储能设备配置无效")
        }
        
        let storage = EnergyStorage(
            id: configuration.id,
            name: configuration.name,
            modelName: configuration.modelName,
            firmwareVersion: configuration.firmwareVersion,
            manufacturer: configuration.manufacturer,
            serialNumber: configuration.serialNumber,
            batteryCapacity: configuration.customProperties["batteryCapacity"] as? Double ?? 10.0,
            maxChargingPower: configuration.customProperties["maxChargingPower"] as? Double ?? 5.0,
            maxDischargingPower: configuration.customProperties["maxDischargingPower"] as? Double ?? 5.0
        )
        
        return storage
    }
    
    public func createDevice(from data: Data) throws -> any Device {
        let decoder = JSONDecoder()
        return try decoder.decode(EnergyStorage.self, from: data)
    }
    
    public func validateConfiguration(_ configuration: DeviceConfiguration) -> Bool {
        guard !configuration.id.isEmpty &&
              !configuration.name.isEmpty &&
              !configuration.modelName.isEmpty &&
              !configuration.serialNumber.isEmpty else {
            return false
        }
        
        // 验证储能设备特定参数
        if let capacity = configuration.customProperties["batteryCapacity"] as? Double,
           capacity <= 0 {
            return false
        }
        
        return true
    }
}

/// 智能插座创建器（占位符实现）
public class SmartPlugCreator: DeviceCreatorProtocol {
    
    public func createDevice(configuration: DeviceConfiguration) throws -> any Device {
        // TODO: 实现智能插座创建逻辑
        throw DeviceFactoryError.notImplemented("智能插座创建器尚未实现")
    }
    
    public func createDevice(from data: Data) throws -> any Device {
        // TODO: 实现从数据创建智能插座
        throw DeviceFactoryError.notImplemented("智能插座数据解析尚未实现")
    }
    
    public func validateConfiguration(_ configuration: DeviceConfiguration) -> Bool {
        return false // 暂未实现
    }
}

/// 智能灯具创建器（占位符实现）
public class SmartLightCreator: DeviceCreatorProtocol {
    
    public func createDevice(configuration: DeviceConfiguration) throws -> any Device {
        // TODO: 实现智能灯具创建逻辑
        throw DeviceFactoryError.notImplemented("智能灯具创建器尚未实现")
    }
    
    public func createDevice(from data: Data) throws -> any Device {
        // TODO: 实现从数据创建智能灯具
        throw DeviceFactoryError.notImplemented("智能灯具数据解析尚未实现")
    }
    
    public func validateConfiguration(_ configuration: DeviceConfiguration) -> Bool {
        return false // 暂未实现
    }
}

/// 智能摄像头创建器（占位符实现）
public class SmartCameraCreator: DeviceCreatorProtocol {
    
    public func createDevice(configuration: DeviceConfiguration) throws -> any Device {
        // TODO: 实现智能摄像头创建逻辑
        throw DeviceFactoryError.notImplemented("智能摄像头创建器尚未实现")
    }
    
    public func createDevice(from data: Data) throws -> any Device {
        // TODO: 实现从数据创建智能摄像头
        throw DeviceFactoryError.notImplemented("智能摄像头数据解析尚未实现")
    }
    
    public func validateConfiguration(_ configuration: DeviceConfiguration) -> Bool {
        return false // 暂未实现
    }
}

// MARK: - Supporting Types

/// 设备配置信息
public struct DeviceConfiguration {
    /// 设备ID
    public let id: String
    
    /// 设备名称
    public let name: String
    
    /// 设备型号
    public let modelName: String
    
    /// 固件版本
    public let firmwareVersion: String
    
    /// 制造商
    public let manufacturer: String
    
    /// 序列号
    public let serialNumber: String
    
    /// 设备类型
    public let deviceType: DeviceType
    
    /// 自定义属性
    public let customProperties: [String: Any]
    
    public init(
        id: String,
        name: String,
        modelName: String,
        firmwareVersion: String,
        manufacturer: String,
        serialNumber: String,
        deviceType: DeviceType,
        customProperties: [String: Any] = [:]
    ) {
        self.id = id
        self.name = name
        self.modelName = modelName
        self.firmwareVersion = firmwareVersion
        self.manufacturer = manufacturer
        self.serialNumber = serialNumber
        self.deviceType = deviceType
        self.customProperties = customProperties
    }
}

/// 基本设备信息（用于从数据解析设备类型）
private struct BasicDeviceInfo: Codable {
    let deviceType: DeviceType
    let id: String
    let name: String
}

/// 设备工厂错误类型
public enum DeviceFactoryError: Error, LocalizedError {
    case unsupportedDeviceType(DeviceType)
    case invalidConfiguration(String)
    case invalidData(Error)
    case creationFailed(DeviceType, Error)
    case notImplemented(String)
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedDeviceType(let type):
            return "不支持的设备类型: \(type.displayName)"
        case .invalidConfiguration(let message):
            return "无效的设备配置: \(message)"
        case .invalidData(let error):
            return "无效的设备数据: \(error.localizedDescription)"
        case .creationFailed(let type, let error):
            return "创建设备失败 (\(type.displayName)): \(error.localizedDescription)"
        case .notImplemented(let message):
            return "功能尚未实现: \(message)"
        }
    }
}

// MARK: - Factory Extensions

public extension DeviceFactory {
    
    /// 便捷方法：创建扫地机器人
    func createSweepingRobot(
        id: String,
        name: String,
        modelName: String,
        firmwareVersion: String = "1.0.0",
        manufacturer: String = "Unknown",
        serialNumber: String,
        batteryCapacity: Int = 3200
    ) throws -> SweepingRobot {
        let configuration = DeviceConfiguration(
            id: id,
            name: name,
            modelName: modelName,
            firmwareVersion: firmwareVersion,
            manufacturer: manufacturer,
            serialNumber: serialNumber,
            deviceType: .sweepingRobot,
            customProperties: ["batteryCapacity": batteryCapacity]
        )
        
        let device = try createDevice(type: .sweepingRobot, configuration: configuration)
        return device as! SweepingRobot
    }
    
    /// 便捷方法：创建泳池机器人
    func createPoolRobot(
        id: String,
        name: String,
        modelName: String,
        firmwareVersion: String = "1.0.0",
        manufacturer: String = "Unknown",
        serialNumber: String,
        batteryCapacity: Int = 5000,
        maxDepth: Double = 3.0
    ) throws -> PoolRobot {
        let configuration = DeviceConfiguration(
            id: id,
            name: name,
            modelName: modelName,
            firmwareVersion: firmwareVersion,
            manufacturer: manufacturer,
            serialNumber: serialNumber,
            deviceType: .poolRobot,
            customProperties: [
                "batteryCapacity": batteryCapacity,
                "maxDepth": maxDepth
            ]
        )
        
        let device = try createDevice(type: .poolRobot, configuration: configuration)
        return device as! PoolRobot
    }
    
    /// 便捷方法：创建储能设备
    func createEnergyStorage(
        id: String,
        name: String,
        modelName: String,
        firmwareVersion: String = "1.0.0",
        manufacturer: String = "Unknown",
        serialNumber: String,
        batteryCapacity: Double = 10.0,
        maxChargingPower: Double = 5.0,
        maxDischargingPower: Double = 5.0
    ) throws -> EnergyStorage {
        let configuration = DeviceConfiguration(
            id: id,
            name: name,
            modelName: modelName,
            firmwareVersion: firmwareVersion,
            manufacturer: manufacturer,
            serialNumber: serialNumber,
            deviceType: .energyStorage,
            customProperties: [
                "batteryCapacity": batteryCapacity,
                "maxChargingPower": maxChargingPower,
                "maxDischargingPower": maxDischargingPower
            ]
        )
        
        let device = try createDevice(type: .energyStorage, configuration: configuration)
        return device as! EnergyStorage
    }
}