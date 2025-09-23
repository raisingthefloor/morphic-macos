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
import MorphicCore
import MorphicService

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Storage.setApplicationSupportDirectoryName("org.raisingthefloor.MorphicBasic")
        UserDefaults.setMorphicSuiteName("org.raisingthefloor.MorphicBasic")

        // TODO: this needs to be consolidated with the main application; we are not taking into account config.json here!
        Session.shared.isCaptureAndApplyEnabled = true
        Session.shared.isServerPreferencesSyncEnabled = true

        populateSolutions()
        Session.shared.open {
            for arg in ProcessInfo.processInfo.arguments[1...] {
                if arg == "login" {
                    self.showLoginWindow(nil)
                    break
                }
                if arg == "capture" {
                    self.showCaptureWindow(nil)
                    break
                }
            }
        }
    }
    
    func populateSolutions() {
        Session.shared.settings.populateSolutions(fromResource: "macos.solutions")
    }
    
//    func application(_ application: NSApplication, open urls: [URL]) {
//        if let url = urls.first {
//            switch url.path {
//            case "login":
//                captureWindowController?.close()
//                showLoginWindow(nil)
//            case "capture":
//                loginWindowController?.close()
//                showCaptureWindow(nil)
//            default:
//                break
//            }
//        }
//    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    var loginWindowController: NSWindowController?
    
    func showLoginWindow(_ sender: Any?) {
        if loginWindowController == nil {
            loginWindowController = LoginWindowController(windowNibName: "LoginWindow")
        }
        loginWindowController?.window?.makeKeyAndOrderFront(sender)
        loginWindowController?.window?.delegate = self
    }
    
    var captureWindowController: NSWindowController?
    
    func showCaptureWindow(_ sender: Any?) {
        if captureWindowController == nil {
            captureWindowController = CaptureWindowController(windowNibName: "CaptureWindow")
        }
        captureWindowController?.window?.makeKeyAndOrderFront(sender)
        captureWindowController?.window?.delegate = self
    }
    
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else {
            return
        }
        if window == captureWindowController?.window {
            captureWindowController = nil
        }
        if window == loginWindowController?.window {
            loginWindowController = nil
        }
    }
}

