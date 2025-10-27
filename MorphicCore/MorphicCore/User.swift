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

/// A Morphic user
public struct User: Codable, Record {
    
    // MARK: - Creating a User
    
    /// Create a new user by generating a new globally unique identifier
    ///
    /// Typically used for completely new users
    public init() {
        identifier = UUID().uuidString
        preferencesId = UUID().uuidString
    }
    
    /// Create a user with a known identifier
    ///
    /// - parameter identifier: The user's unique identifier
    public init(identifier: Identifier) {
        self.identifier = identifier
    }
    
    public static var typeName: String = "User"
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case preferencesId = "preferences_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case email = "email"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(String.self, forKey: .identifier)
        preferencesId = try container.decode(String?.self, forKey: .preferencesId)
        firstName = try container.decode(String?.self, forKey: .firstName)
        lastName = try container.decode(String?.self, forKey: .lastName)
        email = try container.decodeIfPresent(String.self, forKey: .email)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(preferencesId, forKey: .preferencesId)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        if let email = email {
            try container.encode(email, forKey: .email)
        }
    }
    
    // MARK: - Identification
    
    public typealias Identifier = String
    
    /// A globally unique identifier for the user
    public var identifier: Identifier
    
    // MARK: - Name
    
    /// The user's first name
    public var firstName: String?
    
    /// The user's last name
    public var lastName: String?
    
    public var email: String?
    
    // MARK: - Preferences
    
    public var preferencesId: String!
}
