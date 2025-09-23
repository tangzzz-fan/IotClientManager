//
//  ConnectivityLayerTests.swift
//  ConnectivityLayerTests
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import XCTest
@testable import ConnectivityLayer

// MARK: - Connectivity Layer Integration Tests

class ConnectivityLayerTests: XCTestCase {
    
    var connectivityManager: ConnectivityLayerManager!
    var connectionFactory: ConnectionFactory!
    var strategyFactory: CommunicationStrategyFactory!
    
    override func setUp() {
        super.setUp()
        
        let configuration = ConnectivityLayerConfiguration.default
        connectivityManager = ConnectivityLayerManager(configuration: configuration)
        connectionFactory = ConnectionFactory()
        strategyFactory = CommunicationStrategyFactory()
    }
    
    override func tearDown() {
        connectivityManager = nil
        connectionFactory = nil
        strategyFactory = nil
        super.tearDown()
    }
    
    // MARK: - Connection Factory Tests
    
    func testConnectionFactoryCreation() {
        XCTAssertNotNil(connectionFactory)
        
        let statistics = connectionFactory.getStatistics()
        XCTAssertEqual(statistics.totalServicesCreated, 0)
        XCTAssertEqual(statistics.totalDiscoveryServicesCreated, 0)
        XCTAssertEqual(statistics.totalStrategiesCreated, 0)
    }
    
    func testMQTTServiceCreation() throws {
        let config = MQTTConfiguration(
            brokerHost: "test.mosquitto.org",
            brokerPort: 1883,
            clientId: "test-client",
            qos: .atLeastOnce,
            cleanSession: true,
            keepAlive: 60
        )
        
        let service = try connectionFactory.createCommunicationService(
            type: "MQTT",
            configuration: config
        )
        
        XCTAssertTrue(service is MQTTAdapter)
        
        let statistics = connectionFactory.getStatistics()
        XCTAssertEqual(statistics.totalServicesCreated, 1)
    }
    
    func testBLEServiceCreation() throws {
        let service = try connectionFactory.createCommunicationService(
            type: "BLE",
            configuration: nil
        )
        
        XCTAssertTrue(service is BLEAdapter)
    }
    
    func testAliyunSDKServiceCreation() throws {
        let config = AliyunConfiguration(
            productKey: "test-product",
            deviceName: "test-device",
            deviceSecret: "test-secret",
            region: "cn-shanghai",
            logLevel: .info
        )
        
        let service = try connectionFactory.createCommunicationService(
            type: "AliyunSDK",
            configuration: config
        )
        
        XCTAssertTrue(service is AliyunSDKAdapter)
    }
    
    func testInvalidServiceTypeCreation() {
        XCTAssertThrowsError(try connectionFactory.createCommunicationService(
            type: "InvalidType",
            configuration: nil
        )) { error in
            XCTAssertTrue(error is ConnectionFactoryError)
        }
    }
    
    // MARK: - Strategy Factory Tests
    
    func testStrategyFactoryCreation() {
        XCTAssertNotNil(strategyFactory)
        
        let statistics = strategyFactory.getStatistics()
        XCTAssertGreaterThan(statistics.registeredStrategiesCount, 0)
    }
    
    func testAutomaticStrategyCreation() {
        let strategy = strategyFactory.createStrategy(name: "Automatic")
        XCTAssertNotNil(strategy)
        XCTAssertEqual(strategy?.strategyName, "Automatic")
    }
    
    func testReliabilityFirstStrategyCreation() {
        let strategy = strategyFactory.createStrategy(name: "ReliabilityFirst")
        XCTAssertNotNil(strategy)
        XCTAssertEqual(strategy?.strategyName, "ReliabilityFirst")
    }
    
    func testSpeedFirstStrategyCreation() {
        let strategy = strategyFactory.createStrategy(name: "SpeedFirst")
        XCTAssertNotNil(strategy)
        XCTAssertEqual(strategy?.strategyName, "SpeedFirst")
    }
    
    func testPowerSavingStrategyCreation() {
        let strategy = strategyFactory.createStrategy(name: "PowerSaving")
        XCTAssertNotNil(strategy)
        XCTAssertEqual(strategy?.strategyName, "PowerSaving")
    }
    
