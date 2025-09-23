// Copyright 2020-2025 Raising the Floor - US, Inc.
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
import MorphicSettings

public class ZoomEnabledUIAutomation: UIAutomationSetSettingProxy {
    public required init() {
    }
    
    public func apply(_ value: Interoperable?) async throws {
        guard let valueAsBool = value as? Bool else {
            // invalid argument
            throw MorphicError.unspecified
        }
        
        let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
        try await self.setMagnifierIsOn(valueAsBool, waitAtMost: waitForTimespan)
    }
    
    public func setMagnifierIsOn(_ value: Bool, waitAtMost: TimeInterval) async throws {
        // set up a UIAutomationSequence so that cleanup can occur once the sequence goes out of scope (e.g. auto-terminate the app)
        let uiAutomationSequence = UIAutomationSequence()
        let waitAbsoluteDeadline = ProcessInfo.processInfo.systemUptime + waitAtMost

        // make sure that magnifier hotkeys are enabled
        do {
            let hotkeysEnabledAsOptional = try MorphicSettings.MagnifierZoomSettings.getHotkeysEnabled()
            guard let hotkeysEnabled = hotkeysEnabledAsOptional else {
                throw MorphicError.unspecified
            }
            
            if hotkeysEnabled == false {
                let waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
                try await AccessibilityZoomUIAutomationScript.setHotkeysEnabled(value, sequence: uiAutomationSequence, waitAtMost: waitForTimespan)
            }
        } catch let error {
            throw error
        }
        
        // deactivate the magnifier
        // NOTE: to gracefully degrade for the user, we'll allow the sending of the toggle hotkey to try to turn "off" the magnifier if the magnifier is on and also if we cannot determine its state
        let magnifierIsEnabledAsOptional = try MorphicSettings.MagnifierZoomSettings.getMagnifierEnabled()
        var shouldSendMagnifierToggleHotkey: Bool
        if value == true && magnifierIsEnabledAsOptional == false {
            shouldSendMagnifierToggleHotkey = true
        } else if value == false && (magnifierIsEnabledAsOptional == true || magnifierIsEnabledAsOptional == nil) {
            shouldSendMagnifierToggleHotkey = true
        } else {
            shouldSendMagnifierToggleHotkey = false
        }
        //
        if shouldSendMagnifierToggleHotkey {
            try MorphicSettings.MagnifierZoomSettings.sendMagnifierToggleZoomHotkey()

            let waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)

            // wait for the magnifier to show/hide
            let verifySuccess = try await AsyncUtils.wait(atMost: waitForTimespan) {
                guard let magnifierIsEnabled = try MorphicSettings.MagnifierZoomSettings.getMagnifierEnabled() else {
                    return false
                }

                return magnifierIsEnabled == value
            }
            
            if verifySuccess == false {
                throw MorphicError.unspecified
            }
        }
    }
}

public class ScrollToZoomEnabledUIAutomation: UIAutomationSetSettingProxy {
    public required init() {
    }
    
    public func apply(_ value: Interoperable?) async throws {
        guard let valueAsBool = value as? Bool else {
            // invalid argument
            throw MorphicError.unspecified
        }
        
        let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
        try await AccessibilityZoomUIAutomationScript.setUseScrollGestureWithModifierKeysToZoomIsOn(valueAsBool, waitAtMost: waitForTimespan)
    }
}

public class HoverTextEnabledUIAutomation: UIAutomationSetSettingProxy {
    public required init() {
    }
    
    public func apply(_ value: Interoperable?) async throws {
        guard let valueAsBool = value as? Bool else {
            // invalid argument
            throw MorphicError.unspecified
        }
        
        let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
        try await AccessibilityZoomUIAutomationScript.setHoverTextIsOn(valueAsBool, waitAtMost: waitForTimespan)
    }
}

public class TouchbarZoomEnabledUIAutomation: UIAutomationSetSettingProxy {
    public required init() {
    }
    
    public func apply(_ value: Interoperable?) async throws {
        guard let valueAsBool = value as? Bool else {
            // invalid argument
            throw MorphicError.unspecified
        }
        
        let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
        try await AccessibilityZoomUIAutomationScript.setUseTrackpadGestureToZoomIsOn(valueAsBool, waitAtMost: waitForTimespan)
    }
}

public class ZoomStyleUIAutomation: UIAutomationSetSettingProxy {
    public required init() {
    }
    
    public func apply(_ value: Interoperable?) async throws {
        guard let valueAsInt = value as? Int else {
            // invalid argument
            throw MorphicError.unspecified
        }
        
        let valueAsZoomStyle = MorphicSettings.MagnifierZoomSettings.ZoomStyle(fromIntValue: valueAsInt)
        
        let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
        try await AccessibilityZoomUIAutomationScript.setZoomStyle(valueAsZoomStyle, waitAtMost: waitForTimespan)
    }
}
