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

/// A setting finalizer runs once at the end of an `ApplySession` to perform an operation needed by one or more settings.
///
/// For example, a finalizer might be used to restart a process or perform a system call that refreshes some
/// UI components.  Rather than do this operation after each setting changes, finalizers provide a way to
/// perform the operation only once after all the settings have been updated.
public class SettingFinalizer {
    
    /// Create a finalizer from the given description
    public required init(description: SettingFinalizerDescription) {
        self.description = description
    }
    
    public let description: SettingFinalizerDescription
    
    /// Run the finalizer's operation
    public func run(completion: @escaping (_ success: Bool) -> Void) {
        completion(false)
    }
    
    public static func create(from description: SettingFinalizerDescription) -> SettingFinalizer? {
        switch description.type {
        case .notImplemented:
            return nil
        }
    }
    
}

/// A data model describing the finalizer's behavior
public protocol SettingFinalizerDescription {
    
    var type: Setting.FinalizerType { get }
    
    var uniqueRepresentation: String { get }
    
}
