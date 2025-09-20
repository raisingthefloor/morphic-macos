// Copyright 2023-2025 Raising the Floor - US, Inc.
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

import Cocoa
import MorphicCore
import MorphicMacOSNative

public class SystemSettingsGroupUIElementWrapper {
    internal private(set) var systemSettingsMainWindow: SystemSettingsMainWindow
    internal private(set) var groupUIElement: GroupUIElement
    
    internal required init(systemSettingsMainWindow: SystemSettingsMainWindow, groupUIElement: GroupUIElement) {
        self.systemSettingsMainWindow = systemSettingsMainWindow
        self.groupUIElement = groupUIElement
    }
    
    //
    
    internal func getValue(forCheckboxWithIdentifier checkboxIdentifier: A11yUICheckboxIdentifier) throws -> Bool {
        // STEP 1: find the MorphicA11yUIElement through its identifier; this will get the AXCheckbox element
        let a11yUIElement = try self.findA11yUIElementForIdentifier(checkboxIdentifier)
        
        // STEP 2: encapsulate the MorphicA11yUIElement into a CheckboxUIElement, then get its value
        let checkboxUIElement = CheckboxUIElement(accessibilityUiElement: a11yUIElement)
        //
        let resultAsOptional = try checkboxUIElement.getValue()
        if resultAsOptional == nil {
            // could not get the checkbox's value
            throw SystemSettingsApp.NavigationError.unspecified
        }
        let result = resultAsOptional!
        
        return result
    }
    
    internal func setValue(_ value: Bool, forCheckboxWithIdentifier checkboxIdentifier: A11yUICheckboxIdentifier) throws {
        // STEP 1: find the MorphicA11yUIElement through its identifier; this will get the AXCheckbox element
        let a11yUIElement = try self.findA11yUIElementForIdentifier(checkboxIdentifier)

        // STEP 2: convert the checkbox to a CheckboxUIElement, then set its value
        let checkboxUIElement = CheckboxUIElement(accessibilityUiElement: a11yUIElement)
        try checkboxUIElement.setValue(value)
    }
    
    //
    
    public func getValue(forPopUpButtonWithIdentifier popUpButtonIdentifier: A11yUIPopUpButtonIdentifier) throws -> String {
        // STEP 1: find the MorphicA11yUIElement through its identifier; this will get the AXPopUpButton element
        let a11yUIElement = try self.findA11yUIElementForIdentifier(popUpButtonIdentifier)

        // STEP 2: encapsulate the MorphicA11yUIElement into a PopUpButtonUIElement, then get its value
        let popUpButtonUIElement = PopUpButtonUIElement(accessibilityUiElement: a11yUIElement)
        //
        let resultAsOptional = try popUpButtonUIElement.getValue()
        if resultAsOptional == nil {
            // could not get the popUpButton's value
            throw SystemSettingsApp.NavigationError.unspecified
        }
        let result = resultAsOptional!
        
        return result
    }
    
    public func setValue(_ value: String, forPopUpButtonWithIdentifier popUpButtonIdentifier: A11yUIPopUpButtonIdentifier, waitAtMost: TimeInterval) async throws {
        let waitAbsoluteDeadline = ProcessInfo.processInfo.systemUptime + waitAtMost

        // STEP 1: find the MorphicA11yUIElement through its identifier; this will get the AXPopUpButton element
        let a11yUIElement = try self.findA11yUIElementForIdentifier(popUpButtonIdentifier)

        // STEP 2: convert the MorphicA11yUIElement to a PopUpButtonUIElement, then set its value
        let popUpButtonUIElement = PopUpButtonUIElement(accessibilityUiElement: a11yUIElement)
        //
        // NOTE: the value provided to this call is case-sensitive
        let waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        try await popUpButtonUIElement.setValue(value, waitAtMost: waitForTimespan)
    }

    //
    
    // NOTE: technically this function returns an optional String representing the label of the radio button, rather than returning the radio button's enum member value (as it cannot know which enum to use); in the future, we may want to consider returning a struct which contains "label: String" and "value: Int" members (assuming that the value of RadioButtons is always an Int)
    public func getSelectedRadioButton(forRadioGroupWithIdentifier radioGroupIdentifier: A11yUIRadioGroupIdentifier) throws -> String? {
        // STEP 1: find the MorphicA11yUIElement through its identifier; this will get the AXRadioGroup element
        let a11yUIElement = try self.findA11yUIElementForIdentifier(radioGroupIdentifier)

        // STEP 2: encapsulate the MorphicA11yUIElement into a RadioGroupUIElement, then get its max value
        let radioGroupUIElement = RadioGroupUIElement(accessibilityUiElement: a11yUIElement)
        //
        let resultAsOptional = try radioGroupUIElement.getSelectedRadioButton()
        return resultAsOptional
    }
    
    public func setSelectedRadioButton(_ radioButtonLabel: A11yUIRadioButtonLabel, forRadioGroupWithIdentifier radioGroupIdentifier: A11yUIRadioGroupIdentifier) throws {
        // STEP 1: find the MorphicA11yUIElement through its identifier; this will get the AXRadioGroup element
        let a11yUIElement = try self.findA11yUIElementForIdentifier(radioGroupIdentifier)

        // STEP 2: convert the MorphicA11yUIElement to a RadioGroupUIElement, then set its value
        let radioGroupUIElement = RadioGroupUIElement(accessibilityUiElement: a11yUIElement)
        //
        try radioGroupUIElement.setSelectedRadioButton(radioButtonLabel.a11yUILabel())
    }
    
    //

