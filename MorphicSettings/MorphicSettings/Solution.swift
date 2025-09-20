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
import MorphicCore

/// Data model describing a solution
///
/// Solutions typically represent applications or high level features such as
/// - Display
/// - Screen Reader
/// - JAWS
///
/// Within a solution is a list of related settings that control fine-grained details
/// of how the feature works.
public struct Solution: Decodable {
    
    /// The globally unique identifier for the solution, typically in reverse-domain style
    public let identifier: String
    
    /// The settings within this solution
    public let settings: [Setting]
    
    /// Get the setting for the given name
    ///
    /// - parameter name: The locally-unique name for a setting
    public func setting(for name: String) -> Setting? {
        return settingsByName[name]
    }
    
    /// Lookup dictionary for settings by name
    private let settingsByName: [String: Setting]
    
    /// JSON property name map
    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case settings
    }
    
    /// Create a Solution from a decoder (JSON)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(String.self, forKey: .identifier)
        settings = try container.decode([Setting].self, forKey: .settings)
        settingsByName = settings.dictionaryByName()
    }
    
    /// Create a setting with the given identifier and settings
    ///
    /// Solutions will most often be created by decoding JSON, but a manual init method can be useful
    /// in cases such as testing.
    ///
    /// - parameters:
    ///   - identifier: The solution's unique identifier
    ///   - settings: The settings in this solution
    public init(identifier: String, settings: [Setting]) {
        self.identifier = identifier
        self.settings = settings
        settingsByName = settings.dictionaryByName()
    }
    
}

fileprivate extension Array where Element == Setting {
    
    func dictionaryByName() -> [String: Setting] {
        var dictionary = [String: Setting]()
        for setting in self{
            dictionary[setting.name] = setting
        }
        return dictionary
    }
    
}