    func testInvalidStrategyCreation() {
        let strategy = strategyFactory.createStrategy(name: "InvalidStrategy")
        XCTAssertNil(strategy)
    }
    
    func testGetAllStrategies() {
        let strategies = strategyFactory.getAllStrategies()
        XCTAssertGreaterThan(strategies.count, 0)
        
        let strategyNames = strategies.map { $0.strategyName }
        XCTAssertTrue(strategyNames.contains("Automatic"))
        XCTAssertTrue(strategyNames.contains("ReliabilityFirst"))
        XCTAssertTrue(strategyNames.contains("SpeedFirst"))
        XCTAssertTrue(strategyNames.contains("PowerSaving"))
    }
    
    // MARK: - Device Communicator Tests
    
    func testDeviceCommunicatorCreation() {
        let context = createTestContext()
        let communicator = DeviceCommunicator(context: context, strategyFactory: strategyFactory)
        
        XCTAssertNotNil(communicator)
        XCTAssertEqual(communicator.getCurrentContext().deviceId, "test-device-001")
    }
    
    func testDeviceCommunicatorStrategySelection() {
        let context = createTestContext()
        let communicator = DeviceCommunicator(context: context, strategyFactory: strategyFactory)
        
        let availableStrategies = communicator.getAvailableStrategies()
        XCTAssertGreaterThan(availableStrategies.count, 0)
        
        // 验证策略按适用性评分排序
        for i in 0..<(availableStrategies.count - 1) {
            XCTAssertGreaterThanOrEqual(
                availableStrategies[i].suitabilityScore,
                availableStrategies[i + 1].suitabilityScore
            )
        }
    }
    
    func testDeviceCommunicatorContextUpdate() {
        let context = createTestContext()
        let communicator = DeviceCommunicator(context: context, strategyFactory: strategyFactory)
        
        var updatedContext = context
        updatedContext.deviceType = "sensor"
        updatedContext.userPreferences.priorityFactor = .powerSaving
        
        communicator.updateContext(updatedContext)
        
        let currentContext = communicator.getCurrentContext()
        XCTAssertEqual(currentContext.deviceType, "sensor")
        XCTAssertEqual(currentContext.userPreferences.priorityFactor, .powerSaving)
    }
    
    // MARK: - Strategy Evaluation Tests
    
    func testAutomaticStrategyEvaluation() {
        let strategy = AutomaticStrategy()
        let context = createTestContext()
        
        let evaluation = strategy.evaluate(context: context)
        
        XCTAssertTrue(evaluation.isApplicable)
        XCTAssertGreaterThan(evaluation.suitabilityScore, 0)
        XCTAssertFalse(evaluation.reasons.isEmpty)
    }
    
    func testReliabilityFirstStrategyEvaluation() {
        let strategy = ReliabilityFirstStrategy()
        var context = createTestContext()
        context.userPreferences.priorityFactor = .reliability
        
        let evaluation = strategy.evaluate(context: context)
        
        XCTAssertTrue(evaluation.isApplicable)
        XCTAssertGreaterThan(evaluation.suitabilityScore, 70)
    }
    
    func testPowerSavingStrategyEvaluation() {
        let strategy = PowerSavingStrategy()
        var context = createTestContext()
        context.deviceCapabilities.isBatteryPowered = true
        context.userPreferences.powerSavingMode = true
        
        let evaluation = strategy.evaluate(context: context)
        
        XCTAssertTrue(evaluation.isApplicable)
        XCTAssertGreaterThan(evaluation.suitabilityScore, 80)
    }
    
    func testBLEOnlyStrategyEvaluation() {
        let strategy = BLEOnlyStrategy()
        var context = createTestContext()
        context.deviceCapabilities.supportsBLE = false
        
        let evaluation = strategy.evaluate(context: context)
        
        XCTAssertFalse(evaluation.isApplicable)
        XCTAssertEqual(evaluation.suitabilityScore, 0)
    }
    
    // MARK: - Protocol Selection Tests
    
