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

//import Cocoa
import MorphicCore
import OSLog

private let logger = OSLog(subsystem: "MorphicSettings", category: "SpeechUIAutomations")

public class SpeechCheckboxUIAutomation: AccessibilityUIAutomation {

    var checkboxTitle: String! { nil }

    public override func apply(_ value: Interoperable?, completion: @escaping (Bool) -> Void) {
        guard let checked = value as? Bool else {
            os_log(.error, log: logger, "Passed non-boolean value")
            completion(false)
            return
        }
        showAccessibilitySpeechPreferences {
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
                os_log(.error, log: logger, "Failed to check checkbox")
                completion(false)
                return
            }
            completion(true)
        }

    }

}

public class SpeakSelectedTextEnabledUIAutomation: SpeechCheckboxUIAutomation {

    override var checkboxTitle: String! {
        return "Speak selection"
    }

}
