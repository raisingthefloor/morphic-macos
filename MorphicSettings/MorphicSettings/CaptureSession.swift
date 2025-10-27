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

private let logger = OSLog(subsystem: "MorphicSettings", category: "CaptureSession")

/// Capture many values into a `Preferences` object
public class CaptureSession {
 
    /// Create a capture session for the given settings manager and preferences target
    ///
    /// The settings manager will be used to fetch `Setting` information and the preferences will
    /// be modified with the results of the capture upon calling `run()`
    public init(settingsManager: SettingsManager, preferences: Preferences) {
        self.settingsManager = settingsManager
        self.preferences = preferences
        keys = [Preferences.Key]()
    }
    
    /// The settings manager to use to lookup `Setting` objects
    public private(set) var settingsManager: SettingsManager
    
    /// Whether default values should be ignored or explicity set in the `preferences`
    public var captureDefaultValues: Bool = false
    
    /// The preference in which to save the results
    public var preferences: Preferences
    
    /// The keys that should be captured this session
    ///
    /// Intially an empty array, either set it yourself to capture values only for specific keys,
    /// or call `addAllSolutions()` to capture ever single known setting
    public var keys: [Preferences.Key]
    
    /// Add every single known setting to `keys` so they'll all be captured
    public func addAllSolutions() {
        for solution in settingsManager.solutions {
            for setting in solution.settings {
                let key = Preferences.Key(solution: solution.identifier, preference: setting.name)
                keys.append(key)
            }
        }
    }
    
    /// The remaining keys to capture
    private var keyQueue: [Preferences.Key]!
    
    /// Run the capture
    ///
    /// After the run is complete, you can inspect the `preferences` member for updates
    ///
    /// - parameters:
    ///   - completion: Called when the run is done
    public func run(completion: @escaping () -> Void) {
        guard keyQueue == nil else {
            return
        }
        keyQueue = keys.reversed()
        captureNextKey(completion: completion)
    }
    
    private func captureNextKey(completion: @escaping () -> Void) {
        guard keyQueue.count > 0 else{
            keyQueue = nil
            completion()
            return
        }
        let key = keyQueue.removeLast()
        guard let setting = settingsManager.setting(for: key) else {
            os_log(.info, log: logger, "Failed to find setting for %{public}s.%{public}s", key.solution, key.preference)
            captureNextKey(completion: completion)
            return
        }
        guard let handler = setting.createHandler() else {
            os_log(.info, log: logger, "Failed create handler for %{public}s.%{public}s", key.solution, key.preference)
            captureNextKey(completion: completion)
            return
        }
        handler.read{
            result in
            switch result {
            case .succeeded(let value):
                if self.captureDefaultValues || !setting.isDefault(value) {
                    self.preferences.set(value, for: key)
                } else {
                    self.preferences.remove(key: key)
                }
            case .failed:
                os_log(.info, log: logger, "Capture failed for %{public}s.%{public}s", key.solution, key.preference)
                break
            }
            self.captureNextKey(completion: completion)
        }
    }
    
}
