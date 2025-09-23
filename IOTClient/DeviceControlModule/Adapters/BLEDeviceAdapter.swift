//
//  BLEDeviceAdapter.swift
//  DeviceControlModule
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine
import CoreBluetooth

/// BLE设备适配器 - 将现有BLE功能整合到DeviceControlModule架构中
public class BLEDeviceAdapter: NSObject, DeviceAdapterProtocol {
    
    // MARK: - Properties
    
    public let adapterType: DeviceAdapterType = .bluetooth
    public let supportedDeviceTypes: [DeviceType] = [.light, .sensor, .switch, .thermostat, .camera]
    
    private let bleManager: BLEManager
    private let bleServiceManager: BLEServiceManager
    
    private var deviceControllers: [String: BaseDeviceController] = [:]
    private var peripheralToDeviceId: [UUID: String] = [:]
    private var deviceIdToPeripheral: [String: CBPeripheral] = [:]
    
    private let connectionStateSubject = PassthroughSubject<(String, DeviceConnectionState), Never>()
    private let deviceEventSubject = PassthroughSubject<DeviceEvent, Never>()
    private let discoveredDeviceSubject = PassthroughSubject<DiscoveredDevice, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public override init() {
        self.bleManager = BLEManager.shared
        self.bleServiceManager = BLEServiceManager.shared
        super.init()
        
        setupBLEManagerDelegate()
        bleManager.initialize()
    }
    
    // MARK: - DeviceAdapterProtocol Implementation
    
    public func initialize() -> AnyPublisher<Void, DeviceControlError> {
        return Just(())
            .setFailureType(to: DeviceControlError.self)
            .eraseToAnyPublisher()
    }
    
    public func shutdown() -> AnyPublisher<Void, DeviceControlError> {
        bleManager.stopScanning()
        bleManager.disconnectAll()
        deviceControllers.removeAll()
        peripheralToDeviceId.removeAll()
        deviceIdToPeripheral.removeAll()
        
        return Just(())
            .setFailureType(to: DeviceControlError.self)
            .eraseToAnyPublisher()
    }
    
    public func discoverDevices() -> AnyPublisher<DiscoveredDevice, DeviceControlError> {
        bleManager.startScanning()
        
        return discoveredDeviceSubject
            .setFailureType(to: DeviceControlError.self)
            .eraseToAnyPublisher()
    }
    
    public func stopDiscovery() {
        bleManager.stopScanning()
    }
    
    public func connectToDevice(_ deviceInfo: DeviceInfo) -> AnyPublisher<DeviceConnectionState, DeviceControlError> {
        guard let peripheral = deviceIdToPeripheral[deviceInfo.deviceId] else {
            return Fail(error: DeviceControlError.deviceNotFound("BLE peripheral not found for device: \(deviceInfo.deviceId)"))
                .eraseToAnyPublisher()
        }
        
        bleManager.connect(to: peripheral)
        
        return connectionStateSubject
            .filter { $0.0 == deviceInfo.deviceId }
            .map { $0.1 }
            .setFailureType(to: DeviceControlError.self)
            .eraseToAnyPublisher()
    }
    
    public func disconnectFromDevice(_ deviceId: String) -> AnyPublisher<Void, DeviceControlError> {
        guard let peripheral = deviceIdToPeripheral[deviceId] else {
            return Fail(error: DeviceControlError.deviceNotFound("BLE peripheral not found for device: \(deviceId)"))
                .eraseToAnyPublisher()
        }
        
        bleManager.disconnect(from: peripheral)
        
        return Just(())
            .setFailureType(to: DeviceControlError.self)
            .eraseToAnyPublisher()
    }
    
    public func executeCommand(_ command: DeviceCommandProtocol) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        guard let peripheral = deviceIdToPeripheral[command.targetDeviceId] else {
            return Fail(error: DeviceControlError.deviceNotFound("BLE peripheral not found for device: \(command.targetDeviceId)"))
                .eraseToAnyPublisher()
        }
        
