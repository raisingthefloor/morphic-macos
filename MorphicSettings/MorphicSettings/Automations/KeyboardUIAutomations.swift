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

private let logger = OSLog(subsystem: "MorphicSettings", category: "KeyboardUIAutomation")

public class KeyboardUIAutomation: LegacyUIAutomation {
    public required init() {
    }
    
    public func apply(_ value: Interoperable?, completion: @escaping (Bool) -> Void) {
        fatalError("Not implemented")
    }
        
    public func showKeyboardPreferences(tabTitled tab: String, completion: @escaping (_ keyboard: KeyboardPreferencesElement?) -> Void) {
        let app = SystemPreferencesElement()
        app.open {
            success in
            guard success else {
                os_log(.error, log: logger, "Failed to open system preferences")
                completion(nil)
                return
            }
            app.showKeyboard {
                success, keyboard in
                guard success else {
                    os_log(.error, log: logger, "Failed to show Keyboard pane")
                    completion(nil)
                    return
                }
                guard let keyboard = keyboard else {
                    completion(nil)
                    return
                }
                // NOTE: at this point, keyboard.tabGroup is not always discoverable yet, so we wait a second for it to appear; this issue may occur elsewhere (so we should make this a more general check when we refactor the UI automation middleware code)
                AsyncUtils.wait(atMost: 1.0, for: { keyboard.tabGroup != nil }) {
                    success in
                    
                    guard success == true else {
                        os_log(.error, log: logger, "Could not find tab")
                        completion(nil)
                        return
                    }

                    guard let _ = try? keyboard.select(tabTitled: tab) else {
                        os_log(.error, log: logger, "Failed to select tab")
                        completion(nil)
                        return
                    }
                    completion(keyboard)
                }
            }
        }
    }
    
    public func showKeyboardShortcutsPreferences(categoryTitled: String, completion: @escaping (_ keyboard: KeyboardPreferencesElement?) -> Void) {
        showKeyboardPreferences(tabTitled: "Shortcuts") {
            keyboard in
            guard let keyboard = keyboard else {
                completion(nil)
                return
            }
            guard let _ = try? keyboard.select(tableRowTitled: categoryTitled, ofTableTitled: "Shortcuts categories") else {
                os_log(.error, log: logger, "Failed to select category (row)")
                completion(nil)
                return
            }
            completion(keyboard)
        }
    }

}
