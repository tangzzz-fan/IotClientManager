//
//  SettingsRepository.swift
//  PersistenceLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine
import CoreData

// MARK: - Settings Repository Protocol

/// 设置仓库协议
protocol SettingsRepositoryProtocol: Repository, Queryable, Cacheable, Syncable, Observable where Entity == AppSettings, ID == String {
    /// 根据设置类型查找设置
    func findByType(_ type: SettingType) async throws -> [AppSettings]
    
    /// 根据键查找设置
    func findByKey(_ key: String) async throws -> AppSettings?
    
    /// 根据分组查找设置
    func findByGroup(_ group: String) async throws -> [AppSettings]
    
    /// 获取字符串值
    func getString(forKey key: String, defaultValue: String?) async throws -> String?
    
    /// 获取整数值
    func getInt(forKey key: String, defaultValue: Int?) async throws -> Int?
    
    /// 获取布尔值
    func getBool(forKey key: String, defaultValue: Bool?) async throws -> Bool?
    
    /// 获取浮点数值
    func getDouble(forKey key: String, defaultValue: Double?) async throws -> Double?
    
    /// 获取数据值
    func getData(forKey key: String) async throws -> Data?
    
    /// 设置字符串值
    func setString(_ value: String?, forKey key: String, group: String?) async throws
    
    /// 设置整数值
    func setInt(_ value: Int?, forKey key: String, group: String?) async throws
    
    /// 设置布尔值
    func setBool(_ value: Bool?, forKey key: String, group: String?) async throws
    
    /// 设置浮点数值
    func setDouble(_ value: Double?, forKey key: String, group: String?) async throws
    
    /// 设置数据值
    func setData(_ value: Data?, forKey key: String, group: String?) async throws
    
    /// 批量设置
    func setBatch(_ settings: [String: Any], group: String?) async throws
    
    /// 删除设置
    func removeSetting(forKey key: String) async throws
    
    /// 删除分组
    func removeGroup(_ group: String) async throws
    
    /// 重置所有设置
    func resetAllSettings() async throws
    
    /// 导出设置
    func exportSettings() async throws -> Data
    
    /// 导入设置
    func importSettings(from data: Data) async throws
    
    /// 获取设置统计信息
    func getSettingsStatistics() async throws -> SettingsStatistics
}

// MARK: - Settings Repository Implementation

/// 设置仓库实现
class SettingsRepository: SettingsRepositoryProtocol {
    typealias Entity = AppSettings
    typealias ID = String
    
    // MARK: - Properties
    
    private let coreDataStack: CoreDataStack
    private let secureStorage: SecureStorage
    private let cache: NSCache<NSString, CacheWrapper<AppSettings>>
    private let syncQueue: DispatchQueue
    private let subject = PassthroughSubject<[AppSettings], Never>()
    private let eventSubject = PassthroughSubject<RepositoryEvent<AppSettings>, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    private let configuration: RepositoryConfiguration
    private var statistics = SettingsRepositoryStatistics()
    
    // MARK: - Initialization
    
    init(
        coreDataStack: CoreDataStack,
        secureStorage: SecureStorage,
        configuration: RepositoryConfiguration = .default
    ) {
        self.coreDataStack = coreDataStack
        self.secureStorage = secureStorage
        self.configuration = configuration
        self.cache = NSCache<NSString, CacheWrapper<AppSettings>>()
        self.syncQueue = DispatchQueue(label: "com.iotclient.settings-repository", qos: .utility)
        
        setupCache()
        setupNotifications()
        setupDefaultSettings()
    }
    
    // MARK: - Repository Protocol
    
