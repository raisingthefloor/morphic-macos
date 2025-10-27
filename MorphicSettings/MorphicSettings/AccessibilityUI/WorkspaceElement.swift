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
import Cocoa
import OSLog

private var logger = OSLog(subsystem: "MorphicSettings", category: "WorkspaceElement")

public class WorkspaceElement: UIElement {
    
    public static let shared = WorkspaceElement(accessibilityElement: nil)
    
    public override func perform(action: Action, completion: @escaping (_ success: Bool, _ nextTarget: UIElement?) -> Void) {
        switch action {
        case .launch(let bundleIdentifier):
            let app = ApplicationElement.from(bundleIdentifier: bundleIdentifier)
            app.open{
                success in
                completion(success, app)
            }
        default:
            completion(false, nil)
        }
    }
    
    public var launchedApplications = [ApplicationElement]()
    
    public func closeLaunchedApplications() {
        for application in launchedApplications {
            if (try? application.terminate()) == nil {
                os_log(.error, log: logger, "Failed to terminate application %{public}s", application.bundleIdentifier)
            }
        }
        launchedApplications = []
    }
    
    public func sendKey(keyCode: CGKeyCode, keyOptions: MorphicInput.KeyOptions) throws {
        try MorphicInput.sendKey(keyCode: CGKeyCode(keyCode), keyOptions: keyOptions, inputEventSource: .loginSession)
    }
}
