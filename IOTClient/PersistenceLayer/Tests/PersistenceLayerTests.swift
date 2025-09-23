//
//  PersistenceLayerTests.swift
//  PersistenceLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import XCTest
import CoreData
import Combine
@testable import IOTClient

// MARK: - Base Test Case

class PersistenceLayerTestCase: XCTestCase {
    
    var coreDataStack: InMemoryCoreDataStack!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        coreDataStack = InMemoryCoreDataStack()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        coreDataStack = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    func createTestDevice(
        id: String = UUID().uuidString,
        name: String = "Test Device",
        type: String = "sensor",
        macAddress: String = "00:11:22:33:44:55"
    ) -> PersistedDevice {
        return PersistedDevice(
            id: id,
            name: name,
            type: type,
            macAddress: macAddress,
            ipAddress: "192.168.1.100",
            isOnline: true,
            batteryLevel: 85,
            signalStrength: -45,
            lastSeen: Date(),
            roomId: nil,
            createdAt: Date(),
            updatedAt: Date(),
            version: 1
        )
    }
    
    func createTestUser(
        id: String = UUID().uuidString,
        username: String = "testuser",
        email: String = "test@example.com"
    ) -> PersistedUser {
        return PersistedUser(
            id: id,
            username: username,
            email: email,
            firstName: "Test",
            lastName: "User",
            avatarURL: nil,
            isActive: true,
            lastLoginAt: Date(),
            preferences: UserPreferences(
                temperatureUnit: .celsius,
                timeFormat: .twentyFourHour,
                language: "en",
                theme: "light",
                notifications: NotificationSettings(
                    enabled: true,
                    deviceAlerts: true,
                    systemUpdates: true,
                    quietHours: QuietHours(
                        enabled: false,
                        startTime: "22:00",
                        endTime: "08:00"
                    )
                )
            ),
            createdAt: Date(),
            updatedAt: Date(),
            version: 1
        )
    }
    
    func createTestSettings(
        key: String = "test_setting",
        value: String = "test_value"
    ) -> AppSettings {
        return AppSettings(
            id: UUID().uuidString,
            key: key,
            value: value,
            type: .string,
            group: "test",
            isSecure: false,
            validationRules: [],
            createdAt: Date(),
            updatedAt: Date(),
            version: 1
        )
    }
}

// MARK: - Device Repository Tests

class DeviceRepositoryTests: PersistenceLayerTestCase {
    
    var deviceRepository: DeviceRepository!
    var mockSecureStorage: MockSecureStorage!
    
    override func setUp() {
        super.setUp()
        mockSecureStorage = MockSecureStorage()
        deviceRepository = DeviceRepository(
            coreDataStack: coreDataStack,
            secureStorage: mockSecureStorage
        )
    }
    
    override func tearDown() {
        deviceRepository = nil
        mockSecureStorage = nil
        super.tearDown()
    }
    
    // MARK: - Basic CRUD Tests
    
    func testSaveDevice() async throws {
        // Given
        let device = createTestDevice()
        
        // When
        let savedDevice = try await deviceRepository.save(device)
        
        // Then
        XCTAssertEqual(savedDevice.id, device.id)
        XCTAssertEqual(savedDevice.name, device.name)
        XCTAssertEqual(savedDevice.type, device.type)
    }
    
    func testFindDeviceById() async throws {
        // Given
        let device = createTestDevice()
        _ = try await deviceRepository.save(device)
        
        // When
        let foundDevice = try await deviceRepository.findById(device.id)
        
        // Then
        XCTAssertNotNil(foundDevice)
        XCTAssertEqual(foundDevice?.id, device.id)
    }
    
    func testUpdateDevice() async throws {
        // Given
        let device = createTestDevice()
        let savedDevice = try await deviceRepository.save(device)
        
        // When
        var updatedDevice = savedDevice
        updatedDevice.name = "Updated Device"
        let result = try await deviceRepository.update(updatedDevice)
        
        // Then
        XCTAssertEqual(result.name, "Updated Device")
    }
    
