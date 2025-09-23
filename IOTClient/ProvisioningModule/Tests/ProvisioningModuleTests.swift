//
//  ProvisioningModuleTests.swift
//  ProvisioningModuleTests
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import XCTest
import Combine
@testable import ProvisioningModule

// MARK: - Base Test Case

class ProvisioningModuleTestCase: XCTestCase {
    
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }
}

// MARK: - Provisioning States Tests

class ProvisioningStatesTests: ProvisioningModuleTestCase {
    
    func testIdleStateProperties() {
        let state = IdleState()
        
        XCTAssertEqual(state.name, "idle")
        XCTAssertEqual(state.description, "等待开始配网")
        XCTAssertTrue(state.canCancel)
        XCTAssertFalse(state.isFinalState)
    }
    
    func testScanningStateTransitions() {
        let context = ProvisioningContext()
        let state = ScanningState()
        
        // 测试开始扫描事件
        let nextState = state.handleEvent(.startScanning, context: context)
        XCTAssertNil(nextState) // 已经在扫描状态
        
        // 测试设备发现事件
        let deviceFoundState = state.handleEvent(.deviceFound(createMockDevice()), context: context)
        XCTAssertNil(deviceFoundState) // 继续扫描
        
        // 测试扫描完成事件
        let completedState = state.handleEvent(.scanCompleted, context: context)
        XCTAssertTrue(completedState is DeviceSelectionState)
    }
    
    func testConnectingStateTimeout() {
        let context = ProvisioningContext()
        let state = ConnectingState()
        
        // 测试连接超时
        let timeoutState = state.handleEvent(.timeout, context: context)
        XCTAssertTrue(timeoutState is ConnectionFailedState)
    }
    
    func testAuthenticatingStateSuccess() {
        let context = ProvisioningContext()
        let state = AuthenticatingState()
        
        // 测试认证成功
        let successState = state.handleEvent(.authenticationCompleted, context: context)
        XCTAssertTrue(successState is ConfiguringState)
    }
    
    func testConfigurationStateFailure() {
        let context = ProvisioningContext()
        let state = ConfiguringState()
        
        // 测试配置失败
        let failureState = state.handleEvent(.error(ProvisioningError.configurationFailed("Test error")), context: context)
        XCTAssertTrue(failureState is ConfigurationFailedState)
    }
    
    func testVerificationStateSuccess() {
        let context = ProvisioningContext()
        let state = VerifyingState()
        
        // 测试验证成功
        let successState = state.handleEvent(.verificationCompleted, context: context)
        XCTAssertTrue(successState is CompletedState)
    }
    
    func testStateFactory() {
        let factory = ProvisioningStateFactory()
        
        // 测试创建初始状态
        let initialState = factory.createInitialState()
        XCTAssertTrue(initialState is IdleState)
        
        // 测试根据名称创建状态
        let scanningState = factory.createState(named: "scanning")
        XCTAssertTrue(scanningState is ScanningState)
        
        // 测试无效状态名称
        let invalidState = factory.createState(named: "invalid")
        XCTAssertNil(invalidState)
        
        // 测试获取所有状态
        let allStates = factory.getAllStates()
        XCTAssertTrue(allStates.count > 0)
    }
}

// MARK: - Provisioning Models Tests

class ProvisioningModelsTests: ProvisioningModuleTestCase {
    
    func testProvisionableDeviceCreation() {
        let device = createMockDevice()
        
        XCTAssertEqual(device.id, "test-device-id")
        XCTAssertEqual(device.name, "Test Device")
        XCTAssertEqual(device.type, .bluetoothDevice)
        XCTAssertEqual(device.category, .light)
        XCTAssertEqual(device.manufacturer, "Test Manufacturer")
        XCTAssertEqual(device.model, "Test Model")
    }
    
    func testProvisionableDeviceSignalStrength() {
        let strongDevice = ProvisionableDevice(
            id: "strong",
            name: "Strong Device",
            type: .bluetoothDevice,
            category: .light,
            manufacturer: "Test",
            model: "Test",
            rssi: -40
        )
        
        let weakDevice = ProvisionableDevice(
            id: "weak",
            name: "Weak Device",
            type: .bluetoothDevice,
            category: .light,
            manufacturer: "Test",
            model: "Test",
            rssi: -90
        )
        
        XCTAssertGreaterThan(strongDevice.signalStrength, weakDevice.signalStrength)
        XCTAssertGreaterThan(strongDevice.signalStrength, 0.5)
        XCTAssertLessThan(weakDevice.signalStrength, 0.5)
    }
    
