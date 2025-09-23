//
//  Repository.swift
//  PersistenceLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

// MARK: - Repository Protocol

/// 仓库模式基础协议
/// 定义了数据访问层的通用接口
protocol Repository {
    associatedtype Entity: Identifiable & Codable
    associatedtype ID: Hashable
    
    /// 根据ID查找实体
    func findById(_ id: ID) async throws -> Entity?
    
    /// 查找所有实体
    func findAll() async throws -> [Entity]
    
    /// 根据条件查找实体
    func findBy(predicate: NSPredicate) async throws -> [Entity]
    
    /// 保存实体
    func save(_ entity: Entity) async throws -> Entity
    
    /// 批量保存实体
    func saveAll(_ entities: [Entity]) async throws -> [Entity]
    
    /// 更新实体
    func update(_ entity: Entity) async throws -> Entity
    
    /// 删除实体
    func delete(_ entity: Entity) async throws
    
    /// 根据ID删除实体
    func deleteById(_ id: ID) async throws
    
    /// 删除所有实体
    func deleteAll() async throws
    
    /// 检查实体是否存在
    func exists(_ id: ID) async throws -> Bool
    
    /// 获取实体数量
    func count() async throws -> Int
    
    /// 获取实体变化的发布者
    func publisher() -> AnyPublisher<[Entity], Never>
}

// MARK: - Queryable Protocol

/// 可查询协议
/// 为仓库提供高级查询功能
protocol Queryable {
    associatedtype Entity
    
    /// 分页查询
    func findWithPagination(
        offset: Int,
        limit: Int,
        sortBy: String?,
        ascending: Bool
    ) async throws -> PaginatedResult<Entity>
    
    /// 搜索实体
    func search(
        query: String,
        fields: [String]
    ) async throws -> [Entity]
    
    /// 根据多个条件查询
    func findBy(
        criteria: [QueryCriteria]
    ) async throws -> [Entity]
}

// MARK: - Cacheable Protocol

/// 可缓存协议
/// 为仓库提供缓存功能
protocol Cacheable {
    associatedtype Entity
    
    /// 缓存实体
    func cache(_ entity: Entity, forKey key: String) async
    
    /// 从缓存获取实体
    func getCached(forKey key: String) async -> Entity?
    
    /// 清除缓存
    func clearCache() async
    
    /// 清除特定键的缓存
    func clearCache(forKey key: String) async
    
    /// 检查缓存是否存在
    func isCached(forKey key: String) async -> Bool
}

// MARK: - Syncable Protocol

/// 可同步协议
/// 为仓库提供数据同步功能
protocol Syncable {
    associatedtype Entity
    
    /// 同步到远程
    func syncToRemote() async throws
    
    /// 从远程同步
    func syncFromRemote() async throws
    
    /// 获取需要同步的实体
    func getPendingSyncEntities() async throws -> [Entity]
    
    /// 标记实体为已同步
    func markAsSynced(_ entity: Entity) async throws
    
    /// 获取同步状态
    func getSyncStatus() async -> SyncStatus
}

// MARK: - Observable Protocol

/// 可观察协议
/// 为仓库提供数据变化观察功能
protocol Observable {
    associatedtype Entity
    
    /// 观察实体变化
    func observe() -> AnyPublisher<RepositoryEvent<Entity>, Never>
    
    /// 观察特定实体变化
    func observe<ID: Hashable>(_ id: ID) -> AnyPublisher<Entity?, Never>
    
    /// 观察查询结果变化
    func observe(predicate: NSPredicate) -> AnyPublisher<[Entity], Never>
}

// MARK: - Transactional Protocol

/// 事务协议
/// 为仓库提供事务支持
protocol Transactional {
    /// 在事务中执行操作
    func performTransaction<T>(
        _ operation: @escaping () async throws -> T
    ) async throws -> T
    
    /// 开始事务
    func beginTransaction() async throws
    
    /// 提交事务
    func commitTransaction() async throws
    
    /// 回滚事务
    func rollbackTransaction() async throws
}

