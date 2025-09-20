// Copyright 2020 Raising the Floor - US, Inc.
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/GPII/universal/blob/master/LICENSE.txt
//
// The R&D leading to these results received funding from the:
// * Rehabilitation Services Administration, US Dept. of Education under
//   grant H421A150006 (APCP)
// * National Institute on Disability, Independent Living, and
//   Rehabilitation Research (NIDILRR)
// * Administration for Independent Living & Dept. of Education under grants
//   H133E080022 (RERC-IT) and H133E130028/90RE5003-01-00 (UIITA-RERC)
// * European Union's Seventh Framework Programme (FP7/2007-2013) grant
//   agreement nos. 289016 (Cloud4all) and 610510 (Prosperity4All)
// * William and Flora Hewlett Foundation
// * Ontario Ministry of Research and Innovation
// * Canadian Foundation for Innovation
// * Adobe Foundation
// * Consumer Electronics Association Foundation

import Foundation

/// Protocol for interoperable types, like those that can be contained in a JSON file
public protocol Interoperable {
    
    /// Encode this value into a keyed container under the given key
    func encode(to keyedContainer: inout KeyedEncodingContainer<ArbitraryKeys>, for key: ArbitraryKeys) throws
    
    /// Encode this value into an unkeyed container
    func encode(to unkeyedContainer: inout UnkeyedEncodingContainer) throws
    
}

extension Int: Interoperable {

    public func encode(to keyedContainer: inout KeyedEncodingContainer<ArbitraryKeys>, for key: ArbitraryKeys) throws {
        try keyedContainer.encode(self, forKey: key)
    }
    
    public func encode(to unkeyedContainer: inout UnkeyedEncodingContainer) throws {
        try unkeyedContainer.encode(self)
    }
}

extension Double: Interoperable {

    public func encode(to keyedContainer: inout KeyedEncodingContainer<ArbitraryKeys>, for key: ArbitraryKeys) throws {
        try keyedContainer.encode(self, forKey: key)
    }
    
    public func encode(to unkeyedContainer: inout UnkeyedEncodingContainer) throws {
        try unkeyedContainer.encode(self)
    }
    
}

extension Bool: Interoperable {

    public func encode(to keyedContainer: inout KeyedEncodingContainer<ArbitraryKeys>, for key: ArbitraryKeys) throws {
        try keyedContainer.encode(self, forKey: key)
    }
    
    public func encode(to unkeyedContainer: inout UnkeyedEncodingContainer) throws {
        try unkeyedContainer.encode(self)
    }
    
}

extension String: Interoperable {

    public func encode(to keyedContainer: inout KeyedEncodingContainer<ArbitraryKeys>, for key: ArbitraryKeys) throws {
        try keyedContainer.encode(self, forKey: key)
    }
    
    public func encode(to unkeyedContainer: inout UnkeyedEncodingContainer) throws {
        try unkeyedContainer.encode(self)
    }
    
}

extension Array: Interoperable where Element == Interoperable? {
    
    public func encode(to keyedContainer: inout KeyedEncodingContainer<ArbitraryKeys>, for key: ArbitraryKeys) throws {
        var nestedContainer = keyedContainer.nestedUnkeyedContainer(forKey: key)
        try encodeElements(to: &nestedContainer)
    }
    
    public func encode(to unkeyedContainer: inout UnkeyedEncodingContainer) throws {
        var nestedContainer = unkeyedContainer.nestedUnkeyedContainer()
        try encodeElements(to: &nestedContainer)
    }
    
    /// Encode this arrays's interoperable elements into a keyed container
    public func encodeElements(to unkeyedContainer: inout UnkeyedEncodingContainer) throws {
        for v in self {
            if let v = v {
                try v.encode(to: &unkeyedContainer)
            } else {
                try unkeyedContainer.encodeNil()
            }
        }
    }
    
    /// Get the integer value at the given index
    public func int(at index: Int) -> Int? {
        return self[index] as? Int
    }
    
    /// Set the integer value at the given index
    public mutating func set(_ int: Int, at index: Int) {
        self[index] = int
    }
    
    /// Get the double value at the given index
    public func double(at index: Int) -> Double? {
        return self[index] as? Double
    }
    
    /// Set the double value at the given index
    public mutating func set(_ double: Double, at index: Int) {
        self[index] = double
    }
    
    /// Get the string value at the given index
    public func string(at index: Int) -> String? {
        return self[index] as? String
    }
    
    /// Set the string value at the given index
    public mutating func set(_ string: String, at index: Int) {
        self[index] = string
    }
    
    /// Get the bool value at the given index
    public func bool(at index: Int) -> Bool? {
        return self[index] as? Bool
    }
    
    /// Set the bool value at the given index
    public mutating func set(_ bool: Bool, at index: Int) {
        self[index] = bool
    }
    
    /// Get the nested array at the given index
    public func array(at index: Int) -> [Interoperable?]? {
        return self[index] as? [Interoperable?]
    }
    