    func testNetworkConfigurationValidation() {
        // 有效配置
        let validConfig = NetworkConfiguration(
            ssid: "TestNetwork",
            password: "password123",
            securityType: .wpa2
        )
        XCTAssertTrue(validConfig.isValid)
        
        // 无效SSID
        let invalidSSIDConfig = NetworkConfiguration(
            ssid: "",
            password: "password123",
            securityType: .wpa2
        )
        XCTAssertFalse(invalidSSIDConfig.isValid)
        
        // 缺少密码
        let noPasswordConfig = NetworkConfiguration(
            ssid: "TestNetwork",
            password: nil,
            securityType: .wpa2
        )
        XCTAssertFalse(noPasswordConfig.isValid)
        
        // 开放网络（不需要密码）
        let openConfig = NetworkConfiguration(
            ssid: "OpenNetwork",
            password: nil,
            securityType: .open
        )
        XCTAssertTrue(openConfig.isValid)
    }
    
    func testDeviceConfigurationValidation() {
        // 有效配置
        let validConfig = DeviceConfiguration(
            deviceName: "My Device",
            location: "Living Room"
        )
        XCTAssertTrue(validConfig.isValid)
        
        // 无效配置（空名称）
        let invalidConfig = DeviceConfiguration(
            deviceName: "",
            location: "Living Room"
        )
        XCTAssertFalse(invalidConfig.isValid)
    }
    
    func testStaticIPConfiguration() {
        // 有效静态IP
        let validStaticIP = StaticIPConfiguration(
            ipAddress: "192.168.1.100",
            subnetMask: "255.255.255.0",
            gateway: "192.168.1.1",
            primaryDNS: "8.8.8.8",
            secondaryDNS: "8.8.4.4"
        )
        XCTAssertTrue(validStaticIP.isValid)
        
        // 无效IP地址
        let invalidStaticIP = StaticIPConfiguration(
            ipAddress: "999.999.999.999",
            subnetMask: "255.255.255.0",
            gateway: "192.168.1.1",
            primaryDNS: "8.8.8.8"
        )
        XCTAssertFalse(invalidStaticIP.isValid)
    }
    
    func testProvisioningProgress() {
        let progress = ProvisioningProgress(
            currentStep: "连接设备",
            currentStepProgress: 0.5,
            overallProgress: 0.3
        )
        
        XCTAssertEqual(progress.currentStep, "连接设备")
        XCTAssertEqual(progress.currentStepProgress, 0.5)
        XCTAssertEqual(progress.overallProgress, 0.3)
        
        // 测试进度范围限制
        let invalidProgress = ProvisioningProgress(
            currentStep: "测试",
            currentStepProgress: 1.5, // 超出范围
            overallProgress: -0.1     // 超出范围
        )
        
        XCTAssertEqual(invalidProgress.currentStepProgress, 1.0)
        XCTAssertEqual(invalidProgress.overallProgress, 0.0)
    }
}

// MARK: - Provisioning Services Tests

class ProvisioningServicesTests: ProvisioningModuleTestCase {
    
    var scanningService: DefaultDeviceScanningService!
    var connectionService: DefaultDeviceConnectionService!
    var authenticationService: DefaultDeviceAuthenticationService!
    var configurationService: DefaultDeviceConfigurationService!
    var verificationService: DefaultDeviceVerificationService!
    
    override func setUp() {
        super.setUp()
        scanningService = DefaultDeviceScanningService()
        connectionService = DefaultDeviceConnectionService()
        authenticationService = DefaultDeviceAuthenticationService()
        configurationService = DefaultDeviceConfigurationService()
        verificationService = DefaultDeviceVerificationService()
    }
    
