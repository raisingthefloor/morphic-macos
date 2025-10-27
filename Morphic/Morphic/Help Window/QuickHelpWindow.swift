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

/// The large tooltip-like window that displays help about MorphicBar actions
///
/// Uses a `QuickHelpViewController` as its `contentViewController`
class QuickHelpWindow: NSWindow {
    
    /// Create a new Quick Help Window with a `QuickHelpViewController` as its `contentViewController`
    private init() {
        super.init(contentRect: NSMakeRect(0, 0, 100, 100), styleMask: .borderless, backing: .buffered, defer: false)
        hasShadow = true
        isReleasedWhenClosed = false
        level = .floating
        backgroundColor = .clear
        isMovableByWindowBackground = false
        collectionBehavior = [.canJoinAllSpaces]
        ignoresMouseEvents = true
    }
    
    /// Only a single Quick Help Window is displayed at a time
    private static var shared: QuickHelpWindow?
    
    /// Create or update the shared Quick Help Window with the given title and message
    ///
    /// - parameters:
    ///   - title: The text to show in the view controller's `titleLabel`
    ///   - message: The text to show in the view controller's `messageLabel`
    public static func show(viewController: NSViewController) {
        if shared == nil {
            shared = QuickHelpWindow()
            shared?.delegate = delegate
        }
        shared?.contentViewController = viewController;
        shared?.makeKeyAndOrderFront(nil)
        shared?.hideQueued = false
        shared?.reposition()
        shared?.invalidateShadow()  // required to avoid artifacts after changing text
    }
    
    /// Indicates that a hide was requested and will happen soon unless a subsequent `show()` is
    /// called resestting this flag
    private var hideQueued = false
    
    /// Request that the shared window hide
    ///
    /// Since the user is likely to be moving from the button calling `hide()` to another that will call
    /// `show()`, the window doesn't close until a short delay has passed without a `show()` call.
    public static func hide(withoutDelay: Bool = false, completion: (() -> Void)? = nil) {
        shared?.hideQueued = true
        if withoutDelay == false {
            DispatchQueue.main.async {
                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) {
                    timer in
                    if shared?.hideQueued ?? false {
                        shared?.close()
                        shared = nil
                    }
                    completion?()
                }
            }
        } else {
            DispatchQueue.main.async {
                shared?.close()
                shared = nil
                completion?()
            }
        }
    }
    
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
    
    /// Center the window in the screen
    func reposition() {
        // NOTE: due to a limitation in Morphic 1.x, we use the current mouse pointer location as a proxy for the screen on which the
        //       Morphic bar is currently shown; in the future, we should get the current display for the MorphicBar WINDOW instead
        guard let mousePointerLocation = MorphicSettings.MorphicMouse.getCurrentLocation() else {
            assertionFailure("Could not locate the mouse pointer")
            return
        }
        guard let display = Display.displayContainingPoint(mousePointerLocation) else {
            assertionFailure("Could not determine which display contains the mouse pointer")
            return
        }
        
        guard let screen = display.screen() else {
            return
        }
        
        // NOTE: rather than setting the window frame's origin to "screen.visibleFrame.origin", we're adjusting the frame position in the RECT directly; if this causes us troubles in the future (i.e. if our origin is not 0,0), consider setting self.setFrameOrigin with values of all-zeros

        let frame = NSRect(x: screen.frame.origin.x + round((screen.frame.width - self.frame.size.width) / 2), y: screen.frame.origin.y + round((screen.frame.height - self.frame.size.height) / 2), width: self.frame.size.width, height: self.frame.size.height)
        self.setFrame(frame, display: true, animate: false)
    }
    
    class Delegate: NSObject, NSWindowDelegate {
        
        func windowDidChangeScreen(_ notification: Notification) {
            guard let window = notification.object as? QuickHelpWindow else {
                return
            }
            window.reposition()
        }
        
    }
    
    private static var delegate = Delegate()
}