    func findById(_ id: String) async throws -> AppSettings? {
        statistics.incrementReadCount()
        
        // 检查缓存
        if configuration.cacheEnabled,
           let cached = await getCached(forKey: id) {
            statistics.incrementCacheHit()
            return cached
        }
        
        statistics.incrementCacheMiss()
        
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<SettingsEntity> = SettingsEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        do {
            let entities = try await context.perform {
                try context.fetch(request)
            }
            
            guard let entity = entities.first else {
                return nil
            }
            
            let setting = try entity.toAppSettings()
            
            // 缓存结果
            if configuration.cacheEnabled {
                await cache(setting, forKey: id)
            }
            
            return setting
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func findAll() async throws -> [AppSettings] {
        statistics.incrementReadCount()
        
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<SettingsEntity> = SettingsEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "group", ascending: true),
            NSSortDescriptor(key: "key", ascending: true)
        ]
        
        do {
            let entities = try await context.perform {
                try context.fetch(request)
            }
            
            let settings = try entities.map { try $0.toAppSettings() }
            return settings
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func findBy(predicate: NSPredicate) async throws -> [AppSettings] {
        statistics.incrementReadCount()
        
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<SettingsEntity> = SettingsEntity.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = [
            NSSortDescriptor(key: "group", ascending: true),
            NSSortDescriptor(key: "key", ascending: true)
        ]
        
        do {
            let entities = try await context.perform {
                try context.fetch(request)
            }
            
            let settings = try entities.map { try $0.toAppSettings() }
            return settings
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func save(_ entity: AppSettings) async throws -> AppSettings {
        statistics.incrementWriteCount()
        
        let context = coreDataStack.newBackgroundContext()
        
        do {
            let savedSetting = try await context.perform {
                let settingEntity = SettingsEntity(context: context)
                try settingEntity.update(from: entity)
                
                try context.save()
                return try settingEntity.toAppSettings()
            }
            
            // 如果是敏感设置，保存到安全存储
            if entity.isSecure {
                try await secureStorage.store(
                    entity.value,
                    forKey: "setting_\(entity.key)",
                    accessibility: .whenUnlockedThisDeviceOnly
                )
            }
            
            // 更新缓存
            if configuration.cacheEnabled {
                await cache(savedSetting, forKey: savedSetting.id)
            }
            
            // 发送事件
            eventSubject.send(.inserted(savedSetting))
            
            return savedSetting
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func saveAll(_ entities: [AppSettings]) async throws -> [AppSettings] {
        statistics.incrementWriteCount(entities.count)
        
        let context = coreDataStack.newBackgroundContext()
        
        do {
            let savedSettings = try await context.perform {
                var results: [AppSettings] = []
                
                for entity in entities {
                    let settingEntity = SettingsEntity(context: context)
                    try settingEntity.update(from: entity)
                    results.append(try settingEntity.toAppSettings())
                }
                
                try context.save()
                return results
            }
            
            // 批量保存敏感设置
            for (index, setting) in entities.enumerated() {
                if setting.isSecure {
                    try await secureStorage.store(
                        setting.value,
                        forKey: "setting_\(setting.key)",
                        accessibility: .whenUnlockedThisDeviceOnly
                    )
                }
            }
            
            // 批量更新缓存
            if configuration.cacheEnabled {
                for setting in savedSettings {
                    await cache(setting, forKey: setting.id)
                }
            }
            
            // 发送事件
            for setting in savedSettings {
                eventSubject.send(.inserted(setting))
            }
            
            return savedSettings
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func update(_ entity: AppSettings) async throws -> AppSettings {
        statistics.incrementWriteCount()
        
        let context = coreDataStack.newBackgroundContext()
        
        do {
            let updatedSetting = try await context.perform {
                let request: NSFetchRequest<SettingsEntity> = SettingsEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", entity.id)
                request.fetchLimit = 1
                
                guard let settingEntity = try context.fetch(request).first else {
                    throw RepositoryError.entityNotFound
                }
                
                var updatedEntity = entity
                updatedEntity.incrementVersion()
                
                try settingEntity.update(from: updatedEntity)
                try context.save()
                
                return try settingEntity.toAppSettings()
            }
            
            // 更新敏感设置
            if entity.isSecure {
                try await secureStorage.store(
                    entity.value,
                    forKey: "setting_\(entity.key)",
                    accessibility: .whenUnlockedThisDeviceOnly
                )
            }
            
            // 更新缓存
            if configuration.cacheEnabled {
                await cache(updatedSetting, forKey: updatedSetting.id)
            }
            
            // 发送事件
            eventSubject.send(.updated(updatedSetting))
            
            return updatedSetting
        } catch {
            statistics.incrementErrorCount()
            if error is RepositoryError {
                throw error
            }
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func delete(_ entity: AppSettings) async throws {
        try await deleteById(entity.id)
    }
    
    func deleteById(_ id: String) async throws {
        statistics.incrementWriteCount()
        
        let context = coreDataStack.newBackgroundContext()
        
        do {
            let deletedSetting = try await context.perform {
                let request: NSFetchRequest<SettingsEntity> = SettingsEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", id)
                request.fetchLimit = 1
                
                guard let settingEntity = try context.fetch(request).first else {
                    throw RepositoryError.entityNotFound
                }
                
                let setting = try settingEntity.toAppSettings()
                context.delete(settingEntity)
                try context.save()
                
                return setting
            }
            
            // 删除敏感设置
            if deletedSetting.isSecure {
                try await secureStorage.delete(forKey: "setting_\(deletedSetting.key)")
            }
            
            // 清除缓存
            if configuration.cacheEnabled {
                await clearCache(forKey: id)
            }
            
            // 发送事件
            eventSubject.send(.deleted(deletedSetting))
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
            // 获取所有敏感设置的键
            let secureKeys = try await context.perform {
                let request: NSFetchRequest<SettingsEntity> = SettingsEntity.fetchRequest()
                request.predicate = NSPredicate(format: "isSecure == YES")
                request.propertiesToFetch = ["key"]
                let entities = try context.fetch(request)
                return entities.compactMap { $0.key }
            }
            
            try await context.perform {
                let request: NSFetchRequest<NSFetchRequestResult> = SettingsEntity.fetchRequest()
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                try context.execute(deleteRequest)
                try context.save()
            }
            
            // 清理所有敏感设置
            for key in secureKeys {
                try? await secureStorage.delete(forKey: "setting_\(key)")
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
        let request: NSFetchRequest<SettingsEntity> = SettingsEntity.fetchRequest()
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
        let request: NSFetchRequest<SettingsEntity> = SettingsEntity.fetchRequest()
        
        do {
            return try await context.perform {
                try context.count(for: request)
            }
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func publisher() -> AnyPublisher<[AppSettings], Never> {
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Settings-Specific Methods
    
    func findByType(_ type: SettingType) async throws -> [AppSettings] {
        let predicate = NSPredicate(format: "type == %@", type.rawValue)
        return try await findBy(predicate: predicate)
    }
    
    func findByKey(_ key: String) async throws -> AppSettings? {
        let predicate = NSPredicate(format: "key == %@", key)
        let settings = try await findBy(predicate: predicate)
        return settings.first
    }
    
    func findByGroup(_ group: String) async throws -> [AppSettings] {
        let predicate = NSPredicate(format: "group == %@", group)
        return try await findBy(predicate: predicate)
    }
    
    func getString(forKey key: String, defaultValue: String? = nil) async throws -> String? {
        guard let setting = try await findByKey(key) else {
            return defaultValue
        }
        
        if setting.isSecure {
            return try await secureStorage.retrieve(forKey: "setting_\(key)") as? String
        }
        
        return setting.value as? String ?? defaultValue
    }
    
    func getInt(forKey key: String, defaultValue: Int? = nil) async throws -> Int? {
        guard let setting = try await findByKey(key) else {
            return defaultValue
        }
        
        if setting.isSecure {
            let value = try await secureStorage.retrieve(forKey: "setting_\(key)")
            return value as? Int ?? defaultValue
        }
        
        return setting.value as? Int ?? defaultValue
    }
    
    func getBool(forKey key: String, defaultValue: Bool? = nil) async throws -> Bool? {
        guard let setting = try await findByKey(key) else {
            return defaultValue
        }
        
        if setting.isSecure {
            let value = try await secureStorage.retrieve(forKey: "setting_\(key)")
            return value as? Bool ?? defaultValue
        }
        
        return setting.value as? Bool ?? defaultValue
    }
    
    func getDouble(forKey key: String, defaultValue: Double? = nil) async throws -> Double? {
        guard let setting = try await findByKey(key) else {
            return defaultValue
        }
        
        if setting.isSecure {
            let value = try await secureStorage.retrieve(forKey: "setting_\(key)")
            return value as? Double ?? defaultValue
        }
        
        return setting.value as? Double ?? defaultValue
    }
    
    func getData(forKey key: String) async throws -> Data? {
        guard let setting = try await findByKey(key) else {
            return nil
        }
        
        if setting.isSecure {
            return try await secureStorage.retrieve(forKey: "setting_\(key)") as? Data
        }
        
        return setting.value as? Data
    }
    
    func setString(_ value: String?, forKey key: String, group: String? = nil) async throws {
        try await setSetting(value: value, forKey: key, type: .string, group: group)
    }
    
    func setInt(_ value: Int?, forKey key: String, group: String? = nil) async throws {
        try await setSetting(value: value, forKey: key, type: .integer, group: group)
    }
    
    func setBool(_ value: Bool?, forKey key: String, group: String? = nil) async throws {
        try await setSetting(value: value, forKey: key, type: .boolean, group: group)
    }
    
    func setDouble(_ value: Double?, forKey key: String, group: String? = nil) async throws {
        try await setSetting(value: value, forKey: key, type: .double, group: group)
    }
    
    func setData(_ value: Data?, forKey key: String, group: String? = nil) async throws {
        try await setSetting(value: value, forKey: key, type: .data, group: group, isSecure: true)
    }
    
    func setBatch(_ settings: [String: Any], group: String? = nil) async throws {
        var appSettings: [AppSettings] = []
        
        for (key, value) in settings {
            let type = determineSettingType(for: value)
            let setting = AppSettings(
                id: UUID().uuidString,
                key: key,
                value: value,
                type: type,
                group: group ?? "general",
                isSecure: type == .data,
                validationRules: [],
                createdAt: Date(),
                updatedAt: Date()
            )
            appSettings.append(setting)
        }
        
        _ = try await saveAll(appSettings)
    }
    
    func removeSetting(forKey key: String) async throws {
        guard let setting = try await findByKey(key) else {
            return
        }
        
        try await delete(setting)
    }
    
    func removeGroup(_ group: String) async throws {
        let settings = try await findByGroup(group)
        
        for setting in settings {
            try await delete(setting)
        }
    }
    
    func resetAllSettings() async throws {
        try await deleteAll()
        setupDefaultSettings()
    }
    
    func exportSettings() async throws -> Data {
        let settings = try await findAll()
        let exportData = SettingsExportData(settings: settings, exportDate: Date())
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        return try encoder.encode(exportData)
    }
    
    func importSettings(from data: Data) async throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let importData = try decoder.decode(SettingsExportData.self, from: data)
        
        // 清除现有设置
        try await deleteAll()
        
        // 导入新设置
        _ = try await saveAll(importData.settings)
    }
    
    func getSettingsStatistics() async throws -> SettingsStatistics {
        let context = coreDataStack.viewContext
        
        do {
            return try await context.perform {
                let totalRequest: NSFetchRequest<SettingsEntity> = SettingsEntity.fetchRequest()
                let totalCount = try context.count(for: totalRequest)
                
                let secureRequest: NSFetchRequest<SettingsEntity> = SettingsEntity.fetchRequest()
                secureRequest.predicate = NSPredicate(format: "isSecure == YES")
                let secureCount = try context.count(for: secureRequest)
                
                let groupRequest: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "SettingsEntity")
                groupRequest.resultType = .dictionaryResultType
                groupRequest.propertiesToFetch = ["group"]
                groupRequest.returnsDistinctResults = true
                let groupResults = try context.fetch(groupRequest)
                let groups = groupResults.compactMap { $0["group"] as? String }
                
                let typeRequest: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "SettingsEntity")
                typeRequest.resultType = .dictionaryResultType
                typeRequest.propertiesToFetch = ["type"]
                typeRequest.returnsDistinctResults = true
                let typeResults = try context.fetch(typeRequest)
                let types = typeResults.compactMap { $0["type"] as? String }
                
                return SettingsStatistics(
                    totalSettings: totalCount,
                    secureSettings: secureCount,
                    groups: groups,
                    types: types,
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
        cache.name = "SettingsRepository.Cache"
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
    
    private func setupDefaultSettings() {
        Task {
            let defaultSettings = createDefaultSettings()
            
            for setting in defaultSettings {
                if try await findByKey(setting.key) == nil {
                    try? await save(setting)
                }
            }
        }
    }
    
    private func createDefaultSettings() -> [AppSettings] {
        return [
            AppSettings(
                id: UUID().uuidString,
                key: "app_theme",
                value: "system",
                type: .string,
                group: "appearance",
                description: "应用主题设置",
                validationRules: [ValidationRule(type: .options, value: ["light", "dark", "system"])]
            ),
            AppSettings(
                id: UUID().uuidString,
                key: "temperature_unit",
                value: "celsius",
                type: .string,
                group: "units",
                description: "温度单位",
                validationRules: [ValidationRule(type: .options, value: ["celsius", "fahrenheit"])]
            ),
            AppSettings(
                id: UUID().uuidString,
                key: "auto_sync",
                value: true,
                type: .boolean,
                group: "sync",
                description: "自动同步设置"
            ),
            AppSettings(
                id: UUID().uuidString,
                key: "sync_interval",
                value: 300,
                type: .integer,
                group: "sync",
                description: "同步间隔（秒）",
                validationRules: [ValidationRule(type: .range, value: [60, 3600])]
            ),
            AppSettings(
                id: UUID().uuidString,
                key: "notifications_enabled",
                value: true,
                type: .boolean,
                group: "notifications",
                description: "启用通知"
            ),
            AppSettings(
                id: UUID().uuidString,
                key: "debug_mode",
                value: false,
                type: .boolean,
                group: "debug",
                description: "调试模式"
            )
        ]
    }
    
    private func refreshPublisher() async {
        do {
            let settings = try await findAll()
            subject.send(settings)
        } catch {
            print("Failed to refresh settings publisher: \(error)")
        }
    }
    
    private func setSetting(
        value: Any?,
        forKey key: String,
        type: SettingType,
        group: String?,
        isSecure: Bool = false
    ) async throws {
        if let existingSetting = try await findByKey(key) {
            var updatedSetting = existingSetting
            updatedSetting.value = value
            updatedSetting.updatedAt = Date()
            _ = try await update(updatedSetting)
        } else {
            let newSetting = AppSettings(
                id: UUID().uuidString,
                key: key,
                value: value,
                type: type,
                group: group ?? "general",
                isSecure: isSecure,
                validationRules: [],
                createdAt: Date(),
                updatedAt: Date()
            )
            _ = try await save(newSetting)
        }
    }
    
    private func determineSettingType(for value: Any) -> SettingType {
        switch value {
        case is String:
            return .string
        case is Int:
            return .integer
        case is Bool:
            return .boolean
        case is Double, is Float:
            return .double
        case is Data:
            return .data
        default:
            return .string
        }
    }
}

// MARK: - Cacheable Implementation

extension SettingsRepository {
    func cache(_ entity: AppSettings, forKey key: String) async {
        let wrapper = CacheWrapper(entity)
        cache.setObject(wrapper, forKey: key as NSString)
    }
    
    func getCached(forKey key: String) async -> AppSettings? {
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

extension SettingsRepository {
    func syncToRemote() async throws {
        // TODO: 实现远程同步逻辑
    }
    
    func syncFromRemote() async throws {
        // TODO: 实现从远程同步逻辑
    }
    
    func getPendingSyncEntities() async throws -> [AppSettings] {
        let predicate = NSPredicate(format: "syncStatus == %@", SyncStatus.pending.rawValue)
        return try await findBy(predicate: predicate)
    }
    
    func markAsSynced(_ entity: AppSettings) async throws {
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

extension SettingsRepository {
    func observe() -> AnyPublisher<RepositoryEvent<AppSettings>, Never> {
        return eventSubject.eraseToAnyPublisher()
    }
    
    func observe(_ id: String) -> AnyPublisher<AppSettings?, Never> {
        return eventSubject
            .compactMap { event in
                switch event {
                case .inserted(let setting), .updated(let setting):
                    return setting.id == id ? setting : nil
                case .deleted(let setting):
                    return setting.id == id ? nil : nil
                case .cleared:
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }
    
    func observe(predicate: NSPredicate) -> AnyPublisher<[AppSettings], Never> {
        return subject
            .map { settings in
                settings.filter { setting in
                    predicate.evaluate(with: setting)
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Queryable Implementation

extension SettingsRepository {
    func findWithPagination(
        offset: Int,
        limit: Int,
        sortBy: String? = nil,
        ascending: Bool = true
    ) async throws -> PaginatedResult<AppSettings> {
        statistics.incrementReadCount()
        
        let context = coreDataStack.viewContext
        
        // 获取总数
        let countRequest: NSFetchRequest<SettingsEntity> = SettingsEntity.fetchRequest()
        let totalCount = try await context.perform {
            try context.count(for: countRequest)
        }
        
        // 获取分页数据
        let request: NSFetchRequest<SettingsEntity> = SettingsEntity.fetchRequest()
        request.fetchOffset = offset
        request.fetchLimit = limit
        
        if let sortBy = sortBy {
            request.sortDescriptors = [NSSortDescriptor(key: sortBy, ascending: ascending)]
        } else {
            request.sortDescriptors = [
                NSSortDescriptor(key: "group", ascending: true),
                NSSortDescriptor(key: "key", ascending: true)
            ]
        }
        
        do {
            let entities = try await context.perform {
                try context.fetch(request)
            }
            
            let settings = try entities.map { try $0.toAppSettings() }
            
            return PaginatedResult(
                items: settings,
                totalCount: totalCount,
                offset: offset,
                limit: limit
            )
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func search(query: String, fields: [String]) async throws -> [AppSettings] {
        statistics.incrementReadCount()
        
        let predicates = fields.map { field in
            NSPredicate(format: "%K CONTAINS[cd] %@", field, query)
        }
        
        let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        return try await findBy(predicate: compoundPredicate)
    }
    
    func findBy(criteria: [QueryCriteria]) async throws -> [AppSettings] {
        statistics.incrementReadCount()
        
        let predicates = criteria.map { criterion in
            NSPredicate(format: criterion.operation.predicateFormat, criterion.field, criterion.value)
        }
        
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return try await findBy(predicate: compoundPredicate)
    }
}

// MARK: - Supporting Types

/// 设置统计信息
struct SettingsStatistics {
    let totalSettings: Int
    let secureSettings: Int
    let groups: [String]
    let types: [String]
    let lastUpdated: Date
    
    var securePercentage: Double {
        return totalSettings > 0 ? Double(secureSettings) / Double(totalSettings) * 100 : 0
    }
}

/// 设置仓库统计
struct SettingsRepositoryStatistics {
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

/// 设置导出数据
struct SettingsExportData: Codable {
    let settings: [AppSettings]
    let exportDate: Date
    let version: String
    
    init(settings: [AppSettings], exportDate: Date, version: String = "1.0") {
        self.settings = settings
        self.exportDate = exportDate
        self.version = version
    }
}

// MARK: - Core Data Extensions

/// Core Data设置实体扩展
extension SettingsEntity {
    func toAppSettings() throws -> AppSettings {
        guard let id = self.id,
              let key = self.key,
              let typeString = self.type,
              let type = SettingType(rawValue: typeString),
              let group = self.group,
              let createdAt = self.createdAt,
              let updatedAt = self.updatedAt else {
            throw RepositoryError.invalidEntity
        }
        
        return AppSettings(
            id: id,
            key: key,
            value: self.value,
            type: type,
            group: group,
            description: self.settingDescription,
            isSecure: self.isSecure,
            validationRules: [], // TODO: 从JSON解析
            createdAt: createdAt,
            updatedAt: updatedAt,
            version: Int(self.version),
            syncStatus: SyncStatus(rawValue: self.syncStatus ?? "") ?? .idle,
            lastSyncAt: self.lastSyncAt,
            remoteId: self.remoteId
        )
    }
    
    func update(from setting: AppSettings) throws {
        self.id = setting.id
        self.key = setting.key
        self.value = setting.value
        self.type = setting.type.rawValue
        self.group = setting.group
        self.settingDescription = setting.description
        self.isSecure = setting.isSecure
        self.createdAt = setting.createdAt
        self.updatedAt = setting.updatedAt
        self.version = Int32(setting.version)
        self.syncStatus = setting.syncStatus.rawValue
        self.lastSyncAt = setting.lastSyncAt
        self.remoteId = setting.remoteId
        
        // TODO: 序列化validationRules为JSON
    }
}

/// 模拟设置实体（用于测试）
class SettingsEntity: NSManagedObject {
    @NSManaged var id: String?
    @NSManaged var key: String?
    @NSManaged var value: Any?
    @NSManaged var type: String?
    @NSManaged var group: String?
    @NSManaged var settingDescription: String?
    @NSManaged var isSecure: Bool
    @NSManaged var createdAt: Date?
    @NSManaged var updatedAt: Date?
    @NSManaged var version: Int32
    @NSManaged var syncStatus: String?
    @NSManaged var lastSyncAt: Date?
    @NSManaged var remoteId: String?
    
    static func fetchRequest() -> NSFetchRequest<SettingsEntity> {
        return NSFetchRequest<SettingsEntity>(entityName: "SettingsEntity")
    }
}