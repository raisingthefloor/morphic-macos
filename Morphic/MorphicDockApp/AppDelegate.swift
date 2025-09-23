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
import MorphicSettings

class AppDelegate: NSObject, NSApplicationDelegate {
    var ignoreSingleApplicationActivation: Bool = false
    var isTerminatingDueToMorphicClientShutdown: Bool = false
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // capture the "terminateMorphicDockApp" message (to terminate the dock app when Morphic is shutting down)
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(AppDelegate.terminateMorphicDockApp), name: .terminateMorphicDockApp, object: nil)
        
        // if the app was launched by Morphic, ignore the first activation (so we don't send a "show MorphicBar" message to the main app)
        if CommandLine.arguments.contains("--ignoreFirstActivation") == true {
            ignoreSingleApplicationActivation = true
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // tell the Morphic Client app to terminate (if it didn't ask us to terminate...i.e. if the user terminated us)
        if isTerminatingDueToMorphicClientShutdown == false {
            DistributedNotificationCenter.default().postNotificationName(.terminateMorphicClientDueToDockAppTermination, object: nil, userInfo: nil, deliverImmediately: true)
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        if ignoreSingleApplicationActivation == true {
            ignoreSingleApplicationActivation = false
            // activate the topmost window (so that we lose focus, in case the user clicks the dock icon or cmd+tabs to us because they want to show the MorphicBar; otherwise we'd already have focus and clicking on or cmd+tabbing to us would fail to "activate" us)
            activateTopmostWindow()
            return
        }
        
        if morphicIsRunning() == true {
            // tell the Morphic Client app to show the Morphic bar
            DistributedNotificationCenter.default().postNotificationName(.showMorphicBarDueToDockAppActivation, object: nil, userInfo: nil, deliverImmediately: true)
            
            // NOTE: ideally we would only check this if our application was becoming active because it was clicked in the dock (i.e. pinned to the dock)
            // if the dock app shouldn't be running (i.e. dock and cmd+tab entries aren't appropriate), shut down now
            if shouldDockAppBeRunning() == false {
                terminateMorphicDockApp()
            }
        } else {
            // if the application isn't already running, launch it now
            
            // calculate the path to the main application's executable
            let dockAppBundlePath = Bundle.main.bundlePath as NSString
            var pathComponents = dockAppBundlePath.pathComponents
            // remove the last 3 components (.../Contents/Library/ Morphic .app) from the bundle path; the remaining path components will end the path at "Morphic###.app" (our application bundle entry point)
            pathComponents.removeLast(3)
            // NOTE: if we preferred to do so, we could instead remove the last three componeents and then append "MacOS" and "Morphic###" to the end of the path (to launch the application executable directly, vs. via Morphic###.app)
            let morphicClientApplicationPath = NSString.path(withComponents: pathComponents)
            
            // launch the main application
            // NOTE: this will behave identically to just starting up Morphic normally (which is our intention since we're covering the scenario that the dock icon was pinned and the intent is just to start up Morphic)
            // NOTE: in the future, we should try to distinguish between "user clicking on dock icon" and "user starting up application" so that clicking on the dock icon ALWAYS shows the MorphicBar
            _ = NSWorkspace.shared.launchApplication(morphicClientApplicationPath)
            
            // if the dock app shouldn't be running (i.e. dock and cmd+tab entries aren't appropriate), shut down now
            if shouldDockAppBeRunning() == false {
                terminateMorphicDockApp()
            }
        }
    }
    
    func morphicIsRunning() -> Bool {
        // determine if Morphic is already running
        let morphicApplications = NSWorkspace.shared.runningApplications.filter({
            application in
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
    
    func shouldDockAppBeRunning() -> Bool {
        return (NSWorkspace.shared.isVoiceOverEnabled == true) || (NSApplication.shared.isFullKeyboardAccessEnabled == true)
    }

    @objc
    func terminateMorphicDockApp() {
        // capture the "terminateMorphicDockApp" message (to terminate the dock app when Morphic is shutting down)

        // stop listening to this message (so we don't re-enter)
        DistributedNotificationCenter.default().removeObserver(self, name: .terminateMorphicDockApp, object: nil)
        
        // shutdown
        isTerminatingDueToMorphicClientShutdown = true
        NSApplication.shared.terminate(self)
    }
    
    func activateTopmostWindow() {
        // now, find the topmost application that is NOT us and give it focus :)
        // get the window ID of the topmost window
        guard let (_ /* topmostWindowOwnerName */, topmostProcessId) = MorphicWindow.getWindowOwnerNameAndProcessIdOfTopmostWindow() else {
            print("Could not get ID of topmost window")
            return
        }

        // capture a reference to the topmost application
        guard let topmostApplication = NSRunningApplication(processIdentifier: pid_t(topmostProcessId)) else {
            print("Could not get reference to application owning the topmost window")
            return
        }

        // activate the topmost application
        guard topmostApplication.activate(options: .activateIgnoringOtherApps) == true else {
            print("Could not activate the topmost window")
            return
        }

    }
}

extension NSNotification.Name {
    static let showMorphicBarDueToDockAppActivation = NSNotification.Name("org.raisingthefloor.showMorphicBarDueToDockAppActivation")
    static let terminateMorphicDockApp = NSNotification.Name(rawValue: "org.raisingthefloor.terminateMorphicDockApp")
    static let terminateMorphicClientDueToDockAppTermination = NSNotification.Name(rawValue: "org.raisingthefloor.terminateMorphicClientDueToDockAppTermination")
}
