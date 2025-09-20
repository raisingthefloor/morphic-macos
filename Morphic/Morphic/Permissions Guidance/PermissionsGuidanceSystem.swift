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
import Foundation
import MorphicCore
import MorphicMacOSNative
import MorphicSettings

public protocol PermissionsWindowController: NSWindowController {
    func repositionOverSystemPreferencesWindow(bounds: CGRect, visible: Bool)
}
extension PermissionsWindowController {
    func repositionOverSystemPreferencesWindow(bounds: CGRect, visible: Bool) {
        guard let window = window,
              let screenFrame = window.screen?.frame else {
            return
        }
        
        // calculate an offset based on the height of the system preferences window
        let assumedFixedHeightOfSystemPreferencesWindow: CGFloat = 573
        let verticalPadding = bounds.height - assumedFixedHeightOfSystemPreferencesWindow
        
        let xval = bounds.minX
        let yval = screenFrame.maxY - bounds.minY - verticalPadding
        window.setFrameTopLeftPoint(NSPoint(x: xval, y: yval))
        
        window.setIsVisible(visible)
    }
}

public class PermissionsGuidanceSystem {
    public enum PermissionsGuidanceState {
        case inactive
        case waitingForSystemPreferencesLaunch
        case waitingForPermissionGrant
        case permissionGranted
    }
    
    public private(set) var currentState: PermissionsGuidanceState
    
    private static var singleton: PermissionsGuidanceSystem? = nil
    
    private var currentWindow: PermissionsWindowController?

    public static func startNew() {
        if PermissionsGuidanceSystem.singleton != nil {
            PermissionsGuidanceSystem.singleton?.shutdown()
            PermissionsGuidanceSystem.singleton = nil
        }
        
        PermissionsGuidanceSystem.singleton = PermissionsGuidanceSystem()
    }
    
    public static func stop() {
        PermissionsGuidanceSystem.singleton?.shutdown()
        PermissionsGuidanceSystem.singleton = nil
    }
    
    private init() {
        self.currentState = .inactive
        self.currentWindow = nil

        self.currentState = .waitingForSystemPreferencesLaunch
        
        if MorphicA11yAuthorization.authorizationStatus() == false {
            // call first iteration of updateLoop
            AsyncUtils.wait(atMost: 0.03, for: { false }) {_ in
                self.updateLoop()
            }
        }
    }
    
    private func shutdown() {
        self.currentWindow?.close()
        self.currentWindow = nil
        
        self.currentState = .inactive
    }
    
    private func swapWindow(to newWindow: PermissionsWindowController?, bounds: CGRect, visible: Bool) {
        self.currentWindow?.close()
        
        self.currentWindow = newWindow
        if newWindow != nil {
            self.currentWindow?.repositionOverSystemPreferencesWindow(bounds: bounds, visible: visible)
            self.currentWindow?.window?.makeKeyAndOrderFront(nil)
//            self.currentWindow?.window?.delegate = AppDelegate.shared
        }
    }
    
    private func updateLoop() {
//        let knownFixedHeightOfSystemPreferencesWindow: CGFloat = 573 // the correct window is this height on both Mojave and Catalina; on Big Sur the window dows not change when "Privacy" is selected; this value would need to be re-evaluated on future OS versions
        
        // get a list of all windows
        guard var windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: AnyObject]] else {
            return
        }
        
        // find the System Preferences window (and get its bounds)
        var systemPreferencesIsRunning = false
        var systemPreferencesWindowBounds: CGRect? = nil
        //
        for window in windows {
            if let windowOwnerName = window[kCGWindowOwnerName as String] as? String {
                if windowOwnerName == "System Preferences" {
                    systemPreferencesIsRunning = true
                    
                    if let boundsDictionary = window[kCGWindowBounds as String] {
                        systemPreferencesWindowBounds = CGRect.init(dictionaryRepresentation: boundsDictionary as! CFDictionary)
                    }
                }
            }
        }
        
        // filter out any windows which are not on top (i.e. not focused)
        windows = windows.filter { (window) -> Bool in
            guard let windowLayer = window[kCGWindowLayer as String] as? NSNumber else {
                return false
            }
            return (windowLayer == 0)
        }
        
        var systemPreferencesIsTopmost = false
        // determine if System Preferences is topmost
        if let topmostWindow = windows.first {
            if let windowOwnerName = topmostWindow[kCGWindowOwnerName as String] as? String {
                if windowOwnerName == "System Preferences" {
                    systemPreferencesIsTopmost = true
                }
            }
        }
        
        // filter out our own application's window(s)
        let morphicApplicationProcessId = Int(getpid())
        windows = windows.filter { (window) -> Bool in
            guard let windowProcessId = window[kCGWindowOwnerPID as String] as? Int else {
                return false
            }

            return (windowProcessId != morphicApplicationProcessId)
        }
        
        var newState: PermissionsGuidanceState? = nil
        
        // if we were in a state where system preferences was running (and now it is now), reset our state machine
        switch self.currentState {
        case .inactive,
             .waitingForSystemPreferencesLaunch:
            // nothing to do
            break
        case .waitingForPermissionGrant,
             .permissionGranted:
            // if the system preferences window has been closed, exit now
            if systemPreferencesIsRunning == false {
                PermissionsGuidanceSystem.stop()
                return
            }
        }
        
        switch self.currentState {
        case .inactive:
            // abort, as we have been reset
            return
        case .waitingForSystemPreferencesLaunch:
            if systemPreferencesWindowBounds != nil {
                newState = .waitingForPermissionGrant
            }
        case .waitingForPermissionGrant:
            if MorphicA11yAuthorization.authorizationStatus() == true {
                newState = .permissionGranted
            }
        case .permissionGranted:
            // nothing to do
            break
        }
        
        if let newState = newState {
            if self.currentState != newState {
                self.currentState = newState
                if let systemPreferencesWindowBounds = systemPreferencesWindowBounds {
                    var newWindow: PermissionsWindowController? = nil 
                    switch newState {
                    case .inactive,
                         .waitingForSystemPreferencesLaunch:
                        break
                    case .waitingForPermissionGrant:
                        newWindow = PermissionsGuidanceWindowController(windowNibName: "PermissionsGuidanceWindow")
                    case .permissionGranted:
                        newWindow = PermissionsSuccessWindowController(windowNibName: "PermissionsSuccessWindow")
                    }
                    self.swapWindow(to: newWindow, bounds: systemPreferencesWindowBounds, visible: systemPreferencesIsTopmost)
                }
            }
        } else {
            if let systemPreferencesWindowBounds = systemPreferencesWindowBounds {
                currentWindow?.repositionOverSystemPreferencesWindow(bounds: systemPreferencesWindowBounds, visible: systemPreferencesIsTopmost)
            }
        }

        // tail-call our updateLoop after 30ms
        AsyncUtils.wait(atMost: 0.03, for: { false }) {_ in
            self.updateLoop()
        }
    }
}
