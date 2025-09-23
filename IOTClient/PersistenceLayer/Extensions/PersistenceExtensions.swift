//
//  PersistenceExtensions.swift
//  PersistenceLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import CoreData
import Combine

// MARK: - NSManagedObject Extensions

extension NSManagedObject {
    
    /// 获取实体名称
    static var entityName: String {
        return String(describing: self)
    }
    
    /// 创建获取请求
    static func fetchRequest<T: NSManagedObject>() -> NSFetchRequest<T> {
        return NSFetchRequest<T>(entityName: entityName)
    }
    
    /// 从字典创建或更新对象
    func update(from dictionary: [String: Any]) {
        for (key, value) in dictionary {
            if responds(to: NSSelectorFromString(key)) {
                setValue(value, forKey: key)
            }
        }
    }
    
    /// 转换为字典
    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        
        for attribute in entity.attributesByName {
            let key = attribute.key
            let value = self.value(forKey: key)
            dictionary[key] = value
        }
        
        return dictionary
    }
    
    /// 深拷贝对象
    func deepCopy(in context: NSManagedObjectContext) -> Self? {
        guard let entityName = entity.name else { return nil }
        
        let copy = NSEntityDescription.insertNewObject(
            forEntityName: entityName,
            into: context
        ) as? Self
        
        copy?.update(from: toDictionary())
        return copy
    }
}

// MARK: - NSFetchRequest Extensions

extension NSFetchRequest {
    
    /// 添加谓词
    @discardableResult
    func with(predicate: NSPredicate) -> Self {
        self.predicate = predicate
        return self
    }
    
    /// 添加排序描述符
    @discardableResult
    func sorted(by sortDescriptors: [NSSortDescriptor]) -> Self {
        self.sortDescriptors = sortDescriptors
        return self
    }
    
    /// 设置获取限制
    @discardableResult
    func limited(to limit: Int) -> Self {
        self.fetchLimit = limit
        return self
    }
    
    /// 设置获取偏移
    @discardableResult
    func offset(by offset: Int) -> Self {
        self.fetchOffset = offset
        return self
    }
    
    /// 设置批量大小
    @discardableResult
    func batched(size: Int) -> Self {
        self.fetchBatchSize = size
        return self
    }
    
    /// 设置结果类型
    @discardableResult
    func resultType(_ type: NSFetchRequestResultType) -> Self {
        self.resultType = type
        return self
    }
}

// MARK: - NSPredicate Extensions

extension NSPredicate {
    
    /// 组合谓词（AND）
    func and(_ predicate: NSPredicate) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [self, predicate])
    }
    
    /// 组合谓词（OR）
    func or(_ predicate: NSPredicate) -> NSPredicate {
        return NSCompoundPredicate(orPredicateWithSubpredicates: [self, predicate])
    }
    
    /// 取反谓词
    func not() -> NSPredicate {
        return NSCompoundPredicate(notPredicateWithSubpredicate: self)
    }
    
    /// 创建相等谓词
    static func equal<T>(_ keyPath: KeyPath<NSManagedObject, T>, to value: T) -> NSPredicate {
        let key = NSExpression(forKeyPath: keyPath).keyPath
        return NSPredicate(format: "%K == %@", key, value as! CVarArg)
    }
    
    /// 创建包含谓词
    static func contains(_ keyPath: String, value: String, caseInsensitive: Bool = true) -> NSPredicate {
        let format = caseInsensitive ? "%K CONTAINS[cd] %@" : "%K CONTAINS %@"
        return NSPredicate(format: format, keyPath, value)
    }
    
    /// 创建范围谓词
    static func between<T: Comparable>(_ keyPath: String, min: T, max: T) -> NSPredicate {
        return NSPredicate(format: "%K BETWEEN {%@, %@}", keyPath, min as! CVarArg, max as! CVarArg)
    }
    
    /// 创建IN谓词
    static func `in`<T>(_ keyPath: String, values: [T]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", keyPath, values)
    }
}

// MARK: - NSSortDescriptor Extensions

extension NSSortDescriptor {
    
    /// 创建升序排序描述符
    static func ascending(_ key: String) -> NSSortDescriptor {
        return NSSortDescriptor(key: key, ascending: true)
    }
    
    /// 创建降序排序描述符
    static func descending(_ key: String) -> NSSortDescriptor {
        return NSSortDescriptor(key: key, ascending: false)
    }
    
    /// 创建本地化排序描述符
    static func localizedAscending(_ key: String) -> NSSortDescriptor {
        return NSSortDescriptor(
            key: key,
            ascending: true,
            selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
        )
    }
    
    /// 创建本地化降序排序描述符
    static func localizedDescending(_ key: String) -> NSSortDescriptor {
        return NSSortDescriptor(
            key: key,
            ascending: false,
            selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
        )
    }
}

// MARK: - Publisher Extensions

extension Publisher {
    
    /// 在主队列上接收
    func receiveOnMain() -> Publishers.ReceiveOn<Self, DispatchQueue> {
        return receive(on: DispatchQueue.main)
    }
    
    /// 错误处理
    func handleRepositoryError() -> Publishers.Catch<Self, Just<Self.Output>> where Self.Failure == RepositoryError {
        return self.catch { error in
            print("Repository error: \(error)")
            // 这里可以添加错误日志记录
            return Just(Self.Output.self as! Self.Output)
        }
    }
}

// MARK: - Date Extensions

extension Date {
    
    /// 获取今天的开始时间
    static var startOfToday: Date {
        return Calendar.current.startOfDay(for: Date())
    }
    
