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
import MorphicMacOSNative
import MorphicSettings

public class AccessibilityDisplayUIAutomationScript {
    // NOTE: this automation has not been tested as it does not appear to load from the solutions registry
    public static func setColorFiltersIntensity(_ value: Double, sequence: UIAutomationSequence? = nil, waitAtMost: TimeInterval) async throws {
        // verify that we have accessibility permissions (since UI automation will not work without them)
        try UIAutomationScriptUtils.verifyA11yAuthorization()
        
        // NOTE: due to a limitation (or temporary issue) in macOS 13, we are unable to set the exactly value of a slider; instead we move the slider to the value "closest to" the target
        try await Self.setAndVerifySliderValue(closestTo: value, forSliderWithIdentifier: SystemSettingsAccessibilityDisplayCategoryPane.Slider.colorFiltersIntensity, waitAtMost: waitAtMost)
    }
    
    public static func setColorFiltersAreEnabled(_ value: Bool, sequence: UIAutomationSequence? = nil, waitAtMost: TimeInterval) async throws {
        // verify that we have accessibility permissions (since UI automation will not work without them)
        try UIAutomationScriptUtils.verifyA11yAuthorization()
        
        try await Self.setAndVerifyCheckboxValue(value, forCheckboxWithIdentifier: SystemSettingsAccessibilityDisplayCategoryPane.Checkbox.colorFilters, waitAtMost: waitAtMost)
    }
    
    //
    
    public static func setDifferentiateWithoutColorIsOn(_ value: Bool, sequence: UIAutomationSequence? = nil, waitAtMost: TimeInterval) async throws {
        // verify that we have accessibility permissions (since UI automation will not work without them)
        try UIAutomationScriptUtils.verifyA11yAuthorization()

        try await Self.setAndVerifyCheckboxValue(value, forCheckboxWithIdentifier: SystemSettingsAccessibilityDisplayCategoryPane.Checkbox.differentiateWithoutColor, waitAtMost: waitAtMost)
    }


    //
    
    public static func setInvertColorsIsOn(_ value: Bool, sequence: UIAutomationSequence? = nil, waitAtMost: TimeInterval) async throws {
        // verify that we have accessibility permissions (since UI automation will not work without them)
        try UIAutomationScriptUtils.verifyA11yAuthorization()

        try await Self.setAndVerifyCheckboxValue(value, forCheckboxWithIdentifier: SystemSettingsAccessibilityDisplayCategoryPane.Checkbox.invertColors, waitAtMost: waitAtMost)
    }
    
    //
    
    public static func setInvertColorsMode(_ value: AccessibilityDisplaySettings.InvertColorsMode, sequence: UIAutomationSequence? = nil, waitAtMost: TimeInterval) async throws {
        // verify that we have accessibility permissions (since UI automation will not work without them)
        try UIAutomationScriptUtils.verifyA11yAuthorization()

        let radioButton: SystemSettingsAccessibilityDisplayCategoryPane.InvertColorsModeRadioButton
        switch value {
        case .classic:
            radioButton = .classic
        case .smart:
            radioButton = .smart
        }
        
        try await Self.selectAndVerifyRadioGroupButton(radioButton, forRadioGroupWithIdentifier: SystemSettingsAccessibilityDisplayCategoryPane.RadioGroup.invertColorsMode, waitAtMost: waitAtMost)
    }
    
    //

    public static func setPointerSize(_ value: Double, sequence: UIAutomationSequence? = nil, waitAtMost: TimeInterval) async throws {
        // verify that we have accessibility permissions (since UI automation will not work without them)
        try UIAutomationScriptUtils.verifyA11yAuthorization()
        
        // NOTE: due to a limitation (or temporary issue) in macOS 13, we are unable to set the exactly value of a slider; instead we move the slider to the value "closest to" the target
        try await Self.setAndVerifySliderValue(closestTo: value, forSliderWithIdentifier: SystemSettingsAccessibilityDisplayCategoryPane.Slider.pointerSize, waitAtMost: waitAtMost)
    }