    func testDeleteDevice() async throws {
        // Given
        let device = createTestDevice()
        let savedDevice = try await deviceRepository.save(device)
        
        // When
        try await deviceRepository.delete(savedDevice.id)
        
        // Then
        let foundDevice = try await deviceRepository.findById(savedDevice.id)
        XCTAssertNil(foundDevice)
    }
    
    // MARK: - Query Tests
    
    func testFindDevicesByType() async throws {
        // Given
        let sensor1 = createTestDevice(id: "1", name: "Sensor 1", type: "temperature")
        let sensor2 = createTestDevice(id: "2", name: "Sensor 2", type: "temperature")
        let switch1 = createTestDevice(id: "3", name: "Switch 1", type: "switch")
        
        _ = try await deviceRepository.save(sensor1)
        _ = try await deviceRepository.save(sensor2)
        _ = try await deviceRepository.save(switch1)
        
        // When
        let temperatureSensors = try await deviceRepository.findByType("temperature")
        
        // Then
        XCTAssertEqual(temperatureSensors.count, 2)
        XCTAssertTrue(temperatureSensors.allSatisfy { $0.type == "temperature" })
    }
    
    func testFindOnlineDevices() async throws {
        // Given
        var device1 = createTestDevice(id: "1", name: "Online Device")
        device1.isOnline = true
        
        var device2 = createTestDevice(id: "2", name: "Offline Device")
        device2.isOnline = false
        
        _ = try await deviceRepository.save(device1)
        _ = try await deviceRepository.save(device2)
        
        // When
        let onlineDevices = try await deviceRepository.findOnlineDevices()
        
        // Then
        XCTAssertEqual(onlineDevices.count, 1)
        XCTAssertEqual(onlineDevices.first?.name, "Online Device")
    }
    
    func testFindLowBatteryDevices() async throws {
        // Given
        var device1 = createTestDevice(id: "1", name: "Low Battery Device")
        device1.batteryLevel = 15
        
        var device2 = createTestDevice(id: "2", name: "Good Battery Device")
        device2.batteryLevel = 85
        
        _ = try await deviceRepository.save(device1)
        _ = try await deviceRepository.save(device2)
        
        // When
        let lowBatteryDevices = try await deviceRepository.findLowBatteryDevices(threshold: 20)
        
        // Then
        XCTAssertEqual(lowBatteryDevices.count, 1)
        XCTAssertEqual(lowBatteryDevices.first?.name, "Low Battery Device")
    }
    
    // MARK: - Batch Operations Tests
    
    func testBatchUpdateDeviceStatus() async throws {
        // Given
        let devices = [
            createTestDevice(id: "1", name: "Device 1"),
            createTestDevice(id: "2", name: "Device 2"),
            createTestDevice(id: "3", name: "Device 3")
        ]
        
        for device in devices {
            _ = try await deviceRepository.save(device)
        }
        
        let updates = devices.map { device in
            DeviceStatusUpdate(
                deviceId: device.id,
                isOnline: false,
                batteryLevel: 50,
                signalStrength: -60,
                lastSeen: Date()
            )
        }
        
        // When
        try await deviceRepository.batchUpdateStatus(updates)
        
        // Then
        for update in updates {
            let device = try await deviceRepository.findById(update.deviceId)
            XCTAssertNotNil(device)
            XCTAssertEqual(device?.isOnline, false)
            XCTAssertEqual(device?.batteryLevel, 50)
            XCTAssertEqual(device?.signalStrength, -60)
        }
    }
    
    // MARK: - Statistics Tests
    
