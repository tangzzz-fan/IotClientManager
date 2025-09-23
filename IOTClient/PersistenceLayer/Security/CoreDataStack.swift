//
//  CoreDataStack.swift
//  PersistenceLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import CoreData
import Combine

// MARK: - Core Data Stack

/// Core Data栈管理器
class CoreDataStack {
    
    // MARK: - Properties
    
    static let shared = CoreDataStack()
    
    private let modelName: String
    private let storeType: String
    private let configuration: CoreDataConfiguration
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        
        // 配置持久化存储描述符
        if let storeDescription = container.persistentStoreDescriptions.first {
            configureStoreDescription(storeDescription)
        }
        
        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                self?.handlePersistentStoreError(error)
            } else {
                self?.configurePersistentContainer(container)
            }
        }
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        let context = persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Initialization
    
    init(
        modelName: String = "IOTClientDataModel",
        storeType: String = NSSQLiteStoreType,
        configuration: CoreDataConfiguration = .default
    ) {
        self.modelName = modelName
        self.storeType = storeType
        self.configuration = configuration
        
        setupNotifications()
    }
    
    // MARK: - Context Management
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    func performBackgroundTask<T>(
        _ block: @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            let context = newBackgroundContext()
            context.perform {
                do {
                    let result = try block(context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func save(context: NSManagedObjectContext? = nil) async throws {
        let contextToSave = context ?? viewContext
        
        guard contextToSave.hasChanges else { return }
        
        try await contextToSave.perform {
            do {
                try contextToSave.save()
            } catch {
                contextToSave.rollback()
                throw CoreDataError.saveFailed(error)
            }
        }
    }
    
    // MARK: - Store Management
    
    func deleteAndRecreateStore() async throws {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            throw CoreDataError.storeNotFound
        }
        
        // 删除现有存储
        if let store = persistentContainer.persistentStoreCoordinator.persistentStores.first {
            try persistentContainer.persistentStoreCoordinator.remove(store)
        }
        
        // 删除存储文件
        try FileManager.default.removeItem(at: storeURL)
        
        // 重新加载存储
        try await withCheckedThrowingContinuation { continuation in
            persistentContainer.loadPersistentStores { _, error in
                if let error = error {
                    continuation.resume(throwing: CoreDataError.storeLoadFailed(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func migrateStoreIfNeeded() async throws {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url,
              FileManager.default.fileExists(atPath: storeURL.path) else {
            return
        }
        
        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: storeType,
            at: storeURL,
            options: nil
        )
        
        let model = persistentContainer.managedObjectModel
        
        if !model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) {
            try await performMigration(from: storeURL)
        }
    }
    
    // MARK: - Batch Operations
    
    func batchDelete<T: NSManagedObject>(
        entity: T.Type,
        predicate: NSPredicate? = nil
    ) async throws {
        let context = newBackgroundContext()
        
        try await context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entity))
            fetchRequest.predicate = predicate
            
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeObjectIDs
            
            do {
                let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                let objectIDs = result?.result as? [NSManagedObjectID] ?? []
                
                // 更新视图上下文
                let changes = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.viewContext])
                
                try context.save()
            } catch {
                throw CoreDataError.batchOperationFailed(error)
            }
        }
    }
    
    func batchUpdate<T: NSManagedObject>(
        entity: T.Type,
        predicate: NSPredicate? = nil,
        propertiesToUpdate: [String: Any]
    ) async throws {
        let context = newBackgroundContext()
        
        try await context.perform {
            let updateRequest = NSBatchUpdateRequest(entityName: String(describing: entity))
            updateRequest.predicate = predicate
            updateRequest.propertiesToUpdate = propertiesToUpdate
            updateRequest.resultType = .updatedObjectIDsResultType
            
            do {
                let result = try context.execute(updateRequest) as? NSBatchUpdateResult
                let objectIDs = result?.result as? [NSManagedObjectID] ?? []
                
                // 刷新视图上下文中的对象
                for objectID in objectIDs {
                    let object = try? self.viewContext.existingObject(with: objectID)
                    self.viewContext.refresh(object!, mergeChanges: true)
                }
                
                try context.save()
            } catch {
                throw CoreDataError.batchOperationFailed(error)
            }
        }
    }
    
    // MARK: - Statistics
    
    func getStorageStatistics() async throws -> StorageStatistics {
        return try await withCheckedThrowingContinuation { continuation in
            viewContext.perform {
                do {
                    let statistics = try self.calculateStorageStatistics()
                    continuation.resume(returning: statistics)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidSave(_:)),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate(_:)),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    private func configureStoreDescription(_ storeDescription: NSPersistentStoreDescription) {
        storeDescription.type = storeType
        storeDescription.shouldMigrateStoreAutomatically = configuration.shouldMigrateAutomatically
        storeDescription.shouldInferMappingModelAutomatically = configuration.shouldInferMappingModel
        
        // 启用WAL模式以提高并发性能
        storeDescription.setOption("WAL" as NSString, forKey: "journal_mode")
        
        // 启用外键约束
        storeDescription.setOption(true as NSNumber, forKey: "foreign_keys")
        
        // 设置文件保护
        if configuration.enableFileProtection {
            storeDescription.setOption(
                FileProtectionType.complete as NSString,
                forKey: NSPersistentStoreFileProtectionKey
            )
        }
        
        // 配置加密（如果需要）
        if let encryptionKey = configuration.encryptionKey {
            storeDescription.setOption(
                encryptionKey as NSString,
                forKey: "encryption_key"
            )
        }
    }
    
    private func configurePersistentContainer(_ container: NSPersistentContainer) {
        // 配置视图上下文
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // 设置撤销管理器（如果需要）
        if configuration.enableUndoManager {
            container.viewContext.undoManager = UndoManager()
        }
    }
    
    private func handlePersistentStoreError(_ error: Error) {
        print("Core Data error: \(error)")
        
        // 在生产环境中，可能需要更复杂的错误处理逻辑
        // 例如：尝试迁移、删除并重建存储等
        
        if configuration.shouldRecreateStoreOnError {
            Task {
                try? await deleteAndRecreateStore()
            }
        }
    }
    
    private func performMigration(from storeURL: URL) async throws {
        // 实现自定义迁移逻辑
        // 这里可以添加复杂的数据迁移逻辑
        print("Performing Core Data migration from: \(storeURL)")
        
        // 简单的迁移：删除并重建
        try await deleteAndRecreateStore()
    }
    
    private func calculateStorageStatistics() throws -> StorageStatistics {
        let entityNames = persistentContainer.managedObjectModel.entities.compactMap { $0.name }
        var entityCounts: [String: Int] = [:]
        var totalSize: Int64 = 0
        
        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
            let count = try viewContext.count(for: fetchRequest)
            entityCounts[entityName] = count
        }
        
        // 计算存储文件大小
        if let storeURL = persistentContainer.persistentStoreDescriptions.first?.url {
            let attributes = try FileManager.default.attributesOfItem(atPath: storeURL.path)
            totalSize = attributes[.size] as? Int64 ?? 0
        }
        
        return StorageStatistics(
            totalSize: totalSize,
            entityCounts: entityCounts,
            lastUpdated: Date()
        )
    }
    
    @objc private func contextDidSave(_ notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext,
              context != viewContext,
              context.persistentStoreCoordinator == persistentContainer.persistentStoreCoordinator else {
            return
        }
        
        viewContext.perform {
            self.viewContext.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    @objc private func applicationWillTerminate(_ notification: Notification) {
        Task {
            try? await save()
        }
    }
}

// MARK: - Core Data Configuration

/// Core Data配置
struct CoreDataConfiguration {
    let shouldMigrateAutomatically: Bool
    let shouldInferMappingModel: Bool
    let enableFileProtection: Bool
    let enableUndoManager: Bool
    let shouldRecreateStoreOnError: Bool
    let encryptionKey: String?
    
    static let `default` = CoreDataConfiguration(
        shouldMigrateAutomatically: true,
        shouldInferMappingModel: true,
        enableFileProtection: true,
        enableUndoManager: false,
        shouldRecreateStoreOnError: false,
        encryptionKey: nil
    )
    
    static let testing = CoreDataConfiguration(
        shouldMigrateAutomatically: false,
        shouldInferMappingModel: false,
        enableFileProtection: false,
        enableUndoManager: false,
        shouldRecreateStoreOnError: true,
        encryptionKey: nil
    )
}

// MARK: - Storage Statistics

/// 存储统计信息
struct StorageStatistics {
    let totalSize: Int64
    let entityCounts: [String: Int]
    let lastUpdated: Date
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }
    
    var totalEntities: Int {
        return entityCounts.values.reduce(0, +)
    }
}

// MARK: - Core Data Errors

/// Core Data错误类型
enum CoreDataError: Error, LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case storeNotFound
    case storeLoadFailed(Error)
    case migrationFailed(Error)
    case batchOperationFailed(Error)
    case invalidEntity
    case contextNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "保存失败: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "获取数据失败: \(error.localizedDescription)"
        case .storeNotFound:
            return "未找到数据存储"
        case .storeLoadFailed(let error):
            return "加载数据存储失败: \(error.localizedDescription)"
        case .migrationFailed(let error):
            return "数据迁移失败: \(error.localizedDescription)"
        case .batchOperationFailed(let error):
            return "批量操作失败: \(error.localizedDescription)"
        case .invalidEntity:
            return "无效的实体"
        case .contextNotAvailable:
            return "上下文不可用"
        }
    }
}