    func testAutomaticStrategyProtocolSelection() {
        let strategy = AutomaticStrategy()
        let context = createTestContext()
        
        let selection = strategy.selectProtocol(context: context)
        
        XCTAssertFalse(selection.selectedProtocol.isEmpty)
        XCTAssertTrue(strategy.supportedProtocols.contains(selection.selectedProtocol))
        XCTAssertFalse(selection.selectionReason.isEmpty)
    }
    
    func testReliabilityFirstProtocolSelection() {
        let strategy = ReliabilityFirstStrategy()
        var context = createTestContext()
        context.deviceCapabilities.supportsMatter = true
        
        let selection = strategy.selectProtocol(context: context)
        
        XCTAssertEqual(selection.selectedProtocol, "Matter")
        XCTAssertTrue(selection.alternativeProtocols.contains("MQTT"))
    }
    
    func testSpeedFirstProtocolSelection() {
        let strategy = SpeedFirstStrategy()
        let context = createTestContext()
        
        let selection = strategy.selectProtocol(context: context)
        
        XCTAssertEqual(selection.selectedProtocol, "WebSocket")
    }
    
    func testPowerSavingProtocolSelection() {
        let strategy = PowerSavingStrategy()
        var context = createTestContext()
        context.deviceCapabilities.supportsBLE = true
        
        let selection = strategy.selectProtocol(context: context)
        
        XCTAssertEqual(selection.selectedProtocol, "BLE")
    }
    
    // MARK: - Connection Models Tests
    
    func testConnectionInfoCreation() {
        let connectionInfo = ConnectionInfo(
            id: "test-connection",
            deviceId: "test-device",
            type: .mqtt,
            state: .connected,
            parameters: ConnectionParameters(),
            quality: ConnectionQuality(),
            statistics: ConnectionStatistics()
        )
        
        XCTAssertEqual(connectionInfo.id, "test-connection")
        XCTAssertEqual(connectionInfo.deviceId, "test-device")
        XCTAssertEqual(connectionInfo.type, .mqtt)
        XCTAssertEqual(connectionInfo.state, .connected)
    }
    
    func testConnectionQualityCalculation() {
        var quality = ConnectionQuality(
            signalStrength: 0.8,
            stability: 0.9,
            latency: 50,
            throughput: 1000,
            packetLoss: 0.01,
            errorRate: 0.005
        )
        
        let score = quality.calculateQualityScore()
        XCTAssertGreaterThan(score, 0)
        XCTAssertLessThanOrEqual(score, 100)
        
        let level = quality.qualityLevel
        XCTAssertNotEqual(level, .poor)
    }
    
    func testConnectionStatisticsUpdate() {
        var statistics = ConnectionStatistics()
        
        statistics.recordConnection(successful: true)
        statistics.recordMessageSent(bytes: 100)
        statistics.recordMessageReceived(bytes: 200)
        statistics.recordError()
        
        XCTAssertEqual(statistics.connectionAttempts, 1)
        XCTAssertEqual(statistics.successfulConnections, 1)
        XCTAssertEqual(statistics.messagesSent, 1)
        XCTAssertEqual(statistics.messagesReceived, 1)
        XCTAssertEqual(statistics.bytesSent, 100)
        XCTAssertEqual(statistics.bytesReceived, 200)
        XCTAssertEqual(statistics.errorCount, 1)
    }
    
    // MARK: - Connection Extensions Tests
    
    func testConnectionInfoExtensions() {
        let connectionInfo = ConnectionInfo(
            id: "test-connection",
            deviceId: "test-device",
            type: .mqtt,
            state: .connected,
            parameters: ConnectionParameters(),
            quality: ConnectionQuality(),
            statistics: ConnectionStatistics()
        )
        
        XCTAssertTrue(connectionInfo.isConnected)
        XCTAssertFalse(connectionInfo.isDisconnected)
        XCTAssertGreaterThan(connectionInfo.connectionDuration, 0)
    }
    
