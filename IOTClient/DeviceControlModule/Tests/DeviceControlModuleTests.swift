//
//  DeviceControlModuleTests.swift
//  DeviceControlModuleTests
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import XCTest
import Combine
@testable import IOTClient

class DeviceControlModuleTests: XCTestCase {
    var cancellables: Set<AnyCancellable>!
    var mockControlService: MockDeviceControlService!
    var commandFactory: DeviceCommandFactory!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        cancellables = Set<AnyCancellable>()
        mockControlService = MockDeviceControlService()
        commandFactory = DeviceCommandFactory()
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        mockControlService = nil
        commandFactory = nil
        try super.tearDownWithError()
    }
}

// MARK: - Device Command Tests

extension DeviceControlModuleTests {
    func testSwitchCommandCreation() {
        // Given
        let deviceId = "test-device-001"
        let isOn = true
        
        // When
        let command = commandFactory.createSwitchCommand(deviceId: deviceId, isOn: isOn)
        
        // Then
        XCTAssertEqual(command.targetDeviceId, deviceId)
        XCTAssertEqual(command.commandType, isOn ? .switchOn : .switchOff)
        XCTAssertEqual(command.parameters["isOn"] as? Bool, isOn)
        XCTAssertTrue(command.validateParameters())
    }
    
    func testDimmingCommandCreation() {
        // Given
        let deviceId = "test-light-001"
        let brightness = 75
        
        // When
        let command = commandFactory.createDimmingCommand(deviceId: deviceId, brightness: brightness)
        
        // Then
        XCTAssertEqual(command.targetDeviceId, deviceId)
        XCTAssertEqual(command.commandType, .setBrightness)
        XCTAssertEqual(command.parameters["brightness"] as? Int, brightness)
        XCTAssertTrue(command.validateParameters())
    }
    
    func testColorCommandCreation() {
        // Given
        let deviceId = "test-light-002"
        let color = DeviceColor(red: 255, green: 128, blue: 64)
        
        // When
        let command = commandFactory.createColorCommand(deviceId: deviceId, color: color)
        
        // Then
        XCTAssertEqual(command.targetDeviceId, deviceId)
        XCTAssertEqual(command.commandType, .setColor)
        XCTAssertEqual(command.parameters["red"] as? Int, 255)
        XCTAssertEqual(command.parameters["green"] as? Int, 128)
        XCTAssertEqual(command.parameters["blue"] as? Int, 64)
        XCTAssertTrue(command.validateParameters())
    }
    
    func testCommandParameterValidation() {
        // Given
        let deviceId = "test-device-001"
        
        // Test valid brightness
        let validBrightnessCommand = commandFactory.createDimmingCommand(deviceId: deviceId, brightness: 50)
        XCTAssertTrue(validBrightnessCommand.validateParameters())
        
        // Test invalid brightness (negative)
        let invalidBrightnessCommand = commandFactory.createDimmingCommand(deviceId: deviceId, brightness: -10)
        XCTAssertFalse(invalidBrightnessCommand.validateParameters())
        
        // Test invalid brightness (over 100)
        let overBrightnessCommand = commandFactory.createDimmingCommand(deviceId: deviceId, brightness: 150)
        XCTAssertFalse(overBrightnessCommand.validateParameters())
    }
}

// MARK: - Command Queue Tests

extension DeviceControlModuleTests {
    func testCommandQueueEnqueueDequeue() {
        // Given
        let queue = CommandQueue(type: .fifo, maxSize: 10)
        let command1 = commandFactory.createSwitchCommand(deviceId: "device1", isOn: true)
        let command2 = commandFactory.createSwitchCommand(deviceId: "device2", isOn: false)
        
        // When
        queue.enqueue(command1)
        queue.enqueue(command2)
        
        // Then
        XCTAssertEqual(queue.count, 2)
        XCTAssertFalse(queue.isEmpty)
        
        let dequeuedCommand1 = queue.dequeue()
        XCTAssertEqual(dequeuedCommand1?.commandId, command1.commandId)
        
        let dequeuedCommand2 = queue.dequeue()
        XCTAssertEqual(dequeuedCommand2?.commandId, command2.commandId)
        
        XCTAssertTrue(queue.isEmpty)
    }
    