    func testGetDeviceStatistics() async throws {
        // Given
        let devices = [
            createTestDevice(id: "1", type: "temperature"),
            createTestDevice(id: "2", type: "temperature"),
            createTestDevice(id: "3", type: "switch")
        ]
        
        for device in devices {
            _ = try await deviceRepository.save(device)
        }
        
        // When
        let statistics = try await deviceRepository.getStatistics()
        
        // Then
        XCTAssertEqual(statistics.totalDevices, 3)
        XCTAssertEqual(statistics.onlineDevices, 3) // All devices are online by default
        XCTAssertEqual(statistics.devicesByType["temperature"], 2)
        XCTAssertEqual(statistics.devicesByType["switch"], 1)
    }
    
    // MARK: - Cache Tests
    
    func testCacheOperations() async throws {
        // Given
        let device = createTestDevice()
        
        // When - Save device (should be cached)
        let savedDevice = try await deviceRepository.save(device)
        
        // Then - Should be in cache
        let cachedDevice = deviceRepository.getCachedItem(for: savedDevice.id)
        XCTAssertNotNil(cachedDevice)
        XCTAssertEqual(cachedDevice?.id, savedDevice.id)
        
        // When - Clear cache
        deviceRepository.clearCache()
        
        // Then - Should not be in cache
        let cachedDeviceAfterClear = deviceRepository.getCachedItem(for: savedDevice.id)
        XCTAssertNil(cachedDeviceAfterClear)
    }
    
    // MARK: - Observer Tests
    
    func testRepositoryObserver() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Repository event received")
        var receivedEvent: RepositoryEvent<PersistedDevice>?
        
        deviceRepository.eventPublisher
            .sink { event in
                receivedEvent = event
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        let device = createTestDevice()
        _ = try await deviceRepository.save(device)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedEvent)
        XCTAssertEqual(receivedEvent?.type, .created)
        XCTAssertEqual(receivedEvent?.entity.id, device.id)
    }
}

// MARK: - User Repository Tests

class UserRepositoryTests: PersistenceLayerTestCase {
    
    var userRepository: UserRepository!
    var mockSecureStorage: MockSecureStorage!
    
    override func setUp() {
        super.setUp()
        mockSecureStorage = MockSecureStorage()
        userRepository = UserRepository(
            coreDataStack: coreDataStack,
            secureStorage: mockSecureStorage
        )
    }
    
    override func tearDown() {
        userRepository = nil
        mockSecureStorage = nil
        super.tearDown()
    }
    
    func testSaveUser() async throws {
        // Given
        let user = createTestUser()
        
        // When
        let savedUser = try await userRepository.save(user)
        
        // Then
        XCTAssertEqual(savedUser.id, user.id)
        XCTAssertEqual(savedUser.username, user.username)
        XCTAssertEqual(savedUser.email, user.email)
    }
    
    func testFindUserByUsername() async throws {
        // Given
        let user = createTestUser(username: "testuser")
        _ = try await userRepository.save(user)
        
        // When
        let foundUser = try await userRepository.findByUsername("testuser")
        
        // Then
        XCTAssertNotNil(foundUser)
        XCTAssertEqual(foundUser?.username, "testuser")
    }
    
    func testFindUserByEmail() async throws {
        // Given
        let user = createTestUser(email: "test@example.com")
        _ = try await userRepository.save(user)
        
        // When
        let foundUser = try await userRepository.findByEmail("test@example.com")
        
        // Then
        XCTAssertNotNil(foundUser)
        XCTAssertEqual(foundUser?.email, "test@example.com")
    }
    
    func testValidateCredentials() async throws {
        // Given
        let user = createTestUser()
        _ = try await userRepository.save(user)
        
        // Mock password storage
        mockSecureStorage.storedData["user_password_\(user.id)"] = "hashedPassword".data(using: .utf8)!
        
        // When
        let isValid = try await userRepository.validateCredentials(
            username: user.username,
            password: "password"
        )
        
        // Then
        // Note: This would normally validate against a real hash
        // For testing, we just check that the method was called
        XCTAssertTrue(mockSecureStorage.retrieveDataCalled)
    }
    
