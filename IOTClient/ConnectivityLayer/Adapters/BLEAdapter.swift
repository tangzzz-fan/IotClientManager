//
//  BLEAdapter.swift
//  ConnectivityLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine
import CoreBluetooth

/// BLE消息结构
public struct BLEMessage: Codable {
    /// 特征UUID
    public let characteristicUUID: String
    
    /// 服务UUID
    public let serviceUUID: String
    
    /// 消息数据
    public let data: Data
    
    /// 消息类型
    public let messageType: BLEMessageType
    
    /// 设备标识符
    public let deviceIdentifier: String
    
    /// 时间戳
    public let timestamp: Date
    
    /// 信号强度
    public let rssi: Int?
    
    public init(
        characteristicUUID: String,
        serviceUUID: String,
        data: Data,
        messageType: BLEMessageType,
        deviceIdentifier: String,
        timestamp: Date = Date(),
        rssi: Int? = nil
    ) {
        self.characteristicUUID = characteristicUUID
        self.serviceUUID = serviceUUID
        self.data = data
        self.messageType = messageType
        self.deviceIdentifier = deviceIdentifier
        self.timestamp = timestamp
        self.rssi = rssi
    }
    
    /// 从字符串创建消息
    public init(
        characteristicUUID: String,
        serviceUUID: String,
        message: String,
        messageType: BLEMessageType,
        deviceIdentifier: String
    ) {
        self.init(
            characteristicUUID: characteristicUUID,
            serviceUUID: serviceUUID,
            data: message.data(using: .utf8) ?? Data(),
            messageType: messageType,
            deviceIdentifier: deviceIdentifier
        )
    }
    
    /// 获取消息内容字符串
    public var messageString: String? {
        return String(data: data, encoding: .utf8)
    }
    
    /// 消息大小（字节）
    public var size: Int {
        return data.count
    }
}

/// BLE消息类型
public enum BLEMessageType: String, CaseIterable, Codable {
    case read = "read"
    case write = "write"
    case notify = "notify"
    case indicate = "indicate"
    
    public var displayName: String {
        switch self {
        case .read:
            return "读取"
        case .write:
            return "写入"
        case .notify:
            return "通知"
        case .indicate:
            return "指示"
        }
    }
}

/// BLE连接配置
public struct BLEConfiguration {
    /// 扫描服务UUID列表
    public let scanServiceUUIDs: [String]?
    
    /// 扫描超时时间（秒）
    public let scanTimeout: TimeInterval
    
    /// 连接超时时间（秒）
    public let connectionTimeout: TimeInterval
    
    /// 自动重连
    public let autoReconnect: Bool
    
    /// 允许重复设备
    public let allowDuplicates: Bool
    
    /// 扫描选项
    public let scanOptions: [String: Any]
    
    /// 连接选项
    public let connectionOptions: [String: Any]
    
    /// 最大并发连接数
    public let maxConcurrentConnections: Int
    
    /// 特征配置
    public let characteristicConfigurations: [BLECharacteristicConfiguration]
    
    public init(
        scanServiceUUIDs: [String]? = nil,
        scanTimeout: TimeInterval = 30,
        connectionTimeout: TimeInterval = 10,
        autoReconnect: Bool = true,
        allowDuplicates: Bool = false,
        scanOptions: [String: Any] = [:],
        connectionOptions: [String: Any] = [:],
        maxConcurrentConnections: Int = 5,
        characteristicConfigurations: [BLECharacteristicConfiguration] = []
    ) {
        self.scanServiceUUIDs = scanServiceUUIDs
        self.scanTimeout = scanTimeout
        self.connectionTimeout = connectionTimeout
        self.autoReconnect = autoReconnect
        self.allowDuplicates = allowDuplicates
        self.scanOptions = scanOptions
        self.connectionOptions = connectionOptions
        self.maxConcurrentConnections = maxConcurrentConnections
        self.characteristicConfigurations = characteristicConfigurations
    }
    
