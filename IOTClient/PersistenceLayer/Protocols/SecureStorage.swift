//
//  SecureStorage.swift
//  PersistenceLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Security

// MARK: - Secure Storage Protocol

/// 安全存储协议
/// 定义了敏感数据的安全存储接口
protocol SecureStorage {
    /// 存储数据
    func store<T: Codable>(_ value: T, forKey key: String) throws
    
    /// 获取数据
    func retrieve<T: Codable>(_ type: T.Type, forKey key: String) throws -> T?
    
    /// 删除数据
    func delete(forKey key: String) throws
    
    /// 检查键是否存在
    func exists(forKey key: String) -> Bool
    
    /// 获取所有键
    func getAllKeys() throws -> [String]
    
    /// 清除所有数据
    func clearAll() throws
}

// MARK: - Keychain Storage Protocol

/// Keychain存储协议
/// 专门用于iOS Keychain的安全存储
protocol KeychainStorage: SecureStorage {
    /// Keychain服务标识符
    var service: String { get }
    
    /// 访问组（用于应用间共享）
    var accessGroup: String? { get }
    
    /// 访问控制级别
    var accessibility: KeychainAccessibility { get }
    
    /// 存储字符串
    func storeString(_ value: String, forKey key: String) throws
    
    /// 获取字符串
    func retrieveString(forKey key: String) throws -> String?
    
    /// 存储数据
    func storeData(_ data: Data, forKey key: String) throws
    
    /// 获取数据
    func retrieveData(forKey key: String) throws -> Data?
    
    /// 更新数据
    func updateData(_ data: Data, forKey key: String) throws
    
    /// 获取Keychain项目属性
    func getItemAttributes(forKey key: String) throws -> [String: Any]?
}

// MARK: - Encrypted Storage Protocol

/// 加密存储协议
/// 提供数据加密存储功能
protocol EncryptedStorage: SecureStorage {
    /// 加密算法
    var encryptionAlgorithm: EncryptionAlgorithm { get }
    
    /// 密钥派生函数
    var keyDerivationFunction: KeyDerivationFunction { get }
    
    /// 设置主密码
    func setMasterPassword(_ password: String) throws
    
    /// 验证主密码
    func verifyMasterPassword(_ password: String) throws -> Bool
    
    /// 更改主密码
    func changeMasterPassword(from oldPassword: String, to newPassword: String) throws
    
    /// 加密数据
    func encrypt(_ data: Data, withKey key: Data) throws -> Data
    
    /// 解密数据
    func decrypt(_ encryptedData: Data, withKey key: Data) throws -> Data
    
    /// 生成随机密钥
    func generateRandomKey(length: Int) throws -> Data
    
    /// 派生密钥
    func deriveKey(from password: String, salt: Data, iterations: Int) throws -> Data
}

// MARK: - Biometric Storage Protocol

/// 生物识别存储协议
/// 支持Touch ID/Face ID保护的存储
protocol BiometricStorage: SecureStorage {
    /// 生物识别可用性
    var biometricAvailability: BiometricAvailability { get }
    
    /// 存储受生物识别保护的数据
    func storeBiometricProtected<T: Codable>(
        _ value: T,
        forKey key: String,
        prompt: String
    ) throws
    
    /// 获取受生物识别保护的数据
    func retrieveBiometricProtected<T: Codable>(
        _ type: T.Type,
        forKey key: String,
        prompt: String
    ) throws -> T?
    
    /// 检查生物识别是否可用
    func isBiometricAvailable() -> Bool
    
    /// 获取生物识别类型
    func getBiometricType() -> BiometricType
}

// MARK: - Credential Storage Protocol

/// 凭证存储协议
/// 专门用于存储各种凭证信息
protocol CredentialStorage: SecureStorage {
    /// 存储用户凭证
    func storeUserCredential(_ credential: UserCredential) throws
    
    /// 获取用户凭证
    func retrieveUserCredential(forUsername username: String) throws -> UserCredential?
    
    /// 存储WiFi凭证
    func storeWiFiCredential(_ credential: WiFiCredential) throws
    
    /// 获取WiFi凭证
    func retrieveWiFiCredential(forSSID ssid: String) throws -> WiFiCredential?
    
    /// 存储设备凭证
    func storeDeviceCredential(_ credential: DeviceCredential) throws
    
    /// 获取设备凭证
    func retrieveDeviceCredential(forDeviceId deviceId: String) throws -> DeviceCredential?
    
    /// 存储API密钥
    func storeAPIKey(_ apiKey: APIKey) throws
    
    /// 获取API密钥
    func retrieveAPIKey(forService service: String) throws -> APIKey?
    
    /// 存储证书
    func storeCertificate(_ certificate: Certificate) throws
    
    /// 获取证书
    func retrieveCertificate(forIdentifier identifier: String) throws -> Certificate?
}

// MARK: - Supporting Types

/// Keychain访问级别
enum KeychainAccessibility {
    case whenUnlocked
    case afterFirstUnlock
    case whenUnlockedThisDeviceOnly
    case afterFirstUnlockThisDeviceOnly
    case whenPasscodeSetThisDeviceOnly
    
    var cfValue: CFString {
        switch self {
        case .whenUnlocked:
            return kSecAttrAccessibleWhenUnlocked
        case .afterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock
        case .whenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .whenPasscodeSetThisDeviceOnly:
            return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        }
    }
}