    func testConnectionSummaryCreation() {
        let connectionInfo = ConnectionInfo(
            id: "test-connection",
            deviceId: "test-device",
            type: .mqtt,
            state: .connected,
            parameters: ConnectionParameters(),
            quality: ConnectionQuality(signalStrength: 0.8),
            statistics: ConnectionStatistics()
        )
        
        let summary = connectionInfo.createSummary()
        
        XCTAssertEqual(summary.connectionId, "test-connection")
        XCTAssertEqual(summary.deviceId, "test-device")
        XCTAssertEqual(summary.connectionType, .mqtt)
        XCTAssertEqual(summary.currentState, .connected)
        XCTAssertEqual(summary.qualityLevel, connectionInfo.quality.qualityLevel)
    }
    
    // MARK: - Connectivity Layer Manager Tests
    
    func testConnectivityLayerManagerInitialization() {
        XCTAssertNotNil(connectivityManager)
        
        let status = connectivityManager.getStatus()
        XCTAssertEqual(status.state, .initialized)
        XCTAssertTrue(status.isHealthy)
    }
    
    func testConnectivityLayerManagerConfiguration() {
        let config = connectivityManager.getConfiguration()
        
        XCTAssertNotNil(config)
        XCTAssertGreaterThan(config.maxConcurrentConnections, 0)
        XCTAssertGreaterThan(config.connectionTimeout, 0)
    }
    
    func testConnectivityLayerManagerStatistics() {
        let statistics = connectivityManager.getStatistics()
        
        XCTAssertNotNil(statistics)
        XCTAssertGreaterThanOrEqual(statistics.totalConnections, 0)
        XCTAssertGreaterThanOrEqual(statistics.activeConnections, 0)
    }
    
    func testConnectivityLayerManagerHealthCheck() {
        let health = connectivityManager.getHealthStatus()
        
        XCTAssertNotNil(health)
        XCTAssertTrue(health.isHealthy)
        XCTAssertFalse(health.issues.isEmpty) // 可能有一些初始化相关的信息
    }
    
    // MARK: - Integration Tests
    
    func testFullIntegrationFlow() {
        // 创建通信上下文
        let context = createTestContext()
        
        // 创建设备通信器
        let communicator = DeviceCommunicator(context: context, strategyFactory: strategyFactory)
        
        // 获取可用策略
        let strategies = communicator.getAvailableStrategies()
        XCTAssertGreaterThan(strategies.count, 0)
        
        // 选择最佳策略
        let bestStrategy = strategies.first!
        XCTAssertNotNil(bestStrategy)
        
        // 验证策略信息
        XCTAssertFalse(bestStrategy.name.isEmpty)
        XCTAssertFalse(bestStrategy.description.isEmpty)
        XCTAssertGreaterThan(bestStrategy.supportedProtocols.count, 0)
        XCTAssertGreaterThan(bestStrategy.suitabilityScore, 0)
    }
    
    func testStrategyFactoryIntegration() {
        let context = createTestContext()
        
        // 测试所有策略的创建和评估
        let allStrategies = strategyFactory.getAllStrategies()
        
        for strategy in allStrategies {
            let evaluation = strategy.evaluate(context: context)
            XCTAssertGreaterThanOrEqual(evaluation.suitabilityScore, 0)
            XCTAssertLessThanOrEqual(evaluation.suitabilityScore, 100)
            
            if evaluation.isApplicable {
                let selection = strategy.selectProtocol(context: context)
                XCTAssertFalse(selection.selectedProtocol.isEmpty)
                XCTAssertTrue(strategy.supportedProtocols.contains(selection.selectedProtocol))
            }
        }
    }
    
