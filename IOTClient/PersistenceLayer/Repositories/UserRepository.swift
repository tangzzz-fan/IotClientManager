//
//  UserRepository.swift
//  PersistenceLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine
import CoreData

// MARK: - User Repository Protocol

/// 用户仓库协议
protocol UserRepositoryProtocol: Repository, Queryable, Cacheable, Syncable, Observable where Entity == PersistedUser, ID == String {
    /// 根据用户名查找用户
    func findByUsername(_ username: String) async throws -> PersistedUser?
    
    /// 根据邮箱查找用户
    func findByEmail(_ email: String) async throws -> PersistedUser?
    
    /// 根据手机号查找用户
    func findByPhoneNumber(_ phoneNumber: String) async throws -> PersistedUser?
    
    /// 验证用户凭证
    func validateCredentials(username: String, password: String) async throws -> PersistedUser?
    
    /// 更新用户密码
    func updatePassword(_ userId: String, newPassword: String) async throws
    
    /// 更新用户偏好设置
    func updatePreferences(_ userId: String, preferences: UserPreferences) async throws
    
    /// 更新用户头像
    func updateAvatar(_ userId: String, avatarData: Data) async throws
    
    /// 获取当前登录用户
    func getCurrentUser() async throws -> PersistedUser?
    
    /// 设置当前登录用户
    func setCurrentUser(_ user: PersistedUser) async throws
    
    /// 清除当前登录用户
    func clearCurrentUser() async throws
    
    /// 检查用户名是否可用
    func isUsernameAvailable(_ username: String) async throws -> Bool
    
    /// 检查邮箱是否可用
    func isEmailAvailable(_ email: String) async throws -> Bool
    
    /// 获取用户统计信息
    func getUserStatistics() async throws -> UserStatistics
}

// MARK: - User Repository Implementation

/// 用户仓库实现
class UserRepository: UserRepositoryProtocol {
    typealias Entity = PersistedUser
    typealias ID = String
    
    // MARK: - Properties
    
    private let coreDataStack: CoreDataStack
    private let secureStorage: SecureStorage
    private let cache: NSCache<NSString, CacheWrapper<PersistedUser>>
    private let syncQueue: DispatchQueue
    private let subject = PassthroughSubject<[PersistedUser], Never>()
    private let eventSubject = PassthroughSubject<RepositoryEvent<PersistedUser>, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    private let configuration: RepositoryConfiguration
    private var statistics = UserRepositoryStatistics()
    private let currentUserKey = "current_user_id"
    
    // MARK: - Initialization
    
    init(
        coreDataStack: CoreDataStack,
        secureStorage: SecureStorage,
        configuration: RepositoryConfiguration = .default
    ) {
        self.coreDataStack = coreDataStack
        self.secureStorage = secureStorage
        self.configuration = configuration
        self.cache = NSCache<NSString, CacheWrapper<PersistedUser>>()
        self.syncQueue = DispatchQueue(label: "com.iotclient.user-repository", qos: .utility)
        
        setupCache()
        setupNotifications()
    }
    
    // MARK: - Repository Protocol
    