    /// 创建默认配置
    public static var `default`: BLEConfiguration {
        return BLEConfiguration()
    }
}

/// BLE特征配置
public struct BLECharacteristicConfiguration {
    /// 服务UUID
    public let serviceUUID: String
    
    /// 特征UUID
    public let characteristicUUID: String
    
    /// 是否启用通知
    public let enableNotification: Bool
    
    /// 是否启用指示
    public let enableIndication: Bool
    
    /// 写入类型
    public let writeType: CBCharacteristicWriteType
    
    public init(
        serviceUUID: String,
        characteristicUUID: String,
        enableNotification: Bool = false,
        enableIndication: Bool = false,
        writeType: CBCharacteristicWriteType = .withResponse
    ) {
        self.serviceUUID = serviceUUID
        self.characteristicUUID = characteristicUUID
        self.enableNotification = enableNotification
        self.enableIndication = enableIndication
        self.writeType = writeType
    }
}

/// BLE发现的设备信息
public struct BLEDiscoveredDevice {
    /// 外设对象
    public let peripheral: CBPeripheral
    
    /// 广告数据
    public let advertisementData: [String: Any]
    
    /// 信号强度
    public let rssi: NSNumber
    
    /// 发现时间
    public let discoveredAt: Date
    
    /// 设备名称
    public var name: String? {
        return peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
    }
    
    /// 设备标识符
    public var identifier: String {
        return peripheral.identifier.uuidString
    }
    
    /// 服务UUID列表
    public var serviceUUIDs: [String] {
        let uuids = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        return uuids.map { $0.uuidString }
    }
    
    /// 是否可连接
    public var isConnectable: Bool {
        return advertisementData[CBAdvertisementDataIsConnectable] as? Bool ?? false
    }
    
    /// 制造商数据
    public var manufacturerData: Data? {
        return advertisementData[CBAdvertisticDataManufacturerDataKey] as? Data
    }
    
    public init(
        peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi: NSNumber,
        discoveredAt: Date = Date()
    ) {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.rssi = rssi
        self.discoveredAt = discoveredAt
    }
}

/// BLE扫描配置
public struct BLEScanConfiguration {
    /// 扫描服务UUID
    public let serviceUUIDs: [String]?
    
    /// 扫描选项
    public let options: [String: Any]
    
    /// 扫描持续时间（秒）
    public let duration: TimeInterval?
    
    /// 信号强度过滤
    public let rssiThreshold: Int?
    
    public init(
        serviceUUIDs: [String]? = nil,
        options: [String: Any] = [:],
        duration: TimeInterval? = nil,
        rssiThreshold: Int? = nil
    ) {
        self.serviceUUIDs = serviceUUIDs
        self.options = options
        self.duration = duration
        self.rssiThreshold = rssiThreshold
    }
    
    /// 创建默认扫描配置
    public static var `default`: BLEScanConfiguration {
        return BLEScanConfiguration()
    }
}

/// BLE适配器实现
public final class BLEAdapter: NSObject, CommunicationService, DeviceDiscovery {
    
    // MARK: - Type Aliases
    
    public typealias Configuration = BLEConfiguration
    public typealias Message = BLEMessage
    public typealias DiscoveredDevice = BLEDiscoveredDevice
    public typealias ScanConfiguration = BLEScanConfiguration
    
    // MARK: - CommunicationService Properties
    
    public let serviceId: String
    public let serviceName: String = "BLE服务"
    
    @Published private var _connectionState: ConnectionState = .disconnected
    public var connectionState: ConnectionState {
        return _connectionState
    }
    
    public var connectionStatePublisher: AnyPublisher<ConnectionState, Never> {
        return $_connectionState.eraseToAnyPublisher()
    }
    
