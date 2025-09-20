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
import MorphicSettings

public class IncreaseConstrastUIAutomationSetSettingProxy: UIAutomationSetSettingProxy {
    public required init() {
    }
    
    public func apply(_ value: Interoperable?) async throws {
        guard let valueAsBool = value as? Bool else {
            // invalid argument
            throw MorphicError.unspecified
        }

        // set up a UIAutomationSequence so that cleanup can occur once the sequence goes out of scope (e.g. auto-terminate the app)
        let sequence = UIAutomationSequence()

        let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
        try await setIncreaseContrast(valueAsBool, sequence: sequence, waitAtMost: waitForTimespan)
    }
    
    //

    public func setIncreaseContrast(_ value: Bool, sequence: UIAutomationSequence, waitAtMost: TimeInterval) async throws {
        let waitAbsoluteDeadline = ProcessInfo.processInfo.systemUptime + waitAtMost

        // capture the current state of the "increase contrast" and "reduce transparency" features
        // NOTE: before "increase contrast" is changed the first time, macOS will not have a default for this value (i.e. it defaults to "false")
        // TODO: if this method fails, perhaps we should use ui automation to try to retrieve the value?
        let increaseContrastIsEnabled = try MorphicSettings.AccessibilityDisplaySettings.getIncreaseContrastIsEnabled()

        // set the new "increase contrast" state
        if increaseContrastIsEnabled == nil || increaseContrastIsEnabled! != value {
            let waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
            try await AccessibilityDisplayUIAutomationScript.setIncreaseContrastIsOn(value, sequence: sequence, waitAtMost: waitForTimespan)
        }
        // verify that the state has changed
        // TODO: we probably want to refactor this into a standard function (which takes a closure as an argument) which we reuse in many places
        let waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let verifyIncreaseContrast = try await AsyncUtils.wait(atMost: waitForTimespan) {
            guard let verifyState = try MorphicSettings.AccessibilityDisplaySettings.getIncreaseContrastIsEnabled() else {
                return false
            }

            return verifyState == value
        }
        if verifyIncreaseContrast == false {
            // could not verify state change completion
            throw MorphicError.unspecified
        }

        // when turning off "increase contrast", also turn off "reduce transparency" (to match what Morphic v1.x for macOS did)
        if value == false {
            // NOTE: before "reduce transparency" is changed the first time, macOS will not have a default for this value (i.e. it defaults to "false")
            // TODO: if this method fails, perhaps we should use ui automation to try to retrieve the value?
            let reduceTransparencyIsEnabled = try MorphicSettings.AccessibilityDisplaySettings.getReduceTransparencyIsEnabled()

            let newReduceTransparencyIsEnabled = false

            if reduceTransparencyIsEnabled == nil || reduceTransparencyIsEnabled! != newReduceTransparencyIsEnabled {
                var waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
                try await AccessibilityDisplayUIAutomationScript.setReduceTransparencyIsOn(newReduceTransparencyIsEnabled, sequence: sequence, waitAtMost: waitForTimespan)
                // verify that the state has changed
                // TODO: we probably want to refactor this into a standard function (which takes a closure as an argument) which we reuse in many places
                waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
                let verifyReduceTransparency = try await AsyncUtils.wait(atMost: waitForTimespan) {
                    guard let verifyValue = try MorphicSettings.AccessibilityDisplaySettings.getReduceTransparencyIsEnabled() else {
                        return false
                    }

                    return verifyValue == newReduceTransparencyIsEnabled
                }
                if verifyReduceTransparency == false {
                    // could not verify "reduce transparency" value change
                    throw MorphicError.unspecified
                }
            }
        }
    }
}

public class IncreaseColorsUIAutomationSetSettingProxy: UIAutomationSetSettingProxy {
    public required init() {
    }
    
    public func apply(_ value: Interoperable?) async throws {
        guard let valueAsBool = value as? Bool else {
            // invalid argument
            throw MorphicError.unspecified
        }
        
        let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
        try await AccessibilityDisplayUIAutomationScript.setInvertColorsIsOn(valueAsBool, waitAtMost: waitForTimespan)
    }
}

public class InvertClassicUIAutomationSetSettingProxy: UIAutomationSetSettingProxy {
    public required init() {
    }
    
    public func apply(_ value: Interoperable?) async throws {
        guard let valueAsBool = value as? Bool else {
            // invalid argument
            throw MorphicError.unspecified
        }
        
        let valueAsInvertColorsMode: AccessibilityDisplaySettings.InvertColorsMode
        switch valueAsBool {
        case true:
            valueAsInvertColorsMode = .classic
        case false:
            valueAsInvertColorsMode = .smart
        }
        
        let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
        try await AccessibilityDisplayUIAutomationScript.setInvertColorsMode(valueAsInvertColorsMode, waitAtMost: waitForTimespan)
    }
}

public class ReduceMotionUIAutomationSetSettingProxy: UIAutomationSetSettingProxy {
    public required init() {
    }
    
    public func apply(_ value: Interoperable?) async throws {
        guard let valueAsBool = value as? Bool else {
            // invalid argument
            throw MorphicError.unspecified
        }
        
        let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
        try await AccessibilityDisplayUIAutomationScript.setReduceMotionIsOn(valueAsBool, waitAtMost: waitForTimespan)
    }
}

