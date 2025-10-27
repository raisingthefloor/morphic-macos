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

private let logger = OSLog(subsystem: "MorphicSettings", category: "GeneralUIAutomations")

public class GeneralUIAutomation: LegacyUIAutomation {
    
    public required init() {
    }
    
    public func apply(_ value: Interoperable?, completion: @escaping (Bool) -> Void) {
        fatalError("Not implemented")
    }

    public func showGeneralPreferences(completion: @escaping (_ general: GeneralPreferencesElement?) -> Void) {
        let app = SystemPreferencesElement()
        app.open {
            success in
            guard success else {
                os_log(.error, log: logger, "Failed to open system preferences")
                completion(nil)
                return
            }
            app.showGeneral {
                success, general in
                guard success else {
                    os_log(.error, log: logger, "Failed to show General pane")
                    completion(nil)
                    return
                }
                
                // wait for the appearance pane to appear
                AsyncUtils.wait(atMost: 1.0, for: { general?.checkbox(titled: "Light") != nil }) {
                    success in
                    completion(general)
                }
            }
        }
    }
}

public class GeneralCheckboxUIAutomation: GeneralUIAutomation {
    
    var checkboxTitle: String! { nil }

    public override func apply(_ value: Interoperable?, completion: @escaping (Bool) -> Void) {
        guard let checked = value as? Bool else {
            os_log(.error, log: logger, "Passed non-boolean value to checkbox")
            completion(false)
            return
        }
        showGeneralPreferences() {
            general in
            guard let general = general else {
                completion(false)
                return
            }
            guard let checkbox = general.checkbox(titled: self.checkboxTitle) else {
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

public class LightAppearanceUIAutomation: GeneralCheckboxUIAutomation {
    override var checkboxTitle: String! { "Light" }
}

public class DarkAppearanceUIAutomation: GeneralCheckboxUIAutomation {
    override var checkboxTitle: String! { "Dark" }
}

public class AutoAppearanceUIAutomation: GeneralCheckboxUIAutomation {
    override var checkboxTitle: String! { "Auto" }
}
