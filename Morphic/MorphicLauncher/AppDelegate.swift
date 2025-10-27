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

// NOTE: MorphicLauncher has been designed as a sandboxed app.  This should not affect the operatino of it or of the main Morphic client, and should help with future-proofing.

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private let terminateMorphicLauncherNotificationName = NSNotification.Name(rawValue: "org.raisingthefloor.terminateMorphicLauncher")
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if morphicIsRunning() == false {
            // if the application isn't already running, launch it now
            
            // calculate the path to the main application's executable
            let launcherBundlePath = Bundle.main.bundlePath as NSString
            var pathComponents = launcherBundlePath.pathComponents
            // remove the last 4 components (.../Contents/Library/LoginItems/MorphicLauncher.app) from the bundle path; the remaining path components will end the path at "Morphic###.app" (our application bundle entry point)
            pathComponents.removeLast(4)
            // NOTE: if we preferred to do so, we could instead remove the last three componeents and then append "MacOS" and "Morphic###" to the end of the path (to launch the application executable directly, vs. via Morphic###.app)
            let morphicClientApplicationPath = NSString.path(withComponents: pathComponents)
            
            // capture the "terminateMorphicLauncher" message (to terminate the launcher application once Morphic is launched)
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(AppDelegate.terminateMorphicLauncher), name: terminateMorphicLauncherNotificationName, object: nil)
            
            // launch the main application
            _ = NSWorkspace.shared.launchApplication(morphicClientApplicationPath)
        } else {
            // if the application is already running, simply terminate
            NSApplication.shared.terminate(self)
        }
    }

    func morphicIsRunning() -> Bool {
        // determine if Morphic is already running
        let morphicApplications = NSWorkspace.shared.runningApplications.filter({
            application in
            //
            switch application.bundleIdentifier {
            case "org.raisingthefloor.Morphic",
                 "org.raisingthefloor.Morphic-Debug":
                return true
            default:
                return false
            }
        })
        return (morphicApplications.count > 0)
    }
    
    @objc
    func terminateMorphicLauncher() {
        NSApplication.shared.terminate(self)
    }
}