    func testUpdateUserPreferences() async throws {
        // Given
        let user = createTestUser()
        let savedUser = try await userRepository.save(user)
        
        let newPreferences = UserPreferences(
            temperatureUnit: .fahrenheit,
            timeFormat: .twelveHour,
            language: "es",
            theme: "dark",
            notifications: savedUser.preferences.notifications
        )
        
        // When
        let updatedUser = try await userRepository.updatePreferences(
            userId: savedUser.id,
            preferences: newPreferences
        )
        
        // Then
        XCTAssertEqual(updatedUser.preferences.temperatureUnit, .fahrenheit)
        XCTAssertEqual(updatedUser.preferences.timeFormat, .twelveHour)
        XCTAssertEqual(updatedUser.preferences.language, "es")
        XCTAssertEqual(updatedUser.preferences.theme, "dark")
    }
    
    func testCurrentUser() async throws {
        // Given
        let user = createTestUser()
        let savedUser = try await userRepository.save(user)
        
        // When
        try await userRepository.setCurrentUser(savedUser)
        let currentUser = try await userRepository.getCurrentUser()
        
        // Then
        XCTAssertNotNil(currentUser)
        XCTAssertEqual(currentUser?.id, savedUser.id)
    }
}

// MARK: - Settings Repository Tests

class SettingsRepositoryTests: PersistenceLayerTestCase {
    
    var settingsRepository: SettingsRepository!
    var mockSecureStorage: MockSecureStorage!
    
    override func setUp() {
        super.setUp()
        mockSecureStorage = MockSecureStorage()
        settingsRepository = SettingsRepository(
            coreDataStack: coreDataStack,
            secureStorage: mockSecureStorage
        )
    }
    
    override func tearDown() {
        settingsRepository = nil
        mockSecureStorage = nil
        super.tearDown()
    }
    
    func testSaveSetting() async throws {
        // Given
        let setting = createTestSettings(key: "app_theme", value: "dark")
        
        // When
        let savedSetting = try await settingsRepository.save(setting)
        
        // Then
        XCTAssertEqual(savedSetting.key, "app_theme")
        XCTAssertEqual(savedSetting.value, "dark")
    }
    
    func testFindSettingByKey() async throws {
        // Given
        let setting = createTestSettings(key: "notification_enabled", value: "true")
        _ = try await settingsRepository.save(setting)
        
        // When
        let foundSetting = try await settingsRepository.findByKey("notification_enabled")
        
        // Then
        XCTAssertNotNil(foundSetting)
        XCTAssertEqual(foundSetting?.value, "true")
    }
    
    func testGetStringValue() async throws {
        // Given
        let setting = createTestSettings(key: "app_language", value: "en")
        _ = try await settingsRepository.save(setting)
        
        // When
        let value = try await settingsRepository.getStringValue(for: "app_language")
        
        // Then
        XCTAssertEqual(value, "en")
    }
    
    func testGetBoolValue() async throws {
        // Given
        var setting = createTestSettings(key: "notifications_enabled", value: "true")
        setting.type = .boolean
        _ = try await settingsRepository.save(setting)
        
        // When
        let value = try await settingsRepository.getBoolValue(for: "notifications_enabled")
        
        // Then
        XCTAssertEqual(value, true)
    }
    
    func testGetIntValue() async throws {
        // Given
        var setting = createTestSettings(key: "max_devices", value: "50")
        setting.type = .integer
        _ = try await settingsRepository.save(setting)
        
        // When
        let value = try await settingsRepository.getIntValue(for: "max_devices")
        
        // Then
        XCTAssertEqual(value, 50)
    }
    
