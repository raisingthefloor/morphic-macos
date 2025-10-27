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
import OSLog

private let logger = OSLog(subsystem: "MorphicService", category: "Service")

/// Base class for all morphic services
public class Service {
    
    // MARK: - Creating a Service
    
    /// Create a service at the given endpoint using the given session
    ///
    /// - parameters:
    ///   - endpoint: The location of the remote server
    ///   - session: The URL session to use for requests to the remote server
    public init(endpoint: URL, session: Session) {
        self.endpoint = endpoint
        self.session = session
    }
    
    // MARK: - Location
    
    /// The location of the remote server
    public private(set) var endpoint: URL
    
    /// The URL session to use when making requests to the remote server
    public private(set) weak var session: Session!
    
    public enum Response<ResponseBody, BadRequestBody> {
        case success(body: ResponseBody)
        case badRequest(body: BadRequestBody)
        case failed
    }
}
