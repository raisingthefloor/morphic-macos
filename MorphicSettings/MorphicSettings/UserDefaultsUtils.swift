// Copyright 2023-2025 Raising the Floor - US, Inc.
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/raisingthefloor/morphic-macos/blob/master/LICENSE.txt
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

internal class UserDefaultsUtils {
    internal static func defaultAsOptionalBool(suiteName: String, forKey key: String) throws -> Bool? {
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw MorphicError.unspecified
        }
        
        let resultAsOptionalObject = userDefaults.object(forKey: key)
        guard let resultAsObject = resultAsOptionalObject else {
            return nil
        }
        guard let result = resultAsObject as? Bool else {
            throw MorphicError.unspecified
        }
        return result
    }
    
    internal static func defaultAsOptionalInt(suiteName: String, forKey key: String) throws -> Int? {
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw MorphicError.unspecified
        }
        
        let resultAsOptionalObject = userDefaults.object(forKey: key)
        guard let resultAsObject = resultAsOptionalObject else {
            return nil
        }
        guard let result = resultAsObject as? Int else {
            throw MorphicError.unspecified
        }
        return result
    }
}
