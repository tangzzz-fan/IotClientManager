//
//  ConnectivityLayerPerformanceTests.swift
//  ConnectivityLayerTests
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import XCTest
@testable import ConnectivityLayer

// MARK: - Connectivity Layer Performance Tests

class ConnectivityLayerPerformanceTests: XCTestCase {
    
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
    
    // MARK: - Strategy Selection Performance Tests
    
    func testStrategySelectionPerformance() {
        let contexts = createMultipleTestContexts(count: 100)
        
        measure {
            for context in contexts {
                let strategies = strategyFactory.getAvailableStrategies(for: context)
                XCTAssertGreaterThan(strategies.count, 0)
            }
        }
    }
    
    func testConcurrentStrategySelection() {
        let contexts = createMultipleTestContexts(count: 50)
        let expectation = XCTestExpectation(description: "Concurrent strategy selection")
        expectation.expectedFulfillmentCount = contexts.count
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for context in contexts {
            DispatchQueue.global(qos: .userInitiated).async {
                let strategies = self.strategyFactory.getAvailableStrategies(for: context)
                XCTAssertGreaterThan(strategies.count, 0)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(timeElapsed, 5.0, "Concurrent strategy selection should complete within 5 seconds")
    }
    
    func testStrategyEvaluationPerformance() {
        let strategy = AutomaticStrategy()
        let contexts = createMultipleTestContexts(count: 1000)
        
        measure {
            for context in contexts {
                let evaluation = strategy.evaluate(context: context)
                XCTAssertGreaterThanOrEqual(evaluation.suitabilityScore, 0)
            }
        }
    }
    
    func testProtocolSelectionPerformance() {
        let strategy = AutomaticStrategy()
        let contexts = createMultipleTestContexts(count: 500)
        
        measure {
            for context in contexts {
                let selection = strategy.selectProtocol(context: context)
                XCTAssertFalse(selection.selectedProtocol.isEmpty)
            }
        }
    }
    
    // MARK: - Service Creation Performance Tests
    
    func testServiceCreationPerformance() {
        let serviceTypes = ["MQTT", "BLE", "AliyunSDK"]
        
        measure {
            for _ in 0..<100 {
                for serviceType in serviceTypes {
                    do {
                        let service = try connectionFactory.createCommunicationService(
                            type: serviceType,
                            configuration: nil
                        )
                        XCTAssertNotNil(service)
                    } catch {
                        // 某些服务可能需要特定配置
                        continue
                    }
                }
            }
        }
    }
    
    func testConcurrentServiceCreation() {
        let expectation = XCTestExpectation(description: "Concurrent service creation")
        expectation.expectedFulfillmentCount = 50
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<50 {
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let service = try self.connectionFactory.createCommunicationService(
                        type: "MQTT",
                        configuration: nil
                    )
                    XCTAssertNotNil(service)
                } catch {
                    // 配置错误是预期的
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(timeElapsed, 3.0, "Concurrent service creation should complete within 3 seconds")
    }
    
    func testServiceCreationMemoryUsage() {
        let initialMemory = getMemoryUsage()
        
        var services: [any CommunicationService] = []
        
        // 创建大量服务实例
        for i in 0..<100 {
            do {
                let config = MQTTConfiguration(
                    brokerHost: "test.mosquitto.org",
                    brokerPort: 1883,
                    clientId: "test-client-\(i)",
                    qos: .atLeastOnce,
                    cleanSession: true,
                    keepAlive: 60
                )
                
                let service = try connectionFactory.createCommunicationService(
                    type: "MQTT",
                    configuration: config
                )
                services.append(service)
            } catch {
                continue
            }
        }
        
        let peakMemory = getMemoryUsage()
        
        // 清理服务
        services.removeAll()
        
        let finalMemory = getMemoryUsage()
        
        // 验证内存使用合理
        let memoryIncrease = peakMemory - initialMemory
        let memoryRecovered = peakMemory - finalMemory
        
        XCTAssertLessThan(memoryIncrease, 50 * 1024 * 1024, "Memory increase should be less than 50MB")
        XCTAssertGreaterThan(memoryRecovered, memoryIncrease * 0.8, "Should recover at least 80% of allocated memory")
    }
    
    // MARK: - Device Communicator Performance Tests
    
    func testDeviceCommunicatorCreationPerformance() {
        let contexts = createMultipleTestContexts(count: 100)
        
        measure {
            for context in contexts {
                let communicator = DeviceCommunicator(context: context, strategyFactory: strategyFactory)
                XCTAssertNotNil(communicator)
            }
        }
    }
    
    func testDeviceCommunicatorContextUpdatePerformance() {
        let context = createTestContext()
        let communicator = DeviceCommunicator(context: context, strategyFactory: strategyFactory)
        
        let updatedContexts = createMultipleTestContexts(count: 500)
        
        measure {
            for updatedContext in updatedContexts {
                communicator.updateContext(updatedContext)
            }
        }
    }
    
    func testConcurrentDeviceCommunicatorOperations() {
        let contexts = createMultipleTestContexts(count: 20)
        let communicators = contexts.map { DeviceCommunicator(context: $0, strategyFactory: strategyFactory) }
        
        let expectation = XCTestExpectation(description: "Concurrent communicator operations")
        expectation.expectedFulfillmentCount = communicators.count * 3 // 每个通信器执行3个操作
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for communicator in communicators {
            DispatchQueue.global(qos: .userInitiated).async {
                // 操作1：获取可用策略
                let strategies = communicator.getAvailableStrategies()
                XCTAssertGreaterThan(strategies.count, 0)
                expectation.fulfill()
                
                // 操作2：获取连接信息
                let connectionInfo = communicator.getConnectionInfo()
                XCTAssertNotNil(connectionInfo)
                expectation.fulfill()
                
                // 操作3：更新上下文
                var newContext = communicator.getCurrentContext()
                newContext.timestamp = Date()
                communicator.updateContext(newContext)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(timeElapsed, 10.0, "Concurrent operations should complete within 10 seconds")
    }
    
    // MARK: - Connection Models Performance Tests
    
    func testConnectionInfoCreationPerformance() {
        measure {
            for i in 0..<1000 {
                let connectionInfo = ConnectionInfo(
                    id: "test-connection-\(i)",
                    deviceId: "test-device-\(i)",
                    type: .mqtt,
                    state: .connected,
                    parameters: ConnectionParameters(),
                    quality: ConnectionQuality(),
                    statistics: ConnectionStatistics()
                )
                XCTAssertNotNil(connectionInfo)
            }
        }
    }
    
    func testConnectionQualityCalculationPerformance() {
        let qualities = createMultipleConnectionQualities(count: 1000)
        
        measure {
            for var quality in qualities {
                let score = quality.calculateQualityScore()
                XCTAssertGreaterThanOrEqual(score, 0)
                XCTAssertLessThanOrEqual(score, 100)
            }
        }
    }
    
    func testConnectionStatisticsUpdatePerformance() {
        var statistics = ConnectionStatistics()
        
        measure {
            for i in 0..<10000 {
                statistics.recordConnection(successful: i % 10 != 0)
                statistics.recordMessageSent(bytes: Int.random(in: 10...1000))
                statistics.recordMessageReceived(bytes: Int.random(in: 10...1000))
                
                if i % 100 == 0 {
                    statistics.recordError()
                }
            }
        }
        
        XCTAssertEqual(statistics.connectionAttempts, 10000)
        XCTAssertEqual(statistics.successfulConnections, 9000)
        XCTAssertEqual(statistics.messagesSent, 10000)
        XCTAssertEqual(statistics.messagesReceived, 10000)
        XCTAssertEqual(statistics.errorCount, 100)
    }
    
    // MARK: - Connectivity Layer Manager Performance Tests
    
    func testConnectivityManagerStatisticsPerformance() {
        measure {
            for _ in 0..<1000 {
                let statistics = connectivityManager.getStatistics()
                XCTAssertNotNil(statistics)
            }
        }
    }
    
    func testConnectivityManagerHealthCheckPerformance() {
        measure {
            for _ in 0..<500 {
                let health = connectivityManager.getHealthStatus()
                XCTAssertNotNil(health)
            }
        }
    }
    
    func testConnectivityManagerConcurrentAccess() {
        let expectation = XCTestExpectation(description: "Concurrent manager access")
        expectation.expectedFulfillmentCount = 100
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<100 {
            DispatchQueue.global(qos: .userInitiated).async {
                let statistics = self.connectivityManager.getStatistics()
                let health = self.connectivityManager.getHealthStatus()
                let status = self.connectivityManager.getStatus()
                
                XCTAssertNotNil(statistics)
                XCTAssertNotNil(health)
                XCTAssertNotNil(status)
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(timeElapsed, 5.0, "Concurrent manager access should complete within 5 seconds")
    }
    
    // MARK: - Cache Performance Tests
    
    func testStrategyCachePerformance() {
        // 预热缓存
        for i in 0..<10 {
            let strategy = strategyFactory.createStrategy(name: "Automatic")
            XCTAssertNotNil(strategy)
        }
        
        // 测试缓存命中性能
        measure {
            for _ in 0..<1000 {
                let strategy = strategyFactory.createStrategy(name: "Automatic")
                XCTAssertNotNil(strategy)
            }
        }
        
        let statistics = strategyFactory.getStatistics()
        XCTAssertGreaterThan(statistics.cacheHitRate, 0.9, "Cache hit rate should be above 90%")
    }
    
    func testFactoryStatisticsPerformance() {
        // 生成一些统计数据
        for i in 0..<100 {
            let strategy = strategyFactory.createStrategy(name: "Automatic")
            XCTAssertNotNil(strategy)
        }
        
        measure {
            for _ in 0..<1000 {
                let statistics = strategyFactory.getStatistics()
                XCTAssertNotNil(statistics)
            }
        }
    }
    
    // MARK: - Memory Leak Tests
    
    func testStrategyFactoryMemoryLeaks() {
        weak var weakFactory: CommunicationStrategyFactory?
        
        autoreleasepool {
            let factory = CommunicationStrategyFactory()
            weakFactory = factory
            
            // 执行一些操作
            for _ in 0..<100 {
                let strategy = factory.createStrategy(name: "Automatic")
                XCTAssertNotNil(strategy)
            }
        }
        
        // 验证工厂被正确释放
        XCTAssertNil(weakFactory, "Strategy factory should be deallocated")
    }
    
    func testDeviceCommunicatorMemoryLeaks() {
        weak var weakCommunicator: DeviceCommunicator?
        
        autoreleasepool {
            let context = createTestContext()
            let communicator = DeviceCommunicator(context: context, strategyFactory: strategyFactory)
            weakCommunicator = communicator
            
            // 执行一些操作
            let strategies = communicator.getAvailableStrategies()
            XCTAssertGreaterThan(strategies.count, 0)
        }
        
        // 验证通信器被正确释放
        XCTAssertNil(weakCommunicator, "Device communicator should be deallocated")
    }
    
    // MARK: - Stress Tests
    
    func testHighVolumeStrategySelection() {
        let contexts = createMultipleTestContexts(count: 1000)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for context in contexts {
            let strategies = strategyFactory.getAvailableStrategies(for: context)
            XCTAssertGreaterThan(strategies.count, 0)
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(timeElapsed, 10.0, "High volume strategy selection should complete within 10 seconds")
    }
    
    func testHighVolumeServiceCreation() {
        let startTime = CFAbsoluteTimeGetCurrent()
        var createdServices = 0
        
        for i in 0..<500 {
            do {
                let config = MQTTConfiguration(
                    brokerHost: "test.mosquitto.org",
                    brokerPort: 1883,
                    clientId: "stress-test-\(i)",
                    qos: .atLeastOnce,
                    cleanSession: true,
                    keepAlive: 60
                )
                
                let service = try connectionFactory.createCommunicationService(
                    type: "MQTT",
                    configuration: config
                )
                XCTAssertNotNil(service)
                createdServices += 1
            } catch {
                continue
            }
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertGreaterThan(createdServices, 400, "Should successfully create most services")
        XCTAssertLessThan(timeElapsed, 15.0, "High volume service creation should complete within 15 seconds")
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
    
    private func createMultipleTestContexts(count: Int) -> [CommunicationContext] {
        let deviceTypes = ["smart_light", "sensor", "switch", "camera", "robot"]
        let priorityFactors: [PriorityFactor] = [.speed, .reliability, .powerSaving, .security, .balanced]
        let securityLevels: [SecurityLevel] = [.low, .standard, .high, .enterprise]
        
        return (0..<count).map { i in
            let networkInfo = NetworkEnvironment(
                wifiInfo: WiFiInfo(
                    ssid: "TestNetwork-\(i % 5)",
                    isConnected: i % 3 != 0,
                    signalStrength: Double.random(in: 0.3...1.0),
                    frequency: i % 2 == 0 ? 2.4 : 5.0,
                    security: .wpa2
                ),
                cellularInfo: nil,
                bluetoothInfo: BluetoothInfo(
                    isEnabled: true,
                    isConnected: i % 4 == 0,
                    connectedDevices: []
                )
            )
            
            let preferences = CommunicationPreferences(
                priorityFactor: priorityFactors[i % priorityFactors.count],
                allowProtocolSwitching: i % 2 == 0,
                connectionTimeout: Double.random(in: 10...60),
                powerSavingMode: i % 3 == 0,
                dataUsagePreference: .balanced,
                securityLevel: securityLevels[i % securityLevels.count]
            )
            
            let capabilities = DeviceCapabilities(
                supportedProtocols: ["MQTT", "BLE", "HTTP"],
                supportsWiFi: i % 5 != 0,
                supportsBLE: i % 3 != 0,
                supportsZigbee: i % 7 == 0,
                supportsMatter: i % 10 == 0,
                maxConnections: Int.random(in: 1...10),
                isBatteryPowered: i % 4 == 0
            )
            
            return CommunicationContext(
                deviceId: "test-device-\(String(format: "%03d", i))",
                deviceType: deviceTypes[i % deviceTypes.count],
                deviceModel: "TestDevice-v\(i % 3 + 1).0",
                preferredProtocols: ["MQTT", "BLE"],
                networkEnvironment: networkInfo,
                userPreferences: preferences,
                connectionHistory: [],
                deviceCapabilities: capabilities,
                timestamp: Date()
            )
        }
    }
    
    private func createMultipleConnectionQualities(count: Int) -> [ConnectionQuality] {
        return (0..<count).map { _ in
            ConnectionQuality(
                signalStrength: Double.random(in: 0.1...1.0),
                stability: Double.random(in: 0.5...1.0),
                latency: Double.random(in: 10...500),
                throughput: Double.random(in: 100...2000),
                packetLoss: Double.random(in: 0...0.1),
                errorRate: Double.random(in: 0...0.05)
            )
        }
    }
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }
}