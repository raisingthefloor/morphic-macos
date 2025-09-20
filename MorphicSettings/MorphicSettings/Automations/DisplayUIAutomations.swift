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

import Foundation
import MorphicCore
import OSLog

private let logger = OSLog(subsystem: "MorphicSettings", category: "DisplayUIAutomations")

public class DisplayCheckboxUIAutomation: AccessibilityUIAutomation {
    
    var tabTitle: String! { nil }
    var checkboxTitle: String! { nil }

    public override func apply(_ value: Interoperable?, completion: @escaping (Bool) -> Void) {
        guard let checked = value as? Bool else {
            os_log(.error, log: logger, "Passed non-boolean value to checkbox")
            completion(false)
            return
        }
        showAccessibilityDisplayPreferences(tab: self.tabTitle) {
            accessibility in
            guard let accessibility = accessibility else {
                completion(false)
                return
            }
            guard let checkbox = accessibility.checkbox(titled: self.checkboxTitle) else {
                os_log(.error, log: logger, "Failed to find checkbox")
                completion(false)
                return
            }
            guard let _ = try? checkbox.setChecked(checked) else {
                os_log(.error, log: logger, "Failed to press checkbox")
                completion(false)
                return
            }
            completion(true)
        }
    }
    
}

public class DisplaySliderUIAutomation: AccessibilityUIAutomation {
    
    var tabTitle: String! { nil }
    var sliderTitle: String! { nil }

    public override func apply(_ value: Interoperable?, completion: @escaping (Bool) -> Void) {
        if let intValue = value as? Int {
            apply(Double(intValue), completion: completion)
            return
        }
        guard let value = value as? Double else {
            os_log(.error, log: logger, "Passed non-double value to slider")
            completion(false)
            return
        }
        showAccessibilityDisplayPreferences(tab: self.tabTitle) {
            accessibility in
            guard let accessibility = accessibility else {
                completion(false)
                return
            }
            guard let slider = accessibility.slider(titled: self.sliderTitle) else {
                os_log(.error, log: logger, "Failed to find slider")
                completion(false)
                return
            }
            guard let _ = try? slider.setValue(value) else {
                os_log(.error, log: logger, "Failed to update slider value")
                completion(false)
                return
            }
            completion(true)
        }
    }
    
}

public class ContrastUIAutomation: AccessibilityUIAutomation {
    
    public override func apply(_ value: Interoperable?, completion: @escaping (Bool) -> Void) {
        guard let checked = value as? Bool else {
            os_log(.error, log: logger, "Passed non-boolean value to contrast")
            completion(false)
            return
        }
        showAccessibilityDisplayPreferences(tab: "Display") {
            accessibility in
            guard let accessibility = accessibility else {
                completion(false)
                return
            }
            guard let checkbox = accessibility.checkbox(titled: "Increase contrast") else {
                os_log(.error, log: logger, "Failed to find contrast checkbox")
                completion(false)
                return
            }
            guard let _ = try? checkbox.setChecked(checked) else {
                os_log(.error, log: logger, "Failed to press contrast checkbox")
                completion(false)
                return
            }
            if !checked {
                if let transparencyCheckbox = accessibility.checkbox(titled: "Reduce transparency") {
                    if (try? transparencyCheckbox.uncheck()) == nil {
                        os_log(.info, log: logger, "Failed to uncheck reduce transparency when turning off high contrast")
                    }
                }
            }
            completion(true)
        }
    }
    
}

public class DisplayPopupButtonUIAutomation: AccessibilityUIAutomation {
    
    var tabTitle: String! { nil }
    var buttonTitle: String! { nil }
    
    var optionTitles: [Int: String]! { nil }
    
    public override func apply(_ value: Interoperable?, completion: @escaping (Bool) -> Void) {
        guard let value = value as? Int else {
            os_log(.error, log: logger, "Passed non-int value to popup")
            completion(false)
            return
        }
        guard let stringValue = optionTitles[value] else {
            os_log(.error, log: logger, "Passed invalid int value to popup")
            completion(false)
            return
        }
        showAccessibilityDisplayPreferences(tab: tabTitle) {
            accessibility in
            guard let accessibility = accessibility else {
                completion(false)
                return
            }
            guard let button = accessibility.popUpButton(titled: self.buttonTitle) else {
                os_log(.error, log: logger, "Failed to find popup button")
                completion(false)
                return
            }
            button.setValue(stringValue) {
                success in
                guard success else {
                    os_log(.error, log: logger, "Failed to set popup button value")
                    completion(false)
                    return
                }
                completion(true)
            }
        }
        
    }
    
}