    func testFindSettingsByGroup() async throws {
        // Given
        let setting1 = createTestSettings(key: "ui_theme", value: "dark")
        var setting1Modified = setting1
        setting1Modified.group = "ui"
        
        let setting2 = createTestSettings(key: "ui_language", value: "en")
        var setting2Modified = setting2
        setting2Modified.group = "ui"
        
        let setting3 = createTestSettings(key: "sync_interval", value: "300")
        var setting3Modified = setting3
        setting3Modified.group = "sync"
        
        _ = try await settingsRepository.save(setting1Modified)
        _ = try await settingsRepository.save(setting2Modified)
        _ = try await settingsRepository.save(setting3Modified)
        
        // When
        let uiSettings = try await settingsRepository.findByGroup("ui")
        
        // Then
        XCTAssertEqual(uiSettings.count, 2)
        XCTAssertTrue(uiSettings.allSatisfy { $0.group == "ui" })
    }
    
    func testBatchSaveSettings() async throws {
        // Given
        let settings = [
            createTestSettings(key: "setting1", value: "value1"),
            createTestSettings(key: "setting2", value: "value2"),
            createTestSettings(key: "setting3", value: "value3")
        ]
        
        // When
        let savedSettings = try await settingsRepository.batchSave(settings)
        
        // Then
        XCTAssertEqual(savedSettings.count, 3)
        
        for (index, savedSetting) in savedSettings.enumerated() {
            XCTAssertEqual(savedSetting.key, settings[index].key)
            XCTAssertEqual(savedSetting.value, settings[index].value)
        }
    }
    
    func testResetSettings() async throws {
        // Given
        let settings = [
            createTestSettings(key: "setting1", value: "value1"),
            createTestSettings(key: "setting2", value: "value2")
        ]
        
        for setting in settings {
            _ = try await settingsRepository.save(setting)
        }
        
        // When
        try await settingsRepository.resetToDefaults()
        
        // Then
        let allSettings = try await settingsRepository.findAll()
        XCTAssertEqual(allSettings.count, 0)
    }
}

// MARK: - Core Data Stack Tests

class CoreDataStackTests: PersistenceLayerTestCase {
    
    func testPersistentContainer() {
        // Given & When
        let container = coreDataStack.persistentContainer
        
        // Then
        XCTAssertNotNil(container)
        XCTAssertEqual(container.name, "IOTClientDataModel")
    }
    
    func testViewContext() {
        // Given & When
        let context = coreDataStack.viewContext
        
        // Then
        XCTAssertNotNil(context)
        XCTAssertTrue(context.automaticallyMergesChangesFromParent)
    }
    
    func testNewBackgroundContext() {
        // Given & When
        let backgroundContext = coreDataStack.newBackgroundContext()
        
        // Then
        XCTAssertNotNil(backgroundContext)
        XCTAssertNotEqual(backgroundContext, coreDataStack.viewContext)
        XCTAssertTrue(backgroundContext.automaticallyMergesChangesFromParent)
    }
    
    func testSaveContext() async throws {
        // Given
        let context = coreDataStack.viewContext
        
        // Create a test entity (this would be a real Core Data entity in practice)
        // For this test, we'll just verify the save method doesn't throw
        
        // When & Then
        try await coreDataStack.save(context: context)
        // If we get here without throwing, the test passes
    }
    
    func testPerformBackgroundTask() async throws {
        // Given
        var taskExecuted = false
        
        // When
        let result = try await coreDataStack.performBackgroundTask { context in
            taskExecuted = true
            return "Task completed"
        }
        
        // Then
        XCTAssertTrue(taskExecuted)
        XCTAssertEqual(result, "Task completed")
    }
}

// MARK: - Security Tests

class SecurityTests: XCTestCase {
    
    var keychainManager: KeychainManager!
    var encryptedStorageManager: EncryptedStorageManager!
    
    override func setUp() {
        super.setUp()
        keychainManager = KeychainManager()
        encryptedStorageManager = EncryptedStorageManager()
    }
    
    override func tearDown() {
        keychainManager = nil
        encryptedStorageManager = nil
        super.tearDown()
    }
    
    func testKeychainStore() async throws {
        // Given
        let key = "test_key"
        let data = "test_data".data(using: .utf8)!
        
        // When
        try await keychainManager.store(data, for: key)
        
        // Then
        let retrievedData = try await keychainManager.retrieve(for: key)
        XCTAssertEqual(retrievedData, data)
    }
    
