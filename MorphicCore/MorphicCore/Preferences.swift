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

public struct Preferences: Codable, Record {
    
    // MARK: - Creating Preferences
    
    /// Create a new preferences object from the given identifier
    ///
    /// Typically used for completely new users
    public init(identifier: String) {
        self.identifier = identifier
    }
    
    // MARK: - Identifier
    
    public static var typeName: String = "Preferences"
    
    /// The prefernces unique identifier
    public var identifier: String
    
    /// The the id of the user that the preferences belong to
    public var userId: String!
    
    // MARK: - Solution Preferences
    
    public typealias PreferencesSet = [String: Solution]
    
    /// The default map of solution identifier to solution prefs
    public var defaults: PreferencesSet?
    
    public struct Key: Equatable, Hashable {
        
        public var solution: String
        public var preference: String
        
        public init(solution: String, preference: String) {
            self.solution = solution
            self.preference = preference
        }
        
    }

    /// The preferences for a specific solution
    public struct Solution: Codable {
        
        /// Each solution can store arbitrary values
        public var values = [String: Interoperable?]()
        
        public init() {
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: ArbitraryKeys.self)
            values = try container.decodeInteroperableDictionary()
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: ArbitraryKeys.self)
            try values.encodeElements(to: &container)
        }
        
    }
    
    public mutating func set(_ value: Interoperable?, for key: Key) {
        if defaults == nil {
            defaults = [:]
        }
        if defaults?[key.solution] == nil {
            defaults?[key.solution] = Solution()
        }
        defaults?[key.solution]?.values[key.preference] = value
    }
    
    public func get(key: Key) -> Interoperable? {
        return defaults?[key.solution]?.values[key.preference] ?? nil
    }
    
    public mutating func remove(key: Key) {
        if defaults == nil {
            return
        }
        if defaults![key.solution] == nil {
            return
        }
        defaults![key.solution]!.values.removeValue(forKey: key.preference)
        //
        if defaults![key.solution]!.values.count == 0 {
            defaults!.removeValue(forKey: key.solution)
        }
    }
    
    public func keyValueTuples() -> [(Key, Interoperable?)] {
        var tuples = [(Key, Interoperable?)]()
        guard let defaults = defaults else {
            return tuples
        }
        for (identifier, solution) in defaults {
            for (name, value) in solution.values {
                let key = Key(solution: identifier, preference: name)
                tuples.append((key, value))
            }
        }
        return tuples
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case userId = "user_id"
        case defaults = "default"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(String.self, forKey: .identifier)
        userId = try container.decode(String?.self, forKey: .userId)
        defaults = try container.decode(PreferencesSet?.self, forKey: .defaults)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(userId, forKey: .userId)
        try container.encode(defaults, forKey: .defaults)
    }
    
}
