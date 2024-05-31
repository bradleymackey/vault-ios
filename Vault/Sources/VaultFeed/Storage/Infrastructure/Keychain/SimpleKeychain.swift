// The MIT License (MIT)
//
// Copyright (c) 2022 Auth0, Inc. <support@auth0.com> (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import LocalAuthentication
import Security

typealias RetrieveFunction = (_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
typealias RemoveFunction = (_ query: CFDictionary) -> OSStatus

/// A simple Keychain wrapper for iOS, macOS, tvOS, and watchOS.
/// Supports sharing credentials with an **access group** or through **iCloud**, and integrating
/// **Touch ID / Face ID**.
public struct SimpleKeychain {
    let service: String
    let accessGroup: String?
    let accessibility: Accessibility
    let accessControlFlags: SecAccessControlCreateFlags?
    let isSynchronizable: Bool
    let attributes: [String: Any]

    var retrieve: RetrieveFunction = SecItemCopyMatching
    var remove: RemoveFunction = SecItemDelete

    #if canImport(LocalAuthentication) && !os(tvOS)
    let context: LAContext?

    /// Initializes a ``SimpleKeychain`` instance.
    ///
    /// - Parameter service: Name of the service under which to save items. Defaults to the bundle identifier.
    /// - Parameter accessGroup: access group for sharing Keychain items. Defaults to `nil`.
    /// - Parameter accessibility: ``Accessibility`` type the stored items will have. Defaults to
    /// ``Accessibility/afterFirstUnlock``.
    /// - Parameter accessControlFlags: Access control conditions for `kSecAttrAccessControl`.  Defaults to `nil`.
    /// - Parameter context: `LAContext` used to access Keychain items. Defaults to `nil`.
    /// - Parameter synchronizable: Whether the items should be synchronized through iCloud. Defaults to `false`.
    /// - Parameter attributes: Additional attributes to include in every query. Defaults to an empty dictionary.
    /// - Returns: A ``SimpleKeychain`` instance.
    public init(
        service: String = Bundle.main.bundleIdentifier!,
        accessGroup: String? = nil,
        accessibility: Accessibility = .afterFirstUnlock,
        accessControlFlags: SecAccessControlCreateFlags? = nil,
        context: LAContext? = nil,
        synchronizable: Bool = false,
        attributes: [String: Any] = [:]
    ) {
        self.service = service
        self.accessGroup = accessGroup
        self.accessibility = accessibility
        self.accessControlFlags = accessControlFlags
        self.context = context
        isSynchronizable = synchronizable
        self.attributes = attributes
    }
    #else
    /// Initializes a ``SimpleKeychain`` instance.
    ///
    /// - Parameter service: Name of the service under which to save items. Defaults to the bundle identifier.
    /// - Parameter accessGroup: access group for sharing Keychain items. Defaults to `nil`.
    /// - Parameter accessibility: ``Accessibility`` type the stored items will have. Defaults to
    /// ``Accessibility/afterFirstUnlock``.
    /// - Parameter accessControlFlags: Access control conditions for `kSecAttrAccessControl`.  Defaults to `nil`.
    /// - Parameter synchronizable: Whether the items should be synchronized through iCloud. Defaults to `false`.
    /// - Parameter attributes: Additional attributes to include in every query. Defaults to an empty dictionary.
    /// - Returns: A ``SimpleKeychain`` instance.
    public init(
        service: String = Bundle.main.bundleIdentifier!,
        accessGroup: String? = nil,
        accessibility: Accessibility = .afterFirstUnlock,
        accessControlFlags: SecAccessControlCreateFlags? = nil,
        synchronizable: Bool = false,
        attributes: [String: Any] = [:]
    ) {
        self.service = service
        self.accessGroup = accessGroup
        self.accessibility = accessibility
        self.accessControlFlags = accessControlFlags
        isSynchronizable = synchronizable
        self.attributes = attributes
    }
    #endif

    private func assertSuccess(forStatus status: OSStatus) throws {
        if status != errSecSuccess {
            throw SimpleKeychainError(code: SimpleKeychainError.Code(rawValue: status))
        }
    }
}

// MARK: - Retrieve items

extension SimpleKeychain {
    /// Retrieves a `String` value from the Keychain.
    ///
    /// ```swift
    /// let value = try simpleKeychain.string(forKey: "your_key")
    /// ```
    ///
    /// - Parameter key: Key of the Keychain item to retrieve.
    /// - Returns: The `String` value.
    /// - Throws: A ``SimpleKeychainError`` when the SimpleKeychain operation fails.
    public func string(forKey key: String) throws -> String {
        let data = try self.data(forKey: key)

        guard let result = String(data: data, encoding: .utf8) else {
            let message = "Unable to convert the retrieved item to a String value"
            throw SimpleKeychainError(code: SimpleKeychainError.Code.unknown(message: message))
        }

        return result
    }

    /// Retrieves a `Data` value from the Keychain.
    ///
    /// ```swift
    /// let value = try simpleKeychain.data(forKey: "your_key")
    /// ```
    ///
    /// - Parameter key: Key of the Keychain item to retrieve.
    /// - Returns: The `Data` value.
    /// - Throws: A ``SimpleKeychainError`` when the SimpleKeychain operation fails.
    public func data(forKey key: String) throws -> Data {
        let query = getOneQuery(byKey: key)
        var result: AnyObject?
        try assertSuccess(forStatus: retrieve(query as CFDictionary, &result))

        guard let data = result as? Data else {
            let message = "Unable to cast the retrieved item to a Data value"
            throw SimpleKeychainError(code: SimpleKeychainError.Code.unknown(message: message))
        }

        return data
    }
}

// MARK: - Store items

extension SimpleKeychain {
    /// Saves a `String` value with the type `kSecClassKey` in the Keychain.
    ///
    /// ```swift
    /// try simpleKeychain.set("some string", forKey: "your_key")
    /// ```
    ///
    /// - Parameter string: Value to save in the Keychain.
    /// - Parameter key: Key for the Keychain item.
    /// - Throws: A ``SimpleKeychainError`` when the SimpleKeychain operation fails.
    public func set(_ string: String, forKey key: String) throws {
        try set(Data(string.utf8), forKey: key)
    }

    /// Saves a `Data` value with the type `kSecClassKey` in the Keychain.
    ///
    /// ```swift
    /// try simpleKeychain.set(data, forKey: "your_key")
    /// ```
    ///
    /// - Parameter data: Value to save in the Keychain.
    /// - Parameter key: Key for the Keychain item.
    /// - Throws: A ``SimpleKeychainError`` when the SimpleKeychain operation fails.
    public func set(_ data: Data, forKey key: String) throws {
        let addItemQuery = setQuery(forKey: key, data: data)
        let addStatus = SecItemAdd(addItemQuery as CFDictionary, nil)

        if addStatus == SimpleKeychainError.duplicateItem.status {
            let updateQuery = baseQuery(withKey: key)
            let updateAttributes: [String: Any] = [kSecValueData as String: data]
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
            try assertSuccess(forStatus: updateStatus)
        } else {
            try assertSuccess(forStatus: addStatus)
        }
    }
}

// MARK: - Delete items

extension SimpleKeychain {
    /// Deletes an item from the Keychain.
    ///
    /// ```swift
    /// try simpleKeychain.deleteItem(forKey: "your_key")
    /// ```
    ///
    /// - Parameter key: Key of the Keychain item to delete..
    /// - Throws: A ``SimpleKeychainError`` when the SimpleKeychain operation fails.
    public func deleteItem(forKey key: String) throws {
        let query = baseQuery(withKey: key)
        try assertSuccess(forStatus: remove(query as CFDictionary))
    }

    /// Deletes all items from the Keychain for the service and access group values.
    ///
    /// ```swift
    /// try simpleKeychain.deleteAll()
    /// ```
    ///
    /// - Throws: A ``SimpleKeychainError`` when the SimpleKeychain operation fails.
    public func deleteAll() throws {
        var query = baseQuery()
        #if os(macOS)
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        #endif
        let status = remove(query as CFDictionary)
        guard SimpleKeychainError.Code(rawValue: status) != SimpleKeychainError.Code.itemNotFound else { return }
        try assertSuccess(forStatus: status)
    }
}

// MARK: - Convenience methods

extension SimpleKeychain {
    /// Checks if an item is stored in the Keychain.
    ///
    /// ```swift
    /// let isStored = try simpleKeychain.hasItem(forKey: "your_key")
    /// ```
    ///
    /// - Parameter key: Key of the Keychain item to check.
    /// - Returns: Whether the item is stored in the Keychain or not.
    /// - Throws: A ``SimpleKeychainError`` when the SimpleKeychain operation fails.
    public func hasItem(forKey key: String) throws -> Bool {
        let query = baseQuery(withKey: key)
        let status = retrieve(query as CFDictionary, nil)

        if status == SimpleKeychainError.itemNotFound.status {
            return false
        }

        try assertSuccess(forStatus: status)
        return true
    }

    /// Retrieves the keys of all the items stored in the Keychain for the service and access group values.
    ///
    /// ```swift
    /// let keys = try simpleKeychain.keys()
    /// ```
    ///
    /// - Returns: A `String` array containing the keys.
    /// - Throws: A ``SimpleKeychainError`` when the SimpleKeychain operation fails.
    public func keys() throws -> [String] {
        let query = getAllQuery
        var keys: [String] = []
        var result: AnyObject?
        let status = retrieve(query as CFDictionary, &result)
        guard SimpleKeychainError.Code(rawValue: status) != SimpleKeychainError.Code.itemNotFound else { return keys }
        try assertSuccess(forStatus: status)

        guard let items = result as? [[String: Any]] else {
            let message = "Unable to cast the retrieved items to a [[String: Any]] value"
            throw SimpleKeychainError(code: SimpleKeychainError.Code.unknown(message: message))
        }

        for item in items {
            if let key = item[kSecAttrAccount as String] as? String {
                keys.append(key)
            }
        }

        return keys
    }
}

// MARK: - Queries

extension SimpleKeychain {
    func baseQuery(withKey key: String? = nil, data: Data? = nil) -> [String: Any] {
        var query = attributes
        query[kSecClass as String] = kSecClassKey
        query[kSecAttrService as String] = service

        if let key = key {
            query[kSecAttrAccount as String] = key
        }
        if let data = data {
            query[kSecValueData as String] = data
        }
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        #if canImport(LocalAuthentication) && !os(tvOS)
        if let context = context {
            query[kSecUseAuthenticationContext as String] = context
        }
        #endif
        if isSynchronizable {
            query[kSecAttrSynchronizable as String] = kCFBooleanTrue
        }

        return query
    }

    var getAllQuery: [String: Any] {
        var query = baseQuery()
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        return query
    }

    func getOneQuery(byKey key: String) -> [String: Any] {
        var query = baseQuery(withKey: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        return query
    }

    func setQuery(forKey key: String, data: Data) -> [String: Any] {
        var query = baseQuery(withKey: key, data: data)

        if let flags = accessControlFlags,
           let access = SecAccessControlCreateWithFlags(kCFAllocatorDefault, accessibility.rawValue, flags, nil)
        {
            query[kSecAttrAccessControl as String] = access
        } else {
            #if os(macOS)
            // See https://developer.apple.com/documentation/security/ksecattraccessible
            if isSynchronizable || query[kSecUseDataProtectionKeychain as String] as? Bool == true {
                query[kSecAttrAccessible as String] = accessibility.rawValue
            }
            #else
            query[kSecAttrAccessible as String] = accessibility.rawValue
            #endif
        }

        return query
    }
}

// MARK: - Error

/// Represents an error during a SimpleKeychain operation.
public struct SimpleKeychainError: LocalizedError, CustomDebugStringConvertible {
    enum Code: RawRepresentable, Equatable {
        case operationNotImplemented
        case invalidParameters
        case userCanceled
        case itemNotAvailable
        case authFailed
        case duplicateItem
        case itemNotFound
        case interactionNotAllowed
        case decodeFailed
        case other(status: OSStatus)
        case unknown(message: String)

        init(rawValue: OSStatus) {
            switch rawValue {
            case errSecUnimplemented: self = .operationNotImplemented
            case errSecParam: self = .invalidParameters
            case errSecUserCanceled: self = .userCanceled
            case errSecNotAvailable: self = .itemNotAvailable
            case errSecAuthFailed: self = .authFailed
            case errSecDuplicateItem: self = .duplicateItem
            case errSecItemNotFound: self = .itemNotFound
            case errSecInteractionNotAllowed: self = .interactionNotAllowed
            case errSecDecode: self = .decodeFailed
            default: self = .other(status: rawValue)
            }
        }

        var rawValue: OSStatus {
            switch self {
            case .operationNotImplemented: return errSecUnimplemented
            case .invalidParameters: return errSecParam
            case .userCanceled: return errSecUserCanceled
            case .itemNotAvailable: return errSecNotAvailable
            case .authFailed: return errSecAuthFailed
            case .duplicateItem: return errSecDuplicateItem
            case .itemNotFound: return errSecItemNotFound
            case .interactionNotAllowed: return errSecInteractionNotAllowed
            case .decodeFailed: return errSecDecode
            case let .other(status): return status
            case .unknown: return errSecSuccess // This is not a Keychain error
            }
        }
    }

    let code: Code

    init(code: Code) {
        self.code = code
    }

    /// The `OSStatus` of the Keychain operation.
    public var status: OSStatus {
        code.rawValue
    }

    /// Description of the error.
    ///
    /// - Important: You should avoid displaying the error description to the user, it's meant for **debugging** only.
    public var localizedDescription: String { debugDescription }

    /// Description of the error.
    ///
    /// - Important: You should avoid displaying the error description to the user, it's meant for **debugging** only.
    public var errorDescription: String? { debugDescription }

    /// Description of the error.
    ///
    /// - Important: You should avoid displaying the error description to the user, it's meant for **debugging** only.
    public var debugDescription: String {
        switch code {
        case .operationNotImplemented:
            return "errSecUnimplemented: A function or operation is not implemented."
        case .invalidParameters:
            return "errSecParam: One or more parameters passed to the function are not valid."
        case .userCanceled:
            return "errSecUserCanceled: User canceled the operation."
        case .itemNotAvailable:
            return "errSecNotAvailable: No trust results are available."
        case .authFailed:
            return "errSecAuthFailed: Authorization and/or authentication failed."
        case .duplicateItem:
            return "errSecDuplicateItem: The item already exists."
        case .itemNotFound:
            return "errSecItemNotFound: The item cannot be found."
        case .interactionNotAllowed:
            return "errSecInteractionNotAllowed: Interaction with the Security Server is not allowed."
        case .decodeFailed:
            return "errSecDecode: Unable to decode the provided data."
        case .other:
            return "Unspecified Keychain error: \(status)."
        case let .unknown(message):
            return "Unknown error: \(message)."
        }
    }

    // MARK: - Error Cases

    /// A function or operation is not implemented.
    /// See [errSecUnimplemented](https://developer.apple.com/documentation/security/errsecunimplemented).
    public static let operationNotImplemented: SimpleKeychainError = .init(code: .operationNotImplemented)

    /// One or more parameters passed to the function are not valid.
    /// See [errSecParam](https://developer.apple.com/documentation/security/errsecparam).
    public static let invalidParameters: SimpleKeychainError = .init(code: .invalidParameters)

    /// User canceled the operation.
    /// See [errSecUserCanceled](https://developer.apple.com/documentation/security/errsecusercanceled).
    public static let userCanceled: SimpleKeychainError = .init(code: .userCanceled)

    /// No trust results are available.
    /// See [errSecNotAvailable](https://developer.apple.com/documentation/security/errsecnotavailable).
    public static let itemNotAvailable: SimpleKeychainError = .init(code: .itemNotAvailable)

    /// Authorization and/or authentication failed.
    /// See [errSecAuthFailed](https://developer.apple.com/documentation/security/errsecauthfailed).
    public static let authFailed: SimpleKeychainError = .init(code: .authFailed)

    /// The item already exists.
    /// See [errSecDuplicateItem](https://developer.apple.com/documentation/security/errsecduplicateitem).
    public static let duplicateItem: SimpleKeychainError = .init(code: .duplicateItem)

    /// The item cannot be found.
    /// See [errSecItemNotFound](https://developer.apple.com/documentation/security/errsecitemnotfound).
    public static let itemNotFound: SimpleKeychainError = .init(code: .itemNotFound)

    /// Interaction with the Security Server is not allowed.
    /// See
    /// [errSecInteractionNotAllowed](https://developer.apple.com/documentation/security/errsecinteractionnotallowed).
    public static let interactionNotAllowed: SimpleKeychainError = .init(code: .interactionNotAllowed)

    /// Unable to decode the provided data.
    /// See [errSecDecode](https://developer.apple.com/documentation/security/errsecdecode).
    public static let decodeFailed: SimpleKeychainError = .init(code: .decodeFailed)

    /// Other Keychain error.
    /// The `OSStatus` of the Keychain operation can be accessed via the ``status`` property.
    public static let other: SimpleKeychainError = .init(code: .other(status: 0))

    /// Unknown error. This is not a Keychain error but a SimpleKeychain failure. For example, being unable to cast the
    /// retrieved item.
    public static let unknown: SimpleKeychainError = .init(code: .unknown(message: ""))
}

// MARK: - Equatable

extension SimpleKeychainError: Equatable {
    /// Conformance to `Equatable`.
    public static func == (lhs: SimpleKeychainError, rhs: SimpleKeychainError) -> Bool {
        lhs.code == rhs.code && lhs.localizedDescription == rhs.localizedDescription
    }
}

// MARK: - Pattern Matching Operator

extension SimpleKeychainError {
    /// Matches `SimpleKeychainError` values in a switch statement.
    public static func ~= (lhs: SimpleKeychainError, rhs: SimpleKeychainError) -> Bool {
        lhs.code == rhs.code
    }

    /// Matches `Error` values in a switch statement.
    public static func ~= (lhs: SimpleKeychainError, rhs: any Error) -> Bool {
        guard let rhs = rhs as? SimpleKeychainError else { return false }
        return lhs.code == rhs.code
    }
}

// MARK: - Accessibility

/// Represents the accessibility types of Keychain items. It's a mirror of `kSecAttrAccessible` values.
public enum Accessibility: RawRepresentable {
    /// The data in the Keychain item can be accessed only while the device is unlocked by the user.
    /// See [kSecAttrAccessibleWhenUnlocked](https://developer.apple.com/documentation/security/ksecattraccessiblewhenunlocked).
    case whenUnlocked

    /// The data in the Keychain can only be accessed when the device is unlocked. Only available if a passcode is set
    /// on the device.
    /// See [kSecAttrAccessibleWhenUnlockedThisDeviceOnly](https://developer.apple.com/documentation/security/ksecattraccessiblewhenpasscodesetthisdeviceonly).
    case whenUnlockedThisDeviceOnly

    /// The data in the Keychain item cannot be accessed after a restart until the device has been unlocked once by the
    /// user.
    /// See [kSecAttrAccessibleAfterFirstUnlock](https://developer.apple.com/documentation/security/ksecattraccessibleafterfirstunlock).
    case afterFirstUnlock

    /// The data in the Keychain item cannot be accessed after a restart until the device has been unlocked once by the
    /// user.
    /// See [kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly](https://developer.apple.com/documentation/security/ksecattraccessibleafterfirstunlockthisdeviceonly).
    case afterFirstUnlockThisDeviceOnly

    /// The data in the Keychain can only be accessed when the device is unlocked. Only available if a passcode is set
    /// on the device.
    /// See [kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly](https://developer.apple.com/documentation/security/ksecattraccessiblewhenpasscodesetthisdeviceonly).
    case whenPasscodeSetThisDeviceOnly

    /// Maps a `kSecAttrAccessible` value to an accessibility type.
    public init(rawValue: CFString) {
        switch rawValue {
        case kSecAttrAccessibleWhenUnlocked: self = .whenUnlocked
        case kSecAttrAccessibleWhenUnlockedThisDeviceOnly: self = .whenUnlockedThisDeviceOnly
        case kSecAttrAccessibleAfterFirstUnlock: self = .afterFirstUnlock
        case kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly: self = .afterFirstUnlockThisDeviceOnly
        case kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly: self = .whenPasscodeSetThisDeviceOnly
        default: self = .afterFirstUnlock
        }
    }

    /// The `kSecAttrAccessible` value of a given accessibility type.
    public var rawValue: CFString {
        switch self {
        case .whenUnlocked: return kSecAttrAccessibleWhenUnlocked
        case .whenUnlockedThisDeviceOnly: return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlock: return kSecAttrAccessibleAfterFirstUnlock
        case .afterFirstUnlockThisDeviceOnly: return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .whenPasscodeSetThisDeviceOnly: return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        }
    }
}