    public func getMaxValue(forSliderWithIdentifier sliderIdentifier: A11yUISliderIdentifier) throws -> Double {
        // STEP 1: find the MorphicA11yUIElement through its identifier; this will get the AXSlider element
        let a11yUIElement = try self.findA11yUIElementForIdentifier(sliderIdentifier)

        // STEP 2: encapsulate the MorphicA11yUIElement into a SliderUIElement, then get its max value
        let sliderUIElement = SliderUIElement(accessibilityUiElement: a11yUIElement)
        //
        let resultAsOptional = try sliderUIElement.getMaxValue()
        if resultAsOptional == nil {
            // could not get the slider's value
            throw SystemSettingsApp.NavigationError.unspecified
        }
        let result = resultAsOptional!
        
        return result
    }

    public func getMinValue(forSliderWithIdentifier sliderIdentifier: A11yUISliderIdentifier) throws -> Double {
        // STEP 1: find the MorphicA11yUIElement through its identifier; this will get the AXSlider element
        let a11yUIElement = try self.findA11yUIElementForIdentifier(sliderIdentifier)

        // STEP 2: encapsulate the MorphicA11yUIElement into a SliderUIElement, then get its min value
        let sliderUIElement = SliderUIElement(accessibilityUiElement: a11yUIElement)
        //
        let resultAsOptional = try sliderUIElement.getMinValue()
        if resultAsOptional == nil {
            // could not get the slider's value
            throw SystemSettingsApp.NavigationError.unspecified
        }
        let result = resultAsOptional!
        
        return result
    }

    public func getValue(forSliderWithIdentifier sliderIdentifier: A11yUISliderIdentifier) throws -> Double {
        // STEP 1: find the MorphicA11yUIElement through its identifier; this will get the AXSlider element
        let a11yUIElement = try self.findA11yUIElementForIdentifier(sliderIdentifier)

        // STEP 2: encapsulate the MorphicA11yUIElement into a SliderUIElement, then get its value
        let sliderUIElement = SliderUIElement(accessibilityUiElement: a11yUIElement)
        //
        let resultAsOptional = try sliderUIElement.getValue()
        if resultAsOptional == nil {
            // could not get the slider's value
            throw SystemSettingsApp.NavigationError.unspecified
        }
        let result = resultAsOptional!
        
        return result
    }
    
    public func decrementValue(forSliderWithIdentifier sliderIdentifier: A11yUISliderIdentifier) throws {
        // STEP 1: find the MorphicA11yUIElement through its identifier; this will get the AXSlider element
        let a11yUIElement = try self.findA11yUIElementForIdentifier(sliderIdentifier)

        // STEP 2: convert the MorphicA11yUIElement to a SliderUIElement, then decrement its value
        let sliderUIElement = SliderUIElement(accessibilityUiElement: a11yUIElement)
        //
        try sliderUIElement.decrement()
    }

    public func incrementValue(forSliderWithIdentifier sliderIdentifier: A11yUISliderIdentifier) throws {
        // STEP 1: find the MorphicA11yUIElement through its identifier; this will get the AXSlider element
        let a11yUIElement = try self.findA11yUIElementForIdentifier(sliderIdentifier)

        // STEP 2: convert the MorphicA11yUIElement to a SliderUIElement, then increment its value
        let sliderUIElement = SliderUIElement(accessibilityUiElement: a11yUIElement)
        //
        try sliderUIElement.increment()
    }

    //
    
    public func pressButton(forButtonWithLabel buttonLabel: A11yUIButtonLabel) throws {
        // STEP 1: find the button by its text
        let a11yUIElement = try self.findA11yUIElementForLabel(buttonLabel, requiredRole: .button)
        
        // STEP 2: convert the button to a ButtonUIElement and press it
        let buttonUIElement = ButtonUIElement(accessibilityUiElement: a11yUIElement)
        do {
            try buttonUIElement.press()
        } catch let error {
            throw error
        }
    }
    
    //
    
    /* helper functions */
    
    private func findA11yUIElementForIdentifier(_ identifier: A11yUIIdentifier) throws -> MorphicA11yUIElement {
        let a11yUIIdentifier = identifier.a11yUIIdentifier()
        //
        let a11yUIElement: MorphicA11yUIElement?
        do {
            a11yUIElement = try self.groupUIElement.accessibilityUiElement.descendant(identifier: a11yUIIdentifier)
        } catch let error {
            throw error
        }
        guard let a11yUIElement = a11yUIElement else {
            // could not find the a11y ui element
            throw SystemSettingsApp.NavigationError.unspecified
        }
        
        return a11yUIElement
    }
    
    private func findA11yUIElementForLabel(_ label: A11yUILabel, requiredRole: NSAccessibility.Role) throws -> MorphicA11yUIElement {
        let a11yUILabel = label.a11yUILabel()

        let a11yUIElement: MorphicA11yUIElement?
        do {
            // NOTE: the ui elements in dialogs tested so far are within a scroll view, potentially at various depths, etc.  Ideally we would navigate through a more specific hieratchy; for our initial implementation, we are choosing to find the element--but if we find that there are multiple ui elements with the specified role and we are locating the wrong one, then we should revise this code (or make more options in the function arguments list, etc.)
            a11yUIElement = try self.groupUIElement.accessibilityUiElement.dangerousFirstDescendant(where: {
                guard $0.role == requiredRole else {
                    return false
                }

                // NOTE: in our testing so far, the ui element label in dialogs is represented as the description value (i.e. not the title, and not the title ui element's value)
                // NOTE: if we cannot get the title of the label, we intentionally ignore the issue
                guard let description: String = try? $0.value(forAttribute: .description) else {
                    return false
                }

                return description == a11yUILabel
            })
        } catch let error {
            throw error
        }
        guard let a11yUIElement = a11yUIElement else {
            // could not find the a11y ui element
            throw SystemSettingsApp.NavigationError.unspecified
        }
        
        return a11yUIElement
    }

}
