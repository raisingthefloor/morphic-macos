// Copyright 2020-2023 Raising the Floor - US, Inc.
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
import MorphicMacOSNative

public class PopUpButtonUIElement : UIElement {
    public let accessibilityUiElement: MorphicA11yUIElement
    
    public required init(accessibilityUiElement: MorphicA11yUIElement) {
        self.accessibilityUiElement = accessibilityUiElement
    }
    
    // actions
    
    public func getValue() throws -> String? {
        guard let value: String = try self.accessibilityUiElement.value(forAttribute: .value) else {
            return nil
        }
        
        return value
    }

    // NOTE: the press() function will simply pop open the element's menu    
    public func press() throws {
        try self.accessibilityUiElement.perform(action: .press)
    }
    
    public func setValue(_ value: String, waitAtMost: TimeInterval) async throws {
        let waitAbsoluteDeadline = ProcessInfo.processInfo.systemUptime + waitAtMost

        // pop up the menu
        // NOTE: the SwiftUI implementation of AXPopUpButton doesn't seem to support .showMenu properly: on some macOS versions the action is rejected, and on macOS 27.0 it is accepted but no menu appears (only .press opens the menu); so we try .showMenu first and, if it was rejected or produced no menu within a short grace period, we try .press
        var didPress = false
        do {
            try self.accessibilityUiElement.perform(action: .showMenu)
        } catch {
            // if "showMenu" was not accepted, then try ".press" instead
            // TODO: ideally we would capture the "action not available" error here to trigger the call to "press", and would otherwise pass through the original error
            do {
                try self.accessibilityUiElement.perform(action: .press)
            } catch let error {
                throw error
            }
            didPress = true
        }

        // wait for the menu to pop up
        var remainingWaitTimeInterval = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        //
        var menuUIElement: MenuUIElement? = nil
        let findMenu: () throws -> Bool = {
            let menuA11yUIElementAsOptional = try self.accessibilityUiElement.dangerousFirstDescendant(where: { a11yUIElement in
                a11yUIElement.role == .menu
            })

            guard let menuA11yUIElement = menuA11yUIElementAsOptional else {
                return false
            }

            menuUIElement = MenuUIElement(accessibilityUiElement: menuA11yUIElement)
            return true
        }
        if didPress == false {
            // give .showMenu a moment to produce the menu; if it does not (macOS 27.0), fall back to .press
            let showMenuGracePeriod: TimeInterval = 1.0
            let _ = try await AsyncUtils.wait(atMost: min(remainingWaitTimeInterval, showMenuGracePeriod), for: findMenu)
            if menuUIElement == nil {
                do {
                    try self.accessibilityUiElement.perform(action: .press)
                } catch let error {
                    throw error
                }
                remainingWaitTimeInterval = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
            }
        }
        if menuUIElement == nil {
            let _ = try await AsyncUtils.wait(atMost: remainingWaitTimeInterval, for: findMenu)
        }
        guard let menuUIElement = menuUIElement else {
            // timeout while getting our pop-up menu ui element
            throw MorphicError.unspecified
        }
        
        // select the menu item whose title matches the new value
        do {
            try menuUIElement.selectItem(titled: value)
        } catch let error {
            throw error
        }

        // wait for the new value to be committed
        remainingWaitTimeInterval = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let valueConfirmed = try await AsyncUtils.wait(atMost: remainingWaitTimeInterval) {
            guard let currentValue = try self.getValue() else {
                return false
            }
            
            return currentValue == value
        }
        if valueConfirmed == false {
            throw MorphicError.unspecified
        }
    }
}