// MARK: - Supporting Types

/// 分页结果
struct PaginatedResult<T> {
    let items: [T]
    let totalCount: Int
    let offset: Int
    let limit: Int
    let hasMore: Bool
    
    init(items: [T], totalCount: Int, offset: Int, limit: Int) {
        self.items = items
        self.totalCount = totalCount
        self.offset = offset
        self.limit = limit
        self.hasMore = offset + items.count < totalCount
    }
}

/// 查询条件
struct QueryCriteria {
    let field: String
    let operation: QueryOperation
    let value: Any
    
    init(field: String, operation: QueryOperation, value: Any) {
        self.field = field
        self.operation = operation
        self.value = value
    }
}

/// 查询操作
enum QueryOperation {
    case equal
    case notEqual
    case greaterThan
    case greaterThanOrEqual
    case lessThan
    case lessThanOrEqual
    case contains
    case startsWith
    case endsWith
    case `in`
    case notIn
    case isNull
    case isNotNull
    case between
    
    var predicateFormat: String {
        switch self {
        case .equal: return "%K == %@"
        case .notEqual: return "%K != %@"
        case .greaterThan: return "%K > %@"
        case .greaterThanOrEqual: return "%K >= %@"
        case .lessThan: return "%K < %@"
        case .lessThanOrEqual: return "%K <= %@"
        case .contains: return "%K CONTAINS[cd] %@"
        case .startsWith: return "%K BEGINSWITH[cd] %@"
        case .endsWith: return "%K ENDSWITH[cd] %@"
        case .in: return "%K IN %@"
        case .notIn: return "NOT (%K IN %@)"
        case .isNull: return "%K == nil"
        case .isNotNull: return "%K != nil"
        case .between: return "%K BETWEEN %@"
        }
    }
}

/// 同步状态
enum SyncStatus {
    case idle
    case syncing
    case completed
    case failed(Error)
    
    var isActive: Bool {
        if case .syncing = self {
            return true
        }
        return false
    }
}

/// 仓库事件
enum RepositoryEvent<T> {
    case inserted(T)
    case updated(T)
    case deleted(T)
    case cleared
    
    var entity: T? {
        switch self {
        case .inserted(let entity), .updated(let entity), .deleted(let entity):
            return entity
        case .cleared:
            return nil
        }
    }
}

// MARK: - Repository Error

/// 仓库错误
enum RepositoryError: Error, LocalizedError {
    case entityNotFound
    case invalidEntity
    case duplicateEntity
    case constraintViolation
    case transactionFailed
    case syncFailed(Error)
    case cacheError(Error)
    case persistenceError(Error)
    case networkError(Error)
    case authenticationRequired
    case permissionDenied
    case quotaExceeded
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .entityNotFound:
            return "Entity not found"
        case .invalidEntity:
            return "Invalid entity"
        case .duplicateEntity:
            return "Duplicate entity"
        case .constraintViolation:
            return "Constraint violation"
        case .transactionFailed:
            return "Transaction failed"
        case .syncFailed(let error):
            return "Sync failed: \(error.localizedDescription)"
        case .cacheError(let error):
            return "Cache error: \(error.localizedDescription)"
        case .persistenceError(let error):
            return "Persistence error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .authenticationRequired:
            return "Authentication required"
        case .permissionDenied:
            return "Permission denied"
        case .quotaExceeded:
            return "Quota exceeded"
        case .custom(let message):
            return message
        }
    }
}

// MARK: - Repository Configuration

/// 仓库配置
struct RepositoryConfiguration {
    let cacheEnabled: Bool
    let syncEnabled: Bool
    let encryptionEnabled: Bool
    let maxCacheSize: Int
    let syncInterval: TimeInterval
    let retryAttempts: Int
    let timeout: TimeInterval
    
    static let `default` = RepositoryConfiguration(
        cacheEnabled: true,
        syncEnabled: true,
        encryptionEnabled: true,
        maxCacheSize: 1000,
        syncInterval: 300, // 5 minutes
        retryAttempts: 3,
        timeout: 30
    )
}