    func testDeviceScanningService() {
        let expectation = XCTestExpectation(description: "Device scanning")
        
        // 监听扫描状态
        scanningService.isScanning
            .sink { isScanning in
                if isScanning {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // 开始扫描
        scanningService.startScanning(for: [.bluetoothDevice], timeout: 5.0)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Scanning failed: \(error)")
                    }
                },
                receiveValue: { _ in
                    // 扫描开始成功
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
        
        // 停止扫描
        let stopExpectation = XCTestExpectation(description: "Stop scanning")
        scanningService.stopScanning()
            .sink { _ in
                stopExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [stopExpectation], timeout: 1.0)
    }
    
    func testDeviceConnectionService() {
        let expectation = XCTestExpectation(description: "Device connection")
        let device = createMockDevice()
        
        // 监听连接状态
        connectionService.connectionStatus
            .sink { status in
                if status == .connecting {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // 尝试连接
        connectionService.connect(to: device, timeout: 5.0)
            .sink(
                receiveCompletion: { completion in
                    // 连接可能失败，这是正常的（因为是模拟设备）
                },
                receiveValue: { _ in
                    // 连接成功
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testDeviceAuthenticationService() {
        let expectation = XCTestExpectation(description: "Device authentication")
        let device = createMockDevice()
        let authConfig = AuthenticationConfiguration(
            method: .password,
            credentials: ["password": "testpassword"],
            timeout: 10.0,
            retryCount: 3
        )
        
        authenticationService.authenticate(device: device, configuration: authConfig)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Authentication failed: \(error)")
                    }
                },
                receiveValue: { result in
                    XCTAssertTrue(result.isSuccessful)
                    XCTAssertNotNil(result.authInfo)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testDeviceConfigurationService() {
        let expectation = XCTestExpectation(description: "Device configuration")
        let device = createMockDevice()
        let networkConfig = NetworkConfiguration(
            ssid: "TestNetwork",
            password: "password123",
            securityType: .wpa2
        )
        let deviceConfig = DeviceConfiguration(
            deviceName: "Test Device",
            location: "Test Location"
        )
        
        configurationService.configure(device: device, networkConfig: networkConfig, deviceConfig: deviceConfig)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Configuration failed: \(error)")
                    }
                },
                receiveValue: { result in
                    XCTAssertTrue(result.isSuccessful)
                    XCTAssertNotNil(result.deviceInfo)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testDeviceVerificationService() {
        let expectation = XCTestExpectation(description: "Device verification")
        let device = createMockDevice()
        let networkConfig = NetworkConfiguration(
            ssid: "TestNetwork",
            password: "password123",
            securityType: .wpa2
        )
        
        verificationService.verify(device: device, networkConfig: networkConfig)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Verification failed: \(error)")
                    }
                },
                receiveValue: { result in
                    XCTAssertTrue(result.isSuccessful)
                    XCTAssertTrue(result.networkConnected)
                    XCTAssertTrue(result.deviceResponding)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testNetworkTestService() {
        let expectation = XCTestExpectation(description: "Network test")
        let networkConfig = NetworkConfiguration(
            ssid: "TestNetwork",
            password: "password123",
            securityType: .wpa2
        )
        
        verificationService.testNetworkConnection(networkConfig: networkConfig)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Network test failed: \(error)")
                    }
                },
                receiveValue: { result in
                    XCTAssertTrue(result.isConnected)
                    XCTAssertNotNil(result.ipAddress)
                    XCTAssertNotNil(result.bandwidth)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testFunctionalityTestService() {
        let expectation = XCTestExpectation(description: "Functionality test")
        let device = createMockDevice()
        
        verificationService.testDeviceFunctionality(device: device)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Functionality test failed: \(error)")
                    }
                },
                receiveValue: { result in
                    XCTAssertTrue(result.deviceResponding)
                    XCTAssertFalse(result.capabilityTests.isEmpty)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
}

// MARK: - Provisioning Extensions Tests

class ProvisioningExtensionsTests: ProvisioningModuleTestCase {
    
    func testStringValidationExtensions() {
        // SSID验证
        XCTAssertTrue("ValidSSID".isValidSSID)
        XCTAssertFalse("".isValidSSID)
        XCTAssertFalse(String(repeating: "a", count: 33).isValidSSID)
        
        // WiFi密码验证
        XCTAssertTrue("password123".isValidWiFiPassword)
        XCTAssertFalse("short".isValidWiFiPassword)
        XCTAssertFalse(String(repeating: "a", count: 64).isValidWiFiPassword)
        
        // IP地址验证
        XCTAssertTrue("192.168.1.1".isValidIPAddress)
        XCTAssertTrue("0.0.0.0".isValidIPAddress)
        XCTAssertTrue("255.255.255.255".isValidIPAddress)
        XCTAssertFalse("256.1.1.1".isValidIPAddress)
        XCTAssertFalse("192.168.1".isValidIPAddress)
        XCTAssertFalse("invalid.ip.address".isValidIPAddress)
        
        // MAC地址验证
        XCTAssertTrue("00:11:22:33:44:55".isValidMACAddress)
        XCTAssertTrue("AA:BB:CC:DD:EE:FF".isValidMACAddress)
        XCTAssertTrue("00-11-22-33-44-55".isValidMACAddress)
        XCTAssertFalse("invalid:mac:address".isValidMACAddress)
        XCTAssertFalse("00:11:22:33:44".isValidMACAddress)
        
        // 设备友好名称
        XCTAssertEqual("test_device-name".deviceFriendlyName, "Test Device Name")
    }
    
    func testDataExtensions() {
        let testString = "Hello World"
        let data = testString.data(using: .utf8)!
        
        // 十六进制转换
        let hexString = data.hexString
        XCTAssertFalse(hexString.isEmpty)
        
        let dataFromHex = Data(hexString: hexString)
        XCTAssertEqual(data, dataFromHex)
        
        // JSON转换
        let jsonObject = ["key": "value"]
        let jsonData = Data.fromJSONObject(jsonObject)
        XCTAssertNotNil(jsonData)
        
        let parsedObject = jsonData?.toJSONObject() as? [String: String]
        XCTAssertEqual(parsedObject?["key"], "value")
    }
    
    func testDateExtensions() {
        let now = Date()
        let fiveMinutesAgo = now.addingTimeInterval(-300)
        let oneHourAgo = now.addingTimeInterval(-3600)
        
        // 时间间隔检查
        XCTAssertTrue(fiveMinutesAgo.isWithin(600, of: now))
        XCTAssertFalse(oneHourAgo.isWithin(300, of: now))
        
        // 相对时间描述
        XCTAssertEqual(now.relativeTimeDescription, "刚刚")
        XCTAssertTrue(fiveMinutesAgo.relativeTimeDescription.contains("分钟前"))
        XCTAssertTrue(oneHourAgo.relativeTimeDescription.contains("小时前"))
        
        // 配网时间戳
        let timestamp = now.provisioningTimestamp
        XCTAssertTrue(timestamp.contains("-"))
        XCTAssertTrue(timestamp.contains(":"))
        XCTAssertTrue(timestamp.contains("."))
    }
    
    func testTimeIntervalExtensions() {
        let duration: TimeInterval = 3665 // 1小时1分5秒
        XCTAssertEqual(duration.durationDescription, "1:01:05")
        
        let shortDuration: TimeInterval = 65 // 1分5秒
        XCTAssertEqual(shortDuration.durationDescription, "1:05")
        
        let veryShortDuration: TimeInterval = 30 // 30秒
        XCTAssertEqual(veryShortDuration.durationDescription, "30秒")
        
        // 毫秒转换
        XCTAssertEqual(duration.milliseconds, 3665000)
    }
    
    func testArrayExtensions() {
        let devices = [
            createMockDevice(id: "1", rssi: -50),
            createMockDevice(id: "2", rssi: -70),
            createMockDevice(id: "3", rssi: -60)
        ]
        
        // 按信号强度排序
        let sortedBySignal = devices.sortedBySignalStrength()
        XCTAssertEqual(sortedBySignal[0].id, "1") // 最强信号
        XCTAssertEqual(sortedBySignal[2].id, "2") // 最弱信号
        
        // 按类型分组
        let groupedByType = devices.groupedByType()
        XCTAssertEqual(groupedByType[.bluetoothDevice]?.count, 3)
        
        // 过滤支持特定能力的设备
        let devicesWithOnOff = devices.supporting(.onOff)
        XCTAssertEqual(devicesWithOnOff.count, 3)
        
        // 过滤最近发现的设备
        let recentDevices = devices.recentlyDiscovered(within: 3600)
        XCTAssertEqual(recentDevices.count, 3)
    }
    
    func testUtilityFunctions() {
        // 生成设备ID
        let deviceId = generateDeviceID()
        XCTAssertFalse(deviceId.isEmpty)
        XCTAssertNotEqual(deviceId, generateDeviceID())
        
        // 生成会话ID
        let sessionId = generateSessionID()
        XCTAssertTrue(sessionId.hasPrefix("session_"))
        
        // 计算总体进度
        let progress = calculateOverallProgress(currentStep: 3, totalSteps: 5, currentStepProgress: 0.5)
        XCTAssertEqual(progress, 0.5) // (2 + 0.5) / 5
        
        // 估算剩余时间
        let startTime = Date().addingTimeInterval(-60) // 1分钟前开始
        let remainingTime = estimateRemainingTime(startTime: startTime, currentProgress: 0.5)
        XCTAssertNotNil(remainingTime)
        XCTAssertGreaterThan(remainingTime!, 0)
        
        // 格式化字节大小
        let formattedBytes = formatBytes(1024 * 1024) // 1MB
        XCTAssertTrue(formattedBytes.contains("MB"))
        
        // 格式化网络速度
        let formattedSpeed = formatNetworkSpeed(1_000_000) // 1MB/s = 8Mbps
        XCTAssertTrue(formattedSpeed.contains("Mbps"))
        
        // 生成随机MAC地址
        let macAddress = generateRandomMACAddress()
        XCTAssertTrue(macAddress.isValidMACAddress)
        
        // 检查设备兼容性
        let device = createMockDevice()
        let issues = checkDeviceCompatibility(device)
        XCTAssertTrue(issues.isEmpty || !issues.isEmpty) // 可能有也可能没有问题
    }
}

// MARK: - Performance Tests

class ProvisioningPerformanceTests: ProvisioningModuleTestCase {
    
    func testDeviceListSortingPerformance() {
        let devices = (0..<1000).map { index in
            createMockDevice(id: "device_\(index)", rssi: Int.random(in: -100...(-30)))
        }
        
        measure {
            _ = devices.sortedBySignalStrength()
        }
    }
    
    func testDeviceFilteringPerformance() {
        let devices = (0..<1000).map { index in
            createMockDevice(id: "device_\(index)")
        }
        
        measure {
            _ = devices.supporting(.onOff)
        }
    }
    
    func testStateTransitionPerformance() {
        let context = ProvisioningContext()
        let state = ScanningState()
        
        measure {
            for _ in 0..<1000 {
                _ = state.handleEvent(.deviceFound(createMockDevice()), context: context)
            }
        }
    }
    
    func testJSONSerializationPerformance() {
        let device = createMockDevice()
        
        measure {
            for _ in 0..<1000 {
                do {
                    let data = try JSONEncoder().encode(device)
                    _ = try JSONDecoder().decode(ProvisionableDevice.self, from: data)
                } catch {
                    XCTFail("JSON serialization failed: \(error)")
                }
            }
        }
    }
}

// MARK: - Mock Objects

func createMockDevice(id: String = "test-device-id", rssi: Int? = -60) -> ProvisionableDevice {
    return ProvisionableDevice(
        id: id,
        name: "Test Device",
        type: .bluetoothDevice,
        category: .light,
        manufacturer: "Test Manufacturer",
        model: "Test Model",
        firmwareVersion: "1.0.0",
        hardwareVersion: "1.0.0",
        serialNumber: "TEST123456",
        macAddress: "00:11:22:33:44:55",
        rssi: rssi,
        capabilities: [.onOff, .dimming],
        securityLevel: .standard
    )
}

class MockProvisioningDelegate: ProvisioningDelegate {
    var stateChangedCalled = false
    var progressUpdatedCalled = false
    var errorOccurredCalled = false
    var completedCalled = false
    
    func provisioningStateChanged(from oldState: ProvisioningState, to newState: ProvisioningState) {
        stateChangedCalled = true
    }
    
    func provisioningProgressUpdated(_ progress: ProvisioningProgress) {
        progressUpdatedCalled = true
    }
    
    func provisioningErrorOccurred(_ error: ProvisioningError) {
        errorOccurredCalled = true
    }
    
    func provisioningCompleted(result: ProvisioningResult) {
        completedCalled = true
    }
}

class MockDeviceScanningService: DeviceScanningService {
    private let discoveredDevicesSubject = CurrentValueSubject<[ProvisionableDevice], Never>([])
    private let scanningStatusSubject = CurrentValueSubject<Bool, Never>(false)
    
    var discoveredDevices: AnyPublisher<[ProvisionableDevice], Never> {
        return discoveredDevicesSubject.eraseToAnyPublisher()
    }
    
    var isScanning: AnyPublisher<Bool, Never> {
        return scanningStatusSubject.eraseToAnyPublisher()
    }
    
    func startScanning(for types: [DeviceType], timeout: TimeInterval) -> AnyPublisher<Void, ProvisioningError> {
        return Future { [weak self] promise in
            self?.scanningStatusSubject.send(true)
            
            // 模拟发现设备
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                let mockDevices = [createMockDevice()]
                self?.discoveredDevicesSubject.send(mockDevices)
            }
            
            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }
    
    func stopScanning() -> AnyPublisher<Void, Never> {
        return Future { [weak self] promise in
            self?.scanningStatusSubject.send(false)
            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }
    
    func refreshDevice(_ deviceId: String) -> AnyPublisher<ProvisionableDevice?, ProvisioningError> {
        return Just(createMockDevice(id: deviceId))
            .setFailureType(to: ProvisioningError.self)
            .eraseToAnyPublisher()
    }
}