        return executeBLECommand(command, peripheral: peripheral)
    }
    
    public func getDeviceStatus(_ deviceId: String) -> AnyPublisher<DeviceStatus, DeviceControlError> {
        guard let peripheral = deviceIdToPeripheral[deviceId] else {
            return Fail(error: DeviceControlError.deviceNotFound("BLE peripheral not found for device: \(deviceId)"))
                .eraseToAnyPublisher()
        }
        
        return requestBLEDeviceStatus(deviceId: deviceId, peripheral: peripheral)
    }
    
    public var connectionStatePublisher: AnyPublisher<(String, DeviceConnectionState), Never> {
        return connectionStateSubject.eraseToAnyPublisher()
    }
    
    public var deviceEventPublisher: AnyPublisher<DeviceEvent, Never> {
        return deviceEventSubject.eraseToAnyPublisher()
    }
    
    // MARK: - BLE Command Execution
    
    private func executeB LECommand(_ command: DeviceCommandProtocol, peripheral: CBPeripheral) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        return Future<DeviceCommandResult, DeviceControlError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown("Adapter deallocated")))
                return
            }
            
            let startTime = Date()
            
            switch command.commandType {
            case .switch:
                self.executeSwitchCommand(command, peripheral: peripheral, promise: promise, startTime: startTime)
                
            case .dimming:
                self.executeDimmingCommand(command, peripheral: peripheral, promise: promise, startTime: startTime)
                
            case .color:
                self.executeColorCommand(command, peripheral: peripheral, promise: promise, startTime: startTime)
                
            case .temperature:
                self.executeTemperatureCommand(command, peripheral: peripheral, promise: promise, startTime: startTime)
                
            case .status:
                self.executeStatusCommand(command, peripheral: peripheral, promise: promise, startTime: startTime)
                
            case .custom:
                self.executeCustomCommand(command, peripheral: peripheral, promise: promise, startTime: startTime)
                
            default:
                promise(.failure(.commandNotSupported("BLE adapter does not support command type: \(command.commandType)")))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func executeSwitchCommand(_ command: DeviceCommandProtocol, peripheral: CBPeripheral, promise: @escaping (Result<DeviceCommandResult, DeviceControlError>) -> Void, startTime: Date) {
        guard let isOn = command.parameters["isOn"] as? Bool else {
            promise(.failure(.invalidParameters("Missing 'isOn' parameter for switch command")))
            return
        }
        
        let commandData = Data([isOn ? 0x01 : 0x00])
        bleManager.writeData(commandData, to: BLEServiceManager.robotControlCharacteristicUUID, for: peripheral)
        
        // 模拟命令执行结果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let result = DeviceCommandResult(
                commandId: command.commandId,
                status: .completed,
                result: ["success": true, "state": isOn],
                error: nil,
                executionTime: Date().timeIntervalSince(startTime),
                timestamp: Date()
            )
            promise(.success(result))
        }
    }
    
    private func executeDimmingCommand(_ command: DeviceCommandProtocol, peripheral: CBPeripheral, promise: @escaping (Result<DeviceCommandResult, DeviceControlError>) -> Void, startTime: Date) {
        guard let brightness = command.parameters["brightness"] as? Int,
              brightness >= 0 && brightness <= 100 else {
            promise(.failure(.invalidParameters("Invalid 'brightness' parameter for dimming command")))
            return
        }
        
        let commandData = Data([0x10, UInt8(brightness)])
        bleManager.writeData(commandData, to: BLEServiceManager.robotControlCharacteristicUUID, for: peripheral)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let result = DeviceCommandResult(
                commandId: command.commandId,
                status: .completed,
                result: ["success": true, "brightness": brightness],
                error: nil,
                executionTime: Date().timeIntervalSince(startTime),
                timestamp: Date()
            )
            promise(.success(result))
        }
    }
    
    private func executeColorCommand(_ command: DeviceCommandProtocol, peripheral: CBPeripheral, promise: @escaping (Result<DeviceCommandResult, DeviceControlError>) -> Void, startTime: Date) {
        guard let colorDict = command.parameters["color"] as? [String: Any],
              let red = colorDict["red"] as? Int,
              let green = colorDict["green"] as? Int,
              let blue = colorDict["blue"] as? Int else {
            promise(.failure(.invalidParameters("Invalid 'color' parameter for color command")))
            return
        }
        
        let commandData = Data([0x20, UInt8(red), UInt8(green), UInt8(blue)])
        bleManager.writeData(commandData, to: BLEServiceManager.robotControlCharacteristicUUID, for: peripheral)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let result = DeviceCommandResult(
                commandId: command.commandId,
                status: .completed,
                result: ["success": true, "color": ["red": red, "green": green, "blue": blue]],
                error: nil,
                executionTime: Date().timeIntervalSince(startTime),
                timestamp: Date()
            )
            promise(.success(result))
        }
    }
    
    private func executeTemperatureCommand(_ command: DeviceCommandProtocol, peripheral: CBPeripheral, promise: @escaping (Result<DeviceCommandResult, DeviceControlError>) -> Void, startTime: Date) {
        guard let temperature = command.parameters["temperature"] as? Double else {
            promise(.failure(.invalidParameters("Missing 'temperature' parameter for temperature command")))
            return
        }
        
        let tempInt = Int(temperature * 10) // 转换为整数，保留一位小数
        let commandData = Data([0x30, UInt8(tempInt & 0xFF), UInt8((tempInt >> 8) & 0xFF)])
        bleManager.writeData(commandData, to: BLEServiceManager.robotControlCharacteristicUUID, for: peripheral)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let result = DeviceCommandResult(
                commandId: command.commandId,
                status: .completed,
                result: ["success": true, "temperature": temperature],
                error: nil,
                executionTime: Date().timeIntervalSince(startTime),
                timestamp: Date()
            )
            promise(.success(result))
        }
    }
    
    private func executeStatusCommand(_ command: DeviceCommandProtocol, peripheral: CBPeripheral, promise: @escaping (Result<DeviceCommandResult, DeviceControlError>) -> Void, startTime: Date) {
        bleServiceManager.requestDeviceStatus(from: peripheral)
        bleServiceManager.requestBatteryLevel(from: peripheral)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let result = DeviceCommandResult(
                commandId: command.commandId,
                status: .completed,
                result: [
                    "success": true,
                    "status": "online",
                    "batteryLevel": Int.random(in: 20...100),
                    "signalStrength": Int.random(in: -80...(-30))
                ],
                error: nil,
                executionTime: Date().timeIntervalSince(startTime),
                timestamp: Date()
            )
            promise(.success(result))
        }
    }
    
    private func executeCustomCommand(_ command: DeviceCommandProtocol, peripheral: CBPeripheral, promise: @escaping (Result<DeviceCommandResult, DeviceControlError>) -> Void, startTime: Date) {
        guard let commandData = command.parameters["data"] as? Data else {
            promise(.failure(.invalidParameters("Missing 'data' parameter for custom command")))
            return
        }
        
        bleServiceManager.sendCustomCommand(commandData, to: peripheral)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let result = DeviceCommandResult(
                commandId: command.commandId,
                status: .completed,
                result: ["success": true, "dataLength": commandData.count],
                error: nil,
                executionTime: Date().timeIntervalSince(startTime),
                timestamp: Date()
            )
            promise(.success(result))
        }
    }
    
    // MARK: - Device Status
    
    private func requestBLEDeviceStatus(deviceId: String, peripheral: CBPeripheral) -> AnyPublisher<DeviceStatus, DeviceControlError> {
        return Future<DeviceStatus, DeviceControlError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown("Adapter deallocated")))
                return
            }
            
            self.bleServiceManager.requestDeviceStatus(from: peripheral)
            self.bleServiceManager.requestBatteryLevel(from: peripheral)
            
            // 模拟状态获取
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let connectionState: DeviceConnectionState = peripheral.state == .connected ? .connected : .disconnected
                
                let status = DeviceStatus(
                    deviceId: deviceId,
                    connectionState: connectionState,
                    batteryLevel: Int.random(in: 20...100),
                    signalStrength: Int.random(in: -80...(-30)),
                    lastSeen: Date(),
                    properties: [
                        "rssi": Int.random(in: -80...(-30)),
                        "services": peripheral.services?.count ?? 0,
                        "mtu": 23
                    ]
                )
                
                promise(.success(status))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - BLE Manager Delegate Setup
    
    private func setupBLEManagerDelegate() {
        bleManager.delegate = self
    }
    
    // MARK: - Helper Methods
    
    private func createDeviceInfo(from peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) -> DeviceInfo {
        let deviceId = peripheral.identifier.uuidString
        let deviceName = peripheral.name ?? "Unknown BLE Device"
        
        // 根据广告数据推断设备类型
        let deviceType = inferDeviceType(from: advertisementData)
        
        return DeviceInfo(
            deviceId: deviceId,
            deviceName: deviceName,
            deviceType: deviceType,
            manufacturer: extractManufacturer(from: advertisementData),
            modelNumber: "BLE-\(deviceType.rawValue)",
            firmwareVersion: "1.0.0",
            capabilities: inferCapabilities(for: deviceType),
            connectionInfo: [
                "protocol": "BLE",
                "rssi": rssi.intValue,
                "advertisementData": advertisementData
            ]
        )
    }
    
    private func inferDeviceType(from advertisementData: [String: Any]) -> DeviceType {
        // 根据服务UUID或制造商数据推断设备类型
        if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            for uuid in serviceUUIDs {
                switch uuid.uuidString.uppercased() {
                case "180F": // Battery Service
                    return .sensor
                case "1812": // Human Interface Device
                    return .switch
                case "180A": // Device Information
                    return .light
                default:
                    continue
                }
            }
        }
        
        // 默认返回传感器类型
        return .sensor
    }
    
    private func extractManufacturer(from advertisementData: [String: Any]) -> String {
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
           manufacturerData.count >= 2 {
            let manufacturerId = UInt16(manufacturerData[0]) | (UInt16(manufacturerData[1]) << 8)
            return "Manufacturer-\(manufacturerId)"
        }
        return "Unknown"
    }
    
    private func inferCapabilities(for deviceType: DeviceType) -> [DeviceCapability] {
        switch deviceType {
        case .light:
            return [.switch, .dimming, .colorControl]
        case .sensor:
            return [.sensing, .statusReporting]
        case .switch:
            return [.switch]
        case .thermostat:
            return [.temperatureControl, .statusReporting]
        case .camera:
            return [.videoStreaming, .statusReporting]
        default:
            return [.statusReporting]
        }
    }
}