    private let _messageSubject = PassthroughSubject<BLEMessage, Never>()
    public var messagePublisher: AnyPublisher<BLEMessage, Never> {
        return _messageSubject.eraseToAnyPublisher()
    }
    
    private let _errorSubject = PassthroughSubject<CommunicationError, Never>()
    public var errorPublisher: AnyPublisher<CommunicationError, Never> {
        return _errorSubject.eraseToAnyPublisher()
    }
    
    public let supportsAutoReconnect: Bool = true
    public var maxReconnectAttempts: Int = 3
    public var reconnectInterval: TimeInterval = 5.0
    
    // MARK: - DeviceDiscovery Properties
    
    public let discoveryId: String
    public let discoveryName: String = "BLE设备发现"
    
    @Published private var _scanState: ScanState = .idle
    public var scanState: ScanState {
        return _scanState
    }
    
    public var scanStatePublisher: AnyPublisher<ScanState, Never> {
        return $_scanState.eraseToAnyPublisher()
    }
    
    private let _discoveredDeviceSubject = PassthroughSubject<BLEDiscoveredDevice, Never>()
    public var discoveredDevicePublisher: AnyPublisher<BLEDiscoveredDevice, Never> {
        return _discoveredDeviceSubject.eraseToAnyPublisher()
    }
    
    private let _deviceLostSubject = PassthroughSubject<String, Never>()
    public var deviceLostPublisher: AnyPublisher<String, Never> {
        return _deviceLostSubject.eraseToAnyPublisher()
    }
    
    private let _scanErrorSubject = PassthroughSubject<DiscoveryError, Never>()
    public var scanErrorPublisher: AnyPublisher<DiscoveryError, Never> {
        return _scanErrorSubject.eraseToAnyPublisher()
    }
    
    public let supportedDeviceTypes: Set<String> = ["BLE", "Bluetooth"]
    public let supportsBackgroundScanning: Bool = false
    public let scanRange: Double? = 100.0 // 约100米
    
    // MARK: - Private Properties
    
    private var centralManager: CBCentralManager!
    private var currentConfiguration: BLEConfiguration?
    private var currentScanConfiguration: BLEScanConfiguration?
    private var connectedPeripherals = [String: CBPeripheral]()
    private var discoveredDevices = [String: BLEDiscoveredDevice]()
    private var deviceFilter: DeviceFilter?
    private var scanTimer: Timer?
    private var reconnectAttempts = 0
    private var statistics = ServiceStatistics()
    private var scanStatistics = ScanStatistics()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(serviceId: String = "ble-adapter") {
        self.serviceId = serviceId
        self.discoveryId = serviceId
        
        super.init()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        setupStateMonitoring()
    }
    
    // MARK: - CommunicationService Implementation
    