    func testCommandQueuePriorityOrdering() {
        // Given
        let queue = CommandQueue(type: .priority, maxSize: 10)
        let lowPriorityCommand = commandFactory.createSwitchCommand(deviceId: "device1", isOn: true)
        lowPriorityCommand.priority = .low
        
        let highPriorityCommand = commandFactory.createSwitchCommand(deviceId: "device2", isOn: false)
        highPriorityCommand.priority = .high
        
        let criticalPriorityCommand = commandFactory.createSwitchCommand(deviceId: "device3", isOn: true)
        criticalPriorityCommand.priority = .critical
        
        // When
        queue.enqueue(lowPriorityCommand)
        queue.enqueue(highPriorityCommand)
        queue.enqueue(criticalPriorityCommand)
        
        // Then
        let firstDequeued = queue.dequeue()
        XCTAssertEqual(firstDequeued?.priority, .critical)
        
        let secondDequeued = queue.dequeue()
        XCTAssertEqual(secondDequeued?.priority, .high)
        
        let thirdDequeued = queue.dequeue()
        XCTAssertEqual(thirdDequeued?.priority, .low)
    }
    
    func testCommandQueueMaxSize() {
        // Given
        let maxSize = 3
        let queue = CommandQueue(type: .fifo, maxSize: maxSize)
        
        // When
        for i in 1...5 {
            let command = commandFactory.createSwitchCommand(deviceId: "device\(i)", isOn: true)
            queue.enqueue(command)
        }
        
        // Then
        XCTAssertEqual(queue.count, maxSize)
    }
}

// MARK: - Device Controller Tests