    /// Get the dictionary at the given index
    public func dictionary(at index: Int) -> [String: Interoperable?]? {
        return self[index] as? [String: Interoperable?]
    }
    
}

extension Dictionary: Interoperable where Key == String, Value == Interoperable? {

    public func encode(to keyedContainer: inout KeyedEncodingContainer<ArbitraryKeys>, for key: ArbitraryKeys) throws {
        var nestedContainer = keyedContainer.nestedContainer(keyedBy: ArbitraryKeys.self, forKey: key)
        try encodeElements(to: &nestedContainer)
    }
    
    public func encode(to unkeyedContainer: inout UnkeyedEncodingContainer) throws {
        var nestedContainer = unkeyedContainer.nestedContainer(keyedBy: ArbitraryKeys.self)
        try encodeElements(to: &nestedContainer)
    }
    
    /// Encode this dictionary's interoperable elements into a keyed container
    public func encodeElements(to keyedContainer: inout KeyedEncodingContainer<ArbitraryKeys>) throws {
        for (k,v) in self {
            let key = ArbitraryKeys(stringValue: k)!
            if let v = v {
                try v.encode(to: &keyedContainer, for: key)
            } else {
                try keyedContainer.encodeNil(forKey: key)
            }
        }
    }
    
    /// Get the integer value for the given key
    public func int(for key: String) -> Int? {
        return self[key] as? Int
    }
    
    /// Set the integer value for the given key
    public mutating func set(_ int: Int, for key: String) {
        self[key] = int
    }
    
    /// Get the double value for the given key
    public func double(for key: String) -> Double? {
        return self[key] as? Double
    }
    
    /// Set the double value for the given key
    public mutating func set(_ double: Double, for key: String) {
        self[key] = double
    }
    
    /// Get the string value for the given key
    public func string(for key: String) -> String? {
        return self[key] as? String
    }
    
    /// Set the string value for the given key
    public mutating func set(_ string: String, for key: String) {
        self[key] = string
    }
    
    /// Get the bool value for the given key
    public func bool(for key: String) -> Bool? {
        return self[key] as? Bool
    }
    
    /// Set the bool value for the given key
    public mutating func set(_ bool: Bool, for key: String) {
        self[key] = bool
    }
    
    /// Get the array for the given key
    public func array(for key: String) -> [Interoperable?]? {
        return self[key] as? [Interoperable?]
    }
    
    /// Get the nested dictionar for the given key
    public func dictionary(for key: String) -> [String: Interoperable?]? {
        return self[key] as? [String: Interoperable?]
    }
}

/// Support any key in a container
public class ArbitraryKeys: CodingKey {
    
    required public init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
    
    required public init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    public var intValue: Int?
    public var stringValue: String
    
    enum ValueError: Error{
        case typeNotFound
    }
}

public extension KeyedDecodingContainer {
    
    /// Decode an dictionary of `Interoperable`s in arbitrary keys
    func decodeInteroperableDictionary() throws -> [String: Interoperable?] {
        var dict = [String: Interoperable?]()
        for key in allKeys {
            try dict[key.stringValue] = decodeInteroperable(for: key)
        }
        return dict
    }
    
    /// Decode an `Interoperable` for the given key
    func decodeInteroperable(for key: Key) throws -> Interoperable? {
        if (try? decodeNil(forKey: key)) ?? false {
            return nil
        }
        if let i = try? decode(Int.self, forKey: key) {
            return i
        }
        if let d = try? decode(Double.self, forKey: key) {
            return d
        }
        if let b = try? decode(Bool.self, forKey: key) {
            return b
        }
        if let s = try? decode(String.self, forKey: key) {
            return s
        }
        if var container = try? nestedUnkeyedContainer(forKey: key) {
            return try container.decodeInteroperableArray()
        }
        if let container = try? nestedContainer(keyedBy: Key.self, forKey: key) {
            return try container.decodeInteroperableDictionary()
        }
        throw ArbitraryKeys.ValueError.typeNotFound
    }
    
}

public extension UnkeyedDecodingContainer{
    
    /// Decode an array of `Interoperable`s
    mutating func decodeInteroperableArray() throws -> [Interoperable?] {
        guard let count = count else {
            return []
        }
        var array = [Interoperable?]()
        for _ in 0..<count {
            try array.append(decodeInteroperable())
        }
        return array
    }
    
    /// Decode an `Interoperable`
    mutating func decodeInteroperable() throws -> Interoperable? {
        if (try? decodeNil()) ?? false {
            return nil
        }
        if let i = try? decode(Int.self) {
            return i
        }
        if let d = try? decode(Double.self) {
            return d
        }
        if let b = try? decode(Bool.self) {
            return b
        }
        if let s = try? decode(String.self) {
            return s
        }
        if var container = try? nestedUnkeyedContainer() {
            return try container.decodeInteroperableArray()
        }
        if let container = try? nestedContainer(keyedBy: ArbitraryKeys.self) {
            return try container.decodeInteroperableDictionary()
        }
        throw ArbitraryKeys.ValueError.typeNotFound
    }
}
