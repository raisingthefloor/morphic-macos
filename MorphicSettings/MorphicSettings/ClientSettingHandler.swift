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

/// Base class for client handlers that run custom code specific to the setting
public class ClientSettingHandler: SettingHandler {
    
    /// Factory method for creating a client setting handler
    ///
    /// Types are registered via `register(type:for:)`
    ///
    /// - parameter setting: The setting for which a handler should be created
    public static func create(for setting: Setting) -> ClientSettingHandler? {
        guard let description = setting.handlerDescription as? Description else {
            return nil
        }
        let key = Preferences.Key(solution: description.solution, preference: description.preference)
        guard let type = handlerTypesByKey[key] else {
            return nil
        }
        return type.init(setting: setting)
    }
    
    /// Register a client handler of the given type for the given key
    ///
    /// Registered types are avaiable to `create(for:)`
    ///
    /// - parameters:
    ///   - type: The `ClientSettingHandler` subclass to use for the given key
    ///   - key: The key that identifies when to use the given type
    public static func register(type: ClientSettingHandler.Type, for key: Preferences.Key) {
        handlerTypesByKey[key] = type
    }
    
    /// The map of keys to types
    private static var handlerTypesByKey = [Preferences.Key: ClientSettingHandler.Type]()
    
    /// The properly typed description for this handler
    private var description: Description {
        return setting.handlerDescription as! Description
    }
    
    /// Data model describing the properites for a client setting handler
    public struct Description: SettingHandlerDescription {
        
        public var type: Setting.HandlerType {
            return .client
        }

        /// The solution identifier
        public let solution: String
        
        /// The setting name
        public let preference: String
        
        /// A preference key created by combining `solution` and `preference`
        public var key: Preferences.Key {
            return Preferences.Key(solution: solution, preference: preference)
        }
        
    }
}
