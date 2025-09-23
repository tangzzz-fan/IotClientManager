//
//  DeviceRepository.swift
//  PersistenceLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine
import CoreData

// MARK: - Device Repository Protocol

/// 设备仓库协议
protocol DeviceRepositoryProtocol: Repository, Queryable, Cacheable, Syncable, Observable where Entity == PersistedDevice, ID == String {
    /// 根据设备类型查找设备
    func findByType(_ type: String) async throws -> [PersistedDevice]
    
    /// 根据房间ID查找设备
    func findByRoom(_ roomId: String) async throws -> [PersistedDevice]
    
    /// 根据在线状态查找设备
    func findByOnlineStatus(_ isOnline: Bool) async throws -> [PersistedDevice]
    
    /// 根据MAC地址查找设备
    func findByMacAddress(_ macAddress: String) async throws -> PersistedDevice?
    
    /// 根据IP地址查找设备
    func findByIpAddress(_ ipAddress: String) async throws -> PersistedDevice?
    
    /// 查找低电量设备
    func findLowBatteryDevices(threshold: Int) async throws -> [PersistedDevice]
    
    /// 查找离线设备
    func findOfflineDevices(since: Date) async throws -> [PersistedDevice]
    
    /// 更新设备在线状态
    func updateOnlineStatus(_ deviceId: String, isOnline: Bool) async throws
    
    /// 更新设备电池电量
    func updateBatteryLevel(_ deviceId: String, level: Int) async throws
    
    /// 更新设备信号强度
    func updateSignalStrength(_ deviceId: String, strength: Int) async throws
    
    /// 批量更新设备状态
    func batchUpdateStatus(_ updates: [DeviceStatusUpdate]) async throws
    
    /// 获取设备统计信息
    func getStatistics() async throws -> DeviceStatistics
}

// MARK: - Device Repository Implementation

/// 设备仓库实现
class DeviceRepository: DeviceRepositoryProtocol {
    typealias Entity = PersistedDevice
    typealias ID = String
    
    // MARK: - Properties
    
    private let coreDataStack: CoreDataStack
    private let secureStorage: SecureStorage
    private let cache: NSCache<NSString, CacheWrapper<PersistedDevice>>
    private let syncQueue: DispatchQueue
    private let subject = PassthroughSubject<[PersistedDevice], Never>()
    private let eventSubject = PassthroughSubject<RepositoryEvent<PersistedDevice>, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    private let configuration: RepositoryConfiguration
    private var statistics = DeviceRepositoryStatistics()
    
    // MARK: - Initialization
    
    init(
        coreDataStack: CoreDataStack,
        secureStorage: SecureStorage,
        configuration: RepositoryConfiguration = .default
    ) {
        self.coreDataStack = coreDataStack
        self.secureStorage = secureStorage
        self.configuration = configuration
        self.cache = NSCache<NSString, CacheWrapper<PersistedDevice>>()
        self.syncQueue = DispatchQueue(label: "com.iotclient.device-repository", qos: .utility)
        
        setupCache()
        setupNotifications()
    }
    
    // MARK: - Repository Protocol
    