    /// 获取今天的结束时间
    static var endOfToday: Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
    }
    
    /// 获取本周的开始时间
    static var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return calendar.date(from: components)!
    }
    
    /// 获取本月的开始时间
    static var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: components)!
    }
    
    /// 是否是今天
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// 是否是昨天
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    /// 是否是本周
    var isThisWeek: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    /// 是否是本月
    var isThisMonth: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    /// 格式化为相对时间字符串
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - String Extensions

extension String {
    
    /// 是否为有效的邮箱地址
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// 是否为有效的密码（至少8位，包含字母和数字）
    var isValidPassword: Bool {
        let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d@$!%*?&]{8,}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPredicate.evaluate(with: self)
    }
    
    /// 是否为有效的MAC地址
    var isValidMACAddress: Bool {
        let macRegex = "^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$"
        let macPredicate = NSPredicate(format: "SELF MATCHES %@", macRegex)
        return macPredicate.evaluate(with: self)
    }
    
    /// 是否为有效的IP地址
    var isValidIPAddress: Bool {
        let ipRegex = "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
        let ipPredicate = NSPredicate(format: "SELF MATCHES %@", ipRegex)
        return ipPredicate.evaluate(with: self)
    }
    
    /// 生成UUID字符串
    static func generateUUID() -> String {
        return UUID().uuidString
    }
    
    /// 安全的子字符串
    func safeSubstring(from index: Int, length: Int) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: max(0, index))
        let endIndex = self.index(startIndex, offsetBy: min(length, self.count - index))
        return String(self[startIndex..<endIndex])
    }
}

// MARK: - Array Extensions

extension Array {
    
    /// 安全的下标访问
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    /// 分块
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
    
    /// 去重（需要元素遵循Hashable）
    func unique<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}

extension Array where Element: Hashable {
    
    /// 去重
    func unique() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

// MARK: - Dictionary Extensions

extension Dictionary {
    
    /// 合并字典
    mutating func merge(_ other: [Key: Value]) {
        for (key, value) in other {
            self[key] = value
        }
    }
    
    /// 返回合并后的新字典
    func merged(with other: [Key: Value]) -> [Key: Value] {
        var result = self
        result.merge(other)
        return result
    }
    
    /// 安全获取值
    func value<T>(for key: Key, as type: T.Type) -> T? {
        return self[key] as? T
    }
}

// MARK: - Result Extensions

extension Result {
    
    /// 获取成功值
    var value: Success? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    /// 获取错误
    var error: Failure? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
    
    /// 是否成功
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    /// 是否失败
    var isFailure: Bool {
        return !isSuccess
    }
}

// MARK: - Optional Extensions

extension Optional {
    
    /// 如果为nil则抛出错误
    func orThrow(_ error: Error) throws -> Wrapped {
        guard let value = self else {
            throw error
        }
        return value
    }
    
    /// 如果为nil则使用默认值并执行闭包
    func ifNil(_ closure: () -> Void) -> Wrapped? {
        if self == nil {
            closure()
        }
        return self
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    
    // MARK: - Repository Notifications
    
    static let deviceRepositoryDidChange = Notification.Name("DeviceRepositoryDidChange")
    static let userRepositoryDidChange = Notification.Name("UserRepositoryDidChange")
    static let settingsRepositoryDidChange = Notification.Name("SettingsRepositoryDidChange")
    
    // MARK: - Sync Notifications
    
    static let syncDidStart = Notification.Name("SyncDidStart")
    static let syncDidComplete = Notification.Name("SyncDidComplete")
    static let syncDidFail = Notification.Name("SyncDidFail")
    
    // MARK: - Cache Notifications
    
    static let cacheDidClear = Notification.Name("CacheDidClear")
    static let cacheDidUpdate = Notification.Name("CacheDidUpdate")
    
    // MARK: - Security Notifications
    
    static let secureStorageDidChange = Notification.Name("SecureStorageDidChange")
    static let biometricAuthenticationDidChange = Notification.Name("BiometricAuthenticationDidChange")
}

// MARK: - UserDefaults Extensions

extension UserDefaults {
    
    /// 设置Codable对象
    func set<T: Codable>(_ object: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(object) {
            set(data, forKey: key)
        }
    }
    
    /// 获取Codable对象
    func object<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }
    
    /// 移除对象
    func removeObject(forKey key: String) {
        removeObject(forKey: key)
    }
}

// MARK: - DispatchQueue Extensions

extension DispatchQueue {
    
    /// 安全的主队列执行
    static func safeMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
    
    /// 延迟执行
    static func delay(_ delay: TimeInterval, execute: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: execute)
    }
}

// MARK: - FileManager Extensions

extension FileManager {
    
    /// 获取文档目录
    static var documentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    /// 获取缓存目录
    static var cachesDirectory: URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    /// 获取临时目录
    static var temporaryDirectory: URL {
        return FileManager.default.temporaryDirectory
    }
    
    /// 创建目录（如果不存在）
    func createDirectoryIfNeeded(at url: URL) throws {
        if !fileExists(atPath: url.path) {
            try createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    /// 获取文件大小
    func fileSize(at url: URL) -> Int64? {
        guard let attributes = try? attributesOfItem(atPath: url.path) else { return nil }
        return attributes[.size] as? Int64
    }
    
    /// 获取目录大小
    func directorySize(at url: URL) -> Int64 {
        guard let enumerator = enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        
        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(fileSize)
            }
        }
        
        return totalSize
    }
}