extension DeviceControlModuleTests {
    func testLightControllerSwitchOperation() {
        // Given
        let deviceId = "test-light-001"
        let lightController = LightController(
            deviceId: deviceId,
            controlService: mockControlService,
            commandFactory: commandFactory
        )
        
        let expectation = XCTestExpectation(description: "Switch light on")
        
        // When
        lightController.switchLight(isOn: true)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Switch operation failed: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertTrue(result.success)
                    XCTAssertEqual(result.deviceId, deviceId)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLightControllerBrightnessOperation() {
        // Given
        let deviceId = "test-light-002"
        let lightController = LightController(
            deviceId: deviceId,
            controlService: mockControlService,
            commandFactory: commandFactory
        )
        
        let targetBrightness = 80
        let expectation = XCTestExpectation(description: "Set brightness")
        
        // When
        lightController.setBrightness(targetBrightness)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Brightness operation failed: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertTrue(result.success)
                    XCTAssertEqual(result.deviceId, deviceId)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testThermostatControllerTemperatureOperation() {
        // Given
        let deviceId = "test-thermostat-001"
        let thermostatController = ThermostatController(
            deviceId: deviceId,
            controlService: mockControlService,
            commandFactory: commandFactory
        )
        
        let targetTemperature = 22.5
        let expectation = XCTestExpectation(description: "Set temperature")
        
        // When
        thermostatController.setTargetTemperature(targetTemperature)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Temperature operation failed: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertTrue(result.success)
                    XCTAssertEqual(result.deviceId, deviceId)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
}

// MARK: - Device Control Service Tests

extension DeviceControlModuleTests {
    func testDeviceControlServiceCommandExecution() {
        // Given
        let deviceId = "test-device-001"
        let command = commandFactory.createSwitchCommand(deviceId: deviceId, isOn: true)
        let expectation = XCTestExpectation(description: "Execute command")
        
        // When
        mockControlService.executeCommand(command)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Command execution failed: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertTrue(result.success)
                    XCTAssertEqual(result.deviceId, deviceId)
                    XCTAssertEqual(result.commandId, command.commandId)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testDeviceStatusRetrieval() {
        // Given
        let deviceId = "test-device-001"
        let expectation = XCTestExpectation(description: "Get device status")
        
        // When
        mockControlService.getDeviceStatus(deviceId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Status retrieval failed: \(error)")
                    }
                },
                receiveValue: { status in
                    // Then
                    XCTAssertEqual(status.deviceId, deviceId)
                    XCTAssertNotNil(status.lastUpdated)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
}

// MARK: - Batch Command Tests

extension DeviceControlModuleTests {
    func testBatchCommandExecution() {
        // Given
        let device1Id = "device-001"
        let device2Id = "device-002"
        
        let command1 = commandFactory.createSwitchCommand(deviceId: device1Id, isOn: true)
        let command2 = commandFactory.createSwitchCommand(deviceId: device2Id, isOn: false)
        
        let batchCommand = commandFactory.createBatchCommand(commands: [command1, command2])
        let expectation = XCTestExpectation(description: "Execute batch command")
        
        // When
        mockControlService.executeCommand(batchCommand)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Batch command execution failed: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertTrue(result.success)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
}

// MARK: - Device Discovery Tests

extension DeviceControlModuleTests {
    func testDeviceDiscovery() {
        // Given
        let discoveryService = DeviceDiscoveryService()
        let expectation = XCTestExpectation(description: "Discover devices")
        
        // When
        discoveryService.startDiscovery()
        
        // Listen for discovered devices
        discoveryService.getDiscoveredDevicesPublisher()
            .sink { devices in
                // Then
                XCTAssertGreaterThan(devices.count, 0)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 10.0)
        
        discoveryService.stopDiscovery()
    }
}

// MARK: - Device Authentication Tests

extension DeviceControlModuleTests {
    func testDeviceAuthentication() {
        // Given
        let authService = DeviceAuthenticationService()
        let deviceId = "test-device-001"
        let credentials = DeviceCredentials(
            deviceId: deviceId,
            credentialType: .password,
            credentialData: ["password": "test123"]
        )
        
        let expectation = XCTestExpectation(description: "Authenticate device")
        
        // When
        authService.authenticateDevice(deviceId: deviceId, credentials: credentials)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Authentication failed: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertTrue(result.isAuthenticated)
                    XCTAssertNotNil(result.authToken)
                    XCTAssertEqual(result.deviceId, deviceId)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
}

// MARK: - Extensions Tests

extension DeviceControlModuleTests {
    func testDeviceColorExtensions() {
        // Test UIColor conversion
        let deviceColor = DeviceColor(red: 255, green: 128, blue: 64)
        let uiColor = deviceColor.uiColor
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        XCTAssertEqual(Int(red * 255), 255)
        XCTAssertEqual(Int(green * 255), 128)
        XCTAssertEqual(Int(blue * 255), 64)
        
        // Test hex string conversion
        XCTAssertEqual(deviceColor.hexString, "#FF8040")
        
        // Test hex string parsing
        let parsedColor = DeviceColor.from(hexString: "#FF8040")
        XCTAssertNotNil(parsedColor)
        XCTAssertEqual(parsedColor?.red, 255)
        XCTAssertEqual(parsedColor?.green, 128)
        XCTAssertEqual(parsedColor?.blue, 64)
    }
    
    func testStringValidationExtensions() {
        // Test valid device ID
        XCTAssertTrue("Device_001".isValidDeviceId)
        XCTAssertTrue("ABCD1234-EFGH5678".isValidDeviceId)
        
        // Test invalid device ID
        XCTAssertFalse("abc".isValidDeviceId) // Too short
        XCTAssertFalse("device@001".isValidDeviceId) // Invalid character
        
        // Test command ID generation
        let commandId = String.generateDeviceControlId(prefix: "CMD")
        XCTAssertTrue(commandId.hasPrefix("CMD_"))
        XCTAssertTrue(commandId.isValidCommandId)
    }
    
    func testDeviceControlUtils() {
        // Test parameter validation
        let switchParams = ["isOn": true]
        XCTAssertTrue(DeviceControlUtils.validateCommandParameters(switchParams, for: .switchOn))
        
        let brightnessParams = ["brightness": 75]
        XCTAssertTrue(DeviceControlUtils.validateCommandParameters(brightnessParams, for: .setBrightness))
        
        let invalidBrightnessParams = ["brightness": 150]
        XCTAssertFalse(DeviceControlUtils.validateCommandParameters(invalidBrightnessParams, for: .setBrightness))
        
        // Test execution summary
        let result = DeviceCommandResult(
            commandId: "test-command",
            deviceId: "test-device",
            success: true,
            resultData: [:],
            executionTime: 1.25
        )
        
        let summary = DeviceControlUtils.generateExecutionSummary(for: result)
        XCTAssertTrue(summary.contains("成功"))
        XCTAssertTrue(summary.contains("1.25"))
    }
}

// MARK: - Performance Tests

extension DeviceControlModuleTests {
    func testCommandExecutionPerformance() {
        // Given
        let deviceId = "performance-test-device"
        let commandCount = 100
        
        // When
        measure {
            let expectation = XCTestExpectation(description: "Execute multiple commands")
            expectation.expectedFulfillmentCount = commandCount
            
            for i in 0..<commandCount {
                let command = commandFactory.createSwitchCommand(deviceId: "\(deviceId)-\(i)", isOn: i % 2 == 0)
                
                mockControlService.executeCommand(command)
                    .sink(
                        receiveCompletion: { _ in },
                        receiveValue: { _ in
                            expectation.fulfill()
                        }
                    )
                    .store(in: &cancellables)
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testCommandQueuePerformance() {
        // Given
        let queue = CommandQueue(type: .priority, maxSize: 1000)
        let commandCount = 1000
        
        // When
        measure {
            // Enqueue commands
            for i in 0..<commandCount {
                let command = commandFactory.createSwitchCommand(deviceId: "device-\(i)", isOn: true)
                command.priority = CommandPriority.allCases.randomElement() ?? .normal
                queue.enqueue(command)
            }
            
            // Dequeue all commands
            while !queue.isEmpty {
                _ = queue.dequeue()
            }
        }
    }
}

// MARK: - Mock Classes

class MockDeviceControlService: DeviceControlServiceProtocol {
    private var isServiceStarted = false
    private var monitoringDevices: Set<String> = []
    private var eventListeners: [DeviceEventListener] = []
    
    func startService() {
        isServiceStarted = true
    }
    
    func stopService() {
        isServiceStarted = false
        monitoringDevices.removeAll()
        eventListeners.removeAll()
    }
    
    func executeCommand(_ command: DeviceCommandProtocol) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        // Simulate command execution delay
        return Just(DeviceCommandResult(
            commandId: command.commandId,
            deviceId: command.targetDeviceId,
            success: true,
            resultData: [:],
            executionTime: 0.1
        ))
        .delay(for: .milliseconds(100), scheduler: DispatchQueue.main)
        .setFailureType(to: DeviceControlError.self)
        .eraseToAnyPublisher()
    }
    
    func queueCommand(_ command: DeviceCommandProtocol) -> AnyPublisher<Void, DeviceControlError> {
        return Just(())
            .setFailureType(to: DeviceControlError.self)
            .eraseToAnyPublisher()
    }
    
    func getDeviceStatus(_ deviceId: String) -> AnyPublisher<DeviceStatus, DeviceControlError> {
        let status = DeviceStatus(
            deviceId: deviceId,
            connectionState: .connected,
            properties: [:],
            lastUpdated: Date(),
            batteryLevel: 85
        )
        
        return Just(status)
            .setFailureType(to: DeviceControlError.self)
            .eraseToAnyPublisher()
    }
    
    func startMonitoring(_ deviceId: String) {
        monitoringDevices.insert(deviceId)
    }
    
    func stopMonitoring(_ deviceId: String) {
        monitoringDevices.remove(deviceId)
    }
    
    func registerEventListener(_ listener: DeviceEventListener) {
        eventListeners.append(listener)
    }
    
    func unregisterEventListener(_ listener: DeviceEventListener) {
        eventListeners.removeAll { $0.listenerId == listener.listenerId }
    }
}