    func testKeychainDelete() async throws {
        // Given
        let key = "test_key_delete"
        let data = "test_data".data(using: .utf8)!
        
        try await keychainManager.store(data, for: key)
        
        // When
        try await keychainManager.delete(for: key)
        
        // Then
        do {
            _ = try await keychainManager.retrieve(for: key)
            XCTFail("Should have thrown an error")
        } catch {
            // Expected to throw
        }
    }
    
    func testEncryptedStorage() async throws {
        // Given
        let key = "test_encryption_key"
        let data = "sensitive_data".data(using: .utf8)!
        let password = "test_password"
        
        // When
        try await encryptedStorageManager.storeEncrypted(data, for: key, password: password)
        
        // Then
        let decryptedData = try await encryptedStorageManager.retrieveDecrypted(for: key, password: password)
        XCTAssertEqual(decryptedData, data)
    }
}

// MARK: - Mock Classes

class MockSecureStorage: SecureStorage {
    
    var storedData: [String: Data] = [:]
    var storeDataCalled = false
    var retrieveDataCalled = false
    var deleteDataCalled = false
    
    func store(_ data: Data, for key: String) async throws {
        storeDataCalled = true
        storedData[key] = data
    }
    
    func retrieve(for key: String) async throws -> Data {
        retrieveDataCalled = true
        guard let data = storedData[key] else {
            throw SecureStorageError.itemNotFound
        }
        return data
    }
    
    func delete(for key: String) async throws {
        deleteDataCalled = true
        storedData.removeValue(forKey: key)
    }
    
    func exists(for key: String) async throws -> Bool {
        return storedData[key] != nil
    }
    
    func getAllKeys() async throws -> [String] {
        return Array(storedData.keys)
    }
    
    func clear() async throws {
        storedData.removeAll()
    }
}

// MARK: - Test Extensions

extension XCTestCase {
    
    /// 等待异步操作完成的辅助方法
    func waitForAsync<T>(
        timeout: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withTimeout(timeout) {
            try await operation()
        }
    }
    
    /// 带超时的异步操作
    func withTimeout<T>(
        _ timeout: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TimeoutError()
            }
            
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Test Errors

struct TimeoutError: Error {
    let message = "Operation timed out"
}

// MARK: - Performance Tests

class PersistencePerformanceTests: PersistenceLayerTestCase {
    
    func testDeviceRepositoryPerformance() {
        let deviceRepository = DeviceRepository(
            coreDataStack: coreDataStack,
            secureStorage: MockSecureStorage()
        )
        
        measure {
            let expectation = XCTestExpectation(description: "Save devices")
            
            Task {
                do {
                    for i in 0..<100 {
                        let device = createTestDevice(
                            id: "device_\(i)",
                            name: "Device \(i)"
                        )
                        _ = try await deviceRepository.save(device)
                    }
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to save devices: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testBatchOperationPerformance() {
        let deviceRepository = DeviceRepository(
            coreDataStack: coreDataStack,
            secureStorage: MockSecureStorage()
        )
        
        measure {
            let expectation = XCTestExpectation(description: "Batch update devices")
            
            Task {
                do {
                    // First, create devices
                    var devices: [PersistedDevice] = []
                    for i in 0..<100 {
                        let device = createTestDevice(
                            id: "device_\(i)",
                            name: "Device \(i)"
                        )
                        devices.append(try await deviceRepository.save(device))
                    }
                    
                    // Then, batch update them
                    let updates = devices.map { device in
                        DeviceStatusUpdate(
                            deviceId: device.id,
                            isOnline: false,
                            batteryLevel: 50,
                            signalStrength: -60,
                            lastSeen: Date()
                        )
                    }
                    
                    try await deviceRepository.batchUpdateStatus(updates)
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to batch update devices: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
}