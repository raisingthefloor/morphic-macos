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

/// Abstract base class for reading and writing the value for a setting
///
/// Sublclasses should define a `Definition` data model that conforms to
/// `SettingHandlerDescription` and describes the handler's properties
public class SettingHandler {
    
    /// Create a setting handler for the given setting
    ///
    /// - parameters:
    ///   - setting: The description of the setting to read/write
    public required init(setting: Setting) {
        self.setting = setting
    }
    
    /// Write the given value for the setting
    ///
    /// - parameters:
    ///   - value: The value to save for `setting`
    ///   - completion: Called when the write completes
    ///   - success: Whether the write succeeded
    public func apply(_ value: Interoperable?, completion: @escaping (_ success: Bool) -> Void) {
        completion(false)
    }
    
    /// Possbile results for reading a setting's value
    public enum Result {
        /// The read succeeded, with the value
        case succeeded(value: Interoperable)
        /// The read failed
        case failed
    }
    
    /// Read the value for `setting`
    ///
    /// - parameters:
    ///   - completion: Called when the read completes
    ///   - result: The result of the read
    public func read(completion: @escaping (_ result: Result) -> Void) {
        completion(.failed)
    }
    
    /// The setting on which this handler operates
    public let setting: Setting
    
}

/// A protocol that should be adopted by any data  model describing a setting handler
public protocol SettingHandlerDescription: Decodable {
    
    var type: Setting.HandlerType { get }
    
}

public extension Setting {
    
    func createHandler() -> SettingHandler? {
        switch handlerDescription.type{
        case .client:
            return ClientSettingHandler.create(for: self)
        case .defaultsReadUIWrite:
            return DefaultsReadUIWriteSettingHandler(setting: self)
        }
    }
    
}