// MARK: - Extensions

/// NSManagedObjectContext扩展
extension NSManagedObjectContext {
    func saveIfNeeded() throws {
        guard hasChanges else { return }
        try save()
    }
    
    func rollbackIfNeeded() {
        guard hasChanges else { return }
        rollback()
    }
    
    func fetch<T: NSManagedObject>(
        _ entityType: T.Type,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        limit: Int? = nil
    ) throws -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: entityType))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        if let limit = limit {
            request.fetchLimit = limit
        }
        
        return try fetch(request)
    }
    
    func count<T: NSManagedObject>(
        _ entityType: T.Type,
        predicate: NSPredicate? = nil
    ) throws -> Int {
        let request = NSFetchRequest<T>(entityName: String(describing: entityType))
        request.predicate = predicate
        
        return try count(for: request)
    }
    
    func deleteAll<T: NSManagedObject>(_ entityType: T.Type) throws {
        let request = NSFetchRequest<T>(entityName: String(describing: entityType))
        let objects = try fetch(request)
        
        for object in objects {
            delete(object)
        }
    }
}

// MARK: - Testing Support

#if DEBUG
/// 测试用的内存Core Data栈
class InMemoryCoreDataStack: CoreDataStack {
    
    override init(
        modelName: String = "IOTClientDataModel",
        storeType: String = NSInMemoryStoreType,
        configuration: CoreDataConfiguration = .testing
    ) {
        super.init(
            modelName: modelName,
            storeType: storeType,
            configuration: configuration
        )
    }
    
    override lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        
        let storeDescription = NSPersistentStoreDescription()
        storeDescription.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [storeDescription]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Test Core Data stack failed to load: \(error)")
            }
        }
        
        return container
    }()
}
#endif