    func testConnectionFactoryIntegration() {
        // 测试所有支持的服务类型
        let serviceTypes = ["MQTT", "BLE", "AliyunSDK"]
        
        for serviceType in serviceTypes {
            do {
                let service = try connectionFactory.createCommunicationService(
                    type: serviceType,
                    configuration: nil
                )
                XCTAssertNotNil(service)
            } catch {
                // 某些服务可能需要特定配置，这里只验证工厂能正确处理
                XCTAssertTrue(error is ConnectionFactoryError)
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testStrategySelectionPerformance() {
        let context = createTestContext()
        
        measure {
            for _ in 0..<100 {
                let strategies = strategyFactory.getAvailableStrategies(for: context)
                XCTAssertGreaterThan(strategies.count, 0)
            }
        }
    }
    
    func testServiceCreationPerformance() {
        measure {
            for _ in 0..<50 {
                do {
                    let service = try connectionFactory.createCommunicationService(
                        type: "MQTT",
                        configuration: nil
                    )
                    XCTAssertNotNil(service)
                } catch {
                    // 忽略配置错误，专注于性能测试
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestContext() -> CommunicationContext {
        let networkInfo = NetworkEnvironment(
            wifiInfo: WiFiInfo(
                ssid: "TestNetwork",
                isConnected: true,
                signalStrength: 0.8,
                frequency: 2.4,
                security: .wpa2
            ),
            cellularInfo: nil,
            bluetoothInfo: BluetoothInfo(
                isEnabled: true,
                isConnected: false,
                connectedDevices: []
            )
        )
        
        let preferences = CommunicationPreferences(
            priorityFactor: .balanced,
            allowProtocolSwitching: true,
            connectionTimeout: 30,
            powerSavingMode: false,
            dataUsagePreference: .balanced,
            securityLevel: .standard
        )
        
        let capabilities = DeviceCapabilities(
            supportedProtocols: ["MQTT", "BLE", "HTTP"],
            supportsWiFi: true,
            supportsBLE: true,
            supportsZigbee: false,
            supportsMatter: false,
            maxConnections: 5,
            isBatteryPowered: false
        )
        
        return CommunicationContext(
            deviceId: "test-device-001",
            deviceType: "smart_light",
            deviceModel: "TestLight-v1.0",
            preferredProtocols: ["MQTT", "BLE"],
            networkEnvironment: networkInfo,
            userPreferences: preferences,
            connectionHistory: [],
            deviceCapabilities: capabilities,
            timestamp: Date()
        )
    }
}

// MARK: - Mock Classes for Testing

class MockCommunicationService: CommunicationService {
    var isConnected: Bool = false
    var connectionState: ConnectionState = .disconnected
    var lastError: (any Error)?
    
    func connect() async throws {
        isConnected = true
        connectionState = .connected
    }
    
    func disconnect() async {
        isConnected = false
        connectionState = .disconnected
    }
    
    func sendMessage(_ message: any CommunicationMessage) async throws {
        guard isConnected else {
            throw CommunicationError.notConnected
        }
    }
    
    func subscribe(to topic: String) async throws {
        guard isConnected else {
            throw CommunicationError.notConnected
        }
    }
    
    func unsubscribe(from topic: String) async throws {
        guard isConnected else {
            throw CommunicationError.notConnected
        }
    }
    
    func updateConfiguration(_ configuration: Any) throws {
        // Mock implementation
    }
    
    func getDiagnosticInfo() -> [String: Any] {
        return [
            "isConnected": isConnected,
            "connectionState": connectionState.rawValue,
            "lastError": lastError?.localizedDescription ?? "None"
        ]
    }
}

class MockCommunicationStrategy: CommunicationStrategy {
    let strategyName: String
    let strategyDescription: String
    let supportedProtocols: [String]
    let priority: Int
    
    init(name: String, description: String, protocols: [String], priority: Int = 50) {
        self.strategyName = name
        self.strategyDescription = description
        self.supportedProtocols = protocols
        self.priority = priority
    }
    
    func evaluate(context: CommunicationContext) -> StrategyEvaluation {
        return StrategyEvaluation(
            suitabilityScore: priority,
            isApplicable: true,
            reasons: ["Mock strategy evaluation"],
            expectedPerformance: PerformanceMetrics(
                expectedLatency: 100,
                expectedThroughput: 500,
                expectedReliability: 0.9,
                expectedPowerConsumption: 1.0
            )
        )
    }
    
    func selectProtocol(context: CommunicationContext) -> ProtocolSelection {
        return ProtocolSelection(
            selectedProtocol: supportedProtocols.first ?? "MQTT",
            alternativeProtocols: Array(supportedProtocols.dropFirst()),
            selectionReason: "Mock protocol selection",
            expectedConnectionTime: 5.0
        )
    }
    
    func createCommunicationService(
        protocol: String,
        context: CommunicationContext,
        factory: ConnectionFactory
    ) throws -> any CommunicationService {
        return MockCommunicationService()
    }
}