    //
    
    public static func setReduceMotionIsOn(_ value: Bool, sequence: UIAutomationSequence? = nil, waitAtMost: TimeInterval) async throws {
        // verify that we have accessibility permissions (since UI automation will not work without them)
        try UIAutomationScriptUtils.verifyA11yAuthorization()

        try await Self.setAndVerifyCheckboxValue(value, forCheckboxWithIdentifier: SystemSettingsAccessibilityDisplayCategoryPane.Checkbox.reduceMotion, waitAtMost: waitAtMost)
    }
    
    //

    public static func getIncreaseContrastIsOn(sequence: UIAutomationSequence? = nil, waitAtMost: TimeInterval) async throws -> Bool {
        // verify that we have accessibility permissions (since UI automation will not work without them)
        try UIAutomationScriptUtils.verifyA11yAuthorization()

        let waitAbsoluteDeadline = ProcessInfo.processInfo.systemUptime + waitAtMost
        
        // step 1: launch the System Settings app and navigate to the Accessibility > Display pane
        let waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let accessibilityDisplayCategoryPane = try await Self.launchOrAttachSystemSettingsThenNavigativeToAccessibilityDisplay(sequence: sequence, waitFor: waitForTimespan)

        // step 2: check/uncheck the "Increase contrast" checkbox (if it is not already appropriately checked/unchecked)
        let increaseContrastIsEnabled = try accessibilityDisplayCategoryPane.getValue(forCheckboxWithIdentifier: SystemSettingsAccessibilityDisplayCategoryPane.Checkbox.increaseContrast)
        
        return increaseContrastIsEnabled
    }

    public static func setIncreaseContrastIsOn(_ value: Bool, sequence: UIAutomationSequence? = nil, waitAtMost: TimeInterval) async throws {
        // verify that we have accessibility permissions (since UI automation will not work without them)
        try UIAutomationScriptUtils.verifyA11yAuthorization()

        try await Self.setAndVerifyCheckboxValue(value, forCheckboxWithIdentifier: SystemSettingsAccessibilityDisplayCategoryPane.Checkbox.increaseContrast, waitAtMost: waitAtMost)
    }
    
    //

    public static func setReduceTransparencyIsOn(_ value: Bool, sequence: UIAutomationSequence? = nil, waitAtMost: TimeInterval) async throws {
        // verify that we have accessibility permissions (since UI automation will not work without them)
        try UIAutomationScriptUtils.verifyA11yAuthorization()

        try await Self.setAndVerifyCheckboxValue(value, forCheckboxWithIdentifier: SystemSettingsAccessibilityDisplayCategoryPane.Checkbox.reduceTransparency, waitAtMost: waitAtMost)
    }
    
    //
    
    public static func setShakeMousePointerToLocateIsOn(_ value: Bool, sequence: UIAutomationSequence? = nil, waitAtMost: TimeInterval) async throws {
        // verify that we have accessibility permissions (since UI automation will not work without them)
        try UIAutomationScriptUtils.verifyA11yAuthorization()

        try await Self.setAndVerifyCheckboxValue(value, forCheckboxWithIdentifier: SystemSettingsAccessibilityDisplayCategoryPane.Checkbox.shakeMousePointerToLocate, waitAtMost: waitAtMost)
    }
        