// MARK: - BLEManagerDelegate

extension BLEDeviceAdapter: BLEManagerDelegate {
    
    public func bleManagerDidUpdateState(_ state: CBManagerState) {
        let event = DeviceEvent(
            deviceId: "BLE_ADAPTER",
            eventType: .adapterStateChanged,
            data: ["state": state.rawValue],
            timestamp: Date()
        )
        deviceEventSubject.send(event)
    }
    
    public func bleManager(_ manager: BLEManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        let deviceInfo = createDeviceInfo(from: peripheral, advertisementData: advertisementData, rssi: rssi)
        
        // 存储设备映射
        peripheralToDeviceId[peripheral.identifier] = deviceInfo.deviceId
        deviceIdToPeripheral[deviceInfo.deviceId] = peripheral
        
        let discoveredDevice = DiscoveredDevice(
            deviceInfo: deviceInfo,
            discoveryMethod: "BLE Scan",
            discoveryTime: Date(),
            signalStrength: rssi.intValue
        )
        
        discoveredDeviceSubject.send(discoveredDevice)
    }
    
    public func bleManager(_ manager: BLEManager, didConnect peripheral: CBPeripheral) {
        if let deviceId = peripheralToDeviceId[peripheral.identifier] {
            connectionStateSubject.send((deviceId, .connected))
            
            let event = DeviceEvent(
                deviceId: deviceId,
                eventType: .connected,
                data: [:],
                timestamp: Date()
            )
            deviceEventSubject.send(event)
        }
    }
    