    func findById(_ id: String) async throws -> PersistedUser? {
        statistics.incrementReadCount()
        
        // 检查缓存
        if configuration.cacheEnabled,
           let cached = await getCached(forKey: id) {
            statistics.incrementCacheHit()
            return cached
        }
        
        statistics.incrementCacheMiss()
        
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        do {
            let entities = try await context.perform {
                try context.fetch(request)
            }
            
            guard let entity = entities.first else {
                return nil
            }
            
            let user = try entity.toPersistedUser()
            
            // 缓存结果
            if configuration.cacheEnabled {
                await cache(user, forKey: id)
            }
            
            return user
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func findAll() async throws -> [PersistedUser] {
        statistics.incrementReadCount()
        
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "username", ascending: true)]
        
        do {
            let entities = try await context.perform {
                try context.fetch(request)
            }
            
            let users = try entities.map { try $0.toPersistedUser() }
            return users
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func findBy(predicate: NSPredicate) async throws -> [PersistedUser] {
        statistics.incrementReadCount()
        
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "username", ascending: true)]
        
        do {
            let entities = try await context.perform {
                try context.fetch(request)
            }
            
            let users = try entities.map { try $0.toPersistedUser() }
            return users
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func save(_ entity: PersistedUser) async throws -> PersistedUser {
        statistics.incrementWriteCount()
        
        let context = coreDataStack.newBackgroundContext()
        
        do {
            let savedUser = try await context.perform {
                let userEntity = UserEntity(context: context)
                try userEntity.update(from: entity)
                
                try context.save()
                return try userEntity.toPersistedUser()
            }
            
            // 保存敏感信息到安全存储
            if let passwordHash = entity.passwordHash {
                try await secureStorage.store(
                    passwordHash,
                    forKey: "user_password_\(entity.id)",
                    accessibility: .whenUnlockedThisDeviceOnly
                )
            }
            
            // 更新缓存
            if configuration.cacheEnabled {
                await cache(savedUser, forKey: savedUser.id)
            }
            
            // 发送事件
            eventSubject.send(.inserted(savedUser))
            
            return savedUser
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func saveAll(_ entities: [PersistedUser]) async throws -> [PersistedUser] {
        statistics.incrementWriteCount(entities.count)
        
        let context = coreDataStack.newBackgroundContext()
        
        do {
            let savedUsers = try await context.perform {
                var results: [PersistedUser] = []
                
                for entity in entities {
                    let userEntity = UserEntity(context: context)
                    try userEntity.update(from: entity)
                    results.append(try userEntity.toPersistedUser())
                }
                
                try context.save()
                return results
            }
            
            // 批量保存敏感信息
            for (index, user) in entities.enumerated() {
                if let passwordHash = user.passwordHash {
                    try await secureStorage.store(
                        passwordHash,
                        forKey: "user_password_\(user.id)",
                        accessibility: .whenUnlockedThisDeviceOnly
                    )
                }
            }
            
            // 批量更新缓存
            if configuration.cacheEnabled {
                for user in savedUsers {
                    await cache(user, forKey: user.id)
                }
            }
            
            // 发送事件
            for user in savedUsers {
                eventSubject.send(.inserted(user))
            }
            
            return savedUsers
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func update(_ entity: PersistedUser) async throws -> PersistedUser {
        statistics.incrementWriteCount()
        
        let context = coreDataStack.newBackgroundContext()
        
        do {
            let updatedUser = try await context.perform {
                let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", entity.id)
                request.fetchLimit = 1
                
                guard let userEntity = try context.fetch(request).first else {
                    throw RepositoryError.entityNotFound
                }
                
                var updatedEntity = entity
                updatedEntity.incrementVersion()
                
                try userEntity.update(from: updatedEntity)
                try context.save()
                
                return try userEntity.toPersistedUser()
            }
            
            // 更新敏感信息
            if let passwordHash = entity.passwordHash {
                try await secureStorage.store(
                    passwordHash,
                    forKey: "user_password_\(entity.id)",
                    accessibility: .whenUnlockedThisDeviceOnly
                )
            }
            
            // 更新缓存
            if configuration.cacheEnabled {
                await cache(updatedUser, forKey: updatedUser.id)
            }
            
            // 发送事件
            eventSubject.send(.updated(updatedUser))
            
            return updatedUser
        } catch {
            statistics.incrementErrorCount()
            if error is RepositoryError {
                throw error
            }
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func delete(_ entity: PersistedUser) async throws {
        try await deleteById(entity.id)
    }
    
    func deleteById(_ id: String) async throws {
        statistics.incrementWriteCount()
        
        let context = coreDataStack.newBackgroundContext()
        
        do {
            let deletedUser = try await context.perform {
                let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", id)
                request.fetchLimit = 1
                
                guard let userEntity = try context.fetch(request).first else {
                    throw RepositoryError.entityNotFound
                }
                
                let user = try userEntity.toPersistedUser()
                context.delete(userEntity)
                try context.save()
                
                return user
            }
            
            // 删除敏感信息
            try await secureStorage.delete(forKey: "user_password_\(id)")
            
            // 清除缓存
            if configuration.cacheEnabled {
                await clearCache(forKey: id)
            }
            
            // 发送事件
            eventSubject.send(.deleted(deletedUser))
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
            // 获取所有用户ID以清理敏感信息
            let userIds = try await context.perform {
                let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
                request.propertiesToFetch = ["id"]
                let entities = try context.fetch(request)
                return entities.compactMap { $0.id }
            }
            
            try await context.perform {
                let request: NSFetchRequest<NSFetchRequestResult> = UserEntity.fetchRequest()
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                try context.execute(deleteRequest)
                try context.save()
            }
            
            // 清理所有用户的敏感信息
            for userId in userIds {
                try? await secureStorage.delete(forKey: "user_password_\(userId)")
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
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
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
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        
        do {
            return try await context.perform {
                try context.count(for: request)
            }
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func publisher() -> AnyPublisher<[PersistedUser], Never> {
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - User-Specific Methods
    
    func findByUsername(_ username: String) async throws -> PersistedUser? {
        let predicate = NSPredicate(format: "username == %@", username)
        let users = try await findBy(predicate: predicate)
        return users.first
    }
    
    func findByEmail(_ email: String) async throws -> PersistedUser? {
        let predicate = NSPredicate(format: "email == %@", email)
        let users = try await findBy(predicate: predicate)
        return users.first
    }
    
    func findByPhoneNumber(_ phoneNumber: String) async throws -> PersistedUser? {
        let predicate = NSPredicate(format: "phoneNumber == %@", phoneNumber)
        let users = try await findBy(predicate: predicate)
        return users.first
    }
    
    func validateCredentials(username: String, password: String) async throws -> PersistedUser? {
        guard let user = try await findByUsername(username) else {
            return nil
        }
        
        // 从安全存储获取密码哈希
        guard let storedPasswordHash = try await secureStorage.retrieve(forKey: "user_password_\(user.id)") as? String else {
            throw RepositoryError.securityError("Password hash not found")
        }
        
        // 验证密码（这里应该使用适当的密码哈希验证）
        let passwordHash = hashPassword(password)
        
        if passwordHash == storedPasswordHash {
            return user
        } else {
            return nil
        }
    }
    
    func updatePassword(_ userId: String, newPassword: String) async throws {
        guard var user = try await findById(userId) else {
            throw RepositoryError.entityNotFound
        }
        
        let newPasswordHash = hashPassword(newPassword)
        user.passwordHash = newPasswordHash
        
        // 更新数据库
        _ = try await update(user)
        
        // 更新安全存储
        try await secureStorage.store(
            newPasswordHash,
            forKey: "user_password_\(userId)",
            accessibility: .whenUnlockedThisDeviceOnly
        )
    }
    
    func updatePreferences(_ userId: String, preferences: UserPreferences) async throws {
        guard var user = try await findById(userId) else {
            throw RepositoryError.entityNotFound
        }
        
        user.preferences = preferences
        _ = try await update(user)
    }
    
    func updateAvatar(_ userId: String, avatarData: Data) async throws {
        guard var user = try await findById(userId) else {
            throw RepositoryError.entityNotFound
        }
        
        // 保存头像数据到安全存储
        try await secureStorage.store(
            avatarData,
            forKey: "user_avatar_\(userId)",
            accessibility: .whenUnlockedThisDeviceOnly
        )
        
        user.hasAvatar = true
        _ = try await update(user)
    }
    
    func getCurrentUser() async throws -> PersistedUser? {
        guard let currentUserId = try await secureStorage.retrieve(forKey: currentUserKey) as? String else {
            return nil
        }
        
        return try await findById(currentUserId)
    }
    
    func setCurrentUser(_ user: PersistedUser) async throws {
        try await secureStorage.store(
            user.id,
            forKey: currentUserKey,
            accessibility: .whenUnlockedThisDeviceOnly
        )
    }
    
    func clearCurrentUser() async throws {
        try await secureStorage.delete(forKey: currentUserKey)
    }
    
    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let user = try await findByUsername(username)
        return user == nil
    }
    
    func isEmailAvailable(_ email: String) async throws -> Bool {
        let user = try await findByEmail(email)
        return user == nil
    }
    
    func getUserStatistics() async throws -> UserStatistics {
        let context = coreDataStack.viewContext
        
        do {
            return try await context.perform {
                let totalRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
                let totalCount = try context.count(for: totalRequest)
                
                let activeRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
                activeRequest.predicate = NSPredicate(format: "isActive == YES")
                let activeCount = try context.count(for: activeRequest)
                
                let recentRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
                let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                recentRequest.predicate = NSPredicate(format: "lastLoginAt >= %@", thirtyDaysAgo as NSDate)
                let recentActiveCount = try context.count(for: recentRequest)
                
                return UserStatistics(
                    totalUsers: totalCount,
                    activeUsers: activeCount,
                    inactiveUsers: totalCount - activeCount,
                    recentActiveUsers: recentActiveCount,
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
        cache.name = "UserRepository.Cache"
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
            let users = try await findAll()
            subject.send(users)
        } catch {
            print("Failed to refresh user publisher: \(error)")
        }
    }
    
    private func hashPassword(_ password: String) -> String {
        // 这里应该使用适当的密码哈希算法，如bcrypt、scrypt或Argon2
        // 为了演示，这里使用简单的SHA256
        return password.sha256
    }
}

// MARK: - Cacheable Implementation

extension UserRepository {
    func cache(_ entity: PersistedUser, forKey key: String) async {
        let wrapper = CacheWrapper(entity)
        cache.setObject(wrapper, forKey: key as NSString)
    }
    
    func getCached(forKey key: String) async -> PersistedUser? {
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

extension UserRepository {
    func syncToRemote() async throws {
        // TODO: 实现远程同步逻辑
    }
    
    func syncFromRemote() async throws {
        // TODO: 实现从远程同步逻辑
    }
    
    func getPendingSyncEntities() async throws -> [PersistedUser] {
        let predicate = NSPredicate(format: "syncStatus == %@", SyncStatus.pending.rawValue)
        return try await findBy(predicate: predicate)
    }
    
    func markAsSynced(_ entity: PersistedUser) async throws {
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

extension UserRepository {
    func observe() -> AnyPublisher<RepositoryEvent<PersistedUser>, Never> {
        return eventSubject.eraseToAnyPublisher()
    }
    
    func observe(_ id: String) -> AnyPublisher<PersistedUser?, Never> {
        return eventSubject
            .compactMap { event in
                switch event {
                case .inserted(let user), .updated(let user):
                    return user.id == id ? user : nil
                case .deleted(let user):
                    return user.id == id ? nil : nil
                case .cleared:
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }
    
    func observe(predicate: NSPredicate) -> AnyPublisher<[PersistedUser], Never> {
        return subject
            .map { users in
                users.filter { user in
                    predicate.evaluate(with: user)
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Queryable Implementation

extension UserRepository {
    func findWithPagination(
        offset: Int,
        limit: Int,
        sortBy: String? = nil,
        ascending: Bool = true
    ) async throws -> PaginatedResult<PersistedUser> {
        statistics.incrementReadCount()
        
        let context = coreDataStack.viewContext
        
        // 获取总数
        let countRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        let totalCount = try await context.perform {
            try context.count(for: countRequest)
        }
        
        // 获取分页数据
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.fetchOffset = offset
        request.fetchLimit = limit
        
        if let sortBy = sortBy {
            request.sortDescriptors = [NSSortDescriptor(key: sortBy, ascending: ascending)]
        } else {
            request.sortDescriptors = [NSSortDescriptor(key: "username", ascending: true)]
        }
        
        do {
            let entities = try await context.perform {
                try context.fetch(request)
            }
            
            let users = try entities.map { try $0.toPersistedUser() }
            
            return PaginatedResult(
                items: users,
                totalCount: totalCount,
                offset: offset,
                limit: limit
            )
        } catch {
            statistics.incrementErrorCount()
            throw RepositoryError.persistenceError(error)
        }
    }
    
    func search(query: String, fields: [String]) async throws -> [PersistedUser] {
        statistics.incrementReadCount()
        
        let predicates = fields.map { field in
            NSPredicate(format: "%K CONTAINS[cd] %@", field, query)
        }
        
        let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        return try await findBy(predicate: compoundPredicate)
    }
    
    func findBy(criteria: [QueryCriteria]) async throws -> [PersistedUser] {
        statistics.incrementReadCount()
        
        let predicates = criteria.map { criterion in
            NSPredicate(format: criterion.operation.predicateFormat, criterion.field, criterion.value)
        }
        
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return try await findBy(predicate: compoundPredicate)
    }
}

// MARK: - Supporting Types

/// 用户统计信息
struct UserStatistics {
    let totalUsers: Int
    let activeUsers: Int
    let inactiveUsers: Int
    let recentActiveUsers: Int
    let lastUpdated: Date
    
    var activePercentage: Double {
        return totalUsers > 0 ? Double(activeUsers) / Double(totalUsers) * 100 : 0
    }
    
    var recentActivePercentage: Double {
        return totalUsers > 0 ? Double(recentActiveUsers) / Double(totalUsers) * 100 : 0
    }
}

/// 用户仓库统计
struct UserRepositoryStatistics {
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

// MARK: - Core Data Extensions

/// Core Data用户实体扩展
extension UserEntity {
    func toPersistedUser() throws -> PersistedUser {
        guard let id = self.id,
              let username = self.username,
              let email = self.email,
              let createdAt = self.createdAt,
              let updatedAt = self.updatedAt else {
            throw RepositoryError.invalidEntity
        }
        
        return PersistedUser(
            id: id,
            username: username,
            email: email,
            firstName: self.firstName,
            lastName: self.lastName,
            phoneNumber: self.phoneNumber,
            isActive: self.isActive,
            lastLoginAt: self.lastLoginAt,
            preferences: UserPreferences(), // TODO: 从存储的JSON解析
            hasAvatar: self.hasAvatar,
            createdAt: createdAt,
            updatedAt: updatedAt,
            version: Int(self.version),
            syncStatus: SyncStatus(rawValue: self.syncStatus ?? "") ?? .idle,
            lastSyncAt: self.lastSyncAt,
            remoteId: self.remoteId
        )
    }
    
    func update(from user: PersistedUser) throws {
        self.id = user.id
        self.username = user.username
        self.email = user.email
        self.firstName = user.firstName
        self.lastName = user.lastName
        self.phoneNumber = user.phoneNumber
        self.isActive = user.isActive
        self.lastLoginAt = user.lastLoginAt
        self.hasAvatar = user.hasAvatar
        self.createdAt = user.createdAt
        self.updatedAt = user.updatedAt
        self.version = Int32(user.version)
        self.syncStatus = user.syncStatus.rawValue
        self.lastSyncAt = user.lastSyncAt
        self.remoteId = user.remoteId
        
        // TODO: 序列化preferences为JSON
    }
}

/// 模拟用户实体（用于测试）
class UserEntity: NSManagedObject {
    @NSManaged var id: String?
    @NSManaged var username: String?
    @NSManaged var email: String?
    @NSManaged var firstName: String?
    @NSManaged var lastName: String?
    @NSManaged var phoneNumber: String?
    @NSManaged var isActive: Bool
    @NSManaged var lastLoginAt: Date?
    @NSManaged var hasAvatar: Bool
    @NSManaged var createdAt: Date?
    @NSManaged var updatedAt: Date?
    @NSManaged var version: Int32
    @NSManaged var syncStatus: String?
    @NSManaged var lastSyncAt: Date?
    @NSManaged var remoteId: String?
    
    static func fetchRequest() -> NSFetchRequest<UserEntity> {
        return NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }
}

// MARK: - String Extensions

extension String {
    var sha256: String {
        // 简化的SHA256实现，实际应用中应使用CryptoKit
        return "hashed_\(self)"
    }
}