    public func connect(with configuration: BLEConfiguration) -> AnyPublisher<Void, CommunicationError> {
        return Future<Void, CommunicationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.connectionFailed("适配器已释放")))
                return
            }
            
            guard centralManager.state == .poweredOn else {
                promise(.failure(.connectionFailed("蓝牙未开启")))
                return
            }
            
            self.currentConfiguration = configuration
            self._connectionState = .connecting
            
            // BLE连接通常通过扫描和连接特定设备实现
            // 这里简化为配置更新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self._connectionState = .connected
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func disconnect() -> AnyPublisher<Void, CommunicationError> {
        return Future<Void, CommunicationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.connectionFailed("适配器已释放")))
                return
            }
            
            // 断开所有连接的外设
            for peripheral in self.connectedPeripherals.values {
                self.centralManager.cancelPeripheralConnection(peripheral)
            }
            
            self.connectedPeripherals.removeAll()
            self._connectionState = .disconnected
            
            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }
    
    public func reconnect() -> AnyPublisher<Void, CommunicationError> {
        guard let configuration = currentConfiguration else {
            return Fail(error: CommunicationError.invalidConfiguration("无连接配置"))
                .eraseToAnyPublisher()
        }
        
        return disconnect()
            .flatMap { _ in
                return self.connect(with: configuration)
            }
            .eraseToAnyPublisher()
    }
    
    public func sendMessageWithResponse(_ message: BLEMessage, timeout: TimeInterval) -> AnyPublisher<BLEMessage, CommunicationError> {
        return Future<BLEMessage, CommunicationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.messageSendFailed("适配器已释放")))
                return
            }
            
            guard let peripheral = self.connectedPeripherals[message.deviceIdentifier] else {
                promise(.failure(.messageSendFailed("设备未连接")))
                return
            }
            
            self.performSendMessage(message, to: peripheral, promise: promise)
        }
        .timeout(.seconds(timeout), scheduler: DispatchQueue.main)
        .catch { error -> AnyPublisher<BLEMessage, CommunicationError> in
            if error is TimeoutError {
                return Fail(error: CommunicationError.timeout("发送消息超时"))
                    .eraseToAnyPublisher()
            } else {
                return Fail(error: error as? CommunicationError ?? CommunicationError.unknown(error))
                    .eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func subscribe(to topic: String) -> AnyPublisher<Void, CommunicationError> {
        // BLE中的"订阅"通常指启用特征通知
        return Future<Void, CommunicationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.subscriptionFailed("适配器已释放")))
                return
            }
            
            // 解析topic为设备ID和特征UUID
            let components = topic.components(separatedBy: "/")
            guard components.count >= 2 else {
                promise(.failure(.subscriptionFailed("无效的主题格式")))
                return
            }
            
            let deviceId = components[0]
            let characteristicUUID = components[1]
            
            self.enableNotification(deviceId: deviceId, characteristicUUID: characteristicUUID, promise: promise)
        }
        .eraseToAnyPublisher()
    }
    
    public func unsubscribe(from topic: String) -> AnyPublisher<Void, CommunicationError> {
        return Future<Void, CommunicationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.subscriptionFailed("适配器已释放")))
                return
            }
            
            let components = topic.components(separatedBy: "/")
            guard components.count >= 2 else {
                promise(.failure(.subscriptionFailed("无效的主题格式")))
                return
            }
            
            let deviceId = components[0]
            let characteristicUUID = components[1]
            
            self.disableNotification(deviceId: deviceId, characteristicUUID: characteristicUUID, promise: promise)
        }
        .eraseToAnyPublisher()
    }
    
    public func updateConfiguration(_ configuration: BLEConfiguration) -> AnyPublisher<Void, CommunicationError> {
        currentConfiguration = configuration
        return Just(())
            .setFailureType(to: CommunicationError.self)
            .eraseToAnyPublisher()
    }
    
    public func getCurrentConfiguration() -> BLEConfiguration? {
        return currentConfiguration
    }
    
    public func getDiagnostics() -> ConnectionDiagnostics {
        return ConnectionDiagnostics(
            connectionState: connectionState,
            connectionDuration: nil,
            lastConnectedAt: nil,
            lastDisconnectedAt: nil,
            reconnectCount: reconnectAttempts,
            lastError: nil,
            latency: nil,
            signalStrength: nil,
            additionalInfo: [
                "connectedPeripherals": connectedPeripherals.count,
                "discoveredDevices": discoveredDevices.count,
                "centralManagerState": centralManager.state.rawValue
            ]
        )
    }
    
    public func getStatistics() -> ServiceStatistics {
        return statistics
    }
    
    public func resetStatistics() {
        statistics = ServiceStatistics()
    }
    
    // MARK: - DeviceDiscovery Implementation
    
    public func startScanning(with configuration: BLEScanConfiguration?) -> AnyPublisher<Void, DiscoveryError> {
        return Future<Void, DiscoveryError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.scanStartFailed("适配器已释放")))
                return
            }
            
            guard self.centralManager.state == .poweredOn else {
                promise(.failure(.bluetoothPoweredOff))
                return
            }
            
            guard self._scanState.canStartScanning else {
                promise(.failure(.scanStartFailed("当前状态不允许开始扫描")))
                return
            }
            
            self.currentScanConfiguration = configuration ?? BLEScanConfiguration.default
            self.performStartScanning(promise: promise)
        }
        .eraseToAnyPublisher()
    }
    
    public func stopScanning() -> AnyPublisher<Void, DiscoveryError> {
        return Future<Void, DiscoveryError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.scanStopFailed("适配器已释放")))
                return
            }
            
            self.performStopScanning(promise: promise)
        }
        .eraseToAnyPublisher()
    }
    
    public func getDiscoveredDevices() -> [BLEDiscoveredDevice] {
        return Array(discoveredDevices.values)
    }
    
    public func getDevice(by deviceId: String) -> BLEDiscoveredDevice? {
        return discoveredDevices[deviceId]
    }
    
    public func clearDiscoveredDevices() {
        discoveredDevices.removeAll()
    }
    
    public func removeDevice(deviceId: String) -> Bool {
        return discoveredDevices.removeValue(forKey: deviceId) != nil
    }
    
    public func setDeviceFilter(_ filter: DeviceFilter?) {
        deviceFilter = filter
    }
    
    public func getCurrentFilter() -> DeviceFilter? {
        return deviceFilter
    }
    
    public func updateScanConfiguration(_ configuration: BLEScanConfiguration) -> AnyPublisher<Void, DiscoveryError> {
        currentScanConfiguration = configuration
        return Just(())
            .setFailureType(to: DiscoveryError.self)
            .eraseToAnyPublisher()
    }
    
    public func getCurrentScanConfiguration() -> BLEScanConfiguration? {
        return currentScanConfiguration
    }
    
    public func getScanStatistics() -> ScanStatistics {
        return scanStatistics
    }
    
    public func resetScanStatistics() {
        scanStatistics = ScanStatistics()
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEAdapter: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            _connectionState = .disconnected
        case .poweredOff:
            _connectionState = .failed
            _scanState = .failed
            _errorSubject.send(.bluetoothPoweredOff)
        case .unauthorized:
            _connectionState = .failed
            _scanState = .failed
            _errorSubject.send(.bluetoothUnauthorized)
        case .unsupported:
            _connectionState = .failed
            _scanState = .failed
            _errorSubject.send(.bluetoothUnavailable)
        default:
            break
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let device = BLEDiscoveredDevice(
            peripheral: peripheral,
            advertisementData: advertisementData,
            rssi: RSSI
        )
        
        // 应用过滤器
        if shouldIncludeDevice(device) {
            discoveredDevices[device.identifier] = device
            _discoveredDeviceSubject.send(device)
            
            updateScanStatistics(devicesDiscovered: 1)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripherals[peripheral.identifier.uuidString] = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        
        updateStatistics(successfulConnections: 1)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let errorMessage = error?.localizedDescription ?? "连接失败"
        _errorSubject.send(.connectionFailed(errorMessage))
        
        updateStatistics(failedConnections: 1)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripherals.removeValue(forKey: peripheral.identifier.uuidString)
        
        if let error = error {
            _errorSubject.send(.connectionLost)
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLEAdapter: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            _errorSubject.send(.unknown(error!))
            return
        }
        
        peripheral.services?.forEach { service in
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            _errorSubject.send(.unknown(error!))
            return
        }
        
        // 根据配置启用通知
        if let configurations = currentConfiguration?.characteristicConfigurations {
            for config in configurations {
                if config.serviceUUID == service.uuid.uuidString {
                    if let characteristic = service.characteristics?.first(where: { $0.uuid.uuidString == config.characteristicUUID }) {
                        if config.enableNotification {
                            peripheral.setNotifyValue(true, for: characteristic)
                        }
                    }
                }
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value else {
            if let error = error {
                _errorSubject.send(.unknown(error))
            }
            return
        }
        
        let message = BLEMessage(
            characteristicUUID: characteristic.uuid.uuidString,
            serviceUUID: characteristic.service?.uuid.uuidString ?? "",
            data: data,
            messageType: .notify,
            deviceIdentifier: peripheral.identifier.uuidString
        )
        
        _messageSubject.send(message)
        updateStatistics(messagesReceived: 1, bytesReceived: Int64(data.count))
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            _errorSubject.send(.messageSendFailed(error.localizedDescription))
        }
    }
}

// MARK: - Private Implementation

private extension BLEAdapter {
    
    func setupStateMonitoring() {
        // 监听连接状态变化
        connectionStatePublisher
            .sink { [weak self] state in
                self?.handleConnectionStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    func handleConnectionStateChange(_ state: ConnectionState) {
        switch state {
        case .connected:
            reconnectAttempts = 0
        case .disconnected, .failed:
            if currentConfiguration?.autoReconnect == true && reconnectAttempts < maxReconnectAttempts {
                scheduleReconnect()
            }
        default:
            break
        }
    }
    
    func scheduleReconnect() {
        reconnectAttempts += 1
        _connectionState = .reconnecting
        
        DispatchQueue.main.asyncAfter(deadline: .now() + reconnectInterval) { [weak self] in
            self?.performAutoReconnect()
        }
    }
    
    func performAutoReconnect() {
        guard let configuration = currentConfiguration else { return }
        
        reconnect()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        self?.scheduleReconnect()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    func performStartScanning(promise: @escaping (Result<Void, DiscoveryError>) -> Void) {
        _scanState = .starting
        
        let serviceUUIDs = currentScanConfiguration?.serviceUUIDs?.compactMap { CBUUID(string: $0) }
        let options = currentScanConfiguration?.options ?? [:]
        
        centralManager.scanForPeripherals(withServices: serviceUUIDs, options: options)
        
        _scanState = .scanning
        
        // 设置扫描超时
        if let duration = currentScanConfiguration?.duration {
            scanTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?.stopScanning()
                    .sink(
                        receiveCompletion: { _ in },
                        receiveValue: { _ in }
                    )
                    .store(in: &self?.cancellables ?? Set<AnyCancellable>())
            }
        }
        
        updateScanStatistics(scanCount: 1)
        promise(.success(()))
    }
    
    func performStopScanning(promise: @escaping (Result<Void, DiscoveryError>) -> Void) {
        _scanState = .stopping
        
        centralManager.stopScan()
        scanTimer?.invalidate()
        scanTimer = nil
        
        _scanState = .idle
        promise(.success(()))
    }
    
    func performSendMessage(_ message: BLEMessage, to peripheral: CBPeripheral, promise: @escaping (Result<BLEMessage, CommunicationError>) -> Void) {
        guard let service = peripheral.services?.first(where: { $0.uuid.uuidString == message.serviceUUID }) else {
            promise(.failure(.messageSendFailed("服务未找到")))
            return
        }
        
        guard let characteristic = service.characteristics?.first(where: { $0.uuid.uuidString == message.characteristicUUID }) else {
            promise(.failure(.messageSendFailed("特征未找到")))
            return
        }
        
        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
        
        peripheral.writeValue(message.data, for: characteristic, type: writeType)
        
        updateStatistics(messagesSent: 1, bytesSent: Int64(message.data.count))
        promise(.success(message))
    }
    
    func enableNotification(deviceId: String, characteristicUUID: String, promise: @escaping (Result<Void, CommunicationError>) -> Void) {
        guard let peripheral = connectedPeripherals[deviceId] else {
            promise(.failure(.subscriptionFailed("设备未连接")))
            return
        }
        
        guard let characteristic = findCharacteristic(uuid: characteristicUUID, in: peripheral) else {
            promise(.failure(.subscriptionFailed("特征未找到")))
            return
        }
        
        peripheral.setNotifyValue(true, for: characteristic)
        promise(.success(()))
    }
    
    func disableNotification(deviceId: String, characteristicUUID: String, promise: @escaping (Result<Void, CommunicationError>) -> Void) {
        guard let peripheral = connectedPeripherals[deviceId] else {
            promise(.failure(.subscriptionFailed("设备未连接")))
            return
        }
        
        guard let characteristic = findCharacteristic(uuid: characteristicUUID, in: peripheral) else {
            promise(.failure(.subscriptionFailed("特征未找到")))
            return
        }
        
        peripheral.setNotifyValue(false, for: characteristic)
        promise(.success(()))
    }
    
    func findCharacteristic(uuid: String, in peripheral: CBPeripheral) -> CBCharacteristic? {
        for service in peripheral.services ?? [] {
            for characteristic in service.characteristics ?? [] {
                if characteristic.uuid.uuidString == uuid {
                    return characteristic
                }
            }
        }
        return nil
    }
    
    func shouldIncludeDevice(_ device: BLEDiscoveredDevice) -> Bool {
        guard let filter = deviceFilter else { return true }
        
        // 信号强度过滤
        if let minRSSI = filter.minRSSI {
            if device.rssi.intValue < minRSSI {
                return false
            }
        }
        
        // 设备类型过滤
        if let deviceTypes = filter.deviceTypes {
            if !deviceTypes.contains("BLE") && !deviceTypes.contains("Bluetooth") {
                return false
            }
        }
        
        // 名称模式过滤
        if let namePattern = filter.namePattern, let deviceName = device.name {
            if !deviceName.localizedCaseInsensitiveContains(namePattern) {
                return false
            }
        }
        
        // 服务UUID过滤
        if let serviceUUIDs = filter.serviceUUIDs {
            let deviceServiceUUIDs = Set(device.serviceUUIDs)
            if deviceServiceUUIDs.isDisjoint(with: serviceUUIDs) {
                return false
            }
        }
        
        return true
    }
    
    func updateStatistics(messagesSent: Int = 0, messagesReceived: Int = 0, bytesSent: Int64 = 0, bytesReceived: Int64 = 0, successfulConnections: Int = 0, failedConnections: Int = 0) {
        statistics = ServiceStatistics(
            messagesSent: statistics.messagesSent + messagesSent,
            messagesReceived: statistics.messagesReceived + messagesReceived,
            bytesSent: statistics.bytesSent + bytesSent,
            bytesReceived: statistics.bytesReceived + bytesReceived,
            connectionAttempts: statistics.connectionAttempts + successfulConnections + failedConnections,
            successfulConnections: statistics.successfulConnections + successfulConnections,
            failedConnections: statistics.failedConnections + failedConnections,
            averageLatency: statistics.averageLatency,
            statisticsStartTime: statistics.statisticsStartTime,
            lastUpdated: Date()
        )
    }
    
    func updateScanStatistics(scanCount: Int = 0, devicesDiscovered: Int = 0) {
        scanStatistics = ScanStatistics(
            scanStartTime: scanStatistics.scanStartTime,
            totalScanDuration: scanStatistics.totalScanDuration,
            scanCount: scanStatistics.scanCount + scanCount,
            devicesDiscovered: scanStatistics.devicesDiscovered + devicesDiscovered,
            activeDevices: discoveredDevices.count,
            devicesLost: scanStatistics.devicesLost,
            averageDiscoveryTime: scanStatistics.averageDiscoveryTime,
            strongestRSSI: scanStatistics.strongestRSSI,
            weakestRSSI: scanStatistics.weakestRSSI,
            averageRSSI: scanStatistics.averageRSSI,
            deviceTypeStats: scanStatistics.deviceTypeStats,
            errorCount: scanStatistics.errorCount,
            lastUpdated: Date()
        )
    }
}

private struct TimeoutError: Error {}