    public func bleManager(_ manager: BLEManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let deviceId = peripheralToDeviceId[peripheral.identifier] {
            connectionStateSubject.send((deviceId, .error))
            
            let event = DeviceEvent(
                deviceId: deviceId,
                eventType: .connectionFailed,
                data: ["error": error?.localizedDescription ?? "Unknown error"],
                timestamp: Date()
            )
            deviceEventSubject.send(event)
        }
    }
    
    public func bleManager(_ manager: BLEManager, didDisconnect peripheral: CBPeripheral, error: Error?) {
        if let deviceId = peripheralToDeviceId[peripheral.identifier] {
            connectionStateSubject.send((deviceId, .disconnected))
            
            let event = DeviceEvent(
                deviceId: deviceId,
                eventType: .disconnected,
                data: ["error": error?.localizedDescription],
                timestamp: Date()
            )
            deviceEventSubject.send(event)
        }
    }
}

// MARK: - Device Adapter Type

public enum DeviceAdapterType: String, CaseIterable {
    case bluetooth = "BLE"
    case mqtt = "MQTT"
    case zigbee = "Zigbee"
    case matter = "Matter"
    case wifi = "WiFi"
    case ethernet = "Ethernet"
    
    public var displayName: String {
        switch self {
        case .bluetooth:
            return "蓝牙"
        case .mqtt:
            return "MQTT"
        case .zigbee:
            return "Zigbee"
        case .matter:
            return "Matter"
        case .wifi:
            return "WiFi"
        case .ethernet:
            return "以太网"
        }
    }
}

// MARK: - Device Adapter Protocol

public protocol DeviceAdapterProtocol: AnyObject {
    var adapterType: DeviceAdapterType { get }
    var supportedDeviceTypes: [DeviceType] { get }
    
    func initialize() -> AnyPublisher<Void, DeviceControlError>
    func shutdown() -> AnyPublisher<Void, DeviceControlError>
    
    func discoverDevices() -> AnyPublisher<DiscoveredDevice, DeviceControlError>
    func stopDiscovery()
    
    func connectToDevice(_ deviceInfo: DeviceInfo) -> AnyPublisher<DeviceConnectionState, DeviceControlError>
    func disconnectFromDevice(_ deviceId: String) -> AnyPublisher<Void, DeviceControlError>
    
    func executeCommand(_ command: DeviceCommandProtocol) -> AnyPublisher<DeviceCommandResult, DeviceControlError>
    func getDeviceStatus(_ deviceId: String) -> AnyPublisher<DeviceStatus, DeviceControlError>
    
    var connectionStatePublisher: AnyPublisher<(String, DeviceConnectionState), Never> { get }
    var deviceEventPublisher: AnyPublisher<DeviceEvent, Never> { get }
}