    public static func setColorFilterType(_ value: MorphicSettings.AccessibilityDisplaySettings.ColorFilterType, sequence: UIAutomationSequence? = nil, waitAtMost: TimeInterval) async throws {
        // verify that we have accessibility permissions (since UI automation will not work without them)
        try UIAutomationScriptUtils.verifyA11yAuthorization()

        let waitAbsoluteDeadline = ProcessInfo.processInfo.systemUptime + waitAtMost

        // check the current color filter type (in case it's not necessary to change anything)
        do {
            if let currentValue = try AccessibilityDisplaySettings.getColorFilterType() {
                // if there is nothing to change, return now
                if currentValue.intValue == value.intValue {
                    return
                }
            }
        } catch {
            // ignore any errors while trying to get color filter type
        }

        // step 1: launch the System Settings app and navigate to the Accessibility > Display pane
        var waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let accessibilityDisplayCategoryPane = try await Self.launchOrAttachSystemSettingsThenNavigativeToAccessibilityDisplay(sequence: sequence, waitFor: waitForTimespan)

        // step 2: set the value of the Color Filter section's "Filter type" drop-down
        guard let valueAsString = value.stringValue else {
            // if the requested value is not representable with a string (which we need so we can select the appropriate pop-up item), throw an error
            throw MorphicError.unspecified
        }
        waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        try await accessibilityDisplayCategoryPane.setValue(valueAsString, forPopUpButtonWithIdentifier: SystemSettingsAccessibilityZoomCategoryPane.PopUpButton.colorFilterType, waitAtMost: waitForTimespan)
        
        // step 3: verify that the value has been changed successfully
        let remainingWaitTime = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let verifySuccess = try await AsyncUtils.wait(atMost: remainingWaitTime) {
            let colorFilterTypeValue = try accessibilityDisplayCategoryPane.getValue(forPopUpButtonWithIdentifier: SystemSettingsAccessibilityZoomCategoryPane.PopUpButton.colorFilterType)
            return colorFilterTypeValue == valueAsString
        }
        if verifySuccess == false {
            // timeout occurred while waiting for pop-up to be confirmed as changed
            throw MorphicError.unspecified
        }
    }
    
    /* helper functions */

    private static func launchOrAttachSystemSettingsThenNavigativeToAccessibilityDisplay(sequence: UIAutomationSequence?, waitFor: TimeInterval) async throws -> SystemSettingsAccessibilityDisplayCategoryPane {
        let (categoryPane, launchedSystemSettingsApp) = try await SystemSettingsApp.launchOrAttachThenNavigateTo(.accessibilityDisplay, waitUntilFinishedLaunching: waitFor)
        if launchedSystemSettingsApp == true { sequence?.setScriptLaunchedApplicationFlag(bundleIdentifier: SystemSettingsApp.bundleIdentifier) }

        return categoryPane as! SystemSettingsAccessibilityDisplayCategoryPane
    }
    
    private static func setAndVerifyCheckboxValue(_ value: Bool, forCheckboxWithIdentifier a11yUIIdentifier: A11yUICheckboxIdentifier, sequence: UIAutomationSequence? = nil, waitAtMost: TimeInterval) async throws {
        let waitAbsoluteDeadline = ProcessInfo.processInfo.systemUptime + waitAtMost
                
        // step 1: launch the System Settings app and navigate to the Accessibility > Display pane
        let waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let accessibilityDisplayCategoryPane = try await Self.launchOrAttachSystemSettingsThenNavigativeToAccessibilityDisplay(sequence: sequence, waitFor: waitForTimespan)

        // step 2: check/uncheck the checkbox (if it is not already appropriately checked/unchecked)
        try accessibilityDisplayCategoryPane.setValue(value, forCheckboxWithIdentifier: a11yUIIdentifier)

        // step 3: verify that the value has been changed successfully
        let remainingWaitTime = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let verifySuccess = try await AsyncUtils.wait(atMost: remainingWaitTime) {
            let checkboxValue = try accessibilityDisplayCategoryPane.getValue(forCheckboxWithIdentifier: a11yUIIdentifier)
            return checkboxValue == value
        }
        if verifySuccess == false {
            // timeout occurred while waiting for checkbox to be confirmed as changed
            throw MorphicError.unspecified
        }
    }
    
