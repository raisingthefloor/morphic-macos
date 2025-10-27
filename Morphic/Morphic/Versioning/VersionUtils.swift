// Copyright 2021 Raising the Floor - US, Inc.
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

struct VersionUtils {
    static func compositeVersion() -> String? {
        // create a composite tag indicating the version of this build of our software (to match the version #s used by the autoupdate files)
        
        // version # (major.minor)
        guard let shortVersionAsString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return nil
        }
        // build # (build.revision...which the build pipelines treat as minor.patch)
        guard let buildAsString = Bundle.main.infoDictionary?["CFBundleVersion" as String] as? String else {
            return nil
        }

        // capture the major version for the version #
        guard let majorVersionAsString = shortVersionAsString.split(separator: ".").first else {
            return nil
        }
        
        return majorVersionAsString + "." + buildAsString
    }
    
    enum CompareVersionResult {
        case lessThan
        case greaterThan
        case equals
    }
    static func compareVersions(_ lhs: String, _ rhs: String) -> CompareVersionResult? {
        let lhsComponents = lhs.split(separator: ".")
        guard lhsComponents.count > 0 else {
            return nil
        }
        let rhsComponents = rhs.split(separator: ".")
        guard rhsComponents.count > 0 else {
            return nil
        }

        var lhsComponentsAsInts: [Int] = []
        for lhsComponent in lhsComponents {
            guard let componentAsInt = Int(lhsComponent) else {
                // invalid (non-numeric) component
                return nil
            }
            lhsComponentsAsInts.append(componentAsInt)
        }
        //
        var rhsComponentsAsInts: [Int] = []
        for rhsComponent in rhsComponents {
            guard let componentAsInt = Int(rhsComponent) else {
                // invalid (non-numeric) component
                return nil
            }
            rhsComponentsAsInts.append(componentAsInt)
        }
        
        let numberOfComponentsToCompare = max(lhsComponentsAsInts.count, rhsComponentsAsInts.count)
        
        for index in 0..<numberOfComponentsToCompare {
            let lhsInt = lhsComponentsAsInts.count > index ? lhsComponentsAsInts[index] : 0
            let rhsInt = rhsComponentsAsInts.count > index ? rhsComponentsAsInts[index] : 0
            
            if lhsInt > rhsInt {
                return .greaterThan
            } else if lhsInt < rhsInt {
                return .lessThan
            }
        }
        
        // if all of the components matched, the version #s are equal
        return .equals
    }
}
