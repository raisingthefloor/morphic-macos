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

/// A data model describing an individual setting within a `Solution`
public struct Setting: Decodable {
    
    /// The setting's locally-unique name within its owning `Solution`
    public let name: String
    
    /// The type allowed for this setting's value
    public let type: ValueType
    
    /// The possible types for values
    public enum ValueType: String, Decodable {
        
        /// The value is a `String`
        case string
        
        /// The value is an `Int`
        case integer
        
        /// The value is a `Double`
        case double
        
        /// The value is a `Bool`
        case boolean
    }
    
    /// The setting's default value
    public let defaultValue: Interoperable?
    
    /// The description used to create a `SettingHandler` for this setting
    public let handlerDescription: SettingHandlerDescription
    
    /// The description used to create a `SettingFinalizer` for this setting
    public let finalizerDescription: SettingFinalizerDescription?
    
    /// JSON decoding property map
    private enum CodingKeys: String, CodingKey {
        case name
        case type
        case defaultValue = "default"
        case handler
        case finalizer
    }
    
    /// property map for the `handler` sub-container
    ///
    /// Handler descriptions are based on the `type` value within the `handler` container, so
    /// we need to peek inside in order to create the correct handler description
    private enum HandlerCodingKeys: String, CodingKey {
        case type
    }
    
    /// The possible handler descriptions types
    public enum HandlerType: String, Decodable {
        
        /// Client handlers are custom code provided by the client application
        case client = "org.raisingthefloor.morphic.client"
        
        /// Reads from user defaults and writes by opening the system preferences UI
        ///
        /// The latest versions of macOS don't allow an app to write to defaults, which would be the more natural
        /// way to implement a handler
        case defaultsReadUIWrite = "com.apple.macos.defaults-read-ui-write"
    }
    
    /// property map for the `finalizer` sub-container
    ///
    /// Handler descriptions are based on the `type` value within the `finalizer` container, so
    /// we need to peek inside in order to create the correct handler description
    private enum FinalizerCodingKeys: String, CodingKey {
        case type
    }
    
    /// The possible finalizer description types
    public enum FinalizerType: String, Decodable {
        // TODO: remove after the first real case is added
        case notImplemented
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(ValueType.self, forKey: .type)
        defaultValue = try container.decodeInteroperable(for: .defaultValue)
        let handlerContainer = try container.nestedContainer(keyedBy: HandlerCodingKeys.self, forKey: .handler)
        let handlerType = try handlerContainer.decode(HandlerType.self, forKey: .type)
        switch handlerType {
        case .client:
            handlerDescription = try container.decode(ClientSettingHandler.Description.self, forKey: .handler)
        case .defaultsReadUIWrite:
            handlerDescription = try container.decode(DefaultsReadUIWriteSettingHandler.Description.self, forKey: .handler)
        }
        if container.contains(.finalizer) {
            let finalizerContainer = try container.nestedContainer(keyedBy: FinalizerCodingKeys.self, forKey: .finalizer)
            let finalizerType = try finalizerContainer.decode(FinalizerType.self, forKey: .type)
            switch finalizerType {
            case .notImplemented:
                finalizerDescription = nil
            }
        } else {
            finalizerDescription = nil
        }
    }
    
    public func isDefault(_ value: Interoperable?) -> Bool {
        switch type {
        case .boolean:
            guard let defaultValue = defaultValue as? Bool else {
                return false
            }
            guard let value = value as? Bool else {
                return false
            }
            return value == defaultValue
        case .integer:
            guard let defaultValue = defaultValue as? Int else {
                return false
            }
            guard let value = value as? Int else {
                return false
            }
            return value == defaultValue
        case .string:
            guard let defaultValue = defaultValue as? String else {
                return false
            }
            guard let value = value as? String else {
                return false
            }
            return value == defaultValue
        case .double:
            guard let defaultValue = defaultValue as? Double else {
                return false
            }
            guard let value = value as? Double else {
                return false
            }
            return value == defaultValue
        }
    }
}