public class ReduceTransparencyUIAutomationSetSettingProxy: UIAutomationSetSettingProxy {
    public required init() {
    }
    
    public func apply(_ value: Interoperable?) async throws {
        guard let valueAsBool = value as? Bool else {
            // invalid argument
            throw MorphicError.unspecified
        }
        
        let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
        try await AccessibilityDisplayUIAutomationScript.setReduceTransparencyIsOn(valueAsBool, waitAtMost: waitForTimespan)
    }
}

public class DifferentiateWithoutColorUIAutomationSetSettingProxy: UIAutomationSetSettingProxy {
    public required init() {
    }
    
    public func apply(_ value: Interoperable?) async throws {
        guard let valueAsBool = value as? Bool else {
            // invalid argument
            throw MorphicError.unspecified
        }
        
        let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
        try await AccessibilityDisplayUIAutomationScript.setDifferentiateWithoutColorIsOn(valueAsBool, waitAtMost: waitForTimespan)
    }
}

public class CursorShakeUIAutomationSetSettingProxy: UIAutomationSetSettingProxy {
    public required init() {
    }
    
    public func apply(_ value: Interoperable?) async throws {
        guard let valueAsBool = value as? Bool else {
            // invalid argument
            throw MorphicError.unspecified
        }
        
        let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
        try await AccessibilityDisplayUIAutomationScript.setShakeMousePointerToLocateIsOn(valueAsBool, waitAtMost: waitForTimespan)
    }
}

public class CursorSizeUIAutomationSetSettingProxy: UIAutomationSetSettingProxy {
    public required init() {
    }
    
    public func apply(_ value: Interoperable?) async throws {
        guard let valueAsDouble = value as? Double else {
            // invalid argument
            throw MorphicError.unspecified
        }
        
        let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
        try await AccessibilityDisplayUIAutomationScript.setPointerSize(valueAsDouble, waitAtMost: waitForTimespan)
    }
}

public class ColorFilterEnabledUIAutomationSetSettingProxy: UIAutomationSetSettingProxy {
    public required init() {
    }
    
    public func apply(_ value: Interoperable?) async throws {
        guard let valueAsBool = value as? Bool else {
            // invalid argument
            throw MorphicError.unspecified
        }
        
        // implementation option 1: turn color filters on/off directly using API calls
        //
        // NOTE: in our current implementation, we have no method to determine success/failure of the operation
        MorphicDisplayAccessibilitySettings.setColorFiltersEnabled(valueAsBool)
        
//        // implementation option 2: turn color filters on/off using System Settings UI automation
//        //
//        let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
//        try await AccessibilityDisplayUIAutomationScript.setColorFiltersAreEnabled(valueAsBool, waitAtMost: waitForTimespan)
    }
    
}

public class ColorFilterTypeUIAutomationSetSettingProxy: UIAutomationSetSettingProxy {
    public required init() {
    }
    
    public func apply(_ value: Interoperable?) async throws {
        guard let valueAsInt = value as? Int else {
            // invalid argument
            throw MorphicError.unspecified
        }
        let valueAsColorFilterType = MorphicSettings.AccessibilityDisplaySettings.ColorFilterType(fromIntValue: valueAsInt)

        let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
        try await self.setColorFilterType(valueAsColorFilterType, waitAtMost: waitForTimespan)
    }
    
    public func setColorFilterType(_ value: MorphicSettings.AccessibilityDisplaySettings.ColorFilterType, waitAtMost: TimeInterval) async throws {
        // set up a UIAutomationSequence so that cleanup can occur once the sequence goes out of scope (e.g. auto-terminate the app)
        let uiAutomationSequence = UIAutomationSequence()
        let waitAbsoluteDeadline = ProcessInfo.processInfo.systemUptime + waitAtMost
        
        do {
            let waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
            try await AccessibilityDisplayUIAutomationScript.setColorFilterType(value, sequence: uiAutomationSequence, waitAtMost: waitForTimespan)
        } catch let error {
            throw error
        }
        
        // double-check that the setting has been set correctly (by reading the setting from the system defaults)
        let waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let verifySuccess = try await AsyncUtils.wait(atMost: waitForTimespan) {
            let currentColorFilterType = try MorphicSettings.AccessibilityDisplaySettings.getColorFilterType()
            return currentColorFilterType?.intValue == value.intValue
        }
        if verifySuccess == false {
            // timeout occurred while waiting for the change to be verified
            throw MorphicError.unspecified
        }
    }
}

// NOTE: this automation does not appear to load from the solutions registry
public class ColorFilterIntensityUIAutomation: UIAutomationSetSettingProxy {
    public required init() {
    }
    
    public func apply(_ value: Interoperable?) async throws {
        guard let valueAsDouble = value as? Double else {
            // invalid argument
            throw MorphicError.unspecified
        }
        
        let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
        try await AccessibilityDisplayUIAutomationScript.setColorFiltersIntensity(valueAsDouble, waitAtMost: waitForTimespan)
    }
}