    func findById(_ id: String) async throws -> PersistedDevice? {
        statistics.incrementReadCount()
        
        // 检查缓存
        if configuration.cacheEnabled,
           let cached = await getCached(forKey: id) {
            statistics.incrementCacheHit()
            return cached
        }
        
        statistics.incrementCacheMiss()
        
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<DeviceEntity> = DeviceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        do {
            let entities = try await context.perform {
                try context.fetch(request)
            }
            
            guard let entity = entities.first else {
                return nil
            }
            
            let device = try entity.toPersistedDevice()
            
            // 缓存结果
            if configuration.cacheEnabled {
                await cache(device, forKey: id)
            }
            
            return device
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func findAll() async throws -> [PersistedDevice] {
        statistics.incrementReadCount()
        
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<DeviceEntity> = DeviceEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            let entities = try await context.perform {
                try context.fetch(request)
            }
            
            let devices = try entities.map { try $0.toPersistedDevice() }
            return devices
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func findBy(predicate: NSPredicate) async throws -> [PersistedDevice] {
        statistics.incrementReadCount()
        
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<DeviceEntity> = DeviceEntity.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            let entities = try await context.perform {
                try context.fetch(request)
            }
            
            let devices = try entities.map { try $0.toPersistedDevice() }
            return devices
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func save(_ entity: PersistedDevice) async throws -> PersistedDevice {
        statistics.incrementWriteCount()
        
        let context = coreDataStack.newBackgroundContext()
        
        do {
            let savedDevice = try await context.perform {
                let deviceEntity = DeviceEntity(context: context)
                try deviceEntity.update(from: entity)
                
                try context.save()
                return try deviceEntity.toPersistedDevice()
            }
            
            // 更新缓存
            if configuration.cacheEnabled {
                await cache(savedDevice, forKey: savedDevice.id)
            }
            
            // 发送事件
            eventSubject.send(.inserted(savedDevice))
            
            return savedDevice
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func saveAll(_ entities: [PersistedDevice]) async throws -> [PersistedDevice] {
        statistics.incrementWriteCount(entities.count)
        
        let context = coreDataStack.newBackgroundContext()
        
        do {
            let savedDevices = try await context.perform {
                var results: [PersistedDevice] = []
                
                for entity in entities {
                    let deviceEntity = DeviceEntity(context: context)
                    try deviceEntity.update(from: entity)
                    results.append(try deviceEntity.toPersistedDevice())
                }
                
                try context.save()
                return results
            }
            
            // 批量更新缓存
            if configuration.cacheEnabled {
                for device in savedDevices {
                    await cache(device, forKey: device.id)
                }
            }
            
            // 发送事件
            for device in savedDevices {
                eventSubject.send(.inserted(device))
            }
            
            return savedDevices
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func update(_ entity: PersistedDevice) async throws -> PersistedDevice {
        statistics.incrementWriteCount()
        
        let context = coreDataStack.newBackgroundContext()
        
        do {
            let updatedDevice = try await context.perform {
                let request: NSFetchRequest<DeviceEntity> = DeviceEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", entity.id)
                request.fetchLimit = 1
                
                guard let deviceEntity = try context.fetch(request).first else {
                    throw RepositoryError.entityNotFound
                }
                
                var updatedEntity = entity
                updatedEntity.incrementVersion()
                
                try deviceEntity.update(from: updatedEntity)
                try context.save()
                
                return try deviceEntity.toPersistedDevice()
            }
            
            // 更新缓存
            if configuration.cacheEnabled {
                await cache(updatedDevice, forKey: updatedDevice.id)
            }
            
            // 发送事件
            eventSubject.send(.updated(updatedDevice))
            
            return updatedDevice
        } catch {
            statistics.incrementErrorCount()
            if error is RepositoryError {
                throw error
            }
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func delete(_ entity: PersistedDevice) async throws {
        try await deleteById(entity.id)
    }
    
    func deleteById(_ id: String) async throws {
        statistics.incrementWriteCount()
        
        let context = coreDataStack.newBackgroundContext()
        
        do {
            let deletedDevice = try await context.perform {
                let request: NSFetchRequest<DeviceEntity> = DeviceEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", id)
                request.fetchLimit = 1
                
                guard let deviceEntity = try context.fetch(request).first else {
                    throw RepositoryError.entityNotFound
                }
                
                let device = try deviceEntity.toPersistedDevice()
                context.delete(deviceEntity)
                try context.save()
                
                return device
            }
            
            // 清除缓存
            if configuration.cacheEnabled {
                await clearCache(forKey: id)
            }
            
            // 发送事件
            eventSubject.send(.deleted(deletedDevice))
        } catch {
            statistics.incrementErrorCount()
            if error is RepositoryError {
                throw error
            }
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func deleteAll() async throws {
        statistics.incrementWriteCount()
        
        let context = coreDataStack.newBackgroundContext()
        
        do {
            try await context.perform {
                let request: NSFetchRequest<NSFetchRequestResult> = DeviceEntity.fetchRequest()
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                try context.execute(deleteRequest)
                try context.save()
            }
            
            // 清除所有缓存
            if configuration.cacheEnabled {
                await clearCache()
            }
            
            // 发送事件
            eventSubject.send(.cleared)
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func exists(_ id: String) async throws -> Bool {
        statistics.incrementReadCount()
        
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<DeviceEntity> = DeviceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        do {
            let count = try await context.perform {
                try context.count(for: request)
            }
            return count > 0
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func count() async throws -> Int {
        statistics.incrementReadCount()
        
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<DeviceEntity> = DeviceEntity.fetchRequest()
        
        do {
            return try await context.perform {
                try context.count(for: request)
            }
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func publisher() -> AnyPublisher<[PersistedDevice], Never> {
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Device-Specific Methods
    
    func findByType(_ type: String) async throws -> [PersistedDevice] {
        let predicate = NSPredicate(format: "type == %@", type)
        return try await findBy(predicate: predicate)
    }
    
    func findByRoom(_ roomId: String) async throws -> [PersistedDevice] {
        let predicate = NSPredicate(format: "roomId == %@", roomId)
        return try await findBy(predicate: predicate)
    }
    
    func findByOnlineStatus(_ isOnline: Bool) async throws -> [PersistedDevice] {
        let predicate = NSPredicate(format: "isOnline == %@", NSNumber(value: isOnline))
        return try await findBy(predicate: predicate)
    }
    
    func findByMacAddress(_ macAddress: String) async throws -> PersistedDevice? {
        let predicate = NSPredicate(format: "macAddress == %@", macAddress)
        let devices = try await findBy(predicate: predicate)
        return devices.first
    }
    
    func findByIpAddress(_ ipAddress: String) async throws -> PersistedDevice? {
        let predicate = NSPredicate(format: "ipAddress == %@", ipAddress)
        let devices = try await findBy(predicate: predicate)
        return devices.first
    }
    
    func findLowBatteryDevices(threshold: Int = 20) async throws -> [PersistedDevice] {
        let predicate = NSPredicate(format: "batteryLevel != nil AND batteryLevel <= %d", threshold)
        return try await findBy(predicate: predicate)
    }
    
    func findOfflineDevices(since: Date) async throws -> [PersistedDevice] {
        let predicate = NSPredicate(format: "isOnline == NO AND lastSeenAt <= %@", since as NSDate)
        return try await findBy(predicate: predicate)
    }
    
    func updateOnlineStatus(_ deviceId: String, isOnline: Bool) async throws {
        guard var device = try await findById(deviceId) else {
            throw RepositoryError.entityNotFound
        }
        
        device.isOnline = isOnline
        if isOnline {
            device.lastSeenAt = Date()
        }
        
        _ = try await update(device)
    }
    
    func updateBatteryLevel(_ deviceId: String, level: Int) async throws {
        guard var device = try await findById(deviceId) else {
            throw RepositoryError.entityNotFound
        }
        
        device.batteryLevel = level
        _ = try await update(device)
    }
    
    func updateSignalStrength(_ deviceId: String, strength: Int) async throws {
        guard var device = try await findById(deviceId) else {
            throw RepositoryError.entityNotFound
        }
        
        device.signalStrength = strength
        _ = try await update(device)
    }
    
    func batchUpdateStatus(_ updates: [DeviceStatusUpdate]) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        do {
            try await context.perform {
                for update in updates {
                    let request: NSFetchRequest<DeviceEntity> = DeviceEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", update.deviceId)
                    request.fetchLimit = 1
                    
                    guard let deviceEntity = try context.fetch(request).first else {
                        continue
                    }
                    
                    if let isOnline = update.isOnline {
                        deviceEntity.isOnline = isOnline
                        if isOnline {
                            deviceEntity.lastSeenAt = Date()
                        }
                    }
                    
                    if let batteryLevel = update.batteryLevel {
                        deviceEntity.batteryLevel = Int32(batteryLevel)
                    }
                    
                    if let signalStrength = update.signalStrength {
                        deviceEntity.signalStrength = Int32(signalStrength)
                    }
                    
                    if let status = update.status {
                        deviceEntity.status = status.rawValue
                    }
                    
                    deviceEntity.updatedAt = Date()
                    deviceEntity.version += 1
                }
                
                try context.save()
            }
            
            // 清除相关缓存
            if configuration.cacheEnabled {
                for update in updates {
                    await clearCache(forKey: update.deviceId)
                }
            }
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func getStatistics() async throws -> DeviceStatistics {
        let context = coreDataStack.viewContext
        
        do {
            return try await context.perform {
                let totalRequest: NSFetchRequest<DeviceEntity> = DeviceEntity.fetchRequest()
                let totalCount = try context.count(for: totalRequest)
                
                let onlineRequest: NSFetchRequest<DeviceEntity> = DeviceEntity.fetchRequest()
                onlineRequest.predicate = NSPredicate(format: "isOnline == YES")
                let onlineCount = try context.count(for: onlineRequest)
                
                let lowBatteryRequest: NSFetchRequest<DeviceEntity> = DeviceEntity.fetchRequest()
                lowBatteryRequest.predicate = NSPredicate(format: "batteryLevel != nil AND batteryLevel <= 20")
                let lowBatteryCount = try context.count(for: lowBatteryRequest)
                
                let typeRequest: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "DeviceEntity")
                typeRequest.resultType = .dictionaryResultType
                typeRequest.propertiesToFetch = ["type"]
                typeRequest.returnsDistinctResults = true
                let typeResults = try context.fetch(typeRequest)
                let deviceTypes = typeResults.compactMap { $0["type"] as? String }
                
                return DeviceStatistics(
                    totalDevices: totalCount,
                    onlineDevices: onlineCount,
                    offlineDevices: totalCount - onlineCount,
                    lowBatteryDevices: lowBatteryCount,
                    deviceTypes: deviceTypes,
                    lastUpdated: Date()
                )
            }
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupCache() {
        cache.countLimit = configuration.maxCacheSize
        cache.name = "DeviceRepository.Cache"
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .compactMap { $0.object as? NSManagedObjectContext }
            .filter { $0.persistentStoreCoordinator == self.coreDataStack.persistentContainer.persistentStoreCoordinator }
            .sink { [weak self] _ in
                Task {
                    await self?.refreshPublisher()
                }
            }
            .store(in: &cancellables)
    }
    
    private func refreshPublisher() async {
        do {
            let devices = try await findAll()
            subject.send(devices)
        } catch {
            // 记录错误但不中断流
            print("Failed to refresh device publisher: \(error)")
        }
    }
}

// MARK: - Cacheable Implementation

extension DeviceRepository {
    func cache(_ entity: PersistedDevice, forKey key: String) async {
        let wrapper = CacheWrapper(entity)
        cache.setObject(wrapper, forKey: key as NSString)
    }
    
    func getCached(forKey key: String) async -> PersistedDevice? {
        return cache.object(forKey: key as NSString)?.value
    }
    
    func clearCache() async {
        cache.removeAllObjects()
    }
    
    func clearCache(forKey key: String) async {
        cache.removeObject(forKey: key as NSString)
    }
    
    func isCached(forKey key: String) async -> Bool {
        return cache.object(forKey: key as NSString) != nil
    }
}

// MARK: - Syncable Implementation

extension DeviceRepository {
    func syncToRemote() async throws {
        // TODO: 实现远程同步逻辑
    }
    
    func syncFromRemote() async throws {
        // TODO: 实现从远程同步逻辑
    }
    
    func getPendingSyncEntities() async throws -> [PersistedDevice] {
        let predicate = NSPredicate(format: "syncStatus == %@", SyncStatus.pending.rawValue)
        return try await findBy(predicate: predicate)
    }
    
    func markAsSynced(_ entity: PersistedDevice) async throws {
        var updatedEntity = entity
        updatedEntity.markAsSynced()
        _ = try await update(updatedEntity)
    }
    
    func getSyncStatus() async -> SyncStatus {
        // TODO: 实现同步状态检查
        return .idle
    }
}

// MARK: - Observable Implementation

extension DeviceRepository {
    func observe() -> AnyPublisher<RepositoryEvent<PersistedDevice>, Never> {
        return eventSubject.eraseToAnyPublisher()
    }
    
    func observe(_ id: String) -> AnyPublisher<PersistedDevice?, Never> {
        return eventSubject
            .compactMap { event in
                switch event {
                case .inserted(let device), .updated(let device):
                    return device.id == id ? device : nil
                case .deleted(let device):
                    return device.id == id ? nil : nil
                case .cleared:
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }
    
    func observe(predicate: NSPredicate) -> AnyPublisher<[PersistedDevice], Never> {
        return subject
            .map { devices in
                devices.filter { device in
                    predicate.evaluate(with: device)
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Queryable Implementation

extension DeviceRepository {
    func findWithPagination(
        offset: Int,
        limit: Int,
        sortBy: String? = nil,
        ascending: Bool = true
    ) async throws -> PaginatedResult<PersistedDevice> {
        statistics.incrementReadCount()
        
        let context = coreDataStack.viewContext
        
        // 获取总数
        let countRequest: NSFetchRequest<DeviceEntity> = DeviceEntity.fetchRequest()
        let totalCount = try await context.perform {
            try context.count(for: countRequest)
        }
        
        // 获取分页数据
        let request: NSFetchRequest<DeviceEntity> = DeviceEntity.fetchRequest()
        request.fetchOffset = offset
        request.fetchLimit = limit
        
        if let sortBy = sortBy {
            request.sortDescriptors = [NSSortDescriptor(key: sortBy, ascending: ascending)]
        } else {
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        }
        
        do {
            let entities = try await context.perform {
                try context.fetch(request)
            }
            
            let devices = try entities.map { try $0.toPersistedDevice() }
            
            return PaginatedResult(
                items: devices,
                totalCount: totalCount,
                offset: offset,
                limit: limit
            )
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func search(query: String, fields: [String]) async throws -> [PersistedDevice] {
        statistics.incrementReadCount()
        
        let predicates = fields.map { field in
            NSPredicate(format: "%K CONTAINS[cd] %@", field, query)
        }
        
        let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        return try await findBy(predicate: compoundPredicate)
    }
    
    func findBy(criteria: [QueryCriteria]) async throws -> [PersistedDevice] {
        statistics.incrementReadCount()
        
        let predicates = criteria.map { criterion in
            NSPredicate(format: criterion.operation.predicateFormat, criterion.field, criterion.value)
        }
        
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return try await findBy(predicate: compoundPredicate)
    }
}

// MARK: - Supporting Types

/// 设备状态更新
struct DeviceStatusUpdate {
    let deviceId: String
    let isOnline: Bool?
    let batteryLevel: Int?
    let signalStrength: Int?
    let status: DeviceStatus?
    
    init(
        deviceId: String,
        isOnline: Bool? = nil,
        batteryLevel: Int? = nil,
        signalStrength: Int? = nil,
        status: DeviceStatus? = nil
    ) {
        self.deviceId = deviceId
        self.isOnline = isOnline
        self.batteryLevel = batteryLevel
        self.signalStrength = signalStrength
        self.status = status
    }
}

/// 设备统计信息
struct DeviceStatistics {
    let totalDevices: Int
    let onlineDevices: Int
    let offlineDevices: Int
    let lowBatteryDevices: Int
    let deviceTypes: [String]
    let lastUpdated: Date
    
    var onlinePercentage: Double {
        return totalDevices > 0 ? Double(onlineDevices) / Double(totalDevices) * 100 : 0
    }
    
    var lowBatteryPercentage: Double {
        return totalDevices > 0 ? Double(lowBatteryDevices) / Double(totalDevices) * 100 : 0
    }
}

/// 设备仓库统计
struct DeviceRepositoryStatistics {
    private(set) var readCount: Int64 = 0
    private(set) var writeCount: Int64 = 0
    private(set) var cacheHitCount: Int64 = 0
    private(set) var cacheMissCount: Int64 = 0
    private(set) var errorCount: Int64 = 0
    
    mutating func incrementReadCount(_ count: Int = 1) {
        readCount += Int64(count)
    }
    
    mutating func incrementWriteCount(_ count: Int = 1) {
        writeCount += Int64(count)
    }
    
    mutating func incrementCacheHit() {
        cacheHitCount += 1
    }
    
    mutating func incrementCacheMiss() {
        cacheMissCount += 1
    }
    
    mutating func incrementErrorCount() {
        errorCount += 1
    }
    
    var cacheHitRate: Double {
        let total = cacheHitCount + cacheMissCount
        return total > 0 ? Double(cacheHitCount) / Double(total) : 0
    }
}

/// 缓存包装器
class CacheWrapper<T> {
    let value: T
    let timestamp: Date
    
    init(_ value: T) {
        self.value = value
        self.timestamp = Date()
    }
}

// MARK: - Core Data Extensions

/// Core Data设备实体扩展
extension DeviceEntity {
    func toPersistedDevice() throws -> PersistedDevice {
        guard let id = self.id,
              let name = self.name,
              let type = self.type,
              let model = self.model,
              let manufacturer = self.manufacturer,
              let createdAt = self.createdAt,
              let updatedAt = self.updatedAt else {
            throw RepositoryError.invalidEntity
        }
        
        return PersistedDevice(
            id: id,
            name: name,
            type: type,
            model: model,
            manufacturer: manufacturer
        )
        // TODO: 映射其他属性
    }
    
    func update(from device: PersistedDevice) throws {
        self.id = device.id
        self.name = device.name
        self.type = device.type
        self.model = device.model
        self.manufacturer = device.manufacturer
        self.firmwareVersion = device.firmwareVersion
        self.hardwareVersion = device.hardwareVersion
        self.serialNumber = device.serialNumber
        self.macAddress = device.macAddress
        self.ipAddress = device.ipAddress
        self.status = device.status.rawValue
        self.isOnline = device.isOnline
        self.lastSeenAt = device.lastSeenAt
        self.roomId = device.roomId
        self.createdAt = device.createdAt
        self.updatedAt = device.updatedAt
        self.version = Int32(device.version)
        self.syncStatus = device.syncStatus.rawValue
        self.lastSyncAt = device.lastSyncAt
        self.remoteId = device.remoteId
        
        if let batteryLevel = device.batteryLevel {
            self.batteryLevel = Int32(batteryLevel)
        }
        
        if let signalStrength = device.signalStrength {
            self.signalStrength = Int32(signalStrength)
        }
        
        // TODO: 映射其他复杂属性
    }
}

// MARK: - Mock Core Data Stack

/// 模拟Core Data栈（用于测试）
class CoreDataStack {
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DataModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
}

/// 模拟设备实体（用于测试）
class DeviceEntity: NSManagedObject {
    @NSManaged var id: String?
    @NSManaged var name: String?
    @NSManaged var type: String?
    @NSManaged var model: String?
    @NSManaged var manufacturer: String?
    @NSManaged var firmwareVersion: String?
    @NSManaged var hardwareVersion: String?
    @NSManaged var serialNumber: String?
    @NSManaged var macAddress: String?
    @NSManaged var ipAddress: String?
    @NSManaged var status: String?
    @NSManaged var isOnline: Bool
    @NSManaged var lastSeenAt: Date?
    @NSManaged var batteryLevel: Int32
    @NSManaged var signalStrength: Int32
    @NSManaged var roomId: String?
    @NSManaged var createdAt: Date?
    @NSManaged var updatedAt: Date?
    @NSManaged var version: Int32
    @NSManaged var syncStatus: String?
    @NSManaged var lastSyncAt: Date?
    @NSManaged var remoteId: String?
    
    static func fetchRequest() -> NSFetchRequest<DeviceEntity> {
        return NSFetchRequest<DeviceEntity>(entityName: "DeviceEntity")
    }
}