    private static func setAndVerifySliderValue(closestTo value: Double, forSliderWithIdentifier a11yUIIdentifier: A11yUISliderIdentifier, sequence: UIAutomationSequence? = nil, waitAtMost: TimeInterval) async throws {
        let waitAbsoluteDeadline = ProcessInfo.processInfo.systemUptime + waitAtMost
                
        // step 1: launch the System Settings app and navigate to the Accessibility > Display pane
        let waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let accessibilityDisplayCategoryPane = try await Self.launchOrAttachSystemSettingsThenNavigativeToAccessibilityDisplay(sequence: sequence, waitFor: waitForTimespan)

        // step 2: get the slider's min and max values (to make sure the specified value is valid)
        let minValue = try accessibilityDisplayCategoryPane.getMinValue(forSliderWithIdentifier: a11yUIIdentifier)
        let maxValue = try accessibilityDisplayCategoryPane.getMaxValue(forSliderWithIdentifier: a11yUIIdentifier)
        if value < minValue || value > maxValue {
            throw MorphicError.unspecified
        }

        // step 3: set the slider's value to the closest value possible using increment/decrement actions (if it is not already appropriately set)
        // NOTE: previously, we set the value by setting the .value property of the control; however under macOS 13.0, this returns an AX ".failure" result; see ".setValue(_:forSliderWithIdentifier)" for notes; we should revisit this and try to get it to work with precise values
        let originalValue = try accessibilityDisplayCategoryPane.getValue(forSliderWithIdentifier: a11yUIIdentifier)
        //
        if originalValue == value {
            // if the value is already set to the target, return immediately
            return
        } else if originalValue < value {
            // if the target value is greater than the current value, increment it until we equal or are greater than the target value
            repeat {
                try accessibilityDisplayCategoryPane.incrementValue(forSliderWithIdentifier: a11yUIIdentifier)
                let newValue = try accessibilityDisplayCategoryPane.getValue(forSliderWithIdentifier: a11yUIIdentifier)
                if newValue >= value {
                    return
                }
            } while ProcessInfo.processInfo.systemUptime < waitAbsoluteDeadline
        } else /* if originalValue > value */ {
            // if the target value is less than the current value, decrement it until we equal or are less than the target value
            repeat {
                try accessibilityDisplayCategoryPane.decrementValue(forSliderWithIdentifier: a11yUIIdentifier)
                let newValue = try accessibilityDisplayCategoryPane.getValue(forSliderWithIdentifier: a11yUIIdentifier)
                if newValue <= value {
                    return
                }
            } while ProcessInfo.processInfo.systemUptime < waitAbsoluteDeadline
        }       
    }
    
    private static func selectAndVerifyRadioGroupButton(_ radioButtonLabel: A11yUIRadioButtonLabel, forRadioGroupWithIdentifier a11yUIIdentifier: A11yUIRadioGroupIdentifier, sequence: UIAutomationSequence? = nil, waitAtMost: TimeInterval) async throws {
        let waitAbsoluteDeadline = ProcessInfo.processInfo.systemUptime + waitAtMost
                
        // step 1: launch the System Settings app and navigate to the Accessibility > Display pane
        let waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let accessibilityDisplayCategoryPane = try await Self.launchOrAttachSystemSettingsThenNavigativeToAccessibilityDisplay(sequence: sequence, waitFor: waitForTimespan)

        // step 2: set the radio group's selection by selecting one of its child radio buttons
        try accessibilityDisplayCategoryPane.setSelectedRadioButton(radioButtonLabel, forRadioGroupWithIdentifier: a11yUIIdentifier)

        // step 3: verify that the radio group's selection  has been changed successfully
        let remainingWaitTime = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let verifySuccess = try await AsyncUtils.wait(atMost: remainingWaitTime) {
            let radioGroupSelectedRadioButton = try accessibilityDisplayCategoryPane.getSelectedRadioButton(forRadioGroupWithIdentifier: a11yUIIdentifier)

            // NOTE: while it's possible for a radio group to not have a selected value, that condition would equal "not set" in this instance
            guard let radioGroupSelectedRadioButton = radioGroupSelectedRadioButton else {
                return false
            }
            
            return radioGroupSelectedRadioButton == radioButtonLabel.a11yUILabel()
        }
        if verifySuccess == false {
            // timeout occurred while waiting for checkbox to be confirmed as changed
            throw MorphicError.unspecified
        }
    }
}
