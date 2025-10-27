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

import Cocoa
import OSLog
import MorphicCore
import MorphicService

private let logger = OSLog(subsystem: "app", category: "Session")

/// Extension to MorphicService.Session to create a shared session for the app
extension Session {
    
    static var shared: Session = {
        return Session(endpoint: Session.mainBundleEndpoint)
    }()
    
    /// The root URL endpoint for the Morphic service
    ///
    /// Obtained from the `Morphic###ServiceEndpoint` entry in `Info.plist`, which itself is
    /// populated by the `MORPHIC_###_SERVICE_ENDPOINT` build configuration variable.
    ///
    /// The production endpoint URL is hard-coded in `Release.xcconfig`, and a default
    /// URL is specified in `Debug.xcconfig`, each developer can override the setting by
    /// creating a `Local.xcconfig` with whatever value is relevant to their local setup.
    static var mainBundleEndpoint: URL! = {
        guard let endpointString = Bundle.main.infoDictionary?["MorphicServiceEndpoint"] as? String else {
            os_log(.fault, log: logger, "Missing morphic endpoint.  Check build config files")
            return nil
        }
        guard let endpoint = URL(string: endpointString) else {
            os_log(.fault, log: logger, "Invalid morphic endpoint.  Check build config files")
            return nil
        }
        return endpoint
    }()
    
}

extension NSNotification.Name {
    static let morphicSignin = NSNotification.Name("org.raisingthefloor.morphicSignin")
}
