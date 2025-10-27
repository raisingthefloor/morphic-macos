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
import MorphicSettings
import SwiftUI

let registry = RegistryManager()

class SettingControl: ObservableObject, Identifiable
{
    @Published var name: String
    @Published var type: Setting.ValueType
    @Published var wrong: Bool
    @Published var changed: Bool
    @Published var loading: Bool
    @Published var displayVal: String
    @Published var displayBool: Bool {
        didSet {
            if val_bool != displayBool {
                changed = true
                if registry.autoApply {
                    checkVal(isStart: false)
                }
            }
        }
    }
    var val_bool: Bool
    var val_string: String
    var val_int: Int
    var val_double: Double
    var solutionName: String
    
    init(name: String, solname: String, type: Setting.ValueType, val_string: String = "", val_bool: Bool = false, val_double: Double = 0.0, val_int: Int = 0) {
        self.name = name
        self.type = type
        self.wrong = false
        self.changed = false
        self.loading = true
        self.solutionName = solname
        self.val_bool = val_bool
        self.val_double = val_double
        self.val_string = val_string
        self.val_int = val_int
        self.displayVal = ""
        self.displayBool = false
    }
    
    func copy() -> SettingControl {
        let copy = SettingControl(name: name, solname: solutionName, type: type)
        copy.val_bool = val_bool
        copy.val_int = val_int
        copy.val_string = val_string
        copy.val_double = val_double
        return copy
    }
    
    func checkVal(isStart: Bool) {
        wrong = false
        if isStart {return}
        changed = true
        switch type {
        case .string:
            val_string = displayVal
        case .integer:
            guard let ival = Int(displayVal) else {
                wrong = true
                return
            }
            val_int = ival
        case .double:
            guard let dval = Double(displayVal) else {
                wrong = true
                return
            }
            val_double = dval
        case .boolean:
            val_bool = displayBool
        }
        if registry.autoApply {
            apply(alreadyChecked: true)
        }
    }
    
    func apply(alreadyChecked: Bool = false) {
        self.loading = true
        if !changed {
            return
        }
        if !alreadyChecked {
            checkVal(isStart: false)
        }
        var val: Interoperable?
        switch type {
        case .string:
            val = val_string
        case .integer:
            val = val_int
        case .double:
            val = val_double
        case .boolean:
            val = val_bool
        }
        let sname = String(name)
        SettingsManager.shared.apply(val, for: Preferences.Key(solution: solutionName, preference: sname)) { success in
            DispatchQueue.main.async {
                if !success {
                    self.capture()
                } else {
                    self.loading = false
                }
            }
        }
    }
    
    func capture() {
        self.loading = true
        let sname = String(name)
        SettingsManager.shared.capture(valueFor: Preferences.Key(solution: solutionName, preference: sname)) { value in
            switch self.type {
            case .string:
                let v_string: String? = value as? String
                if v_string == nil {
                    return
                }
                self.val_string = v_string!
                self.displayVal = self.val_string
            case .boolean:
                guard let v_bool = value as? Bool else {
                    return
                }
                self.val_bool = v_bool
                self.displayBool = self.val_bool
            case .integer:
                guard let v_int = value as? Int else {
                    return
                }
                self.val_int = v_int
                self.displayVal = String(format: "%i", self.val_int)
            case .double:
                guard let v_double = value as? Double else {
                    return
                }
                self.val_double = v_double
                self.displayVal = String(format: "%f", self.val_double)
            }
            self.loading = false
            self.changed = false
            self.wrong = false
        }
    }
}

class SolutionCollection: ObservableObject, Identifiable
{
    @Published var name: String
    @Published var settings: [SettingControl]
    
    init(solutionName: String) {
        self.name = solutionName
        self.settings = [SettingControl]()
    }
    
    func copy() -> SolutionCollection {
        let copy = SolutionCollection(solutionName: name)
        for setting in settings {
            copy.settings.append(setting.copy())
        }
        return copy;
    }
    
    func applySettings() {
        for setting in self.settings {
            if setting.changed {
                setting.apply()
            }
        }
    }
    
    func captureSettings()
    {
        for setting in self.settings {
            setting.capture()
        }
    }
}

class RegistryManager: ObservableObject
{
    @Published var solutions: [SolutionCollection]
    @Published var load: String
    @Published var autoApply: Bool
    
    init() {
        load = "NO REGISTRY LOADED"
        autoApply = true
        solutions = [SolutionCollection]()
    }
    
    func loadSolution() {
        let fileDialog = NSOpenPanel()
        fileDialog.message = "Please select a solution registry JSON file to load:"
        fileDialog.showsResizeIndicator = true
        fileDialog.showsHiddenFiles = false
        fileDialog.allowsMultipleSelection = false
        fileDialog.canChooseDirectories = false
        if fileDialog.runModal() == NSApplication.ModalResponse.OK {
            if let solurl = fileDialog.url {
                let solpath: String = solurl.path
                SettingsManager.shared.populateSolutions(from: solurl)
                if SettingsManager.shared.solutions.isEmpty {
                    load = "ERROR, INVALID SOLUTION FILE. PLEASE TRY AGAIN."
                    return
                }
                solutions = [SolutionCollection]()
                for solution in SettingsManager.shared.solutions {
                    let collection = SolutionCollection(solutionName: solution.identifier)
                    for setting in solution.settings
                    {
                        collection.settings.append(SettingControl(name: setting.name, solname: solution.identifier, type: setting.type))
                    }
                    solutions.append(collection)
                }
                captureAllSettings()
                load = "Loaded file " + solpath
            }
        }
    }
    
    func applyAllSettings() {
        for solution in self.solutions {
            for setting in solution.settings {
                if setting.changed {
                    setting.apply()
                }
            }
        }
    }
    
    func captureAllSettings() {
        for solution in self.solutions {
            for setting in solution.settings {
                setting.capture()
            }
        }
    }
}