/// 加密算法
enum EncryptionAlgorithm {
    case aes256GCM
    case aes256CBC
    case chacha20Poly1305
    
    var keySize: Int {
        switch self {
        case .aes256GCM, .aes256CBC:
            return 32 // 256 bits
        case .chacha20Poly1305:
            return 32 // 256 bits
        }
    }
    
    var ivSize: Int {
        switch self {
        case .aes256GCM:
            return 12 // 96 bits
        case .aes256CBC:
            return 16 // 128 bits
        case .chacha20Poly1305:
            return 12 // 96 bits
        }
    }
}

/// 密钥派生函数
enum KeyDerivationFunction {
    case pbkdf2
    case scrypt
    case argon2
    
    var defaultIterations: Int {
        switch self {
        case .pbkdf2:
            return 100000
        case .scrypt:
            return 16384
        case .argon2:
            return 3
        }
    }
}

/// 生物识别可用性
enum BiometricAvailability {
    case available
    case notAvailable
    case notEnrolled
    case lockout
    case permanentLockout
}

/// 生物识别类型
enum BiometricType {
    case none
    case touchID
    case faceID
    case opticID
}

/// 用户凭证
struct UserCredential: Codable {
    let username: String
    let password: String
    let email: String?
    let createdAt: Date
    let lastUsed: Date?
    let expiresAt: Date?
    
    init(username: String, password: String, email: String? = nil) {
        self.username = username
        self.password = password
        self.email = email
        self.createdAt = Date()
        self.lastUsed = nil
        self.expiresAt = nil
    }
}

/// WiFi凭证
struct WiFiCredential: Codable {
    let ssid: String
    let password: String
    let security: WiFiSecurity
    let hidden: Bool
    let priority: Int
    let createdAt: Date
    let lastUsed: Date?
    
    init(ssid: String, password: String, security: WiFiSecurity = .wpa2, hidden: Bool = false, priority: Int = 0) {
        self.ssid = ssid
        self.password = password
        self.security = security
        self.hidden = hidden
        self.priority = priority
        self.createdAt = Date()
        self.lastUsed = nil
    }
}

/// WiFi安全类型
enum WiFiSecurity: String, Codable, CaseIterable {
    case open = "OPEN"
    case wep = "WEP"
    case wpa = "WPA"
    case wpa2 = "WPA2"
    case wpa3 = "WPA3"
    case wpaEnterprise = "WPA_ENTERPRISE"
    case wpa2Enterprise = "WPA2_ENTERPRISE"
    case wpa3Enterprise = "WPA3_ENTERPRISE"
}

/// 设备凭证
struct DeviceCredential: Codable {
    let deviceId: String
    let deviceName: String
    let authToken: String
    let refreshToken: String?
    let certificateData: Data?
    let privateKeyData: Data?
    let createdAt: Date
    let expiresAt: Date?
    
    init(deviceId: String, deviceName: String, authToken: String, refreshToken: String? = nil) {
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.authToken = authToken
        self.refreshToken = refreshToken
        self.certificateData = nil
        self.privateKeyData = nil
        self.createdAt = Date()
        self.expiresAt = nil
    }
}

/// API密钥
struct APIKey: Codable {
    let service: String
    let key: String
    let secret: String?
    let scope: [String]
    let createdAt: Date
    let expiresAt: Date?
    let rateLimit: Int?
    
    init(service: String, key: String, secret: String? = nil, scope: [String] = []) {
        self.service = service
        self.key = key
        self.secret = secret
        self.scope = scope
        self.createdAt = Date()
        self.expiresAt = nil
        self.rateLimit = nil
    }
}

/// 证书
struct Certificate: Codable {
    let identifier: String
    let commonName: String
    let certificateData: Data
    let privateKeyData: Data?
    let issuer: String
    let serialNumber: String
    let validFrom: Date
    let validTo: Date
    let fingerprint: String
    
    var isValid: Bool {
        let now = Date()
        return now >= validFrom && now <= validTo
    }
    
    var isExpiringSoon: Bool {
        let thirtyDaysFromNow = Date().addingTimeInterval(30 * 24 * 60 * 60)
        return validTo <= thirtyDaysFromNow
    }
}

// MARK: - Secure Storage Error

/// 安全存储错误
enum SecureStorageError: Error, LocalizedError {
    case itemNotFound
    case duplicateItem
    case invalidData
    case encryptionFailed
    case decryptionFailed
    case keyGenerationFailed
    case biometricNotAvailable
    case biometricAuthenticationFailed
    case keychainError(OSStatus)
    case passwordRequired
    case invalidPassword
    case accessDenied
    case quotaExceeded
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Item not found in secure storage"
        case .duplicateItem:
            return "Item already exists in secure storage"
        case .invalidData:
            return "Invalid data format"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .keyGenerationFailed:
            return "Failed to generate encryption key"
        case .biometricNotAvailable:
            return "Biometric authentication not available"
        case .biometricAuthenticationFailed:
            return "Biometric authentication failed"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .passwordRequired:
            return "Password required"
        case .invalidPassword:
            return "Invalid password"
        case .accessDenied:
            return "Access denied"
        case .quotaExceeded:
            return "Storage quota exceeded"
        case .custom(let message):
            return message
        }
    }
}