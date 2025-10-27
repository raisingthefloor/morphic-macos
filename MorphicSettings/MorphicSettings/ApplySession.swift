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

private let logger = OSLog(subsystem: "MorphicSettings", category: "ApplySession")

/// Apply many settings in one session
///
/// Apply sessions can take advantage of `SettingFinalizer`s and only perform certain operations once
/// instead of once-per-setting.  This is useful for things like writing files or calling refresh functions
public class ApplySession {
    
    /// Create an apply session for the given settings manager and values
    ///
    /// The settings manager will be used to fetch `Setting` information
    ///
    /// - parameters:
    ///   - settingsManager: The settings manager to use when looking up `Setting`s
    ///   - valuesByKey: The values to apply in this session
    public required init(settingsManager: SettingsManager, keyValueTuples: [(Preferences.Key, Interoperable?)]) {
        self.settingsManager = settingsManager
        self.keyValueTuples = keyValueTuples
    }
    
    /// Create an apply session for the given settings manager and preferences
    ///
    /// Convenience method that extracts values from preferences
    public convenience init(settingsManager: SettingsManager, preferences: Preferences) {
        self.init(settingsManager: settingsManager, keyValueTuples: preferences.keyValueTuples())
    }
    
    /// The values to apply for in session
    public var keyValueTuples: [(Preferences.Key, Interoperable?)]
    
    public func add(key: Preferences.Key, value: Interoperable?) {
        keyValueTuples.append((key, value))
    }
    
    public func addFirst(key: Preferences.Key, value: Interoperable?) {
        keyValueTuples.insert((key, value), at: 0)
    }
    
    /// The results for each individual setting
    ///
    /// - note: if a key doesn't have a result, you can assume it failed
    public private(set) var results = [Preferences.Key: Bool]()
       
    /// The settings manager to use to lookup `Setting` objects
    public private(set) var settingsManager: SettingsManager
    
    /// The remaining keys to apply
    private var keyValueQueue: [(Preferences.Key, Interoperable?)]!
    
    /// The remaining finalizers to run
    private var finalizerQueue: [SettingFinalizerDescription]!
    
    public func addDefaultValuesFromAllSolutions() {
        let valuesByKey = [Preferences.Key: Interoperable?].init(uniqueKeysWithValues: keyValueTuples)
        for solution in settingsManager.solutions {
            for setting in solution.settings {
                let key = Preferences.Key(solution: solution.identifier, preference: setting.name)
                if valuesByKey[key] == nil {
                    if let defaultValue = setting.defaultValue {
                        keyValueTuples.append((key, defaultValue))
                    }
                }
            }
        }
    }
    
    /// Apply each setting and then call the completion handler
    ///
    /// - parameters:
    ///   - completion: Called when all the setting apply calls have completed
    public func run(completion: @escaping () -> Void) {
        guard keyValueQueue == nil else{
            os_log(.info, log: logger, "Calling .run() before previous run finished")
            return
        }
        
        WorkspaceElement.shared.launchedApplications = []
        
        // Figure out which unique finalizers need to run
        finalizerQueue = [SettingFinalizerDescription]()
        var seenFinalizers = Set<String>()
        for pair in keyValueTuples {
            let key = pair.0
            guard let setting = settingsManager.setting(for: key) else {
                // os_log(.info, log: logger, "Cannot find setting for %{public}s.%{public}s", key.solution, key.preference)
                continue
            }
            if let description = setting.finalizerDescription {
                if !seenFinalizers.contains(description.uniqueRepresentation) {
                    seenFinalizers.insert(description.uniqueRepresentation)
                    finalizerQueue.append(description)
                }
            }
        }
        
        // Start applying
        keyValueQueue = keyValueTuples.reversed()
        applyNextKey(completion: completion)
    }
    
    /// Apply a single setting
    private func applyNextKey(completion: @escaping () -> Void) {
        guard keyValueQueue.count > 0 else {
            callNextFinalizer(completion: completion)
            return
        }
        let pair = keyValueQueue.removeLast()
        let key = pair.0
        let value = pair.1
        guard let setting = settingsManager.setting(for: key) else {
             os_log(.info, log: logger, "Cannot find setting for %{public}s.%{public}s", key.solution, key.preference)
            applyNextKey(completion: completion)
            return
        }
        guard let handler = setting.createHandler() else {
            os_log(.info, log: logger, "Cannot create handler for %{public}s.%{public}s", key.solution, key.preference)
            applyNextKey(completion: completion)
            return
        }
        handler.apply(value) {
            success in
            if !success{
                os_log(.info, log: logger, "Failed to apply %{public}s.%{public}s", key.solution, key.preference)
            }
            self.results[key] = success
            self.applyNextKey(completion: completion)
        }
    }
    
    /// Call a single finalizer
    private func callNextFinalizer(completion: @escaping () -> Void) {
        guard finalizerQueue.count > 0 else{
            keyValueQueue = nil
            finalizerQueue = nil
            WorkspaceElement.shared.closeLaunchedApplications()
            completion()
            return
        }
        let description = finalizerQueue.removeLast()
        guard let finalizer = SettingFinalizer.create(from: description) else {
            callNextFinalizer(completion: completion)
            return
        }
        finalizer.run {
            success in
            self.callNextFinalizer(completion: completion)
        }
    }
    
}