public class InvertColorsUIAutomation: DisplayCheckboxUIAutomation {
    
    override var tabTitle: String! { "Display" }
    override var checkboxTitle: String! { "Invert colors" }
    
}

public class InvertClassicUIAutomation: DisplayCheckboxUIAutomation {
    
    override var tabTitle: String! { "Display" }
    override var checkboxTitle: String! { "Classic Invert" }
    
}

public class ReduceMotionUIAutomation: DisplayCheckboxUIAutomation {
    
    override var tabTitle: String! { "Display" }
    override var checkboxTitle: String! { "Reduce motion" }
    
}

public class ReduceTransparencyUIAutomation: DisplayCheckboxUIAutomation {
    
    override var tabTitle: String! { "Display" }
    override var checkboxTitle: String! { "Reduce transparency" }
    
}

public class DifferentiateWithoutColorUIAutomation: DisplayCheckboxUIAutomation {
    
    override var tabTitle: String! { "Display" }
    override var checkboxTitle: String! { "Differentiate without color" }
    
}

public class CursorShakeUIAutomation: DisplayCheckboxUIAutomation {
    
    override var tabTitle: String! { "Cursor" }
    override var checkboxTitle: String! { "Shake mouse pointer to locate" }
    
}

public class CursorSizeUIAutomation: DisplaySliderUIAutomation {
    
    override var tabTitle: String! { "Cursor" }
    override var sliderTitle: String! { "Cursor size:" }
    
}

public class ColorFilterEnabledAutomation: DisplayCheckboxUIAutomation {
    
    override var tabTitle: String! { "Color Filters" }
    override var checkboxTitle: String! { "Enable Color Filters" }
    
}

// Type Popup isn't properly labeled
public class ColorFilterTypeAutomation: AccessibilityUIAutomation {
    
    var optionTitles: [Int : String]! {
        [
            1: "Grayscale",
            2: "Red/Green filter (Protanopia)",
            4: "Green/Red filter (Deuteranopia)",
            8: "Blue/Yellow filter (Tritanopia)",
            16: "Color Tint"
        ]
    }
    
    public override func apply(_ value: Interoperable?, completion: @escaping (Bool) -> Void) {
        guard let value = value as? Int else {
            os_log(.error, log: logger, "Passed non-int value to popup")
            completion(false)
            return
        }
        guard let stringValue = optionTitles[value] else {
            os_log(.error, log: logger, "Passed invalid int value to popup")
            completion(false)
            return
        }
        showAccessibilityDisplayPreferences(tab: "Color Filters") {
            accessibility in
            guard let accessibility = accessibility else {
                completion(false)
                return
            }
            guard let button = accessibility.firstPopupButton() else {
                os_log(.error, log: logger, "Failed to find popup button")
                completion(false)
                return
            }
            button.setValue(stringValue) {
                success in
                guard success else {
                    os_log(.error, log: logger, "Failed to set popup button value")
                    completion(false)
                    return
                }
                completion(true)
            }
        }
        
    }
    
}

// Intensity Slider isn't properly labeled
class ColorFilterIntensityUIAutomation: AccessibilityUIAutomation {

    public override func apply(_ value: Interoperable?, completion: @escaping (Bool) -> Void) {
        if let intValue = value as? Int {
            apply(Double(intValue), completion: completion)
            return
        }
        guard let value = value as? Double else {
            os_log(.error, log: logger, "Passed non-double value to slider")
            completion(false)
            return
        }
        showAccessibilityDisplayPreferences(tab: "Color Filters") {
            accessibility in
            guard let accessibility = accessibility else {
                completion(false)
                return
            }
            guard let slider = accessibility.firstSlider() else {
                os_log(.error, log: logger, "Failed to find slider")
                completion(false)
                return
            }
            guard let _ = try? slider.setValue(value) else {
                os_log(.error, log: logger, "Failed to update slider value")
                completion(false)
                return
            }
            completion(true)
        }
    }
}
